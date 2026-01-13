using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.Xrm.Sdk;
using Microsoft.Xrm.Sdk.Query;

namespace wm_compatibility
{
    /// <summary>
    /// Validates accessory compatibility on Sales Order changes (Create/Update).
    /// Updates salesorder.wm_compatibilitystatus and wm_compatibilitydescription.
    /// </summary>
    public class AccessoryCompatibilityPlugin : IPlugin
    {
        // Status option set values
        private const int StatusPass = 1;
        private const int StatusFail = 2;
        private const int StatusNoAccessories = 4;

        // Accessory relationship type in productsubstitute
        // salesrelationshiptype: 0=Up-sell, 1=Cross-sell, 2=Accessory, 3=Substitute
        private const int AccessoryRelationshipType = 2;

        // Max description length (safe cap for Memo field)
        private const int MaxDescriptionLength = 4000;

        public void Execute(IServiceProvider serviceProvider)
        {
            // 0) Obtain services
            var context = (IPluginExecutionContext)serviceProvider.GetService(typeof(IPluginExecutionContext));
            var serviceFactory = (IOrganizationServiceFactory)serviceProvider.GetService(typeof(IOrganizationServiceFactory));
            var service = serviceFactory.CreateOrganizationService(context.UserId);
            var tracingService = (ITracingService)serviceProvider.GetService(typeof(ITracingService));

            try
            {
                tracingService.Trace("AccessoryCompatibilityPlugin started. Message: {0}, Depth: {1}", context.MessageName, context.Depth);

                // Recursion guard: avoid infinite loops
                if (context.Depth > 2)
                {
                    tracingService.Trace("Exiting due to depth > 2 (recursion guard).");
                    return;
                }

                // Validate target exists
                if (!context.InputParameters.Contains("Target"))
                {
                    tracingService.Trace("No Target in InputParameters. Exiting.");
                    return;
                }

                // 1) Get orderId directly from Target (since we're on salesorder entity)
                Entity target = (Entity)context.InputParameters["Target"];
                Guid orderId = target.Id;

                if (orderId == Guid.Empty)
                {
                    tracingService.Trace("No orderId resolved. Exiting.");
                    return;
                }

                tracingService.Trace("Order ID resolved: {0}", orderId);

                // 2) Load order header to get account - try both accountid and customerid
                Guid accountId = GetEntityReferenceId(target, "customerid");
                if (accountId == Guid.Empty)
                {
                    accountId = GetEntityReferenceId(target, "accountid");
                }
                if (accountId == Guid.Empty)
                {
                    // Not in Target, retrieve from database
                    Entity order = service.Retrieve("salesorder", orderId, new ColumnSet("customerid", "accountid"));
                    accountId = GetEntityReferenceId(order, "customerid");
                    if (accountId == Guid.Empty)
                    {
                        accountId = GetEntityReferenceId(order, "accountid");
                    }
                }
                tracingService.Trace("Account ID: {0}", accountId);

                // 3) Load all order lines (product ids)
                List<Guid> lineProductIds = QueryOrderLineProductIds(service, orderId, tracingService);
                tracingService.Trace("Order line product count: {0}", lineProductIds.Count);

                // Log the actual product IDs for debugging
                foreach (Guid productId in lineProductIds)
                {
                    tracingService.Trace("Order line product ID: {0}", productId);
                }

                // Edge: empty order has no lines → treat as No Accessories
                if (lineProductIds.Count == 0)
                {
                    tracingService.Trace("No order lines found. Setting status to No Accessories.");
                    UpdateOrderStatusAndDescription(service, orderId, StatusNoAccessories, string.Empty);
                    return;
                }

                // 4) Load accessory mappings in one batch
                Dictionary<Guid, HashSet<Guid>> childToParent = QueryAccessoryMappings(service, lineProductIds, tracingService);
                HashSet<Guid> accessoryChildrenOnOrder = new HashSet<Guid>(childToParent.Keys);
                tracingService.Trace("Accessory children on order: {0}", accessoryChildrenOnOrder.Count);

                if (accessoryChildrenOnOrder.Count == 0)
                {
                    tracingService.Trace("No accessories on order. Setting status to No Accessories.");
                    UpdateOrderStatusAndDescription(service, orderId, StatusNoAccessories, string.Empty);
                    return;
                }

                // 5) Parents present on order
                HashSet<Guid> allParentIds = new HashSet<Guid>(childToParent.Values.SelectMany(s => s));
                HashSet<Guid> parentsOnOrder = new HashSet<Guid>(lineProductIds.Intersect(allParentIds));
                tracingService.Trace("Parents on order: {0}", parentsOnOrder.Count);

                // 6) Evaluate each accessory child
                HashSet<Guid> failedChildren = new HashSet<Guid>();
                HashSet<Guid> needsHistoricalCheck = new HashSet<Guid>();

                foreach (Guid childId in accessoryChildrenOnOrder)
                {
                    HashSet<Guid> parentSet = childToParent[childId];
                    bool intraOk = parentsOnOrder.Overlaps(parentSet);

                    if (!intraOk)
                    {
                        if (accountId != Guid.Empty)
                        {
                            needsHistoricalCheck.Add(childId);
                        }
                        else
                        {
                            // No account, can't check historical - mark as failed
                            failedChildren.Add(childId);
                        }
                    }
                }

                tracingService.Trace("Accessories needing historical check: {0}", needsHistoricalCheck.Count);

                // 7) Historical purchases check (only if needed)
                if (needsHistoricalCheck.Count > 0 && accountId != Guid.Empty)
                {
                    HashSet<Guid> purchasedProductIds = QueryPurchasedProductsForAccount(service, accountId, tracingService);
                    tracingService.Trace("Historical purchased products: {0}", purchasedProductIds.Count);

                    foreach (Guid childId in needsHistoricalCheck)
                    {
                        HashSet<Guid> parentSet = childToParent[childId];
                        bool historicalOk = purchasedProductIds.Overlaps(parentSet);

                        if (!historicalOk)
                        {
                            failedChildren.Add(childId);
                        }
                    }
                }

                tracingService.Trace("Failed accessories count: {0}", failedChildren.Count);

                // 8) Aggregate & update
                if (failedChildren.Count == 0)
                {
                    tracingService.Trace("All accessories pass. Setting status to Pass.");
                    UpdateOrderStatusAndDescription(service, orderId, StatusPass, string.Empty);
                    return;
                }

                // FAIL → build description with product names
                List<string> failedNames = ResolveProductNames(service, failedChildren, tracingService);
                string description = BuildDescriptionText(failedNames, MaxDescriptionLength);
                tracingService.Trace("Setting status to Fail with {0} failed accessories.", failedNames.Count);
                UpdateOrderStatusAndDescription(service, orderId, StatusFail, description);
            }
            catch (Exception ex)
            {
                tracingService.Trace("Error in AccessoryCompatibilityPlugin: {0}", ex.ToString());
                throw new InvalidPluginExecutionException(
                    $"An error occurred in Accessory Compatibility Validator: {ex.Message}", ex);
            }
        }

        /// <summary>
        /// Gets the ID from an EntityReference attribute, or Guid.Empty if not found.
        /// </summary>
        private Guid GetEntityReferenceId(Entity entity, string attributeName)
        {
            if (entity == null || !entity.Contains(attributeName))
            {
                return Guid.Empty;
            }

            object value = entity[attributeName];
            if (value is EntityReference entityRef)
            {
                return entityRef.Id;
            }

            return Guid.Empty;
        }

        /// <summary>
        /// Queries all distinct product IDs for salesorderdetail lines of an order.
        /// </summary>
        private List<Guid> QueryOrderLineProductIds(IOrganizationService service, Guid orderId, ITracingService tracingService)
        {
            tracingService.Trace("Querying order line product IDs for order: {0}", orderId);

            QueryExpression query = new QueryExpression("salesorderdetail")
            {
                ColumnSet = new ColumnSet("productid"),
                Criteria = new FilterExpression
                {
                    Conditions =
                    {
                        new ConditionExpression("salesorderid", ConditionOperator.Equal, orderId)
                    }
                }
            };

            EntityCollection results = service.RetrieveMultiple(query);
            HashSet<Guid> productIds = new HashSet<Guid>();

            foreach (Entity line in results.Entities)
            {
                Guid productId = GetEntityReferenceId(line, "productid");
                if (productId != Guid.Empty)
                {
                    productIds.Add(productId);
                }
            }

            return productIds.ToList();
        }

        /// <summary>
        /// Batch queries productsubstitute for accessory mappings.
        /// Returns Dictionary mapping childId → set of parentIds.
        /// Checks both directions: product as accessory (substitutedproductid) and product as parent (productid).
        /// </summary>
        private Dictionary<Guid, HashSet<Guid>> QueryAccessoryMappings(
            IOrganizationService service,
            List<Guid> lineProductIds,
            ITracingService tracingService)
        {
            tracingService.Trace("Querying accessory mappings for {0} products", lineProductIds.Count);

            Dictionary<Guid, HashSet<Guid>> childToParent = new Dictionary<Guid, HashSet<Guid>>();

            if (lineProductIds.Count == 0)
            {
                return childToParent;
            }

            // First, let's query ALL accessory relationships to see what's in the system (for debugging)
            QueryExpression debugQuery = new QueryExpression("productsubstitute")
            {
                ColumnSet = new ColumnSet("productid", "substitutedproductid", "salesrelationshiptype"),
                Criteria = new FilterExpression
                {
                    FilterOperator = LogicalOperator.Or,
                    Conditions =
                    {
                        new ConditionExpression("substitutedproductid", ConditionOperator.In, lineProductIds.Cast<object>().ToArray()),
                        new ConditionExpression("productid", ConditionOperator.In, lineProductIds.Cast<object>().ToArray())
                    }
                }
            };

            EntityCollection debugResults = service.RetrieveMultiple(debugQuery);
            tracingService.Trace("Total productsubstitute records found for order products: {0}", debugResults.Entities.Count);

            foreach (Entity mapping in debugResults.Entities)
            {
                Guid subProductId = GetEntityReferenceId(mapping, "substitutedproductid");
                Guid prodId = GetEntityReferenceId(mapping, "productid");
                int? relType = mapping.GetAttributeValue<OptionSetValue>("salesrelationshiptype")?.Value;
                tracingService.Trace("Found relationship: ProductId={0}, SubstitutedProductId={1}, RelType={2}", 
                    prodId, subProductId, relType);
            }

            // Now query for actual accessory relationships
            // In productsubstitute: productid = parent, substitutedproductid = accessory (child)
            QueryExpression query = new QueryExpression("productsubstitute")
            {
                ColumnSet = new ColumnSet("productid", "substitutedproductid"),
                Criteria = new FilterExpression
                {
                    Conditions =
                    {
                        new ConditionExpression("salesrelationshiptype", ConditionOperator.Equal, AccessoryRelationshipType),
                        new ConditionExpression("substitutedproductid", ConditionOperator.In, lineProductIds.Cast<object>().ToArray())
                    }
                }
            };

            EntityCollection results = service.RetrieveMultiple(query);

            foreach (Entity mapping in results.Entities)
            {
                Guid childId = GetEntityReferenceId(mapping, "substitutedproductid");
                Guid parentId = GetEntityReferenceId(mapping, "productid");

                if (childId == Guid.Empty || parentId == Guid.Empty)
                {
                    continue;
                }

                if (!childToParent.ContainsKey(childId))
                {
                    childToParent[childId] = new HashSet<Guid>();
                }

                childToParent[childId].Add(parentId);
            }

            tracingService.Trace("Found {0} accessory mappings with RelType={1}", childToParent.Count, AccessoryRelationshipType);
            return childToParent;
        }

        /// <summary>
        /// Queries purchased products for an account from wsi_productspurchased.
        /// Returns distinct HashSet of product IDs.
        /// </summary>
        private HashSet<Guid> QueryPurchasedProductsForAccount(
            IOrganizationService service,
            Guid accountId,
            ITracingService tracingService)
        {
            tracingService.Trace("Querying purchased products for account: {0}", accountId);

            HashSet<Guid> purchasedProducts = new HashSet<Guid>();

            QueryExpression query = new QueryExpression("wsi_productspurchased")
            {
                ColumnSet = new ColumnSet("wsi_product"),
                Criteria = new FilterExpression
                {
                    Conditions =
                    {
                        new ConditionExpression("wsi_account", ConditionOperator.Equal, accountId)
                    }
                }
            };

            EntityCollection results = service.RetrieveMultiple(query);

            foreach (Entity record in results.Entities)
            {
                Guid productId = GetEntityReferenceId(record, "wsi_product");
                if (productId != Guid.Empty)
                {
                    purchasedProducts.Add(productId);
                }
            }

            return purchasedProducts;
        }

        /// <summary>
        /// Resolves product names with fallback to productnumber.
        /// Returns sorted, distinct list of strings.
        /// </summary>
        private List<string> ResolveProductNames(
            IOrganizationService service,
            IEnumerable<Guid> productIds,
            ITracingService tracingService)
        {
            List<Guid> idList = productIds.ToList();
            tracingService.Trace("Resolving names for {0} products", idList.Count);

            List<string> names = new List<string>();

            if (idList.Count == 0)
            {
                return names;
            }

            QueryExpression query = new QueryExpression("product")
            {
                ColumnSet = new ColumnSet("name", "productnumber"),
                Criteria = new FilterExpression
                {
                    Conditions =
                    {
                        new ConditionExpression("productid", ConditionOperator.In, idList.Cast<object>().ToArray())
                    }
                }
            };

            EntityCollection results = service.RetrieveMultiple(query);

            foreach (Entity product in results.Entities)
            {
                string name = product.GetAttributeValue<string>("name");
                string productNumber = product.GetAttributeValue<string>("productnumber");

                // Use name if available, fallback to productnumber
                string displayName = !string.IsNullOrWhiteSpace(name) ? name : productNumber;

                if (!string.IsNullOrWhiteSpace(displayName))
                {
                    names.Add(displayName);
                }
            }

            // Sort alphabetically and ensure distinct
            return names.Distinct().OrderBy(n => n).ToList();
        }

        /// <summary>
        /// Builds newline-separated text with cap. If cap exceeded, truncates and appends "(+N more)".
        /// </summary>
        private string BuildDescriptionText(IEnumerable<string> names, int maxLength)
        {
            List<string> nameList = names.ToList();

            if (nameList.Count == 0)
            {
                return string.Empty;
            }

            string result = string.Empty;
            int includedCount = 0;

            foreach (string name in nameList)
            {
                string lineToAdd = includedCount == 0 ? name : Environment.NewLine + name;
                
                // Check if adding this line would exceed max length (leaving room for suffix)
                string potentialSuffix = $"{Environment.NewLine}(+{nameList.Count - includedCount - 1} more)";
                int reserveLength = potentialSuffix.Length;

                if (result.Length + lineToAdd.Length > maxLength - reserveLength && includedCount > 0)
                {
                    // Would exceed limit, add suffix and break
                    int remaining = nameList.Count - includedCount;
                    if (remaining > 0)
                    {
                        result += $"{Environment.NewLine}(+{remaining} more)";
                    }
                    break;
                }

                result += lineToAdd;
                includedCount++;
            }

            // Final truncation safety check
            if (result.Length > maxLength)
            {
                result = result.Substring(0, maxLength);
            }

            return result;
        }

        /// <summary>
        /// Atomic update of status and description on salesorder.
        /// </summary>
        private void UpdateOrderStatusAndDescription(
            IOrganizationService service,
            Guid orderId,
            int status,
            string description)
        {
            Entity orderUpdate = new Entity("salesorder", orderId)
            {
                ["wm_compatibilitystatus"] = new OptionSetValue(status),
                ["wm_compatibilitydescription"] = description
            };

            service.Update(orderUpdate);
        }
    }
}

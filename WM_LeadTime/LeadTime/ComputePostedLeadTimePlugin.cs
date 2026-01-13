// ComputePostedLeadTimePlugin.cs
// LeadTime plugin to compute wm_PostedLeadTime within country scope.

using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.Xrm.Sdk;
using Microsoft.Xrm.Sdk.Messages;
using Microsoft.Xrm.Sdk.Metadata;
using Microsoft.Xrm.Sdk.Query;

namespace LeadTime
{
    /// <summary>
    /// Computes the minimum wm_leadtimeoutputdays for the source Item Availability By Location record
    /// within the same country (via wsi_location lookup), considering the source product and its
    /// substitutes (SalesRelationshipType = Substitute). Excludes retired products and null/negative
    /// lead-time values. Writes the result to wm_PostedLeadTime (null when none).
    /// </summary>
    public sealed class ComputePostedLeadTimePlugin : IPlugin
    {
        /// <summary>
        /// Entry point for the plugin.
        /// </summary>
        /// <param name="serviceProvider">Service provider from the runtime.</param>
        public void Execute(IServiceProvider serviceProvider)
        {
            var context = (IPluginExecutionContext)serviceProvider.GetService(typeof(IPluginExecutionContext));
            if (!string.Equals(context.PrimaryEntityName, "wsi_itemavailabilitybylocation", StringComparison.OrdinalIgnoreCase))
            {
                return;
            }

            var factory = (IOrganizationServiceFactory)serviceProvider.GetService(typeof(IOrganizationServiceFactory));
            var service = factory.CreateOrganizationService(context.UserId);
            var tracing = (ITracingService)serviceProvider.GetService(typeof(ITracingService));

            try
            {
                var itemAvailabilityId = context.PrimaryEntityId;
                var minLeadTime = ComputePostedLeadTime(service, tracing, itemAvailabilityId);

                var update = new Entity("wsi_itemavailabilitybylocation", itemAvailabilityId);
                update["wm_PostedLeadTime"] = minLeadTime.HasValue ? (object)minLeadTime.Value : null;
                service.Update(update);
            }
            catch (Exception ex)
            {
                tracing?.Trace("ComputePostedLeadTimePlugin error: {0}", ex);
                throw;
            }
        }

        private static int? ComputePostedLeadTime(IOrganizationService service, ITracingService tracing, Guid itemAvailabilityId)
        {
            // 1) Source + country via lookup join
            var item = service.Retrieve(
                "wsi_itemavailabilitybylocation",
                itemAvailabilityId,
                new ColumnSet("wsi_product", "wsi_location"));

            var productRef = item.GetAttributeValue<EntityReference>("wsi_product");
            var locationRef = item.GetAttributeValue<EntityReference>("wsi_location");
            if (productRef == null || locationRef == null)
            {
                tracing?.Trace("Missing product or location; cannot compute lead time.");
                return null;
            }

            var location = service.Retrieve(
                "wsi_location",
                locationRef.Id,
                new ColumnSet("wm_countryregion", "wsi_code"));

            var sourceCountry = location.GetAttributeValue<string>("wm_countryregion");
            if (string.IsNullOrWhiteSpace(sourceCountry))
            {
                tracing?.Trace("Missing wm_countryregion on location; cannot compute lead time.");
                return null;
            }

            // 2) Candidates: source product + substitutes (SalesRelationshipType = Substitute)
            var candidateProductIds = new HashSet<Guid> { productRef.Id };
            var substituteValue = GetOptionSetValueByLabel(
                service,
                "wsi_productrelationship",
                "salesrelationshiptype",
                "Substitute");

            var relQuery = new QueryExpression("wsi_productrelationship")
            {
                ColumnSet = new ColumnSet("wsi_substitutedproductid"),
                Criteria = new FilterExpression(LogicalOperator.And)
                {
                    Conditions =
                    {
                        new ConditionExpression("wsi_productid", ConditionOperator.Equal, productRef.Id),
                        new ConditionExpression("salesrelationshiptype", ConditionOperator.Equal, substituteValue)
                    }
                }
            };

            var relationships = service.RetrieveMultiple(relQuery).Entities;
            foreach (var rel in relationships)
            {
                var subRef = rel.GetAttributeValue<EntityReference>("wsi_substitutedproductid");
                if (subRef != null)
                {
                    candidateProductIds.Add(subRef.Id);
                }
            }

            // 3) Filter to active products only (statecode = 0)
            var productsQuery = new QueryExpression("product")
            {
                ColumnSet = new ColumnSet("productid"),
                Criteria = new FilterExpression(LogicalOperator.And)
                {
                    Conditions =
                    {
                        new ConditionExpression("productid", ConditionOperator.In, candidateProductIds.ToArray()),
                        new ConditionExpression("statecode", ConditionOperator.Equal, 0)
                    }
                }
            };

            var activeProducts = service.RetrieveMultiple(productsQuery).Entities
                .Select(p => p.Id)
                .ToHashSet();

            if (activeProducts.Count == 0)
            {
                tracing?.Trace("No active candidate products found.");
                return null;
            }

            // 4) Gather lead times within same country (lookup join to wsi_location)
            var iaQuery = new QueryExpression("wsi_itemavailabilitybylocation")
            {
                ColumnSet = new ColumnSet("wm_leadtimeoutputdays", "wsi_product"),
                Criteria = new FilterExpression(LogicalOperator.And)
                {
                    Conditions =
                    {
                        new ConditionExpression("wsi_product", ConditionOperator.In, activeProducts.ToArray())
                    }
                }
            };

            var link = iaQuery.AddLink("wsi_location", "wsi_location", "wsi_locationid");
            link.Columns = new ColumnSet("wm_countryregion", "wsi_code");
            link.EntityAlias = "loc";
            link.LinkCriteria.AddCondition("wm_countryregion", ConditionOperator.Equal, sourceCountry);

            var iaRecords = service.RetrieveMultiple(iaQuery).Entities;

            // 5) Compute min; ignore null/negative
            var leadTimes = iaRecords
                .Select(r => r.GetAttributeValue<int?>("wm_leadtimeoutputdays"))
                .Where(v => v.HasValue && v.Value >= 0)
                .Select(v => v.Value)
                .ToList();

            if (leadTimes.Count == 0)
            {
                tracing?.Trace("No eligible lead-time values found; posting null.");
                return null;
            }

            return leadTimes.Min();
        }

        /// <summary>
        /// Resolve an OptionSet value by its label (case-insensitive).
        /// </summary>
        private static int GetOptionSetValueByLabel(
            IOrganizationService service,
            string entityLogicalName,
            string attributeLogicalName,
            string label)
        {
            var request = new RetrieveAttributeRequest
            {
                EntityLogicalName = entityLogicalName,
                LogicalName = attributeLogicalName,
                RetrieveAsIfPublished = true
            };

            var response = (RetrieveAttributeResponse)service.Execute(request);
            var metadata = (PicklistAttributeMetadata)response.AttributeMetadata;

            var match = metadata.OptionSet.Options.FirstOrDefault(
                o => o.Label != null &&
                     o.Label.UserLocalizedLabel != null &&
                     string.Equals(o.Label.UserLocalizedLabel.Label, label, StringComparison.OrdinalIgnoreCase));

            if (match == null)
            {
                throw new InvalidPluginExecutionException(
                    $"Option label '{label}' not found for {entityLogicalName}.{attributeLogicalName}.");
            }

            return match.Value.GetValueOrDefault();
        }
    }
}
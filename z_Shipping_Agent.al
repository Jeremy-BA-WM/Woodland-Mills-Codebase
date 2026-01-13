query 80530 "API - Shipping Agent"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';

    EntityName = 'ShippingAgent';     // singular
    EntitySetName = 'ShippingAgents';    // plural

    elements
    {
        dataitem(Shipping_Agent; "Shipping Agent")
        {
            // Header columns
            column(shippingAgent; Code) { }
            column(Name; Name) { }
            column(SCAC; "WSI0042 SCAC") { }

            // Header audit columns
            column(CreatedAt; SystemCreatedAt) { }
            column(CreatedBy; SystemCreatedBy) { }
            column(ModifiedAt; SystemModifiedAt) { }
            column(ModifiedBy; SystemModifiedBy) { }
        }
    }
}
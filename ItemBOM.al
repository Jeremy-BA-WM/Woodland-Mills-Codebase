query 80160 "API - ItemBOM"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';

    EntityName = 'BOM_Component';     // singular
    EntitySetName = 'BOM_Components';    // plural

    elements
    {
        dataitem(BOM_Component; "BOM Component")
        {
            // Header columns
            column(HeaderNo; "No.") { }
            column(HeaderParentItem; "Parent Item No.") { }
            column(HeaderQTY; "Quantity per") { }

            // Header audit columns
            column(HeaderCreatedAt; SystemCreatedAt) { }
            column(HeaderCreatedBy; SystemCreatedBy) { }
            column(HeaderModifiedAt; SystemModifiedAt) { }
            column(HeaderModifiedBy; SystemModifiedBy) { }
        }
    }
}
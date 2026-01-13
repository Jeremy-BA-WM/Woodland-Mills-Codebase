query 80522 "API - Item BOM"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';

    EntityName = 'Z_BOM_Component';     // singular
    EntitySetName = 'Z_BOM_Components';    // plural

    elements
    {
        dataitem(BOM_Component; "BOM Component")
        {
            // Header columns
            column(ItemNo; "No.") { }
            column(ParentItemNo; "Parent Item No.") { }
            column(HeaderQTY; "Quantity per") { }

            // Header audit columns
            column(CreatedAt; SystemCreatedAt) { }
            column(CreatedBy; SystemCreatedBy) { }
            column(ModifiedAt; SystemModifiedAt) { }
            column(ModifiedBy; SystemModifiedBy) { }
        }
    }
}
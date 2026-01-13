query 80518 "API - PriceList Line"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';

    EntityName = 'Z_PriceListLine';     // singular
    EntitySetName = 'Z_PriceListLines';    // plural

    elements
    {
        dataitem(Price_List_Line; "Price List Line")
        {
            // Header columns
            column(Id; SystemId) { }
            column(ItemNo; "Asset No.") { }
            column(UnitPrice; "Unit Price") { }
            column(PriceListNo; "Price List Code") { }

            // Header audit columns
            column(CreatedAt; SystemCreatedAt) { }
            column(CreatedBy; SystemCreatedBy) { }
            column(ModifiedAt; SystemModifiedAt) { }
            column(ModifiedBy; SystemModifiedBy) { }

        }
    }
}
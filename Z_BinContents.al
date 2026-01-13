query 80523 "API - Bin Contents"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';

    EntityName = 'Z_BinContent';     // singular
    EntitySetName = 'Z_BinContents';    // plural

    elements
    {
        dataitem(Bin_Content; "Bin Content")
        {
            // Header columns
            column(BINNo; "Bin Code") { }
            column(ItemNo; "Item No.") { }
            column(LocationNo; "Location Code") { }
            column(QTY; "Quantity") { }
            column(Fixed; "Fixed") { }
            column(CrossDock; "Cross-Dock Bin") { }
            // Header audit columns
            column(CreatedAt; SystemCreatedAt) { }
            column(CreatedBy; SystemCreatedBy) { }
            column(ModifiedAt; SystemModifiedAt) { }
            column(ModifiedBy; SystemModifiedBy) { }
        }
    }
}
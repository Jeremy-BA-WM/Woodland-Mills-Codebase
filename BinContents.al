query 80190 "API - BinContents"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';

    EntityName = 'BinContent';     // singular
    EntitySetName = 'BinContents';    // plural

    elements
    {
        dataitem(Bin_Content; "Bin Content")
        {
            // Header columns
            column(HeaderNo; "Bin Code") { }
            column(HeaderItemNo; "Item No.") { }
            column(HeaderLocation; "Location Code") { }
            column(HeaderQTY; "Quantity") { }
            column(HeaderFixed; "Fixed") { }
            column(HeaderCrossDock; "Cross-Dock Bin") { }
            // Header audit columns
            column(HeaderCreatedAt; SystemCreatedAt) { }
            column(HeaderCreatedBy; SystemCreatedBy) { }
            column(HeaderModifiedAt; SystemModifiedAt) { }
            column(HeaderModifiedBy; SystemModifiedBy) { }
        }
    }
}
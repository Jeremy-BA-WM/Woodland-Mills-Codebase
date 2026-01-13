query 80040 "API - StockkeepingUnits"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';

    EntityName = 'StockkeepingUnits';     // singular
    EntitySetName = 'StockkeepingUnits';    // plural

    elements
    {
        dataitem(Stockkeeping_Unit; "stockkeeping Unit")
        {
            // Header columns
            column(HeaderItemNo; "Item No.") { }
            column(HeaderLeadTime; "Lead Time Calculation") { }
            column(HeaderLocation; "Location Code") { }
            column(HeaderReplenishment; "Replenishment System") { }
            column(HeaderVendorNo; "Vendor No.") { }
            column(HeaderReorderomgPolicy; "Reordering Policy") { }
            column(HeaderReorderPoint; "Reorder Point") { }
            column(HeaderReorderQTY; "Reorder Quantity") { }
            column(HeaderOrderMultiple; "Order Multiple") { }
            column(HeaderTransferFrom; "Transfer-from Code") { }
            // Header audit columns
            column(HeaderCreatedAt; SystemCreatedAt) { }
            column(HeaderCreatedBy; SystemCreatedBy) { }
            column(HeaderModifiedAt; SystemModifiedAt) { }
            column(HeaderModifiedBy; SystemModifiedBy) { }

        }
    }
}
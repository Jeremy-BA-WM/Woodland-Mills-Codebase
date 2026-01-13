query 80506 "API - Stockkeeping Units"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';

    EntityName = 'Z_StockkeepingUnit';     // singular
    EntitySetName = 'Z_StockkeepingUnits';    // plural

    elements
    {
        dataitem(Stockkeeping_Unit; "stockkeeping Unit")
        {
            // Header columns
            column(Id; SystemId) { }
            column(ItemNo; "Item No.") { }
            column(LeadTime; "Lead Time Calculation") { }
            column(LocationNo; "Location Code") { }
            column(Replenishment; "Replenishment System") { }
            column(VendorNo; "Vendor No.") { }
            column(ReorderingPolicy; "Reordering Policy") { }
            column(ReorderPoint; "Reorder Point") { }
            column(ReorderQTY; "Reorder Quantity") { }
            column(OrderMultiple; "Order Multiple") { }
            column(TransferFrom; "Transfer-from Code") { }
            // Header audit columns
            column(CreatedAt; SystemCreatedAt) { }
            column(CreatedBy; SystemCreatedBy) { }
            column(ModifiedAt; SystemModifiedAt) { }
            column(ModifiedBy; SystemModifiedBy) { }

        }
    }
}
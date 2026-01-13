query 80508 "API - Shipment Line"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';

    EntityName = 'Z_ShipmentLine';     // singular
    EntitySetName = 'Z_ShipmentLines';    // plural

    elements
    {
        dataitem(Sales_Shipment_Line; "Sales Shipment Line")
        {
            // Header columns
            column(Id; SystemId) { }
            column(ShipmentNo; "Document No.") { }
            column(ItemNo; "No.") { }
            column(QTY; "Quantity") { }
            column(QTYInvoiced; "Quantity Invoiced") { }
            column(UnitPrice; "Unit Price") { }
            column(DiscountPct; "Line Discount %") { }
            column(Type; Type) { }
            column(LocationNo; "Location Code") { }
            column(ShipmentDate; "Shipment Date") { }
            column(Weight; "WSI0032 Weight") { }
            column(TotalWeight; "WSI0032 Total Weight") { }
            column(Cubage; "WSI0032 Cubage") { }
            column(TotalCubage; "WSI0032 Total Cubage") { }

            // Header audit columns
            column(CreatedAt; SystemCreatedAt) { }
            column(CreatedBy; SystemCreatedBy) { }
            column(ModifiedAt; SystemModifiedAt) { }
            column(ModifiedBy; SystemModifiedBy) { }

        }
    }
}
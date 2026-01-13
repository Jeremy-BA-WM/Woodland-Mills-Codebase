query 80514 "API - Purch Receipt Line"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';

    EntityName = 'Z_PurchReceiptLine';     // singular
    EntitySetName = 'Z_PurchReceiptLines';    // plural

    elements
    {
        dataitem(Purch__Rcpt__Line; "Purch. Rcpt. Line")
        {
            // Header columns
            column(Id; SystemId) { }
            column(ItemNo; "No.") { }
            column(QTY; Quantity) { }
            column(OrderDate; "Order Date") { }
            column(ExpectedReceiptDate; "Expected Receipt Date") { }
            column(QTYInvoiced; "Quantity Invoiced") { }
            column(UnitCost; "Direct Unit Cost") { }
            column(Description; "Description") { }
            column(PurchReceiptNo; "Document No.") { }
            column(LineType; "Type") { }
            column(LocationNo; "Location Code") { }

            // ✅ Vendor field
            column(Weight; "WSI0032 Weight") { }
            column(Cubage; "WSI0032 Cubage") { }
            column(TotalWeight; "WSI0032 Total Weight") { }
            column(TotalCubage; "WSI0032 Total Cubage") { }

            // Header audit columns
            column(CreatedAt; SystemCreatedAt) { }
            column(CreatedBy; SystemCreatedBy) { }
            column(ModifiedAt; SystemModifiedAt) { }
            column(ModifiedBy; SystemModifiedBy) { }
        }
    }
}
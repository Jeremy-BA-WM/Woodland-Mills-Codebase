query 80516 "API - Purch Line"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';

    EntityName = 'Z_PurchaseLine';     // singular
    EntitySetName = 'Z_PurchaseLines';    // plural

    elements
    {
        dataitem(Purchase_Line; "Purchase Line")
        {
            // Header columns
            column(Id; SystemId) { }
            column(ItemNo; "No.") { }
            column(QTY; Quantity) { }
            column(OutstandingQTY; "Outstanding Quantity") { }
            column(QTYReceived; "Quantity Received") { }
            column(QTYInvoiced; "Quantity Invoiced") { }
            column(UnitCost; "Direct Unit Cost") { }
            column(Amount; Amount) { }
            column(DiscountPct; "Line Discount %") { }
            column(AmountExclVAT; "Line Amount") { }
            column(DocumentType; "Document Type") { }
            column(PurchaseNo; "Document No.") { }
            column(Type; Type) { }
            column(LocationNo; "Location Code") { }
            column(VATpct; "VAT %") { }
            column(VAT; "VAT Base Amount") { }
            column(AmountIncludingVAT; "Amount Including VAT") { }
            column(Description; "Description") { }

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
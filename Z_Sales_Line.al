query 80512 "API - Sales Line"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';

    EntityName = 'Z_SalesLine';     // singular
    EntitySetName = 'Z_SalesLines';    // plural

    elements
    {
        dataitem(SalesLine; "Sales Line")
        {
            // Header columns
            column(Id; SystemId) { }
            column(ItemNo; "No.") { }
            column(QTY; Quantity) { }
            column(ReservedQTY; "Reserved Quantity") { }
            column(OutstandingQTY; "Outstanding Quantity") { }
            column(QTYShipped; "Quantity Shipped") { }
            column(QTYInvoiced; "Quantity Invoiced") { }
            column(UnitPrice; "Unit Price") { }
            column(Amount; Amount) { }
            column(DiscountPct; "Line Discount %") { }
            column(AmountExclVAT; "Line Amount") { }
            column(DocumentType; "Document Type") { }
            column(SalesNo; "Document No.") { }
            column(Type; Type) { }
            column(LocationNo; "Location Code") { }
            column(Description; "Description") { }
            column(VATpct; "VAT %") { }
            column(VAT; "VAT Base Amount") { }
            column(AmountIncludingVAT; "Amount Including VAT") { }

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

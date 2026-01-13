query 80510 "API - Sales Inv Line"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';

    EntityName = 'Z_SalesInvoiceLine';     // singular
    EntitySetName = 'Z_SalesInvoiceLines';    // plural

    elements
    {
        dataitem(Sales_Invoice_Line; "Sales Invoice Line")
        {
            // Header columns
            column(Id; SystemId) { }
            column(SalesInvNo; "Document No.") { }
            column(ItemNo; "No.") { }
            column(QTY; Quantity) { }
            column(UnitPrice; "Unit Price") { }
            column(Amount; Amount) { }
            column(DiscountPct; "Line Discount %") { }
            column(AmountExclVAT; "Line Amount") { }
            column(VATpct; "VAT %") { }
            column(VAT; "VAT Base Amount") { }
            column(AmountIncludingVAT; "Amount Including VAT") { }
            column(Type; Type) { }
            column(LocationNo; "Location Code") { }
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
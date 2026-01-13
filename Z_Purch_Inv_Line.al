query 80114 "API - Purch Invoice Line"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';

    EntityName = 'Z_PurchInvoiceLine';     // singular
    EntitySetName = 'Z_PurchInvoiceLines';    // plural

    elements
    {
        dataitem(Purch__Inv__line; "Purch. Inv. Line")
        {
            // Header columns
            column(Id; SystemId) { }
            column(ItemNo; "No.") { }
            column(QTY; Quantity) { }
            column(PurchReceiptNo; "Receipt No.") { }
            column(GenProductPostingGroup; "Gen. Prod. Posting Group") { }
            column(Amount; Amount) { }
            column(DiscountPct; "Line Discount %") { }
            column(AmountExclVAT; "Line Amount") { }
            column(PurchInvNo; "Document No.") { }
            column(Description; "Description") { }
            column(Type; Type) { }
            column(LocationNo; "Location Code") { }
            column(UnitCost; "Unit Cost") { }
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
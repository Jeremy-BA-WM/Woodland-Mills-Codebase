query 80113 "API - Purch Invoice Header"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';

    EntityName = 'Z_PurchInvoiceHeader';     // singular
    EntitySetName = 'Z_PurchInvoiceHeaders';    // plural

    elements
    {
        dataitem(Purch__Inv__Header; "Purch. Inv. Header")
        {
            // Header columns
            column(Id; SystemId) { }
            column(PurchInvNo; "No.") { }
            column(VendorNo; "Buy-from Vendor No.") { }
            column(VendorName; "Buy-from Vendor Name") { }
            column(ShipmentMethod; "Shipment Method Code") { }
            column(PostingDate; "Posting Date") { }
            column(VendorPostingGroup; "Vendor Posting Group") { }
            column(VendorOrderNo; "Vendor Order No.") { }
            column(CurrencyFactor; "Currency Factor") { }
            column(VendorInvoiceNo; "Vendor Invoice No.") { }
            column(OrderDate; "Order Date") { }
            column(PurchaseNo; "Order No.") { }
            column(ExpectedReceipt; "Expected Receipt Date") { }
            column(Reference; "Your Reference") { }
            column(CurrencyCode; "Currency Code") { }
            column(PaymentMethod; "Payment Method Code") { }
            column(PaymentTerms; "Payment Terms Code") { }
            column(TotalAmount; Amount) { }
            column(LocationNo; "Location Code") { }
            column(GenBusinessPostingGroup; "Gen. Bus. Posting Group") { }
            column(ShippingAgent; "Shipment Method Code") { }
            column(TaxAreaCode; "Tax Area Code") { }

            // ✅ Vendor field
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
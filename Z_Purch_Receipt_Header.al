query 80513 "API - Purch Receipt Header"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';

    EntityName = 'Z_PurchReceiptHeader';     // singular
    EntitySetName = 'Z_PurchReceiptHeaders';    // plural

    elements
    {
        dataitem(PurchRcptHeader; "Purch. Rcpt. Header")
        {
            // Header columns
            column(Id; SystemId) { }
            column(PurchReceiptNo; "No.") { }
            column(VendorNo; "Buy-from Vendor No.") { }
            column(VendorName; "Buy-from Vendor Name") { }
            column(ShipmentMethod; "Shipment Method Code") { }
            column(PostingDate; "Posting Date") { }
            column(PurchaseNo; "Order No.") { }
            column(OrderDate; "Order Date") { }
            column(ExpectedReceipt; "Expected Receipt Date") { }
            column(Reference; "Your Reference") { }
            column(LocationNo; "Location Code") { }
            column(GenBusinessPostingGroup; "Gen. Bus. Posting Group") { }
            column(ShippingAgent; "Shipment Method Code") { }

            // ✅ Vendor field
            column(TotalWeight; "WSI0032 Total Weight") { }
            column(TotalCubage; "WSI0032 Total Cubage") { }
            column(ContainerNo; "WSI0042 ContainerNo") { }

            // Header audit columns
            column(CreatedAt; SystemCreatedAt) { }
            column(CreatedBy; SystemCreatedBy) { }
            column(ModifiedAt; SystemModifiedAt) { }
            column(ModifiedBy; SystemModifiedBy) { }
        }
    }
}
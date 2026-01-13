query 80110 "API - PurchaseInvandLines"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';

    EntityName = 'PurchaseInvandLines';     // singular
    EntitySetName = 'PurchaseInvandLines';    // plural

    elements
    {
        dataitem(Purch__Inv__Header; "Purch. Inv. Header")
        {
            // Header columns
            column(HeaderId; SystemId) { }
            column(HeaderNo; "No.") { }
            column(HeaderVendorNo; "Buy-from Vendor No.") { }
            column(HeaderVendorName; "Buy-from Vendor Name") { }
            column(HeaderShipment_Method_Code; "Shipment Method Code") { }
            column(HeaderPostingDate; "Posting Date") { }
            column(HeaderVendorPostingGroup; "Vendor Posting Group") { }
            column(HeaderCurrencyFactor; "Currency Factor") { }
            column(HeaderVendorInvoiceNo; "Vendor Invoice No.") { }
            column(HeaderOrderDate; "Order Date") { }
            column(HeaderOrderNo; "Order No.") { }
            column(HeaderExpectedReceipt; "Expected Receipt Date") { }
            column(HeaderReference; "Your Reference") { }
            column(HeaderCurrencyCode; "Currency Code") { }
            column(HeaderTotalAmount; Amount) { }
            column(HeaderLocation_Code; "Location Code") { }
            column(HeaderGenBusinessPostingGroup; "Gen. Bus. Posting Group") { }
            column(HeaderShippingAgent; "Shipment Method Code") { }

            // ✅ Vendor field
            column(HeaderWeight; "WSI0032 Total Weight") { }
            column(HeaderCubage; "WSI0032 Total Cubage") { }

            // Header audit columns
            column(HeaderCreatedAt; SystemCreatedAt) { }
            column(HeaderCreatedBy; SystemCreatedBy) { }
            column(HeaderModifiedAt; SystemModifiedAt) { }
            column(HeaderModifiedBy; SystemModifiedBy) { }

            dataitem(Purch__Inv__Line; "Purch. Inv. Line")
            {
                // Join lines to header
                DataItemLink =
                    "Document No." = Purch__Inv__Header."No.";

                // (Optional) restrict to Item lines only:
                // filter(ItemOnly; Type) = const(Item);

                // Line columns
                column(LineId; SystemId) { }
                column(LineNo; "Line No.") { }
                column(LineItemNo; "No.") { }
                column(LineQuantity; Quantity) { }
                column(LineReceiptNo; "Receipt No.") { }
                column(LineGenProductPostingGroup; "Gen. Prod. Posting Group") { }
                column(LineAmount; Amount) { }
                column(LineDiscountPct; "Line Discount %") { }
                column(GetLineAmountExclVAT; "Line Amount") { }
                column(LineDocumentNo; "Document No.") { }
                column(LineType; Type) { }
                column(LineLocation_Code; "Location Code") { }

                // Line audit columns
                column(LineCreatedAt; SystemCreatedAt) { }
                column(LineCreatedBy; SystemCreatedBy) { }
                column(LineModifiedAt; SystemModifiedAt) { }
                column(LineModifiedBy; SystemModifiedBy) { }

            }
        }
    }
}
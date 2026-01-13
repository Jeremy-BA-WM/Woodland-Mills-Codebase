query 80020 "API - PurchReceiptandLines"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';

    EntityName = 'PurchaseHeaderandLines';     // singular
    EntitySetName = 'PurchaseHeaderandLines';    // plural

    elements
    {
        dataitem(Purchase_Header; "Purchase Header")
        {
            // Header columns
            column(HeaderId; SystemId) { }
            column(HeaderNo; "No.") { }
            column(HeaderVendorNo; "Buy-from Vendor No.") { }
            column(HeaderVendorName; "Buy-from Vendor Name") { }
            column(HeaderShipment_Method_Code; "Shipment Method Code") { }
            column(HeaderPostingDate; "Posting Date") { }
            column(HeaderDocumentType; "Document Type") { }
            column(HeaderOrderDate; "Order Date") { }
            column(HeaderExpectedReceipt; "Expected Receipt Date") { }
            column(HeaderReference; "Your Reference") { }
            column(HeaderCurrencyCode; "Currency Code") { }
            column(HeaderTotalAmount; Amount) { }
            column(HeaderStatus; Status) { }
            column(HeaderLocation_Code; "Location Code") { }
            column(HeaderGenBusinessPostingGroup; "Gen. Bus. Posting Group") { }
            column(HeaderShippingAgent; "Shipment Method Code") { }

            // ✅ Vendor field
            column(HeaderWeight; "WSI0032 Total Weight") { }
            column(HeaderContainerNo; "WSI0042 ContainerNo") { }

            // Header audit columns
            column(HeaderCreatedAt; SystemCreatedAt) { }
            column(HeaderCreatedBy; SystemCreatedBy) { }
            column(HeaderModifiedAt; SystemModifiedAt) { }
            column(HeaderModifiedBy; SystemModifiedBy) { }

            dataitem(Purchase_Line; "Purchase Line")
            {
                // Join lines to header
                DataItemLink =
                    "Document Type" = Purchase_Header."Document Type",
                    "Document No." = Purchase_Header."No.";

                // (Optional) restrict to Item lines only:
                // filter(ItemOnly; Type) = const(Item);

                // Line columns
                column(LineId; SystemId) { }
                column(LineNo; "Line No.") { }
                column(LineItemNo; "No.") { }
                column(LineQuantity; Quantity) { }
                column(LineOutstandingQTY; "Outstanding Quantity") { }
                column(LineQTYReceived; "Quantity Received") { }
                column(LineQTYInvoiced; "Quantity Invoiced") { }
                column(LineUnitCost; "Direct Unit Cost") { }
                column(LineAmount; Amount) { }
                column(LineDiscountPct; "Line Discount %") { }
                column(GetLineAmountExclVAT; "Line Amount") { }
                column(LineDocumentType; "Document Type") { }
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
query 80090 "API - PurchaseHeaderandLines"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';

    EntityName = 'PurchReceiptHeaderandLines';     // singular
    EntitySetName = 'PurchReceiptHeaderandLines';    // plural

    elements
    {
        dataitem(PurchRcptHeader; "Purch. Rcpt. Header")
        {
            // Header columns
            column(HeaderId; SystemId) { }
            column(HeaderNo; "No.") { }
            column(HeaderVendorNo; "Buy-from Vendor No.") { }
            column(HeaderVendorName; "Buy-from Vendor Name") { }
            column(HeaderShipment_Method_Code; "Shipment Method Code") { }
            column(HeaderPostingDate; "Posting Date") { }
            column(HeaderOrderNo; "Order No.") { }
            column(HeaderOrderDate; "Order Date") { }
            column(HeaderExpectedReceipt; "Expected Receipt Date") { }
            column(HeaderReference; "Your Reference") { }
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

            dataitem(PurchRcptLine; "Purch. Rcpt. Line")
            {
                // Join lines to header
                DataItemLink =
                    "Document No." = PurchRcptHeader."No.",
                    "Document No." = PurchRcptHeader."No.";

                // (Optional) restrict to Item lines only:
                // filter(ItemOnly; Type) = const(Item);

                // Line columns
                column(LineId; SystemId) { }
                column(LineNo; "Line No.") { }
                column(LineItemNo; "No.") { }
                column(LineQuantity; Quantity) { }
                column(LineOrderDate; "Order Date") { }
                column(LineExpectedReceiptDate; "Expected Receipt Date") { }
                column(LineQTYInvoiced; "Quantity Invoiced") { }
                column(LineUnitCost; "Direct Unit Cost") { }
                column(LineDescription; Description) { }
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
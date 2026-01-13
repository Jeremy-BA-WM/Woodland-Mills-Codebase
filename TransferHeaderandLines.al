query 80170 "API - TransferHeaderandLines"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';

    EntityName = 'TransferHeaderandLines';     // singular
    EntitySetName = 'TransferHeaderandLines';    // plural

    elements
    {
        dataitem(Transfer_Header; "Transfer Header")
        {
            // Header columns
            column(HeaderId; SystemId) { }
            column(HeaderNo; "No.") { }
            column(HeaderTransferFrom; "Transfer-from Code") { }
            column(HeaderTransferTo; "Transfer-to Code") { }
            column(HeaderShipment_Method_Code; "Shipment Method Code") { }
            column(HeaderPostingDate; "Posting Date") { }
            column(HeaderStatus; Status) { }

            // Header audit columns
            column(HeaderCreatedAt; SystemCreatedAt) { }
            column(HeaderCreatedBy; SystemCreatedBy) { }
            column(HeaderModifiedAt; SystemModifiedAt) { }
            column(HeaderModifiedBy; SystemModifiedBy) { }

            dataitem(Purchase_Line; "Purchase Line")
            {
                // Join lines to header
                DataItemLink =
                    "Document Type" = Transfer_Header."No.",
                    "No." = Transfer_Header."No.";

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
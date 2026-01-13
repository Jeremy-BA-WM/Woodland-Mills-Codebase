query 80060 "API - SalesInvHeaderLines"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';

    EntityName = 'SalesInvoiceHeaderandLines';     // singular
    EntitySetName = 'SalesInvoiceHeaderandLines';    // plural

    elements
    {
        dataitem(Sales_Invoice_Header; "Sales Invoice Header")
        {
            // Header columns
            column(HeaderId; SystemId) { }
            column(HeaderNo; "No.") { }
            column(HeaderCustomerName; "Sell-to Customer Name") { }
            column(HeaderCustomerNo; "Sell-to Customer No.") { }
            column(HeaderShipment_Method_Code; "Shipment Method Code") { }
            column(HeaderPostingDate; "Posting Date") { }
            column(HeaderOrderDate; "Order Date") { }
            column(HeaderExternalDocumentNo; "External Document No.") { }
            column(HeaderCurrencyCode; "Currency Code") { }
            column(HeaderTotalAmount; Amount) { }
            column(HeaderLocation_Code; "Location Code") { }
            column(HeaderGenBusinessPostingGroup; "Gen. Bus. Posting Group") { }
            column(HeaderShippingAgent; "Shipping Agent Code") { }
            column(HeaderOrderNo; "Order No.") { }

            // ✅ Vendor field
            column(HeaderWeight; "WSI0032 Total Weight") { }

            // Header audit columns
            column(HeaderCreatedAt; SystemCreatedAt) { }
            column(HeaderCreatedBy; SystemCreatedBy) { }
            column(HeaderModifiedAt; SystemModifiedAt) { }
            column(HeaderModifiedBy; SystemModifiedBy) { }

            dataitem(Sales_Invoice_Line; "Sales Invoice Line")
            {
                // Join lines to header
                DataItemLink = "Document No." = Sales_Invoice_Header."No.";

                // (Optional) restrict to Item lines only:
                // filter(ItemOnly; Type) = const(Item);

                // Line columns
                column(LineId; SystemId) { }
                column(LineNo; "Line No.") { }
                column(LineItemNo; "No.") { }
                column(LineQuantity; Quantity) { }
                column(LineUnitPrice; "Unit Price") { }
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
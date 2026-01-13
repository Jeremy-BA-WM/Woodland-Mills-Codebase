query 80030 "API - ShipmentHeaderandLines"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';

    EntityName = 'ShipmentHeaderandLines';     // singular
    EntitySetName = 'ShipmentHeaderandLines';    // plural

    elements
    {
        dataitem(Sales_Shipment_Header; "Sales Shipment Header")
        {
            // Header columns
            column(HeaderId; SystemId) { }
            column(HeaderNo; "No.") { }
            column(HeaderCustomerName; "Sell-to Customer Name") { }
            column(HeaderCustomerNo; "Sell-to Customer No.") { }
            column(HeaderShipment_Method_Code; "Shipment Method Code") { }
            column(HeaderPostingDate; "Posting Date") { }
            column(HeaderReference; "Your Reference") { }
            column(HeaderOrderNo; "Order No.") { }
            column(HeaderOrderDate; "Order Date") { }
            column(HeaderExternalDocumentNo; "External Document No.") { }
            column(HeaderCurrencyCode; "Currency Code") { }
            column(HeaderLocation_Code; "Location Code") { }
            column(HeaderGenBusinessPostingGroup; "Gen. Bus. Posting Group") { }
            column(HeaderShippingAgent; "Shipping Agent Code") { }
            column(HeaderRequestedDeliveryDate; "Requested Delivery Date") { }
            column(HeaderCountry; "Ship-to Country/Region Code") { }
            column(HeaderState; "Ship-to County") { }

            // ✅ Vendor field
            column(HeaderWeight; "WSI0032 Total Weight") { }
            column(HeaderCubage; "WSI0032 Total Cubage") { }

            // Header audit columns
            column(HeaderCreatedAt; SystemCreatedAt) { }
            column(HeaderCreatedBy; SystemCreatedBy) { }
            column(HeaderModifiedAt; SystemModifiedAt) { }
            column(HeaderModifiedBy; SystemModifiedBy) { }

            dataitem(Sales_Shipment_Line; "Sales Shipment Line")
            {
                DataItemLink = "Document No." = Sales_Shipment_Header."No.";

                // (Optional) restrict to Item lines only:
                // filter(ItemOnly; Type) = const(Item);

                // Line columns
                column(LineId; SystemId) { }
                column(LineNo; "Line No.") { }
                column(LineItemNo; "No.") { }
                column(LineQuantity; Quantity) { }
                column(LineQTYInvoiced; "Quantity Invoiced") { }
                column(LineUnitPrice; "Unit Price") { }
                column(LineDiscountPct; "Line Discount %") { }
                column(LineDocumentNo; "Document No.") { }
                column(LineType; Type) { }
                column(LineLocation_Code; "Location Code") { }
                column(LineShipmentDate; "Shipment Date") { }

                // Line audit columns
                column(LineCreatedAt; SystemCreatedAt) { }
                column(LineCreatedBy; SystemCreatedBy) { }
                column(LineModifiedAt; SystemModifiedAt) { }
                column(LineModifiedBy; SystemModifiedBy) { }

            }
        }
    }
}
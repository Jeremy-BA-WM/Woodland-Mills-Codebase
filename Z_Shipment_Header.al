query 80507 "API - Shipment Header"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';

    EntityName = 'Z_ShipmentHeader';     // singular
    EntitySetName = 'Z_ShipmentHeaders';    // plural

    elements
    {
        dataitem(Sales_Shipment_Header; "Sales Shipment Header")
        {
            // Header columns
            column(Id; SystemId) { }
            column(ShipmentNo; "No.") { }
            column(CustomerName; "Sell-to Customer Name") { }
            column(CustomerNo; "Sell-to Customer No.") { }
            column(ShipmentMethod; "Shipment Method Code") { }
            column(PostingDate; "Posting Date") { }
            column(Reference; "Your Reference") { }
            column(SalesNo; "Order No.") { }
            column(OrderDate; "Order Date") { }
            column(ExternalDocumentNo; "External Document No.") { }
            column(CurrencyCode; "Currency Code") { }
            column(LocationNo; "Location Code") { }
            column(GenBusinessPostingGroup; "Gen. Bus. Posting Group") { }
            column(ShippingAgent; "Shipping Agent Code") { }
#pragma warning disable AL0432
            column(TrackingNo; "Package Tracking No.") { }
#pragma warning restore AL0432
            // column(TrackingNo; "Package Tracking No.") { } // Removed: field marked for removal (length changed); replace with an appropriate field if available
            column(RequestedDeliveryDate; "Requested Delivery Date") { }
            column(Country; "Ship-to Country/Region Code") { }
            column(State; "Ship-to County") { }

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
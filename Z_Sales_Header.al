query 80511 "API - Sales Header"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';

    EntityName = 'Z_SalesHeader';     // singular
    EntitySetName = 'Z_SalesHeaders';    // plural

    elements
    {
        dataitem(SalesHeader; "Sales Header")
        {
            // Header columns
            column(Id; SystemId) { }
            column(SalesNo; "No.") { }
            column(CustomerName; "Sell-to Customer Name") { }
            column(CustomerNo; "Sell-to Customer No.") { }
            column(ShimentMethod; "Shipment Method Code") { }
            column(PostingDate; "Posting Date") { }
            column(DocumentType; "Document Type") { }
            column(OrderDate; "Order Date") { }
            column(ExternalDocumentNo; "External Document No.") { }
            column(CurrencyCode; "Currency Code") { }
            column(TotalAmount; Amount) { }
            column(Status; Status) { }
            column(LocationNo; "Location Code") { }
            column(GenBusinessPostingGroup; "Gen. Bus. Posting Group") { }
            column(ShippingAgent; "Shipping Agent Code") { }
            column(RequestedDeliveryDate; "Requested Delivery Date") { }

            // ✅ Vendor field
            column(TotalWeight; "WSI0032 Total Weight") { }
            column(TotalCubage; "WSI0032 Total Cubage") { }
            column(ReleasedStatus; "WSI Released Status") { }
            column(WSIStatus; "WSI Status") { }
            column(FulfillabilityStatus; "WSI Fulfillability Status") { }

            // Header audit columns
            column(CreatedAt; SystemCreatedAt) { }
            column(CreatedBy; SystemCreatedBy) { }
            column(ModifiedAt; SystemModifiedAt) { }
            column(ModifiedBy; SystemModifiedBy) { }
        }
    }
}
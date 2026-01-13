query 80509 "API - Sales Inv Header"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';

    EntityName = 'Z_SalesInvoiceHeader';     // singular
    EntitySetName = 'Z_SalesInvoiceHeaders';    // plural

    elements
    {
        dataitem(Sales_Invoice_Header; "Sales Invoice Header")
        {
            // Header columns
            column(Id; SystemId) { }
            column(SalesInvNo; "No.") { }
            column(CustomerName; "Sell-to Customer Name") { }
            column(CustomerNo; "Sell-to Customer No.") { }
            column(ShipmentMethod; "Shipment Method Code") { }
            column(PostingDate; "Posting Date") { }
            column(OrderDate; "Order Date") { }
            column(ExternalDocumentNo; "External Document No.") { }
            column(CurrencyCode; "Currency Code") { }
            column(TotalAmount; Amount) { }
            column(LocationNo; "Location Code") { }
            column(GenBusinessPostingGroup; "Gen. Bus. Posting Group") { }
            column(ShippingAgent; "Shipping Agent Code") { }
            column(SalesNo; "Order No.") { }

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
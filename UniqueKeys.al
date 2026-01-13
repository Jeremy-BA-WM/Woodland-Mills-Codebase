query 80201 "API - EDI940Keys"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';
    EntityName = 'EDI940Keys';
    EntitySetName = 'EDI940Keys';

    elements
    {
        dataitem(SourceTable; "WSI0042 EDI940OB")
        {
            column(EDI940No; "WSI OriginalSONumber") { }
            column(EDI940EDIOrderNo; "Order Number") { }
        }
    }
}

query 80202 "API - EDI945Keys"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';
    EntityName = 'EDI945Keys';
    EntitySetName = 'EDI945Keys';

    elements
    {
        dataitem(SourceTable; "WSI0042 EDI945IBV2")
        {
            column(EDI945EDIOrderNo; "Order Number") { }
        }
    }
}

query 80203 "API - ItemKeys"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';
    EntityName = 'ItemKeys';
    EntitySetName = 'ItemKeys';

    elements
    {
        dataitem(SourceTable; "Item")
        {
            column(ItemNo; "No.") { }
        }
    }
}

query 80204 "API - PurchaseHeaderKeys"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';
    EntityName = 'PurchaseHeaderKeys';
    EntitySetName = 'PurchaseHeaderKeys';

    elements
    {
        dataitem(SourceTable; "Purchase Header")
        {
            column(PurchaseNo; "No.") { }
        }
    }
}

query 80205 "API - PurchaseInvoiceKeys"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';
    EntityName = 'PurchaseInvoiceKeys';
    EntitySetName = 'PurchaseInvoiceKeys';

    elements
    {
        dataitem(SourceTable; "Purch. Inv. Header")
        {
            column(PurchaseInvoiceNo; "No.") { }
        }
    }
}

query 80206 "API - SalesHeaderKeys"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';
    EntityName = 'SalesHeaderKeys';
    EntitySetName = 'SalesHeaderKeys';

    elements
    {
        dataitem(SourceTable; "Sales Header")
        {
            column(SalesNo; "No.") { }
        }
    }
}

query 80207 "API - SalesInvoiceKeys"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';
    EntityName = 'SalesInvoiceKeys';
    EntitySetName = 'SalesInvoiceKeys';

    elements
    {
        dataitem(SourceTable; "Sales Invoice Header")
        {
            column(SalesInvoiceNo; "No.") { }
        }
    }
}

query 80208 "API - SalesShipmentKeys"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';
    EntityName = 'SalesShipmentKeys';
    EntitySetName = 'SalesShipmentKeys';

    elements
    {
        dataitem(SourceTable; "Sales Shipment Header")
        {
            column(ShipmentNo; "No.") { }
        }
    }
}

query 80209 "API - TransferHeaderKeys"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';
    EntityName = 'TransferHeaderKeys';
    EntitySetName = 'TransferHeaderKeys';

    elements
    {
        dataitem(SourceTable; "Transfer Header")
        {
            column(TransferNo; "No.") { }
        }
    }
}
query 80210 "API - PurchaseReceiptKeys"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';
    EntityName = 'ReceiptHeaderKeys';
    EntitySetName = 'ReceiptHeaderKeys';

    elements
    {
        dataitem(SourceTable; "Purch. Rcpt. Header")
        {
            column(ReceiptNo; "No.") { }
        }
    }
}
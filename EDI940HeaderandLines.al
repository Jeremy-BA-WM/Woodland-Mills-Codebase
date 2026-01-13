query 80050 "API - 940HeaderandLines"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';

    EntityName = 'EDI940HeaderandLines';     // singular
    EntitySetName = 'EDI940HeaderandLines';    // plural

    elements
    {
        dataitem(WSI0042_EDI940OB; "WSI0042 EDI940OB")
        {
            // Header columns
            column(HeaderId; SystemId) { }
            column(HeaderNo; "WSI OriginalSONumber") { }
            column(HeaderEDIOrderNo; "Order Number") { }
            column(HeaderCustomerName; ShipToName) { }
            column(HeaderCustomerNo; "ID Code") { }
            column(HeaderShipmentAgent; "Shipping Agent") { }
            column(HeaderSCAC; "SCAC") { }
            column(HeaderRequestedDeliveryDate; RequestedDeliveryDate) { }
            column(HeaderDocumentType; DocType) { }
            column(HeaderStatus; Status) { }
            column(HeaderLocation_Code; LocationCode) { }

            // Header audit columns
            column(HeaderCreatedAt; SystemCreatedAt) { }
            column(HeaderCreatedBy; SystemCreatedBy) { }
            column(HeaderModifiedAt; SystemModifiedAt) { }
            column(HeaderModifiedBy; SystemModifiedBy) { }

            dataitem(WSI0042_EDI940OB_Lines; "WSI0042 EDI940OB Lines")
            {
                DataItemLink = "Order Number" = WSI0042_EDI940OB."Order Number";
                // Join lines to header


                // (Optional) restrict to Item lines only:
                // filter(ItemOnly; Type) = const(Item);

                // Line columns
                column(LineId; SystemId) { }
                column(LineItemNo; ItemNum) { }
                column(LineQuantity; QTY) { }
                column(LineEDIOrderNo; "Order Number") { }

                // Line audit columns
                column(LineCreatedAt; SystemCreatedAt) { }
                column(LineCreatedBy; SystemCreatedBy) { }
                column(LineModifiedAt; SystemModifiedAt) { }
                column(LineModifiedBy; SystemModifiedBy) { }

            }
        }
    }
}
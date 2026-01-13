query 80070 "API - 945HeaderandLines"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';

    EntityName = 'EDI945HeaderandLines';     // singular
    EntitySetName = 'EDI945HeaderandLines';    // plural

    elements
    {
        dataitem(WSI0042_EDI945IBV2; "WSI0042 EDI945IBV2")
        {
            // Header columns
            column(HeaderId; SystemId) { }
            column(HeaderEDIOrderNo; "Order Number") { }
            column(HeaderTrackingNo; "Shipment Identification Num1") { }
            column(HeaderSCAC; "Shipping Agent") { }
            column(HeaderShipmentDate; "Shipment Date") { }
            column(HeaderDocumentType; DocType) { }
            column(HeaderStatus; Status) { }
            column(HeaderTradingPartner; ShipFrom) { }



            // Header audit columns
            column(HeaderCreatedAt; SystemCreatedAt) { }
            column(HeaderCreatedBy; SystemCreatedBy) { }
            column(HeaderModifiedAt; SystemModifiedAt) { }
            column(HeaderModifiedBy; SystemModifiedBy) { }

            dataitem(WSI0042_EDI945IB_Lines_V2; "WSI0042 EDI945IB Lines V2")
            {
                DataItemLink = "Order Number" = WSI0042_EDI945IBV2."Order Number";
                // Join lines to header


                // (Optional) restrict to Item lines only:
                // filter(ItemOnly; Type) = const(Item);

                // Line columns
                column(LineId; SystemId) { }
                column(LineItemNo; "Item No.") { }
                column(LineQuantity; "Quantity Shipped") { }
                column(LineEDIOrderNo; "Order Number") { }
                column(LineLotNo; LotNo) { }

                // Line audit columns
                column(LineCreatedAt; SystemCreatedAt) { }
                column(LineCreatedBy; SystemCreatedBy) { }
                column(LineModifiedAt; SystemModifiedAt) { }
                column(LineModifiedBy; SystemModifiedBy) { }

            }
        }
    }
}
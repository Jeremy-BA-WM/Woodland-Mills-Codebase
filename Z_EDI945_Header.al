query 80528 "API - 945 Header"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';

    EntityName = 'Z_EDI945Header';     // singular
    EntitySetName = 'Z_EDI945Headers';    // plural

    elements
    {
        dataitem(WSI0042_EDI945IBV2; "WSI0042 EDI945IBV2")
        {
            // Header columns
            column(Id; SystemId) { }
            column(EDISalesNo; "Order Number") { }
            column(TrackingNo; "Shipment Identification Num1") { }
            column(SCAC; "Shipping Agent") { }
            column(ISA_ID; ISAID) { }
            column(GS_ID; GSID) { }
            column(ShipmentDate; "Shipment Date") { }
            column(DocumentType; DocType) { }
            column(Status; Status) { }
            column(TradingPartner; ShipFrom) { }

            // Header audit columns
            column(CreatedAt; SystemCreatedAt) { }
            column(CreatedBy; SystemCreatedBy) { }
            column(ModifiedAt; SystemModifiedAt) { }
            column(ModifiedBy; SystemModifiedBy) { }

        }
    }
}
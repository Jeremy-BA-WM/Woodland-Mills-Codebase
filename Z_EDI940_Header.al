query 80526 "API - 940 Header"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';

    EntityName = 'Z_EDI940Header';     // singular
    EntitySetName = 'Z_EDI940Headers';    // plural

    elements
    {
        dataitem(WSI0042_EDI940OB; "WSI0042 EDI940OB")
        {
            // Header columns
            column(Id; SystemId) { }
            column(SalesNo; "WSI OriginalSONumber") { }
            column(EDISalesNo; "Order Number") { }
            column(CustomerName; ShipToName) { }
            column(CustomerNo; "ID Code") { }
            column(ISA_ID; ISAID) { }
            column(GS_ID; GSID) { }
            column(ShipmentAgent; "Shipping Agent") { }
            column(SCAC; "SCAC") { }
            column(RequestedDeliveryDate; RequestedDeliveryDate) { }
            column(DocumentType; DocType) { }
            column(Status; Status) { }
            column(LocationNo; LocationCode) { }
            column(Street1; ShipToAdd1) { }
            column(Street2; ShipToAdd2) { }
            column(City; ShipToCity) { }
            column(Country; ShipToCountry) { }
            column(ZIP; ShipToPCode) { }
            column(Email; ShipToEmail) { }
            column(Phone; ShipToPhone) { }
            column(Notes; Notes) { }
            column(Reference; Reference1) { }

            // Header audit columns
            column(CreatedAt; SystemCreatedAt) { }
            column(CreatedBy; SystemCreatedBy) { }
            column(ModifiedAt; SystemModifiedAt) { }
            column(ModifiedBy; SystemModifiedBy) { }

        }
    }
}
query 80503 "API - Transfer Header"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';

    EntityName = 'Z_TransferHeader';     // singular
    EntitySetName = 'Z_TransferHeaders';    // plural

    elements
    {
        dataitem(Transfer_Header; "Transfer Header")
        {
            // Header columns
            column(Id; SystemId) { }
            column(TransferNo; "No.") { }
            column(TransferFrom; "Transfer-from Code") { }
            column(TransferTo; "Transfer-to Code") { }
            column(ShipmentMethod; "Shipment Method Code") { }
            column(PostingDate; "Posting Date") { }
            column(Status; Status) { }
            // Header audit columns
            column(CreatedAt; SystemCreatedAt) { }
            column(CreatedBy; SystemCreatedBy) { }
            column(ModifiedAt; SystemModifiedAt) { }
            column(ModifiedBy; SystemModifiedBy) { }

        }
    }
}
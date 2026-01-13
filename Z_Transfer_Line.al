query 80504 "API - Transfer Line"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';

    EntityName = 'Z_TransferLine';     // singular
    EntitySetName = 'Z_TransferLines';    // plural

    elements
    {
        dataitem(Transfer_Line; "Transfer Line")
        {
            // Header columns
            column(Id; SystemId) { }
            column(TransferNo; "Document No.") { }
            column(ItemNo; "Item No.") { }
            column(QTY; Quantity) { }
            column(TransferFromCode; "Transfer-from Code") { }
            column(TransferToCode; "Transfer-to Code") { }
            column(OutstandingQTY; "Outstanding Quantity") { }
            column(QTYReceived; "Quantity Received") { }
            column(QTYShipped; "Quantity Shipped") { }

            // Header audit columns
            column(CreatedAt; SystemCreatedAt) { }
            column(CreatedBy; SystemCreatedBy) { }
            column(ModifiedAt; SystemModifiedAt) { }
            column(ModifiedBy; SystemModifiedBy) { }
        }
    }
}
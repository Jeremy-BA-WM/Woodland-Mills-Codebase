query 80520 "API - Item Ledger Entries"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';

    EntityName = 'Z_ItemLedgerEntry';     // singular
    EntitySetName = 'Z_ItemLedgerEntries';    // plural

    elements
    {
        dataitem(Item_Ledger_Entry; "Item Ledger Entry")
        {
            // Header columns
            column(Id; SystemId) { }
            column(EntryNumber; "Entry No.") { }
            column(ItemNo; "Item No.") { }
            column(PostingDate; "Posting Date") { }
            column(EntryType; "Entry Type") { }
            column(SourceNo; "Source No.") { }
            column(DocumentNo; "Document No.") { }
            column(DocumentType; "Document Type") { }
            column(LocationNo; "Location Code") { }
            column(Positive; Positive) { }
            column(SourceType; "Source Type") { }
            column(NoSeries; "No. Series") { }
            column(CostAmount; "Cost Amount (Actual)") { }
            column(SalesAmount; "Sales Amount (Actual)") { }
            column(QTY; "Quantity") { }

            // Header audit columns
            column(CreatedAt; SystemCreatedAt) { }
            column(CreatedBy; SystemCreatedBy) { }
            column(ModifiedAt; SystemModifiedAt) { }
            column(ModifiedBy; SystemModifiedBy) { }
        }
    }
}
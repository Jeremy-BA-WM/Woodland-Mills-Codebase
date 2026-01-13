query 80080 "API - ItemLedgerEntries"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';

    EntityName = 'ItemLedgerEntries';     // singular
    EntitySetName = 'ItemLedgerEntries';    // plural

    elements
    {
        dataitem(Item_Ledger_Entry; "Item Ledger Entry")
        {
            // Header columns
            column(HeaderId; SystemId) { }
            column(HeaderEntryNumber; "Entry No.") { }
            column(HeaderItemNo; "Item No.") { }
            column(HeaderPostingDate; "Posting Date") { }
            column(HeaderEntryType; "Entry Type") { }
            column(HeaderSourceNo; "Source No.") { }
            column(HeaderDocumentNo; "Document No.") { }
            column(HeaderDocumentType; "Document Type") { }
            column(HeaderLocation_Code; "Location Code") { }
            column(HeaderPositive; Positive) { }
            column(HeaderSourceType; "Source Type") { }
            column(HeaderNoSeries; "No. Series") { }
            column(HeaderCostAmount; "Cost Amount (Actual)") { }
            column(HeaderSalesAmount; "Sales Amount (Actual)") { }
            column(HeaderQuantity; "Quantity") { }

            // Header audit columns
            column(HeaderCreatedAt; SystemCreatedAt) { }
            column(HeaderCreatedBy; SystemCreatedBy) { }
            column(HeaderModifiedAt; SystemModifiedAt) { }
            column(HeaderModifiedBy; SystemModifiedBy) { }
        }
    }
}
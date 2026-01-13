query 80529 "API - 945 Line"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';

    EntityName = 'Z_EDI945Line';     // singular
    EntitySetName = 'Z_EDI945Lines';    // plural

    elements
    {
        dataitem(WSI0042_EDI945IB_Lines_V2; "WSI0042 EDI945IB Lines V2")
        {
            // Header columns
            column(Id; SystemId) { }
            column(ItemNo; "Item No.") { }
            column(QTY; "Quantity Shipped") { }
            column(ISA_ID; ISAID) { }
            column(GS_ID; GSID) { }
            column(EDISalesNo; "Order Number") { }
            column(LotNo; LotNo) { }

            // Header audit columns
            column(CreatedAt; SystemCreatedAt) { }
            column(CreatedBy; SystemCreatedBy) { }
            column(ModifiedAt; SystemModifiedAt) { }
            column(ModifiedBy; SystemModifiedBy) { }
        }
    }
}
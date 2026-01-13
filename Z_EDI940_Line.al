query 80527 "API - 940 Line"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';

    EntityName = 'Z_EDI940Line';     // singular
    EntitySetName = 'Z_EDI940Lines';    // plural

    elements
    {
        dataitem(WSI0042_EDI940OB_Lines; "WSI0042 EDI940OB Lines")
        {
            // Header columns
            column(Id; SystemId) { }
            column(ItemNo; ItemNum) { }
            column(QTY; QTY) { }
            column(ISA_ID; ISAID) { }
            column(GS_ID; GSID) { }
            column(EDISalesNo; "Order Number") { }

            // Header audit columns
            column(CreatedAt; SystemCreatedAt) { }
            column(CreatedBy; SystemCreatedBy) { }
            column(ModifiedAt; SystemModifiedAt) { }
            column(ModifiedBy; SystemModifiedBy) { }
        }
    }
}
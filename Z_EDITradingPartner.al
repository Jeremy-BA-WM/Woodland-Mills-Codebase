query 80532 "API - EDITradingPartner"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';

    EntityName = 'Z_EDITradingPartner';     // singular
    EntitySetName = 'Z_EDITradingPartners';    // plural

    elements
    {
        dataitem(WSI0042_Trading_Partners; "WSI0042 Trading Partners")
        {
            // Header columns

            column(TPID; TPID) { }
            column(ISA_ID; "ISA ID") { }
            column(GS_ID; "GS ID") { }
            column(LocationNo; Name) { }

            // Header audit columns
            column(CreatedAt; SystemCreatedAt) { }
            column(CreatedBy; SystemCreatedBy) { }
            column(ModifiedAt; SystemModifiedAt) { }
            column(ModifiedBy; SystemModifiedBy) { }
        }
    }
}
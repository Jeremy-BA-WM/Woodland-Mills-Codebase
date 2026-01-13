query 80505 "API - Territory"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';

    EntityName = 'Z_Territory';     // singular
    EntitySetName = 'Z_Territories';    // plural

    elements
    {
        dataitem(Territory; "Territory")
        {
            // Header columns

            column(Id; SystemId) { }
            column(No; code) { }
            column(LocationNo; Name) { }

            // Header audit columns
            column(CreatedAt; SystemCreatedAt) { }
            column(CreatedBy; SystemCreatedBy) { }
            column(ModifiedAt; SystemModifiedAt) { }
            column(ModifiedBy; SystemModifiedBy) { }
        }
    }
}
query 80180 "API - Territories"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';

    EntityName = 'Territory';     // singular
    EntitySetName = 'Territories';    // plural

    elements
    {
        dataitem(Territory; "Territory")
        {
            // Header columns
            column(HeaderNo; code) { }
            column(HeaderLocation; Name) { }

            // Header audit columns
            column(HeaderCreatedAt; SystemCreatedAt) { }
            column(HeaderCreatedBy; SystemCreatedBy) { }
            column(HeaderModifiedAt; SystemModifiedAt) { }
            column(HeaderModifiedBy; SystemModifiedBy) { }
        }
    }
}
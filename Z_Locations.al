query 80519 "API - Location"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';

    EntityName = 'Z_Location';     // singular
    EntitySetName = 'Z_Locations';    // plural

    elements
    {
        dataitem(Location; Location)
        {
            // Header columns
            column(LocationNo; code) { }
            column(Name; Name) { }
            column(Address; Address) { }
            column(City; City) { }
            column(Country; "Country/Region Code") { }
            column(State; "County") { }
            column(ZIP; "Post Code") { }
            column(EDITradingPartner; "WSI0042 TradingPartner") { }

            // Header audit columns
            column(CreatedAt; SystemCreatedAt) { }
            column(CreatedBy; SystemCreatedBy) { }
            column(ModifiedAt; SystemModifiedAt) { }
            column(ModifiedBy; SystemModifiedBy) { }
        }
    }
}
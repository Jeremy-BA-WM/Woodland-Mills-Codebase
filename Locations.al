query 80150 "API - Locations"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';

    EntityName = 'Location';     // singular
    EntitySetName = 'Locations';    // plural

    elements
    {
        dataitem(Location; "Location")
        {
            // Header columns
            column(HeaderNo; code) { }
            column(HeaderName; Name) { }
            column(HeaderAddress; Address) { }
            column(HeaderCity; City) { }
            column(HeaderCountry; "Country/Region Code") { }
            column(HeaderState; "County") { }
            column(HeaderPostCode; "Post Code") { }
            column(HeaderEDITradingPartner; "WSI0042 TradingPartner") { }

            // Header audit columns
            column(HeaderCreatedAt; SystemCreatedAt) { }
            column(HeaderCreatedBy; SystemCreatedBy) { }
            column(HeaderModifiedAt; SystemModifiedAt) { }
            column(HeaderModifiedBy; SystemModifiedBy) { }
        }
    }
}
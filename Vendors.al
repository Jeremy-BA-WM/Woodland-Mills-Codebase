query 80140 "API - Vendors"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';

    EntityName = 'Vendor';     // singular
    EntitySetName = 'Vendors';    // plural

    elements
    {
        dataitem(Vendor; "Vendor")
        {
            // Header columns
            column(HeaderNo; "No.") { }
            column(HeaderName; "Search Name") { }
            column(HeaderVendorPostingGroup; "Vendor Posting Group") { }
            column(HeaderCurrencyCode; "Currency Code") { }
            column(HeaderCountry; "Country/Region Code") { }
            column(HeaderState; "County") { }
            column(HeaderBalanceLCY; Balance) { }
            column(HeaderBalanceOG; "WSI Balance (OG)") { }
            column(HeaderTerms; "Payment Terms Code") { }

            // Header audit columns
            column(HeaderCreatedAt; SystemCreatedAt) { }
            column(HeaderCreatedBy; SystemCreatedBy) { }
            column(HeaderModifiedAt; SystemModifiedAt) { }
            column(HeaderModifiedBy; SystemModifiedBy) { }
        }
    }
}
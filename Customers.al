query 80130 "API - Customers"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';

    EntityName = 'Customers';     // singular
    EntitySetName = 'Customers';    // plural

    elements
    {
        dataitem(Customer; "Customer")
        {
            // Header columns
            column(HeaderNo; "No.") { }
            column(HeaderName; "Search Name") { }
            column(HeaderCustomerPostingGroup; "Customer Posting Group") { }
            column(HeaderCustomerPriceGroup; "Customer Price Group") { }
            column(HeaderCurrencyCode; "Currency Code") { }
            column(HeaderCountry; "Country/Region Code") { }
            column(HeaderState; "County") { }
            column(HeaderBalanceLCY; Balance) { }
            column(HeaderBalanceOG; "WSI Balance (OG)") { }

            // Header audit columns
            column(HeaderCreatedAt; SystemCreatedAt) { }
            column(HeaderCreatedBy; SystemCreatedBy) { }
            column(HeaderModifiedAt; SystemModifiedAt) { }
            column(HeaderModifiedBy; SystemModifiedBy) { }
        }
    }
}
query 80524 "API - Customer"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';

    EntityName = 'Z_Customer';     // singular
    EntitySetName = 'Z_Customers';    // plural

    elements
    {
        dataitem(Customer; "Customer")
        {
            // Header columns
            column(CustomerNo; "No.") { }
            column(Name; "Search Name") { }
            column(CustomerPostingGroup; "Customer Posting Group") { }
            column(CustomerPriceGroup; "Customer Price Group") { }
            column(CurrencyCode; "Currency Code") { }
            column(Country; "Country/Region Code") { }
            column(State; "County") { }
            column(BalanceLCY; Balance) { }
            column(BalanceOG; "WSI Balance (OG)") { }

            // Header audit columns
            column(CreatedAt; SystemCreatedAt) { }
            column(CreatedBy; SystemCreatedBy) { }
            column(ModifiedAt; SystemModifiedAt) { }
            column(ModifiedBy; SystemModifiedBy) { }
        }
    }
}
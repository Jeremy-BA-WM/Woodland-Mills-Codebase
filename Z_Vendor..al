query 80502 "API - Vendor"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';

    EntityName = 'Z_Vendor';     // singular
    EntitySetName = 'Z_Vendors';    // plural

    elements
    {
        dataitem(Vendor; "Vendor")
        {
            column(Id; SystemId) { }            // Header columns
            column(VendorNo; "No.") { }
            column(VendorName; "Search Name") { }
            column(VendorPostingGroup; "Vendor Posting Group") { }
            column(CurrencyCode; "Currency Code") { }
            column(Country; "Country/Region Code") { }
            column(State; "County") { }
            column(LocationNo; "Location Code") { }
            column(BalanceLCY; Balance) { }
            column(BalanceOG; "WSI Balance (OG)") { }
            column(PaymentTerms; "Payment Terms Code") { }

            // Header audit columns
            column(CreatedAt; SystemCreatedAt) { }
            column(CreatedBy; SystemCreatedBy) { }
            column(ModifiedAt; SystemModifiedAt) { }
            column(ModifiedBy; SystemModifiedBy) { }
        }
    }
}
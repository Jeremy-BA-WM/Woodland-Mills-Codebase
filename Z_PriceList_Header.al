query 80517 "API - PriceList Header"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';

    EntityName = 'Z_PriceListHeader';     // singular
    EntitySetName = 'Z_PriceListHeaders';    // plural

    elements
    {
        dataitem(Price_List_Header; "Price List Header")
        {
            // Header columns
            column(PriceListNo; code) { }
            column(SourceGroup; "Source Group") { }
            column(Description; "Description") { }
            column(CurrencyCode; "Currency Code") { }
            column(AssignToNo; "Assign-to No.") { }

            // Header audit columns
            column(CreatedAt; SystemCreatedAt) { }
            column(CreatedBy; SystemCreatedBy) { }
            column(ModifiedAt; SystemModifiedAt) { }
            column(ModifiedBy; SystemModifiedBy) { }

        }
    }
}
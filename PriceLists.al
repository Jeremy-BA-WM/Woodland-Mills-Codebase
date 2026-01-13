query 80041 "API - PriceLists"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';

    EntityName = 'PriceLists';     // singular
    EntitySetName = 'PriceLists';    // plural

    elements
    {
        dataitem(Price_List_Header; "Price List Header")
        {
            // Header columns
            column(HeaderCode; code) { }
            column(HeaderSourceGroup; "Source Group") { }
            column(HeaderDescription; "Description") { }
            column(HeaderCurrencyCode; "Currency Code") { }

            // Header audit columns
            column(HeaderCreatedAt; SystemCreatedAt) { }
            column(HeaderCreatedBy; SystemCreatedBy) { }
            column(HeaderModifiedAt; SystemModifiedAt) { }
            column(HeaderModifiedBy; SystemModifiedBy) { }

            dataitem(Price_List_Line; "Price List Line")
            {
                // Join lines to header
                DataItemLink = "Price List Code" = Price_List_Header.code;

                // Line columns
                column(LineId; SystemId) { }
                column(LineNo; "Asset No.") { }
                column(LineUnitPrice; "Unit Price") { }

                // Line audit columns   
                column(LineCreatedAt; SystemCreatedAt) { }
                column(LineCreatedBy; SystemCreatedBy) { }
                column(LineModifiedAt; SystemModifiedAt) { }
                column(LineModifiedBy; SystemModifiedBy) { }

            }
        }
    }
}
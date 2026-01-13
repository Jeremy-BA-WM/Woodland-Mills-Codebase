query 80100 "API - DemandForecast"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';

    EntityName = 'DemandForecast';     // singular
    EntitySetName = 'DemandForecasts';    // plural

    elements
    {
        dataitem(Production_Forecast_Entry; "Production Forecast Entry")
        {
            // Header columns
            column(HeaderItemNo; "Item No.") { }
            column(HeaderForecastDate; "Forecast Date") { }
            column(HeaderForecastQTY; "Forecast Quantity") { }
            column(HeaderLocation_Code; "Location Code") { }
            column(HeaderForecastName; "Production Forecast Name") { }
            column(HeaderQTY; "Qty. per Unit of Measure") { }

            // Header audit columns
            column(HeaderCreatedAt; SystemCreatedAt) { }
            column(HeaderCreatedBy; SystemCreatedBy) { }
            column(HeaderModifiedAt; SystemModifiedAt) { }
            column(HeaderModifiedBy; SystemModifiedBy) { }
        }
    }
}
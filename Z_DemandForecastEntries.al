query 80525 "API - Demand Forecast"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';

    EntityName = 'Z_DemandForecast';     // singular
    EntitySetName = 'Z_DemandForecasts';    // plural

    elements
    {
        dataitem(Production_Forecast_Entry; "Production Forecast Entry")
        {
            // Header columns
            column(ItemNo; "Item No.") { }
            column(ForecastDate; "Forecast Date") { }
            column(ForecastQTY; "Forecast Quantity") { }
            column(LocationNo; "Location Code") { }
            column(ForecastName; "Production Forecast Name") { }
            column(QTY; "Qty. per Unit of Measure") { }

            // Header audit columns
            column(CreatedAt; SystemCreatedAt) { }
            column(CreatedBy; SystemCreatedBy) { }
            column(ModifiedAt; SystemModifiedAt) { }
            column(ModifiedBy; SystemModifiedBy) { }
        }
    }
}
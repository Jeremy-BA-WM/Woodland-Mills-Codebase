query 80521 "Item Dimensions Detailed"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';

    EntityName = 'Z_DefaultDimension';     // singular
    EntitySetName = 'Z_DefaultDimensions';    // plural
    elements
    {
        dataitem(DefaultDim; "Default Dimension")
        {
            // Only include dimensions for the Item table (Table ID = 27)
            DataItemTableFilter = "Table ID" = const(27);

            column(ItemNo; "No.") { }
            column(DimensionCode; "Dimension Code") { }
            column(DimensionValueCode; "Dimension Value Code") { }
            column(SystemCreatedAt; SystemCreatedAt) { }
            column(SystemCreatedBy; SystemCreatedBy) { }
            column(SystemModifiedAt; SystemModifiedAt) { }
            column(SystemModifiedBy; SystemModifiedBy) { }

            dataitem(DimValue; "Dimension Value")
            {
                DataItemLink = "Dimension Code" = DefaultDim."Dimension Code",
                               "Code" = DefaultDim."Dimension Value Code";

                column(DimensionValueName; Name) { }
            }
        }
    }
}

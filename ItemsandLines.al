query 80162 "API - ItemsandLines"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';

    EntityName = 'ItemsandLines';
    EntitySetName = 'ItemsandLines';

    elements
    {
        dataitem(Item; Item)
        {
            column(HeaderId; SystemId) { }
            column(HeaderNo; "No.") { }
            column(HeaderDescription; "Search Description") { }
            column(HeaderAssemblyBOM; "Assembly BOM") { }
            column(HeaderType; "Inventory") { }
            column(HeaderUnitCost; "Unit Cost") { }
            column(HeaderCategory; "Item Category Code") { }
            column(HeaderVendorNo; "Vendor No.") { }
            column(HeaderGrossWeight; "Gross Weight") { }
            column(HeaderTariffNo; "Tariff No.") { }
            column(HeaderInventory; "Inventory") { }
            column(HeaderQTYonSO; "Qty. on Sales Order") { }
            column(HeaderQTYonPO; "Qty. on Purch. Order") { }
            column(HeaderCountryofOrigin; "Country/Region of Origin Code") { }
            column(HeaderLotTracking; "Item Tracking Code") { }
            column(HeaderSalesBlocked; "Sales Blocked") { }
            column(HeaderPurchasingBlocked; "Purchasing Blocked") { }
            column(HeaderNMFC; "IW LTL Freight NMFC Class") { }
            column(HeaderFreightClass; "IW LTL Freight NMFC Class") { }

            column(HeaderCreatedAt; SystemCreatedAt) { }
            column(HeaderCreatedBy; SystemCreatedBy) { }
            column(HeaderModifiedAt; SystemModifiedAt) { }
            column(HeaderModifiedBy; SystemModifiedBy) { }

            // Nest Item_Unit_of_Measure and Default_Dimension inside Item dataitem
            dataitem(Item_Unit_of_Measure; "Item Unit of Measure")
            {
                DataItemLink = "Item No." = Item."No.";

                column(LineUOM_Code; Code) { }
                column(LineUOM_Length; Length) { }
                column(LineUOM_Width; Width) { }
                column(LineUOM_Height; Height) { }
                column(LineUOM_Weight; Weight) { }
                column(LineUOM_Cubage; Cubage) { }
                column(LineUOM_QtyperUnitofMeasure; "Qty. per Unit of Measure") { }

                column(LineUOM_CreatedAt; SystemCreatedAt) { }
                column(LineUOM_CreatedBy; SystemCreatedBy) { }
                column(LineUOM_ModifiedAt; SystemModifiedAt) { }
                column(LineUOM_ModifiedBy; SystemModifiedBy) { }

                dataitem(Default_Dimension; "Default Dimension")
                {
                    DataItemLink = "No." = Item."No.";

                    column(LineDimCode; "Dimension Code") { }
                    column(LineDimValueCode; "Dimension Value Code") { }
                    column(LineDimName; "Dimension Value Name") { }
                    column(LineDim_No; "No.") { }

                    column(LineDim_CreatedAt; SystemCreatedAt) { }
                    column(LineDim_CreatedBy; SystemCreatedBy) { }
                    column(LineDim_ModifiedAt; SystemModifiedAt) { }
                    column(LineDim_ModifiedBy; SystemModifiedBy) { }

                    dataitem(Item_Substitution; "Item Substitution")
                    {
                        DataItemLink = "No." = Item."No.";

                        column(LineSubItemNo; "Substitute No.") { }
                        column(LineSubDescription; Description) { }
                        column(LineSubInterchangeable; Interchangeable) { }

                        column(LineSub_CreatedAt; SystemCreatedAt) { }
                        column(LineSub_CreatedBy; SystemCreatedBy) { }
                        column(LineSub_ModifiedAt; SystemModifiedAt) { }
                        column(LineSub_ModifiedBy; SystemModifiedBy) { }

                    }
                }
            }
        }
    }
}
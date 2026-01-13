query 80501 "API - Item"
{
    QueryType = API;
    APIPublisher = 'woodlandmills';
    APIGroup = 'custom';
    APIVersion = 'v2.0';

    EntityName = 'Z_Item';
    EntitySetName = 'Items';

    elements
    {
        dataitem(Item; Item)
        {
            column(Id; SystemId) { }
            column(ItemNo; "No.") { }
            column(ItemDesc; "Search Description") { }
            column(ItemAssyBOM; "Assembly BOM") { }
            column(ItemType; "Inventory") { }
            column(ItemRevID; "Revision ID") { }
            column(ItemLabelOutput; "Label Output") { }
            column(ItemUnitCost; "Unit Cost") { }
            column(ItemCategory; "Item Category Code") { }
            column(VendorNo; "Vendor No.") { }
            column(ItemGrossWeight; "Gross Weight") { }
            column(ItemTariffNo; "Tariff No.") { }
            column(ItemInventory; "Inventory") { }
            column(ItemQTYonSO; "Qty. on Sales Order") { }
            column(ItemQTYonPO; "Qty. on Purch. Order") { }
            column(ItemCountryofOrigin; "Country/Region of Origin Code") { }
            column(ItemLotTracking; "Item Tracking Code") { }
            column(ItemSalesBlocked; "Sales Blocked") { }
            column(ItemPurchasingBlocked; "Purchasing Blocked") { }
            column(ItemNMFC; "IW LTL Freight NMFC Class") { }
            column(ItemFreightClass; "IW LTL Freight NMFC Class") { }

            column(CreatedAt; SystemCreatedAt) { }
            column(CreatedBy; SystemCreatedBy) { }
            column(ModifiedAt; SystemModifiedAt) { }
            column(ModifiedBy; SystemModifiedBy) { }

            // Nest Item_Unit_of_Measure and Default_Dimension inside Item dataitem
            dataitem(Item_Unit_of_Measure; "Item Unit of Measure")
            {
                DataItemLink = "Item No." = Item."No.";

                column(UOMCode; Code) { }
                column(UOMLength; Length) { }
                column(UOMWidth; Width) { }
                column(UOMHeight; Height) { }
                column(UOMWeight; Weight) { }
                column(UOMCubage; Cubage) { }
                column(UOMQtyperUOM; "Qty. per Unit of Measure") { }

                column(UOMCreatedAt; SystemCreatedAt) { }
                column(UOMCreatedBy; SystemCreatedBy) { }
                column(UOMModifiedAt; SystemModifiedAt) { }
                column(UOMModifiedBy; SystemModifiedBy) { }

                dataitem(Item_Substitution; "Item Substitution")
                {
                    DataItemLink = "No." = Item."No.";

                    column(SubItemNo; "Substitute No.") { }
                    column(SubDesc; Description) { }
                    column(SubInterchangeable; Interchangeable) { }

                    column(SubCreatedAt; SystemCreatedAt) { }
                    column(SubCreatedBy; SystemCreatedBy) { }
                    column(SubModifiedAt; SystemModifiedAt) { }
                    column(SubModifiedBy; SystemModifiedBy) { }

                }
            }
        }
    }
}
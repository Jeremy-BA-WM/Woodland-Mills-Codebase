table 89697 "WLM Item Load Fit"
{
    Caption = 'WLM Item Load Fit';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Parent Load Unit Code"; Code[10]) { Caption = 'Parent Load Unit Code'; TableRelation = "WLM Order Loading Unit".Code; }
        field(2; "Item No."; Code[20]) { Caption = 'Item No.'; TableRelation = Item."No."; }
        field(11; "Child Load Unit Code"; Code[10]) { Caption = 'Child Load Unit'; TableRelation = "WLM Order Loading Unit".Code; }
        field(3; "Units Per Parent"; Decimal) { Caption = 'Units Per Parent'; DecimalPlaces = 0 : 5; }
        field(4; "Units Per Lane"; Decimal) { Caption = 'Units Per Lane'; DecimalPlaces = 0 : 5; }
        field(5; "Lane Count"; Integer) { Caption = 'Lane Count'; }
        field(6; "Height Slots"; Integer) { Caption = 'Units/Stack'; }
        field(7; "Used Rotation"; Boolean) { Caption = 'Used Rotation'; }
        field(8; "Lane Width"; Decimal) { Caption = 'Lane Width'; DecimalPlaces = 0 : 5; }
        field(9; "Computed On"; DateTime) { Caption = 'Computed On'; }
        field(10; "Computed By"; Code[50]) { Caption = 'Computed By'; Editable = false; }
        field(20; "Usable Width %"; Decimal)
        {
            Caption = 'Usable Width %';
            DecimalPlaces = 0 : 5;
            ObsoleteState = Pending;
            ObsoleteReason = 'Maintained for upgrade compatibility';
        }
        field(21; "Usable Length %"; Decimal)
        {
            Caption = 'Usable Length %';
            DecimalPlaces = 0 : 5;
            ObsoleteState = Pending;
            ObsoleteReason = 'Maintained for upgrade compatibility';
        }
        field(22; "Usable Height %"; Decimal)
        {
            Caption = 'Usable Height %';
            DecimalPlaces = 0 : 5;
            ObsoleteState = Pending;
            ObsoleteReason = 'Maintained for upgrade compatibility';
        }
        field(30; "Width % Consumed"; Decimal) { Caption = 'Width % Consumed'; DecimalPlaces = 0 : 5; Editable = false; }
        field(31; "Length % Consumed"; Decimal) { Caption = 'Length % Consumed'; DecimalPlaces = 0 : 5; Editable = false; }
        field(32; "Height % Consumed"; Decimal) { Caption = 'Height % Consumed'; DecimalPlaces = 0 : 5; Editable = false; }
        field(33; "Volume % Consumed"; Decimal) { Caption = 'Volume % Consumed'; DecimalPlaces = 0 : 5; Editable = false; }
        field(34; "Total Weight"; Decimal) { Caption = 'Total Weight'; DecimalPlaces = 0 : 5; Editable = false; }
        field(35; "Units per Row"; Integer) { Caption = 'Units per Row'; Editable = false; }
        field(36; "No. of Rows"; Integer) { Caption = 'No. of Rows'; Editable = false; }
        field(37; "Enforce Order Multiples"; Boolean) { Caption = 'Enforce Order Multiples'; InitValue = true; }
        field(38; "Order Multiple"; Integer) { Caption = 'Order Multiple'; Editable = true; }
        field(25; "Aisle Width"; Decimal) { Caption = 'Aisle Width (Length Direction)'; DecimalPlaces = 0 : 5; InitValue = 0; }
        field(26; "Rows Lost"; Integer) { Caption = 'Tie-Down / Blocked Rows (Length)'; InitValue = 0; }
    }

    keys
    {
        key(PK; "Parent Load Unit Code", "Item No.") { Clustered = true; }
        key(ChildIdx; "Child Load Unit Code", "Parent Load Unit Code", "Item No.") { }
    }
}

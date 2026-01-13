table 89696 "WLM Load Suggestion"
{
    Caption = 'WLM Load Suggestion';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item."No.";
        }
        field(3; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location.Code;
        }
        field(4; "Required Date"; Date)
        {
            Caption = 'Required Date';
        }
        field(5; "Load Unit Code"; Code[10])
        {
            Caption = 'Load Unit Code';
            TableRelation = "WLM Order Loading Unit".Code;
        }
        field(6; "Sub Units"; Decimal)
        {
            Caption = 'Sub Units';
            DecimalPlaces = 0 : 5;
        }
        field(7; "Parent Units"; Decimal)
        {
            Caption = 'Parent Units';
            DecimalPlaces = 0 : 5;
        }
        field(8; "Priority Score"; Decimal)
        {
            Caption = 'Priority Score';
            DecimalPlaces = 0 : 5;
        }
        field(9; "Shortage Date"; Date)
        {
            Caption = 'Shortage Date';
        }
        field(10; Status; Option)
        {
            Caption = 'Status';
            OptionMembers = Open,Released,Skipped;
            InitValue = Open;
        }
        field(16; "Suggestion Type"; Enum "WLM Load Suggestion Type")
        {
            Caption = 'Suggestion Type';
            DataClassification = CustomerContent;
        }
        field(17; "Source Location Code"; Code[10])
        {
            Caption = 'Source Location Code';
            TableRelation = Location.Code;
        }
        field(18; "Source Vendor No."; Code[20])
        {
            Caption = 'Source Vendor No.';
            TableRelation = Vendor."No.";
        }
        field(20; "Created At"; DateTime)
        {
            Caption = 'Created At';
            Editable = false;
        }
        field(21; "Created By"; Code[50])
        {
            Caption = 'Created By';
            Editable = false;
        }
        field(22; "Release Date"; Date)
        {
            Caption = 'Release Date';
        }
        field(23; "Load Group ID"; Guid)
        {
            Caption = 'Load Group ID';
            Editable = false;
        }
        field(24; "Proposed Document No."; Text[30])
        {
            Caption = 'Proposed Document';
            Editable = false;
        }
        field(25; "Load Batch No."; Code[20])
        {
            Caption = 'Load Batch No.';
            FieldClass = FlowField;
            CalcFormula = lookup("WLM Load Batch"."Batch No." where("Load Group ID" = field("Load Group ID")));
            Editable = false;
        }
        field(26; "Load Profile Code"; Code[20])
        {
            Caption = 'Load Profile Code';
            FieldClass = FlowField;
            CalcFormula = lookup("WLM Load Batch"."Profile Code" where("Load Group ID" = field("Load Group ID")));
            Editable = false;
        }
        field(30; "Units per Sub Unit"; Integer)
        {
            Caption = 'Units per Sub Unit';
            FieldClass = FlowField;
            CalcFormula = lookup("WLM Item Loading Unit"."Units per Sub Unit" where("Item No." = field("Item No.")));
            Editable = false;
        }
        field(40; "Requirement Month"; Integer)
        {
            Caption = 'Requirement Month';
            Description = 'Month number of requirement date (1-12) for period-based load grouping';
        }
        field(41; "Requirement Year"; Integer)
        {
            Caption = 'Requirement Year';
            Description = 'Year of requirement date for period-based load grouping';
        }
        field(42; "Requirement Period"; Text[10])
        {
            Caption = 'Requirement Period';
            Description = 'Combined YYYY-MM period for sorting and grouping';
        }
        field(43; "Pct of Parent Unit"; Decimal)
        {
            Caption = '% of Parent Unit';
            DecimalPlaces = 0 : 5;
            Description = 'Percentage or fraction of a parent loading unit this item represents';
        }
        field(44; "Cumulative Parent Units"; Decimal)
        {
            Caption = 'Cumulative Parent Units';
            DecimalPlaces = 0 : 5;
            Description = 'Running total of parent units in the load group for efficiency tracking';
        }
        field(45; "Load Efficiency Pct"; Decimal)
        {
            Caption = 'Load Efficiency %';
            DecimalPlaces = 0 : 2;
            Description = 'How efficiently packed the load group is (used capacity / total capacity)';
        }
        field(46; "Days Until Required"; Integer)
        {
            Caption = 'Days Until Required';
            Description = 'Number of days from workdate until required date';
        }
        field(47; "Month Priority Rank"; Integer)
        {
            Caption = 'Month Priority Rank';
            Description = 'Priority rank within month (1=current month highest priority)';
        }
        field(48; "Base Qty Required"; Decimal)
        {
            Caption = 'Base Qty Required';
            DecimalPlaces = 0 : 5;
            Description = 'Original quantity required in base units before load conversion';
        }
        field(50; "Urgency Level"; Option)
        {
            Caption = 'Urgency Level';
            OptionMembers = ParStock,BelowROP,Stockout;
            OptionCaption = 'Par Stock,Below ROP,Stockout';
            Description = 'Stockout=critical (balance negative), BelowROP=important (below reorder point), ParStock=secondary (rebuilding par)';
        }
        field(51; "Stockout Qty"; Decimal)
        {
            Caption = 'Stockout Qty';
            DecimalPlaces = 0 : 5;
            Description = 'Quantity causing stockout - highest priority to fill';
        }
        field(52; "Par Rebuild Qty"; Decimal)
        {
            Caption = 'Par Rebuild Qty';
            DecimalPlaces = 0 : 5;
            Description = 'Quantity needed to rebuild to par/reorder point - secondary priority';
        }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(StatusPriority; Status, "Priority Score") { }
        key(PeriodPriority; "Requirement Period", "Priority Score") { }
        key(MonthVendor; "Requirement Period", "Source Vendor No.", "Priority Score") { }
        key(MonthLocation; "Requirement Period", "Source Location Code", "Priority Score") { }
        key(UrgencyPriority; "Urgency Level", "Priority Score") { }
    }

    trigger OnInsert()
    begin
        if "Created At" = 0DT then
            "Created At" := CurrentDateTime;
        if "Created By" = '' then
            "Created By" := UserId;
    end;
}

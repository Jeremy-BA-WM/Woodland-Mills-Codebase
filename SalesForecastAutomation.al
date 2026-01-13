// ============================================================================
// WLM Advanced Item Planning — Cloud-safe Migration to v2 (Line No. PK)
// - Keep 89600 (original PK) as ObsoletePending; introduce 89601 with Line No. PK
// - All pages and codeunits point to 89601 (country-aware rows)
// - Restore old WB profile tables (89608/89609/89610) and 89640; mark Obsolete Removed/Pending
// - Unified WB Attribution table (89676)
// - Upgrade migrates data from 89600/89640 -> 89601
// - Deterministic Line Nos.: we assign in code (MAX+10000) and keep AutoIncrement=true
// - Region Map fast tab rename; Location Country FF on Region Map
// - Self rows = BLANK Related Item; Builder treats BLANK or A→A as self (compat)
// - Shortcut Dim FlowFields (GD1/2 + SD3..8 via Default Dimensions) on Planning & Forecast Entries
// - "Planning Filters" logic: plan all if Dimension Filter empty
// - "Use Region Location Mapping" per Filter Value cohort with routing in Builder
// - NEW: Date math hardened + cohort via Item Default Dimensions + returns suppression
// ============================================================================

// ======================= TABLES =======================
table 89600 "WLM Adv Item Planning"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by WLM Adv Item Planning v2 (table 89601) with Line No. PK and Location Country/Region per row. Data is migrated by upgrade.';
    Caption = 'Advanced Item Planning (Legacy)';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Item No."; Code[20]) { Caption = 'Item No.'; TableRelation = Item."No."; }
        field(2; "Related Item No."; Code[20]) { Caption = 'Related Item No.'; TableRelation = Item."No."; }
        field(3; "Contribution %"; Decimal) { Caption = 'Contribution %'; MinValue = 0; MaxValue = 100; InitValue = 100; }
        field(4; "Multiplier %"; Decimal) { Caption = 'Multiplier %'; MinValue = 0; MaxValue = 100000; InitValue = 100; }
        field(5; "Include Variants"; Boolean) { Caption = 'Include Variants'; }
        field(6; "Effective From"; Date) { Caption = 'Effective From'; }
        field(7; "Effective To"; Date) { Caption = 'Effective To'; }
        field(8; Active; Boolean) { Caption = 'Active'; InitValue = true; }
        field(9; "US Multiplier %"; Decimal)
        {
            Caption = 'US Multiplier %';
            ObsoleteState = Pending;
            ObsoleteReason = 'Legacy. Superseded by per-country rows in v2.';
            MinValue = 0;
            MaxValue = 100000;
            InitValue = 100;
        }
        field(10; "CA Multiplier %"; Decimal)
        {
            Caption = 'CA Multiplier %';
            ObsoleteState = Pending;
            ObsoleteReason = 'Legacy. Superseded by per-country rows in v2.';
            MinValue = 0;
            MaxValue = 100000;
            InitValue = 100;
        }
        field(50000; "SD1 Code FF"; Code[20]) { FieldClass = FlowFilter; }
        field(50001; "SD2 Code FF"; Code[20]) { FieldClass = FlowFilter; }
        field(50002; "SD3 Code FF"; Code[20]) { FieldClass = FlowFilter; }
        field(50003; "SD4 Code FF"; Code[20]) { FieldClass = FlowFilter; }
        field(50004; "SD5 Code FF"; Code[20]) { FieldClass = FlowFilter; }
        field(50005; "SD6 Code FF"; Code[20]) { FieldClass = FlowFilter; }
        field(50006; "SD7 Code FF"; Code[20]) { FieldClass = FlowFilter; }
        field(50007; "SD8 Code FF"; Code[20]) { FieldClass = FlowFilter; }
        field(50010; "Item Description FF"; Text[100])
        {
            Caption = 'Description';
            FieldClass = FlowField;
            CalcFormula = lookup(Item.Description where("No." = field("Item No.")));
        }
        field(50011; "Item Category Code FF"; Code[20])
        {
            Caption = 'Item Category Code';
            FieldClass = FlowField;
            CalcFormula = lookup(Item."Item Category Code" where("No." = field("Item No.")));
        }
        field(50012; "Vendor No. FF"; Code[20])
        {
            Caption = 'Vendor No.';
            FieldClass = FlowField;
            CalcFormula = lookup(Item."Vendor No." where("No." = field("Item No.")));
        }
        field(50100; "Use Workback Projection"; Boolean) { Caption = 'Use Workback Projection'; }
        field(50101; "US Workback Annual Projection"; Decimal)
        {
            Caption = 'US Workback Annual Projection';
            ObsoleteState = Pending;
            ObsoleteReason = 'Migrated to unified per-row Workback Annual on v2 by Country.';
        }
        field(50102; "CA Workback Annual Projection"; Decimal)
        {
            Caption = 'CA Workback Annual Projection';
            ObsoleteState = Pending;
            ObsoleteReason = 'Migrated to unified per-row Workback Annual on v2 by Country.';
        }
    }
    keys
    {
        key(PK; "Item No.", "Related Item No.") { Clustered = true; }
        key(ActiveIdx; "Item No.", Active, "Effective From") { }
    }
}

table 89601 "WLM Adv Item Planning v2"
{
    Caption = 'Advanced Item Planning';
    DataClassification = CustomerContent;
    fields
    {
        field(90000; "Line No."; Integer) { Caption = 'Line No.'; AutoIncrement = true; }
        field(1; "Item No."; Code[20]) { Caption = 'Item No.'; TableRelation = Item."No."; }
        field(2; "Related Item No."; Code[20]) { Caption = 'Related Item No.'; TableRelation = Item."No."; } // blank = self

        field(11; "Location Country/Region Code"; Code[10])
        {
            Caption = 'Location Country/Region';
            TableRelation = "Country/Region".Code;
        }
        field(12; "Par Stock Target"; Integer)
        {
            Caption = 'Par Stock Target (Months)';
            MinValue = 0;
            InitValue = 0;
        }

        field(13; "Use Region Location Mapping"; Boolean)
        {
            Caption = 'Use Region Location Mapping';
            ToolTip = 'Indicates whether this planning row should apply the Region → Location mapping.';
            InitValue = false;
        }

        field(14; "Factor Seasonality"; Boolean)
        {
            Caption = 'Factor Seasonality';
            ToolTip = 'Use stored seasonality for this item/country to fill gaps in demand when projecting.';
            InitValue = false;
            trigger OnValidate()
            begin
                if "Use Workback Projection" and (not "Factor Seasonality") then
                    Error('Factor Seasonality must remain enabled when Workback Projection is turned on.');
            end;
        }

        field(3; "Contribution %"; Decimal) { Caption = 'Contribution %'; MinValue = 0; MaxValue = 100; InitValue = 100; }
        field(4; "Multiplier %"; Decimal) { Caption = 'Multiplier %'; MinValue = 0; MaxValue = 100000; InitValue = 100; }
        field(5; "Include Variants"; Boolean) { Caption = 'Include Variants'; }
        field(6; "Effective From"; Date) { Caption = 'Effective From'; }
        field(7; "Effective To"; Date) { Caption = 'Effective To'; }
        field(8; Active; Boolean) { Caption = 'Active'; InitValue = true; }

        // FlowFilters (reserved)
        field(50000; "SD1 Code FF"; Code[20]) { FieldClass = FlowFilter; }
        field(50001; "SD2 Code FF"; Code[20]) { FieldClass = FlowFilter; }
        field(50002; "SD3 Code FF"; Code[20]) { FieldClass = FlowFilter; }
        field(50003; "SD4 Code FF"; Code[20]) { FieldClass = FlowFilter; }
        field(50004; "SD5 Code FF"; Code[20]) { FieldClass = FlowFilter; }
        field(50005; "SD6 Code FF"; Code[20]) { FieldClass = FlowFilter; }
        field(50006; "SD7 Code FF"; Code[20]) { FieldClass = FlowFilter; }
        field(50007; "SD8 Code FF"; Code[20]) { FieldClass = FlowFilter; }

        // Item helpers
        field(50010; "Item Description FF"; Text[100])
        {
            Caption = 'Description';
            FieldClass = FlowField;
            CalcFormula = lookup(Item.Description where("No." = field("Item No.")));
        }
        field(50011; "Item Category Code FF"; Code[20])
        {
            Caption = 'Item Category Code';
            FieldClass = FlowField;
            CalcFormula = lookup(Item."Item Category Code" where("No." = field("Item No.")));
        }
        field(50012; "Vendor No. FF"; Code[20])
        {
            Caption = 'Vendor No.';
            FieldClass = FlowField;
            CalcFormula = lookup(Item."Vendor No." where("No." = field("Item No.")));
        }

        // Global Dims 1/2
        field(50020; "Global Dimension 1 Code FF"; Code[20])
        {
            Caption = 'Global Dimension 1 Code';
            FieldClass = FlowField;
            CalcFormula = lookup(Item."Global Dimension 1 Code" where("No." = field("Item No.")));
        }
        field(50021; "Global Dimension 2 Code FF"; Code[20])
        {
            Caption = 'Global Dimension 2 Code';
            FieldClass = FlowField;
            CalcFormula = lookup(Item."Global Dimension 2 Code" where("No." = field("Item No.")));
        }

        // Shortcut Code names from G/L Setup
        field(50030; "SD3 Code Name FF"; Code[20]) { Caption = 'Shortcut Dimension 3 Code (Setup)'; FieldClass = FlowField; CalcFormula = lookup("General Ledger Setup"."Shortcut Dimension 3 Code"); }
        field(50031; "SD4 Code Name FF"; Code[20]) { Caption = 'Shortcut Dimension 4 Code (Setup)'; FieldClass = FlowField; CalcFormula = lookup("General Ledger Setup"."Shortcut Dimension 4 Code"); }
        field(50032; "SD5 Code Name FF"; Code[20]) { Caption = 'Shortcut Dimension 5 Code (Setup)'; FieldClass = FlowField; CalcFormula = lookup("General Ledger Setup"."Shortcut Dimension 5 Code"); }
        field(50033; "SD6 Code Name FF"; Code[20]) { Caption = 'Shortcut Dimension 6 Code (Setup)'; FieldClass = FlowField; CalcFormula = lookup("General Ledger Setup"."Shortcut Dimension 6 Code"); }
        field(50034; "SD7 Code Name FF"; Code[20]) { Caption = 'Shortcut Dimension 7 Code (Setup)'; FieldClass = FlowField; CalcFormula = lookup("General Ledger Setup"."Shortcut Dimension 7 Code"); }
        field(50035; "SD8 Code Name FF"; Code[20]) { Caption = 'Shortcut Dimension 8 Code (Setup)'; FieldClass = FlowField; CalcFormula = lookup("General Ledger Setup"."Shortcut Dimension 8 Code"); }

        // Shortcut values from Default Dimensions
        field(50040; "Shortcut Dim 3 Value FF"; Code[20]) { Caption = 'Shortcut Dimension 3 Value'; FieldClass = FlowField; CalcFormula = lookup("Default Dimension"."Dimension Value Code" where("Table ID" = const(Database::Item), "No." = field("Item No."), "Dimension Code" = field("SD3 Code Name FF"))); }
        field(50041; "Shortcut Dim 4 Value FF"; Code[20]) { Caption = 'Shortcut Dimension 4 Value'; FieldClass = FlowField; CalcFormula = lookup("Default Dimension"."Dimension Value Code" where("Table ID" = const(Database::Item), "No." = field("Item No."), "Dimension Code" = field("SD4 Code Name FF"))); }
        field(50042; "Shortcut Dim 5 Value FF"; Code[20]) { Caption = 'Shortcut Dimension 5 Value'; FieldClass = FlowField; CalcFormula = lookup("Default Dimension"."Dimension Value Code" where("Table ID" = const(Database::Item), "No." = field("Item No."), "Dimension Code" = field("SD5 Code Name FF"))); }
        field(50043; "Shortcut Dim 6 Value FF"; Code[20]) { Caption = 'Shortcut Dimension 6 Value'; FieldClass = FlowField; CalcFormula = lookup("Default Dimension"."Dimension Value Code" where("Table ID" = const(Database::Item), "No." = field("Item No."), "Dimension Code" = field("SD6 Code Name FF"))); }
        field(50044; "Shortcut Dim 7 Value FF"; Code[20]) { Caption = 'Shortcut Dimension 7 Value'; FieldClass = FlowField; CalcFormula = lookup("Default Dimension"."Dimension Value Code" where("Table ID" = const(Database::Item), "No." = field("Item No."), "Dimension Code" = field("SD7 Code Name FF"))); }
        field(50045; "Shortcut Dim 8 Value FF"; Code[20]) { Caption = 'Shortcut Dimension 8 Value'; FieldClass = FlowField; CalcFormula = lookup("Default Dimension"."Dimension Value Code" where("Table ID" = const(Database::Item), "No." = field("Item No."), "Dimension Code" = field("SD8 Code Name FF"))); }

        // Workback
        field(50100; "Use Workback Projection"; Boolean)
        {
            Caption = 'Use Workback Projection';
            trigger OnValidate()
            begin
                if "Use Workback Projection" then
                    "Factor Seasonality" := true;
            end;
        }
        field(50110; "Workback Annual Projection"; Decimal) { Caption = 'Workback Annual Projection'; MinValue = 0; InitValue = 0; }
    }
    keys
    {
        key(PK; "Line No.") { Clustered = true; }
        key(Idx_ItemSelfCountry; "Item No.", "Related Item No.", "Location Country/Region Code", Active, "Effective From") { }
        key(Idx_ItemActive; "Item No.", Active, "Effective From") { }
    }
}

table 89602 "WLM FcstSetup"
{
    Caption = 'WLM Forecast Setup';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Primary Key"; Code[10]) { InitValue = 'SETUP'; }
        field(2; "Default Forecast Name"; Code[20]) { InitValue = 'OPERATIONS'; }
        field(3; "Default Bucket"; Option) { OptionMembers = Day,Week,Month; InitValue = Month; }
        field(4; "Lookback Months"; Integer) { Caption = 'Lookback Period'; InitValue = 12; }
        field(5; "Replace Mode"; Boolean) { Caption = 'Replace Existing Entries'; InitValue = true; }
        field(6; "Include Returns"; Boolean) { InitValue = false; }
        field(7; "Default Self Multiplier %"; Decimal) { Caption = 'Default Self Multiplier %'; MinValue = 0; MaxValue = 100000; InitValue = 100; }

        field(8; "Projection Months"; Integer)
        {
            Caption = 'Projection Period';
            MinValue = 0;
            InitValue = 12;
        }
        field(9; "Default Par Stock Target"; Integer)
        {
            Caption = 'Default Par Stock Target (Months)';
            MinValue = 0;
            InitValue = 2;
        }

        field(20; "SalesType Dim. Code"; Code[20]) { Caption = 'Dimension Code'; }
        field(21; "Retail Prefix"; Code[20]) { Caption = 'Retail Prefix'; InitValue = 'RETAIL'; }
        field(26; "Default Self US Multiplier %"; Decimal) { Caption = 'Default Self US Multiplier %'; MinValue = 0; MaxValue = 100000; InitValue = 100; ObsoleteState = Pending; ObsoleteReason = 'Replaced by per-row Multiplier % in v2.'; }
        field(27; "Default Self CA Multiplier %"; Decimal) { Caption = 'Default Self CA Multiplier %'; MinValue = 0; MaxValue = 100000; InitValue = 100; ObsoleteState = Pending; ObsoleteReason = 'Replaced by per-row Multiplier % in v2.'; }

        field(22; "Exclude Purchasing Blocked"; Boolean) { Caption = 'Exclude Purchasing Blocked (Pull)'; InitValue = true; }
        field(23; "Exclude Sales Blocked"; Boolean) { Caption = 'Exclude Sales Blocked (Pull)'; InitValue = false; }
        field(24; "Exclude Blocked"; Boolean) { Caption = 'Exclude Blocked (Pull)'; InitValue = true; }
        field(25; "Exclude Non-Inventory Items"; Boolean) { Caption = 'Exclude Non-Inventory Items (Pull)'; InitValue = false; }

        field(28; "Demand Date Source"; Option) { Caption = 'Demand Date Source'; OptionMembers = PostingDate,DocumentDate,OrderDate,RequestedDelivery,PromisedDelivery,EarliestOfAll; InitValue = EarliestOfAll; }
        field(29; "Dimension Filter"; Code[20]) { Caption = 'Dimension Filter'; TableRelation = Dimension.Code; }
        field(60; "WB Dimension Filter"; Code[20]) { Caption = 'Seasonality Dimension Filter'; TableRelation = Dimension.Code; }
        field(70; "Planning UOM Code"; Code[10]) { Caption = 'Planning UOM Code'; TableRelation = "Unit of Measure".Code; }
        field(71; "Resource Planning Buckets"; Integer)
        {
            Caption = 'Resource Planning Horizon';
            ToolTip = 'Limits load suggestions to this many Default Bucket intervals (e.g., 3 months when bucket = Month).';
            MinValue = 0;
            InitValue = 3;
        }

        field(80; "Default Parent Load Unit"; Code[10])
        {
            Caption = 'Default Parent Load Unit';
            TableRelation = "Unit of Measure".Code;
            ToolTip = 'Fallback load unit code applied when no specific load profile is found.';
        }
        field(81; "Default Parent Unit Capacity"; Decimal)
        {
            Caption = 'Default Parent Unit Capacity';
            MinValue = 0;
            ToolTip = 'Default capacity (in parent units) used when no load profile provides a capacity.';
        }
        field(82; "Default Min Fill Percent"; Decimal)
        {
            Caption = 'Default Min Fill %';
            MinValue = 0;
            MaxValue = 100;
            ToolTip = 'Fallback minimum fill percentage enforced when a load profile is not resolved.';
        }
        field(83; "Default Allow Partial Load"; Boolean)
        {
            Caption = 'Allow Partial Load by Default';
            ToolTip = 'Determines whether partial loads are allowed when using fallback settings.';
            InitValue = true;
        }
        field(84; "Load Batch No. Series"; Code[20])
        {
            Caption = 'Load Batch No. Series';
            TableRelation = "No. Series".Code;
            ToolTip = 'Specifies the No. Series used to assign sequential load batch numbers. Leave blank to use legacy labels.';
        }
        field(85; "Load Batch Sequence No."; Integer)
        {
            Caption = 'Last Load Batch No.';
            Editable = false;
        }
        field(86; "Factor Subs in Inventory"; Boolean)
        {
            Caption = 'Factor Substitutes in Inventory';
            InitValue = false;
        }
        field(87; "Factor Subs in Sales Hist"; Boolean)
        {
            Caption = 'Factor Substitutes in Sales History';
            ToolTip = 'When enabled, sales history for items that list this item as a substitute will be consolidated into the base demand for this item.';
            InitValue = false;
        }
        field(88; "Factor Subs in Par Dashboard"; Boolean)
        {
            Caption = 'Factor Substitutes in Item Par Dashboard';
            ToolTip = 'When enabled, purchasing-blocked items that have substitutes will be treated as donors; their quantities/costs roll into the substitute and the donors are hidden on the Par Dashboard.';
            InitValue = false;
        }
        field(89; "Factor Subs in Inbound"; Boolean)
        {
            Caption = 'Factor Substitutes in Inbounds';
            ToolTip = 'When enabled, inbound purchases/transfers for donor items roll up to the substitute in planning calculations.';
            InitValue = false;
        }
        field(91; "Factor Subs in Sales Demand"; Boolean)
        {
            Caption = 'Factor Substitutes in Open Sales Demand';
            ToolTip = 'When enabled, open sales orders for items that list this item as a substitute will also count as demand against this item.';
            InitValue = false;
        }
        field(90; "Default Lead Time Days"; Integer)
        {
            Caption = 'Default Lead Time (Days)';
            ToolTip = 'Default lead time in days used when no vendor/SKU lead time is defined. Used to calculate Expected Receipt Date.';
            MinValue = 0;
            InitValue = 28;
        }
    }
    keys { key(PK; "Primary Key") { Clustered = true; } }
}

table 89603 "WLM FcstBuffer"
{
    Caption = 'WLM Forecast Buffer';
    DataClassification = SystemMetadata;
    TableType = Temporary;
    fields
    {
        field(1; "Item No."; Code[20])
        {
            TableRelation = Item."No.";
        }
        field(2; "Location Code"; Code[10])
        {
            TableRelation = Location.Code;
        }
        field(3; "Bucket Date"; Date) { }
        field(4; "Base Qty"; Decimal) { }
        field(10; Description; Text[100]) { }
        field(11; "Item Category Code"; Code[20]) { }
        field(12; "Vendor No."; Code[20]) { }
        field(20; "On Hand Qty"; Decimal) { }
        field(21; "Reserved Qty"; Decimal) { }
        field(22; "Projected Sales"; Decimal) { }
        field(23; "Reorder Point"; Decimal) { Caption = 'Reorder Point (Projected)'; }
        field(24; "SKU Reorder Point"; Decimal) { Caption = 'Reorder Point (SKU)'; }
        field(29; "Reorder Point MAX"; Decimal) { Caption = 'Reorder Point (MAX)'; }
        field(25; "Inbound Arrivals"; Decimal) { }
        field(27; "Inbound Arrival - Purchase"; Decimal) { Caption = 'Inbound Arrival - Purchase'; }
        field(28; "Inbound Arrival - Transfer"; Decimal) { Caption = 'Inbound Arrival - Transfer'; }
        field(26; "Open Transfer Demand"; Decimal) { Caption = 'Open Transfer Demand'; }
        field(30; "Qty Required"; Decimal) { }
        field(60; "Unit Cost"; Decimal) { Caption = 'Unit Cost'; }
        field(61; "Last Direct Cost"; Decimal) { Caption = 'Last Direct Cost'; }
        field(62; "Req. Cost (Unit)"; Decimal) { Caption = 'Required Qty * Unit Cost'; }
        field(63; "Req. Cost (Last Direct)"; Decimal) { Caption = 'Required Qty * Last Direct Cost'; }
        field(40; "Required On"; Date) { }
        field(41; "Earliest Replenishment"; Date) { }
        field(50; "Loading Unit Type"; Code[10]) { }
        field(51; "Pct of Sub Unit"; Decimal)
        {
            Caption = 'Required Sub-Loading Units';
            DecimalPlaces = 0 : 5;
        }
        field(53; "Pct of Parent Unit 1"; Decimal)
        {
            Caption = 'Required Parent Loading Unit 1';
            DecimalPlaces = 0 : 5;
        }
        field(54; "Pct of Parent Unit 2"; Decimal)
        {
            Caption = 'Required Parent Loading Unit 2';
            DecimalPlaces = 0 : 5;
        }
        field(52; Surplus; Decimal)
        {
            Caption = 'Surplus';
        }
        field(70; "Global Dimension 1 Code"; Code[20])
        {
            Caption = 'Global Dimension 1 Code';
            FieldClass = FlowField;
            CalcFormula = lookup(Item."Global Dimension 1 Code" where("No." = field("Item No.")));
        }
        field(71; "Global Dimension 2 Code"; Code[20])
        {
            Caption = 'Global Dimension 2 Code';
            FieldClass = FlowField;
            CalcFormula = lookup(Item."Global Dimension 2 Code" where("No." = field("Item No.")));
        }
        field(80; "SD3 Code Name"; Code[20])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("General Ledger Setup"."Shortcut Dimension 3 Code");
        }
        field(81; "SD4 Code Name"; Code[20])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("General Ledger Setup"."Shortcut Dimension 4 Code");
        }
        field(82; "SD5 Code Name"; Code[20])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("General Ledger Setup"."Shortcut Dimension 5 Code");
        }
        field(83; "SD6 Code Name"; Code[20])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("General Ledger Setup"."Shortcut Dimension 6 Code");
        }
        field(84; "SD7 Code Name"; Code[20])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("General Ledger Setup"."Shortcut Dimension 7 Code");
        }
        field(85; "SD8 Code Name"; Code[20])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("General Ledger Setup"."Shortcut Dimension 8 Code");
        }
        field(90; "Shortcut Dimension 3 Value"; Code[20])
        {
            Caption = 'Shortcut Dimension 3 Value';
            FieldClass = FlowField;
            CalcFormula = lookup("Default Dimension"."Dimension Value Code" where("Table ID" = const(Database::Item), "No." = field("Item No."), "Dimension Code" = field("SD3 Code Name")));
        }
        field(91; "Shortcut Dimension 4 Value"; Code[20])
        {
            Caption = 'Shortcut Dimension 4 Value';
            FieldClass = FlowField;
            CalcFormula = lookup("Default Dimension"."Dimension Value Code" where("Table ID" = const(Database::Item), "No." = field("Item No."), "Dimension Code" = field("SD4 Code Name")));
        }
        field(92; "Shortcut Dimension 5 Value"; Code[20])
        {
            Caption = 'Shortcut Dimension 5 Value';
            FieldClass = FlowField;
            CalcFormula = lookup("Default Dimension"."Dimension Value Code" where("Table ID" = const(Database::Item), "No." = field("Item No."), "Dimension Code" = field("SD5 Code Name")));
        }
        field(93; "Shortcut Dimension 6 Value"; Code[20])
        {
            Caption = 'Shortcut Dimension 6 Value';
            FieldClass = FlowField;
            CalcFormula = lookup("Default Dimension"."Dimension Value Code" where("Table ID" = const(Database::Item), "No." = field("Item No."), "Dimension Code" = field("SD6 Code Name")));
        }
        field(94; "Shortcut Dimension 7 Value"; Code[20])
        {
            Caption = 'Shortcut Dimension 7 Value';
            FieldClass = FlowField;
            CalcFormula = lookup("Default Dimension"."Dimension Value Code" where("Table ID" = const(Database::Item), "No." = field("Item No."), "Dimension Code" = field("SD7 Code Name")));
        }
        field(95; "Shortcut Dimension 8 Value"; Code[20])
        {
            Caption = 'Shortcut Dimension 8 Value';
            FieldClass = FlowField;
            CalcFormula = lookup("Default Dimension"."Dimension Value Code" where("Table ID" = const(Database::Item), "No." = field("Item No."), "Dimension Code" = field("SD8 Code Name")));
        }
    }
    keys { key(PK; "Item No.", "Location Code", "Bucket Date") { Clustered = true; } }
}

table 89604 "WLM Fcst Location"
{
    Caption = 'WLM Forecast Location';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Location Code"; Code[10]) { Caption = 'Location Code'; TableRelation = Location.Code; }
        field(2; Active; Boolean) { Caption = 'Active (Include in Planning)'; InitValue = true; }
        field(3; "Location Country/Region FF"; Code[10])
        {
            Caption = 'Location Country/Region';
            FieldClass = FlowField;
            CalcFormula = lookup(Location."Country/Region Code" where(Code = field("Location Code")));
            Editable = false;
        }
    }
    keys { key(PK; "Location Code") { Clustered = true; } }
}

table 89605 "WLM Region Location Map"
{
    Caption = 'WLM Region → Location Map';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Region Code"; Code[30]) { Caption = 'Region Code (Ship-to County/State)'; }
        field(2; "Location Code"; Code[10]) { Caption = 'Target Location'; TableRelation = Location.Code; }
        field(3; Active; Boolean) { Caption = 'Active'; InitValue = true; }
        field(4; "Location Country/Region FF"; Code[10])
        {
            Caption = 'Location Country/Region';
            FieldClass = FlowField;
            CalcFormula = lookup(Location."Country/Region Code" where(Code = field("Location Code")));
        }
    }
    keys { key(PK; "Region Code") { Clustered = true; } }
}

table 89630 "WLM Forecast Entry"
{
    Caption = 'WLM Forecast Entry';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Forecast Name"; Code[20]) { Caption = 'Forecast Name'; }
        field(2; "Item No."; Code[20]) { Caption = 'Item No.'; TableRelation = Item."No."; }
        field(3; "Location Code"; Code[10]) { Caption = 'Location Code'; TableRelation = Location.Code; }
        field(4; "Forecast Date"; Date) { Caption = 'Forecast Date'; }
        field(5; Quantity; Decimal) { Caption = 'Quantity'; }
        field(6; "Created At"; DateTime) { Caption = 'Created At'; Editable = false; }
        field(7; "Created By"; Code[50]) { Caption = 'Created By'; Editable = false; }
        field(8; "Historical Sales Qty"; Decimal) { Caption = 'Historical Sales Qty'; Editable = false; }
        field(9; "Multiplier Used %"; Decimal) { Caption = 'Multiplier Used %'; Editable = false; DecimalPlaces = 0 : 2; }
        field(10; "Historical Period Start"; Date) { Caption = 'Historical Period Start'; Editable = false; }
        field(11; "Historical Period End"; Date) { Caption = 'Historical Period End'; Editable = false; }

        field(50010; "Item Description FF"; Text[100]) { Caption = 'Description'; FieldClass = FlowField; CalcFormula = lookup(Item.Description where("No." = field("Item No."))); }
        field(50011; "Item Category Code FF"; Code[20]) { Caption = 'Item Category Code'; FieldClass = FlowField; CalcFormula = lookup(Item."Item Category Code" where("No." = field("Item No."))); }
        field(50012; "Vendor No. FF"; Code[20]) { Caption = 'Vendor No.'; FieldClass = FlowField; CalcFormula = lookup(Item."Vendor No." where("No." = field("Item No."))); }

        field(50020; "Global Dimension 1 Code FF"; Code[20]) { Caption = 'Global Dimension 1 Code'; FieldClass = FlowField; CalcFormula = lookup(Item."Global Dimension 1 Code" where("No." = field("Item No."))); }
        field(50021; "Global Dimension 2 Code FF"; Code[20]) { Caption = 'Global Dimension 2 Code'; FieldClass = FlowField; CalcFormula = lookup(Item."Global Dimension 2 Code" where("No." = field("Item No."))); }

        field(50030; "SD3 Code Name FF"; Code[20]) { FieldClass = FlowField; CalcFormula = lookup("General Ledger Setup"."Shortcut Dimension 3 Code"); }
        field(50031; "SD4 Code Name FF"; Code[20]) { FieldClass = FlowField; CalcFormula = lookup("General Ledger Setup"."Shortcut Dimension 4 Code"); }
        field(50032; "SD5 Code Name FF"; Code[20]) { FieldClass = FlowField; CalcFormula = lookup("General Ledger Setup"."Shortcut Dimension 5 Code"); }
        field(50033; "SD6 Code Name FF"; Code[20]) { FieldClass = FlowField; CalcFormula = lookup("General Ledger Setup"."Shortcut Dimension 6 Code"); }
        field(50034; "SD7 Code Name FF"; Code[20]) { FieldClass = FlowField; CalcFormula = lookup("General Ledger Setup"."Shortcut Dimension 7 Code"); }
        field(50035; "SD8 Code Name FF"; Code[20]) { FieldClass = FlowField; CalcFormula = lookup("General Ledger Setup"."Shortcut Dimension 8 Code"); }

        field(50040; "Shortcut Dim 3 Value FF"; Code[20]) { Caption = 'Shortcut Dimension 3 Value'; FieldClass = FlowField; CalcFormula = lookup("Default Dimension"."Dimension Value Code" where("Table ID" = const(Database::Item), "No." = field("Item No."), "Dimension Code" = field("SD3 Code Name FF"))); }
        field(50041; "Shortcut Dim 4 Value FF"; Code[20]) { Caption = 'Shortcut Dimension 4 Value'; FieldClass = FlowField; CalcFormula = lookup("Default Dimension"."Dimension Value Code" where("Table ID" = const(Database::Item), "No." = field("Item No."), "Dimension Code" = field("SD4 Code Name FF"))); }
        field(50042; "Shortcut Dim 5 Value FF"; Code[20]) { Caption = 'Shortcut Dimension 5 Value'; FieldClass = FlowField; CalcFormula = lookup("Default Dimension"."Dimension Value Code" where("Table ID" = const(Database::Item), "No." = field("Item No."), "Dimension Code" = field("SD5 Code Name FF"))); }
        field(50043; "Shortcut Dim 6 Value FF"; Code[20]) { Caption = 'Shortcut Dimension 6 Value'; FieldClass = FlowField; CalcFormula = lookup("Default Dimension"."Dimension Value Code" where("Table ID" = const(Database::Item), "No." = field("Item No."), "Dimension Code" = field("SD6 Code Name FF"))); }
        field(50044; "Shortcut Dim 7 Value FF"; Code[20]) { Caption = 'Shortcut Dimension 7 Value'; FieldClass = FlowField; CalcFormula = lookup("Default Dimension"."Dimension Value Code" where("Table ID" = const(Database::Item), "No." = field("Item No."), "Dimension Code" = field("SD7 Code Name FF"))); }
        field(50045; "Shortcut Dim 8 Value FF"; Code[20]) { Caption = 'Shortcut Dimension 8 Value'; FieldClass = FlowField; CalcFormula = lookup("Default Dimension"."Dimension Value Code" where("Table ID" = const(Database::Item), "No." = field("Item No."), "Dimension Code" = field("SD8 Code Name FF"))); }
    }
    keys { key(PK; "Forecast Name", "Item No.", "Location Code", "Forecast Date") { Clustered = true; } }
    trigger OnInsert()
    begin
        if "Created At" = 0DT then "Created At" := CurrentDateTime;
        if "Created By" = '' then "Created By" := UserId;
    end;
}

table 89606 "WLM Dim Filter Value"
{
    Caption = 'WLM Dimension Filter Value';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Dimension Code"; Code[20]) { Caption = 'Dimension Code'; TableRelation = Dimension.Code; NotBlank = true; }
        field(2; "Dimension Value Code"; Code[20]) { Caption = 'Dimension Value Code'; NotBlank = true; }
        field(3; Active; Boolean) { Caption = 'Active'; InitValue = true; }
        field(10; Description; Text[100]) { Caption = 'Description'; }
        field(11; "Use Region Location Mapping"; Boolean)
        {
            Caption = 'Use Region Location Mapping';
            DataClassification = CustomerContent;
            InitValue = false;
        }
    }
    keys { key(PK; "Dimension Code", "Dimension Value Code") { Clustered = true; } }
}

table 89607 "WLM Seasonality Filter Value"
{
    Caption = 'WLM Seasonality Filter Value';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Dimension Code"; Code[20]) { Caption = 'Dimension Code'; TableRelation = Dimension.Code; NotBlank = true; }
        field(2; "Dimension Value Code"; Code[20]) { Caption = 'Dimension Value Code'; NotBlank = true; }
        field(3; Active; Boolean) { Caption = 'Active'; InitValue = true; }
        field(10; Description; Text[100]) { Caption = 'Description'; }
    }
    keys { key(PK; "Dimension Code", "Dimension Value Code") { Clustered = true; } }
}

table 89676 "WLM Seasonality Attribution"
{
    Caption = 'WLM Seasonality Attribution';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Dimension Code"; Code[20]) { Caption = 'Dimension Code'; }
        field(2; "Dimension Value Code"; Code[20]) { Caption = 'Dimension Value Code'; }
        field(3; "Month No"; Integer) { Caption = 'Month No'; MinValue = 0; MaxValue = 12; } // 0 = default
        field(4; "Location Code"; Code[10]) { Caption = 'Location Code'; TableRelation = Location.Code; }
        field(5; "Country/Region Code FF"; Code[10])
        {
            Caption = 'Location Country/Region';
            FieldClass = FlowField;
            CalcFormula = lookup(Location."Country/Region Code" where(Code = field("Location Code")));
        }
        field(6; "Month %"; Decimal) { Caption = 'Month %'; MinValue = 0; MaxValue = 100; }
        field(7; "Location %"; Decimal) { Caption = 'Location %'; MinValue = 0; MaxValue = 100; }
    }
    keys { key(PK; "Dimension Code", "Dimension Value Code", "Month No", "Location Code") { Clustered = true; } }
}

table 89608 "WLM WB Month Profile"
{
    ObsoleteState = Removed;
    ObsoleteReason = 'Replaced by unified table WLM Seasonality Attribution (89676).';
    Caption = 'WLM WB Month Profile (Legacy)';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Dimension Code"; Code[20]) { }
        field(2; "Dimension Value Code"; Code[20]) { }
        field(3; "Month No"; Integer) { MinValue = 1; MaxValue = 12; }
        field(4; "Month %"; Decimal) { MinValue = 0; MaxValue = 100; }
    }
    keys { key(PK; "Dimension Code", "Dimension Value Code", "Month No") { Clustered = true; } }
}

table 89609 "WLM WB Country Profile"
{
    ObsoleteState = Removed;
    ObsoleteReason = 'Replaced by unified table WLM Seasonality Attribution (89676).';
    Caption = 'WLM WB Country Profile (Legacy)';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Dimension Code"; Code[20]) { }
        field(2; "Dimension Value Code"; Code[20]) { }
        field(3; "Country/Region Code"; Code[10]) { TableRelation = "Country/Region".Code; }
        field(4; "Country %"; Decimal) { MinValue = 0; MaxValue = 100; }
    }
    keys { key(PK; "Dimension Code", "Dimension Value Code", "Country/Region Code") { Clustered = true; } }
}

table 89610 "WLM WB Location Profile"
{
    ObsoleteState = Removed;
    ObsoleteReason = 'Replaced by unified table WLM Seasonality Attribution (89676).';
    Caption = 'WLM WB Location Profile (Legacy)';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Dimension Code"; Code[20]) { }
        field(2; "Dimension Value Code"; Code[20]) { }
        field(3; "Country/Region Code"; Code[10]) { TableRelation = "Country/Region".Code; }
        field(4; "Location Code"; Code[10]) { TableRelation = Location.Code; }
        field(5; "Location %"; Decimal) { MinValue = 0; MaxValue = 100; }
    }
    keys { key(PK; "Dimension Code", "Dimension Value Code", "Country/Region Code", "Location Code") { Clustered = true; } }
}

table 89640 "WLM Adv Item Planning Country"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by per-row Country on WLM Adv Item Planning v2 (89601).';
    Caption = 'Adv Item Planning (By Country) (Legacy)';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Item No."; Code[20]) { TableRelation = Item."No."; }
        field(2; "Related Item No."; Code[20]) { TableRelation = Item."No."; }
        field(3; "Country/Region Code"; Code[10]) { TableRelation = "Country/Region".Code; }
        field(4; "Multiplier %"; Decimal) { MinValue = 0; MaxValue = 100000; InitValue = 100; }
        field(5; "Effective From"; Date) { }
        field(6; "Effective To"; Date) { }
        field(7; Active; Boolean) { InitValue = true; }
    }
    keys { key(PK; "Item No.", "Related Item No.", "Country/Region Code") { Clustered = true; } }
}

// ======================= PAGES =======================
page 89611 "WLM AdvPlanningPart"
{
    PageType = ListPart;
    SourceTable = "WLM Adv Item Planning v2";
    Caption = 'Advanced Item Planning';
    ApplicationArea = All;
    layout
    {
        area(content)
        {
            repeater(Rep)
            {
                field(LineNo; Rec."Line No.") { ApplicationArea = All; Editable = false; }
                field(ItemNo; Rec."Item No.") { ApplicationArea = All; }
                field(VendorNo; Rec."Vendor No. FF") { ApplicationArea = All; Caption = 'Vendor No.'; Editable = false; }
                field(RelatedItemNo; Rec."Related Item No.") { ApplicationArea = All; }
                field(LocationCountry; Rec."Location Country/Region Code") { ApplicationArea = All; }
                field(UseRegionLocationMapping; Rec."Use Region Location Mapping")
                {
                    ApplicationArea = All;
                    Caption = 'Use Region Location Mapping';
                    ToolTip = 'Toggle to apply Region → Location mapping for this planning row.';
                }
                field(FactorSeasonality; Rec."Factor Seasonality")
                {
                    ApplicationArea = All;
                    Caption = 'Factor Seasonality';
                    ToolTip = 'If enabled, fill missing demand using stored seasonality for the cohort.';
                    Editable = not Rec."Use Workback Projection";
                }
                field(ContributionPct; Rec."Contribution %") { ApplicationArea = All; }
                field(MultiplierPct; Rec."Multiplier %") { ApplicationArea = All; }
                field(IncludeVariants; Rec."Include Variants") { ApplicationArea = All; }
                field(EffectiveFrom; Rec."Effective From") { ApplicationArea = All; }
                field(EffectiveTo; Rec."Effective To") { ApplicationArea = All; }
                field(Active; Rec.Active) { ApplicationArea = All; }
                field(UseWorkback; Rec."Use Workback Projection") { ApplicationArea = All; }
                field(WBAnnual; Rec."Workback Annual Projection") { ApplicationArea = All; }
                field(ItemDescriptionFF; Rec."Item Description FF") { ApplicationArea = All; Caption = 'Description'; Editable = false; }
                field(ItemCategoryCodeFF; Rec."Item Category Code FF") { ApplicationArea = All; Caption = 'Item Category Code'; Editable = false; }
                field(GD1; Rec."Global Dimension 1 Code FF") { ApplicationArea = All; Editable = false; }
                field(GD2; Rec."Global Dimension 2 Code FF") { ApplicationArea = All; Editable = false; }
                field(SD3; Rec."Shortcut Dim 3 Value FF") { ApplicationArea = All; Editable = false; }
                field(SD4; Rec."Shortcut Dim 4 Value FF") { ApplicationArea = All; Editable = false; }
                field(SD5; Rec."Shortcut Dim 5 Value FF") { ApplicationArea = All; Editable = false; }
                field(SD6; Rec."Shortcut Dim 6 Value FF") { ApplicationArea = All; Editable = false; }
                field(SD7; Rec."Shortcut Dim 7 Value FF") { ApplicationArea = All; Editable = false; }
                field(SD8; Rec."Shortcut Dim 8 Value FF") { ApplicationArea = All; Editable = false; }
            }
        }
    }
}

page 89614 "WLM Adv Planning List"
{
    PageType = List;
    SourceTable = "WLM Adv Item Planning v2";
    Caption = 'WLM Adv Planning List';
    ApplicationArea = All;
    UsageCategory = Lists;
    layout
    {
        area(content)
        {
            repeater(Rep)
            {
                field(LineNo; Rec."Line No.") { ApplicationArea = All; Editable = false; }
                field(ItemNo; Rec."Item No.") { ApplicationArea = All; }
                field(VendorNo; Rec."Vendor No. FF") { ApplicationArea = All; Caption = 'Vendor No.'; Editable = false; }
                field(RelatedItemNo; Rec."Related Item No.") { ApplicationArea = All; }
                field(LocationCountry; Rec."Location Country/Region Code")
                {
                    ApplicationArea = All;
                    Caption = 'Location Country/Region';
                }
                field(UseRegionLocationMapping; Rec."Use Region Location Mapping")
                {
                    ApplicationArea = All;
                    Caption = 'Use Region Location Mapping';
                    ToolTip = 'Indicates whether Region → Location mapping should be applied for this planning row.';
                }
                field(FactorSeasonality; Rec."Factor Seasonality")
                {
                    ApplicationArea = All;
                    Caption = 'Factor Seasonality';
                    ToolTip = 'Fill missing demand for this row using stored seasonality for its cohort.';
                    Editable = not Rec."Use Workback Projection";
                }
                field(ContributionPct; Rec."Contribution %") { ApplicationArea = All; }
                field(MultiplierPct; Rec."Multiplier %")
                {
                    ApplicationArea = All;
                    Editable = not Rec."Use Workback Projection";
                    ToolTip = 'Multiplier used when Use Workback Projection = false.';
                }
                field(IncludeVariants; Rec."Include Variants") { ApplicationArea = All; }
                field(EffectiveFrom; Rec."Effective From") { ApplicationArea = All; }
                field(EffectiveTo; Rec."Effective To") { ApplicationArea = All; }
                field(Active; Rec.Active) { ApplicationArea = All; }
                field(UseWorkback; Rec."Use Workback Projection") { ApplicationArea = All; }
                field(WBAnnual; Rec."Workback Annual Projection") { ApplicationArea = All; }
                field(ItemDescriptionFF; Rec."Item Description FF") { ApplicationArea = All; Caption = 'Description'; Editable = false; }
                field(ItemCategoryCodeFF; Rec."Item Category Code FF") { ApplicationArea = All; Caption = 'Item Category Code'; Editable = false; }
                field(GD1; Rec."Global Dimension 1 Code FF") { ApplicationArea = All; Editable = false; }
                field(GD2; Rec."Global Dimension 2 Code FF") { ApplicationArea = All; Editable = false; }
                field(SD3; Rec."Shortcut Dim 3 Value FF") { ApplicationArea = All; Editable = false; }
                field(SD4; Rec."Shortcut Dim 4 Value FF") { ApplicationArea = All; Editable = false; }
                field(SD5; Rec."Shortcut Dim 5 Value FF") { ApplicationArea = All; Editable = false; }
                field(SD6; Rec."Shortcut Dim 6 Value FF") { ApplicationArea = All; Editable = false; }
                field(SD7; Rec."Shortcut Dim 7 Value FF") { ApplicationArea = All; Editable = false; }
                field(SD8; Rec."Shortcut Dim 8 Value FF") { ApplicationArea = All; Editable = false; }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(PullItemsToPlanning)
            {
                Caption = 'Pull Items → Planning';
                ApplicationArea = All;
                Image = Import;
                ToolTip = 'Add planning rows (one per Country/Region) for items whose Default Dimension matches the Setup Dimension Filter and an Active value.';
                trigger OnAction()
                var
                    Seeder: Codeunit "WLM RetailSeed";
                    CountAdded: Integer;
                begin
                    CountAdded := Seeder.SeedItemsToPlanning_FromDimensionFilter();
                    Message('%1 planning row(s) added (self rows per Country). Existing rows were skipped.', CountAdded);
                end;
            }
            action(RemoveObsoleteItemsFromPlanning)
            {
                Caption = 'Remove Obsolete Items → Planning';
                ApplicationArea = All;
                Image = Delete;
                ToolTip = 'Remove planning rows for items that no longer conform to current Setup exclude toggles.';
                trigger OnAction()
                var
                    Cleanup: Codeunit "WLM PlanningCleanup";
                    ItemsRemoved: Integer;
                    RowsRemoved: Integer;
                begin
                    Cleanup.RemoveObsoleteFromPlanning(ItemsRemoved, RowsRemoved);
                    Message('%1 item(s) removed from planning (%2 row(s) deleted).', ItemsRemoved, RowsRemoved);
                end;
            }
            action(PullSkuToPlanning)
            {
                Caption = 'Pull Stockkeeping Units → Planning';
                ApplicationArea = All;
                Image = Import;
                ToolTip = 'Copies SKU-level planning recommendations into the Advanced Item Planning list.';
                trigger OnAction()
                var
                    Pull: Codeunit "WLM SkuPull";
                    CountUpserted: Integer;
                begin
                    CountUpserted := Pull.PullSkuToPlanning();
                    Message('%1 SKU planning row(s) upserted.', CountUpserted);
                end;
            }
            action(InitializeWorkbackProfiles)
            {
                Caption = 'Initialize Workback Profiles';
                ApplicationArea = All;
                Image = Setup;
                ToolTip = 'Seed unified attribution with even Month% and Location% (per Country) where missing.';
                trigger OnAction()
                var
                    Setup: Record "WLM FcstSetup";
                    Val: Record "WLM Seasonality Filter Value";
                    WBA: Record "WLM Seasonality Attribution";
                    LocOn: Record "WLM Fcst Location";
                    LocationRec: Record Location;
                    Countries: List of [Code[10]];
                    CountryLocs: List of [Code[10]];
                    CountCountries: Integer;
                    CountLocs: Integer;
                    EvenMonthPct: Decimal;
                    EvenLocPct: Decimal;
                    i: Integer;
                    li: Integer;
                    m: Integer;
                    K: Code[10];
                    LCode: Code[10];
                begin
                    if not Setup.Get('SETUP') then
                        Error('Initialize WLM Forecast Setup first.');

                    Clear(Countries);
                    LocOn.Reset();
                    LocOn.SetRange(Active, true);
                    if LocOn.FindSet() then
                        repeat
                            if LocationRec.Get(LocOn."Location Code") then
                                if (LocationRec."Country/Region Code" <> '') and not ListContainsCode10(Countries, LocationRec."Country/Region Code") then
                                    Countries.Add(LocationRec."Country/Region Code");
                        until LocOn.Next() = 0;

                    CountCountries := Countries.Count();
                    if CountCountries = 0 then begin
                        Message('No active planning locations. Nothing to initialize.');
                        exit;
                    end;

                    EvenMonthPct := 100 / 12;

                    Val.Reset();
                    Val.SetRange("Dimension Code", UpperCase(Setup."WB Dimension Filter"));
                    Val.SetRange(Active, true);
                    if Val.FindSet() then
                        repeat
                            for m := 1 to 12 do begin
                                for i := 1 to Countries.Count() do begin
                                    K := Countries.Get(i);

                                    Clear(CountryLocs);
                                    LocOn.Reset();
                                    LocOn.SetRange(Active, true);
                                    if LocOn.FindSet() then
                                        repeat
                                            if LocationRec.Get(LocOn."Location Code") and (LocationRec."Country/Region Code" = K) then
                                                CountryLocs.Add(LocationRec.Code);
                                        until LocOn.Next() = 0;

                                    CountLocs := CountryLocs.Count();
                                    if CountLocs = 0 then
                                        continue;

                                    EvenLocPct := 100 / CountLocs;

                                    for li := 1 to CountryLocs.Count() do begin
                                        LCode := CountryLocs.Get(li);
                                        WBA.Reset();
                                        WBA.SetRange("Dimension Code", Val."Dimension Code");
                                        WBA.SetRange("Dimension Value Code", Val."Dimension Value Code");
                                        WBA.SetRange("Month No", m);
                                        WBA.SetRange("Location Code", LCode);
                                        if not WBA.FindFirst() then begin
                                            WBA.Init();
                                            WBA."Dimension Code" := Val."Dimension Code";
                                            WBA."Dimension Value Code" := Val."Dimension Value Code";
                                            WBA."Month No" := m;
                                            WBA."Location Code" := LCode;
                                            WBA."Month %" := EvenMonthPct;
                                            WBA."Location %" := EvenLocPct;
                                            WBA.Insert(true);
                                        end;
                                    end;
                                end;
                            end;
                        until Val.Next() = 0;

                    Message('Unified Workback profiles initialized where missing (Month% & Location% per Country).');
                end;
            }
        }
    }
    local procedure ListContainsCode10(var L: List of [Code[10]]; V: Code[10]): Boolean
    var
        i: Integer;
    begin
        for i := 1 to L.Count() do
            if L.Get(i) = V then
                exit(true);
        exit(false);
    end;
}

page 89615 "WLM Fcst Locations"
{
    PageType = ListPart;
    SourceTable = "WLM Fcst Location";
    Caption = 'WLM Forecast Locations';
    ApplicationArea = All;
    Editable = true;
    layout
    {
        area(content)
        {
            repeater(Rep)
            {
                field(LocationCode; Rec."Location Code")
                {
                    ApplicationArea = All;
                    Visible = true;
                }
                field(LocationCountry; Rec."Location Country/Region FF") { ApplicationArea = All; Editable = false; Caption = 'Country/Region'; }
                field(Active; Rec.Active) { ApplicationArea = All; }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(EditLocationsInExcel)
            {
                Caption = 'Edit in Excel';
                ApplicationArea = All;
                Image = Excel;
                ToolTip = 'Opens the planning locations list in Excel for bulk edits.';
                trigger OnAction()
                begin
                    PAGE.Run(PAGE::"WLM Fcst Location Worksheet");
                end;
            }
            action(ActivateSelected)
            {
                Caption = 'Mark Selected Active';
                ApplicationArea = All;
                Image = SelectEntries;
                ToolTip = 'Sets the Active flag to true for the selected locations.';
                trigger OnAction()
                begin
                    SetActiveForSelection(true);
                end;
            }
            action(DeactivateSelected)
            {
                Caption = 'Mark Selected Inactive';
                ApplicationArea = All;
                Image = Cancel;
                ToolTip = 'Sets the Active flag to false for the selected locations.';
                trigger OnAction()
                begin
                    SetActiveForSelection(false);
                end;
            }
        }
    }

    local procedure SetActiveForSelection(NewState: Boolean)
    var
        Selection: Record "WLM Fcst Location";
    begin
        CurrPage.SetSelectionFilter(Selection);
        if Selection.IsEmpty() then begin
            Selection.Reset();
            Selection.SetRange("Location Code", Rec."Location Code");
        end;

        if Selection.FindSet() then
            repeat
                if Selection.Active <> NewState then begin
                    Selection.Active := NewState;
                    Selection.Modify(true);
                end;
            until Selection.Next() = 0;
    end;
}

page 89616 "WLM Region Location Map"
{
    PageType = ListPart;
    SourceTable = "WLM Region Location Map";
    Caption = 'Region → Location Mapping';
    ApplicationArea = All;
    Editable = true;
    layout
    {
        area(content)
        {
            repeater(Rep)
            {
                field(RegionCode; Rec."Region Code") { ApplicationArea = All; ToolTip = 'Ship-to County/State (e.g., ON).'; }
                field(LocationCode; Rec."Location Code") { ApplicationArea = All; ToolTip = 'Target location.'; }
                field(LocationCountry; Rec."Location Country/Region FF") { ApplicationArea = All; Caption = 'Location Country/Region'; Editable = false; }
                field(Active; Rec.Active) { ApplicationArea = All; }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(EditMappingInExcel)
            {
                Caption = 'Edit in Excel';
                ApplicationArea = All;
                Image = Excel;
                ToolTip = 'Opens the Region → Location mapping list in Excel for quick maintenance.';
                trigger OnAction()
                begin
                    PAGE.Run(PAGE::"WLM Region Map Worksheet");
                end;
            }
            action(ActivateRegions)
            {
                Caption = 'Mark Selected Active';
                ApplicationArea = All;
                Image = SelectEntries;
                ToolTip = 'Marks the selected region mappings as active so they influence routing.';
                trigger OnAction()
                begin
                    SetActiveForSelection(true);
                end;
            }
            action(DeactivateRegions)
            {
                Caption = 'Mark Selected Inactive';
                ApplicationArea = All;
                Image = Cancel;
                ToolTip = 'Marks the selected region mappings as inactive to exclude them from routing.';
                trigger OnAction()
                begin
                    SetActiveForSelection(false);
                end;
            }
        }
    }

    local procedure SetActiveForSelection(NewState: Boolean)
    var
        Selection: Record "WLM Region Location Map";
    begin
        CurrPage.SetSelectionFilter(Selection);
        if Selection.IsEmpty() then begin
            Selection.Reset();
            Selection.SetRange("Region Code", Rec."Region Code");
            Selection.SetRange("Location Code", Rec."Location Code");
        end;

        if not Selection.FindSet() then
            exit;

        repeat
            if Selection.Active <> NewState then begin
                Selection.Active := NewState;
                Selection.Modify(true);
            end;
        until Selection.Next() = 0;
    end;
}

page 89618 "WLM Region Map Worksheet"
{
    Caption = 'Region → Location Mapping';
    PageType = List;
    SourceTable = "WLM Region Location Map";
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = true;
    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = true;
    layout
    {
        area(content)
        {
            repeater(Rep)
            {
                field(RegionCode; Rec."Region Code") { ApplicationArea = All; ToolTip = 'Ship-to County/State (e.g., ON).'; }
                field(LocationCode; Rec."Location Code") { ApplicationArea = All; ToolTip = 'Target location.'; }
                field(LocationCountry; Rec."Location Country/Region FF") { ApplicationArea = All; Caption = 'Location Country/Region'; Editable = false; }
                field(Active; Rec.Active) { ApplicationArea = All; }
            }
        }
    }
}

page 89617 "WLM Dim Filter Values"
{
    PageType = ListPart;
    SourceTable = "WLM Dim Filter Value";
    Caption = 'Dimension Filter Values';
    ApplicationArea = All;
    Editable = true;
    layout
    {
        area(content)
        {
            repeater(Rep)
            {
                field(DimensionCode; Rec."Dimension Code") { ApplicationArea = All; }
                field(DimensionValueCode; Rec."Dimension Value Code")
                {
                    ApplicationArea = All;
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        DimVal: Record "Dimension Value";
                    begin
                        if Rec."Dimension Code" = '' then
                            exit(false);
                        DimVal.Reset();
                        DimVal.SetRange("Dimension Code", Rec."Dimension Code");
                        if PAGE.RunModal(PAGE::"Dimension Values", DimVal) = Action::LookupOK then begin
                            Rec.Validate("Dimension Value Code", DimVal.Code);
                            exit(true);
                        end;
                        exit(false);
                    end;
                }
                field(UseRegionMap; Rec."Use Region Location Mapping")
                {
                    ApplicationArea = All;
                    ToolTip = 'If true, route sales via Region → Location Mapping; else use original sales location.';
                }
                field(Active; Rec.Active) { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(EditFiltersInExcel)
            {
                Caption = 'Edit in Excel';
                ApplicationArea = All;
                Image = Excel;
                ToolTip = 'Opens the Planning Filter Values list in Excel for bulk maintenance.';
                trigger OnAction()
                begin
                    PAGE.Run(PAGE::"WLM Dim Filter Worksheet");
                end;
            }
            action(ActivateFilters)
            {
                Caption = 'Mark Selected Active';
                ApplicationArea = All;
                Image = SelectEntries;
                ToolTip = 'Activates the selected dimension values so those cohorts participate in planning.';
                trigger OnAction()
                begin
                    SetActiveForSelection(true);
                end;
            }
            action(DeactivateFilters)
            {
                Caption = 'Mark Selected Inactive';
                ApplicationArea = All;
                Image = Cancel;
                ToolTip = 'Deactivates the selected dimension values to exclude them from planning.';
                trigger OnAction()
                begin
                    SetActiveForSelection(false);
                end;
            }
        }
    }

    local procedure SetActiveForSelection(NewState: Boolean)
    var
        Selection: Record "WLM Dim Filter Value";
    begin
        CurrPage.SetSelectionFilter(Selection);
        if Selection.IsEmpty() then begin
            Selection.Reset();
            Selection.SetRange("Dimension Code", Rec."Dimension Code");
            Selection.SetRange("Dimension Value Code", Rec."Dimension Value Code");
        end;

        if not Selection.FindSet() then
            exit;

        repeat
            if Selection.Active <> NewState then begin
                Selection.Active := NewState;
                Selection.Modify(true);
            end;
        until Selection.Next() = 0;
    end;
}

page 89670 "WLM Seasonality Filter Values"
{
    PageType = ListPart;
    SourceTable = "WLM Seasonality Filter Value";
    Caption = 'Seasonality Filter Values';
    ApplicationArea = All;
    Editable = true;
    layout
    {
        area(content)
        {
            repeater(Rep)
            {
                field(DimensionCode; Rec."Dimension Code") { ApplicationArea = All; }
                field(DimensionValueCode; Rec."Dimension Value Code")
                {
                    ApplicationArea = All;
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        DimVal: Record "Dimension Value";
                    begin
                        if Rec."Dimension Code" = '' then
                            exit(false);
                        DimVal.Reset();
                        DimVal.SetRange("Dimension Code", Rec."Dimension Code");
                        if PAGE.RunModal(PAGE::"Dimension Values", DimVal) = Action::LookupOK then begin
                            Rec.Validate("Dimension Value Code", DimVal.Code);
                            exit(true);
                        end;
                        exit(false);
                    end;
                }
                field(Active; Rec.Active) { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(EditSeasonalityFiltersInExcel)
            {
                Caption = 'Edit in Excel';
                ApplicationArea = All;
                Image = Excel;
                ToolTip = 'Opens the Seasonality Filter Values list in Excel for quick editing.';
                trigger OnAction()
                begin
                    PAGE.Run(PAGE::"WLM Seasonality Filter WS");
                end;
            }
            action(ActivateSeasonalityFilters)
            {
                Caption = 'Mark Selected Active';
                ApplicationArea = All;
                Image = SelectEntries;
                ToolTip = 'Activates the selected seasonality dimension values so they can store attribution.';
                trigger OnAction()
                begin
                    SetActiveForSelection(true);
                end;
            }
            action(DeactivateSeasonalityFilters)
            {
                Caption = 'Mark Selected Inactive';
                ApplicationArea = All;
                Image = Cancel;
                ToolTip = 'Deactivates the selected seasonality dimension values to exclude them.';
                trigger OnAction()
                begin
                    SetActiveForSelection(false);
                end;
            }
        }
    }

    local procedure SetActiveForSelection(NewState: Boolean)
    var
        Selection: Record "WLM Seasonality Filter Value";
    begin
        CurrPage.SetSelectionFilter(Selection);
        if Selection.IsEmpty() then begin
            Selection.Reset();
            Selection.SetRange("Dimension Code", Rec."Dimension Code");
            Selection.SetRange("Dimension Value Code", Rec."Dimension Value Code");
        end;

        if not Selection.FindSet() then
            exit;

        repeat
            if Selection.Active <> NewState then begin
                Selection.Active := NewState;
                Selection.Modify(true);
            end;
        until Selection.Next() = 0;
    end;
}

page 89677 "WLM Seasonality Attribution"
{
    PageType = ListPart;
    SourceTable = "WLM Seasonality Attribution";
    Caption = 'Stored Seasonality Attribution';
    ApplicationArea = All;
    Editable = true;
    layout
    {
        area(content)
        {
            repeater(Rep)
            {
                field(DimCode; Rec."Dimension Code") { ApplicationArea = All; }
                field(DimValue; Rec."Dimension Value Code") { ApplicationArea = All; }
                field(MonthNo; Rec."Month No") { ApplicationArea = All; ToolTip = '0 = default for all months'; }
                field(LocationCode; Rec."Location Code") { ApplicationArea = All; Visible = false; }
                field(LocationCountry; Rec."Country/Region Code FF") { ApplicationArea = All; Editable = false; Visible = true; }
                field(MonthPct; Rec."Month %") { ApplicationArea = All; }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(EditProfilesInExcel)
            {
                Caption = 'Edit in Excel';
                ApplicationArea = All;
                Image = Excel;
                ToolTip = 'Opens the stored seasonality attribution in Excel for mass updates.';
                trigger OnAction()
                begin
                    PAGE.Run(PAGE::"WLM Seasonality Profiles WS");
                end;
            }
        }
    }
}

page 89631 "WLM Forecast Entries"
{
    PageType = List;
    SourceTable = "WLM Forecast Entry";
    Caption = 'WLM Forecast Entries';
    UsageCategory = Lists;
    ApplicationArea = All;
    layout
    {
        area(content)
        {
            repeater(Rep)
            {
                field(ForecastName; Rec."Forecast Name") { ApplicationArea = All; }
                field(ItemNo; Rec."Item No.") { ApplicationArea = All; }
                field(VendorNo; Rec."Vendor No. FF") { ApplicationArea = All; Caption = 'Vendor No.'; Editable = false; }
                field(LocationCode; Rec."Location Code") { ApplicationArea = All; }
                field(ForecastDate; Rec."Forecast Date") { ApplicationArea = All; }
                field(Quantity; Rec.Quantity) { ApplicationArea = All; }
                field(HistoricalSalesQty; Rec."Historical Sales Qty")
                {
                    ApplicationArea = All;
                    Caption = 'Historical Sales (Actual)';
                    Editable = false;
                    ToolTip = 'Actual sales quantity from the historical period used to generate this forecast.';
                }
                field(MultiplierUsed; Rec."Multiplier Used %")
                {
                    ApplicationArea = All;
                    Caption = 'Multiplier %';
                    Editable = false;
                    ToolTip = 'The multiplier percentage applied to historical sales to calculate the forecast quantity.';
                }
                field(VariancePct; VariancePct)
                {
                    ApplicationArea = All;
                    Caption = 'Variance %';
                    Editable = false;
                    DecimalPlaces = 0 : 2;
                    ToolTip = 'Percentage difference: (Forecast - Historical × Multiplier) / (Historical × Multiplier). A value other than 0 indicates a discrepancy.';
                    Style = Unfavorable;
                    StyleExpr = HasVariance;
                }
                field(ExpectedQty; ExpectedQty)
                {
                    ApplicationArea = All;
                    Caption = 'Expected Qty';
                    Editable = false;
                    ToolTip = 'Expected forecast quantity = Historical Sales × Multiplier %. Compare to actual Quantity to validate.';
                }
                field(HistPeriodStart; Rec."Historical Period Start")
                {
                    ApplicationArea = All;
                    Caption = 'Hist. Period Start';
                    Editable = false;
                    Visible = false;
                }
                field(HistPeriodEnd; Rec."Historical Period End")
                {
                    ApplicationArea = All;
                    Caption = 'Hist. Period End';
                    Editable = false;
                    Visible = false;
                }
                field(CreatedAt; Rec."Created At") { ApplicationArea = All; Editable = false; }
                field(CreatedBy; Rec."Created By") { ApplicationArea = All; Editable = false; }
                field(ItemDescriptionFE; Rec."Item Description FF") { ApplicationArea = All; Caption = 'Description'; Editable = false; }
                field(ItemCategoryCodeFE; Rec."Item Category Code FF") { ApplicationArea = All; Caption = 'Item Category Code'; Editable = false; }
                field(GD1; Rec."Global Dimension 1 Code FF") { ApplicationArea = All; Editable = false; }
                field(GD2; Rec."Global Dimension 2 Code FF") { ApplicationArea = All; Editable = false; }
                field(SD3; Rec."Shortcut Dim 3 Value FF") { ApplicationArea = All; Editable = false; }
                field(SD4; Rec."Shortcut Dim 4 Value FF") { ApplicationArea = All; Editable = false; }
                field(SD5; Rec."Shortcut Dim 5 Value FF") { ApplicationArea = All; Editable = false; }
                field(SD6; Rec."Shortcut Dim 6 Value FF") { ApplicationArea = All; Editable = false; }
                field(SD7; Rec."Shortcut Dim 7 Value FF") { ApplicationArea = All; Editable = false; }
                field(SD8; Rec."Shortcut Dim 8 Value FF") { ApplicationArea = All; Editable = false; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RecalculateHistoricalData)
            {
                ApplicationArea = All;
                Caption = 'Recalculate Historical Data';
                ToolTip = 'Backfill historical sales, multiplier, and period data for existing forecast entries to enable comparison validation.';
                Image = Recalculate;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    FcstEntry: Record "WLM Forecast Entry";
                    FcstBuilder: Codeunit "WLM FcstBuilder";
                    ConfirmMsg: Label 'This will recalculate historical data for %1 forecast entries. Continue?';
                    DoneMsg: Label 'Recalculated historical data for %1 entries.';
                    EntryCount: Integer;
                begin
                    FcstEntry.Copy(Rec);
                    EntryCount := FcstEntry.Count();

                    if EntryCount = 0 then begin
                        Message('No forecast entries to process.');
                        exit;
                    end;

                    if not Confirm(ConfirmMsg, true, EntryCount) then
                        exit;

                    if FcstEntry.FindSet() then
                        repeat
                            FcstBuilder.RecalculateHistoricalDataForEntry(FcstEntry);
                        until FcstEntry.Next() = 0;

                    Message(DoneMsg, EntryCount);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CalculateVariance();
    end;

    var
        VariancePct: Decimal;
        ExpectedQty: Decimal;
        HasVariance: Boolean;

    local procedure CalculateVariance()
    begin
        ExpectedQty := 0;
        VariancePct := 0;
        HasVariance := false;

        if (Rec."Historical Sales Qty" <> 0) and (Rec."Multiplier Used %" <> 0) then begin
            ExpectedQty := Round(Rec."Historical Sales Qty" * (Rec."Multiplier Used %" / 100), 1);
            if ExpectedQty <> 0 then begin
                VariancePct := ((Rec.Quantity - ExpectedQty) / ExpectedQty) * 100;
                HasVariance := (VariancePct > 5) or (VariancePct < -5);
            end;
        end;
    end;
}

page 89613 "WLM FcstSetupCard"
{
    PageType = Card;
    SourceTable = "WLM FcstSetup";
    Caption = 'WLM Planning Module';
    ApplicationArea = All;
    UsageCategory = Administration;
    layout
    {
        area(content)
        {
            group(General)
            {
                field(DefaultForecastName; Rec."Default Forecast Name") { ApplicationArea = All; }
                field(DefaultBucket; Rec."Default Bucket") { ApplicationArea = All; }
                field(LookbackMonths; Rec."Lookback Months")
                {
                    ApplicationArea = All;
                    ToolTip = 'Number of prior buckets to include.';
                }
                field(ProjectionMonths; Rec."Projection Months")
                {
                    ApplicationArea = All;
                    ToolTip = 'Number of forward months to project.';
                }
                field(ReplaceMode; Rec."Replace Mode") { ApplicationArea = All; }
                field(IncludeReturns; Rec."Include Returns") { ApplicationArea = All; }
                field(DefaultSelfMult; Rec."Default Self Multiplier %") { ApplicationArea = All; }
                field(DefaultPar; Rec."Default Par Stock Target") { ApplicationArea = All; Caption = 'Default Par Stock Target (Months)'; }
                field(FactorSubsInventory; Rec."Factor Subs in Inventory")
                {
                    ApplicationArea = All;
                    Caption = 'Factor Substitutes in Inventory';
                    ToolTip = 'When enabled, on-hand inventory for items listed as substitutions will count toward the primary item''s inventory during planning.';
                }
                field(FactorSubsSalesHist; Rec."Factor Subs in Sales Hist")
                {
                    ApplicationArea = All;
                    Caption = 'Factor Substitutes in Sales History';
                    ToolTip = 'When enabled, historical sales for items that list this item as a substitute will be consolidated into base demand for this item.';
                }
                field(FactorSubsParDashboard; Rec."Factor Subs in Par Dashboard")
                {
                    ApplicationArea = All;
                    Caption = 'Factor Substitutes in Item Par Dashboard';
                    ToolTip = 'When enabled, purchasing-blocked items that list this item as a substitute will roll their inventory, inbound, costs, and demand into the substitute on the Par Dashboard. Donor items will be hidden.';
                }
                field(FactorSubsInbounds; Rec."Factor Subs in Inbound")
                {
                    ApplicationArea = All;
                    Caption = 'Factor Substitutes in Inbounds';
                    ToolTip = 'When enabled, inbound purchases/transfers for donor items roll up to the substitute in planning calculations.';
                }
                field(FactorSubsSalesDemand; Rec."Factor Subs in Sales Demand")
                {
                    ApplicationArea = All;
                    Caption = 'Factor Substitutes in Open Sales Demand';
                    ToolTip = 'When enabled, open sales orders for items that list this item as a substitute will also count as demand against this item.';
                }
                field(PlanningUOM; Rec."Planning UOM Code")
                {
                    ApplicationArea = All;
                    Caption = 'Planning UOM Code';
                    ToolTip = 'Default unit of measure used when translating demand into loading units.';
                }
                field(ResourcePlanning; Rec."Resource Planning Buckets")
                {
                    ApplicationArea = All;
                    Caption = 'Resource Planning Horizon';
                    ToolTip = 'Number of Default Bucket intervals to plan when generating load suggestions (e.g., 3 months).';
                }
                group(DefaultLoadProfileFallback)
                {
                    Caption = 'Load Profile Fallbacks';
                    field(DefaultParentUnit; Rec."Default Parent Load Unit")
                    {
                        ApplicationArea = All;
                        Caption = 'Default Parent Load Unit';
                        ToolTip = 'Applied when no specific load profile exists for the vendor/location combination.';
                    }
                    field(DefaultParentCapacity; Rec."Default Parent Unit Capacity")
                    {
                        ApplicationArea = All;
                        Caption = 'Default Parent Unit Capacity';
                        ToolTip = 'Fallback capacity (parent units) to plan when a profile is not found.';
                    }
                    field(DefaultMinFill; Rec."Default Min Fill Percent")
                    {
                        ApplicationArea = All;
                        Caption = 'Default Min Fill %';
                        ToolTip = 'Minimum fill percentage enforced when using fallback settings.';
                    }
                    field(DefaultAllowPartial; Rec."Default Allow Partial Load")
                    {
                        ApplicationArea = All;
                        Caption = 'Allow Partial Load (Fallback)';
                        ToolTip = 'Determines if fallback loads can release without meeting min-fill.';
                    }
                }
                group(Numbering)
                {
                    Caption = 'Numbering';
                    field(LoadBatchNoSeries; Rec."Load Batch No. Series")
                    {
                        ApplicationArea = All;
                        Caption = 'Load Batch No. Series';
                        ToolTip = 'Select the No. Series that controls the Batch No. on generated load batches. Leave blank to use legacy labels.';
                    }
                    field(LoadBatchSequence; Rec."Load Batch Sequence No.")
                    {
                        ApplicationArea = All;
                        Caption = 'Last Load Batch No.';
                        Editable = false;
                        ToolTip = 'Displays the last sequential batch number assigned when a number series is not provided.';
                    }
                }
            }
            group(ItemExclusions)
            {
                Caption = 'Item Exclusions (for Pull/Cleanup)';
                InstructionalText = 'These toggles apply when pulling items into planning and when removing obsolete items.';
                field(ExcludePurchasingBlocked; Rec."Exclude Purchasing Blocked")
                {
                    ApplicationArea = All;
                    ToolTip = 'If enabled, items with Purchasing Blocked = true will be excluded from Seed/Cleanup.';
                }
                field(ExcludeSalesBlocked; Rec."Exclude Sales Blocked")
                {
                    ApplicationArea = All;
                    ToolTip = 'If enabled, items with Sales Blocked = true will be excluded from Seed/Cleanup.';
                }
                field(ExcludeBlocked; Rec."Exclude Blocked")
                {
                    ApplicationArea = All;
                    ToolTip = 'If enabled, items with Blocked = true will be excluded from Seed/Cleanup.';
                }
                field(ExcludeNonInventory; Rec."Exclude Non-Inventory Items")
                {
                    ApplicationArea = All;
                    ToolTip = 'If enabled, only Inventory items will be included in Seed/Cleanup (Non-Inventory excluded).';
                }
            }
            group(DemandDating)
            {
                Caption = 'Demand Dating';
                field(DemandDateSource; Rec."Demand Date Source")
                {
                    ApplicationArea = All;
                    ToolTip = 'Select the date used to attribute and bucket historical demand.';
                }
            }
            group(Classification)
            {
                Caption = 'Planning Filters';
                field(DimensionFilter; Rec."Dimension Filter")
                {
                    ApplicationArea = All;
                    ToolTip = 'Blank = plan all items. If set, plan only items with Default Dimension values listed below.';
                }
                part(DimFilterValues; "WLM Dim Filter Values")
                {
                    ApplicationArea = All;
                    Caption = 'Filter Values';
                    SubPageLink = "Dimension Code" = field("Dimension Filter");
                }
            }
            group(SeasonalityByDimension)
            {
                Caption = 'Seasonality by Dimension';
                group(SeasonalitySettings)
                {
                    field(WBDimensionFilter; Rec."WB Dimension Filter")
                    {
                        ApplicationArea = All;
                        Caption = 'Seasonality Dimension Filter';
                        ToolTip = 'Dimension used to build and apply stored seasonality profiles across planning rows.';
                        trigger OnValidate()
                        var
                            Season: Codeunit "WLM SeasonalityBuilder";
                        begin
                            Season.PreloadFilterValues();
                            Season.BuildSeasonalityFromHistory();
                        end;
                    }
                }
                part(SeasonalityFilterValuesPane; "WLM Seasonality Filter Values")
                {
                    Caption = 'Filter Values';
                    ApplicationArea = All;
                    SubPageLink = "Dimension Code" = field("WB Dimension Filter");
                }
                part(SeasonalityProfilesPane; "WLM Seasonality Attribution")
                {
                    Caption = 'Seasonality Profiles';
                    ApplicationArea = All;
                    SubPageLink = "Dimension Code" = field("WB Dimension Filter");
                }
            }
            group(Locations)
            {
                Caption = 'Locations to Plan';
                part(FcstLocs; "WLM Fcst Locations") { ApplicationArea = All; }
            }
            group(RegionMapping)
            {
                Caption = 'Optimal Region Coverage → Location Mapping';
                part(RegionMap; "WLM Region Location Map") { ApplicationArea = All; }
            }
            group(LoadingUnits)
            {
                Caption = 'Order Loading Units';
                part(OrderLoadingUnitsPart; "WLM Order Loading Units") { ApplicationArea = All; }
            }
            group(ItemLoadingUnitGroup)
            {
                Caption = 'Item Loading Units';
                part(ItemLoadingUnitsPart; "WLM Item Loading Units") { ApplicationArea = All; }
            }
            group(ItemLoadFitsGroup)
            {
                Caption = 'Item Loading Fits';
                part(ItemLoadFitsPart; "WLM Item Load Fit Sub")
                {
                    ApplicationArea = All;
                    Provider = ItemLoadingUnitsPart;
                    SubPageLink = "Item No." = field("Item No.");
                }
            }
            group(VendorCapacityGroup)
            {
                Caption = 'Vendor Capacity Calendar';
                part(VendorCapacityPart; "WLM Vendor Capacity") { ApplicationArea = All; }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(Initialize)
            {
                Caption = 'Initialize';
                ApplicationArea = All;
                ToolTip = 'Creates the singleton Forecast Setup record if it does not already exist.';
                trigger OnAction()
                var
                    S: Record "WLM FcstSetup";
                begin
                    if not S.Get('SETUP') then begin
                        S.Init();
                        S.Insert(true);
                        Message('Setup row created.');
                    end else
                        Message('Setup row already exists.');
                end;
            }

            action(OpenItemParDashboard)
            {
                Caption = 'Promote → WLM Item Par Dashboard';
                ApplicationArea = All;
                Image = Navigate;
                ToolTip = 'Open the WLM Item Par Dashboard to review par, off-par, days of inventory, depletion and turns by item using the current forecast setup.';
                trigger OnAction()
                begin
                    Page.Run(Page::"WLM Item Par Dashboard");
                end;
            }
            action(RecomputeItemLoadFits)
            {
                Caption = 'Recompute Item Load Fits';
                ApplicationArea = All;
                Image = Calculate;
                ToolTip = 'Recalculates item load fits for all item loading units against all parent load units.';
                trigger OnAction()
                var
                    FitMgt: Codeunit "WLM Item Load Fit Mgt";
                begin
                    FitMgt.RecomputeAllItems();
                    Message('Item load fits recomputed for all items.');
                end;
            }
            action(LoadLocations)
            {
                Caption = 'Load Locations';
                ApplicationArea = All;
                Image = Import;
                ToolTip = 'Loads all locations into the planning list so you can mark which ones are active.';
                trigger OnAction()
                var
                    L: Record Location;
                    F: Record "WLM Fcst Location";
                begin
                    if L.FindSet() then
                        repeat
                            if not F.Get(L.Code) then begin
                                F.Init();
                                F."Location Code" := L.Code;
                                F.Active := true;
                                F.Insert(true);
                            end;
                        until L.Next() = 0;
                    Message('Locations loaded. Review Active to include/exclude.');
                end;
            }
            action(LoadPlanningFilterValues)
            {
                Caption = 'Load Planning Filter Values';
                ApplicationArea = All;
                Image = Import;
                ToolTip = 'Pulls all dimension values for the configured Planning Filter dimension so you do not have to enter them manually.';
                trigger OnAction()
                var
                    Loader: Codeunit "WLM FilterLoader";
                    Setup: Record "WLM FcstSetup";
                    Added: Integer;
                    DimCode: Code[20];
                begin
                    if not Setup.Get('SETUP') then
                        Error('Initialize WLM Forecast Setup first.');

                    DimCode := UpperCase(Setup."Dimension Filter");
                    Added := Loader.LoadPlanningFilterValues();

                    if Added = 0 then
                        Message('Planning filter values were already aligned for dimension %1.', DimCode)
                    else
                        Message('%1 planning filter value(s) added for dimension %2.', Added, DimCode);
                end;
            }
            action(LoadSeasonalityFilterValues)
            {
                Caption = 'Load Seasonality Filter Values';
                ApplicationArea = All;
                Image = Import;
                ToolTip = 'Syncs the Seasonality Filter values from the configured dimension.';
                trigger OnAction()
                var
                    Season: Codeunit "WLM SeasonalityBuilder";
                    Setup: Record "WLM FcstSetup";
                    DimCode: Code[20];
                begin
                    if not Setup.Get('SETUP') then
                        Error('Initialize WLM Forecast Setup first.');

                    DimCode := UpperCase(Setup."WB Dimension Filter");
                    if DimCode = '' then
                        Error('Set the Seasonality Dimension Filter before loading values.');

                    Season.PreloadFilterValues();
                    Message('Seasonality filter values synced for dimension %1.', DimCode);
                end;
            }
            action(BuildSeasonalityProfiles)
            {
                Caption = 'Build Seasonality Profiles';
                ApplicationArea = All;
                Image = Calculate;
                ToolTip = 'Rebuilds seasonality attribution (%) from shipment and return history for the configured seasonality dimension.';
                trigger OnAction()
                var
                    Season: Codeunit "WLM SeasonalityBuilder";
                    Setup: Record "WLM FcstSetup";
                    DimCode: Code[20];
                begin
                    if not Setup.Get('SETUP') then
                        Error('Initialize WLM Forecast Setup first.');

                    DimCode := UpperCase(Setup."WB Dimension Filter");
                    if DimCode = '' then
                        Error('Set the Seasonality Dimension Filter before building profiles.');

                    Season.BuildSeasonalityFromHistory();
                    Message('Seasonality profiles rebuilt for dimension %1.', DimCode);
                end;
            }
            action(SeedItemLoadingUnits)
            {
                Caption = 'Load Item Loading Units';
                ApplicationArea = All;
                Image = Import;
                ToolTip = 'Create item loading unit records for items that are missing from the subpage using default planning settings.';
                trigger OnAction()
                var
                    Setup: Record "WLM FcstSetup";
                    Seeder: Codeunit "WLM ItemLoadingSeed";
                    Inserted: Integer;
                begin
                    if not Setup.Get('SETUP') then
                        Error('Initialize WLM Forecast Setup first.');

                    Inserted := Seeder.SeedAll();

                    if Inserted = 0 then
                        Message('All items already have loading unit definitions.')
                    else
                        Message('%1 item loading unit(s) added.', Inserted);

                    CurrPage.ItemLoadingUnitsPart.PAGE.Update(false);
                end;
            }
            action(EnableNightlyForecastJob)
            {
                Caption = 'Enable Nightly Forecast Job';
                ApplicationArea = All;
                Image = Start;
                ToolTip = 'Ensures the job queue entry exists so the nightly forecast build runs automatically.';
                trigger OnAction()
                var
                    Installer: Codeunit "WLM FcstInstall";
                begin
                    if not Installer.TryEnsureJobQueue() then
                        Error('Failed to seed the Job Queue entry.');
                    Message('Nightly forecast job is present and set to Ready.');
                end;
            }
            action(PromoteToWLMEntries)
            {
                Caption = 'Promote → WLM Forecast Entries';
                ApplicationArea = All;
                Image = Process;
                ToolTip = 'Builds the latest forecast for all active items and writes the results to WLM Forecast Entries.';
                trigger OnAction()
                var
                    Setup: Record "WLM FcstSetup";
                    Promote: Codeunit "WLM PromoteForecast";
                    Builder: Codeunit "WLM FcstBuilder";
                    FromDate, ToDate : Date;
                    FcstName: Code[20];
                    Affected: Integer;
                begin
                    if not Setup.Get('SETUP') then
                        Error('Initialize WLM Forecast Setup first.');

                    // Build latest forecast entries before promotion
                    Builder.BuildForAllActiveUsingDefaults();

                    FcstName := Setup."Default Forecast Name";
                    CalcPromotionDateRange(Setup, FromDate, ToDate);

                    Affected := Promote.PromoteToWLMForecastEntries(FcstName, FromDate, ToDate, Setup."Replace Mode");
                    Message('%1 forecast line(s) confirmed in WLM Forecast Entries for "%2" (%3..%4).',
                        Affected, FcstName, FromDate, ToDate);
                end;
            }
            action(PromoteWLMToDemand)
            {
                Caption = 'Promote → Demand Forecast';
                ApplicationArea = All;
                Image = Process;
                ToolTip = 'Copies the WLM Forecast Entries into the standard Demand Forecast tables.';
                trigger OnAction()
                var
                    Setup: Record "WLM FcstSetup";
                    Promote: Codeunit "WLM PromoteForecast";
                    FromDate, ToDate : Date;
                    FcstName: Code[20];
                    Affected: Integer;
                begin
                    if not Setup.Get('SETUP') then
                        Error('Initialize WLM Forecast Setup first.');

                    FcstName := Setup."Default Forecast Name";
                    CalcPromotionDateRange(Setup, FromDate, ToDate);

                    Affected := Promote.PromoteToDemandForecast(FcstName, FromDate, ToDate, Setup."Replace Mode");
                    Message('Promoted %1 forecast line(s) to "%2" for %3..%4.',
                        Affected, FcstName, FromDate, ToDate);
                end;
            }
            action(RebuildLoadSuggestions)
            {
                Caption = 'Rebuild Load Suggestions';
                ApplicationArea = All;
                Image = Refresh;
                ToolTip = 'Clears and rebuilds load suggestions for the configured horizon using the latest plan data.';
                trigger OnAction()
                var
                    Setup: Record "WLM FcstSetup";
                    Mgt: Codeunit "WLM LoadSuggestionMgt";
                    FromDate: Date;
                    ToDate: Date;
                begin
                    if not Setup.Get('SETUP') then
                        Error('Initialize WLM Forecast Setup first.');

                    CalcPromotionDateRange(Setup, FromDate, ToDate);
                    ApplyResourcePlanningLimit(Setup, FromDate, ToDate);
                    Mgt.RebuildSuggestions(FromDate, ToDate);
                    Message('Load suggestions rebuilt for %1..%2.', FromDate, ToDate);
                end;
            }
            action(OpenLoadSuggestions)
            {
                Caption = 'Open Load Suggestions';
                ApplicationArea = All;
                Image = ListPage;
                ToolTip = 'Opens the load suggestions list so planners can review, release, or skip loads.';
                RunObject = page "WLM Load Batches";
            }
            action(OpenPlanningSchedule)
            {
                Caption = 'Promote → WLM Planning Schedule';
                ApplicationArea = All;
                Image = Navigate;
                ToolTip = 'Review demand, supply, net, and running balances by item/location/date used for load planning.';
                RunObject = page "WLM Planning Schedule";
            }
            action(PullItemsToPlanning_Setup)
            {
                Caption = 'Pull Items → Planning';
                ApplicationArea = All;
                Image = Import;
                ToolTip = 'Blank Dimension Filter = plan all items. If set, plan only Default Dimension values below.';
                trigger OnAction()
                var
                    Seeder: Codeunit "WLM RetailSeed";
                    CountAdded: Integer;
                begin
                    CountAdded := Seeder.SeedItemsToPlanning_FromDimensionFilter();
                    Message('%1 planning row(s) added (self rows per Country). Existing rows were skipped.', CountAdded);
                end;
            }
        }
    }

    local procedure CalcDefaultDateRange_PerBucket(Bucket: Option Day,Week,Month; LookbackPeriod: Integer; var FromDate: Date; var ToDate: Date)
    var
        firstOfTo, firstOfFrom : Date;
        days: Integer;
        monday, sunday : Date;
        baseToday: Date;
    begin
        baseToday := Today;
        if baseToday = 0D then baseToday := WorkDate;
        ToDate := baseToday;

        case Bucket of
            Bucket::Day:
                begin
                    if LookbackPeriod < 0 then LookbackPeriod := 0;
                    FromDate := ToDate - LookbackPeriod;
                end;
            Bucket::Week:
                begin
                    if LookbackPeriod < 0 then LookbackPeriod := 0;
                    days := LookbackPeriod * 7;
                    FromDate := ToDate - days;
                    monday := FromDate - (Date2DWY(FromDate, 1) - 1);
                    FromDate := monday;
                    sunday := ToDate + (7 - Date2DWY(ToDate, 1));
                    ToDate := sunday;
                end;
            Bucket::Month:
                begin
                    firstOfTo := DMY2Date(1, Date2DMY(ToDate, 2), Date2DMY(ToDate, 3));
                    if firstOfTo = 0D then firstOfTo := baseToday;
                    if LookbackPeriod < 0 then LookbackPeriod := 0;
                    FromDate := CalcDate(StrSubstNo('-%1M', LookbackPeriod), firstOfTo);
                    firstOfFrom := DMY2Date(1, Date2DMY(FromDate, 2), Date2DMY(FromDate, 3));
                    if firstOfFrom <> 0D then
                        FromDate := firstOfFrom
                    else
                        FromDate := firstOfTo;
                    ToDate := CalcDate('<CM+1D-1D>', firstOfTo);
                    if ToDate = 0D then ToDate := firstOfTo;
                end;
        end;
    end;

    local procedure CalcPromotionDateRange(Setup: Record "WLM FcstSetup"; var FromDate: Date; var ToDate: Date)
    var
        today: Date;
        firstOfThis: Date;
        d: Date;
    begin
        today := Today;
        if today = 0D then
            today := WorkDate;

        case Setup."Default Bucket" of
            Setup."Default Bucket"::Day:
                begin
                    FromDate := today;
                    ToDate := CalcDate(StrSubstNo('+%1M', Setup."Projection Months"), today);
                end;
            Setup."Default Bucket"::Week:
                begin
                    FromDate := today - (Date2DWY(today, 1) - 1);
                    d := CalcDate(StrSubstNo('+%1M', Setup."Projection Months"), today);
                    ToDate := d + (7 - Date2DWY(d, 1));
                end;
            Setup."Default Bucket"::Month:
                begin
                    firstOfThis := DMY2Date(1, Date2DMY(today, 2), Date2DMY(today, 3));
                    if firstOfThis = 0D then
                        firstOfThis := today;
                    FromDate := firstOfThis;
                    ToDate := CalcDate(StrSubstNo('+%1M', Setup."Projection Months"), firstOfThis);
                    if ToDate = 0D then
                        ToDate := firstOfThis;
                    ToDate := CalcDate('<CM+1D-1D>', ToDate);
                end;
        end;
    end;

    local procedure ApplyResourcePlanningLimit(Setup: Record "WLM FcstSetup"; var FromDate: Date; var ToDate: Date)
    var
        Buckets: Integer;
        ProposedEnd: Date;
        StartDate: Date;
    begin
        Buckets := Setup."Resource Planning Buckets";
        if Buckets <= 0 then
            exit;

        StartDate := FromDate;
        if StartDate = 0D then
            StartDate := WorkDate;

        case Setup."Default Bucket" of
            Setup."Default Bucket"::Day:
                ProposedEnd := StartDate + (Buckets - 1);
            Setup."Default Bucket"::Week:
                begin
                    StartDate := StartDate - (Date2DWY(StartDate, 1) - 1);
                    ProposedEnd := StartDate + ((Buckets * 7) - 1);
                end;
            Setup."Default Bucket"::Month:
                begin
                    StartDate := DMY2Date(1, Date2DMY(StartDate, 2), Date2DMY(StartDate, 3));
                    if StartDate = 0D then
                        StartDate := FromDate;
                    ProposedEnd := CalcDate(StrSubstNo('+%1M', Buckets - 1), StartDate);
                    if ProposedEnd = 0D then
                        ProposedEnd := StartDate;
                    ProposedEnd := CalcDate('<CM+1D-1D>', ProposedEnd);
                end;
        end;

        if ProposedEnd = 0D then
            exit;

        FromDate := StartDate;
        if (ToDate = 0D) or (ProposedEnd < ToDate) then
            ToDate := ProposedEnd;
    end;
}

// ======================= CODEUNITS =======================

// ---- Seasonality Builder (fixed variables/filters; no inline var; AL-safe pipes)
codeunit 89678 "WLM SeasonalityBuilder"
{
    procedure PreloadFilterValues()
    var
        Setup: Record "WLM FcstSetup";
        DimVal: Record "Dimension Value";
        WbVal: Record "WLM Seasonality Filter Value";
        WBDimCode: Code[20];
    begin
        EnsureSetup(Setup);
        WBDimCode := UpperCase(Setup."WB Dimension Filter");
        if WBDimCode = '' then
            exit;

        DimVal.Reset();
        DimVal.SetRange("Dimension Code", WBDimCode);
        if DimVal.FindSet() then
            repeat
                if not WbVal.Get(WBDimCode, UpperCase(DimVal.Code)) then begin
                    WbVal.Init();
                    WbVal."Dimension Code" := WBDimCode;
                    WbVal."Dimension Value Code" := UpperCase(DimVal.Code);
                    WbVal.Active := true;
                    WbVal.Insert(true);
                end else begin
                    WbVal.Active := true;
                    WbVal.Modify(true);
                end;
            until DimVal.Next() = 0;
    end;

    procedure BuildSeasonalityFromHistory()
    var
        Setup: Record "WLM FcstSetup";
        Val: Record "WLM Seasonality Filter Value";
        DefDim: Record "Default Dimension";
        SalesShptLine: Record "Sales Shipment Line";
        SalesShptHeader: Record "Sales Shipment Header";
        ReturnShptLine: Record "Return Shipment Line";
        ReturnShptHeader: Record "Return Shipment Header";
        WBA: Record "WLM Seasonality Attribution";
        WBDimCode: Code[20];
        TodayD: Date;
        FromDate: Date;
        ToDate: Date;
        Items: List of [Code[20]];
        itemFilter: Text;
        CountryMonthTotals: Dictionary of [Text, Decimal];
        CountryTotals: Dictionary of [Code[10], Decimal];
        CountriesWithDemand: List of [Code[10]];
        CountryToLocation: Dictionary of [Code[10], Code[10]];
        LocationLookup: Code[10];
        Country: Code[10];
        CountryMonthKey: Text;
        MonthNo: Integer;
        Qty: Decimal;
        MonthPct: Decimal;
        CountryTotal: Decimal;
        CountryMonthQty: Decimal;
        IncludeReturns: Boolean;
        i: Integer;
    begin
        EnsureSetup(Setup);
        WBDimCode := UpperCase(Setup."WB Dimension Filter");
        if WBDimCode = '' then
            exit;

        IncludeReturns := Setup."Include Returns";

        TodayD := Today;
        if TodayD = 0D then
            TodayD := WorkDate;
        ToDate := TodayD;
        FromDate := CalcDate('-12M', ToDate);
        if FromDate = 0D then
            FromDate := ToDate;

        if not BuildCountryLocationMap(CountryToLocation) then
            exit;

        Val.Reset();
        Val.SetRange("Dimension Code", WBDimCode);
        Val.SetRange(Active, true);
        if Val.FindSet() then
            repeat
                Clear(Items);
                DefDim.Reset();
                DefDim.SetRange("Table ID", Database::Item);
                DefDim.SetRange("Dimension Code", WBDimCode);
                DefDim.SetRange("Dimension Value Code", Val."Dimension Value Code");
                if DefDim.FindSet() then
                    repeat
                        Items.Add(DefDim."No.");
                    until DefDim.Next() = 0;

                itemFilter := BuildItemFilter(Items);
                if itemFilter = '' then begin
                    ClearSeasonalityRows(WBA, WBDimCode, Val."Dimension Value Code");
                    continue;
                end;

                Clear(CountryMonthTotals);
                Clear(CountryTotals);
                Clear(CountriesWithDemand);

                // Sales shipments (positive demand)
                SalesShptLine.Reset();
                SalesShptLine.SetCurrentKey("Posting Date", "No.");
                SalesShptLine.SetFilter("No.", itemFilter);
                SalesShptLine.SetFilter(Type, '%1', SalesShptLine.Type::Item);
                SalesShptLine.SetRange("Posting Date", FromDate, ToDate);
                if SalesShptLine.FindSet() then
                    repeat
                        if not SalesShptHeader.Get(SalesShptLine."Document No.") then
                            continue;

                        Country := UpperCase(SalesShptHeader."Ship-to Country/Region Code");
                        if Country = '' then
                            continue;
                        if not CountryToLocation.Get(Country, LocationLookup) then
                            continue;

                        MonthNo := Date2DMY(GetShipmentDemandDate(Setup, SalesShptLine, SalesShptHeader), 2);
                        if (MonthNo < 1) or (MonthNo > 12) then
                            continue;

                        Qty := SalesShptLine.Quantity;
                        if Qty = 0 then
                            continue;
                        if Qty < 0 then
                            Qty := -Qty;

                        AddDemandEntry(Country, MonthNo, Qty, CountryTotals, CountryMonthTotals, CountriesWithDemand);
                    until SalesShptLine.Next() = 0;

                // Return shipments reduce demand (optional)
                if IncludeReturns then begin
                    ReturnShptLine.Reset();
                    ReturnShptLine.SetCurrentKey("Posting Date", "No.");
                    ReturnShptLine.SetFilter("No.", itemFilter);
                    ReturnShptLine.SetFilter(Type, '%1', ReturnShptLine.Type::Item);
                    ReturnShptLine.SetRange("Posting Date", FromDate, ToDate);
                    if ReturnShptLine.FindSet() then
                        repeat
                            if not ReturnShptHeader.Get(ReturnShptLine."Document No.") then
                                continue;
                            Country := UpperCase(ReturnShptHeader."Ship-to Country/Region Code");
                            if Country = '' then
                                continue;
                            if not CountryToLocation.Get(Country, LocationLookup) then
                                continue;

                            MonthNo := Date2DMY(ReturnShptLine."Posting Date", 2);
                            if (MonthNo < 1) or (MonthNo > 12) then
                                continue;

                            Qty := Abs(ReturnShptLine.Quantity);
                            if Qty = 0 then
                                continue;

                            AddDemandEntry(Country, MonthNo, -Qty, CountryTotals, CountryMonthTotals, CountriesWithDemand);
                        until ReturnShptLine.Next() = 0;
                end;

                // Remove previous attribution rows for this dimension value
                ClearSeasonalityRows(WBA, WBDimCode, Val."Dimension Value Code");

                // Emit attribution per country/location
                for i := 1 to CountriesWithDemand.Count() do begin
                    Country := CountriesWithDemand.Get(i);
                    if not CountryToLocation.Get(Country, LocationLookup) then
                        continue;
                    if not CountryTotals.Get(Country, CountryTotal) then
                        continue;
                    if CountryTotal <= 0 then
                        continue;

                    for MonthNo := 1 to 12 do begin
                        CountryMonthKey := GetCountryMonthKey(Country, MonthNo);
                        if not CountryMonthTotals.ContainsKey(CountryMonthKey) then
                            CountryMonthQty := 0
                        else begin
                            CountryMonthTotals.Get(CountryMonthKey, CountryMonthQty);
                            if CountryMonthQty < 0 then
                                CountryMonthQty := 0;
                        end;

                        if CountryTotal > 0 then
                            MonthPct := Round((CountryMonthQty / CountryTotal) * 100, 0.00001)
                        else
                            MonthPct := 0;

                        UpsertAttribution(WBA, WBDimCode, Val."Dimension Value Code", MonthNo, LocationLookup, MonthPct, 100);
                    end;
                end;
            until Val.Next() = 0;
    end;

    local procedure UpsertAttribution(var A: Record "WLM Seasonality Attribution"; DimCode: Code[20]; DimVal: Code[20]; MonthNo: Integer; LocCode: Code[10]; MonthPct: Decimal; LocPct: Decimal)
    begin
        A.Reset();
        A.SetRange("Dimension Code", DimCode);
        A.SetRange("Dimension Value Code", DimVal);
        A.SetRange("Month No", MonthNo);
        A.SetRange("Location Code", LocCode);
        if A.FindFirst() then begin
            A.Validate("Month %", MonthPct);
            A.Validate("Location %", LocPct);
            A.Modify(true);
        end else begin
            A.Init();
            A."Dimension Code" := DimCode;
            A."Dimension Value Code" := DimVal;
            A."Month No" := MonthNo;
            A."Location Code" := LocCode;
            A."Month %" := MonthPct;
            A."Location %" := LocPct;
            A.Insert(true);
        end;
    end;

    local procedure EnsureSetup(var Setup: Record "WLM FcstSetup")
    begin
        if not Setup.Get('SETUP') then begin Setup.Init(); Setup.Insert(true); end;
    end;

    local procedure ListContainsCode10(var L: List of [Code[10]]; V: Code[10]): Boolean
    var
        idx: Integer;
    begin
        for idx := 1 to L.Count() do
            if L.Get(idx) = V then
                exit(true);
        exit(false);
    end;

    local procedure BuildCountryLocationMap(var Map: Dictionary of [Code[10], Code[10]]): Boolean
    var
        LocOn: Record "WLM Fcst Location";
        LocRec: Record Location;
        Country: Code[10];
    begin
        Clear(Map);
        LocOn.Reset();
        LocOn.SetRange(Active, true);
        if not LocOn.FindSet() then
            exit(false);

        repeat
            if LocRec.Get(LocOn."Location Code") then begin
                Country := UpperCase(LocRec."Country/Region Code");
                if Country = '' then
                    continue;
                if not Map.ContainsKey(Country) then
                    Map.Add(Country, LocOn."Location Code");
            end;
        until LocOn.Next() = 0;

        exit(Map.Count() > 0);
    end;

    local procedure BuildItemFilter(var Items: List of [Code[20]]): Text
    var
        FilterTxt: Text;
        idx: Integer;
    begin
        FilterTxt := '';
        for idx := 1 to Items.Count() do begin
            if FilterTxt = '' then
                FilterTxt := Items.Get(idx)
            else
                FilterTxt := FilterTxt + '|' + Items.Get(idx);
        end;
        exit(FilterTxt);
    end;

    local procedure AddDemandEntry(Country: Code[10]; MonthNo: Integer; Amount: Decimal; var CountryTotals: Dictionary of [Code[10], Decimal]; var CountryMonthTotals: Dictionary of [Text, Decimal]; var Countries: List of [Code[10]])
    var
        Existing: Decimal;
        CountryMonthKey: Text;
    begin
        if Amount = 0 then
            exit;

        if CountryTotals.ContainsKey(Country) then begin
            CountryTotals.Get(Country, Existing);
            CountryTotals.Set(Country, Existing + Amount);
        end else begin
            CountryTotals.Add(Country, Amount);
            if not ListContainsCode10(Countries, Country) then
                Countries.Add(Country);
        end;

        CountryMonthKey := GetCountryMonthKey(Country, MonthNo);
        if CountryMonthTotals.ContainsKey(CountryMonthKey) then begin
            CountryMonthTotals.Get(CountryMonthKey, Existing);
            CountryMonthTotals.Set(CountryMonthKey, Existing + Amount);
        end else
            CountryMonthTotals.Add(CountryMonthKey, Amount);
    end;

    local procedure GetCountryMonthKey(Country: Code[10]; MonthNo: Integer): Text
    begin
        exit(StrSubstNo('%1|%2', Country, MonthNo));
    end;

    local procedure ClearSeasonalityRows(var WBA: Record "WLM Seasonality Attribution"; DimCode: Code[20]; DimVal: Code[20])
    begin
        WBA.Reset();
        WBA.SetRange("Dimension Code", DimCode);
        WBA.SetRange("Dimension Value Code", DimVal);
        if WBA.FindSet() then
            WBA.DeleteAll(true);
    end;

    local procedure GetShipmentDemandDate(Setup: Record "WLM FcstSetup"; ShptLine: Record "Sales Shipment Line"; ShptHeader: Record "Sales Shipment Header"): Date
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OrderDate: Date;
        ReqDate: Date;
        PromDate: Date;
        DocDate: Date;
        PostDate: Date;
        Candidate: Date;
        Earliest: Date;
    begin
        PostDate := ShptLine."Posting Date";
        DocDate := ShptHeader."Document Date";

        if ShptLine."Order No." <> '' then begin
            if SalesHeader.Get(SalesHeader."Document Type"::Order, ShptLine."Order No.") then
                OrderDate := SalesHeader."Order Date";

            if ShptLine."Order Line No." <> 0 then begin
                SalesLine.Reset();
                SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
                SalesLine.SetRange("Document No.", ShptLine."Order No.");
                SalesLine.SetRange("Line No.", ShptLine."Order Line No.");
                if SalesLine.FindFirst() then begin
                    ReqDate := SalesLine."Requested Delivery Date";
                    PromDate := SalesLine."Promised Delivery Date";
                end;
            end;
        end;

        case Setup."Demand Date Source" of
            Setup."Demand Date Source"::PostingDate:
                exit(PostDate);

            Setup."Demand Date Source"::DocumentDate:
                begin
                    if DocDate <> 0D then
                        exit(DocDate);
                    exit(PostDate);
                end;

            Setup."Demand Date Source"::OrderDate:
                begin
                    if OrderDate <> 0D then
                        exit(OrderDate);
                    if DocDate <> 0D then
                        exit(DocDate);
                    exit(PostDate);
                end;

            Setup."Demand Date Source"::RequestedDelivery:
                begin
                    if ReqDate <> 0D then
                        exit(ReqDate);
                    if PromDate <> 0D then
                        exit(PromDate);
                    if OrderDate <> 0D then
                        exit(OrderDate);
                    if DocDate <> 0D then
                        exit(DocDate);
                    exit(PostDate);
                end;

            Setup."Demand Date Source"::PromisedDelivery:
                begin
                    if PromDate <> 0D then
                        exit(PromDate);
                    if ReqDate <> 0D then
                        exit(ReqDate);
                    if OrderDate <> 0D then
                        exit(OrderDate);
                    if DocDate <> 0D then
                        exit(DocDate);
                    exit(PostDate);
                end;

            Setup."Demand Date Source"::EarliestOfAll:
                begin
                    Earliest := 0D;

                    Candidate := OrderDate;
                    if (Candidate <> 0D) and ((Earliest = 0D) or (Candidate < Earliest)) then
                        Earliest := Candidate;
                    Candidate := ReqDate;
                    if (Candidate <> 0D) and ((Earliest = 0D) or (Candidate < Earliest)) then
                        Earliest := Candidate;
                    Candidate := PromDate;
                    if (Candidate <> 0D) and ((Earliest = 0D) or (Candidate < Earliest)) then
                        Earliest := Candidate;
                    Candidate := DocDate;
                    if (Candidate <> 0D) and ((Earliest = 0D) or (Candidate < Earliest)) then
                        Earliest := Candidate;

                    if Earliest <> 0D then
                        exit(Earliest);
                    exit(PostDate);
                end;
        end;

        exit(PostDate);
    end;
}

codeunit 89679 "WLM FilterLoader"
{
    procedure LoadPlanningFilterValues(): Integer
    var
        Setup: Record "WLM FcstSetup";
        DimVal: Record "Dimension Value";
        FilterVal: Record "WLM Dim Filter Value";
        DimCode: Code[20];
        DimValueCode: Code[20];
        Added: Integer;
    begin
        EnsureSetup(Setup);
        DimCode := UpperCase(Setup."Dimension Filter");
        if DimCode = '' then
            Error('Set the Dimension Filter before loading filter values.');

        DimVal.Reset();
        DimVal.SetRange("Dimension Code", DimCode);
        if DimVal.FindSet() then
            repeat
                DimValueCode := UpperCase(DimVal.Code);
                if FilterVal.Get(DimCode, DimValueCode) then begin
                    if not FilterVal.Active then begin
                        FilterVal.Active := true;
                        FilterVal.Modify(true);
                    end;
                end else begin
                    FilterVal.Init();
                    FilterVal."Dimension Code" := DimCode;
                    FilterVal."Dimension Value Code" := DimValueCode;
                    FilterVal.Active := true;
                    FilterVal.Insert(true);
                    Added += 1;
                end;
            until DimVal.Next() = 0
        else
            Message('No dimension values exist for %1.', DimCode);

        exit(Added);
    end;

    local procedure EnsureSetup(var Setup: Record "WLM FcstSetup")
    begin
        if not Setup.Get('SETUP') then begin
            Setup.Init();
            Setup.Insert(true);
        end;
    end;



    local procedure BuildWBLocsFromRegionMap(CountryCode: Code[10]; var Locs: List of [Code[10]]; var Weights: List of [Decimal])
    var
        Map: Record "WLM Region Location Map";
        LocRec: Record Location;
        LocOn: Record "WLM Fcst Location";
    begin
        Clear(Locs);
        Clear(Weights);

        Map.Reset();
        Map.SetRange(Active, true);
        if Map.FindSet() then
            repeat
                if (Map."Location Code" <> '') and LocRec.Get(Map."Location Code") then
                    if LocRec."Country/Region Code" = CountryCode then begin
                        // honor active forecast locations only
                        LocOn.Reset();
                        LocOn.SetRange("Location Code", Map."Location Code");
                        LocOn.SetRange(Active, true);
                        if LocOn.FindFirst() then begin
                            Locs.Add(Map."Location Code");
                            Weights.Add(1); // even split across mapped locations
                        end;
                    end;
            until Map.Next() = 0;
    end;

}

// ---- Forecast Builder (corrected filters & date helpers)
codeunit 89620 "WLM FcstBuilder"
{
    SingleInstance = false;

    procedure BuildForItemUsingDefaults(ItemNo: Code[20])
    var
        Setup: Record "WLM FcstSetup";
        FromDate: Date;
        ToDate: Date;
    begin
        EnsureSetup(Setup);
        if (UpperCase(Setup."Dimension Filter") <> '') and (not ItemMatchesSetupFilter(ItemNo)) then begin
            LogWorkbackBypass(ItemNo, 'Skipped: item default dimension not in active Filter Values.');
            exit;
        end;

        CalcDefaultDateRange_PerBucket(Setup."Default Bucket", Setup."Lookback Months", FromDate, ToDate);

        BuildForItem(
            ItemNo, FromDate, ToDate,
            Setup."Default Forecast Name",
            Setup."Default Bucket",
            Setup."Replace Mode",
            Setup."Include Returns",
            Setup."Projection Months"
        );
    end;

    procedure BuildForAllActiveUsingDefaults()
    var
        Plan: Record "WLM Adv Item Planning v2";
        Setup: Record "WLM FcstSetup";
        LastItem: Code[20];
    begin
        EnsureSetup(Setup);
        LastItem := '';
        Plan.Reset();
        Plan.SetCurrentKey("Item No.", Active, "Effective From");
        Plan.SetRange(Active, true);
        if Plan.FindSet() then
            repeat
                if Plan."Item No." <> LastItem then begin
                    if (UpperCase(Setup."Dimension Filter") = '') or ItemMatchesSetupFilter(Plan."Item No.") then
                        BuildForItemUsingDefaults(Plan."Item No.");
                    LastItem := Plan."Item No.";
                end;
            until Plan.Next() = 0;
    end;

    procedure PreviewForItem(ItemNo: Code[20])
    var
        Setup: Record "WLM FcstSetup";
        FromDate: Date;
        ToDate: Date;
    begin
        EnsureSetup(Setup);
        if (UpperCase(Setup."Dimension Filter") <> '') and (not ItemMatchesSetupFilter(ItemNo)) then begin
            Message('Item %1 is not in the current Planning Filter cohort (%2).', ItemNo, Setup."Dimension Filter");
            exit;
        end;
        CalcDefaultDateRange_PerBucket(Setup."Default Bucket", Setup."Lookback Months", FromDate, ToDate);
        Message(
            'Preview: %1 (%2) %3..%4 -> "%5", +%6 month(s).',
            ItemNo,
            Format(Setup."Default Bucket"),
            FromDate, ToDate,
            Setup."Default Forecast Name",
            Setup."Projection Months"
        );
    end;

    procedure ClearForecastForItem(ItemNo: Code[20])
    var
        Setup: Record "WLM FcstSetup";
#if WLM_POST
#if WLM_PREMIUM
        DFE: Record 99000852;
#else
        WLEntry: Record "WLM Forecast Entry";
#endif
#endif
    begin
        EnsureSetup(Setup);
#if WLM_POST
#if WLM_PREMIUM
        DFE.Reset();
        DFE.SetRange("Production Forecast Name", Setup."Default Forecast Name");
        DFE.SetRange("Item No.", ItemNo);
        if DFE.FindSet() then
            DFE.DeleteAll(true);
#else
        WLEntry.Reset();
        WLEntry.SetRange("Forecast Name", Setup."Default Forecast Name");
        WLEntry.SetRange("Item No.", ItemNo);
        if WLEntry.FindSet() then
            WLEntry.DeleteAll(true);
#endif
#endif
        Message('Cleared forecast "%1" for %2.', Setup."Default Forecast Name", ItemNo);
    end;

    procedure BuildForItem(
        ItemNo: Code[20];
        FromDate: Date;
        ToDate: Date;
        ForecastName: Code[20];
        Bucket: Option Day,Week,Month;
        ReplaceMode: Boolean;
        IncludeReturns: Boolean;
        ProjectionMonths: Integer)
    var
        Setup: Record "WLM FcstSetup";
        Map: Record "WLM Adv Item Planning v2";
        ILE: Record "Item Ledger Entry";
        Buffer: Record "WLM FcstBuffer" temporary;
        ItemRec: Record Item;

        PosBaseByKey: Dictionary of [Text, Decimal];
        ExistingPos: Decimal;
        TargetLoc: Code[10];
        BucketDate: Date;
        ProjDate: Date;
        DemandDate: Date;
        Qty: Decimal;
        AdjBase: Decimal;
        DonorFilter: Text;
        ContribPct: Decimal;
        MultPct: Decimal;
        RegionCode: Code[30];
        EffMultPct: Decimal;
        WBHandled: Boolean;
        keyText: Text;
        FinalQty: Decimal;
        PosFinal: Decimal;
        posBase: Decimal;
        DonorSet: Dictionary of [Code[20], Boolean];
        SubDonors: Dictionary of [Code[20], Boolean];
        DonorKeys: List of [Code[20]];
        DonorCode: Code[20];
        SubRec: Record "Item Substitution";
        i: Integer;

#if WLM_POST
#if WLM_PREMIUM
        DFE: Record 99000852;
#else
        WLEntry: Record "WLM Forecast Entry";
#endif
#endif
    begin
        EnsureSetup(Setup);

        // Respect cohort based on the Item's Default Dimension (not transaction dims)
        if (UpperCase(Setup."Dimension Filter") <> '') and (not ItemMatchesSetupFilter(ItemNo)) then
            exit;

        if not ItemRec.Get(ItemNo) then
            Error('Item %1 not found.', ItemNo);

        // Respect Setup exclusion toggles (parity with Seed/Cleanup)
        if Setup."Exclude Blocked" and ItemRec.Blocked then begin
            LogWorkbackBypass(ItemNo, 'Skipped: item is Blocked and Exclude Blocked = true.');
            exit;
        end;
        if Setup."Exclude Purchasing Blocked" and ItemRec."Purchasing Blocked" then begin
            LogWorkbackBypass(ItemNo, 'Skipped: item is Purchasing Blocked and Exclude Purchasing Blocked = true.');
            exit;
        end;
        if Setup."Exclude Sales Blocked" and ItemRec."Sales Blocked" then begin
            LogWorkbackBypass(ItemNo, 'Skipped: item is Sales Blocked and Exclude Sales Blocked = true.');
            exit;
        end;
        if Setup."Exclude Non-Inventory Items" and (ItemRec.Type <> ItemRec.Type::Inventory) then begin
            LogWorkbackBypass(ItemNo, 'Skipped: item is not Inventory and Exclude Non-Inventory Items = true.');
            exit;
        end;

        // Workback path (if configured for the item)
        if ExistsWBForItem(ItemNo) then begin
            WBHandled := DoWorkback(ItemNo, ForecastName, Bucket, ReplaceMode, Setup."Projection Months");
            if WBHandled then
                exit
            else
                LogWorkbackBypass(ItemNo, 'Workback configured but produced no lines (see workback log for skip reasons).');
        end else
            LogWorkbackBypass(ItemNo, 'No active workback plan rows: requires Use Workback Projection = true and Workback Annual Projection > 0.');

        // Donor filter: self + active donors within effective window + optional substitutes
        Clear(DonorSet);
        Clear(SubDonors);
        if not DonorSet.ContainsKey(ItemNo) then
            DonorSet.Add(ItemNo, true);

        Map.Reset();
        Map.SetRange("Item No.", ItemNo);
        Map.SetRange(Active, true);
        if Map.FindSet() then
            repeat
                if IsEffective(Map."Effective From", Map."Effective To", FromDate, ToDate) then
                    if (Map."Related Item No." <> '') and (Map."Related Item No." <> ItemNo) then
                        if not DonorSet.ContainsKey(Map."Related Item No.") then
                            DonorSet.Add(Map."Related Item No.", true);
            until Map.Next() = 0;

        if Setup."Factor Subs in Sales Hist" then begin
            SubRec.Reset();
            SubRec.SetRange("Substitute No.", ItemNo);
            if SubRec.FindSet() then
                repeat
                    if not SubDonors.ContainsKey(SubRec."No.") then
                        SubDonors.Add(SubRec."No.", true);
                    if not DonorSet.ContainsKey(SubRec."No.") then
                        DonorSet.Add(SubRec."No.", true);
                until SubRec.Next() = 0;
        end;

        DonorFilter := '';
        DonorKeys := DonorSet.Keys();
        for i := 1 to DonorKeys.Count() do begin
            DonorCode := DonorKeys.Get(i);
            if DonorFilter <> '' then
                DonorFilter += '|';
            DonorFilter += DonorCode;
        end;

        // Pull historical ILE sales (optionally include returns)
        ILE.Reset();
        ILE.SetCurrentKey("Item No.", "Posting Date", "Location Code");
        ILE.SetFilter("Item No.", DonorFilter);
        ILE.SetRange("Posting Date", CalcDate('-24M', ToDate), ToDate);
        ILE.SetRange("Entry Type", ILE."Entry Type"::Sale);
        if not IncludeReturns then
            ILE.SetFilter(Quantity, '<%1', 0);

        Clear(PosBaseByKey);
        if ILE.FindSet() then
            repeat
                // Region routing driven by Item cohort toggle (not by posted line dims)
                if ShouldUseRegionMapForItem(ItemNo) then begin
                    RegionCode := GetShipToRegionFromPostedDoc(ILE);
                    TargetLoc := MapRegionToLocation(RegionCode);
                    if TargetLoc = '' then
                        continue; // region-mapped cohort: ignore demand when no mapping exists
                end else
                    TargetLoc := ILE."Location Code";

                if not IsLocationActiveOrListEmpty(TargetLoc) then
                    continue;

                // Choose demand date based on Setup
                DemandDate := GetDemandSignalDate(ILE);
                if (DemandDate < FromDate) or (DemandDate > ToDate) then
                    continue;

                // Bucket + forward projection
                BucketDate := GetBucketStartDate(DemandDate, Bucket);
                ProjDate := ProjectDate_PerBucket(BucketDate, Bucket, ProjectionMonths);

                // Normalize quantity semantics for demand planning
                Qty := ToBaseQty(ILE."Item No.", ILE.Quantity);
                if Qty < 0 then
                    Qty := -Qty // shipments -> positive demand
                else begin
                    if not IncludeReturns then
                        continue; // filtered already; explicit guard
                    Qty := -Qty; // returns reduce demand when included
                end;

                // Donor contribution%
                GetDonorParams(ItemNo, ILE."Item No.", ILE."Variant Code", DemandDate, ContribPct, MultPct);

                // If this donor is a source item for which the target is configured as a substitute,
                // treat it as full contribution regardless of related-item maps.
                if SubDonors.ContainsKey(ILE."Item No.") then begin
                    ContribPct := 100;
                    MultPct := 100;
                end;
                AdjBase := Qty * (ContribPct / 100);

                // Aggregate into temp buffer
                if Buffer.Get(ItemNo, TargetLoc, ProjDate) then begin
                    Buffer."Base Qty" := Buffer."Base Qty" + AdjBase;
                    Buffer.Modify();
                end else begin
                    Buffer.Init();
                    Buffer."Item No." := ItemNo;
                    Buffer."Location Code" := TargetLoc;
                    Buffer."Bucket Date" := ProjDate;
                    Buffer."Base Qty" := AdjBase;
                    Buffer.Insert();
                end;

                // Track positive-only base contribution for "no absolute negatives"
                if AdjBase > 0 then begin
                    keyText := MakeKey(ItemNo, TargetLoc, ProjDate);
                    if PosBaseByKey.ContainsKey(keyText) then begin
                        ExistingPos := 0;
                        PosBaseByKey.Get(keyText, ExistingPos);
                        ExistingPos := ExistingPos + AdjBase;
                        PosBaseByKey.Set(keyText, ExistingPos);
                    end else
                        PosBaseByKey.Add(keyText, AdjBase);
                end;
            until ILE.Next() = 0;

        ApplyFactorSeasonality(
            ItemNo,
            Buffer,
            Bucket,
            FromDate,
            ToDate,
            ProjectionMonths,
            PosBaseByKey,
            Setup);

        // Write results (apply multiplier + enforce "no absolute negatives")
        if Buffer.FindSet() then
            repeat
                EffMultPct := ResolveCountryMultiplier(ItemNo, Buffer."Location Code");

                // Final = base * multiplier
                FinalQty := ROUND(Buffer."Base Qty" * (EffMultPct / 100), 1, '>');

                // Positive portion after multiplier
                keyText := MakeKey(ItemNo, Buffer."Location Code", Buffer."Bucket Date");
                posBase := 0;
                if PosBaseByKey.ContainsKey(keyText) then
                    PosBaseByKey.Get(keyText, posBase);
                PosFinal := ROUND(posBase * (EffMultPct / 100), 1, '>');

                // Enforce "no absolute negatives"
                if (PosFinal <= 0) and (FinalQty < 0) then
                    continue // suppress line entirely
                else if (PosFinal > 0) and (FinalQty < 0) then
                    FinalQty := 0;

#if WLM_POST
#if WLM_PREMIUM
                if ReplaceMode then
                    DeleteExistingForecastLine(ForecastName, ItemNo, Buffer."Location Code", Buffer."Bucket Date");

                if FinalQty <> 0 then begin
                    DFE.Init();
                    DFE."Entry No." := 0;
                    DFE.Validate("Production Forecast Name", ForecastName);
                    DFE.Validate("Item No.", ItemNo);
                    DFE.Validate("Location Code", Buffer."Location Code");
                    DFE.Validate("Forecast Date", Buffer."Bucket Date");
                    DFE.Validate("Forecast Quantity", FinalQty);
                    DFE.Insert(true);
                end;
#else
                if ReplaceMode then
                    DeleteExistingForecastLine(ForecastName, ItemNo, Buffer."Location Code", Buffer."Bucket Date");

                if FinalQty <> 0 then begin
                    WLEntry.Init();
                    WLEntry.Validate("Forecast Name", ForecastName);
                    WLEntry.Validate("Item No.", ItemNo);
                    WLEntry.Validate("Location Code", Buffer."Location Code");
                    WLEntry.Validate("Forecast Date", Buffer."Bucket Date");
                    WLEntry.Validate(Quantity, FinalQty);
                    // Store historical comparison data
                    WLEntry."Historical Sales Qty" := Buffer."Base Qty";
                    WLEntry."Multiplier Used %" := EffMultPct;
                    WLEntry."Historical Period Start" := CalcDate('-24M', ToDate);
                    WLEntry."Historical Period End" := ToDate;
                    WLEntry.Insert(true);
                end;
#endif
#endif
            until Buffer.Next() = 0;
    end;

    // ===================== Workback =====================
    local procedure ExistsWBForItem(ItemNo: Code[20]): Boolean
    var
        P: Record "WLM Adv Item Planning v2";
    begin
        P.Reset();
        P.SetRange("Item No.", ItemNo);
        P.SetFilter("Related Item No.", '%1|%2', '', ItemNo);
        P.SetRange(Active, true);
        if P.FindSet() then
            repeat
                if P."Use Workback Projection" and (P."Workback Annual Projection" > 0) then
                    exit(true);
            until P.Next() = 0;
        exit(false);
    end;

    local procedure BuildWBLocSplitFromRegionMap(CountryCode: Code[10]; var Locs: List of [Code[10]]; var Weights: List of [Decimal])
    var
        Map: Record "WLM Region Location Map";
        LocRec: Record Location;
        LocOn: Record "WLM Fcst Location";
        LocWeight: Dictionary of [Code[10], Integer];
        LocKeys: List of [Code[10]];
        KeyLoc: Code[10];
        Count: Integer;
        i: Integer;
    begin
        Clear(Locs);
        Clear(Weights);
        Clear(LocWeight);

        // Collect unique target locations (active + country match) and count how many map rows point to each.
        Map.Reset();
        Map.SetRange(Active, true);
        if Map.FindSet() then
            repeat
                if (Map."Location Code" <> '') and LocRec.Get(Map."Location Code") then
                    if LocRec."Country/Region Code" = CountryCode then begin
                        LocOn.Reset();
                        LocOn.SetRange("Location Code", Map."Location Code");
                        LocOn.SetRange(Active, true);
                        if LocOn.FindFirst() then begin
                            if LocWeight.Get(Map."Location Code", Count) then
                                Count := Count + 1
                            else
                                Count := 1;
                            LocWeight.Set(Map."Location Code", Count);
                        end;
                    end;
            until Map.Next() = 0;

        // Emit unique location list with weights equal to count of mapped regions.
        LocKeys := LocWeight.Keys();
        for i := 1 to LocKeys.Count() do begin
            KeyLoc := LocKeys.Get(i);
            Locs.Add(KeyLoc);
            LocWeight.Get(KeyLoc, Count);
            Weights.Add(Count);
        end;
    end;

    local procedure BuildWBLocSplitFromActiveForecastLocations(CountryCode: Code[10]; var Locs: List of [Code[10]]; var Weights: List of [Decimal])
    var
        LocOn: Record "WLM Fcst Location";
        LocRec: Record Location;
    begin
        Clear(Locs);
        Clear(Weights);

        LocOn.Reset();
        LocOn.SetRange(Active, true);
        if LocOn.FindSet() then
            repeat
                if LocRec.Get(LocOn."Location Code") and (LocRec."Country/Region Code" = CountryCode) then begin
                    Locs.Add(LocRec.Code);
                    Weights.Add(1);
                end;
            until LocOn.Next() = 0;
    end;

    local procedure DoWorkback(
        ItemNo: Code[20];
        ForecastName: Code[20];
        Bucket: Option Day,Week,Month;
        ReplaceMode: Boolean;
        ProjectionMonths: Integer): Boolean
    var
        Setup: Record "WLM FcstSetup";
        Plan: Record "WLM Adv Item Planning v2";
        WBDVal: Record "WLM Seasonality Filter Value";
        WB: Record "WLM Seasonality Attribution";
        LocOn: Record "WLM Fcst Location";
        ItemDim: Record "Default Dimension";
        LocationRec: Record Location;
        WBDimCode: Code[20];
        WBDimValue: Code[20];
        BucketDates: List of [Date];
        StartDate: Date;
        EndDate: Date;
        CountryCode: Code[10];
        Locs: List of [Code[10]];
        Weights: List of [Decimal];
        Alloc: List of [Integer];
        MonthNo: Integer;
        MonthPct: Decimal;
        Annual: Integer;
        Qty: Integer;
        k: Integer;
        j: Integer;
        AnyInserted: Boolean;
        CustomDimensions: Dictionary of [Text, Text];
    begin
        EnsureSetup(Setup);
        WBDimCode := UpperCase(Setup."WB Dimension Filter");
        if WBDimCode = '' then
            Error('Workback projection requires WB Dimension Filter to be set in Forecast Setup.');

        ItemDim.Reset();
        ItemDim.SetRange("Table ID", Database::Item);
        ItemDim.SetRange("No.", ItemNo);
        ItemDim.SetRange("Dimension Code", WBDimCode);
        if ItemDim.FindFirst() then
            WBDimValue := UpperCase(ItemDim."Dimension Value Code")
        else
            Error('Item %1 is marked for Workback but is missing default dimension %2.', ItemNo, WBDimCode);

        WBDVal.Reset();
        WBDVal.SetRange("Dimension Code", WBDimCode);
        WBDVal.SetRange("Dimension Value Code", WBDimValue);
        WBDVal.SetRange(Active, true);
        if not WBDVal.FindFirst() then
            Error('No active Workback Seasonality Filter Value for %1 = %2.', WBDimCode, WBDimValue);

        CalcForwardHorizon(Bucket, ProjectionMonths, StartDate, EndDate, BucketDates);
        if BucketDates.Count() = 0 then
            Error('Workback horizon produced no bucket dates. Check Projection Months and bucket setting.');

        Plan.Reset();
        Plan.SetRange("Item No.", ItemNo);
        Plan.SetFilter("Related Item No.", '%1|%2', '', ItemNo);
        Plan.SetRange(Active, true);
        if not Plan.FindSet() then
            exit(false);

        repeat
            if not Plan."Use Workback Projection" then begin
                LogWorkbackSkip(ItemNo, CountryCode, 0, 'Plan row not flagged for workback.');
                continue;
            end;

            Annual := Round(Plan."Workback Annual Projection", 1, '>');
            if Annual <= 0 then begin
                LogWorkbackSkip(ItemNo, CountryCode, 0, 'Workback Annual Projection <= 0.');
                continue;
            end;

            CountryCode := Plan."Location Country/Region Code";
            if CountryCode = '' then begin
                LogWorkbackSkip(ItemNo, CountryCode, 0, 'No country on plan row.');
                continue;
            end;

            for k := 1 to BucketDates.Count() do begin
                MonthNo := Date2DMY(BucketDates.Get(k), 2);

                MonthPct := 0;
                WB.Reset();
                WB.SetRange("Dimension Code", WBDimCode);
                WB.SetRange("Dimension Value Code", WBDimValue);
                WB.SetRange("Month No", MonthNo);
                if WB.FindFirst() then
                    MonthPct := WB."Month %"
                else begin
                    WB.Reset();
                    WB.SetRange("Dimension Code", WBDimCode);
                    WB.SetRange("Dimension Value Code", WBDimValue);
                    WB.SetRange("Month No", 0);
                    if WB.FindFirst() then
                        MonthPct := WB."Month %";
                end;

                if MonthPct = 0 then begin
                    LogWorkbackSkip(ItemNo, CountryCode, MonthNo, 'Month % is 0; skipping bucket.');
                    continue;
                end;

                Clear(Locs);
                Clear(Weights);

                // Preferred split: use Region → Location mapping when the cohort is flagged for region mapping
                // (item default dimension matches an active Dimension Filter value with Use Region Location Mapping = true).
                if ShouldUseRegionMapForItem(ItemNo) then
                    BuildWBLocSplitFromRegionMap(CountryCode, Locs, Weights)
                else
                    BuildWBLocSplitFromActiveForecastLocations(CountryCode, Locs, Weights);

                if Locs.Count() = 0 then begin
                    LogWorkbackSkip(ItemNo, CountryCode, MonthNo, 'No locations available for split (region map/active locations).');
                    continue;
                end;

                Qty := Round(Annual * (MonthPct / 100), 1, '>');
                if Qty <= 0 then
                    continue;

                Alloc := AllocateByLargestRemainder(Qty, Weights);
                for j := 1 to Locs.Count() do
                    if Alloc.Get(j) > 0 then begin
                        UpsertForecast(ForecastName, ItemNo, Locs.Get(j), BucketDates.Get(k), Alloc.Get(j), ReplaceMode);
                        AnyInserted := true;
                    end;
            end;
        until Plan.Next() = 0;

        if not AnyInserted then begin
            Clear(CustomDimensions);
            CustomDimensions.Add('ItemNo', ItemNo);
            CustomDimensions.Add('CountryCode', CountryCode);

            Session.LogMessage(
                'WLM-WB-NOLINES',
                StrSubstNo(
                    'Workback is enabled for %1 but no forecast lines were produced. Verify active WLM Forecast Locations for country %2 and Seasonality Attribution (Month %% / Location %%).',
                    ItemNo, CountryCode),
                Verbosity::Warning,
                DataClassification::SystemMetadata,
                TelemetryScope::ExtensionPublisher,
                CustomDimensions);
            exit(false);
        end;

        exit(true);
    end;

    local procedure UpsertForecast(ForecastName: Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; D: Date; Units: Integer; ReplaceExisting: Boolean)
    var
#if WLM_POST
#if WLM_PREMIUM
        DFName: Record 99000851;
        DFE: Record 99000852;
#else
        WLEntry: Record "WLM Forecast Entry";
#endif
#endif
    begin
#if WLM_POST
#if WLM_PREMIUM
        if Units = 0 then exit;

        if not DFName.Get(ForecastName) then begin
            DFName.Init();
            DFName.Validate(Name, ForecastName);
            DFName.Insert(true);
        end;

        if ReplaceExisting then begin
            DFE.Reset();
            DFE.SetRange("Production Forecast Name", ForecastName);
            DFE.SetRange("Item No.", ItemNo);
            DFE.SetRange("Location Code", LocationCode);
            DFE.SetRange("Forecast Date", D);
            if DFE.FindSet() then
                DFE.DeleteAll(true);
        end;

        DFE.Init();
        DFE."Entry No." := 0;
        DFE.Validate("Production Forecast Name", ForecastName);
        DFE.Validate("Item No.", ItemNo);
        DFE.Validate("Location Code", LocationCode);
        DFE.Validate("Forecast Date", D);
        DFE.Validate("Forecast Quantity", Units);
        DFE.Insert(true);
#else
        if Units = 0 then exit;

        if ReplaceExisting then begin
            WLEntry.Reset();
            WLEntry.SetRange("Forecast Name", ForecastName);
            WLEntry.SetRange("Item No.", ItemNo);
            WLEntry.SetRange("Location Code", LocationCode);
            WLEntry.SetRange("Forecast Date", D);
            if WLEntry.FindSet() then
                WLEntry.DeleteAll(true);
        end;

        WLEntry.Init();
        WLEntry.Validate("Forecast Name", ForecastName);
        WLEntry.Validate("Item No.", ItemNo);
        WLEntry.Validate("Location Code", LocationCode);
        WLEntry.Validate("Forecast Date", D);
        WLEntry.Validate(Quantity, Units);
        WLEntry.Insert(true);
#endif
#endif
    end;

    // ===================== Cohort & routing helpers =====================
    local procedure ShouldUseRegionMapForItem(ItemNo: Code[20]): Boolean
    var
        Setup: Record "WLM FcstSetup";
        DimCodeU: Code[20];
        DimValCodeU: Code[20];
        Val: Record "WLM Dim Filter Value";
        Plan: Record "WLM Adv Item Planning v2";
    begin
        // Plan-level override: if any active plan row for this item is flagged to use region mapping, honor it
        Plan.Reset();
        Plan.SetRange("Item No.", ItemNo);
        Plan.SetRange(Active, true);
        Plan.SetRange("Use Region Location Mapping", true);
        if Plan.FindFirst() then
            exit(true);

        // Cohort-level check based on Dimension Filter + Filter Value toggle
        EnsureSetup(Setup);
        DimCodeU := UpperCase(Setup."Dimension Filter");
        if DimCodeU = '' then
            exit(false);

        DimValCodeU := GetItemDimValue(ItemNo, DimCodeU);
        if DimValCodeU = '' then
            exit(false);

        Val.Reset();
        Val.SetRange("Dimension Code", DimCodeU);
        Val.SetRange("Dimension Value Code", DimValCodeU);
        Val.SetRange(Active, true);
        if Val.FindFirst() then
            exit(Val."Use Region Location Mapping");
        exit(false);
    end;

    local procedure ItemMatchesSetupFilter(ItemNo: Code[20]): Boolean
    var
        Setup: Record "WLM FcstSetup";
        DimCodeU: Code[20];
        DimValCodeU: Code[20];
        Val: Record "WLM Dim Filter Value";
    begin
        EnsureSetup(Setup);
        DimCodeU := UpperCase(Setup."Dimension Filter");
        if DimCodeU = '' then
            exit(true); // no filter → plan everything

        DimValCodeU := GetItemDimValue(ItemNo, DimCodeU);
        if DimValCodeU = '' then
            exit(false);

        Val.Reset();
        Val.SetRange("Dimension Code", DimCodeU);
        Val.SetRange("Dimension Value Code", DimValCodeU);
        Val.SetRange(Active, true);
        exit(Val.FindFirst());
    end;

    local procedure GetItemDimValue(ItemNo: Code[20]; DimCodeU: Code[20]): Code[20]
    var
        DefDim: Record "Default Dimension";
    begin
        DefDim.Reset();
        DefDim.SetRange("Table ID", Database::Item);
        DefDim.SetRange("No.", ItemNo);
        DefDim.SetRange("Dimension Code", DimCodeU);
        if DefDim.FindFirst() then
            exit(UpperCase(DefDim."Dimension Value Code"));
        exit('');
    end;

    local procedure MakeKey(ItemNo: Code[20]; Loc: Code[10]; D: Date): Text
    begin
        exit(StrSubstNo('%1|%2|%3', ItemNo, Loc, Format(D)));
    end;

    local procedure LogWorkbackSkip(ItemNo: Code[20]; Country: Code[10]; MonthNo: Integer; Reason: Text)
    var
        CustomDimensions: Dictionary of [Text, Text];
        WBLog: Record "WLM Workback Log";
    begin
        Clear(CustomDimensions);
        CustomDimensions.Add('ItemNo', ItemNo);
        CustomDimensions.Add('Country', Country);
        CustomDimensions.Add('MonthNo', Format(MonthNo));

        Session.LogMessage(
            'WLM-WB-SKIP',
            StrSubstNo('Workback skipped for %1 (Country %2, Month %3): %4', ItemNo, Country, MonthNo, Reason),
            Verbosity::Normal,
            DataClassification::SystemMetadata,
            TelemetryScope::ExtensionPublisher,
            CustomDimensions);

        // Persist to in-client log table
        WBLog.Init();
        WBLog."Item No." := ItemNo;
        WBLog."Country/Region Code" := Country;
        WBLog."Month No" := MonthNo;
        WBLog.Reason := CopyStr(Reason, 1, MaxStrLen(WBLog.Reason));
        WBLog.Insert(true);
    end;

    local procedure LogWorkbackBypass(ItemNo: Code[20]; Reason: Text)
    var
        WBLog: Record "WLM Workback Log";
    begin
        WBLog.Init();
        WBLog."Item No." := ItemNo;
        WBLog."Country/Region Code" := '';
        WBLog."Month No" := 0;
        WBLog.Reason := CopyStr(Reason, 1, MaxStrLen(WBLog.Reason));
        WBLog.Insert(true);
    end;

    // ===================== Misc helpers =====================
    local procedure AllocateByLargestRemainder(Total: Integer; Weights: List of [Decimal]): List of [Integer]
    var
        Result: List of [Integer];
        Fracs: List of [Decimal];
        i: Integer;
        BaseSum: Integer;
        Rem: Integer;
        SumW: Decimal;
        Ideal: Decimal;
        BasePart: Decimal;
        Frac: Decimal;
        idx: Integer;
        bestIdx: Integer;
        bestFrac: Decimal;
    begin
        Clear(Result);
        Clear(Fracs);

        if (Total <= 0) or (Weights.Count() = 0) then begin
            for i := 1 to Weights.Count() do
                Result.Add(0);
            exit(Result);
        end;

        SumW := 0;
        for i := 1 to Weights.Count() do
            SumW += Weights.Get(i);

        if SumW = 0 then begin
            for i := 1 to Weights.Count() do
                Result.Add(0);
            exit(Result);
        end;

        BaseSum := 0;
        for i := 1 to Weights.Count() do begin
            Ideal := (Weights.Get(i) / SumW) * Total;
            BasePart := ROUND(Ideal, 1, '<');
            Result.Add(BasePart);
            Frac := Ideal - BasePart;
            Fracs.Add(Frac);
            BaseSum += BasePart;
        end;

        Rem := Total - BaseSum;
        while Rem > 0 do begin
            bestIdx := 1;
            bestFrac := Fracs.Get(1);
            for idx := 2 to Fracs.Count() do
                if Fracs.Get(idx) > bestFrac then begin
                    bestFrac := Fracs.Get(idx);
                    bestIdx := idx;
                end;
            Result.Set(bestIdx, Result.Get(bestIdx) + 1);
            Fracs.Set(bestIdx, -1); // used
            Rem -= 1;
        end;

        exit(Result);
    end;

    local procedure EnsureSetup(var Setup: Record "WLM FcstSetup")
    begin
        if not Setup.Get('SETUP') then begin
            Setup.Init();
            Setup.Insert(true);
        end;
    end;

    local procedure GetDemandSignalDate(ILE: Record "Item Ledger Entry"): Date
    var
        Setup: Record "WLM FcstSetup";
        SH: Record "Sales Header";
        SL: Record "Sales Line";
        SIH: Record "Sales Invoice Header";
        SSH: Record "Sales Shipment Header";
        OrderDate: Date;
        ReqDate: Date;
        PromDate: Date;
        DocDate: Date;
        PostDate: Date;
        Candidate: Date;
        Earliest: Date;
        HasOrder: Boolean;
    begin
        EnsureSetup(Setup);
        PostDate := ILE."Posting Date";

        // Try to resolve originating order info if available
        HasOrder := (ILE."Order No." <> '');
        if HasOrder then begin
            if SH.Get(SH."Document Type"::Order, ILE."Order No.") then
                OrderDate := SH."Order Date";

            if ILE."Order Line No." <> 0 then begin
                SL.Reset();
                SL.SetRange("Document Type", SL."Document Type"::Order);
                SL.SetRange("Document No.", ILE."Order No.");
                SL.SetRange("Line No.", ILE."Order Line No.");
                if SL.FindFirst() then begin
                    ReqDate := SL."Requested Delivery Date";
                    PromDate := SL."Promised Delivery Date";
                end;
            end;
        end;

        // Prefer Sales Invoice Header; fall back to Sales Shipment Header
        if (SIH.Get(ILE."Document No.")) then
            DocDate := SIH."Document Date"
        else
            if (SSH.Get(ILE."Document No.")) then
                DocDate := SSH."Document Date";

        case Setup."Demand Date Source" of
            Setup."Demand Date Source"::PostingDate:
                exit(PostDate);

            Setup."Demand Date Source"::DocumentDate:
                begin
                    if DocDate <> 0D then exit(DocDate);
                    exit(PostDate);
                end;

            Setup."Demand Date Source"::OrderDate:
                begin
                    if OrderDate <> 0D then exit(OrderDate);
                    if DocDate <> 0D then exit(DocDate);
                    exit(PostDate);
                end;

            Setup."Demand Date Source"::RequestedDelivery:
                begin
                    if ReqDate <> 0D then exit(ReqDate);
                    if PromDate <> 0D then exit(PromDate);
                    if OrderDate <> 0D then exit(OrderDate);
                    if DocDate <> 0D then exit(DocDate);
                    exit(PostDate);
                end;

            Setup."Demand Date Source"::PromisedDelivery:
                begin
                    if PromDate <> 0D then exit(PromDate);
                    if ReqDate <> 0D then exit(ReqDate);
                    if OrderDate <> 0D then exit(OrderDate);
                    if DocDate <> 0D then exit(DocDate);
                    exit(PostDate);
                end;

            Setup."Demand Date Source"::EarliestOfAll:
                begin
                    Earliest := 0D;

                    Candidate := OrderDate;
                    if (Candidate <> 0D) and ((Earliest = 0D) or (Candidate < Earliest)) then Earliest := Candidate;
                    Candidate := ReqDate;
                    if (Candidate <> 0D) and ((Earliest = 0D) or (Candidate < Earliest)) then Earliest := Candidate;
                    Candidate := PromDate;
                    if (Candidate <> 0D) and ((Earliest = 0D) or (Candidate < Earliest)) then Earliest := Candidate;
                    Candidate := DocDate;
                    if (Candidate <> 0D) and ((Earliest = 0D) or (Candidate < Earliest)) then Earliest := Candidate;

                    if Earliest <> 0D then exit(Earliest);
                    exit(PostDate);
                end;
        end;

        exit(PostDate);
    end;

    local procedure GetShipToRegionFromPostedDoc(ILE: Record "Item Ledger Entry"): Code[30]
    var
        SIH: Record "Sales Invoice Header";
        SSH: Record "Sales Shipment Header";
    begin
        if SIH.Get(ILE."Document No.") then
            exit(UpperCase(DelChr(SIH."Ship-to County", '=', ' ')));
        if SSH.Get(ILE."Document No.") then
            exit(UpperCase(DelChr(SSH."Ship-to County", '=', ' ')));
        exit('');
    end;

    local procedure MapRegionToLocation(Region: Code[30]): Code[10]
    var
        M: Record "WLM Region Location Map";
    begin
        if Region = '' then
            exit('');
        if M.Get(Region) and M.Active then
            exit(M."Location Code");
        exit('');
    end;

    local procedure IsLocationActiveOrListEmpty(TargetLoc: Code[10]): Boolean
    var
        L: Record "WLM Fcst Location";
    begin
        if L.IsEmpty() then
            exit(true); // No configured list → treat all as active
        if TargetLoc = '' then
            exit(false);
        if L.Get(TargetLoc) then
            exit(L.Active);
        exit(false);
    end;

    local procedure GetDonorParams(TargetItemNo: Code[20]; DonorItemNo: Code[20]; DonorVariant: Code[10]; OnDate: Date; var ContribPct: Decimal; var MultPct: Decimal)
    var
        Map: Record "WLM Adv Item Planning v2";
    begin
        ContribPct := 0;
        MultPct := 100;

        if TargetItemNo = DonorItemNo then begin
            // Self rows: BLANK or A->A (compat)
            Map.Reset();
            Map.SetRange("Item No.", TargetItemNo);
            Map.SetFilter("Related Item No.", '%1|%2', '', DonorItemNo);
            Map.SetRange(Active, true);
            if Map.FindFirst() and IsEffective(Map."Effective From", Map."Effective To", OnDate, OnDate) then
                ContribPct := Map."Contribution %"
            else
                ContribPct := 100;
            exit;
        end;

        // Donor rows
        Map.Reset();
        Map.SetRange("Item No.", TargetItemNo);
        Map.SetRange("Related Item No.", DonorItemNo);
        Map.SetRange(Active, true);
        if Map.FindFirst() and IsEffective(Map."Effective From", Map."Effective To", OnDate, OnDate) then
            ContribPct := Map."Contribution %";
    end;

    local procedure ResolveCountryMultiplier(ItemNo: Code[20]; LocationCode: Code[10]): Decimal
    var
        Setup: Record "WLM FcstSetup";
        PRow: Record "WLM Adv Item Planning v2";
        Loc: Record Location;
        CCode: Code[10];
        Eff: Decimal;
    begin
        EnsureSetup(Setup);
        Eff := Setup."Default Self Multiplier %";

        if Loc.Get(LocationCode) then
            CCode := Loc."Country/Region Code";

        // Prefer a country-specific self row (BLANK or A->A)
        PRow.Reset();
        PRow.SetRange("Item No.", ItemNo);
        PRow.SetFilter("Related Item No.", '%1|%2', '', ItemNo);
        PRow.SetRange("Location Country/Region Code", CCode);
        PRow.SetRange(Active, true);
        if PRow.FindFirst() then
            exit(PRow."Multiplier %");

        // Else any active self row
        PRow.Reset();
        PRow.SetRange("Item No.", ItemNo);
        PRow.SetFilter("Related Item No.", '%1|%2', '', ItemNo);
        PRow.SetRange(Active, true);
        if PRow.FindFirst() and (PRow."Multiplier %" <> 0) then
            Eff := PRow."Multiplier %";

        exit(Eff);
    end;

    local procedure ApplyFactorSeasonality(
        ItemNo: Code[20];
        var Buffer: Record "WLM FcstBuffer" temporary;
        Bucket: Option Day,Week,Month;
        FromDate: Date;
        ToDate: Date;
        ProjectionMonths: Integer;
        var PosBaseByKey: Dictionary of [Text, Decimal];
        Setup: Record "WLM FcstSetup")
    var
        DimCode: Code[20];
        DimValue: Code[20];
        Plan: Record "WLM Adv Item Planning v2";
        CountrySeen: Dictionary of [Code[10], Boolean];
        CountryCode: Code[10];
        Locs: List of [Code[10]];
        CountryBase: Decimal;
        ProjDates: List of [Date];
    begin
        DimCode := UpperCase(Setup."WB Dimension Filter");
        if DimCode = '' then
            exit;

        DimValue := GetItemDimValue(ItemNo, DimCode);
        if DimValue = '' then
            exit;

        CollectProjectedDates(FromDate, ToDate, Bucket, ProjectionMonths, ProjDates);
        if ProjDates.Count() = 0 then
            exit;

        Clear(CountrySeen);

        Plan.Reset();
        Plan.SetRange("Item No.", ItemNo);
        Plan.SetFilter("Related Item No.", '%1|%2', '', ItemNo);
        Plan.SetRange(Active, true);
        Plan.SetRange("Factor Seasonality", true);
        if Plan.FindSet() then
            repeat
                CountryCode := Plan."Location Country/Region Code";
                if CountrySeen.ContainsKey(CountryCode) then
                    continue;
                CountrySeen.Add(CountryCode, true);

                BuildLocationListForCountry(CountryCode, Locs);
                if Locs.Count() = 0 then
                    continue;

                CountryBase := SumPositiveBaseForLocations(Buffer, Locs);
                if CountryBase <= 0 then
                    continue;

                ApplySeasonalityForCountry(
                    ItemNo,
                    DimCode,
                    DimValue,
                    CountryBase,
                    Locs,
                    ProjDates,
                    Buffer,
                    PosBaseByKey);
            until Plan.Next() = 0;
    end;

    local procedure ApplySeasonalityForCountry(
        ItemNo: Code[20];
        DimCode: Code[20];
        DimValue: Code[20];
        CountryBase: Decimal;
        Locs: List of [Code[10]];
        ProjDates: List of [Date];
        var Buffer: Record "WLM FcstBuffer" temporary;
        var PosBaseByKey: Dictionary of [Text, Decimal])
    var
        MonthPctCache: Dictionary of [Integer, Decimal];
        MonthUsed: List of [Integer];
        SumMonthPct: Decimal;
        idx: Integer;
        MonthNo: Integer;
        MonthPct: Decimal;
        MonthShare: Decimal;
        locIdx: Integer;
        LocCode: Code[10];
        LocPct: Decimal;
        TargetQty: Decimal;
        ProjDate: Date;
        PrimaryLocCode: Code[10];
    begin
        Clear(MonthPctCache);
        Clear(MonthUsed);
        SumMonthPct := 0;

        if Locs.Count() = 0 then
            exit;
        PrimaryLocCode := Locs.Get(1);

        for idx := 1 to ProjDates.Count() do begin
            MonthNo := Date2DMY(ProjDates.Get(idx), 2);
            if ListContainsInteger(MonthUsed, MonthNo) then
                continue;
            MonthUsed.Add(MonthNo);

            MonthPct := TryGetSeasonalityMonthPct(DimCode, DimValue, MonthNo, PrimaryLocCode);
            if MonthPct = 0 then
                MonthPct := TryGetSeasonalityMonthPct(DimCode, DimValue, 0, PrimaryLocCode);

            if MonthPct <= 0 then
                continue;

            MonthPctCache.Add(MonthNo, MonthPct);
            SumMonthPct += MonthPct;
        end;

        if SumMonthPct <= 0 then
            exit;

        for idx := 1 to ProjDates.Count() do begin
            ProjDate := ProjDates.Get(idx);
            MonthNo := Date2DMY(ProjDate, 2);
            if not MonthPctCache.ContainsKey(MonthNo) then
                continue;

            MonthPct := MonthPctCache.Get(MonthNo);
            MonthShare := MonthPct / SumMonthPct;

            for locIdx := 1 to Locs.Count() do begin
                LocCode := Locs.Get(locIdx);
                LocPct := TryGetSeasonalityLocPct(DimCode, DimValue, MonthNo, LocCode);
                if LocPct = 0 then
                    LocPct := TryGetSeasonalityLocPct(DimCode, DimValue, 0, LocCode);

                if LocPct <= 0 then
                    continue;

                TargetQty := ROUND(CountryBase * MonthShare * (LocPct / 100), 0.00001);
                SetBufferBaseQty(Buffer, ItemNo, LocCode, ProjDate, TargetQty, PosBaseByKey);
            end;
        end;
    end;

    local procedure CollectProjectedDates(
        FromDate: Date;
        ToDate: Date;
        Bucket: Option Day,Week,Month;
        ProjectionMonths: Integer;
        var Dates: List of [Date])
    var
        StartBucket: Date;
        EndBucket: Date;
        CurrBucket: Date;
        ProjDate: Date;
    begin
        Clear(Dates);

        StartBucket := GetBucketStartDate(FromDate, Bucket);
        EndBucket := GetBucketStartDate(ToDate, Bucket);

        if (StartBucket = 0D) or (EndBucket = 0D) then
            exit;
        if StartBucket > EndBucket then
            exit;

        CurrBucket := StartBucket;
        repeat
            ProjDate := ProjectDate_PerBucket(CurrBucket, Bucket, ProjectionMonths);
            if not ListContainsDate(Dates, ProjDate) then
                Dates.Add(ProjDate);
            CurrBucket := IncrementBucketStartDate(CurrBucket, Bucket);
        until CurrBucket > EndBucket;
    end;

    local procedure IncrementBucketStartDate(Current: Date; Bucket: Option Day,Week,Month): Date
    begin
        case Bucket of
            Bucket::Day:
                exit(Current + 1);
            Bucket::Week:
                exit(Current + 7);
            Bucket::Month:
                exit(CalcDate('+1M', Current));
        end;
    end;

    local procedure TryGetSeasonalityMonthPct(DimCode: Code[20]; DimValue: Code[20]; MonthNo: Integer; LocationCode: Code[10]): Decimal
    var
        WBA: Record "WLM Seasonality Attribution";
    begin
        WBA.Reset();
        WBA.SetRange("Dimension Code", DimCode);
        WBA.SetRange("Dimension Value Code", DimValue);
        WBA.SetRange("Month No", MonthNo);
        if LocationCode <> '' then
            WBA.SetRange("Location Code", LocationCode);
        if WBA.FindFirst() then
            exit(WBA."Month %");
        exit(0);
    end;

    local procedure TryGetSeasonalityLocPct(DimCode: Code[20]; DimValue: Code[20]; MonthNo: Integer; LocationCode: Code[10]): Decimal
    var
        WBA: Record "WLM Seasonality Attribution";
    begin
        WBA.Reset();
        WBA.SetRange("Dimension Code", DimCode);
        WBA.SetRange("Dimension Value Code", DimValue);
        WBA.SetRange("Location Code", LocationCode);
        WBA.SetRange("Month No", MonthNo);
        if WBA.FindFirst() then
            exit(WBA."Location %");
        exit(0);
    end;

    local procedure BuildLocationListForCountry(CountryCode: Code[10]; var Locs: List of [Code[10]])
    var
        LocOn: Record "WLM Fcst Location";
        LocationRec: Record Location;
    begin
        Clear(Locs);
        LocOn.Reset();
        LocOn.SetRange(Active, true);
        if LocOn.FindSet() then
            repeat
                if not LocationRec.Get(LocOn."Location Code") then
                    continue;

                if (CountryCode = '') or (LocationRec."Country/Region Code" = CountryCode) then
                    if not ListContainsLocation(Locs, LocOn."Location Code") then
                        Locs.Add(LocOn."Location Code");
            until LocOn.Next() = 0;
    end;

    local procedure ListContainsLocation(var Locs: List of [Code[10]]; CodeVal: Code[10]): Boolean
    var
        idx: Integer;
    begin
        for idx := 1 to Locs.Count() do
            if Locs.Get(idx) = CodeVal then
                exit(true);
        exit(false);
    end;

    local procedure ListContainsInteger(var Ints: List of [Integer]; Value: Integer): Boolean
    var
        idx: Integer;
    begin
        for idx := 1 to Ints.Count() do
            if Ints.Get(idx) = Value then
                exit(true);
        exit(false);
    end;

    local procedure ListContainsDate(var Dates: List of [Date]; Value: Date): Boolean
    var
        idx: Integer;
    begin
        for idx := 1 to Dates.Count() do
            if Dates.Get(idx) = Value then
                exit(true);
        exit(false);
    end;

    local procedure SumPositiveBaseForLocations(
        var Buffer: Record "WLM FcstBuffer" temporary;
        Locs: List of [Code[10]]): Decimal
    var
        SumBase: Decimal;
        idx: Integer;
        LocMap: Dictionary of [Code[10], Boolean];
    begin
        Clear(LocMap);
        for idx := 1 to Locs.Count() do
            if not LocMap.ContainsKey(Locs.Get(idx)) then
                LocMap.Add(Locs.Get(idx), true);

        Buffer.Reset();
        if Buffer.FindSet() then
            repeat
                if LocMap.ContainsKey(Buffer."Location Code") then
                    if Buffer."Base Qty" > 0 then
                        SumBase += Buffer."Base Qty";
            until Buffer.Next() = 0;

        exit(SumBase);
    end;

    local procedure SetBufferBaseQty(
        var Buffer: Record "WLM FcstBuffer" temporary;
        ItemNo: Code[20];
        LocationCode: Code[10];
        ProjDate: Date;
        TargetQty: Decimal;
        var PosBaseByKey: Dictionary of [Text, Decimal])
    var
        keyText: Text;
    begin
        if Buffer.Get(ItemNo, LocationCode, ProjDate) then begin
            Buffer."Base Qty" := TargetQty;
            Buffer.Modify();
        end else begin
            Buffer.Init();
            Buffer."Item No." := ItemNo;
            Buffer."Location Code" := LocationCode;
            Buffer."Bucket Date" := ProjDate;
            Buffer."Base Qty" := TargetQty;
            Buffer.Insert();
        end;

        keyText := MakeKey(ItemNo, LocationCode, ProjDate);
        if TargetQty > 0 then begin
            if PosBaseByKey.ContainsKey(keyText) then
                PosBaseByKey.Set(keyText, TargetQty)
            else
                PosBaseByKey.Add(keyText, TargetQty);
        end else begin
            if PosBaseByKey.ContainsKey(keyText) then
                PosBaseByKey.Remove(keyText);
        end;
    end;

    local procedure CalcDefaultDateRange_PerBucket(Bucket: Option Day,Week,Month; LookbackPeriod: Integer; var FromDate: Date; var ToDate: Date)
    var
        firstOfTo: Date;
        firstOfFrom: Date;
        days: Integer;
        monday: Date;
        sunday: Date;
        baseToday: Date;
    begin
        baseToday := Today;
        if baseToday = 0D then
            baseToday := WorkDate;

        ToDate := baseToday;

        case Bucket of
            Bucket::Day:
                begin
                    if LookbackPeriod < 0 then LookbackPeriod := 0;
                    FromDate := ToDate - LookbackPeriod;
                end;

            Bucket::Week:
                begin
                    if LookbackPeriod < 0 then LookbackPeriod := 0;
                    days := LookbackPeriod * 7;
                    FromDate := ToDate - days;
                    monday := FromDate - (Date2DWY(FromDate, 1) - 1);
                    FromDate := monday;
                    sunday := ToDate + (7 - Date2DWY(ToDate, 1));
                    ToDate := sunday;
                end;

            Bucket::Month:
                begin
                    firstOfTo := DMY2Date(1, Date2DMY(ToDate, 2), Date2DMY(ToDate, 3));
                    if firstOfTo = 0D then
                        firstOfTo := baseToday;

                    if LookbackPeriod < 0 then
                        LookbackPeriod := 0;

                    FromDate := CalcDate(StrSubstNo('-%1M', LookbackPeriod), firstOfTo);
                    firstOfFrom := DMY2Date(1, Date2DMY(FromDate, 2), Date2DMY(FromDate, 3));
                    if firstOfFrom <> 0D then
                        FromDate := firstOfFrom
                    else
                        FromDate := firstOfTo;

                    ToDate := CalcDate('<CM+1D-1D>', firstOfTo);
                    if ToDate = 0D then
                        ToDate := firstOfTo;
                end;
        end;
    end;


    local procedure GetBucketStartDate(D: Date; Bucket: Option Day,Week,Month): Date
    var
        WeekStart: Date;
    begin
        case Bucket of
            Bucket::Day:
                exit(D);
            Bucket::Week:
                begin
                    WeekStart := D - (Date2DWY(D, 1) - 1);
                    exit(WeekStart);
                end;
            Bucket::Month:
                exit(DMY2Date(1, Date2DMY(D, 2), Date2DMY(D, 3)));
        end;
    end;

    local procedure ProjectDate_PerBucket(SrcBucketDate: Date; Bucket: Option Day,Week,Month; ProjectionPeriod: Integer): Date
    var
        Base: Date;
        Future: Date;
        FutureWeekStart: Date;
        months: Integer;
    begin
        case Bucket of
            Bucket::Day:
                exit(SrcBucketDate + ProjectionPeriod);

            Bucket::Week:
                begin
                    Base := SrcBucketDate - (Date2DWY(SrcBucketDate, 1) - 1);
                    Future := Base + (ProjectionPeriod * 7);
                    FutureWeekStart := Future - (Date2DWY(Future, 1) - 1);
                    exit(FutureWeekStart);
                end;

            Bucket::Month:
                begin
                    Base := DMY2Date(1, Date2DMY(SrcBucketDate, 2), Date2DMY(SrcBucketDate, 3));
                    if Base = 0D then
                        Base := SrcBucketDate;

                    months := ProjectionPeriod;
                    if months < 0 then
                        months := 0;

                    Future := CalcDate(StrSubstNo('+%1M', months), Base);
                    if Future = 0D then
                        Future := Base;

                    exit(DMY2Date(1, Date2DMY(Future, 2), Date2DMY(Future, 3)));
                end;
        end;
    end;

    local procedure CalcForwardHorizon(Bucket: Option Day,Week,Month; ProjectionMonths: Integer; var StartDate: Date; var EndDate: Date; var Dates: List of [Date])
    var
        firstOfTo: Date;
        today: Date;
        d: Date;
        months: Integer;
    begin
        Clear(Dates);

        today := Today;
        if today = 0D then
            today := WorkDate;

        StartDate := today;

        months := ProjectionMonths;
        if months < 0 then months := 0;

        case Bucket of
            Bucket::Month:
                begin
                    firstOfTo := DMY2Date(1, Date2DMY(today, 2), Date2DMY(today, 3));
                    if firstOfTo = 0D then firstOfTo := today;

                    EndDate := CalcDate(StrSubstNo('+%1M', months), firstOfTo);
                    if EndDate = 0D then EndDate := firstOfTo;

                    BuildMonthStartDates(months, Dates);
                end;

            Bucket::Week:
                begin
                    EndDate := CalcDate(StrSubstNo('+%1M', months), today);
                    if EndDate = 0D then EndDate := today;

                    d := today - (Date2DWY(today, 1) - 1);
                    while d <= EndDate do begin
                        Dates.Add(d);
                        d := d + 7;
                    end;
                end;

            Bucket::Day:
                begin
                    EndDate := CalcDate(StrSubstNo('+%1M', months), today);
                    if EndDate = 0D then EndDate := today;

                    d := today;
                    while d <= EndDate do begin
                        Dates.Add(d);
                        d := d + 1;
                    end;
                end;
        end;
    end;

    local procedure BuildMonthStartDates(ProjectionMonths: Integer; var Dates: List of [Date])
    var
        today: Date;
        base: Date;
        i: Integer;
        months: Integer;
    begin
        Clear(Dates);
        months := ProjectionMonths;
        if months < 0 then months := 0;

        today := Today;
        if today = 0D then
            today := WorkDate;

        base := DMY2Date(1, Date2DMY(today, 2), Date2DMY(today, 3));
        if base = 0D then
            base := today;

        for i := 0 to months - 1 do
            Dates.Add(CalcDate(StrSubstNo('+%1M', i), base));
    end;

    local procedure IsEffective(FromD: Date; ToD: Date; WindowFrom: Date; WindowTo: Date): Boolean
    begin
        if (FromD <> 0D) and (FromD > WindowTo) then exit(false);
        if (ToD <> 0D) and (ToD < WindowFrom) then exit(false);
        exit(true);
    end;

#if WLM_POST
    local procedure DeleteExistingForecastLine(ForecastName: Code[20]; ItemNo: Code[20]; Loc: Code[10]; ProjDate: Date)
    var
#if WLM_PREMIUM
        DFE: Record 99000852;
#else
        W: Record "WLM Forecast Entry";
#endif
    begin
#if WLM_PREMIUM
        DFE.Reset();
        DFE.SetRange("Production Forecast Name", ForecastName);
        DFE.SetRange("Item No.", ItemNo);
        DFE.SetRange("Location Code", Loc);
        DFE.SetRange("Forecast Date", ProjDate);
        if DFE.FindSet() then
            DFE.DeleteAll(true);
#else
        W.Reset();
        W.SetRange("Forecast Name", ForecastName);
        W.SetRange("Item No.", ItemNo);
        W.SetRange("Location Code", Loc);
        W.SetRange("Forecast Date", ProjDate);
        if W.FindSet() then
            W.DeleteAll(true);
#endif
    end;
#endif

    local procedure ToBaseQty(ItemNo: Code[20]; Qty: Decimal): Decimal
    begin
        // Extend here for UOM conversions if needed
        exit(Qty);
    end;

    procedure RecalculateHistoricalDataForEntry(var FcstEntry: Record "WLM Forecast Entry")
    var
        Setup: Record "WLM FcstSetup";
        ILE: Record "Item Ledger Entry";
        Map: Record "WLM Adv Item Planning v2";
        SubRec: Record "Item Substitution";
        Loc: Record Location;
        DonorSet: Dictionary of [Code[20], Boolean];
        SubDonors: Dictionary of [Code[20], Boolean];
        DonorKeys: List of [Code[20]];
        DonorFilter: Text;
        DonorCode: Code[20];
        HistoricalQty: Decimal;
        MultiplierPct: Decimal;
        HistStartDate: Date;
        HistEndDate: Date;
        ProjectionMonths: Integer;
        i: Integer;
        Qty: Decimal;
        ContribPct: Decimal;
        MultPct: Decimal;
        AdjBase: Decimal;
        TargetLoc: Code[10];
        RegionCode: Code[20];
    begin
        EnsureSetup(Setup);

        // Calculate historical period - the SAME bucket from ProjectionMonths ago
        // For monthly buckets: if forecast is Nov 2026 and projection = 12 months, 
        // then historical period is Nov 2025 (the month that projected to Nov 2026)
        ProjectionMonths := Setup."Projection Months";
        if ProjectionMonths <= 0 then
            ProjectionMonths := 12;

        // Calculate the historical bucket that would have projected to this forecast date
        // HistStartDate = first day of the source month, HistEndDate = last day of source month
        HistStartDate := CalcDate(StrSubstNo('-%1M', ProjectionMonths), FcstEntry."Forecast Date");
        HistEndDate := CalcDate('<CM>', HistStartDate); // End of that month

        // Get multiplier for this item/location
        MultiplierPct := ResolveCountryMultiplier(FcstEntry."Item No.", FcstEntry."Location Code");

        // Build donor filter: self + active donors + substitutes
        Clear(DonorSet);
        Clear(SubDonors);
        if not DonorSet.ContainsKey(FcstEntry."Item No.") then
            DonorSet.Add(FcstEntry."Item No.", true);

        Map.Reset();
        Map.SetRange("Item No.", FcstEntry."Item No.");
        Map.SetRange(Active, true);
        if Map.FindSet() then
            repeat
                if IsEffective(Map."Effective From", Map."Effective To", HistStartDate, HistEndDate) then
                    if (Map."Related Item No." <> '') and (Map."Related Item No." <> FcstEntry."Item No.") then
                        if not DonorSet.ContainsKey(Map."Related Item No.") then
                            DonorSet.Add(Map."Related Item No.", true);
            until Map.Next() = 0;

        if Setup."Factor Subs in Sales Hist" then begin
            SubRec.Reset();
            SubRec.SetRange("Substitute No.", FcstEntry."Item No.");
            if SubRec.FindSet() then
                repeat
                    if not SubDonors.ContainsKey(SubRec."No.") then
                        SubDonors.Add(SubRec."No.", true);
                    if not DonorSet.ContainsKey(SubRec."No.") then
                        DonorSet.Add(SubRec."No.", true);
                until SubRec.Next() = 0;
        end;

        DonorFilter := '';
        DonorKeys := DonorSet.Keys();
        for i := 1 to DonorKeys.Count() do begin
            DonorCode := DonorKeys.Get(i);
            if DonorFilter <> '' then
                DonorFilter += '|';
            DonorFilter += DonorCode;
        end;

        // Sum historical sales from ILE for the specific historical month
        HistoricalQty := 0;
        ILE.Reset();
        ILE.SetCurrentKey("Item No.", "Posting Date", "Location Code");
        ILE.SetFilter("Item No.", DonorFilter);
        ILE.SetRange("Posting Date", HistStartDate, HistEndDate);
        ILE.SetRange("Entry Type", ILE."Entry Type"::Sale);
        ILE.SetFilter(Quantity, '<%1', 0); // Sales are negative

        if ILE.FindSet() then
            repeat
                // Check if this ILE's location maps to the forecast location
                // (Region routing may map multiple source locations to one target)
                if ShouldUseRegionMapForItem(FcstEntry."Item No.") then begin
                    RegionCode := GetShipToRegionFromPostedDoc(ILE);
                    TargetLoc := MapRegionToLocation(RegionCode);
                end else
                    TargetLoc := ILE."Location Code";

                // Only count sales that map to this forecast's location
                if TargetLoc <> FcstEntry."Location Code" then
                    continue;

                Qty := -ILE.Quantity; // Convert to positive

                // Apply donor contribution %
                GetDonorParams(FcstEntry."Item No.", ILE."Item No.", ILE."Variant Code", ILE."Posting Date", ContribPct, MultPct);

                // Substitutes get full contribution
                if SubDonors.ContainsKey(ILE."Item No.") then
                    ContribPct := 100;

                AdjBase := Qty * (ContribPct / 100);
                HistoricalQty += AdjBase;
            until ILE.Next() = 0;

        // Update the forecast entry with historical data
        FcstEntry."Historical Sales Qty" := HistoricalQty;
        FcstEntry."Multiplier Used %" := MultiplierPct;
        FcstEntry."Historical Period Start" := HistStartDate;
        FcstEntry."Historical Period End" := HistEndDate;
        FcstEntry.Modify();
    end;
}

// ---- Retail seeding (fixed filters)
codeunit 89627 "WLM RetailSeed"
{
    procedure SeedItemsToPlanning_FromDimensionFilter(): Integer
    var
        Setup: Record "WLM FcstSetup";
        Val: Record "WLM Dim Filter Value";
        DefDim: Record "Default Dimension";
        ItemRec: Record Item;
        Plan: Record "WLM Adv Item Planning v2";
        LocOn: Record "WLM Fcst Location";
        LocationRec: Record Location;
        Countries: List of [Code[10]];
        K: Code[10];
        Added: Integer;
        DimCodeU: Code[20];
        ExclPurch, ExclSales, ExclBlocked, ExclNonInv : Boolean;
        i: Integer;
        UseRegionMap: Boolean;
    begin
        Added := 0;
        if not Setup.Get('SETUP') then begin Setup.Init(); Setup.Insert(true); end;

        DimCodeU := UpperCase(Setup."Dimension Filter");
        ExclPurch := Setup."Exclude Purchasing Blocked";
        ExclSales := Setup."Exclude Sales Blocked";
        ExclBlocked := Setup."Exclude Blocked";
        ExclNonInv := Setup."Exclude Non-Inventory Items";

        Clear(Countries);
        LocOn.Reset();
        LocOn.SetRange(Active, true);
        if LocOn.FindSet() then
            repeat
                if LocationRec.Get(LocOn."Location Code") then
                    if (LocationRec."Country/Region Code" <> '') and not ListContains(Countries, LocationRec."Country/Region Code") then
                        Countries.Add(LocationRec."Country/Region Code");
            until LocOn.Next() = 0;

        if DimCodeU = '' then begin
            ItemRec.Reset();
            if ExclBlocked then ItemRec.SetRange(Blocked, false);
            if ExclPurch then ItemRec.SetRange("Purchasing Blocked", false);
            if ExclSales then ItemRec.SetRange("Sales Blocked", false);
            if ExclNonInv then ItemRec.SetRange(Type, ItemRec.Type::Inventory);

            if ItemRec.FindSet() then
                repeat
                    for i := 1 to Countries.Count() do begin
                        K := Countries.Get(i);
                        UseRegionMap := false;
                        EnsureSelfPlanRow(ItemRec."No.", K, UseRegionMap, Setup, Added);
                    end;
                until ItemRec.Next() = 0;

            exit(Added);
        end;

        // When a Dimension Filter is set, restrict to items whose Default Dimension has an Active Filter Value
        Val.Reset();
        Val.SetRange("Dimension Code", DimCodeU);
        Val.SetRange(Active, true);
        if Val.FindSet() then
            repeat
                DefDim.Reset();
                DefDim.SetRange("Table ID", Database::Item);
                DefDim.SetRange("Dimension Code", DimCodeU);
                DefDim.SetRange("Dimension Value Code", Val."Dimension Value Code");
                if DefDim.FindSet() then
                    repeat
                        if ItemRec.Get(DefDim."No.") then begin
                            if ExclBlocked and ItemRec.Blocked then continue;
                            if ExclPurch and ItemRec."Purchasing Blocked" then continue;
                            if ExclSales and ItemRec."Sales Blocked" then continue;
                            if ExclNonInv and (ItemRec.Type <> ItemRec.Type::Inventory) then continue;

                            UseRegionMap := Val."Use Region Location Mapping";
                            for i := 1 to Countries.Count() do begin
                                K := Countries.Get(i);
                                EnsureSelfPlanRow(ItemRec."No.", K, UseRegionMap, Setup, Added);
                            end;
                        end;
                    until DefDim.Next() = 0;
            until Val.Next() = 0;

        exit(Added);
    end;

    local procedure NextLineNo(): Integer
    var
        R: Record "WLM Adv Item Planning v2";
    begin
        R.Reset();
        if R.FindLast() then
            exit(R."Line No." + 10000);
        exit(10000);
    end;

    local procedure EnsureSelfPlanRow(ItemNo: Code[20]; CountryCode: Code[10]; UseRegionMap: Boolean; var Setup: Record "WLM FcstSetup"; var Added: Integer)
    var
        Plan: Record "WLM Adv Item Planning v2";
    begin
        // Check if a self row already exists for this item/country (blank or A->A)
        Plan.Reset();
        Plan.SetRange("Item No.", ItemNo);
        Plan.SetFilter("Related Item No.", '%1|%2', '', ItemNo);
        Plan.SetRange("Location Country/Region Code", CountryCode);
        if Plan.FindFirst() then
            exit;

        // Create new self row
        Plan.Init();
        Plan."Line No." := NextLineNo();
        Plan."Item No." := ItemNo;
        Plan."Related Item No." := '';
        Plan."Location Country/Region Code" := CountryCode;
        Plan."Contribution %" := 100;
        Plan."Multiplier %" := Setup."Default Self Multiplier %";
        Plan."Include Variants" := false;
        Plan.Validate("Use Workback Projection", false);
        Plan."Workback Annual Projection" := 0;
        Plan."Par Stock Target" := Setup."Default Par Stock Target";
        Plan."Use Region Location Mapping" := UseRegionMap;
        Plan.Active := true;
        Plan.Insert(true);
        Added += 1;
    end;

    local procedure ListContains(var L: List of [Code[10]]; V: Code[10]): Boolean
    var
        i: Integer;
    begin
        for i := 1 to L.Count() do
            if L.Get(i) = V then
                exit(true);
        exit(false);
    end;
}
codeunit 89629 "WLM PlanningCleanup"
{
    procedure RemoveObsoleteFromPlanning(var ItemsRemoved: Integer; var RowsRemoved: Integer)
    var
        Setup: Record "WLM FcstSetup";
        Plan, PlanToDelete : Record "WLM Adv Item Planning v2";
        ItemRec: Record Item;
        LastItemNo: Code[20];
        DeleteThisItem: Boolean;
        ExclPurch, ExclSales, ExclBlocked, ExclNonInv : Boolean;
    begin
        ItemsRemoved := 0;
        RowsRemoved := 0;

        if not Setup.Get('SETUP') then begin Setup.Init(); Setup.Insert(true); end;

        ExclPurch := Setup."Exclude Purchasing Blocked";
        ExclSales := Setup."Exclude Sales Blocked";
        ExclBlocked := Setup."Exclude Blocked";
        ExclNonInv := Setup."Exclude Non-Inventory Items";

        LastItemNo := '';

        Plan.Reset();
        Plan.SetCurrentKey("Item No.", Active, "Effective From");
        if Plan.FindSet(false) then
            repeat
                if Plan."Item No." <> LastItemNo then begin
                    LastItemNo := Plan."Item No.";
                    DeleteThisItem := false;

                    if ItemRec.Get(LastItemNo) then begin
                        if ExclBlocked and ItemRec.Blocked then DeleteThisItem := true;
                        if not DeleteThisItem and ExclPurch and ItemRec."Purchasing Blocked" then DeleteThisItem := true;
                        if not DeleteThisItem and ExclSales and ItemRec."Sales Blocked" then DeleteThisItem := true;
                        if not DeleteThisItem and ExclNonInv and (ItemRec.Type <> ItemRec.Type::Inventory) then DeleteThisItem := true;
                    end else
                        DeleteThisItem := true;

                    if DeleteThisItem then begin
                        PlanToDelete.Reset();
                        PlanToDelete.SetRange("Item No.", LastItemNo);
                        if PlanToDelete.FindSet() then
                            repeat
                                RowsRemoved += 1;
                            until PlanToDelete.Next() = 0;

                        PlanToDelete.Reset();
                        PlanToDelete.SetRange("Item No.", LastItemNo);
                        PlanToDelete.DeleteAll(true);
                        ItemsRemoved += 1;
                    end;
                end;
            until Plan.Next() = 0;
    end;
}

codeunit 89626 "WLM PromoteForecast"
{
    SingleInstance = false;

    procedure PromoteToWLMForecastEntries(ForecastName: Code[20]; FromDate: Date; ToDate: Date; ReplaceExisting: Boolean): Integer
    var
        WLEntry: Record "WLM Forecast Entry";
        Inserted: Integer;
#if WLM_PREMIUM
        DFName: Record 99000851;
        DFE: Record 99000852;
#endif
    begin
#if WLM_PREMIUM
        if not DFName.Get(ForecastName) then begin
            DFName.Init();
            DFName.Validate(Name, ForecastName);
            DFName.Insert(true);
        end;

        if ReplaceExisting then begin
            WLEntry.Reset();
            WLEntry.SetRange("Forecast Name", ForecastName);
            if FromDate <> 0D then
                WLEntry.SetRange("Forecast Date", FromDate, ToDate);
            if WLEntry.FindSet() then
                WLEntry.DeleteAll(true);
        end;

        DFE.Reset();
        DFE.SetRange("Production Forecast Name", ForecastName);
        if FromDate <> 0D then
            DFE.SetRange("Forecast Date", FromDate, ToDate);
        if DFE.FindSet() then
            repeat
                if WLEntry.Get(ForecastName, DFE."Item No.", DFE."Location Code", DFE."Forecast Date") then begin
                    WLEntry.Quantity := DFE."Forecast Quantity";
                    WLEntry.Modify(true);
                end else begin
                    WLEntry.Init();
                    WLEntry.Validate("Forecast Name", ForecastName);
                    WLEntry.Validate("Item No.", DFE."Item No.");
                    WLEntry.Validate("Location Code", DFE."Location Code");
                    WLEntry.Validate("Forecast Date", DFE."Forecast Date");
                    WLEntry.Validate(Quantity, DFE."Forecast Quantity");
                    WLEntry.Insert(true);
                end;
                Inserted += 1;
            until DFE.Next() = 0;

        exit(Inserted);
#else
        WLEntry.Reset();
        WLEntry.SetRange("Forecast Name", ForecastName);
        if FromDate <> 0D then
            WLEntry.SetRange("Forecast Date", FromDate, ToDate);
        exit(WLEntry.Count());
#endif
    end;

#if WLM_PREMIUM
    procedure PromoteToDemandForecast(ForecastName: Code[20]; FromDate: Date; ToDate: Date; ReplaceExisting: Boolean): Integer
    var
        WLEntry: Record "WLM Forecast Entry";
        DFName: Record 99000851;
        DFE: Record 99000852;
        Inserted: Integer;
    begin
        if not DFName.Get(ForecastName) then begin
            DFName.Init();
            DFName.Validate(Name, ForecastName);
            DFName.Insert(true);
        end;

        if ReplaceExisting then begin
            DFE.Reset();
            DFE.SetRange("Production Forecast Name", ForecastName);
            if FromDate <> 0D then
                DFE.SetRange("Forecast Date", FromDate, ToDate);
            DFE.DeleteAll(true);
        end;

        WLEntry.Reset();
        WLEntry.SetRange("Forecast Name", ForecastName);
        if FromDate <> 0D then
            WLEntry.SetRange("Forecast Date", FromDate, ToDate);
        if not WLEntry.FindSet() then
            Error('No WLM Forecast Entries exist for "%1" in the selected range. Run "Promote → WLM Forecast Entries" first.', ForecastName);

        repeat
            if WLEntry.Quantity = 0 then
                continue;

            if not ReplaceExisting then begin
                DFE.Reset();
                DFE.SetRange("Production Forecast Name", ForecastName);
                DFE.SetRange("Item No.", WLEntry."Item No.");
                DFE.SetRange("Location Code", WLEntry."Location Code");
                DFE.SetRange("Forecast Date", WLEntry."Forecast Date");
                if DFE.FindFirst() then
                    DFE.Delete(true);
            end;

            DFE.Init();
            DFE."Entry No." := 0;
            DFE.Validate("Production Forecast Name", ForecastName);
            DFE.Validate("Item No.", WLEntry."Item No.");
            DFE.Validate("Location Code", WLEntry."Location Code");
            DFE.Validate("Forecast Date", WLEntry."Forecast Date");
            DFE.Validate("Forecast Quantity", WLEntry.Quantity);
            DFE.Insert(true);
            Inserted += 1;
        until WLEntry.Next() = 0;

        exit(Inserted);
    end;
#else
    procedure PromoteToDemandForecast(ForecastName: Code[20]; FromDate: Date; ToDate: Date; ReplaceExisting: Boolean): Integer
    begin
        Error('Demand Forecast tables (99000851/99000852) require a build with WLM_PREMIUM.');
    end;
#endif
}

codeunit 89621 "WLM FcstNightlyJob"
{
    SingleInstance = false;

    trigger OnRun()
    var
        Builder: Codeunit "WLM FcstBuilder";
        Setup: Record "WLM FcstSetup";
#if WLM_PREMIUM
        Promote: Codeunit "WLM PromoteForecast";
        FromDate, ToDate : Date;
        today: Date;
        firstOfThis: Date;
        d: Date;
#endif
    begin
        Builder.BuildForAllActiveUsingDefaults();

#if WLM_PREMIUM
        if not Setup.Get('SETUP') then begin
            Setup.Init();
            Setup.Insert(true);
        end;

        // Forward horizon based on Projection Months
        today := Today;
        if today = 0D then today := WorkDate;

        case Setup."Default Bucket" of
            Setup."Default Bucket"::Day:
                begin
                    FromDate := today;
                    ToDate := CalcDate(StrSubstNo('+%1M', Setup."Projection Months"), today);
                end;

            Setup."Default Bucket"::Week:
                begin
                    FromDate := today - (Date2DWY(today, 1) - 1); // Monday
                    d := CalcDate(StrSubstNo('+%1M', Setup."Projection Months"), today);
                    ToDate := d + (7 - Date2DWY(d, 1)); // Sunday
                end;

            Setup."Default Bucket"::Month:
                begin
                    firstOfThis := DMY2Date(1, Date2DMY(today, 2), Date2DMY(today, 3));
                    if firstOfThis = 0D then firstOfThis := today;
                    FromDate := firstOfThis;
                    ToDate := CalcDate(StrSubstNo('+%1M', Setup."Projection Months"), firstOfThis);
                    if ToDate = 0D then ToDate := firstOfThis;
                    ToDate := CalcDate('<CM+1D-1D>', ToDate);
                end;
        end;

        Promote.PromoteToDemandForecast(Setup."Default Forecast Name", FromDate, ToDate, Setup."Replace Mode");
#endif
    end;
}

codeunit 89622 "WLM FcstInstall"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    begin
        if not TryEnsureJobQueue() then;
        SeedItemLoadingUnits();
    end;

    [TryFunction]
    procedure TryEnsureJobQueue()
    begin
        EnsureJobQueue();
    end;

    local procedure EnsureJobQueue()
    var
        JQ, Existing : Record "Job Queue Entry";
        Earliest: DateTime;
    begin
        Existing.Reset();
        Existing.SetRange("Object Type to Run", Existing."Object Type to Run"::Codeunit);
        Existing.SetRange("Object ID to Run", CODEUNIT::"WLM FcstNightlyJob");
        if Existing.FindFirst() then exit;

        Clear(JQ);
        JQ.Init();
        JQ.ID := CreateGuid();
        JQ.Validate(Description, 'WLM Nightly Forecast Build');
        JQ.Validate("Object Type to Run", JQ."Object Type to Run"::Codeunit);
        JQ.Validate("Object ID to Run", CODEUNIT::"WLM FcstNightlyJob");
        Earliest := CreateDateTime(Today, 013000T);
        if Earliest < CurrentDateTime then Earliest := CurrentDateTime + 3600000;
        JQ.Validate("Earliest Start Date/Time", Earliest);
        JQ.Validate("Recurring Job", true);
        JQ.Validate("No. of Minutes between Runs", 1440);
        JQ.Insert(false);
        JQ.SetStatus(JQ.Status::Ready);
    end;

    local procedure SeedItemLoadingUnits()
    var
        Seeder: Codeunit "WLM ItemLoadingSeed";
    begin
        Seeder.SeedAll();
    end;
}

codeunit 89661 "WLM FcstUpgrade"
{
    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
    var
        Setup: Record "WLM FcstSetup";
        DimVal: Record "Dimension Value";
        Val: Record "WLM Dim Filter Value";
        WbVal: Record "WLM Seasonality Filter Value";
        LegacyPlan: Record "WLM Adv Item Planning"; // 89600
        LegacyCtry: Record "WLM Adv Item Planning Country"; // 89640
        NewPlan: Record "WLM Adv Item Planning v2"; // 89601
        LocOn: Record "WLM Fcst Location";
        LocationRec: Record Location;
        Countries: List of [Code[10]];
        K: Code[10];
        i: Integer;
        DimCodeU: Code[20];
    begin
        if not Setup.Get('SETUP') then begin Setup.Init(); Setup.Insert(true); end;

        if Setup."Default Forecast Name" = '' then begin Setup."Default Forecast Name" := 'OPERATIONS'; Setup.Modify(true); end;

        if (Setup."Dimension Filter" = '') and (Setup."SalesType Dim. Code" <> '') then begin
            DimCodeU := UpperCase(Setup."SalesType Dim. Code");
            if DimensionExists(DimCodeU) then begin
                Setup.Validate("Dimension Filter", DimCodeU);
                Setup.Modify(true);

                if Setup."Retail Prefix" <> '' then begin
                    DimVal.Reset();
                    DimVal.SetRange("Dimension Code", Setup."Dimension Filter");
                    DimVal.SetRange(Code, UpperCase(Setup."Retail Prefix"));
                    if DimVal.FindFirst() then
                        if not Val.Get(Setup."Dimension Filter", UpperCase(Setup."Retail Prefix")) then begin
                            Val.Init();
                            Val."Dimension Code" := Setup."Dimension Filter";
                            Val."Dimension Value Code" := UpperCase(Setup."Retail Prefix");
                            Val.Active := true;
                            Val.Insert(true);
                        end;
                end;
            end else
                LogMissingDimension('Dimension Filter', DimCodeU);
        end;

        if (Setup."WB Dimension Filter" = '') and (Setup."SalesType Dim. Code" <> '') then begin
            DimCodeU := UpperCase(Setup."SalesType Dim. Code");
            if DimensionExists(DimCodeU) then begin
                Setup.Validate("WB Dimension Filter", DimCodeU);
                Setup.Modify(true);

                if Setup."Retail Prefix" <> '' then begin
                    DimVal.Reset();
                    DimVal.SetRange("Dimension Code", Setup."WB Dimension Filter");
                    DimVal.SetRange(Code, UpperCase(Setup."Retail Prefix"));
                    if DimVal.FindFirst() then
                        if not WbVal.Get(Setup."WB Dimension Filter", UpperCase(Setup."Retail Prefix")) then begin
                            WbVal.Init();
                            WbVal."Dimension Code" := Setup."WB Dimension Filter";
                            WbVal."Dimension Value Code" := UpperCase(Setup."Retail Prefix");
                            WbVal.Active := true;
                            WbVal.Insert(true);
                        end;
                end;
            end else
                LogMissingDimension('WB Dimension Filter', DimCodeU);
        end;

        Clear(Countries);
        LocOn.Reset();
        LocOn.SetRange(Active, true);
        if LocOn.FindSet() then
            repeat
                if LocationRec.Get(LocOn."Location Code") then
                    if (LocationRec."Country/Region Code" <> '') and not ListContainsCode10(Countries, LocationRec."Country/Region Code") then
                        Countries.Add(LocationRec."Country/Region Code");
            until LocOn.Next() = 0;

        LegacyPlan.Reset();
        if LegacyPlan.FindSet() then
            repeat
                if (LegacyPlan."Related Item No." = '') or (LegacyPlan."Related Item No." = LegacyPlan."Item No.") then begin
                    for i := 1 to Countries.Count() do begin
                        K := Countries.Get(i);

                        if not ExistsV2Self(LegacyPlan."Item No.", K) then begin
                            NewPlan.Init();
                            NewPlan."Line No." := NextLineNoV2();
                            NewPlan."Item No." := LegacyPlan."Item No.";
                            NewPlan."Related Item No." := '';
                            NewPlan."Location Country/Region Code" := K;
                            NewPlan."Contribution %" := 100;
                            NewPlan."Multiplier %" := ResolveLegacyCountryMultiplier(LegacyPlan."Item No.", K, LegacyPlan."Multiplier %", Setup."Default Self Multiplier %");
                            NewPlan."Include Variants" := LegacyPlan."Include Variants";
                            NewPlan.Active := LegacyPlan.Active;

                            NewPlan.Validate("Use Workback Projection", false);
                            NewPlan."Workback Annual Projection" := 0;

                            NewPlan."Par Stock Target" := Setup."Default Par Stock Target";
                            NewPlan.Insert(true);
                        end;
                    end;
                end;

                if (LegacyPlan."Related Item No." <> '') and (LegacyPlan."Related Item No." <> LegacyPlan."Item No.") then begin
                    if not ExistsV2Row(LegacyPlan."Item No.", LegacyPlan."Related Item No.") then begin
                        NewPlan.Init();
                        NewPlan."Line No." := NextLineNoV2();
                        NewPlan."Item No." := LegacyPlan."Item No.";
                        NewPlan."Related Item No." := LegacyPlan."Related Item No.";
                        NewPlan."Location Country/Region Code" := '';
                        NewPlan."Contribution %" := LegacyPlan."Contribution %";
                        NewPlan."Multiplier %" := LegacyPlan."Multiplier %";
                        NewPlan."Include Variants" := LegacyPlan."Include Variants";
                        NewPlan.Active := LegacyPlan.Active;
                        NewPlan."Par Stock Target" := Setup."Default Par Stock Target";
                        NewPlan.Insert(true);
                    end;
                end;
            until LegacyPlan.Next() = 0;
    end;

    local procedure NextLineNoV2(): Integer
    var
        V2: Record "WLM Adv Item Planning v2";
    begin
        V2.Reset();
        if V2.FindLast() then exit(V2."Line No." + 10000);
        exit(10000);
    end;

    local procedure ExistsV2Self(ItemNo: Code[20]; Country: Code[10]): Boolean
    var
        V2: Record "WLM Adv Item Planning v2";
    begin
        V2.Reset();
        V2.SetRange("Item No.", ItemNo);
        V2.SetFilter("Related Item No.", '%1|%2', '', ItemNo);
        V2.SetRange("Location Country/Region Code", Country);
        exit(V2.FindFirst());
    end;

    local procedure ExistsV2Row(ItemNo: Code[20]; RelatedItemNo: Code[20]): Boolean
    var
        V2: Record "WLM Adv Item Planning v2";
    begin
        V2.Reset();
        V2.SetRange("Item No.", ItemNo);
        V2.SetRange("Related Item No.", RelatedItemNo);
        exit(V2.FindFirst());
    end;

    local procedure ResolveLegacyCountryMultiplier(ItemNo: Code[20]; Country: Code[10]; LegacySelfMult: Decimal; DefaultSelf: Decimal): Decimal
    var
        ByCtry: Record "WLM Adv Item Planning Country";
        Eff: Decimal;
    begin
        Eff := DefaultSelf;

        ByCtry.Reset();
        ByCtry.SetRange("Item No.", ItemNo);
        ByCtry.SetRange("Related Item No.", ItemNo);
        ByCtry.SetRange("Country/Region Code", Country);
        ByCtry.SetRange(Active, true);
        if ByCtry.FindFirst() then exit(ByCtry."Multiplier %");

        if LegacySelfMult <> 0 then Eff := LegacySelfMult;
        exit(Eff);
    end;

    local procedure ListContainsCode10(var L: List of [Code[10]]; V: Code[10]): Boolean
    var
        i: Integer;
    begin
        for i := 1 to L.Count() do if L.Get(i) = V then exit(true);
        exit(false);
    end;

    local procedure DimensionExists(DimCode: Code[20]): Boolean
    var
        DimRec: Record Dimension;
    begin
        if DimCode = '' then
            exit(false);

        DimRec.Reset();
        DimRec.SetRange(Code, DimCode);
        exit(DimRec.FindFirst());
    end;

    local procedure LogMissingDimension(TargetField: Text; DimCode: Code[20])
    begin
        Session.LogMessage(
            'WLM_DIM_MISSING',
            StrSubstNo(
                'Skipped setting %1 during upgrade because Dimension %2 does not exist in this company.',
                TargetField,
                DimCode),
            Verbosity::Warning,
            DataClassification::SystemMetadata,
            TelemetryScope::ExtensionPublisher,
            'Category', 'Upgrade',
            'TargetField', TargetField);
    end;
}

// ======================= PERMISSION SET =======================
permissionset 89650 "WLM FcstAdmin"
{
    Assignable = true;
    Permissions =
        tabledata "WLM Adv Item Planning v2" = RIMD,
        tabledata "WLM FcstSetup" = RIMD,
        tabledata "WLM FcstBuffer" = RI,
        tabledata "WLM Fcst Location" = RIMD,
        tabledata "WLM Region Location Map" = RIMD,
        tabledata "WLM Forecast Entry" = RIMD,
        tabledata "WLM Order Loading Unit" = RIMD,
        tabledata "WLM Vendor Capacity" = RIMD,
        tabledata "WLM Item Loading Unit" = RIMD,
        tabledata "WLM Load Profile" = RIMD,
        tabledata "WLM Load Batch" = RIMD,
        tabledata "WLM Dim Filter Value" = RIMD,
        tabledata "WLM Seasonality Filter Value" = RIMD,
        tabledata "WLM Seasonality Attribution" = RIMD,
        tabledata "WLM Load Suggestion" = RIMD,
        tabledata Item = R,
        tabledata "Default Dimension" = R,
        tabledata "Item Ledger Entry" = R,
        tabledata "Job Queue Entry" = RIMD,
        tabledata "Sales Shipment Header" = R,
        tabledata "Sales Invoice Header" = R,
        tabledata "Sales Header" = R,
        tabledata "Sales Line" = R,
        tabledata "General Ledger Setup" = R,
        tabledata "WLM SKU Planning" = RIMD
#if WLM_POST
#if WLM_PREMIUM
        , tabledata "Production Forecast Name" = RIMD
        , tabledata "Production Forecast Entry" = RIMD
#endif
#endif
        ,
        page "WLM AdvPlanningPart" = X,
        page "WLM Adv Planning List" = X,
        page "WLM Fcst Locations" = X,
        page "WLM Fcst Location Worksheet" = X,
        page "WLM Region Location Map" = X,
        page "WLM Region Map Worksheet" = X,
        page "WLM Dim Filter Values" = X,
        page "WLM Dim Filter Worksheet" = X,
        page "WLM Seasonality Filter Values" = X,
        page "WLM Seasonality Filter WS" = X,
        page "WLM Seasonality Attribution" = X,
        page "WLM Seasonality Profiles WS" = X,
        page "WLM Order Loading Units" = X,
        page "WLM Vendor Capacity" = X,
        page "WLM Item Loading Units" = X,
        page "WLM Load Profiles" = X,
        page "WLM Load Batches" = X,
        page "WLM Load Batch Card" = X,
        page "WLM Load Batch Lines" = X,
        page "WLM Vendor Capacity Worksheet" = X,
        page "WLM Item Loading Units WS" = X,
        page "WLM Forecast Entries" = X,
        page "WLM FcstSetupCard" = X,
        codeunit "WLM FcstNightlyJob" = X,
        codeunit "WLM FcstBuilder" = X,
        codeunit "WLM RetailSeed" = X,
        codeunit "WLM PlanningCleanup" = X,
        codeunit "WLM PromoteForecast" = X,
        codeunit "WLM FcstInstall" = X,
        codeunit "WLM FcstUpgrade" = X,
        page "WLM SKU Planning" = X,
        codeunit "WLM SkuPull" = X,
        codeunit "WLM SkuReorderJob" = X,
        codeunit "WLM SeasonalityBuilder" = X,
        codeunit "WLM FilterLoader" = X,
        codeunit "WLM ItemLoadingSeed" = X,
        codeunit "WLM LoadSuggestionMgt" = X,
        codeunit "WLM LoadSuggestionWriter" = X,
        codeunit "WLM LoadPlanner" = X;
}

// ======================= SKU Planning =======================
table 89680 "WLM SKU Planning"
{
    Caption = 'WLM SKU Planning';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Item No."; Code[20]) { TableRelation = Item."No."; }
        field(2; "Location Code"; Code[10]) { TableRelation = Location.Code; }
        field(3; "Variant Code"; Code[10]) { Caption = 'Variant Code'; }
        field(10; "Reorder Point Recommendation"; Integer) { Caption = 'Reorder Point Recommendation'; }
        field(50012; "Vendor No. FF"; Code[20])
        {
            Caption = 'Vendor No.';
            FieldClass = FlowField;
            CalcFormula = lookup(Item."Vendor No." where("No." = field("Item No.")));
        }
        field(50050; "Country/Region Code FF"; Code[10])
        {
            Caption = 'Country/Region';
            FieldClass = FlowField;
            CalcFormula = lookup(Location."Country/Region Code" where(Code = field("Location Code")));
        }
    }
    keys { key(PK; "Item No.", "Location Code", "Variant Code") { Clustered = true; } }
}

page 89681 "WLM SKU Planning"
{
    PageType = List;
    SourceTable = "WLM SKU Planning";
    Caption = 'WLM SKU Planning';
    ApplicationArea = All;
    UsageCategory = Lists;
    layout
    {
        area(content)
        {
            repeater(Rep)
            {
                field(ItemNo; Rec."Item No.") { ApplicationArea = All; }
                field(Location; Rec."Location Code") { ApplicationArea = All; }
                field(Variant; Rec."Variant Code") { ApplicationArea = All; }
                field(Country; Rec."Country/Region Code FF") { ApplicationArea = All; Editable = false; }
                field(VendorNo; Rec."Vendor No. FF") { ApplicationArea = All; Editable = false; }
                field(ROP; Rec."Reorder Point Recommendation") { ApplicationArea = All; }
            }
        }
    }
}

codeunit 89682 "WLM SkuPull"
{
    procedure PullSkuToPlanning(): Integer
    var
        Setup: Record "WLM FcstSetup";
        Plan: Record "WLM Adv Item Planning v2";
        LocOn: Record "WLM Fcst Location";
        Loc: Record Location;
        WLEntry: Record "WLM Forecast Entry";
        SkuPlan: Record "WLM SKU Planning";
        CountUpserted: Integer;
        FcstName: Code[20];
        FromDate: Date;
        ToDate: Date;
        Country: Code[10];
        Par: Integer;
        TotalQty: Decimal;
        AvgPerMonth: Decimal;
    begin
        EnsureSetup(Setup);
        FcstName := Setup."Default Forecast Name";
        CalcForwardHorizon_Months(Setup."Projection Months", FromDate, ToDate);

        Plan.Reset();
        Plan.SetCurrentKey("Item No.", Active, "Effective From");
        Plan.SetRange(Active, true);
        Plan.SetFilter("Related Item No.", '%1|%2', '', Plan."Item No.");
        if Plan.FindSet() then
            repeat
                Country := Plan."Location Country/Region Code";
                if Country = '' then
                    continue;

                Par := Plan."Par Stock Target";
                if Par = 0 then
                    Par := Setup."Default Par Stock Target";

                LocOn.Reset();
                LocOn.SetRange(Active, true);
                if LocOn.FindSet() then
                    repeat
                        if Loc.Get(LocOn."Location Code") and (Loc."Country/Region Code" = Country) then begin
                            WLEntry.Reset();
                            WLEntry.SetRange("Forecast Name", FcstName);
                            WLEntry.SetRange("Item No.", Plan."Item No.");
                            WLEntry.SetRange("Location Code", Loc.Code);
                            WLEntry.SetRange("Forecast Date", FromDate, ToDate);

                            TotalQty := 0;
                            if WLEntry.FindSet() then
                                repeat
                                    TotalQty += WLEntry.Quantity;
                                until WLEntry.Next() = 0;

                            if Setup."Projection Months" > 0 then
                                AvgPerMonth := TotalQty / Setup."Projection Months"
                            else
                                AvgPerMonth := 0;

                            UpsertSkuPlan(SkuPlan, Plan."Item No.", Loc.Code, '', Round(AvgPerMonth * Par, 1, '>'));
                            CountUpserted += 1;
                        end;
                    until LocOn.Next() = 0;
            until Plan.Next() = 0;

        exit(CountUpserted);
    end;

    local procedure UpsertSkuPlan(var S: Record "WLM SKU Planning"; ItemNo: Code[20]; LocCode: Code[10]; VarCode: Code[10]; ROP: Integer)
    begin
        if S.Get(ItemNo, LocCode, VarCode) then begin
            S.Validate("Reorder Point Recommendation", ROP);
            S.Modify(true);
        end else begin
            S.Init();
            S.Validate("Item No.", ItemNo);
            S.Validate("Location Code", LocCode);
            S.Validate("Variant Code", VarCode);
            S.Validate("Reorder Point Recommendation", ROP);
            S.Insert(true);
        end;
    end;

    local procedure EnsureSetup(var Setup: Record "WLM FcstSetup")
    begin
        if not Setup.Get('SETUP') then begin Setup.Init(); Setup.Insert(true); end;
    end;

    local procedure CalcForwardHorizon_Months(ProjMonths: Integer; var FromDate: Date; var ToDate: Date)
    var
        today: Date;
        firstOfThis: Date;
    begin
        today := Today;
        if today = 0D then today := WorkDate;

        firstOfThis := DMY2Date(1, Date2DMY(today, 2), Date2DMY(today, 3));
        if firstOfThis = 0D then firstOfThis := today;

        FromDate := firstOfThis;
        ToDate := CalcDate(StrSubstNo('+%1M', ProjMonths), firstOfThis);
        if ToDate = 0D then ToDate := firstOfThis;
        ToDate := CalcDate('<CM+1D-1D>', ToDate);
    end;
}

codeunit 89683 "WLM SkuReorderJob"
{
    trigger OnRun()
    var
        Pull: Codeunit "WLM SkuPull";
    begin
        Pull.PullSkuToPlanning();
    end;
}

page 89685 "WLM Fcst Location Worksheet"
{
    Caption = 'WLM Forecast Locations';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "WLM Fcst Location";
    Editable = true;
    layout
    {
        area(content)
        {
            repeater(Rep)
            {
                field(LocationCode; Rec."Location Code") { ApplicationArea = All; }
                field(LocationCountry; Rec."Location Country/Region FF") { ApplicationArea = All; Editable = false; Caption = 'Country/Region'; }
                field(Active; Rec.Active) { ApplicationArea = All; }
            }
        }
    }
}

page 89686 "WLM Dim Filter Worksheet"
{
    Caption = 'WLM Dimension Filter Values';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "WLM Dim Filter Value";
    Editable = true;
    layout
    {
        area(content)
        {
            repeater(Rep)
            {
                field(DimensionCode; Rec."Dimension Code") { ApplicationArea = All; }
                field(DimensionValueCode; Rec."Dimension Value Code") { ApplicationArea = All; }
                field(UseRegionMap; Rec."Use Region Location Mapping") { ApplicationArea = All; }
                field(Active; Rec.Active) { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
            }
        }
    }
}

page 89687 "WLM Seasonality Filter WS"
{
    Caption = 'WLM Seasonality Filter Values';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "WLM Seasonality Filter Value";
    Editable = true;
    layout
    {
        area(content)
        {
            repeater(Rep)
            {
                field(DimensionCode; Rec."Dimension Code") { ApplicationArea = All; }
                field(DimensionValueCode; Rec."Dimension Value Code") { ApplicationArea = All; }
                field(Active; Rec.Active) { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
            }
        }
    }
}

page 89688 "WLM Seasonality Profiles WS"
{
    Caption = 'WLM Seasonality Profiles';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "WLM Seasonality Attribution";
    Editable = true;
    layout
    {
        area(content)
        {
            repeater(Rep)
            {
                field(DimensionCode; Rec."Dimension Code") { ApplicationArea = All; }
                field(DimensionValueCode; Rec."Dimension Value Code") { ApplicationArea = All; }
                field(MonthNo; Rec."Month No") { ApplicationArea = All; }
                field(LocationCode; Rec."Location Code") { ApplicationArea = All; }
                field(LocationCountry; Rec."Country/Region Code FF") { ApplicationArea = All; Editable = false; }
                field(MonthPct; Rec."Month %") { ApplicationArea = All; }
                field(LocationPct; Rec."Location %") { ApplicationArea = All; }
            }
        }
    }
}

table 89632 "WLM Order Loading Unit"
{
    Caption = 'WLM Order Loading Unit';
    DataClassification = CustomerContent;
    fields
    {
        field(1; Code; Code[10]) { Caption = 'Code'; NotBlank = true; }
        field(10; Description; Text[100]) { Caption = 'Description'; }
        field(20; InteriorLength; Decimal) { Caption = 'Interior Length'; DecimalPlaces = 0 : 5; ToolTip = 'Interior length in default length unit (setup).'; }
        field(21; InteriorWidth; Decimal) { Caption = 'Interior Width'; DecimalPlaces = 0 : 5; }
        field(22; InteriorHeight; Decimal) { Caption = 'Interior Height'; DecimalPlaces = 0 : 5; }
        field(23; MaxWeight; Decimal) { Caption = 'Max Weight'; DecimalPlaces = 0 : 5; ToolTip = 'Weight capacity in base weight unit.'; }
        field(30; DefaultShipmentMethod; Code[10]) { Caption = 'Default Shipment Method'; TableRelation = "Shipment Method"."Code"; }
        field(40; DefaultPlanningUOM; Code[10]) { Caption = 'Planning UOM Code'; TableRelation = "Unit of Measure".Code; }
        field(50; AllowAsParent; Boolean) { Caption = 'Can Act as Parent Unit'; InitValue = true; }
        field(51; AllowAsSubUnit; Boolean) { Caption = 'Can Act as Sub Unit'; InitValue = true; }
        field(52; ParentLoadingUnit; Code[10])
        {
            Caption = 'Parent Loading Unit';
            ObsoleteState = Pending;
            ObsoleteReason = 'Kept for schema compatibility; no longer used.';
            ObsoleteTag = 'WLM2.1';
        }
        field(53; UnitsPerParent; Decimal)
        {
            Caption = 'Units per Parent';
            DecimalPlaces = 0 : 5;
            ObsoleteState = Pending;
            ObsoleteReason = 'Kept for schema compatibility; no longer used.';
            ObsoleteTag = 'WLM2.1';
        }
        field(60; "Use Lane Packing"; Boolean)
        {
            Caption = 'Enforce Lane Packing Rules';
            ToolTip = 'Indicates that loads built with this parent unit must respect detailed lane/rectangle placement (no reuse of leftover pockets).';
            InitValue = false;
        }
        field(61; "Allow Rotation as Sub Unit"; Boolean)
        {
            Caption = 'Allow Rotation as Sub Unit';
            ToolTip = 'If enabled, this loading unit may be rotated when used as a child/sub unit inside a parent. Disable to force fixed orientation inside parents.';
            InitValue = true;
        }
    }
    keys { key(PK; Code) { Clustered = true; } }
}

table 89633 "WLM Vendor Capacity"
{
    Caption = 'WLM Vendor Capacity Calendar';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Vendor No."; Code[20]) { Caption = 'Vendor No.'; TableRelation = Vendor."No."; }
        field(2; "Vendor Name"; Text[100])
        {
            Caption = 'Vendor Name';
            FieldClass = FlowField;
            CalcFormula = lookup(Vendor.Name where("No." = field("Vendor No.")));
            Editable = false;
        }
        field(3; "Calendar Year"; Integer) { Caption = 'Calendar Year'; }
        field(4; "ISO Week No."; Integer) { Caption = 'ISO Week No.'; MinValue = 1; MaxValue = 53; }
        field(5; "Loading Unit Code"; Code[10]) { Caption = 'Loading Unit Code'; TableRelation = "WLM Order Loading Unit".Code; }
        field(6; OutputQty; Integer) { Caption = 'Weekly Capacity (Units)'; MinValue = 0; }
        field(7; Description; Text[100]) { Caption = 'Description'; }
    }
    keys
    {
        key(PK; "Vendor No.", "Calendar Year", "ISO Week No.", "Loading Unit Code") { Clustered = true; }
    }
}

table 89634 "WLM Item Loading Unit"
{
    Caption = 'WLM Item Loading Unit';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item."No.";
            trigger OnValidate()
            begin
                EnsureDefaultUOMFromSetup();
                AutoPopulateItemDimensions();
                AutoPopulateUnitsPerSubUnit(true);
            end;
        }
        field(2; "Default Loading Unit"; Code[10])
        {
            Caption = 'Default Loading Unit';
            TableRelation = "WLM Order Loading Unit".Code;
            trigger OnValidate()
            begin
                AutoPopulateItemDimensions();
                AutoPopulateUnitsPerSubUnit(true);
            end;
        }
        field(3; "Units per Sub Unit"; Integer)
        {
            Caption = 'Units per Sub Unit';
            MinValue = 0;
            trigger OnValidate()
            begin
                if "Units per Sub Unit" = 0 then
                    AutoPopulateUnitsPerSubUnit(true);
            end;
        }
        field(4; CanRotate; Boolean) { Caption = 'Can Rotate'; InitValue = false; }
        field(5; CanStack; Boolean) { Caption = 'Can Stack'; InitValue = true; }
        field(6; StackWith; Option) { Caption = 'Stack With'; OptionMembers = Self,Mixed,None; InitValue = Self; }
        field(7; AllowPartialSubUnit; Boolean) { Caption = 'Allow Partial Sub Unit'; InitValue = false; }
        field(8; DefaultUOM; Code[10])
        {
            Caption = 'Default Planning UOM';
            TableRelation = "Unit of Measure".Code;
            trigger OnValidate()
            begin
                if DefaultUOM = '' then
                    EnsureDefaultUOMFromSetup();
                AutoPopulateItemDimensions();
                AutoPopulateUnitsPerSubUnit(true);
            end;
        }
        field(9; "Item Description"; Text[100])
        {
            Caption = 'Item Description';
            FieldClass = FlowField;
            CalcFormula = lookup(Item.Description where("No." = field("Item No.")));
            Editable = false;
        }
        field(20; "Unit Length"; Decimal)
        {
            Caption = 'Unit Length';
            DecimalPlaces = 0 : 5;
            trigger OnValidate()
            begin
                SyncDimensionsToItemUOM();
            end;
        }
        field(21; "Unit Width"; Decimal)
        {
            Caption = 'Unit Width';
            DecimalPlaces = 0 : 5;
            trigger OnValidate()
            begin
                SyncDimensionsToItemUOM();
            end;
        }
        field(22; "Unit Height"; Decimal)
        {
            Caption = 'Unit Height';
            DecimalPlaces = 0 : 5;
            trigger OnValidate()
            begin
                SyncDimensionsToItemUOM();
            end;
        }
        field(23; "Unit Weight"; Decimal)
        {
            Caption = 'Unit Weight';
            DecimalPlaces = 0 : 5;
            trigger OnValidate()
            begin
                SyncDimensionsToItemUOM();
            end;
        }
        field(24; Cubage; Decimal)
        {
            Caption = 'Cubage';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(30; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            FieldClass = FlowField;
            CalcFormula = lookup(Item."Vendor No." where("No." = field("Item No.")));
        }
        field(40; "Item Category Code"; Code[20])
        {
            Caption = 'Item Category Code';
            FieldClass = FlowField;
            CalcFormula = lookup(Item."Item Category Code" where("No." = field("Item No.")));
        }
        field(41; "Global Dimension 1 Code"; Code[20])
        {
            Caption = 'Global Dimension 1 Code';
            FieldClass = FlowField;
            CalcFormula = lookup(Item."Global Dimension 1 Code" where("No." = field("Item No.")));
        }
        field(42; "Global Dimension 2 Code"; Code[20])
        {
            Caption = 'Global Dimension 2 Code';
            FieldClass = FlowField;
            CalcFormula = lookup(Item."Global Dimension 2 Code" where("No." = field("Item No.")));
        }
        field(50; "SD3 Code Name"; Code[20])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("General Ledger Setup"."Shortcut Dimension 3 Code");
        }
        field(51; "SD4 Code Name"; Code[20])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("General Ledger Setup"."Shortcut Dimension 4 Code");
        }
        field(52; "SD5 Code Name"; Code[20])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("General Ledger Setup"."Shortcut Dimension 5 Code");
        }
        field(53; "SD6 Code Name"; Code[20])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("General Ledger Setup"."Shortcut Dimension 6 Code");
        }
        field(54; "SD7 Code Name"; Code[20])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("General Ledger Setup"."Shortcut Dimension 7 Code");
        }
        field(55; "SD8 Code Name"; Code[20])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("General Ledger Setup"."Shortcut Dimension 8 Code");
        }
        field(60; "Shortcut Dimension 3 Value"; Code[20])
        {
            Caption = 'Shortcut Dimension 3 Value';
            FieldClass = FlowField;
            CalcFormula = lookup("Default Dimension"."Dimension Value Code" where("Table ID" = const(Database::Item), "No." = field("Item No."), "Dimension Code" = field("SD3 Code Name")));
        }
        field(61; "Shortcut Dimension 4 Value"; Code[20])
        {
            Caption = 'Shortcut Dimension 4 Value';
            FieldClass = FlowField;
            CalcFormula = lookup("Default Dimension"."Dimension Value Code" where("Table ID" = const(Database::Item), "No." = field("Item No."), "Dimension Code" = field("SD4 Code Name")));
        }
        field(62; "Shortcut Dimension 5 Value"; Code[20])
        {
            Caption = 'Shortcut Dimension 5 Value';
            FieldClass = FlowField;
            CalcFormula = lookup("Default Dimension"."Dimension Value Code" where("Table ID" = const(Database::Item), "No." = field("Item No."), "Dimension Code" = field("SD5 Code Name")));
        }
        field(63; "Shortcut Dimension 6 Value"; Code[20])
        {
            Caption = 'Shortcut Dimension 6 Value';
            FieldClass = FlowField;
            CalcFormula = lookup("Default Dimension"."Dimension Value Code" where("Table ID" = const(Database::Item), "No." = field("Item No."), "Dimension Code" = field("SD6 Code Name")));
        }
        field(64; "Shortcut Dimension 7 Value"; Code[20])
        {
            Caption = 'Shortcut Dimension 7 Value';
            FieldClass = FlowField;
            CalcFormula = lookup("Default Dimension"."Dimension Value Code" where("Table ID" = const(Database::Item), "No." = field("Item No."), "Dimension Code" = field("SD7 Code Name")));
        }
        field(65; "Shortcut Dimension 8 Value"; Code[20])
        {
            Caption = 'Shortcut Dimension 8 Value';
            FieldClass = FlowField;
            CalcFormula = lookup("Default Dimension"."Dimension Value Code" where("Table ID" = const(Database::Item), "No." = field("Item No."), "Dimension Code" = field("SD8 Code Name")));
        }
    }
    keys { key(PK; "Item No.") { Clustered = true; } }

    trigger OnInsert()
    begin
        EnsureDefaultUOMFromSetup();
        AutoPopulateItemDimensions();
        AutoPopulateUnitsPerSubUnit(true);
        RecomputeItemFits();
    end;

    trigger OnModify()
    begin
        RecomputeItemFits();
    end;

    local procedure AutoPopulateUnitsPerSubUnit(Force: Boolean)
    var
        LoadingUnit: Record "WLM Order Loading Unit";
        ItemRec: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        BaseUOMCode: Code[10];
        ItemLength: Decimal;
        ItemWidth: Decimal;
        ItemHeight: Decimal;
        ItemWeight: Decimal;
        ContainerVolume: Decimal;
        ItemVolume: Decimal;
        VolumeCapacity: Decimal;
        WeightCapacity: Decimal;
        Suggested: Decimal;
    begin
        if (not Force) and ("Units per Sub Unit" <> 0) then
            exit;

        if "Item No." = '' then
            exit;

        if "Default Loading Unit" = '' then begin
            "Units per Sub Unit" := 1;
            exit;
        end;

        if not LoadingUnit.Get("Default Loading Unit") then
            exit;

        if not ItemRec.Get("Item No.") then
            exit;

        if (DefaultUOM <> '') and ItemUOM.Get("Item No.", DefaultUOM) then begin
            ItemLength := ItemUOM.Length;
            ItemWidth := ItemUOM.Width;
            ItemHeight := ItemUOM.Height;
            ItemWeight := ItemUOM.Weight;
        end else begin
            BaseUOMCode := ItemRec."Base Unit of Measure";
            if (BaseUOMCode <> '') and ItemUOM.Get("Item No.", BaseUOMCode) then begin
                ItemLength := ItemUOM.Length;
                ItemWidth := ItemUOM.Width;
                ItemHeight := ItemUOM.Height;
                ItemWeight := ItemUOM.Weight;
            end else begin
                ItemLength := "Unit Length";
                ItemWidth := "Unit Width";
                ItemHeight := "Unit Height";
                ItemWeight := "Unit Weight";
            end;
        end;

        ContainerVolume := LoadingUnit.InteriorLength * LoadingUnit.InteriorWidth * LoadingUnit.InteriorHeight;
        ItemVolume := ItemLength * ItemWidth * ItemHeight;

        if (ContainerVolume > 0) and (ItemVolume > 0) then
            VolumeCapacity := ROUND(ContainerVolume / ItemVolume, 1, '<');

        if (LoadingUnit.MaxWeight > 0) and (ItemWeight > 0) then
            WeightCapacity := ROUND(LoadingUnit.MaxWeight / ItemWeight, 1, '<');

        if (VolumeCapacity > 0) and (WeightCapacity > 0) then begin
            if VolumeCapacity < WeightCapacity then
                Suggested := RoundCapacity(VolumeCapacity)
            else
                Suggested := RoundCapacity(WeightCapacity);
        end else if VolumeCapacity > 0 then
                Suggested := RoundCapacity(VolumeCapacity)
        else if WeightCapacity > 0 then
            Suggested := RoundCapacity(WeightCapacity)
        else
            Suggested := 0;

        if Suggested <= 0 then
            Suggested := 1;

        "Units per Sub Unit" := ROUND(Suggested, 1, '<');
    end;

    local procedure RoundCapacity(Value: Decimal): Decimal
    begin
        if Value <= 0 then
            exit(0);
        exit(ROUND(Value, 1, '<'));
    end;

    local procedure EnsureDefaultUOMFromSetup()
    var
        Setup: Record "WLM FcstSetup";
    begin
        if DefaultUOM <> '' then
            exit;

        if not Setup.Get('SETUP') then
            exit;

        if Setup."Planning UOM Code" = '' then
            exit;

        DefaultUOM := Setup."Planning UOM Code";
    end;

    local procedure AutoPopulateItemDimensions()
    var
        ItemUOM: Record "Item Unit of Measure";
        ItemRec: Record Item;
        UOMCode: Code[10];
    begin
        if "Item No." = '' then
            exit;

        UOMCode := DefaultUOM;
        if UOMCode = '' then begin
            if ItemRec.Get("Item No.") then
                UOMCode := ItemRec."Base Unit of Measure";
        end;

        if (UOMCode <> '') and ItemUOM.Get("Item No.", UOMCode) then begin
            "Unit Length" := ItemUOM.Length;
            "Unit Width" := ItemUOM.Width;
            "Unit Height" := ItemUOM.Height;
            "Unit Weight" := ItemUOM.Weight;
            Cubage := ItemUOM.Cubage;
        end;
    end;

    local procedure SyncDimensionsToItemUOM()
    var
        ItemUOM: Record "Item Unit of Measure";
        ItemRec: Record Item;
        UOMCode: Code[10];
    begin
        if "Item No." = '' then
            exit;

        UOMCode := DefaultUOM;
        if UOMCode = '' then begin
            if ItemRec.Get("Item No.") then
                UOMCode := ItemRec."Base Unit of Measure";
        end;

        if UOMCode = '' then
            exit;

        if not ItemUOM.Get("Item No.", UOMCode) then
            exit;

        ItemUOM.Validate(Length, "Unit Length");
        ItemUOM.Validate(Width, "Unit Width");
        ItemUOM.Validate(Height, "Unit Height");
        ItemUOM.Validate(Weight, "Unit Weight");
        ItemUOM.Modify(true);
        Cubage := ItemUOM.Cubage;
    end;

    local procedure RecomputeItemFits()
    var
        FitMgt: Codeunit "WLM Item Load Fit Mgt";
    begin
        if "Item No." = '' then
            exit;
        FitMgt.RecomputeForItem("Item No.");
    end;
}

page 89690 "WLM Order Loading Units"
{
    PageType = ListPart;
    SourceTable = "WLM Order Loading Unit";
    Caption = 'Order Loading Units';
    ApplicationArea = All;
    Editable = true;
    layout
    {
        area(content)
        {
            repeater(Rep)
            {
                field(Code; Rec.Code) { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field(DefaultShipmentMethod; Rec."DefaultShipmentMethod") { ApplicationArea = All; Caption = 'Default Shipment Method'; }
                field(DefaultPlanningUOM; Rec."DefaultPlanningUOM") { ApplicationArea = All; Caption = 'Planning UOM'; }
                field(InteriorLength; Rec.InteriorLength) { ApplicationArea = All; Caption = 'Interior Length'; }
                field(InteriorWidth; Rec.InteriorWidth) { ApplicationArea = All; Caption = 'Interior Width'; }
                field(InteriorHeight; Rec.InteriorHeight) { ApplicationArea = All; Caption = 'Interior Height'; }
                field(MaxWeight; Rec.MaxWeight) { ApplicationArea = All; Caption = 'Max Weight'; }
                field(AllowAsParent; Rec.AllowAsParent) { ApplicationArea = All; Caption = 'Can Be Parent'; }
                field(AllowAsSubUnit; Rec.AllowAsSubUnit) { ApplicationArea = All; Caption = 'Can Be Sub Unit'; }
                field(UseLanePacking; Rec."Use Lane Packing") { ApplicationArea = All; Caption = 'Use Lane Packing'; }
                field(AllowRotationAsSubUnit; Rec."Allow Rotation as Sub Unit")
                {
                    ApplicationArea = All;
                    Caption = 'Allow Rotation as Sub Unit';
                    Editable = Rec.AllowAsSubUnit;
                }
            }
        }
    }
}

page 89691 "WLM Vendor Capacity"
{
    PageType = ListPart;
    SourceTable = "WLM Vendor Capacity";
    Caption = 'Vendor Capacity Calendar';
    ApplicationArea = All;
    Editable = true;
    layout
    {
        area(content)
        {
            repeater(Rep)
            {
                field(VendorNo; Rec."Vendor No.") { ApplicationArea = All; }
                field(VendorName; Rec."Vendor Name") { ApplicationArea = All; Editable = false; }
                field(CalendarYear; Rec."Calendar Year") { ApplicationArea = All; }
                field(ISOWeekNo; Rec."ISO Week No.") { ApplicationArea = All; }
                field(LoadingUnitCode; Rec."Loading Unit Code") { ApplicationArea = All; }
                field(OutputQty; Rec.OutputQty) { ApplicationArea = All; Caption = 'Weekly Capacity'; }
                field(Description; Rec.Description) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(EditVendorCapacityInExcel)
            {
                Caption = 'Edit in Excel';
                ApplicationArea = All;
                Image = Excel;
                ToolTip = 'Opens the vendor capacity calendar in Excel for faster maintenance.';
                trigger OnAction()
                begin
                    PAGE.Run(PAGE::"WLM Vendor Capacity Worksheet");
                end;
            }
        }
    }
}

page 89692 "WLM Item Loading Units"
{
    PageType = ListPart;
    SourceTable = "WLM Item Loading Unit";
    Caption = 'Item Loading Units';
    ApplicationArea = All;
    Editable = true;
    layout
    {
        area(content)
        {
            repeater(Rep)
            {
                field(ItemNo; Rec."Item No.") { ApplicationArea = All; }
                field(ItemDescription; Rec."Item Description") { ApplicationArea = All; Editable = false; }
                field(VendorNo; Rec."Vendor No.") { ApplicationArea = All; Caption = 'Vendor No.'; Editable = false; }
                field(ItemCategory; Rec."Item Category Code") { ApplicationArea = All; Caption = 'Item Category Code'; Editable = false; }
                field(GlobalDim1; Rec."Global Dimension 1 Code") { ApplicationArea = All; Caption = 'Global Dimension 1 Code'; Editable = false; }
                field(GlobalDim2; Rec."Global Dimension 2 Code") { ApplicationArea = All; Caption = 'Global Dimension 2 Code'; Editable = false; }
                field(ShortcutDim3; Rec."Shortcut Dimension 3 Value") { ApplicationArea = All; Caption = 'Shortcut Dimension 3 Value'; Editable = false; }
                field(ShortcutDim4; Rec."Shortcut Dimension 4 Value") { ApplicationArea = All; Caption = 'Shortcut Dimension 4 Value'; Editable = false; }
                field(ShortcutDim5; Rec."Shortcut Dimension 5 Value") { ApplicationArea = All; Caption = 'Shortcut Dimension 5 Value'; Editable = false; }
                field(ShortcutDim6; Rec."Shortcut Dimension 6 Value") { ApplicationArea = All; Caption = 'Shortcut Dimension 6 Value'; Editable = false; }
                field(ShortcutDim7; Rec."Shortcut Dimension 7 Value") { ApplicationArea = All; Caption = 'Shortcut Dimension 7 Value'; Editable = false; }
                field(ShortcutDim8; Rec."Shortcut Dimension 8 Value") { ApplicationArea = All; Caption = 'Shortcut Dimension 8 Value'; Editable = false; }
                field(DefaultLoadingUnit; Rec."Default Loading Unit") { ApplicationArea = All; }
                field(DefaultUOM; Rec."DefaultUOM") { ApplicationArea = All; Caption = 'Planning UOM'; }
                field(UnitsPerSubUnit; Rec."Units per Sub Unit") { ApplicationArea = All; }
                field(AllowPartial; Rec.AllowPartialSubUnit) { ApplicationArea = All; Caption = 'Allow Partial'; }
                field(CanRotate; Rec.CanRotate) { ApplicationArea = All; }
                field(CanStack; Rec.CanStack) { ApplicationArea = All; }
                field(StackWith; Rec.StackWith) { ApplicationArea = All; }
                field(UnitLength; Rec."Unit Length") { ApplicationArea = All; Caption = 'Unit Length'; }
                field(UnitWidth; Rec."Unit Width") { ApplicationArea = All; Caption = 'Unit Width'; }
                field(UnitHeight; Rec."Unit Height") { ApplicationArea = All; Caption = 'Unit Height'; }
                field(UnitWeight; Rec."Unit Weight") { ApplicationArea = All; Caption = 'Unit Weight'; }
                field(Cubage; Rec.Cubage) { ApplicationArea = All; Caption = 'Cubage'; Editable = false; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(EditItemLoadingUnitsInExcel)
            {
                Caption = 'Edit in Excel';
                ApplicationArea = All;
                Image = Excel;
                ToolTip = 'Opens the Item Loading Units worksheet in Excel for bulk editing.';
                trigger OnAction()
                begin
                    PAGE.Run(PAGE::"WLM Item Loading Units WS");
                end;
            }
            action(ViewFits)
            {
                Caption = 'View Item Load Fits';
                ApplicationArea = All;
                Image = ViewDetails;
                ToolTip = 'Open the computed item load fits for the selected item.';
                trigger OnAction()
                var
                    FitRec: Record "WLM Item Load Fit";
                begin
                    if Rec."Item No." = '' then
                        exit;
                    FitRec.Reset();
                    FitRec.SetRange("Item No.", Rec."Item No.");
                    PAGE.Run(PAGE::"WLM Item Load Fit List", FitRec);
                end;
            }
        }
    }
}

page 89693 "WLM Vendor Capacity Worksheet"
{
    Caption = 'WLM Vendor Capacity';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "WLM Vendor Capacity";
    Editable = true;
    layout
    {
        area(content)
        {
            repeater(Rep)
            {
                field(VendorNo; Rec."Vendor No.") { ApplicationArea = All; }
                field(VendorName; Rec."Vendor Name") { ApplicationArea = All; Editable = false; }
                field(CalendarYear; Rec."Calendar Year") { ApplicationArea = All; }
                field(ISOWeekNo; Rec."ISO Week No.") { ApplicationArea = All; }
                field(LoadingUnitCode; Rec."Loading Unit Code") { ApplicationArea = All; }
                field(OutputQty; Rec.OutputQty) { ApplicationArea = All; Caption = 'Weekly Capacity'; }
                field(Description; Rec.Description) { ApplicationArea = All; }
            }
        }
    }
}

page 89694 "WLM Item Loading Units WS"
{
    Caption = 'WLM Item Loading Units';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "WLM Item Loading Unit";
    Editable = true;
    layout
    {
        area(content)
        {
            repeater(Rep)
            {
                field(ItemNo; Rec."Item No.") { ApplicationArea = All; }
                field(ItemDescription; Rec."Item Description") { ApplicationArea = All; Editable = false; }
                field(VendorNo; Rec."Vendor No.") { ApplicationArea = All; Caption = 'Vendor No.'; Editable = false; }
                field(ItemCategory; Rec."Item Category Code") { ApplicationArea = All; Caption = 'Item Category Code'; Editable = false; }
                field(GlobalDim1; Rec."Global Dimension 1 Code") { ApplicationArea = All; Caption = 'Global Dimension 1 Code'; Editable = false; }
                field(GlobalDim2; Rec."Global Dimension 2 Code") { ApplicationArea = All; Caption = 'Global Dimension 2 Code'; Editable = false; }
                field(ShortcutDim3; Rec."Shortcut Dimension 3 Value") { ApplicationArea = All; Caption = 'Shortcut Dimension 3 Value'; Editable = false; }
                field(ShortcutDim4; Rec."Shortcut Dimension 4 Value") { ApplicationArea = All; Caption = 'Shortcut Dimension 4 Value'; Editable = false; }
                field(ShortcutDim5; Rec."Shortcut Dimension 5 Value") { ApplicationArea = All; Caption = 'Shortcut Dimension 5 Value'; Editable = false; }
                field(ShortcutDim6; Rec."Shortcut Dimension 6 Value") { ApplicationArea = All; Caption = 'Shortcut Dimension 6 Value'; Editable = false; }
                field(ShortcutDim7; Rec."Shortcut Dimension 7 Value") { ApplicationArea = All; Caption = 'Shortcut Dimension 7 Value'; Editable = false; }
                field(ShortcutDim8; Rec."Shortcut Dimension 8 Value") { ApplicationArea = All; Caption = 'Shortcut Dimension 8 Value'; Editable = false; }
                field(DefaultLoadingUnit; Rec."Default Loading Unit") { ApplicationArea = All; }
                field(DefaultUOM; Rec."DefaultUOM") { ApplicationArea = All; Caption = 'Planning UOM'; }
                field(UnitsPerSubUnit; Rec."Units per Sub Unit") { ApplicationArea = All; }
                field(CanRotate; Rec.CanRotate) { ApplicationArea = All; }
                field(CanStack; Rec.CanStack) { ApplicationArea = All; }
                field(StackWith; Rec.StackWith) { ApplicationArea = All; }
                field(AllowPartial; Rec.AllowPartialSubUnit) { ApplicationArea = All; Caption = 'Allow Partial'; }
                field(UnitLength; Rec."Unit Length") { ApplicationArea = All; }
                field(UnitWidth; Rec."Unit Width") { ApplicationArea = All; }
                field(UnitHeight; Rec."Unit Height") { ApplicationArea = All; }
                field(UnitWeight; Rec."Unit Weight") { ApplicationArea = All; }
                field(Cubage; Rec.Cubage) { ApplicationArea = All; Editable = false; }
            }
        }
    }
}
table 89700 "WLM Load Profile"
{
    Caption = 'WLM Load Profile';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Code; Code[20])
        {
            Caption = 'Code';
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Suggestion Type"; Enum "WLM Load Suggestion Type")
        {
            Caption = 'Suggestion Type';
        }
        field(4; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor."No.";
        }
        field(5; "Source Location Code"; Code[10])
        {
            Caption = 'Source Location Code';
            TableRelation = Location.Code;
        }
        field(6; "Destination Location Code"; Code[10])
        {
            Caption = 'Destination Location Code';
            TableRelation = Location.Code;
        }
        field(7; "Shipping Method Code"; Code[10])
        {
            Caption = 'Shipping Method Code';
            TableRelation = "Shipment Method".Code;
        }
        field(8; "Parent Load Unit Code"; Code[10])
        {
            Caption = 'Parent Load Unit Code';
            TableRelation = "WLM Order Loading Unit".Code;
        }
        field(9; "Parent Unit Capacity"; Decimal)
        {
            Caption = 'Parent Unit Capacity';
            DecimalPlaces = 0 : 5;
        }
        field(10; "Min Fill Percent"; Decimal)
        {
            Caption = 'Minimum Fill %';
            DecimalPlaces = 0 : 2;
            MinValue = 0;
            MaxValue = 100;
        }
        field(11; "Allow Mixed Items"; Boolean)
        {
            Caption = 'Allow Mixed Items';
            InitValue = true;
        }
        field(12; "Allow Partial Load"; Boolean)
        {
            Caption = 'Allow Partial Load';
            InitValue = false;
        }
        field(13; "Planning Document Type"; Option)
        {
            Caption = 'Planning Document Type';
            OptionMembers = PurchaseOrder,TransferOrder;
        }
        field(14; "Default Priority Weight"; Decimal)
        {
            Caption = 'Default Priority Weight';
            DecimalPlaces = 0 : 5;
        }
    }

    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
        key(TypeIdx; "Suggestion Type", "Vendor No.", "Source Location Code", "Destination Location Code")
        {
        }
    }
}

page 89700 "WLM Load Profiles"
{
    PageType = List;
    SourceTable = "WLM Load Profile";
    Caption = 'WLM Load Profiles';
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(Code; Rec.Code) { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field(SuggestionType; Rec."Suggestion Type") { ApplicationArea = All; }
                field(VendorNo; Rec."Vendor No.") { ApplicationArea = All; }
                field(SourceLocation; Rec."Source Location Code") { ApplicationArea = All; }
                field(DestinationLocation; Rec."Destination Location Code") { ApplicationArea = All; }
                field(ShippingMethod; Rec."Shipping Method Code") { ApplicationArea = All; }
                field(ParentLoadUnit; Rec."Parent Load Unit Code") { ApplicationArea = All; }
                field(ParentCapacity; Rec."Parent Unit Capacity") { ApplicationArea = All; }
                field(MinFillPercent; Rec."Min Fill Percent") { ApplicationArea = All; }
                field(AllowMixedItems; Rec."Allow Mixed Items") { ApplicationArea = All; }
                field(AllowPartialLoad; Rec."Allow Partial Load") { ApplicationArea = All; }
                field(PlanningDocType; Rec."Planning Document Type") { ApplicationArea = All; }
                field(DefaultPriorityWeight; Rec."Default Priority Weight") { ApplicationArea = All; }
            }
        }
    }
}

table 89701 "WLM Load Batch"
{
    Caption = 'WLM Load Batch';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Load Group ID"; Guid)
        {
            Caption = 'Load Group ID';
        }
        field(2; "Batch No."; Code[20])
        {
            Caption = 'Batch No.';
        }
        field(3; "Profile Code"; Code[20])
        {
            Caption = 'Profile Code';
            TableRelation = "WLM Load Profile".Code;
        }
        field(4; "Suggestion Type"; Enum "WLM Load Suggestion Type")
        {
            Caption = 'Suggestion Type';
        }
        field(5; "Source Location Code"; Code[10])
        {
            Caption = 'Source Location Code';
            TableRelation = Location.Code;
        }
        field(6; "Destination Location Code"; Code[10])
        {
            Caption = 'Destination Location Code';
            TableRelation = Location.Code;
        }
        field(7; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor."No.";
        }
        field(8; "Shipping Method Code"; Code[10])
        {
            Caption = 'Shipping Method Code';
            TableRelation = "Shipment Method".Code;
        }
        field(9; "Parent Load Unit Code"; Code[10])
        {
            Caption = 'Parent Load Unit Code';
            TableRelation = "WLM Order Loading Unit".Code;
        }
        field(10; "Parent Unit Capacity"; Decimal)
        {
            Caption = 'Parent Unit Capacity';
            DecimalPlaces = 0 : 5;
        }
        field(11; "Parent Units Planned"; Decimal)
        {
            Caption = 'Parent Units Planned';
            DecimalPlaces = 0 : 5;
        }
        field(12; "Min Fill Percent"; Decimal)
        {
            Caption = 'Minimum Fill %';
            DecimalPlaces = 0 : 2;
        }
        field(13; Status; Option)
        {
            Caption = 'Status';
            OptionMembers = Planned,Firm,Released,Closed,Skipped;
            InitValue = Planned;
        }
        field(14; "Release Date"; Date)
        {
            Caption = 'Release Date';
        }
        field(15; "Required Date"; Date)
        {
            Caption = 'Required Date';
        }
        field(16; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(17; "Created At"; DateTime)
        {
            Caption = 'Created At';
            Editable = false;
        }
        field(18; "Created By"; Code[50])
        {
            Caption = 'Created By';
            Editable = false;
        }
        field(20; "Requirement Period"; Text[10])
        {
            Caption = 'Requirement Period';
            Description = 'YYYY-MM period for the batch (for mixed load grouping)';
        }
        field(21; "Load Fill Percent"; Decimal)
        {
            Caption = 'Load Fill %';
            DecimalPlaces = 0 : 2;
            Description = 'Actual fill percentage of the load batch';
        }
        field(22; "Mixed SKU Count"; Integer)
        {
            Caption = 'Mixed SKU Count';
            FieldClass = FlowField;
            CalcFormula = count("WLM Load Suggestion" where("Load Group ID" = field("Load Group ID")));
            Editable = false;
        }
        field(23; "Total Sub Units"; Decimal)
        {
            Caption = 'Total Sub Units';
            DecimalPlaces = 0 : 5;
            FieldClass = FlowField;
            CalcFormula = sum("WLM Load Suggestion"."Sub Units" where("Load Group ID" = field("Load Group ID")));
            Editable = false;
            ObsoleteState = Pending;
            ObsoleteReason = 'Use Total Units (field 25) instead which sums base quantity';
        }
        field(24; "Avg Month Priority"; Decimal)
        {
            Caption = 'Avg Month Priority';
            DecimalPlaces = 0 : 2;
            Description = 'Average month priority rank of items in this batch';
            ObsoleteState = Pending;
            ObsoleteReason = 'Use Batch Priority (field 26) instead';
        }
        field(25; "Total Units"; Decimal)
        {
            Caption = 'Total Units';
            DecimalPlaces = 0 : 5;
            FieldClass = FlowField;
            CalcFormula = sum("WLM Load Suggestion"."Sub Units" where("Load Group ID" = field("Load Group ID")));
            Editable = false;
            Description = 'Total sub units (pieces) on the batch - same as what Parent Units Planned was';
        }
        field(26; "Batch Priority"; Integer)
        {
            Caption = 'Batch Priority';
            Description = 'Priority order for batches - lower number = higher priority';
        }
        field(27; "Total Weight"; Decimal)
        {
            Caption = 'Total Weight';
            DecimalPlaces = 0 : 2;
            Editable = false;
            Description = 'Total weight of all items in the batch (Item Qty * Net Weight)';
        }
        field(28; "Expected Receipt Date"; Date)
        {
            Caption = 'Expected Receipt Date';
            Description = 'Earliest feasible arrival date factoring lead times from Item/Vendor/SKU';
        }
        field(29; "Proposed Document No."; Code[20])
        {
            Caption = 'Proposed Document No.';
            Editable = false;
            Description = 'Document number created when batch is promoted to planning lines';
        }
    }

    keys
    {
        key(PK; "Load Group ID")
        {
            Clustered = true;
        }
        key(BatchIdx; "Batch No.")
        {
        }
        key(PriorityIdx; "Batch Priority", "Batch No.")
        {
        }
        key(PeriodIdx; "Requirement Period", "Vendor No.")
        {
        }
    }

    trigger OnInsert()
    begin
        if "Created At" = 0DT then
            "Created At" := CurrentDateTime;
        if "Created By" = '' then
            "Created By" := UserId;
    end;
}

page 89701 "WLM Load Batches"
{
    PageType = List;
    SourceTable = "WLM Load Batch";
    SourceTableView = sorting("Batch Priority", "Batch No.");
    Caption = 'WLM Load Batches';
    ApplicationArea = All;
    UsageCategory = Tasks;
    CardPageID = "WLM Load Batch Card";

    layout
    {
        area(content)
        {
            group(Batches)
            {
                repeater(General)
                {
                    field(BatchPriority; Rec."Batch Priority") { ApplicationArea = All; Caption = 'Priority'; }
                    field(BatchNo; Rec."Batch No.") { ApplicationArea = All; }
                    field(ProfileCode; Rec."Profile Code") { ApplicationArea = All; }
                    field(RequirementPeriod; Rec."Requirement Period") { ApplicationArea = All; Caption = 'Req. Period'; }
                    field(SuggestionType; Rec."Suggestion Type") { ApplicationArea = All; }
                    field(Status; Rec.Status) { ApplicationArea = All; }
                    field(MixedSKUCount; Rec."Mixed SKU Count") { ApplicationArea = All; Caption = 'SKU Count'; }
                    field(TotalUnits; Rec."Total Units") { ApplicationArea = All; Caption = 'Total Units'; }
                    field(LoadFillPercent; Rec."Load Fill Percent") { ApplicationArea = All; Caption = 'Fill %'; }
                    field(SourceLocation; Rec."Source Location Code") { ApplicationArea = All; }
                    field(DestinationLocation; Rec."Destination Location Code") { ApplicationArea = All; }
                    field(VendorNo; Rec."Vendor No.") { ApplicationArea = All; }
                    field(ShippingMethod; Rec."Shipping Method Code") { ApplicationArea = All; }
                    field(ParentLoadUnit; Rec."Parent Load Unit Code") { ApplicationArea = All; }
                    field(ParentCapacity; Rec."Parent Unit Capacity") { ApplicationArea = All; }
                    field(MinFillPercent; Rec."Min Fill Percent") { ApplicationArea = All; }
                    field(TotalWeight; Rec."Total Weight") { ApplicationArea = All; Caption = 'Total Weight'; }
                    field(ExpectedReceiptDate; Rec."Expected Receipt Date") { ApplicationArea = All; Caption = 'Expected Receipt'; }
                    field(ReleaseDate; Rec."Release Date") { ApplicationArea = All; }
                    field(RequiredDate; Rec."Required Date") { ApplicationArea = All; }
                    field(Description; Rec.Description) { ApplicationArea = All; }
                }
            }
            group(Lines)
            {
                Caption = 'Lines';
                part(BatchLines; "WLM Load Batch Lines")
                {
                    ApplicationArea = All;
                    SubPageLink = "Load Group ID" = field("Load Group ID");
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ReleaseBatch)
            {
                Caption = 'Mark Batch Released';
                ApplicationArea = All;
                Image = Confirm;
                ToolTip = 'Marks the selected batch and all of its lines as released after carrying out documents.';
                trigger OnAction()
                var
                    Mgt: Codeunit "WLM LoadSuggestionMgt";
                    Sel: Record "WLM Load Batch";
                begin
                    CurrPage.SetSelectionFilter(Sel);
                    if Sel.IsEmpty() then
                        Sel.Get(Rec."Load Group ID");

                    if Sel.FindSet() then
                        repeat
                            Mgt.ReleaseBatch(Sel);
                        until Sel.Next() = 0;

                    CurrPage.Update(false);
                end;
            }
            action(SkipBatch)
            {
                Caption = 'Mark Batch Skipped';
                ApplicationArea = All;
                Image = Cancel;
                ToolTip = 'Marks the selected batch and all lines as skipped so they no longer appear open.';
                trigger OnAction()
                var
                    Mgt: Codeunit "WLM LoadSuggestionMgt";
                    Sel: Record "WLM Load Batch";
                begin
                    CurrPage.SetSelectionFilter(Sel);
                    if Sel.IsEmpty() then
                        Sel.Get(Rec."Load Group ID");

                    if Sel.FindSet() then
                        repeat
                            Mgt.SkipBatch(Sel);
                        until Sel.Next() = 0;

                    CurrPage.Update(false);
                end;
            }
            action(PromoteToPlanningLines)
            {
                Caption = 'Promote to Planning Lines';
                ApplicationArea = All;
                Image = TransferOrder;
                ToolTip = 'Creates Purchase Orders or Transfer Orders for batches with Released status. Documents will include expected receipt date, shipping method, vendor, and line details.';
                trigger OnAction()
                var
                    Mgt: Codeunit "WLM LoadSuggestionMgt";
                    Sel: Record "WLM Load Batch";
                    CreatedCount: Integer;
                begin
                    CurrPage.SetSelectionFilter(Sel);
                    if Sel.IsEmpty() then
                        Sel.Get(Rec."Load Group ID");

                    Sel.SetRange(Status, Sel.Status::Released);
                    if Sel.IsEmpty() then begin
                        Message('No released batches selected. Please mark batches as Released before promoting.');
                        exit;
                    end;

                    CreatedCount := Mgt.PromoteBatchesToDocuments(Sel);
                    Message('%1 document(s) created successfully.', CreatedCount);
                    CurrPage.Update(false);
                end;
            }
        }
    }
}

page 89702 "WLM Load Batch Card"
{
    PageType = Card;
    SourceTable = "WLM Load Batch";
    Caption = 'WLM Load Batch';
    ApplicationArea = All;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(BatchPriority; Rec."Batch Priority") { ApplicationArea = All; Caption = 'Priority'; Editable = false; }
                field(BatchNo; Rec."Batch No.") { ApplicationArea = All; Editable = false; }
                field(ProfileCode; Rec."Profile Code") { ApplicationArea = All; }
                field(RequirementPeriod; Rec."Requirement Period") { ApplicationArea = All; Caption = 'Requirement Period'; Editable = false; }
                field(SuggestionType; Rec."Suggestion Type") { ApplicationArea = All; Editable = false; }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field(MixedSKUCount; Rec."Mixed SKU Count") { ApplicationArea = All; Caption = 'SKU Count'; }
                field(TotalUnits; Rec."Total Units") { ApplicationArea = All; Caption = 'Total Units'; }
                field(LoadFillPercent; Rec."Load Fill Percent") { ApplicationArea = All; Caption = 'Fill %'; }
                field(SourceLocation; Rec."Source Location Code") { ApplicationArea = All; }
                field(DestinationLocation; Rec."Destination Location Code") { ApplicationArea = All; }
                field(VendorNo; Rec."Vendor No.") { ApplicationArea = All; }
                field(ShippingMethod; Rec."Shipping Method Code") { ApplicationArea = All; }
                field(ParentLoadUnit; Rec."Parent Load Unit Code") { ApplicationArea = All; }
                field(ParentUnitCapacity; Rec."Parent Unit Capacity") { ApplicationArea = All; }
                field(MinFillPercent; Rec."Min Fill Percent") { ApplicationArea = All; }
                field(TotalWeight; Rec."Total Weight") { ApplicationArea = All; Caption = 'Total Weight'; }
                field(ExpectedReceiptDate; Rec."Expected Receipt Date") { ApplicationArea = All; Caption = 'Expected Receipt Date'; }
                field(ReleaseDate; Rec."Release Date") { ApplicationArea = All; }
                field(RequiredDate; Rec."Required Date") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
            }
            part(BatchLines; "WLM Load Batch Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Load Group ID" = field("Load Group ID");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ReleaseBatch)
            {
                Caption = 'Mark Released';
                ApplicationArea = All;
                Image = Confirm;
                ToolTip = 'Marks this batch and its lines as released once documents are created.';
                trigger OnAction()
                var
                    Mgt: Codeunit "WLM LoadSuggestionMgt";
                begin
                    Mgt.ReleaseBatch(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(SkipBatch)
            {
                Caption = 'Mark Skipped';
                ApplicationArea = All;
                Image = Cancel;
                ToolTip = 'Marks this batch and its lines as skipped so they no longer show as open.';
                trigger OnAction()
                var
                    Mgt: Codeunit "WLM LoadSuggestionMgt";
                begin
                    Mgt.SkipBatch(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
    }
}

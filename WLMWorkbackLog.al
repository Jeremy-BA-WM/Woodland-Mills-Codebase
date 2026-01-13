table 89690 "WLM Workback Log"
{
    Caption = 'WLM Workback Log';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; "Item No."; Code[20]) { Caption = 'Item No.'; DataClassification = CustomerContent; }
        field(3; "Country/Region Code"; Code[10]) { Caption = 'Country/Region Code'; DataClassification = CustomerContent; }
        field(4; "Month No"; Integer) { Caption = 'Month No'; DataClassification = CustomerContent; }
        field(5; Reason; Text[250]) { Caption = 'Reason'; DataClassification = SystemMetadata; }
        field(6; "Created At"; DateTime) { Caption = 'Created At'; DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }

    trigger OnInsert()
    begin
        if "Created At" = 0DT then
            "Created At" := CurrentDateTime;
    end;
}

page 89698 "WLM Workback Log"
{
    PageType = List;
    SourceTable = "WLM Workback Log";
    ApplicationArea = All;
    Caption = 'WLM Workback Log';
    Editable = false;
    UsageCategory = ReportsAndAnalysis;

    layout
    {
        area(content)
        {
            repeater(Rep)
            {
                field(EntryNo; Rec."Entry No.") { ApplicationArea = All; }
                field(ItemNo; Rec."Item No.") { ApplicationArea = All; }
                field(Country; Rec."Country/Region Code") { ApplicationArea = All; }
                field(MonthNo; Rec."Month No") { ApplicationArea = All; }
                field(Reason; Rec.Reason) { ApplicationArea = All; }
                field(CreatedAt; Rec."Created At") { ApplicationArea = All; }
            }
        }
    }
}

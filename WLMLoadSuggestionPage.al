page 89697 "WLM Load Batch Lines"
{
    Caption = 'WLM Load Batch Lines';
    PageType = ListPart;
    SourceTable = "WLM Load Suggestion";
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(EntryNo; Rec."Entry No.") { ApplicationArea = All; Editable = false; }
                field(UrgencyLevel; Rec."Urgency Level") { ApplicationArea = All; Caption = 'Urgency'; Editable = false; StyleExpr = UrgencyStyle; }
                field(ItemNo; Rec."Item No.") { ApplicationArea = All; }
                field(LocationCode; Rec."Location Code") { ApplicationArea = All; }
                field(RequiredDate; Rec."Required Date") { ApplicationArea = All; }
                field(RequirementPeriod; Rec."Requirement Period") { ApplicationArea = All; Caption = 'Req. Period'; Editable = false; }
                field(StockoutQty; Rec."Stockout Qty") { ApplicationArea = All; Caption = 'Stockout Qty'; Editable = false; StyleExpr = UrgencyStyle; }
                field(ParRebuildQty; Rec."Par Rebuild Qty") { ApplicationArea = All; Caption = 'Par Rebuild Qty'; Editable = false; }
                field(MonthPriorityRank; Rec."Month Priority Rank") { ApplicationArea = All; Caption = 'Month Priority'; Editable = false; }
                field(DaysUntilRequired; Rec."Days Until Required") { ApplicationArea = All; Caption = 'Days Until Req.'; Editable = false; }
                field(ShortageDate; Rec."Shortage Date") { ApplicationArea = All; Editable = false; }
                field(LoadUnitCode; Rec."Load Unit Code") { ApplicationArea = All; }
                field(SubUnits; Rec."Sub Units") { ApplicationArea = All; }
                field(ParentUnits; Rec."Parent Units") { ApplicationArea = All; }
                field(PctOfParentUnit; Rec."Pct of Parent Unit") { ApplicationArea = All; Caption = '% of Parent'; Editable = false; }
                field(UnitsPerSubUnit; Rec."Units per Sub Unit") { ApplicationArea = All; Caption = 'Units/Sub'; }
                field(BaseUnits; CalcBaseUnits) { ApplicationArea = All; Caption = 'Base Units'; Editable = false; }
                field(BaseQtyRequired; Rec."Base Qty Required") { ApplicationArea = All; Caption = 'Base Qty Req.'; Editable = false; }
                field(PriorityScore; Rec."Priority Score") { ApplicationArea = All; Editable = false; }
                field(SuggestionType; Rec."Suggestion Type") { ApplicationArea = All; Editable = false; }
                field(SourceLocation; Rec."Source Location Code") { ApplicationArea = All; Editable = false; }
                field(SourceVendor; Rec."Source Vendor No.") { ApplicationArea = All; Editable = false; }
                field(ReleaseDate; Rec."Release Date") { ApplicationArea = All; Editable = false; }
                field(LoadGroupId; Rec."Load Group ID") { ApplicationArea = All; Editable = false; }
                field(LoadBatchNo; Rec."Load Batch No.") { ApplicationArea = All; Editable = false; }
                field(LoadProfileCode; Rec."Load Profile Code") { ApplicationArea = All; Editable = false; }
                field(ProposedDocument; Rec."Proposed Document No.") { ApplicationArea = All; Editable = false; }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field(CreatedAt; Rec."Created At") { ApplicationArea = All; Editable = false; }
                field(CreatedBy; Rec."Created By") { ApplicationArea = All; Editable = false; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ExportToExcel)
            {
                Caption = 'Export All Lines to Excel';
                ApplicationArea = All;
                Image = ExportToExcel;
                ToolTip = 'Export all load batch lines to Excel for auditing and comparison with WLM Planning Schedule.';
                trigger OnAction()
                var
                    LoadSuggestion: Record "WLM Load Suggestion";
                begin
                    LoadSuggestion.Reset();
                    Report.Run(Report::"WLM Load Suggestion Export", true, false, LoadSuggestion);
                end;
            }
        }
    }

    var
        CalcBaseUnits: Decimal;
        UrgencyStyle: Text;

    trigger OnAfterGetRecord()
    begin
        CalcBaseUnits := Rec."Sub Units" * Rec."Units per Sub Unit";

        // Set style based on urgency level
        case Rec."Urgency Level" of
            Rec."Urgency Level"::Stockout:
                UrgencyStyle := 'Unfavorable';  // Red - critical
            Rec."Urgency Level"::BelowROP:
                UrgencyStyle := 'Ambiguous';    // Yellow - important
            Rec."Urgency Level"::ParStock:
                UrgencyStyle := 'Favorable';    // Green - secondary
        end;
    end;
}

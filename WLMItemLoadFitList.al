page 89705 "WLM Item Load Fit List"
{
    Caption = 'Item Load Fits';
    PageType = List;
    SourceTable = "WLM Item Load Fit";
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Rep)
            {
                field(ParentLoadUnitCode; Rec."Parent Load Unit Code") { ApplicationArea = All; Caption = 'Parent Load Unit'; }
                field(ChildLoadUnitCode; Rec."Child Load Unit Code") { ApplicationArea = All; Caption = 'Child Load Unit'; }
                field(ItemNo; Rec."Item No.") { ApplicationArea = All; Caption = 'Item No.'; }
                field(UnitsPerParent; Rec."Units Per Parent") { ApplicationArea = All; Caption = 'Units/Parent'; }
                field(UnitsPerLane; Rec."Units Per Lane") { ApplicationArea = All; Caption = 'Units/Lane'; }
                field(LaneCount; Rec."Lane Count") { ApplicationArea = All; Caption = 'No. of Lanes'; }
                field(UnitsPerRow; Rec."Units per Row") { ApplicationArea = All; Caption = 'Units/Row'; }
                field(NumberOfRows; Rec."No. of Rows") { ApplicationArea = All; Caption = 'No. of Rows'; }
                field(HeightSlots; Rec."Height Slots") { ApplicationArea = All; Caption = 'Units/Stack'; }
                field(EnforceOrderMultiples; Rec."Enforce Order Multiples") { ApplicationArea = All; Caption = 'Enforce Order Multiples'; }
                field(OrderMultiple; Rec."Order Multiple") { ApplicationArea = All; Caption = 'Order Multiple'; }
                field(LaneWidth; Rec."Lane Width") { ApplicationArea = All; Caption = 'Lane Width'; }
                field(WidthPct; Rec."Width % Consumed") { ApplicationArea = All; Caption = 'Width %'; }
                field(LengthPct; Rec."Length % Consumed") { ApplicationArea = All; Caption = 'Length %'; }
                field(HeightPct; Rec."Height % Consumed") { ApplicationArea = All; Caption = 'Height %'; }
                field(VolumePct; Rec."Volume % Consumed") { ApplicationArea = All; Caption = 'Volume %'; }
                field(TotalWeight; Rec."Total Weight") { ApplicationArea = All; Caption = 'Total Weight'; }
                field(ComputedOn; Rec."Computed On") { ApplicationArea = All; Caption = 'Computed On'; Editable = false; }
                field(ComputedBy; Rec."Computed By") { ApplicationArea = All; Caption = 'Computed By'; Editable = false; }
            }
        }
    }
}
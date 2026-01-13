codeunit 89699 "WLM Item Load Fit Mgt"
{
    SingleInstance = true;

    procedure GetFit(ParentLoadUnitCode: Code[10]; ItemNo: Code[20]; var Fit: Record "WLM Item Load Fit"): Boolean
    var
        ItemLoad: Record "WLM Item Loading Unit";
        ChildLoadUnitCode: Code[10];
    begin
        if (ParentLoadUnitCode = '') or (ItemNo = '') then
            exit(false);

        Fit.Reset();
        Fit.SetRange("Parent Load Unit Code", ParentLoadUnitCode);
        Fit.SetRange("Item No.", ItemNo);

        if ItemLoad.Get(ItemNo) then begin
            ChildLoadUnitCode := ItemLoad."Default Loading Unit";
            if ChildLoadUnitCode <> '' then begin
                Fit.SetRange("Child Load Unit Code", ChildLoadUnitCode);
                if Fit.FindFirst() then
                    exit(true);
                Fit.SetRange("Child Load Unit Code");
            end;
        end;

        exit(Fit.FindFirst());
    end;

    procedure ComputeAndStoreFit(ParentLoadUnitCode: Code[10]; ItemNo: Code[20]): Boolean
    var
        ParentUnit: Record "WLM Order Loading Unit";
        ItemLoad: Record "WLM Item Loading Unit";
        Fit: Record "WLM Item Load Fit";
        UnitsPerParent: Decimal;
        UnitsPerLane: Decimal;
        LaneCount: Integer;
        HeightSlots: Integer;
        UsedRotation: Boolean;
        LaneWidth: Decimal;
        WidthPct: Decimal;
        LengthPct: Decimal;
        HeightPct: Decimal;
        VolumePct: Decimal;
        TotalWeight: Decimal;
        ChildLoadUnitCode: Code[10];
        ChildUnit: Record "WLM Order Loading Unit";
        AllowRotationInParent: Boolean;
        UnitsPerRow: Integer;
        NumberOfRows: Integer;
        PackLength: Decimal;
        PackWidth: Decimal;
        PackHeight: Decimal;
        PackWeight: Decimal;
        UnitsPerSubUnit: Integer;
        SubUnitsPerParent: Decimal;
        UnitsPerRowSub: Integer;
        EnforceOrderMultiples: Boolean;
        OrderMultiple: Integer;
    begin
        if (ParentLoadUnitCode = '') or (ItemNo = '') then
            exit(false);
        if not ParentUnit.Get(ParentLoadUnitCode) then
            exit(false);
        if not ItemLoad.Get(ItemNo) then
            exit(false);

        ChildLoadUnitCode := ItemLoad."Default Loading Unit";
        AllowRotationInParent := ItemLoad.CanRotate;
        if (ChildLoadUnitCode <> '') and ChildUnit.Get(ChildLoadUnitCode) then
            AllowRotationInParent := AllowRotationInParent and ChildUnit."Allow Rotation as Sub Unit";

        PackLength := ItemLoad."Unit Length";
        PackWidth := ItemLoad."Unit Width";
        PackHeight := ItemLoad."Unit Height";
        PackWeight := ItemLoad."Unit Weight";
        UnitsPerSubUnit := ItemLoad."Units per Sub Unit";
        if UnitsPerSubUnit <= 0 then
            UnitsPerSubUnit := 1;

        if (ChildLoadUnitCode <> '') and ChildUnit.Get(ChildLoadUnitCode) then begin
            PackLength := ChildUnit.InteriorLength;
            PackWidth := ChildUnit.InteriorWidth;
            PackHeight := ChildUnit.InteriorHeight;
            // Weight could be refined to include packaging; use piece weight as baseline.
        end;

        if not Fit.Get(ParentLoadUnitCode, ItemNo) then begin
            Fit.Init();
            Fit."Aisle Width" := 0;
            Fit."Rows Lost" := 0;
        end;

        if not DetermineBestFit(
            ParentUnit,
            Fit."Aisle Width",
            Fit."Rows Lost",
            UnitsPerParent,
            UnitsPerLane,
            LaneCount,
            HeightSlots,
            UsedRotation,
            LaneWidth,
            WidthPct,
            LengthPct,
            HeightPct,
            VolumePct,
            TotalWeight,
            AllowRotationInParent,
            PackLength,
            PackWidth,
            PackHeight,
            PackWeight,
            ItemLoad.CanStack) then
            exit(false);

        SubUnitsPerParent := UnitsPerParent;
        UnitsPerParent := SubUnitsPerParent * UnitsPerSubUnit;
        UnitsPerLane := UnitsPerLane * UnitsPerSubUnit;
        UnitsPerRowSub := LaneCount * HeightSlots;
        if UnitsPerRowSub <> 0 then begin
            UnitsPerRow := UnitsPerRowSub * UnitsPerSubUnit;
            NumberOfRows := Round(UnitsPerParent / UnitsPerRow, 1, '<');
        end else begin
            UnitsPerRow := 0;
            NumberOfRows := 0;
        end;
        TotalWeight := UnitsPerParent * ItemLoad."Unit Weight";

        if ChildLoadUnitCode = '' then begin
            // "Self" items (no sub-unit): enforce row-based order multiples for efficient packing
            EnforceOrderMultiples := true;
            OrderMultiple := UnitsPerRow;
        end else begin
            // Items with sub-units (CRATE): don't enforce row multiples
            // These items are packed in crates which can be mixed flexibly
            EnforceOrderMultiples := false;
            OrderMultiple := 0;
        end;

        if Fit.Get(ParentLoadUnitCode, ItemNo) then begin
            Fit.Validate("Child Load Unit Code", ChildLoadUnitCode);
            Fit.Validate("Units Per Parent", UnitsPerParent);
            Fit.Validate("Units Per Lane", UnitsPerLane);
            Fit.Validate("Lane Count", LaneCount);
            Fit.Validate("Height Slots", HeightSlots);
            Fit.Validate("Used Rotation", UsedRotation);
            Fit.Validate("Lane Width", LaneWidth);
            Fit.Validate("Width % Consumed", WidthPct);
            Fit.Validate("Length % Consumed", LengthPct);
            Fit.Validate("Height % Consumed", HeightPct);
            Fit.Validate("Volume % Consumed", VolumePct);
            Fit.Validate("Total Weight", TotalWeight);
            Fit.Validate("Units per Row", UnitsPerRow);
            Fit.Validate("No. of Rows", NumberOfRows);
            Fit.Validate("Enforce Order Multiples", EnforceOrderMultiples);
            Fit.Validate("Order Multiple", OrderMultiple);
            Fit."Computed On" := CurrentDateTime;
            Fit."Computed By" := CopyStr(UserId, 1, MaxStrLen(Fit."Computed By"));
            Fit.Modify(true);
        end else begin
            Fit.Init();
            Fit.Validate("Parent Load Unit Code", ParentLoadUnitCode);
            Fit.Validate("Item No.", ItemNo);
            Fit.Validate("Child Load Unit Code", ChildLoadUnitCode);
            Fit."Aisle Width" := 0;
            Fit."Rows Lost" := 0;
            Fit.Validate("Units Per Parent", UnitsPerParent);
            Fit.Validate("Units Per Lane", UnitsPerLane);
            Fit.Validate("Lane Count", LaneCount);
            Fit.Validate("Height Slots", HeightSlots);
            Fit.Validate("Used Rotation", UsedRotation);
            Fit.Validate("Lane Width", LaneWidth);
            Fit.Validate("Width % Consumed", WidthPct);
            Fit.Validate("Length % Consumed", LengthPct);
            Fit.Validate("Height % Consumed", HeightPct);
            Fit.Validate("Volume % Consumed", VolumePct);
            Fit.Validate("Total Weight", TotalWeight);
            Fit.Validate("Units per Row", UnitsPerRow);
            Fit.Validate("No. of Rows", NumberOfRows);
            Fit.Validate("Enforce Order Multiples", EnforceOrderMultiples);
            Fit.Validate("Order Multiple", OrderMultiple);
            Fit."Computed On" := CurrentDateTime;
            Fit."Computed By" := CopyStr(UserId, 1, MaxStrLen(Fit."Computed By"));
            Fit.Insert(true);
        end;
        exit(true);
    end;

    procedure RecomputeForItem(ItemNo: Code[20])
    var
        ParentUnit: Record "WLM Order Loading Unit";
    begin
        if ItemNo = '' then
            exit;
        ParentUnit.Reset();
        if ParentUnit.FindSet() then
            repeat
                ComputeAndStoreFit(ParentUnit.Code, ItemNo);
            until ParentUnit.Next() = 0;
    end;

    procedure RecomputeAllItems()
    var
        ItemLoad: Record "WLM Item Loading Unit";
    begin
        ItemLoad.Reset();
        if ItemLoad.FindSet() then
            repeat
                RecomputeForItem(ItemLoad."Item No.");
            until ItemLoad.Next() = 0;
    end;

    local procedure DetermineBestFit(ParentUnit: Record "WLM Order Loading Unit";
                                     AisleWidth: Decimal;
                                     RowsLost: Integer;
                                     var UnitsPerParent: Decimal;
                                     var UnitsPerLane: Decimal;
                                     var LaneCount: Integer;
                                     var HeightSlots: Integer;
                                     var UsedRotation: Boolean;
                                     var LaneWidth: Decimal;
                                     var WidthPct: Decimal;
                                     var LengthPct: Decimal;
                                     var HeightPct: Decimal;
                                     var VolumePct: Decimal;
                                     var TotalWeight: Decimal;
                                     AllowRotationInParent: Boolean;
                                     ItemLength: Decimal;
                                     ItemWidth: Decimal;
                                     ItemHeight: Decimal;
                                     ItemWeight: Decimal;
                                     AllowStack: Boolean): Boolean
    var
        OptionUnitsPerParent: Decimal;
        OptionUnitsPerLane: Decimal;
        OptionLaneCount: Integer;
        OptionHeightSlots: Integer;
        OptionRotation: Boolean;
        OptionLaneWidth: Decimal;
        BestUnits: Decimal;
        OptionWidthPct: Decimal;
        OptionLengthPct: Decimal;
        OptionHeightPct: Decimal;
        OptionVolumePct: Decimal;
        OptionTotalWeight: Decimal;
    begin
        UnitsPerParent := 0;
        UnitsPerLane := 0;
        LaneCount := 0;
        HeightSlots := 0;
        UsedRotation := false;
        LaneWidth := 0;
        WidthPct := 0;
        LengthPct := 0;
        HeightPct := 0;
        VolumePct := 0;
        TotalWeight := 0;
        BestUnits := 0;

        EvaluateOrientation(ParentUnit, ItemLength, ItemWidth, ItemHeight, AllowStack, false,
            OptionUnitsPerParent, OptionUnitsPerLane, OptionLaneCount, OptionHeightSlots, OptionLaneWidth,
            OptionWidthPct, OptionLengthPct, OptionHeightPct, OptionVolumePct, OptionTotalWeight,
            AisleWidth, RowsLost, ItemWeight);
        if OptionUnitsPerParent > BestUnits then begin
            BestUnits := OptionUnitsPerParent;
            UnitsPerParent := OptionUnitsPerParent;
            UnitsPerLane := OptionUnitsPerLane;
            LaneCount := OptionLaneCount;
            HeightSlots := OptionHeightSlots;
            UsedRotation := false;
            LaneWidth := OptionLaneWidth;
            WidthPct := OptionWidthPct;
            LengthPct := OptionLengthPct;
            HeightPct := OptionHeightPct;
            VolumePct := OptionVolumePct;
            TotalWeight := OptionTotalWeight;
        end;

        if AllowRotationInParent then begin
            EvaluateOrientation(ParentUnit, ItemWidth, ItemLength, ItemHeight, AllowStack, true,
                OptionUnitsPerParent, OptionUnitsPerLane, OptionLaneCount, OptionHeightSlots, OptionLaneWidth,
                OptionWidthPct, OptionLengthPct, OptionHeightPct, OptionVolumePct, OptionTotalWeight,
                AisleWidth, RowsLost, ItemWeight);
            if OptionUnitsPerParent > BestUnits then begin
                BestUnits := OptionUnitsPerParent;
                UnitsPerParent := OptionUnitsPerParent;
                UnitsPerLane := OptionUnitsPerLane;
                LaneCount := OptionLaneCount;
                HeightSlots := OptionHeightSlots;
                UsedRotation := true;
                LaneWidth := OptionLaneWidth;
                WidthPct := OptionWidthPct;
                LengthPct := OptionLengthPct;
                HeightPct := OptionHeightPct;
                VolumePct := OptionVolumePct;
                TotalWeight := OptionTotalWeight;
            end;
        end;

        exit(BestUnits > 0);
    end;

    local procedure EvaluateOrientation(ParentUnit: Record "WLM Order Loading Unit";
                                        ItemLength: Decimal; ItemWidth: Decimal; ItemHeight: Decimal; AllowStack: Boolean; Rotated: Boolean;
                                        var UnitsPerParent: Decimal; var UnitsPerLane: Decimal; var LaneCount: Integer; var HeightSlots: Integer; var LaneWidth: Decimal;
                                        var WidthPct: Decimal; var LengthPct: Decimal; var HeightPct: Decimal; var VolumePct: Decimal; var TotalWeight: Decimal;
                                        AisleWidth: Decimal; RowsLost: Integer; UnitWeight: Decimal)
    var
        AlongLength: Decimal;
        AlongWidth: Decimal;
        HeightFit: Decimal;
        EffectiveLength: Decimal;
        ItemVolume: Decimal;
        ParentVolume: Decimal;
        WidthUsed: Decimal;
        LengthUsed: Decimal;
    begin
        UnitsPerParent := 0;
        UnitsPerLane := 0;
        LaneCount := 0;
        HeightSlots := 0;
        LaneWidth := 0;
        WidthPct := 0;
        LengthPct := 0;
        HeightPct := 0;
        VolumePct := 0;
        TotalWeight := 0;

        if (ParentUnit.InteriorLength <= 0) or (ParentUnit.InteriorWidth <= 0) or (ParentUnit.InteriorHeight <= 0) then
            exit;
        if (ItemLength <= 0) or (ItemWidth <= 0) or (ItemHeight <= 0) then
            exit;

        if AisleWidth < 0 then
            AisleWidth := 0;
        if RowsLost < 0 then
            RowsLost := 0;

        EffectiveLength := ParentUnit.InteriorLength - AisleWidth;
        AlongLength := ROUND(EffectiveLength / ItemLength, 1, '<');
        if RowsLost > 0 then
            AlongLength -= RowsLost;
        AlongWidth := ROUND(ParentUnit.InteriorWidth / ItemWidth, 1, '<');
        HeightFit := ROUND(ParentUnit.InteriorHeight / ItemHeight, 1, '<');

        if not AllowStack then begin
            if HeightFit >= 1 then
                HeightFit := 1
            else
                exit;
        end;

        if (AlongLength <= 0) or (AlongWidth <= 0) or (HeightFit <= 0) then
            exit;

        LaneWidth := ItemWidth;
        UnitsPerLane := AlongLength * HeightFit;
        LaneCount := AlongWidth;
        HeightSlots := HeightFit;
        UnitsPerParent := LaneCount * UnitsPerLane;

        // Consumed metrics
        WidthUsed := LaneCount * ItemWidth;
        LengthUsed := (AlongLength * ItemLength) + AisleWidth + (RowsLost * ItemLength);
        if ParentUnit.InteriorWidth > 0 then
            WidthPct := ROUND((WidthUsed / ParentUnit.InteriorWidth) * 100, 0.1, '>');
        if ParentUnit.InteriorLength > 0 then
            LengthPct := ROUND((LengthUsed / ParentUnit.InteriorLength) * 100, 0.1, '>');
        if ParentUnit.InteriorHeight > 0 then
            HeightPct := ROUND(((HeightFit * ItemHeight) / ParentUnit.InteriorHeight) * 100, 0.1, '>');

        ItemVolume := ItemLength * ItemWidth * ItemHeight;
        ParentVolume := ParentUnit.InteriorLength * ParentUnit.InteriorWidth * ParentUnit.InteriorHeight;
        if ParentVolume > 0 then
            VolumePct := ROUND(((UnitsPerParent * ItemVolume) / ParentVolume) * 100, 0.1, '>');

        TotalWeight := UnitsPerParent * UnitWeight;
    end;
}

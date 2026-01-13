page 89721 "WLM Planning Schedule"
{
    PageType = List;
    SourceTable = "WLM FcstBuffer";
    SourceTableTemporary = true;
    Caption = 'WLM Planning Schedule';
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(Filters)
            {
                Caption = 'Date Filters';
                field(FromDate; FromDate)
                {
                    ApplicationArea = All;
                    Caption = 'From Date';
                    ToolTip = 'Start date for calculating requirements.';
                    trigger OnValidate()
                    begin
                        RebuildSchedule();
                    end;
                }
                field(ToDate; ToDate)
                {
                    ApplicationArea = All;
                    Caption = 'To Date';
                    ToolTip = 'End date for calculating requirements.';
                    trigger OnValidate()
                    begin
                        RebuildSchedule();
                    end;
                }
            }

            repeater(Schedule)
            {
                field(ItemNo; Rec."Item No.") { ApplicationArea = All; Caption = 'Item No.'; }
                field(Description; Rec.Description) { ApplicationArea = All; Caption = 'Description'; Editable = false; }
                field(ItemCategory; Rec."Item Category Code") { ApplicationArea = All; Caption = 'Item Category'; Editable = false; }
                field(VendorNo; Rec."Vendor No.") { ApplicationArea = All; Caption = 'Vendor'; Editable = false; }
                field(GD1; Rec."Global Dimension 1 Code") { ApplicationArea = All; Caption = 'Global Dimension 1'; Editable = false; }
                field(GD2; Rec."Global Dimension 2 Code") { ApplicationArea = All; Caption = 'Global Dimension 2'; Editable = false; }
                field(SD3; Rec."Shortcut Dimension 3 Value") { ApplicationArea = All; Caption = 'Shortcut Dimension 3'; Editable = false; }
                field(SD4; Rec."Shortcut Dimension 4 Value") { ApplicationArea = All; Caption = 'Shortcut Dimension 4'; Editable = false; }
                field(SD5; Rec."Shortcut Dimension 5 Value") { ApplicationArea = All; Caption = 'Shortcut Dimension 5'; Editable = false; }
                field(SD6; Rec."Shortcut Dimension 6 Value") { ApplicationArea = All; Caption = 'Shortcut Dimension 6'; Editable = false; }
                field(SD7; Rec."Shortcut Dimension 7 Value") { ApplicationArea = All; Caption = 'Shortcut Dimension 7'; Editable = false; }
                field(SD8; Rec."Shortcut Dimension 8 Value") { ApplicationArea = All; Caption = 'Shortcut Dimension 8'; Editable = false; }
                field(LocationCode; Rec."Location Code") { ApplicationArea = All; Caption = 'Location'; Editable = false; }
                field(BucketDate; Rec."Bucket Date") { ApplicationArea = All; Caption = 'Required On'; Editable = false; }
                field(OnHand; Rec."On Hand Qty") { ApplicationArea = All; Caption = 'On Hand'; Editable = false; }
                field(Inbound; Rec."Inbound Arrivals") { ApplicationArea = All; Caption = 'Inbound Arrivals'; Editable = false; }
                field(InboundPurch; Rec."Inbound Arrival - Purchase") { ApplicationArea = All; Caption = 'Inbound Arrival - Purchase'; Editable = false; }
                field(InboundTransfer; Rec."Inbound Arrival - Transfer") { ApplicationArea = All; Caption = 'Inbound Arrival - Transfer'; Editable = false; }
                field(Reserved; Rec."Reserved Qty") { ApplicationArea = All; Caption = 'Open Sales Demand'; Editable = false; }
                field(OpenTransfer; Rec."Open Transfer Demand") { ApplicationArea = All; Caption = 'Open Transfer Demand'; Editable = false; }
                field(ProjectedSales; Rec."Projected Sales") { ApplicationArea = All; Caption = 'Projected Sales'; Editable = false; }
                field(ReorderPoint; Rec."Reorder Point") { ApplicationArea = All; Caption = 'Reorder Point (Projected)'; Editable = false; }
                field(SKUReorderPoint; Rec."SKU Reorder Point") { ApplicationArea = All; Caption = 'Reorder Point (SKU)'; Editable = false; }
                field(ReorderPointMAX; Rec."Reorder Point MAX") { ApplicationArea = All; Caption = 'Reorder Point (MAX)'; Editable = false; }
                field(QtyRequired; Rec."Qty Required") { ApplicationArea = All; Caption = 'Qty Required'; Editable = false; }
                field(LastDirectCost; Rec."Last Direct Cost") { ApplicationArea = All; Caption = 'Last Direct Cost'; Editable = false; }
                field(ReqCostLast; Rec."Req. Cost (Last Direct)") { ApplicationArea = All; Caption = 'Req. Cost (Last Direct)'; Editable = false; }
                field(UnitCost; Rec."Unit Cost") { ApplicationArea = All; Caption = 'Unit Cost'; Editable = false; }
                field(ReqCostUnit; Rec."Req. Cost (Unit)") { ApplicationArea = All; Caption = 'Req. Cost (Unit)'; Editable = false; }
                field(Surplus; Rec.Surplus) { ApplicationArea = All; Caption = 'Surplus'; Editable = false; }
                field(EarliestReplenishment; Rec."Earliest Replenishment") { ApplicationArea = All; Caption = 'Earliest Replenishment'; Editable = false; }
                field(LoadingUnit; Rec."Loading Unit Type") { ApplicationArea = All; Caption = 'Loading Unit Type'; Editable = false; }
                field(PctSub; Rec."Pct of Sub Unit") { ApplicationArea = All; Caption = 'Required Sub-Loading Units'; Editable = false; }
                field(PctParent1; Rec."Pct of Parent Unit 1") { ApplicationArea = All; Caption = 'Required Parent Loading Unit 1'; Editable = false; }
                field(PctParent2; Rec."Pct of Parent Unit 2") { ApplicationArea = All; Caption = 'Required Parent Loading Unit 2'; Editable = false; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        InitDates();
        RebuildSchedule();
    end;

    local procedure InitDates()
    begin
        FromDate := WorkDate;
        if FromDate = 0D then
            FromDate := Today;
        ToDate := CalcDate('+3M', FromDate);
    end;

    local procedure ApplySetupHorizon()
    var
        Setup: Record "WLM FcstSetup";
        HorizonBuckets: Integer;
    begin
        if not Setup.Get('SETUP') then
            exit;

        HorizonBuckets := Setup."Resource Planning Buckets";
        if HorizonBuckets <= 0 then
            exit;

        FromDate := WorkDate;
        if FromDate = 0D then
            FromDate := Today;

        case Setup."Default Bucket" of
            Setup."Default Bucket"::Day:
                ToDate := FromDate + (HorizonBuckets - 1);
            Setup."Default Bucket"::Week:
                ToDate := FromDate + (HorizonBuckets * 7) - 1;
            Setup."Default Bucket"::Month:
                begin
                    ToDate := CalcDate(StrSubstNo('+%1M', HorizonBuckets - 1), FromDate);
                    ToDate := CalcDate('<CM+1D-1D>', ToDate);
                end;
        end;
    end;

    local procedure RebuildSchedule()
    var
        Setup: Record "WLM FcstSetup";
        FcstEntry: Record "WLM Forecast Entry";
    begin
        Rec.Reset();
        Rec.DeleteAll();

        if not Setup.Get('SETUP') then
            exit;

        FcstEntry.Reset();
        if Setup."Default Forecast Name" <> '' then
            FcstEntry.SetRange("Forecast Name", Setup."Default Forecast Name");

        if (FromDate <> 0D) or (ToDate <> 0D) then begin
            if (FromDate <> 0D) and (ToDate <> 0D) then
                FcstEntry.SetRange("Forecast Date", FromDate, ToDate)
            else if FromDate <> 0D then
                FcstEntry.SetFilter("Forecast Date", '>=%1', FromDate)
            else if ToDate <> 0D then
                FcstEntry.SetFilter("Forecast Date", '<=%1', ToDate);
        end;

        if FcstEntry.FindSet() then
            repeat
                SafeAddBucket(FcstEntry);
            until FcstEntry.Next() = 0;

        if Rec.FindSet() then
            repeat
                if SafeEnrichRow(Rec) then
                    Rec.Modify()
                else
                    Rec.Next();
            until Rec.Next() = 0;

        ComputeRunningAvailability();
    end;

    local procedure SafeAddBucket(var FcstEntry: Record "WLM Forecast Entry")
    var
        SafeLoc: Code[10];
    begin
        SafeLoc := NormalizeLocation(FcstEntry."Location Code");
        if Rec.Get(NormalizeItemNo(FcstEntry."Item No."), SafeLoc, FcstEntry."Forecast Date") then begin
            Rec."Base Qty" += FcstEntry.Quantity;
            Rec."Projected Sales" := Rec."Base Qty";
            Rec.Modify();
        end else begin
            Rec.Init();
            Rec."Item No." := NormalizeItemNo(FcstEntry."Item No.");
            Rec."Location Code" := SafeLoc;
            Rec."Bucket Date" := FcstEntry."Forecast Date";
            Rec."Base Qty" := FcstEntry.Quantity;
            Rec."Projected Sales" := FcstEntry.Quantity;
            Rec.Insert();
        end;
    end;

    [TryFunction]
    local procedure SafeEnrichRow(var Buffer: Record "WLM FcstBuffer")
    var
        ItemRec: Record Item;
        SKU: Record "Stockkeeping Unit";
        ItemLoad: Record "WLM Item Loading Unit";
        SafeLoc: Code[10];
        VariantCode: Code[10];
        Available: Decimal;
        AvailableSubUnits: Decimal;
        Remainder: Decimal;
        RequiredQty: Decimal;
        Parent1Code: Code[10];
        Parent2Code: Code[10];
        Parent1Units: Decimal;
        Parent2Units: Decimal;
        ItemReorder: Decimal;
        SKUReorder: Decimal;
        ParReorder: Decimal;
    begin
        // Always clamp codes to their defined lengths to avoid runtime overflow when source data is wider.
        SafeLoc := NormalizeLocation(Buffer."Location Code");
        Buffer."Item No." := NormalizeItemNo(Buffer."Item No.");
        Buffer."Location Code" := SafeLoc;

        if ItemRec.Get(Buffer."Item No.") then begin
            Buffer.Description := CopyStr(ItemRec.Description, 1, MaxStrLen(Buffer.Description));
            Buffer."Item Category Code" := CopyStr(ItemRec."Item Category Code", 1, MaxStrLen(Buffer."Item Category Code"));
            Buffer."Vendor No." := CopyStr(ItemRec."Vendor No.", 1, MaxStrLen(Buffer."Vendor No."));
            ItemReorder := ItemRec."Reorder Point";
            Buffer."Unit Cost" := ItemRec."Unit Cost";
            Buffer."Last Direct Cost" := ItemRec."Last Direct Cost";
        end else begin
            Buffer.Description := '';
            Buffer."Item Category Code" := '';
            Buffer."Vendor No." := '';
            ItemReorder := 0;
            Buffer."Unit Cost" := 0;
            Buffer."Last Direct Cost" := 0;
        end;

        VariantCode := '';
        // Stockkeeping Unit PK order is (Item No., Variant Code, Location Code)
        if SKU.Get(Buffer."Item No.", VariantCode, SafeLoc) then begin
            SKUReorder := SKU."Reorder Point";
            Buffer."SKU Reorder Point" := SKUReorder;
        end else begin
            // Fallback: allow any matching SKU for the item/location regardless of variant order
            SKU.Reset();
            SKU.SetRange("Item No.", Buffer."Item No.");
            SKU.SetRange("Location Code", SafeLoc);
            if SKU.FindFirst() then begin
                SKUReorder := SKU."Reorder Point";
                Buffer."SKU Reorder Point" := SKUReorder;
            end else begin
                SKUReorder := 0;
                Buffer."SKU Reorder Point" := 0;
            end;
        end;

        ParReorder := ComputeParReorderPoint(Buffer."Item No.", SafeLoc);

        // Store Reorder Point (Projected) - auto-calculated from forecast
        Buffer."Reorder Point" := ParReorder;

        // SKU Reorder Point already set above

        // Reorder Point (MAX) - higher of Projected vs SKU, used in calculations
        if ParReorder > SKUReorder then
            Buffer."Reorder Point MAX" := ParReorder
        else
            Buffer."Reorder Point MAX" := SKUReorder;

        Buffer."On Hand Qty" := CalcOnHand(Buffer."Item No.", SafeLoc);
        Buffer."Reserved Qty" := CalcOpenSales(Buffer."Item No.", SafeLoc, Buffer."Bucket Date");
        Buffer."Projected Sales" := Buffer."Base Qty";
        CalcInbound(Buffer."Item No.", SafeLoc, Buffer."Bucket Date", Buffer."Inbound Arrival - Purchase", Buffer."Inbound Arrival - Transfer");
        Buffer."Inbound Arrivals" := Buffer."Inbound Arrival - Purchase" + Buffer."Inbound Arrival - Transfer";
        Buffer."Open Transfer Demand" := CalcOpenTransfers(Buffer."Item No.", SafeLoc, Buffer."Bucket Date");
        Buffer.Surplus := 0;

        Available := Buffer."On Hand Qty" - Buffer."Reserved Qty" + Buffer."Inbound Arrivals";
        Buffer."Qty Required" := Buffer."Projected Sales" - Available;
        if Buffer."Qty Required" < 0 then
            Buffer."Qty Required" := 0;
        RequiredQty := Buffer."Qty Required";

        Buffer."Required On" := Buffer."Bucket Date";
        Buffer."Earliest Replenishment" := Buffer."Bucket Date";

        Buffer."Loading Unit Type" := '';
        Buffer."Pct of Sub Unit" := 0;
        Buffer."Pct of Parent Unit 1" := 0;
        Buffer."Pct of Parent Unit 2" := 0;
        if ItemLoad.Get(Buffer."Item No.") then begin
            Buffer."Loading Unit Type" := CopyStr(ItemLoad."Default Loading Unit", 1, MaxStrLen(Buffer."Loading Unit Type"));

            if (ItemLoad."Units per Sub Unit" > 0) and (RequiredQty > 0) then
                // Show required sub-units (unrounded): QtyRequired / UnitsPerSub
                Buffer."Pct of Sub Unit" := RequiredQty / ItemLoad."Units per Sub Unit"
            else
                Buffer."Pct of Sub Unit" := 0;
        end;

        Parent1Code := '';
        Parent2Code := '';
        Parent1Units := 0;
        Parent2Units := 0;
        ResolveTopParentFits(Buffer."Item No.", Parent1Code, Parent1Units, Parent2Code, Parent2Units);

        if (Parent1Units > 0) and (RequiredQty > 0) then
            Buffer."Pct of Parent Unit 1" := RequiredQty / Parent1Units
        else
            Buffer."Pct of Parent Unit 1" := 0;

        if (Parent2Units > 0) and (RequiredQty > 0) then
            Buffer."Pct of Parent Unit 2" := RequiredQty / Parent2Units
        else
            Buffer."Pct of Parent Unit 2" := 0;
    end;

    local procedure ComputeRunningAvailability()
    var
        CurrentItem: Code[20];
        CurrentLoc: Code[10];
        RunningAvail: Decimal;
        ItemLoad: Record "WLM Item Loading Unit";
        UnitsPerSub: Decimal;
        Remainder: Decimal;
        ReorderFloor: Decimal;
        DemandShortfall: Decimal;
        ReorderShortfall: Decimal;
        OpenSalesApplied: Decimal;
        TransferDemand: Decimal;
        DemandTotal: Decimal;
        IsFirstBucket: Boolean;
        InboundCumulative: Decimal;
        InboundThisBucket: Decimal;
        PrevInboundCumulative: Decimal;
        InboundPurchCumulative: Decimal;
        InboundTransferCumulative: Decimal;
        InboundPurchThisBucket: Decimal;
        InboundTransferThisBucket: Decimal;
        PrevInboundPurchCumulative: Decimal;
        PrevInboundTransferCumulative: Decimal;
        Parent1Code: Code[10];
        Parent2Code: Code[10];
        Parent1Units: Decimal;
        Parent2Units: Decimal;
        ProratedSales: Decimal;
        DaysInMonth: Integer;
        DaysRemaining: Integer;
        BucketMonth: Integer;
        BucketYear: Integer;
        TodayDate: Date;
    begin
        Rec.Reset();
        Rec.SetCurrentKey("Item No.", "Location Code", "Bucket Date");

        TodayDate := WorkDate();
        if TodayDate = 0D then
            TodayDate := Today;

        if Rec.FindSet() then
            repeat
                if (Rec."Item No." <> CurrentItem) or (Rec."Location Code" <> CurrentLoc) then begin
                    CurrentItem := Rec."Item No.";
                    CurrentLoc := Rec."Location Code";
                    RunningAvail := Rec."On Hand Qty";
                    IsFirstBucket := true;
                    PrevInboundCumulative := 0;
                    PrevInboundPurchCumulative := 0;
                    PrevInboundTransferCumulative := 0;
                end;

                // Compute incremental inbound from cumulative values (total, purchase, transfer)
                InboundCumulative := Rec."Inbound Arrivals";
                InboundPurchCumulative := Rec."Inbound Arrival - Purchase";
                InboundTransferCumulative := Rec."Inbound Arrival - Transfer";

                InboundThisBucket := InboundCumulative - PrevInboundCumulative;
                InboundPurchThisBucket := InboundPurchCumulative - PrevInboundPurchCumulative;
                InboundTransferThisBucket := InboundTransferCumulative - PrevInboundTransferCumulative;

                if InboundThisBucket < 0 then
                    InboundThisBucket := InboundCumulative; // safety fallback
                if InboundPurchThisBucket < 0 then
                    InboundPurchThisBucket := InboundPurchCumulative;
                if InboundTransferThisBucket < 0 then
                    InboundTransferThisBucket := InboundTransferCumulative;

                PrevInboundCumulative := InboundCumulative;
                PrevInboundPurchCumulative := InboundPurchCumulative;
                PrevInboundTransferCumulative := InboundTransferCumulative;

                // On Hand shows projected inventory BEFORE adding this period's inbound
                // (This is the position coming into the period after prior period's suggestion accepted)
                Rec."On Hand Qty" := RunningAvail;

                // Add inbound to running availability for calculations
                RunningAvail += InboundThisBucket;
                if RunningAvail < 0 then
                    RunningAvail := 0;

                // Display the incremental inbound for this bucket (separate from On Hand)
                Rec."Inbound Arrivals" := InboundThisBucket;
                Rec."Inbound Arrival - Purchase" := InboundPurchThisBucket;
                Rec."Inbound Arrival - Transfer" := InboundTransferThisBucket;

                DemandShortfall := 0;
                ReorderShortfall := 0;

                // Open sales demand only on the first bucket per item/location (display and consumption)
                if IsFirstBucket then
                    OpenSalesApplied := Rec."Reserved Qty"
                else begin
                    OpenSalesApplied := 0;
                    Rec."Reserved Qty" := 0; // hide on later buckets
                end;

                // Issue #1: Prorate projected sales for current month based on days remaining
                ProratedSales := Rec."Projected Sales";
                if IsFirstBucket and (Rec."Bucket Date" <> 0D) then begin
                    BucketMonth := Date2DMY(Rec."Bucket Date", 2);
                    BucketYear := Date2DMY(Rec."Bucket Date", 3);
                    // Check if bucket is in the same month as today
                    if (Date2DMY(TodayDate, 2) = BucketMonth) and (Date2DMY(TodayDate, 3) = BucketYear) then begin
                        // Calculate days in this month and days remaining
                        DaysInMonth := Date2DMY(CalcDate('<CM>', Rec."Bucket Date"), 1);
                        DaysRemaining := DaysInMonth - Date2DMY(TodayDate, 1) + 1; // Include today
                        if (DaysInMonth > 0) and (DaysRemaining > 0) then
                            ProratedSales := Round(Rec."Projected Sales" * (DaysRemaining / DaysInMonth), 1);
                    end;
                end;

                TransferDemand := Rec."Open Transfer Demand";
                DemandTotal := ProratedSales + TransferDemand + OpenSalesApplied;

                // Store the prorated value back for display
                Rec."Projected Sales" := ProratedSales;

                // Consume demand from running availability
                if RunningAvail >= DemandTotal then begin
                    RunningAvail -= DemandTotal;
                end else begin
                    DemandShortfall := DemandTotal - RunningAvail;
                    RunningAvail := 0;
                end;

                // After first bucket processed, set flag false
                IsFirstBucket := false;

                // Use Reorder Point (MAX) - the higher of Projected vs SKU
                ReorderFloor := Rec."Reorder Point MAX";

                // Calculate reorder shortfall based on current running availability (after demand consumed)
                if RunningAvail < ReorderFloor then
                    ReorderShortfall := ReorderFloor - RunningAvail
                else
                    ReorderShortfall := 0;

                Rec."Qty Required" := DemandShortfall + ReorderShortfall;

                // Surplus = On Hand + Inbound - (Prorated Sales + Open Sales + Open Transfer + Reorder MAX)
                // On Hand is shown BEFORE inbound, so we add Inbound separately
                Rec.Surplus := Rec."On Hand Qty" + Rec."Inbound Arrivals" -
                    (Rec."Projected Sales" + Rec."Reserved Qty" + Rec."Open Transfer Demand" + ReorderFloor);

                // After calculating the requirement, set RunningAvail to the reorder point (par level)
                // This shows projected inventory IF suggestions are accepted - we'd be AT par, not above it
                // Example: If deficit=5, par=144, qty required=149, after receiving we should be at 144, not 149
                if Rec."Qty Required" > 0 then
                    RunningAvail := ReorderFloor
                else
                    RunningAvail := RunningAvail; // No suggestion needed, keep current balance

                // Compute cost extensions using the net required quantity
                Rec."Req. Cost (Unit)" := Rec."Qty Required" * Rec."Unit Cost";
                Rec."Req. Cost (Last Direct)" := Rec."Qty Required" * Rec."Last Direct Cost";

                Rec."Pct of Sub Unit" := 0;
                if ItemLoad.Get(CurrentItem) then begin
                    UnitsPerSub := ItemLoad."Units per Sub Unit";
                    if (UnitsPerSub > 0) and (Rec."Qty Required" > 0) then
                        // Show required sub-units (unrounded): QtyRequired / UnitsPerSub
                        Rec."Pct of Sub Unit" := Rec."Qty Required" / UnitsPerSub;
                end;

                Parent1Code := '';
                Parent2Code := '';
                Parent1Units := 0;
                Parent2Units := 0;
                ResolveTopParentFits(CurrentItem, Parent1Code, Parent1Units, Parent2Code, Parent2Units);

                if (Parent1Units > 0) and (Rec."Qty Required" > 0) then
                    Rec."Pct of Parent Unit 1" := Rec."Qty Required" / Parent1Units
                else
                    Rec."Pct of Parent Unit 1" := 0;

                if (Parent2Units > 0) and (Rec."Qty Required" > 0) then
                    Rec."Pct of Parent Unit 2" := Rec."Qty Required" / Parent2Units
                else
                    Rec."Pct of Parent Unit 2" := 0;

                Rec.Modify();
            until Rec.Next() = 0;
    end;

    local procedure ResolveTopParentFits(ItemNo: Code[20]; var Parent1Code: Code[10]; var Parent1Units: Decimal; var Parent2Code: Code[10]; var Parent2Units: Decimal)
    var
        ItemLoad: Record "WLM Item Loading Unit";
        DefaultChild: Code[10];
    begin
        Parent1Code := '';
        Parent2Code := '';
        Parent1Units := 0;
        Parent2Units := 0;

        if ItemNo = '' then
            exit;

        DefaultChild := '';
        if ItemLoad.Get(ItemNo) then
            DefaultChild := ItemLoad."Default Loading Unit";

        // Prefer fits using the item's default child loading unit when available
        ApplyBestFits(ItemNo, DefaultChild, DefaultChild <> '', Parent1Code, Parent1Units, Parent2Code, Parent2Units);

        // Fallback: consider any fit if none found with the preferred child
        if (Parent1Code = '') and (Parent2Code = '') then
            ApplyBestFits(ItemNo, '', false, Parent1Code, Parent1Units, Parent2Code, Parent2Units);
    end;

    local procedure ApplyBestFits(ItemNo: Code[20]; ChildFilter: Code[10]; UseChildFilter: Boolean; var Best1Code: Code[10]; var Best1Units: Decimal; var Best2Code: Code[10]; var Best2Units: Decimal)
    var
        Fit: Record "WLM Item Load Fit";
        Parent: Record "WLM Order Loading Unit";
    begin
        Fit.Reset();
        Fit.SetRange("Item No.", ItemNo);
        if UseChildFilter and (ChildFilter <> '') then
            Fit.SetRange("Child Load Unit Code", ChildFilter);

        if Fit.FindSet() then
            repeat
                if Parent.Get(Fit."Parent Load Unit Code") and Parent.AllowAsParent then begin
                    if Fit."Parent Load Unit Code" = Best1Code then begin
                        if Fit."Units Per Parent" > Best1Units then
                            Best1Units := Fit."Units Per Parent";
                    end else if Fit."Parent Load Unit Code" = Best2Code then begin
                        if Fit."Units Per Parent" > Best2Units then
                            Best2Units := Fit."Units Per Parent";
                    end else if Fit."Units Per Parent" > Best1Units then begin
                        Best2Units := Best1Units;
                        Best2Code := Best1Code;
                        Best1Units := Fit."Units Per Parent";
                        Best1Code := Fit."Parent Load Unit Code";
                    end else if Fit."Units Per Parent" > Best2Units then begin
                        Best2Units := Fit."Units Per Parent";
                        Best2Code := Fit."Parent Load Unit Code";
                    end;
                end;
            until Fit.Next() = 0;
    end;

    local procedure ComputeParReorderPoint(ItemNo: Code[20]; LocationCode: Code[10]): Decimal
    var
        Setup: Record "WLM FcstSetup";
        FcstEntry: Record "WLM Forecast Entry";
        StartDate: Date;
        EndDate: Date;
        TotalQty: Decimal;
        MonthsWindow: Integer;
        ParMonths: Integer;
        AvgMonthly: Decimal;
    begin
        if ItemNo = '' then
            exit(0);

        if not Setup.Get('SETUP') then
            exit(0);

        ParMonths := Setup."Default Par Stock Target";
        if ParMonths <= 0 then
            exit(0);

        // Use a 12-month forward window to average forecast demand per month.
        MonthsWindow := 12;
        StartDate := WorkDate;
        if StartDate = 0D then
            StartDate := Today;
        if StartDate = 0D then
            exit(0);

        StartDate := DMY2Date(1, Date2DMY(StartDate, 2), Date2DMY(StartDate, 3)); // first of month
        EndDate := CalcDate(StrSubstNo('+%1M', MonthsWindow), StartDate);
        EndDate := CalcDate('<CM-1D>', EndDate); // end of last month in window

        FcstEntry.Reset();
        FcstEntry.SetRange("Item No.", ItemNo);
        FcstEntry.SetRange("Location Code", LocationCode);
        if Setup."Default Forecast Name" <> '' then
            FcstEntry.SetRange("Forecast Name", Setup."Default Forecast Name");
        FcstEntry.SetRange("Forecast Date", StartDate, EndDate);

        FcstEntry.CalcSums(Quantity);
        TotalQty := FcstEntry.Quantity;
        if TotalQty <= 0 then
            exit(0);

        AvgMonthly := TotalQty / MonthsWindow;
        exit(ROUND(AvgMonthly * ParMonths, 1, '>'));
    end;

    local procedure NormalizeLocation(LocationCode: Code[20]): Code[10]
    var
        Clean: Text[30];
    begin
        Clean := DelChr(UpperCase(Format(LocationCode)), '=', ' ');
        exit(CopyStr(Clean, 1, 10));
    end;

    local procedure NormalizeItemNo(ItemNo: Code[50]): Code[20]
    var
        Clean: Text[50];
    begin
        Clean := DelChr(UpperCase(Format(ItemNo)), '=', ' ');
        exit(CopyStr(Clean, 1, 20));
    end;

    local procedure CalcOnHand(ItemNo: Code[20]; LocationCode: Code[10]): Decimal
    var
        Setup: Record "WLM FcstSetup";
        SubRec: Record "Item Substitution";
        Seen: Dictionary of [Code[20], Boolean];
        DonorNo: Code[20];
        Qty: Decimal;
    begin
        Qty := CalcOnHandSingle(ItemNo, LocationCode);

        if Setup.Get('SETUP') and Setup."Factor Subs in Inventory" then begin
            Seen.Add(ItemNo, true);
            SubRec.Reset();
            SubRec.SetRange("Substitute No.", ItemNo);
            if SubRec.FindSet() then
                repeat
                    DonorNo := SubRec."No.";
                    if not Seen.ContainsKey(DonorNo) then begin
                        Qty += CalcOnHandSingle(DonorNo, LocationCode);
                        Seen.Add(DonorNo, true);
                    end;
                until SubRec.Next() = 0;
        end;

        exit(Qty);
    end;

    local procedure CalcOnHandSingle(ItemNo: Code[20]; LocationCode: Code[10]): Decimal
    var
        ILE: Record "Item Ledger Entry";
    begin
        ILE.Reset();
        ILE.SetRange("Item No.", ItemNo);
        if LocationCode <> '' then
            ILE.SetRange("Location Code", LocationCode);
        ILE.CalcSums(Quantity);
        exit(ILE.Quantity);
    end;

    local procedure CalcOpenSales(ItemNo: Code[20]; LocationCode: Code[10]; BucketDate: Date): Decimal
    var
        Setup: Record "WLM FcstSetup";
        SubRec: Record "Item Substitution";
        SalesLine: Record "Sales Line";
        Seen: Dictionary of [Code[20], Boolean];
        TotalQty: Decimal;
        DonorNo: Code[20];
    begin
        TotalQty := 0;

        // Always include sales for the item itself
        Seen.Add(ItemNo, true);
        TotalQty += CalcOpenSalesForItem(ItemNo, LocationCode, BucketDate);

        // If factoring substitutes in sales demand: also include sales for items that substitute for this item
        // e.g., if ItemB is a substitute for ItemA, open sales for ItemB create demand pressure on ItemA
        if Setup.Get('SETUP') and Setup."Factor Subs in Sales Demand" then begin
            SubRec.Reset();
            SubRec.SetRange("Substitute No.", ItemNo);  // Find items where ItemNo is listed as a substitute
            if SubRec.FindSet() then
                repeat
                    DonorNo := SubRec."No.";
                    if not Seen.ContainsKey(DonorNo) then begin
                        Seen.Add(DonorNo, true);
                        TotalQty += CalcOpenSalesForItem(DonorNo, LocationCode, BucketDate);
                    end;
                until SubRec.Next() = 0;
        end;

        exit(TotalQty);
    end;

    local procedure CalcOpenSalesForItem(ItemNo: Code[20]; LocationCode: Code[10]; BucketDate: Date): Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetRange("No.", ItemNo);
        if LocationCode <> '' then
            SalesLine.SetRange("Location Code", LocationCode);
        SalesLine.SetFilter("Outstanding Quantity", '<>0');
        SalesLine.SetFilter("Shipment Date", '<=%1', BucketDate);
        SalesLine.CalcSums("Outstanding Quantity");
        exit(SalesLine."Outstanding Quantity");
    end;

    local procedure CalcOpenTransfers(ItemNo: Code[20]; LocationCode: Code[10]; BucketDate: Date): Decimal
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.Reset();
        TransferLine.SetRange("Transfer-from Code", LocationCode);
        TransferLine.SetRange("Item No.", ItemNo);
        TransferLine.SetFilter("Outstanding Quantity", '<>0');
        TransferLine.SetFilter("Shipment Date", '<=%1', BucketDate);
        TransferLine.CalcSums("Outstanding Quantity");
        exit(TransferLine."Outstanding Quantity");
    end;

    local procedure CalcInbound(ItemNo: Code[20]; LocationCode: Code[10]; BucketDate: Date; var InboundPurch: Decimal; var InboundTransfer: Decimal): Decimal
    var
        Setup: Record "WLM FcstSetup";
        SubRec: Record "Item Substitution";
        Seen: Dictionary of [Code[20], Boolean];
        Qty: Decimal;
        DonorNo: Code[20];
    begin
        if BucketDate = 0D then
            exit(0);

        InboundPurch := 0;
        InboundTransfer := 0;
        Qty := 0;

        if Setup.Get('SETUP') and Setup."Factor Subs in Inbound" then begin
            Seen.Add(ItemNo, true);
            AddInboundForItem(ItemNo, LocationCode, BucketDate, InboundPurch, InboundTransfer);

            SubRec.Reset();
            SubRec.SetRange("Substitute No.", ItemNo);
            if SubRec.FindSet() then
                repeat
                    DonorNo := SubRec."No.";
                    if not Seen.ContainsKey(DonorNo) then begin
                        Seen.Add(DonorNo, true);
                        AddInboundForItem(DonorNo, LocationCode, BucketDate, InboundPurch, InboundTransfer);
                    end;
                until SubRec.Next() = 0;
        end else begin
            AddInboundForItem(ItemNo, LocationCode, BucketDate, InboundPurch, InboundTransfer);
        end;

        Qty := InboundPurch + InboundTransfer;
        exit(Qty);
    end;

    local procedure AddInboundForItem(ItemNo: Code[20]; LocationCode: Code[10]; BucketDate: Date; var InboundPurchTotal: Decimal; var InboundTransferTotal: Decimal)
    var
        PurchLine: Record "Purchase Line";
        TransferLine: Record "Transfer Line";
    begin
        // Purchase orders inbound to this location due on or before the bucket date (cumulative)
        PurchLine.Reset();
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
        PurchLine.SetRange(Type, PurchLine.Type::Item);
        PurchLine.SetRange("No.", ItemNo);
        PurchLine.SetRange("Location Code", LocationCode);
        PurchLine.SetFilter("Expected Receipt Date", '<=%1', BucketDate);
        PurchLine.SetFilter("Outstanding Quantity", '<>0');
        PurchLine.CalcSums("Outstanding Quantity");
        InboundPurchTotal += PurchLine."Outstanding Quantity";

        // Transfer orders inbound to this location due on or before the bucket date (cumulative)
        TransferLine.Reset();
        TransferLine.SetRange("Transfer-to Code", LocationCode);
        TransferLine.SetRange("Item No.", ItemNo);
        TransferLine.SetFilter("Receipt Date", '<=%1', BucketDate);
        TransferLine.SetFilter("Outstanding Quantity", '<>0');
        TransferLine.CalcSums("Outstanding Quantity");
        InboundTransferTotal += TransferLine."Outstanding Quantity";
    end;

    var
        FromDate: Date;
        ToDate: Date;
}

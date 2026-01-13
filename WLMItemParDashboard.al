page 89710 "WLM Item Par Dashboard"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = Item;
    Caption = 'WLM Item Par Dashboard';
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("No."; Rec."No.") { ApplicationArea = All; Editable = false; }
                field(Description; Rec.Description) { ApplicationArea = All; Editable = false; }
                field("Vendor No."; Rec."Vendor No.") { ApplicationArea = All; Editable = false; }
                field("Item Category Code"; Rec."Item Category Code") { ApplicationArea = All; Editable = false; }
                field(Notes; NotesTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Notes';
                    Editable = false;
                }

                field("Global Dimension 1 Code"; Rec."Global Dimension 1 Code") { ApplicationArea = All; Editable = false; }
                field("Global Dimension 2 Code"; Rec."Global Dimension 2 Code") { ApplicationArea = All; Editable = false; }

                field("Shortcut Dim 3"; Rec."Shortcut Dim 3 Value FF")
                {
                    Caption = 'Shortcut Dimension 3';
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Shortcut Dim 4"; Rec."Shortcut Dim 4 Value FF")
                {
                    Caption = 'Shortcut Dimension 4';
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Shortcut Dim 5"; Rec."Shortcut Dim 5 Value FF")
                {
                    Caption = 'Shortcut Dimension 5';
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Shortcut Dim 6"; Rec."Shortcut Dim 6 Value FF")
                {
                    Caption = 'Shortcut Dimension 6';
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Shortcut Dim 7"; Rec."Shortcut Dim 7 Value FF")
                {
                    Caption = 'Shortcut Dimension 7';
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Shortcut Dim 8"; Rec."Shortcut Dim 8 Value FF")
                {
                    Caption = 'Shortcut Dimension 8';
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Purchasing Blocked"; Rec."Purchasing Blocked") { ApplicationArea = All; Editable = false; }
                field("Sales Blocked"; Rec."Sales Blocked") { ApplicationArea = All; Editable = false; }
                field(Blocked; Rec.Blocked) { ApplicationArea = All; Editable = false; }

                field("Last Direct Cost"; Rec."Last Direct Cost") { ApplicationArea = All; Editable = false; }
                field("Unit Cost"; Rec."Unit Cost") { ApplicationArea = All; Editable = false; }

                field(Inventory; InventoryQty)
                {
                    ApplicationArea = All;
                    Caption = 'Inventory (Planned Locs)';
                    BlankZero = true;
                    Style = Unfavorable;
                    StyleExpr = InventoryIsNegative;
                }
                field("Qty. on Purch. Orders"; QtyOnPO)
                {
                    ApplicationArea = All;
                    Caption = 'Qty. on Purchase Orders (Planned Locs)';
                    BlankZero = true;
                    Style = Unfavorable;
                    StyleExpr = QtyOnPOIsNegative;
                }
                field("Sales (Last 12M)"; SalesLast12M)
                {
                    ApplicationArea = All;
                    Caption = 'Sales (Last 12M)';
                    BlankZero = true;
                    Style = Unfavorable;
                    StyleExpr = SalesLastIsNegative;
                }
                field("Sales (Next 12M)"; SalesNext12M)
                {
                    ApplicationArea = All;
                    Caption = 'Sales (Next 12M)';
                    BlankZero = true;
                    Style = Unfavorable;
                    StyleExpr = SalesNextIsNegative;
                }
                field("Par Stock"; ParStock)
                {
                    ApplicationArea = All;
                    Caption = 'Par Stock';
                    BlankZero = true;
                    Style = Unfavorable;
                    StyleExpr = ParStockIsNegative;
                }
                field("Par (Next 12M)"; ParStockFuture)
                {
                    ApplicationArea = All;
                    Caption = 'Par (Next 12M)';
                    BlankZero = true;
                    Style = Unfavorable;
                    StyleExpr = ParFutureIsNegative;
                }
                field("Off Par"; OffPar)
                {
                    ApplicationArea = All;
                    Caption = 'Off Par';
                    BlankZero = true;
                    Style = Unfavorable;
                    StyleExpr = OffParIsNegative;
                }
                field("Off Par Unit Cost"; OffParUnitCost)
                {
                    ApplicationArea = All;
                    Caption = 'Off Par Unit Cost';
                    BlankZero = true;
                    Style = Unfavorable;
                    StyleExpr = OffParUnitCostIsNegative;
                }
                field("Off Par Last Direct Cost"; OffParLastDirectCost)
                {
                    ApplicationArea = All;
                    Caption = 'Off Par Last Direct Cost';
                    BlankZero = true;
                    Style = Unfavorable;
                    StyleExpr = OffParLastDirectCostIsNegative;
                }

                field("Days of Inventory (Last 12M)"; DaysInvPastTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Days of Inventory (Last 12M)';
                }
                field("Days of Inventory (Next 12M)"; DaysInvFutureTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Days of Inventory (Next 12M)';
                }
                field("Date to Full Depletion"; DateFullDepletion)
                {
                    ApplicationArea = All;
                    Caption = 'Date to Full Depletion';
                }
                field("Date to Par"; DateToPar)
                {
                    ApplicationArea = All;
                    Caption = 'Date to Par';
                }
                field("Date to Full Depletion (Inbound)"; DateFullDepletionInbound)
                {
                    ApplicationArea = All;
                    Caption = 'Date to Full Depletion (Inbound)';
                }
                field("Date to Par (Inbound)"; DateToParInbound)
                {
                    ApplicationArea = All;
                    Caption = 'Date to Par (Inbound)';
                }
                field("Inventory Turnover"; InventoryTurns)
                {
                    ApplicationArea = All;
                    Caption = 'Inventory Turnover (12M)';
                    BlankZero = true;
                }
                field("Unit Turn"; UnitTurn)
                {
                    ApplicationArea = All;
                    Caption = 'Unit Turn';
                    BlankZero = true;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(RefreshMetrics)
            {
                Caption = 'Refresh Metrics';
                ApplicationArea = All;
                Image = Refresh;
                trigger OnAction()
                begin
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        Setup: Record "WLM FcstSetup";
        GLSetup: Record "General Ledger Setup";
        ILE: Record "Item Ledger Entry";
        ValEntry: Record "Value Entry";
        FcstEntry: Record "WLM Forecast Entry";
        PurchLine: Record "Purchase Line";
        LocPlan: Record "WLM Fcst Location";
        ItemSub: Record "Item Substitution";
        ItemLookup: Record Item;

        ActiveLocFilter: Text;
        ParMonths: Integer;
        TodayDate: Date;
        DonorExclusionFilter: Text;

        InventoryQty: Decimal;
        QtyOnPO: Decimal;
        ParStock: Decimal;
        ParStockFuture: Decimal;
        OffPar: Decimal;
        OffParUnitCost: Decimal;
        OffParLastDirectCost: Decimal;
        OffParIsNegative: Boolean;
        OffParUnitCostIsNegative: Boolean;
        OffParLastDirectCostIsNegative: Boolean;
        InventoryIsNegative: Boolean;
        QtyOnPOIsNegative: Boolean;
        SalesLastIsNegative: Boolean;
        SalesNextIsNegative: Boolean;
        ParStockIsNegative: Boolean;
        ParFutureIsNegative: Boolean;
        DaysInvPastTxt: Text[30];
        DaysInvFutureTxt: Text[30];
        DateFullDepletion: Date;
        DateToPar: Date;
        DateFullDepletionInbound: Date;
        DateToParInbound: Date;
        InventoryTurns: Decimal;
        SalesLast12M: Decimal;
        SalesNext12M: Decimal;
        UnitTurn: Decimal;
        NotesTxt: Text[100];

        ShortcutDim3Code: Code[20];
        ShortcutDim4Code: Code[20];
        ShortcutDim5Code: Code[20];
        ShortcutDim6Code: Code[20];
        ShortcutDim7Code: Code[20];
        ShortcutDim8Code: Code[20];

        ItemGroup: List of [Code[20]];

    trigger OnOpenPage()
    begin
        TodayDate := WorkDate();
        EnsureSetup();
        LoadGLSetup();
        BuildActiveLocFilter();
        SetDimFlowFilters();
        ParMonths := Setup."Default Par Stock Target";
        ApplyDonorExclusionFilter();
    end;

    local procedure CalcNotes()
    var
        SubNo: Code[20];
    begin
        NotesTxt := '';

        if not Setup."Factor Subs in Par Dashboard" then
            exit;

        if not Rec."Purchasing Blocked" then
            exit;

        ItemSub.Reset();
        ItemSub.SetRange("No.", Rec."No.");
        if ItemSub.FindFirst() then begin
            SubNo := ItemSub."Substitute No.";
            if SubNo <> '' then
                NotesTxt := StrSubstNo('Attributed to Substitute Item %1', SubNo);
        end;
    end;

    trigger OnAfterGetRecord()
    begin
        EnsureSetup();
        CalcNotes();
        BuildItemGroup(ItemGroup);
        CalcMetrics();
    end;

    local procedure EnsureSetup()
    begin
        if not Setup.Get('SETUP') then begin
            Setup.Init();
            Setup.Insert(true);
        end;
    end;

    local procedure ApplyDonorExclusionFilter()
    var
        DonorNos: List of [Code[20]];
        FilterTxt: Text;
        DonorNo: Code[20];
    begin
        if not Setup."Factor Subs in Par Dashboard" then
            exit;

        ItemSub.Reset();
        if ItemSub.FindSet() then
            repeat
                DonorNo := ItemSub."No.";
                if (DonorNo = '') or (ItemSub."Substitute No." = '') then
                    continue;

                if ItemLookup.Get(DonorNo) then
                    if ItemLookup."Purchasing Blocked" then begin
                        if not DonorNos.Contains(DonorNo) then
                            DonorNos.Add(DonorNo);
                    end;
            until ItemSub.Next() = 0;

        if DonorNos.Count() = 0 then
            exit;

        foreach DonorNo in DonorNos do begin
            if FilterTxt <> '' then
                FilterTxt += '&';
            FilterTxt += '<>' + DonorNo;
        end;

        DonorExclusionFilter := FilterTxt;

        if FilterTxt <> '' then
            ApplyFilterWithExclusion(FilterTxt);
    end;

    local procedure ApplyFilterWithExclusion(ExclFilter: Text)
    var
        Existing: Text;
        Combined: Text;
    begin
        Existing := Rec.GetFilter("No.");
        if Existing = '' then
            Combined := ExclFilter
        else
            Combined := '(' + Existing + ')&(' + ExclFilter + ')';

        Rec.SetFilter("No.", Combined);
    end;

    local procedure BuildItemGroup(var ItemNos: List of [Code[20]])
    var
        DonorNo: Code[20];
    begin
        ClearList(ItemNos);
        ItemNos.Add(Rec."No.");

        if not Setup."Factor Subs in Par Dashboard" then
            exit;

        ItemSub.Reset();
        ItemSub.SetRange("Substitute No.", Rec."No.");
        if ItemSub.FindSet() then
            repeat
                DonorNo := ItemSub."No.";
                if DonorNo = '' then
                    continue;

                if ItemLookup.Get(DonorNo) then
                    if ItemLookup."Purchasing Blocked" then
                        if not ItemNos.Contains(DonorNo) then
                            ItemNos.Add(DonorNo);
            until ItemSub.Next() = 0;
    end;

    local procedure ClearList(var Codes: List of [Code[20]])
    begin
        while Codes.Count() > 0 do
            Codes.RemoveAt(1);
    end;

    local procedure LoadGLSetup()
    begin
        if not GLSetup.Get() then
            Clear(GLSetup);

        ShortcutDim3Code := GLSetup."Shortcut Dimension 3 Code";
        ShortcutDim4Code := GLSetup."Shortcut Dimension 4 Code";
        ShortcutDim5Code := GLSetup."Shortcut Dimension 5 Code";
        ShortcutDim6Code := GLSetup."Shortcut Dimension 6 Code";
        ShortcutDim7Code := GLSetup."Shortcut Dimension 7 Code";
        ShortcutDim8Code := GLSetup."Shortcut Dimension 8 Code";
    end;

    local procedure SetDimFlowFilters()
    begin
        if ShortcutDim3Code <> '' then
            Rec.SetRange("Shortcut Dim 3 Code FF", ShortcutDim3Code)
        else
            Rec.SetRange("Shortcut Dim 3 Code FF");

        if ShortcutDim4Code <> '' then
            Rec.SetRange("Shortcut Dim 4 Code FF", ShortcutDim4Code)
        else
            Rec.SetRange("Shortcut Dim 4 Code FF");

        if ShortcutDim5Code <> '' then
            Rec.SetRange("Shortcut Dim 5 Code FF", ShortcutDim5Code)
        else
            Rec.SetRange("Shortcut Dim 5 Code FF");

        if ShortcutDim6Code <> '' then
            Rec.SetRange("Shortcut Dim 6 Code FF", ShortcutDim6Code)
        else
            Rec.SetRange("Shortcut Dim 6 Code FF");

        if ShortcutDim7Code <> '' then
            Rec.SetRange("Shortcut Dim 7 Code FF", ShortcutDim7Code)
        else
            Rec.SetRange("Shortcut Dim 7 Code FF");

        if ShortcutDim8Code <> '' then
            Rec.SetRange("Shortcut Dim 8 Code FF", ShortcutDim8Code)
        else
            Rec.SetRange("Shortcut Dim 8 Code FF");
    end;

    local procedure BuildActiveLocFilter()
    var
        LocFilter: Text;
    begin
        ActiveLocFilter := '';
        LocPlan.Reset();
        LocPlan.SetRange(Active, true);
        if LocPlan.FindSet() then
            repeat
                if LocFilter <> '' then
                    LocFilter += '|';
                LocFilter += LocPlan."Location Code";
            until LocPlan.Next() = 0;

        ActiveLocFilter := LocFilter;
    end;

    local procedure CalcMetrics()
    var
        Sales12M: Decimal;
        AvgDailySales: Decimal;
        Forecast12M: Decimal;
        AvgDailyForecast: Decimal;
        InvStart: Decimal;
        AvgInv: Decimal;
        MaxUnitCost: Decimal;
        MaxLastDirectCost: Decimal;
    begin
        InventoryQty := CalcInventory(ItemGroup);
        QtyOnPO := CalcQtyOnPurchaseOrders(ItemGroup);

        Sales12M := CalcSales12M(ItemGroup);
        SalesLast12M := Sales12M;
        AvgDailySales := Sales12M / 365;

        ParStock := Round(AvgDailySales * ParMonths * 30, 1, '>'); // round up to whole units
        OffPar := InventoryQty - ParStock; // positive = over par, negative = under par
        CalcMaxCosts(ItemGroup, MaxUnitCost, MaxLastDirectCost);
        OffParUnitCost := OffPar * MaxUnitCost;
        OffParLastDirectCost := OffPar * MaxLastDirectCost;
        OffParIsNegative := OffPar < 0;
        OffParUnitCostIsNegative := OffParUnitCost < 0;
        OffParLastDirectCostIsNegative := OffParLastDirectCost < 0;
        InventoryIsNegative := InventoryQty < 0;
        QtyOnPOIsNegative := QtyOnPO < 0;
        SalesLastIsNegative := SalesLast12M < 0;
        SalesNextIsNegative := SalesNext12M < 0;
        ParStockIsNegative := ParStock < 0;
        ParFutureIsNegative := ParStockFuture < 0;

        if AvgDailySales = 0 then
            DaysInvPastTxt := '∞'
        else
            // show whole days to avoid overflow/asterisk rendering
            DaysInvPastTxt := Format(InventoryQty / AvgDailySales, 0, '<Sign><Integer>');

        Forecast12M := CalcForecast12M(ItemGroup);
        SalesNext12M := Forecast12M;
        AvgDailyForecast := Forecast12M / 365;

        ParStockFuture := Round(AvgDailyForecast * ParMonths * 30, 1, '>');

        if AvgDailyForecast = 0 then
            DaysInvFutureTxt := '∞'
        else
            // show whole days to avoid overflow/asterisk rendering
            DaysInvFutureTxt := Format(InventoryQty / AvgDailyForecast, 0, '<Sign><Integer>');

        DateFullDepletion := CalcDateToThreshold(ItemGroup, 0, InventoryQty);
        DateToPar := CalcDateToPar(ItemGroup, ParStock, InventoryQty);
        DateFullDepletionInbound := CalcDateToThresholdInbound(ItemGroup, 0, InventoryQty);
        DateToParInbound := CalcDateToParInbound(ItemGroup, ParStock, InventoryQty);

        CalcInventoryTurns(ItemGroup, InvStart, AvgInv, InventoryTurns);

        // Unit Turnover = Total Units Sold in Period / Average Units in Inventory
        if AvgInv = 0 then
            UnitTurn := 0
        else
            UnitTurn := SalesLast12M / AvgInv;
    end;

    local procedure BuildGroupFilter(ItemNos: List of [Code[20]]): Text
    var
        FilterTxt: Text;
        ItemNo: Code[20];
    begin
        FilterTxt := '';
        foreach ItemNo in ItemNos do begin
            if FilterTxt <> '' then
                FilterTxt += '|';
            FilterTxt += ItemNo;
        end;
        exit(FilterTxt);
    end;

    local procedure CalcInventory(ItemNos: List of [Code[20]]): Decimal
    var
        Qty: Decimal;
        ItemFilter: Text;
    begin
        ItemFilter := BuildGroupFilter(ItemNos);
        // Sum remaining quantity across active forecast locations (avoid drop ship / other locs)
        ILE.Reset();
        ILE.SetCurrentKey("Item No.", "Location Code", "Posting Date");
        if ItemFilter <> '' then
            ILE.SetFilter("Item No.", ItemFilter)
        else
            ILE.SetRange("Item No.");
        if ActiveLocFilter <> '' then
            ILE.SetFilter("Location Code", ActiveLocFilter);
        ILE.CalcSums("Remaining Quantity");
        Qty := ILE."Remaining Quantity";
        exit(Qty);
    end;

    local procedure CalcQtyOnPurchaseOrders(ItemNos: List of [Code[20]]): Decimal
    var
        Qty: Decimal;
        ItemFilter: Text;
    begin
        ItemFilter := BuildGroupFilter(ItemNos);
        PurchLine.Reset();
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
        PurchLine.SetRange(Type, PurchLine.Type::Item);
        if ItemFilter <> '' then
            PurchLine.SetFilter("No.", ItemFilter);
        PurchLine.SetFilter("Outstanding Quantity", '<>%1', 0);
        if ActiveLocFilter <> '' then
            PurchLine.SetFilter("Location Code", ActiveLocFilter);

        if PurchLine.FindSet() then
            repeat
                Qty += PurchLine."Outstanding Quantity";
            until PurchLine.Next() = 0;
        exit(Qty);
    end;

    local procedure CalcSales12M(ItemNos: List of [Code[20]]): Decimal
    var
        StartDate: Date;
        Qty: Decimal;
        ItemFilter: Text;
    begin
        StartDate := CalcDate('-12M', TodayDate + 1);
        ItemFilter := BuildGroupFilter(ItemNos);
        ILE.Reset();
        ILE.SetCurrentKey("Item No.", "Posting Date", "Location Code");
        if ItemFilter <> '' then
            ILE.SetFilter("Item No.", ItemFilter);
        ILE.SetRange("Entry Type", ILE."Entry Type"::Sale);
        ILE.SetRange("Posting Date", StartDate, TodayDate);
        if ActiveLocFilter <> '' then
            ILE.SetFilter("Location Code", ActiveLocFilter);
        if ILE.FindSet() then
            repeat
                // Sales are negative; treat demand as positive
                Qty += -ILE.Quantity;
            until ILE.Next() = 0;
        exit(Qty);
    end;

    local procedure CalcForecast12M(ItemNos: List of [Code[20]]): Decimal
    var
        EndDate: Date;
        Qty: Decimal;
        ItemFilter: Text;
    begin
        EndDate := CalcDate('+12M', TodayDate);
        ItemFilter := BuildGroupFilter(ItemNos);
        FcstEntry.Reset();
        FcstEntry.SetCurrentKey("Item No.", "Forecast Date", "Location Code");
        if ItemFilter <> '' then
            FcstEntry.SetFilter("Item No.", ItemFilter);
        FcstEntry.SetRange("Forecast Date", TodayDate, EndDate);
        if ActiveLocFilter <> '' then
            FcstEntry.SetFilter("Location Code", ActiveLocFilter);
        // If a specific forecast name is required, use Setup.Default Forecast Name
        if Setup."Default Forecast Name" <> '' then
            FcstEntry.SetRange("Forecast Name", Setup."Default Forecast Name");

        if FcstEntry.FindSet() then
            repeat
                Qty += FcstEntry.Quantity;
            until FcstEntry.Next() = 0;
        exit(Qty);
    end;

    local procedure CalcAvgDailyForecast(ItemNos: List of [Code[20]]): Decimal
    var
        Forecast12M: Decimal;
    begin
        Forecast12M := CalcForecast12M(ItemNos);
        exit(Forecast12M / 365);
    end;

    local procedure CalcMaxCosts(ItemNos: List of [Code[20]]; var MaxUnitCost: Decimal; var MaxLastDirectCost: Decimal)
    var
        ItemNo: Code[20];
    begin
        MaxUnitCost := 0;
        MaxLastDirectCost := 0;
        foreach ItemNo in ItemNos do
            if ItemLookup.Get(ItemNo) then begin
                if ItemLookup."Unit Cost" > MaxUnitCost then
                    MaxUnitCost := ItemLookup."Unit Cost";
                if ItemLookup."Last Direct Cost" > MaxLastDirectCost then
                    MaxLastDirectCost := ItemLookup."Last Direct Cost";
            end;
    end;

    local procedure CalcDateToThreshold(ItemNos: List of [Code[20]]; Threshold: Decimal; StartingQty: Decimal): Date
    var
        EndDate: Date;
        Qty: Decimal;
        CurrentDate: Date;
        LastDate: Date;
        AvgDailyForecast: Decimal;
        DaysNeeded: Decimal;
        ItemFilter: Text;
    begin
        Qty := StartingQty;
        if Qty <= Threshold then
            exit(TodayDate);

        EndDate := CalcDate('+24M', TodayDate);

        FcstEntry.Reset();
        FcstEntry.SetCurrentKey("Item No.", "Forecast Date", "Location Code");
        ItemFilter := BuildGroupFilter(ItemNos);
        if ItemFilter <> '' then
            FcstEntry.SetFilter("Item No.", ItemFilter);
        FcstEntry.SetRange("Forecast Date", TodayDate, EndDate);
        if ActiveLocFilter <> '' then
            FcstEntry.SetFilter("Location Code", ActiveLocFilter);
        if Setup."Default Forecast Name" <> '' then
            FcstEntry.SetRange("Forecast Name", Setup."Default Forecast Name");

        if FcstEntry.FindSet() then
            repeat
                if (LastDate = 0D) or (FcstEntry."Forecast Date" <> LastDate) then
                    LastDate := FcstEntry."Forecast Date";
                Qty -= FcstEntry.Quantity;
                if Qty <= Threshold then
                    exit(FcstEntry."Forecast Date");
            until FcstEntry.Next() = 0;

        // Fallback: extend beyond horizon using steady average daily forecast demand
        AvgDailyForecast := CalcAvgDailyForecast(ItemNos);
        if AvgDailyForecast <= 0 then
            exit(0D);

        DaysNeeded := ROUND((Qty - Threshold) / AvgDailyForecast, 1, '>');
        exit(TodayDate + DaysNeeded);
    end;

    local procedure CalcDateToPar(ItemNos: List of [Code[20]]; ParTarget: Decimal; StartingQty: Decimal): Date
    var
        EndDate: Date;
        Qty: Decimal;
        AvgDailyForecast: Decimal;
        DaysNeeded: Decimal;
        ItemFilter: Text;
    begin
        if StartingQty >= ParTarget then
            exit(TodayDate);

        Qty := StartingQty;
        EndDate := CalcDate('+24M', TodayDate);

        FcstEntry.Reset();
        FcstEntry.SetCurrentKey("Item No.", "Forecast Date", "Location Code");
        ItemFilter := BuildGroupFilter(ItemNos);
        if ItemFilter <> '' then
            FcstEntry.SetFilter("Item No.", ItemFilter);
        FcstEntry.SetRange("Forecast Date", TodayDate, EndDate);
        if ActiveLocFilter <> '' then
            FcstEntry.SetFilter("Location Code", ActiveLocFilter);
        if Setup."Default Forecast Name" <> '' then
            FcstEntry.SetRange("Forecast Name", Setup."Default Forecast Name");

        if FcstEntry.FindSet() then
            repeat
                Qty -= FcstEntry.Quantity;
                if Qty <= ParTarget then
                    exit(FcstEntry."Forecast Date");
            until FcstEntry.Next() = 0;

        // Fallback: extend beyond horizon using steady average daily forecast demand
        AvgDailyForecast := CalcAvgDailyForecast(ItemNos);
        if AvgDailyForecast <= 0 then
            exit(0D);

        DaysNeeded := ROUND((ParTarget - Qty) / AvgDailyForecast, 1, '>');
        exit(TodayDate + DaysNeeded);
    end;

    local procedure BuildNetChangesByDate(ItemNos: List of [Code[20]]; var DateChanges: Dictionary of [Date, Decimal]; var DateList: List of [Date])
    var
        Change: Decimal;
        D: Date;
        Existing: Decimal;
        HorizonEnd: Date;
        ItemFilter: Text;
    begin
        Clear(DateChanges);
        Clear(DateList);
        HorizonEnd := CalcDate('+24M', TodayDate);

        ItemFilter := BuildGroupFilter(ItemNos);

        // Forecast demand (negative)
        FcstEntry.Reset();
        FcstEntry.SetCurrentKey("Item No.", "Forecast Date", "Location Code");
        if ItemFilter <> '' then
            FcstEntry.SetFilter("Item No.", ItemFilter);
        FcstEntry.SetRange("Forecast Date", TodayDate, HorizonEnd);
        if ActiveLocFilter <> '' then
            FcstEntry.SetFilter("Location Code", ActiveLocFilter);
        if Setup."Default Forecast Name" <> '' then
            FcstEntry.SetRange("Forecast Name", Setup."Default Forecast Name");

        if FcstEntry.FindSet() then
            repeat
                D := FcstEntry."Forecast Date";
                Change := -FcstEntry.Quantity;
                if DateChanges.ContainsKey(D) then begin
                    Existing := 0;
                    DateChanges.Get(D, Existing);
                    DateChanges.Set(D, Existing + Change);
                end else begin
                    DateChanges.Add(D, Change);
                    DateList.Add(D);
                end;
            until FcstEntry.Next() = 0;

        // Inbound purchase orders (positive)
        PurchLine.Reset();
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
        PurchLine.SetRange(Type, PurchLine.Type::Item);
        if ItemFilter <> '' then
            PurchLine.SetFilter("No.", ItemFilter);
        PurchLine.SetFilter("Outstanding Quantity", '<>%1', 0);
        PurchLine.SetRange("Expected Receipt Date", TodayDate, HorizonEnd);
        if ActiveLocFilter <> '' then
            PurchLine.SetFilter("Location Code", ActiveLocFilter);

        if PurchLine.FindSet() then
            repeat
                D := PurchLine."Expected Receipt Date";
                Change := PurchLine."Outstanding Quantity";
                if DateChanges.ContainsKey(D) then begin
                    Existing := 0;
                    DateChanges.Get(D, Existing);
                    DateChanges.Set(D, Existing + Change);
                end else begin
                    DateChanges.Add(D, Change);
                    DateList.Add(D);
                end;
            until PurchLine.Next() = 0;

        // list will be consumed via PopEarliestDate
    end;

    local procedure CalcDateToThresholdInbound(ItemNos: List of [Code[20]]; Threshold: Decimal; StartingQty: Decimal): Date
    var
        DateChanges: Dictionary of [Date, Decimal];
        DateList: List of [Date];
        Qty: Decimal;
        D: Date;
        AvgDailyForecast: Decimal;
        DaysNeeded: Decimal;
    begin
        Qty := StartingQty;
        if Qty <= Threshold then
            exit(TodayDate);

        BuildNetChangesByDate(ItemNos, DateChanges, DateList);
        while DateList.Count() > 0 do begin
            D := PopEarliestDate(DateList);
            Qty += GetChange(DateChanges, D);
            if Qty <= Threshold then
                exit(D);
        end;

        // Fallback: extend beyond horizon using steady average daily forecast demand
        AvgDailyForecast := CalcAvgDailyForecast(ItemNos);
        if AvgDailyForecast <= 0 then
            exit(0D);

        DaysNeeded := ROUND((Qty - Threshold) / AvgDailyForecast, 1, '>');
        exit(TodayDate + DaysNeeded);
    end;

    local procedure CalcDateToParInbound(ItemNos: List of [Code[20]]; ParTarget: Decimal; StartingQty: Decimal): Date
    var
        DateChanges: Dictionary of [Date, Decimal];
        DateList: List of [Date];
        Qty: Decimal;
        D: Date;
        AvgDailyForecast: Decimal;
        DaysNeeded: Decimal;
    begin
        if StartingQty >= ParTarget then
            exit(TodayDate);

        Qty := StartingQty;
        BuildNetChangesByDate(ItemNos, DateChanges, DateList);

        while DateList.Count() > 0 do begin
            D := PopEarliestDate(DateList);
            Qty += GetChange(DateChanges, D);
            if Qty <= ParTarget then
                exit(D);
        end;

        // Fallback: extend beyond horizon using steady average daily forecast demand
        AvgDailyForecast := CalcAvgDailyForecast(ItemNos);
        if AvgDailyForecast <= 0 then
            exit(0D);

        DaysNeeded := ROUND((ParTarget - Qty) / AvgDailyForecast, 1, '>');
        exit(TodayDate + DaysNeeded);
    end;

    local procedure PopEarliestDate(var DateList: List of [Date]): Date
    var
        MinDate: Date;
        idx: Integer;
        i: Integer;
    begin
        if DateList.Count() = 0 then
            exit(0D);

        MinDate := DateList.Get(1);
        idx := 1;
        for i := 2 to DateList.Count() do
            if DateList.Get(i) < MinDate then begin
                MinDate := DateList.Get(i);
                idx := i;
            end;

        DateList.RemoveAt(idx);
        exit(MinDate);
    end;

    local procedure GetChange(DateChanges: Dictionary of [Date, Decimal]; D: Date): Decimal
    var
        Val: Decimal;
    begin
        Val := 0;
        if DateChanges.ContainsKey(D) then
            DateChanges.Get(D, Val);
        exit(Val);
    end;

    local procedure CalcInventoryTurns(ItemNos: List of [Code[20]]; var InventoryAtStart: Decimal; var AvgInventory: Decimal; var Turns: Decimal)
    var
        StartDate: Date;
        COGS: Decimal;
        InvNow: Decimal;
        ItemFilter: Text;
        ItemNo: Code[20];
        OldLocFilter: Text;
    begin
        StartDate := CalcDate('-12M', TodayDate + 1);

        ItemFilter := BuildGroupFilter(ItemNos);

        // COGS last 12 months, scoped to active locations via related ILEs
        ILE.Reset();
        if ItemFilter <> '' then
            ILE.SetFilter("Item No.", ItemFilter);
        ILE.SetRange("Entry Type", ILE."Entry Type"::Sale);
        ILE.SetRange("Posting Date", StartDate, TodayDate);
        if ActiveLocFilter <> '' then
            ILE.SetFilter("Location Code", ActiveLocFilter);

        if ILE.FindSet() then
            repeat
                ValEntry.Reset();
                ValEntry.SetRange("Item Ledger Entry No.", ILE."Entry No.");
                ValEntry.CalcSums("Cost Amount (Actual)");
                COGS += -ValEntry."Cost Amount (Actual)"; // sales are negative; make positive
            until ILE.Next() = 0;

        // Inventory now (already filtered by active locs elsewhere)
        InvNow := InventoryQty;

        // Inventory 12M ago via Date Filter on Item for each group item, respecting active locations
        InventoryAtStart := 0;
        foreach ItemNo in ItemNos do begin
            if ItemLookup.Get(ItemNo) then begin
                OldLocFilter := ItemLookup.GetFilter("Location Filter");
                if ActiveLocFilter <> '' then
                    ItemLookup.SetFilter("Location Filter", ActiveLocFilter)
                else
                    ItemLookup.SetRange("Location Filter");

                ItemLookup.SetRange("Date Filter", 0D, StartDate - 1);
                ItemLookup.CalcFields(Inventory);
                InventoryAtStart += ItemLookup.Inventory;

                ItemLookup.SetRange("Date Filter");
                ItemLookup.SetFilter("Location Filter", OldLocFilter);
            end;
        end;

        AvgInventory := (InvNow + InventoryAtStart) / 2;
        if AvgInventory = 0 then begin
            Turns := 0;
            exit;
        end;

        Turns := COGS / AvgInventory;
    end;

}

table 89695 "WLM Net Requirement"
{
    Caption = 'WLM Net Requirement';
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item."No.";
        }
        field(2; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location.Code;
        }
        field(3; "Required Date"; Date)
        {
            Caption = 'Required Date';
        }
        field(10; "Demand Quantity"; Decimal)
        {
            Caption = 'Demand Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(11; "Supply Quantity"; Decimal)
        {
            Caption = 'Supply Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(12; "Net Quantity"; Decimal)
        {
            Caption = 'Net Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(13; "Running Balance"; Decimal)
        {
            Caption = 'Running Balance';
            DecimalPlaces = 0 : 5;
        }
        field(14; "Shortage Date"; Date)
        {
            Caption = 'Shortage Date';
        }
        field(15; "Priority Score"; Decimal)
        {
            Caption = 'Priority Score';
            DecimalPlaces = 0 : 5;
        }
        field(16; "Reorder Point"; Decimal)
        {
            Caption = 'Reorder Point';
            DecimalPlaces = 0 : 5;
        }
        field(17; "Below ROP Date"; Date)
        {
            Caption = 'Below Reorder Point Date';
        }
        field(18; "Zero Balance Date"; Date)
        {
            Caption = 'Zero Balance Date';
        }
        field(20; "Urgency Level"; Option)
        {
            Caption = 'Urgency Level';
            OptionMembers = ParStock,BelowROP,Stockout;
            Description = 'Stockout=balance will go negative, BelowROP=below reorder point but positive, ParStock=rebuilding par';
        }
        field(21; "Stockout Qty"; Decimal)
        {
            Caption = 'Stockout Qty';
            DecimalPlaces = 0 : 5;
            Description = 'Quantity that will cause stockout (demand exceeding supply)';
        }
        field(22; "Par Rebuild Qty"; Decimal)
        {
            Caption = 'Par Rebuild Qty';
            DecimalPlaces = 0 : 5;
            Description = 'Quantity needed to rebuild to par/reorder point';
        }
    }

    keys
    {
        key(PK; "Item No.", "Location Code", "Required Date")
        {
            Clustered = true;
        }
        key(PriorityIdx; "Priority Score", "Required Date")
        {
        }
        key(UrgencyIdx; "Urgency Level", "Priority Score")
        {
        }
    }
}

codeunit 89688 "WLM LoadPlanner"
{
    procedure BuildLoadSuggestions(FromDate: Date; ToDate: Date; SuggestionHandler: Interface "WLM Load Suggestion Handler")
    var
        Requirement: Record "WLM Net Requirement" temporary;
        Setup: Record "WLM FcstSetup";
        StartDate: Date;
        EndDate: Date;
    begin
        EnsureSetup(Setup);
        StartDate := FromDate;
        EndDate := ToDate;
        ApplyResourcePlanningLimit(Setup, StartDate, EndDate);

        BuildNetRequirements(StartDate, EndDate, Requirement);
        GenerateLoadSuggestions(Requirement, SuggestionHandler);
    end;

    procedure BuildNetRequirements(FromDate: Date; ToDate: Date; var Requirement: Record "WLM Net Requirement")
    var
        Setup: Record "WLM FcstSetup";
        StartDate: Date;
        EndDate: Date;
    begin
        EnsureSetup(Setup);

        StartDate := NormalizeFromDate(FromDate);
        EndDate := NormalizeToDate(ToDate);

        Requirement.Reset();
        Requirement.DeleteAll();
        Clear(LocationBalances);
        Clear(LocationShortageFlags);
        Clear(ReorderPointCache);
        LoadPlannedLocations();

        CollectForecastDemand(Setup, StartDate, EndDate, Requirement);
        CollectSalesDemand(StartDate, EndDate, Requirement);
        CollectOnHandInventory(Setup, StartDate, Requirement);
        CollectPurchaseSupply(StartDate, EndDate, Requirement);
        CollectTransferSupply(StartDate, EndDate, Requirement);

        FinalizeNetMetrics(Requirement);
    end;

    local procedure CollectForecastDemand(Setup: Record "WLM FcstSetup"; FromDate: Date; ToDate: Date; var Requirement: Record "WLM Net Requirement")
    var
        ForecastEntry: Record "WLM Forecast Entry";
        ForecastName: Code[20];
        ProratedQty: Decimal;
        TodayDate: Date;
        ForecastMonth: Integer;
        ForecastYear: Integer;
        DaysInMonth: Integer;
        DaysRemaining: Integer;
    begin
        ForecastName := Setup."Default Forecast Name";
        ForecastEntry.Reset();
        if ForecastName <> '' then
            ForecastEntry.SetRange("Forecast Name", ForecastName);

        if FromDate <> 0D then
            ForecastEntry.SetRange("Forecast Date", FromDate, ToDate);

        TodayDate := WorkDate();
        if TodayDate = 0D then
            TodayDate := Today;

        if ForecastEntry.FindSet() then
            repeat
                ProratedQty := ForecastEntry.Quantity;

                // Prorate current month forecast by days remaining
                if ForecastEntry."Forecast Date" <> 0D then begin
                    ForecastMonth := Date2DMY(ForecastEntry."Forecast Date", 2);
                    ForecastYear := Date2DMY(ForecastEntry."Forecast Date", 3);
                    // Check if forecast is in the same month as today
                    if (Date2DMY(TodayDate, 2) = ForecastMonth) and (Date2DMY(TodayDate, 3) = ForecastYear) then begin
                        // Calculate days in this month and days remaining
                        DaysInMonth := Date2DMY(CalcDate('<CM>', ForecastEntry."Forecast Date"), 1);
                        DaysRemaining := DaysInMonth - Date2DMY(TodayDate, 1) + 1; // Include today
                        if (DaysInMonth > 0) and (DaysRemaining > 0) then
                            ProratedQty := Round(ForecastEntry.Quantity * (DaysRemaining / DaysInMonth), 1);
                    end;
                end;

                AddDemandLine(Requirement, ForecastEntry."Item No.", ForecastEntry."Location Code", ForecastEntry."Forecast Date", ProratedQty);
            until ForecastEntry.Next() = 0;
    end;

    local procedure CollectSalesDemand(FromDate: Date; ToDate: Date; var Requirement: Record "WLM Net Requirement")
    var
        Setup: Record "WLM FcstSetup";
        SalesLine: Record "Sales Line";
        Substitution: Record "Item Substitution";
        DemandDate: Date;
        Qty: Decimal;
    begin
        EnsureSetup(Setup);

        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetFilter("Outstanding Quantity", '<>0');

        if SalesLine.FindSet() then
            repeat
                Qty := SalesLine."Outstanding Quantity";
                if Qty = 0 then
                    continue;

                DemandDate := DetermineSalesDemandDate(SalesLine);
                if (FromDate <> 0D) and (DemandDate < FromDate) then
                    continue;
                if (ToDate <> 0D) and (DemandDate > ToDate) then
                    continue;

                // Add demand for the item itself
                AddDemandLine(Requirement, SalesLine."No.", SalesLine."Location Code", DemandDate, Qty);

                // If factoring substitutes in sales demand: also add demand to items that this sales item substitutes for
                // e.g., if ItemB is a substitute for ItemA, an open sales order for ItemB also creates demand pressure on ItemA
                if Setup."Factor Subs in Sales Demand" then begin
                    Substitution.Reset();
                    Substitution.SetRange("No.", SalesLine."No.");  // Find items where this sales item is listed as a substitute
                    if Substitution.FindSet() then
                        repeat
                            AddDemandLine(Requirement, Substitution."Substitute No.", SalesLine."Location Code", DemandDate, Qty);
                        until Substitution.Next() = 0;
                end;
            until SalesLine.Next() = 0;
    end;

    local procedure CollectOnHandInventory(Setup: Record "WLM FcstSetup"; FromDate: Date; var Requirement: Record "WLM Net Requirement")
    var
        ILE: Record "Item Ledger Entry";
        SupplyDate: Date;
        OnHandQty: Decimal;
        CurrentItem: Code[20];
        CurrentLoc: Code[10];
        Substitution: Record "Item Substitution";
    begin
        SupplyDate := FromDate;
        if SupplyDate = 0D then
            SupplyDate := WorkDate;
        SupplyDate := SupplyDate - 1;

        // Group by Item/Location and sum Quantity (actual inventory movement)
        // This matches how Planning Schedule calculates On Hand
        ILE.Reset();
        ILE.SetCurrentKey("Item No.", "Location Code");

        if ILE.FindSet() then begin
            CurrentItem := '';
            CurrentLoc := '';
            OnHandQty := 0;

            repeat
                if (ILE."Item No." <> CurrentItem) or (ILE."Location Code" <> CurrentLoc) then begin
                    // Save previous item/location's on-hand
                    if (CurrentItem <> '') and (OnHandQty <> 0) then begin
                        AddSupplyLine(Requirement, CurrentItem, CurrentLoc, SupplyDate, OnHandQty);

                        if Setup."Factor Subs in Inventory" then begin
                            Substitution.Reset();
                            Substitution.SetRange("No.", CurrentItem);
                            if Substitution.FindSet() then
                                repeat
                                    AddSupplyLine(Requirement, Substitution."Substitute No.", CurrentLoc, SupplyDate, OnHandQty);
                                until Substitution.Next() = 0;
                        end;
                    end;

                    // Start new group
                    CurrentItem := ILE."Item No.";
                    CurrentLoc := ILE."Location Code";
                    OnHandQty := 0;
                end;

                OnHandQty += ILE.Quantity;
            until ILE.Next() = 0;

            // Don't forget the last group
            if (CurrentItem <> '') and (OnHandQty <> 0) then begin
                AddSupplyLine(Requirement, CurrentItem, CurrentLoc, SupplyDate, OnHandQty);

                if Setup."Factor Subs in Inventory" then begin
                    Substitution.Reset();
                    Substitution.SetRange("No.", CurrentItem);
                    if Substitution.FindSet() then
                        repeat
                            AddSupplyLine(Requirement, Substitution."Substitute No.", CurrentLoc, SupplyDate, OnHandQty);
                        until Substitution.Next() = 0;
                end;
            end;
        end;
    end;

    local procedure RemainingQuantityIsFlowField(): Boolean
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
        ILE: Record "Item Ledger Entry";
    begin
        if RemainingQtyChecked then
            exit(RemainingQtyIsFlowField);

        RecRef.Open(Database::"Item Ledger Entry");
        FieldRef := RecRef.Field(ILE.FieldNo("Remaining Quantity"));
        RemainingQtyIsFlowField := FieldRef.Class = FieldClass::FlowField;
        RemainingQtyChecked := true;
        RecRef.Close();
        exit(RemainingQtyIsFlowField);
    end;

    local procedure CollectPurchaseSupply(FromDate: Date; ToDate: Date; var Requirement: Record "WLM Net Requirement")
    var
        Setup: Record "WLM FcstSetup";
        PurchLine: Record "Purchase Line";
        Substitution: Record "Item Substitution";
        Qty: Decimal;
        ReceiptDate: Date;
    begin
        EnsureSetup(Setup);

        PurchLine.Reset();
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
        PurchLine.SetRange(Type, PurchLine.Type::Item);
        PurchLine.SetFilter("Outstanding Quantity", '<>0');
        if (FromDate <> 0D) and (ToDate <> 0D) then
            PurchLine.SetRange("Expected Receipt Date", FromDate, ToDate)
        else begin
            if FromDate <> 0D then
                PurchLine.SetFilter("Expected Receipt Date", '>=%1', FromDate)
            else
                if ToDate <> 0D then
                    PurchLine.SetFilter("Expected Receipt Date", '<=%1', ToDate);
        end;

        if PurchLine.FindSet() then
            repeat
                Qty := PurchLine."Outstanding Quantity";
                if Qty = 0 then
                    continue;
                ReceiptDate := PurchLine."Expected Receipt Date";
                if ReceiptDate = 0D then
                    ReceiptDate := FromDate;

                // Add supply for the item itself
                AddSupplyLine(Requirement, PurchLine."No.", PurchLine."Location Code", ReceiptDate, Qty);

                // If factoring substitutes in inbound: also credit this supply to items that this item substitutes for
                // e.g., if ItemB is a substitute for ItemA, a PO for ItemB also provides supply coverage for ItemA
                if Setup."Factor Subs in Inbound" then begin
                    Substitution.Reset();
                    Substitution.SetRange("No.", PurchLine."No.");  // Find items where this PO item is listed as a substitute
                    if Substitution.FindSet() then
                        repeat
                            AddSupplyLine(Requirement, Substitution."Substitute No.", PurchLine."Location Code", ReceiptDate, Qty);
                        until Substitution.Next() = 0;
                end;
            until PurchLine.Next() = 0;
    end;

    local procedure CollectTransferSupply(FromDate: Date; ToDate: Date; var Requirement: Record "WLM Net Requirement")
    var
        Setup: Record "WLM FcstSetup";
        TransferLine: Record "Transfer Line";
        Substitution: Record "Item Substitution";
        Qty: Decimal;
        ReceiptDate: Date;
        ShipmentDate: Date;
    begin
        EnsureSetup(Setup);

        TransferLine.Reset();
        TransferLine.SetFilter("Outstanding Quantity", '<>0');
        if (FromDate <> 0D) and (ToDate <> 0D) then
            TransferLine.SetRange("Receipt Date", FromDate, ToDate)
        else begin
            if FromDate <> 0D then
                TransferLine.SetFilter("Receipt Date", '>=%1', FromDate)
            else
                if ToDate <> 0D then
                    TransferLine.SetFilter("Receipt Date", '<=%1', ToDate);
        end;

        if TransferLine.FindSet() then
            repeat
                Qty := TransferLine."Outstanding Quantity";
                if Qty = 0 then
                    continue;

                ReceiptDate := TransferLine."Receipt Date";
                if ReceiptDate = 0D then
                    ReceiptDate := ToDate;

                // Add supply for the item itself at destination
                AddSupplyLine(Requirement, TransferLine."Item No.", TransferLine."Transfer-to Code", ReceiptDate, Qty);

                // Add demand for the item itself at source
                ShipmentDate := TransferLine."Shipment Date";
                if ShipmentDate = 0D then
                    ShipmentDate := ReceiptDate;
                AddDemandLine(Requirement, TransferLine."Item No.", TransferLine."Transfer-from Code", ShipmentDate, Qty);

                // If factoring substitutes in inbound: also credit this supply to items that this item substitutes for
                // e.g., if ItemB is a substitute for ItemA, a transfer of ItemB also provides supply coverage for ItemA
                if Setup."Factor Subs in Inbound" then begin
                    Substitution.Reset();
                    Substitution.SetRange("No.", TransferLine."Item No.");  // Find items where this transfer item is listed as a substitute
                    if Substitution.FindSet() then
                        repeat
                            // Supply for the substitute item at destination
                            AddSupplyLine(Requirement, Substitution."Substitute No.", TransferLine."Transfer-to Code", ReceiptDate, Qty);
                        // Note: We don't add demand for substitutes at source - only the actual item being transferred creates demand there
                        until Substitution.Next() = 0;
                end;
            until TransferLine.Next() = 0;
    end;

    local procedure AddDemandLine(var Requirement: Record "WLM Net Requirement"; ItemNo: Code[20]; LocationCode: Code[10]; DemandDate: Date; Quantity: Decimal)
    begin
        if Quantity = 0 then
            exit;
        if not ShouldIncludeItem(ItemNo) then
            exit;
        // Only include demand for planned locations (from WLM Fcst Location with Active = true)
        if not LocationIsPlanned(LocationCode) then
            exit;
        if DemandDate = 0D then
            DemandDate := WorkDate;

        Requirement.Reset();
        if Requirement.Get(ItemNo, LocationCode, DemandDate) then begin
            Requirement."Demand Quantity" := Requirement."Demand Quantity" + Quantity;
            Requirement."Net Quantity" := Requirement."Demand Quantity" - Requirement."Supply Quantity";
            Requirement.Modify();
        end else begin
            Requirement.Init();
            Requirement."Item No." := ItemNo;
            Requirement."Location Code" := LocationCode;
            Requirement."Required Date" := DemandDate;
            Requirement."Demand Quantity" := Quantity;
            Requirement."Supply Quantity" := 0;
            Requirement."Net Quantity" := Quantity;
            Requirement."Running Balance" := 0;
            Requirement."Shortage Date" := 0D;
            Requirement."Priority Score" := 0;
            Requirement.Insert();
        end;
    end;

    local procedure DetermineSalesDemandDate(SalesLine: Record "Sales Line"): Date
    var
        DemandDate: Date;
        SalesHeader: Record "Sales Header";
    begin
        DemandDate := SalesLine."Shipment Date";
        if DemandDate = 0D then
            DemandDate := SalesLine."Planned Shipment Date";
        if DemandDate = 0D then
            DemandDate := SalesLine."Requested Delivery Date";
        if DemandDate = 0D then
            if SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.") then
                DemandDate := SalesHeader."Order Date";
        if DemandDate = 0D then
            DemandDate := WorkDate;
        exit(DemandDate);
    end;

    local procedure AddSupplyLine(var Requirement: Record "WLM Net Requirement"; ItemNo: Code[20]; LocationCode: Code[10]; SupplyDate: Date; Quantity: Decimal)
    begin
        if Quantity = 0 then
            exit;
        if not ShouldIncludeItem(ItemNo) then
            exit;
        // Only include supply for planned locations (from WLM Fcst Location with Active = true)
        if not LocationIsPlanned(LocationCode) then
            exit;
        if SupplyDate = 0D then
            SupplyDate := WorkDate;

        Requirement.Reset();
        if Requirement.Get(ItemNo, LocationCode, SupplyDate) then begin
            Requirement."Supply Quantity" := Requirement."Supply Quantity" + Quantity;
            Requirement."Net Quantity" := Requirement."Demand Quantity" - Requirement."Supply Quantity";
            Requirement.Modify();
        end else begin
            Requirement.Init();
            Requirement."Item No." := ItemNo;
            Requirement."Location Code" := LocationCode;
            Requirement."Required Date" := SupplyDate;
            Requirement."Supply Quantity" := Quantity;
            Requirement."Demand Quantity" := 0;
            Requirement."Net Quantity" := -Quantity;
            Requirement."Running Balance" := 0;
            Requirement."Shortage Date" := 0D;
            Requirement."Priority Score" := 0;
            Requirement.Insert();
        end;
    end;

    local procedure FinalizeNetMetrics(var Requirement: Record "WLM Net Requirement")
    var
        CurrentItem: Code[20];
        CurrentLocation: Code[10];
        Balance: Decimal;
        ShortageDate: Date;
        BelowROPDate: Date;
        ZeroBalanceDate: Date;
        ReorderPoint: Decimal;
        StockoutQty: Decimal;
        ParRebuildQty: Decimal;
        SuggestionQty: Decimal;
    begin
        Requirement.Reset();
        Requirement.SetCurrentKey("Item No.", "Location Code", "Required Date");
        if Requirement.FindSet(true) then
            repeat
                if (Requirement."Item No." <> CurrentItem) or (Requirement."Location Code" <> CurrentLocation) then begin
                    if (CurrentItem <> '') and (CurrentLocation <> '') then
                        StoreLocationBalance(CurrentItem, CurrentLocation, Balance, BelowROPDate <> 0D);

                    CurrentItem := Requirement."Item No.";
                    CurrentLocation := Requirement."Location Code";
                    Balance := 0;
                    ShortageDate := 0D;
                    BelowROPDate := 0D;
                    ZeroBalanceDate := 0D;
                    ReorderPoint := GetReorderPoint(CurrentItem, CurrentLocation);
                end;

                Balance := Balance + Requirement."Supply Quantity" - Requirement."Demand Quantity";
                Requirement."Running Balance" := Balance;
                Requirement."Net Quantity" := Requirement."Demand Quantity" - Requirement."Supply Quantity";

                if (Balance < ReorderPoint) and (BelowROPDate = 0D) then
                    BelowROPDate := Requirement."Required Date";

                if (Balance <= 0) and (ZeroBalanceDate = 0D) then
                    ZeroBalanceDate := Requirement."Required Date";

                if (Balance < 0) and (ShortageDate = 0D) then
                    ShortageDate := Requirement."Required Date";

                Requirement."Shortage Date" := ShortageDate;
                Requirement."Reorder Point" := ReorderPoint;
                Requirement."Below ROP Date" := BelowROPDate;
                Requirement."Zero Balance Date" := ZeroBalanceDate;

                // Calculate urgency level and split quantities
                // Stockout: demand will cause balance to go negative
                // BelowROP: below reorder point but still positive
                // ParStock: rebuilding to par (secondary priority)
                StockoutQty := 0;
                ParRebuildQty := 0;
                SuggestionQty := 0;

                if Balance < 0 then begin
                    // CRITICAL: Balance is negative - stockout situation
                    Requirement."Urgency Level" := Requirement."Urgency Level"::Stockout;
                    StockoutQty := Abs(Balance);
                    ParRebuildQty := ReorderPoint; // Need full ROP after covering stockout
                    SuggestionQty := StockoutQty + ParRebuildQty;
                end else if Balance < ReorderPoint then begin
                    // IMPORTANT: Below reorder point but positive
                    if Balance <= 0 then begin
                        Requirement."Urgency Level" := Requirement."Urgency Level"::Stockout;
                        StockoutQty := Abs(Balance);
                        ParRebuildQty := ReorderPoint;
                        SuggestionQty := StockoutQty + ParRebuildQty;
                    end else begin
                        Requirement."Urgency Level" := Requirement."Urgency Level"::BelowROP;
                        StockoutQty := 0;
                        ParRebuildQty := ReorderPoint - Balance;
                        SuggestionQty := ParRebuildQty;
                    end;
                end else begin
                    // SECONDARY: Above reorder point, just maintaining par
                    Requirement."Urgency Level" := Requirement."Urgency Level"::ParStock;
                    StockoutQty := 0;
                    ParRebuildQty := 0;
                    SuggestionQty := 0;
                end;

                Requirement."Stockout Qty" := StockoutQty;
                Requirement."Par Rebuild Qty" := ParRebuildQty;
                Requirement."Priority Score" := CalculatePriority(Requirement);
                Requirement.Modify();

            // NOTE: Do NOT inflate Balance here with SuggestionQty
            // Running Balance should reflect TRUE supply-demand picture
            // Suggestion tracking is handled by PlannedSupply in GenerateLoadSuggestions
            // which processes chronologically and accumulates planned orders
            until Requirement.Next() = 0;

        if (CurrentItem <> '') and (CurrentLocation <> '') then
            StoreLocationBalance(CurrentItem, CurrentLocation, Balance, BelowROPDate <> 0D);
    end;

    local procedure CalculatePriority(var Requirement: Record "WLM Net Requirement"): Decimal
    var
        DaysUntilDue: Integer;
        Priority: Decimal;
        UrgencyBonus: Decimal;
    begin
        if Requirement."Required Date" = 0D then
            exit(0);

        // Base priority from days until due (sooner = higher priority)
        DaysUntilDue := Requirement."Required Date" - WorkDate;
        if DaysUntilDue <= 0 then
            Priority := 100000  // Overdue gets highest base
        else
            Priority := 100000 - DaysUntilDue;

        // CRITICAL: Urgency level determines major priority tiers
        // This ensures stockout items are ALWAYS prioritized over par stock rebuilding
        case Requirement."Urgency Level" of
            Requirement."Urgency Level"::Stockout:
                begin
                    // Tier 1: Stockout situations get massive priority boost
                    // Balance will go negative - this is critical
                    UrgencyBonus := 500000;
                    // Additional boost based on how severe the stockout is
                    if Requirement."Stockout Qty" > 0 then
                        UrgencyBonus += Requirement."Stockout Qty" * 10;
                end;
            Requirement."Urgency Level"::BelowROP:
                begin
                    // Tier 2: Below reorder point but still positive
                    // Important but not as critical as stockout
                    UrgencyBonus := 200000;
                    // Boost based on how far below ROP
                    if Requirement."Par Rebuild Qty" > 0 then
                        UrgencyBonus += Requirement."Par Rebuild Qty";
                end;
            Requirement."Urgency Level"::ParStock:
                begin
                    // Tier 3: Par stock rebuilding - lowest priority
                    // Only fill loads with these if space available after urgent items
                    UrgencyBonus := 0;
                end;
        end;

        Priority += UrgencyBonus;

        // Legacy bonus for shortage date (kept for compatibility)
        if Requirement."Shortage Date" <> 0D then
            Priority += 1000;

        // Add net quantity to help sort within same urgency tier
        if Requirement."Net Quantity" > 0 then
            Priority += Requirement."Net Quantity";
        exit(Priority);
    end;

    local procedure GenerateLoadSuggestions(var Requirement: Record "WLM Net Requirement"; Handler: Interface "WLM Load Suggestion Handler")
    var
        LoadUnitCode: Code[10];
        UnitsPerSubUnit: Decimal;
        TransferQty: Decimal;
        RemainingQty: Decimal;
        SourceLocation: Code[10];
        VendorNo: Code[20];
        DonorKey: Text[60];
        DonorBalance: Decimal;
        CurrentItem: Code[20];
        CurrentLocation: Code[10];
        RunningAvail: Decimal;
        ReorderFloor: Decimal;
        QtyRequired: Decimal;
        DemandShortfall: Decimal;
        ReorderShortfall: Decimal;
        DemandThisPeriod: Decimal;
        OnHandQty: Decimal;
        InboundQty: Decimal;
        PrevInboundCumulative: Decimal;
        InboundThisPeriod: Decimal;
    begin
        // Calculate FRESH - ignore pre-calculated Running Balance
        // Match Planning Schedule logic exactly
        Clear(VendorCapacityUsage);
        Clear(LoadGroupLookup);
        Clear(LoadGroupSequenceCounters);
        Clear(LoadGroupDisplayOrder);
        Clear(PlannedSupply);
        ClearBucketedShortages();
        ResetPendingSuggestions();

        Requirement.Reset();
        Requirement.SetCurrentKey("Item No.", "Location Code", "Required Date");

        if not Requirement.FindSet() then
            exit;

        CurrentItem := '';
        CurrentLocation := '';

        repeat
            // Reset when item/location changes
            if (Requirement."Item No." <> CurrentItem) or (Requirement."Location Code" <> CurrentLocation) then begin
                CurrentItem := Requirement."Item No.";
                CurrentLocation := Requirement."Location Code";

                // Start with fresh On Hand calculation (like Planning Schedule)
                // Uses CalcOnHand which includes substitute inventory if enabled
                OnHandQty := CalcOnHand(CurrentItem, CurrentLocation);
                RunningAvail := OnHandQty;
                PrevInboundCumulative := 0;

                // Get reorder point for this item/location
                ReorderFloor := GetReorderPoint(CurrentItem, CurrentLocation);
            end;

            // Calculate incremental inbound for this period
            InboundQty := CalcInboundCumulative(CurrentItem, CurrentLocation, Requirement."Required Date");
            InboundThisPeriod := InboundQty - PrevInboundCumulative;
            if InboundThisPeriod < 0 then
                InboundThisPeriod := 0;
            PrevInboundCumulative := InboundQty;

            // Add inbound to running availability
            RunningAvail := RunningAvail + InboundThisPeriod;

            // Get demand for this period (Demand Quantity from the requirement record)
            DemandThisPeriod := Requirement."Demand Quantity";

            // Consume demand from running availability
            DemandShortfall := 0;
            if RunningAvail >= DemandThisPeriod then
                RunningAvail := RunningAvail - DemandThisPeriod
            else begin
                DemandShortfall := DemandThisPeriod - RunningAvail;
                RunningAvail := 0;
            end;

            // Calculate reorder shortfall (how much below par)
            if RunningAvail < ReorderFloor then
                ReorderShortfall := ReorderFloor - RunningAvail
            else
                ReorderShortfall := 0;

            // Total required = demand shortfall + reorder shortfall
            QtyRequired := DemandShortfall + ReorderShortfall;

            // Skip if nothing needed
            if QtyRequired <= 0 then
                continue;

            // CRITICAL: After creating suggestion, reset running availability to par
            // This is the key difference - we assume suggestion will be accepted
            RunningAvail := ReorderFloor;

            GetItemLoadInfo(Requirement."Item No.", LoadUnitCode, UnitsPerSubUnit);

            RemainingQty := QtyRequired;

            // Try transfers first
            repeat
                TransferQty := 0;
                SourceLocation := '';
                if not SelectBestTransferDonor(Requirement."Item No.", Requirement."Location Code", SourceLocation, TransferQty) then
                    break;

                if TransferQty <= 0 then
                    break;

                if TransferQty > RemainingQty then
                    TransferQty := RemainingQty;

                DonorKey := BuildLocationBalanceKey(Requirement."Item No.", SourceLocation);
                if LocationBalances.Get(DonorKey, DonorBalance) then
                    LocationBalances.Set(DonorKey, DonorBalance - TransferQty);

                QueueSuggestion(
                    Requirement,
                    TransferQty,
                    LoadUnitCode,
                    UnitsPerSubUnit,
                    "WLM Load Suggestion Type"::Transfer,
                    SourceLocation,
                    '');

                RemainingQty := RemainingQty - TransferQty;
            until RemainingQty <= 0;

            // Purchase remainder
            if RemainingQty > 0 then begin
                VendorNo := GetPrimaryVendor(Requirement."Item No.");

                QueueSuggestion(
                    Requirement,
                    RemainingQty,
                    LoadUnitCode,
                    UnitsPerSubUnit,
                    "WLM Load Suggestion Type"::Purchase,
                    '',
                    VendorNo);
            end;

        until Requirement.Next() = 0;

        ProcessQueuedSuggestions(Handler);
        FinalizeBatchMetrics();
    end;

    local procedure CalcOnHandSingle(ItemNo: Code[20]; LocationCode: Code[10]): Decimal
    var
        ILE: Record "Item Ledger Entry";
    begin
        // Exact same logic as Planning Schedule
        ILE.Reset();
        ILE.SetRange("Item No.", ItemNo);
        if LocationCode <> '' then
            ILE.SetRange("Location Code", LocationCode);
        ILE.CalcSums(Quantity);
        exit(ILE.Quantity);
    end;

    local procedure CalcOnHand(ItemNo: Code[20]; LocationCode: Code[10]): Decimal
    var
        Setup: Record "WLM FcstSetup";
        SubRec: Record "Item Substitution";
        Seen: Dictionary of [Code[20], Boolean];
        DonorNo: Code[20];
        Qty: Decimal;
    begin
        // Start with the item's own on-hand
        Qty := CalcOnHandSingle(ItemNo, LocationCode);

        // If "Factor Subs in Inventory" is enabled, add inventory from substitute items
        // This matches Planning Schedule's CalcOnHand logic exactly
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

    local procedure CalcInboundCumulative(ItemNo: Code[20]; LocationCode: Code[10]; AsOfDate: Date): Decimal
    var
        PurchLine: Record "Purchase Line";
        TransferLine: Record "Transfer Line";
        TotalInbound: Decimal;
    begin
        TotalInbound := 0;

        if AsOfDate = 0D then
            exit(0);

        // Inbound purchases
        PurchLine.Reset();
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
        PurchLine.SetRange(Type, PurchLine.Type::Item);
        PurchLine.SetRange("No.", ItemNo);
        PurchLine.SetRange("Location Code", LocationCode);
        PurchLine.SetFilter("Expected Receipt Date", '<=%1', AsOfDate);
        PurchLine.SetFilter("Outstanding Quantity", '<>0');
        PurchLine.CalcSums("Outstanding Quantity");
        TotalInbound := TotalInbound + PurchLine."Outstanding Quantity";

        // Inbound transfers
        TransferLine.Reset();
        TransferLine.SetRange("Item No.", ItemNo);
        TransferLine.SetRange("Transfer-to Code", LocationCode);
        TransferLine.SetFilter("Receipt Date", '<=%1', AsOfDate);
        TransferLine.SetFilter("Outstanding Quantity", '<>0');
        TransferLine.CalcSums("Outstanding Quantity");
        TotalInbound := TotalInbound + TransferLine."Outstanding Quantity";

        exit(TotalInbound);
    end;

    local procedure CalcItemLocationOnHand(ItemNo: Code[20]; LocationCode: Code[10]): Decimal
    var
        ILE: Record "Item Ledger Entry";
    begin
        // Use ILE.CalcSums like Planning Schedule does
        ILE.Reset();
        ILE.SetRange("Item No.", ItemNo);
        if LocationCode <> '' then
            ILE.SetRange("Location Code", LocationCode);
        ILE.CalcSums(Quantity);
        exit(ILE.Quantity);
    end;

    local procedure CalcItemLocationInbound(ItemNo: Code[20]; LocationCode: Code[10]; AsOfDate: Date): Decimal
    var
        PurchLine: Record "Purchase Line";
        TransferLine: Record "Transfer Line";
        TotalInbound: Decimal;
    begin
        TotalInbound := 0;

        // Inbound purchases
        PurchLine.Reset();
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
        PurchLine.SetRange(Type, PurchLine.Type::Item);
        PurchLine.SetRange("No.", ItemNo);
        PurchLine.SetRange("Location Code", LocationCode);
        PurchLine.SetFilter("Outstanding Quantity", '<>0');
        if AsOfDate <> 0D then
            PurchLine.SetFilter("Expected Receipt Date", '<=%1', AsOfDate);
        PurchLine.CalcSums("Outstanding Quantity");
        TotalInbound += PurchLine."Outstanding Quantity";

        // Inbound transfers
        TransferLine.Reset();
        TransferLine.SetRange("Item No.", ItemNo);
        TransferLine.SetRange("Transfer-to Code", LocationCode);
        TransferLine.SetFilter("Outstanding Quantity", '<>0');
        if AsOfDate <> 0D then
            TransferLine.SetFilter("Receipt Date", '<=%1', AsOfDate);
        TransferLine.CalcSums("Outstanding Quantity");
        TotalInbound += TransferLine."Outstanding Quantity";

        exit(TotalInbound);
    end;

    local procedure CalcPlanningHorizonEnd(Setup: Record "WLM FcstSetup"; FromDate: Date): Date
    var
        HorizonBuckets: Integer;
        ToDate: Date;
    begin
        HorizonBuckets := Setup."Resource Planning Buckets";
        if HorizonBuckets <= 0 then begin
            ToDate := CalcDate('+3M', FromDate);
            exit(ToDate);
        end;

        case Setup."Default Bucket" of
            Setup."Default Bucket"::Day:
                ToDate := FromDate + (HorizonBuckets - 1);
            Setup."Default Bucket"::Week:
                ToDate := FromDate + (HorizonBuckets * 7) - 1;
            Setup."Default Bucket"::Month:
                begin
                    ToDate := CalcDate(StrSubstNo('+%1M', HorizonBuckets - 1), FromDate);
                    ToDate := CalcDate('<CM>', ToDate);
                end;
        end;
        exit(ToDate);
    end;

    local procedure BuildForecastBuffer(var Buffer: Record "WLM FcstBuffer"; Setup: Record "WLM FcstSetup"; FromDate: Date; ToDate: Date)
    var
        FcstEntry: Record "WLM Forecast Entry";
    begin
        Buffer.Reset();
        Buffer.DeleteAll();

        FcstEntry.Reset();
        if Setup."Default Forecast Name" <> '' then
            FcstEntry.SetRange("Forecast Name", Setup."Default Forecast Name");

        if (FromDate <> 0D) and (ToDate <> 0D) then
            FcstEntry.SetRange("Forecast Date", FromDate, ToDate);

        if FcstEntry.FindSet() then
            repeat
                if Buffer.Get(FcstEntry."Item No.", FcstEntry."Location Code", FcstEntry."Forecast Date") then begin
                    Buffer."Base Qty" += FcstEntry.Quantity;
                    Buffer."Projected Sales" := Buffer."Base Qty";
                    Buffer.Modify();
                end else begin
                    Buffer.Init();
                    Buffer."Item No." := FcstEntry."Item No.";
                    Buffer."Location Code" := FcstEntry."Location Code";
                    Buffer."Bucket Date" := FcstEntry."Forecast Date";
                    Buffer."Base Qty" := FcstEntry.Quantity;
                    Buffer."Projected Sales" := FcstEntry.Quantity;
                    Buffer.Insert();
                end;
            until FcstEntry.Next() = 0;
    end;

    local procedure EnrichForecastBuffer(var Buffer: Record "WLM FcstBuffer")
    var
        ItemRec: Record Item;
        SKU: Record "Stockkeeping Unit";
        VariantCode: Code[10];
        ItemReorder: Decimal;
        SKUReorder: Decimal;
        ParReorder: Decimal;
    begin
        Buffer.Reset();
        if Buffer.FindSet() then
            repeat
                // Get item info
                if ItemRec.Get(Buffer."Item No.") then begin
                    Buffer.Description := CopyStr(ItemRec.Description, 1, MaxStrLen(Buffer.Description));
                    Buffer."Item Category Code" := CopyStr(ItemRec."Item Category Code", 1, MaxStrLen(Buffer."Item Category Code"));
                    Buffer."Vendor No." := CopyStr(ItemRec."Vendor No.", 1, MaxStrLen(Buffer."Vendor No."));
                    ItemReorder := ItemRec."Reorder Point";
                end else
                    ItemReorder := 0;

                // Get SKU reorder point
                // SKU primary key is (Location Code, Item No., Variant Code)
                VariantCode := '';
                if SKU.Get(Buffer."Location Code", Buffer."Item No.", VariantCode) then
                    SKUReorder := SKU."Reorder Point"
                else begin
                    SKU.Reset();
                    SKU.SetRange("Location Code", Buffer."Location Code");
                    SKU.SetRange("Item No.", Buffer."Item No.");
                    if SKU.FindFirst() then
                        SKUReorder := SKU."Reorder Point"
                    else
                        SKUReorder := 0;
                end;

                // Calculate Par reorder point
                ParReorder := CalcParReorderForBuffer(Buffer."Item No.", Buffer."Location Code");

                Buffer."Reorder Point" := ParReorder;
                Buffer."SKU Reorder Point" := SKUReorder;
                if ParReorder > SKUReorder then
                    Buffer."Reorder Point MAX" := ParReorder
                else
                    Buffer."Reorder Point MAX" := SKUReorder;

                // Get on-hand, inbound, open sales
                Buffer."On Hand Qty" := CalcOnHandForBuffer(Buffer."Item No.", Buffer."Location Code");
                Buffer."Reserved Qty" := CalcOpenSalesForBuffer(Buffer."Item No.", Buffer."Location Code", Buffer."Bucket Date");
                CalcInboundForBuffer(Buffer."Item No.", Buffer."Location Code", Buffer."Bucket Date",
                    Buffer."Inbound Arrival - Purchase", Buffer."Inbound Arrival - Transfer");
                Buffer."Inbound Arrivals" := Buffer."Inbound Arrival - Purchase" + Buffer."Inbound Arrival - Transfer";
                Buffer."Open Transfer Demand" := CalcOpenTransferForBuffer(Buffer."Item No.", Buffer."Location Code", Buffer."Bucket Date");

                Buffer.Modify();
            until Buffer.Next() = 0;
    end;

    local procedure CalcRunningAvailAndRequirements(var Buffer: Record "WLM FcstBuffer")
    var
        CurrentItem: Code[20];
        CurrentLoc: Code[10];
        RunningAvail: Decimal;
        ReorderFloor: Decimal;
        DemandShortfall: Decimal;
        ReorderShortfall: Decimal;
        OpenSalesApplied: Decimal;
        TransferDemand: Decimal;
        DemandTotal: Decimal;
        IsFirstBucket: Boolean;
        InboundThisBucket: Decimal;
        PrevInboundCumulative: Decimal;
        ProratedSales: Decimal;
        DaysInMonth: Integer;
        DaysRemaining: Integer;
        BucketMonth: Integer;
        BucketYear: Integer;
        TodayDate: Date;
    begin
        Buffer.Reset();
        Buffer.SetCurrentKey("Item No.", "Location Code", "Bucket Date");

        TodayDate := WorkDate();
        if TodayDate = 0D then
            TodayDate := Today;

        CurrentItem := '';
        CurrentLoc := '';

        if Buffer.FindSet() then
            repeat
                if (Buffer."Item No." <> CurrentItem) or (Buffer."Location Code" <> CurrentLoc) then begin
                    CurrentItem := Buffer."Item No.";
                    CurrentLoc := Buffer."Location Code";
                    RunningAvail := Buffer."On Hand Qty";
                    IsFirstBucket := true;
                    PrevInboundCumulative := 0;
                end;

                // Compute incremental inbound
                InboundThisBucket := Buffer."Inbound Arrivals" - PrevInboundCumulative;
                if InboundThisBucket < 0 then
                    InboundThisBucket := Buffer."Inbound Arrivals";
                PrevInboundCumulative := Buffer."Inbound Arrivals";

                // Update On Hand to show projected inventory BEFORE this period's inbound
                Buffer."On Hand Qty" := RunningAvail;

                // Add inbound to running availability
                RunningAvail += InboundThisBucket;
                if RunningAvail < 0 then
                    RunningAvail := 0;

                // Update inbound to show incremental
                Buffer."Inbound Arrivals" := InboundThisBucket;

                DemandShortfall := 0;
                ReorderShortfall := 0;

                // Open sales only on first bucket
                if IsFirstBucket then
                    OpenSalesApplied := Buffer."Reserved Qty"
                else begin
                    OpenSalesApplied := 0;
                    Buffer."Reserved Qty" := 0;
                end;

                // Prorate current month
                ProratedSales := Buffer."Projected Sales";
                if IsFirstBucket and (Buffer."Bucket Date" <> 0D) then begin
                    BucketMonth := Date2DMY(Buffer."Bucket Date", 2);
                    BucketYear := Date2DMY(Buffer."Bucket Date", 3);
                    if (Date2DMY(TodayDate, 2) = BucketMonth) and (Date2DMY(TodayDate, 3) = BucketYear) then begin
                        DaysInMonth := Date2DMY(CalcDate('<CM>', Buffer."Bucket Date"), 1);
                        DaysRemaining := DaysInMonth - Date2DMY(TodayDate, 1) + 1;
                        if (DaysInMonth > 0) and (DaysRemaining > 0) then
                            ProratedSales := Round(Buffer."Projected Sales" * (DaysRemaining / DaysInMonth), 1);
                    end;
                end;

                TransferDemand := Buffer."Open Transfer Demand";
                DemandTotal := ProratedSales + TransferDemand + OpenSalesApplied;

                Buffer."Projected Sales" := ProratedSales;

                // Consume demand
                if RunningAvail >= DemandTotal then
                    RunningAvail -= DemandTotal
                else begin
                    DemandShortfall := DemandTotal - RunningAvail;
                    RunningAvail := 0;
                end;

                IsFirstBucket := false;

                // Calculate reorder shortfall
                ReorderFloor := Buffer."Reorder Point MAX";
                if RunningAvail < ReorderFloor then
                    ReorderShortfall := ReorderFloor - RunningAvail
                else
                    ReorderShortfall := 0;

                Buffer."Qty Required" := DemandShortfall + ReorderShortfall;

                // After suggestion, reset to par
                if Buffer."Qty Required" > 0 then
                    RunningAvail := ReorderFloor;

                Buffer.Modify();
            until Buffer.Next() = 0;
    end;

    local procedure GenerateSuggestionsFromBuffer(var Buffer: Record "WLM FcstBuffer"; Handler: Interface "WLM Load Suggestion Handler")
    var
        TempReq: Record "WLM Net Requirement" temporary;
        LoadUnitCode: Code[10];
        UnitsPerSubUnit: Decimal;
        RemainingQty: Decimal;
        TransferQty: Decimal;
        SourceLocation: Code[10];
        VendorNo: Code[20];
        DonorKey: Text[60];
        DonorBalance: Decimal;
    begin
        // Convert buffer to temporary requirement record format for QueueSuggestion compatibility
        Buffer.Reset();
        if Buffer.FindSet() then
            repeat
                if Buffer."Qty Required" <= 0 then
                    continue;

                // Build a temporary requirement record
                TempReq.Init();
                TempReq."Item No." := Buffer."Item No.";
                TempReq."Location Code" := Buffer."Location Code";
                TempReq."Required Date" := Buffer."Bucket Date";
                TempReq."Reorder Point" := Buffer."Reorder Point MAX";
                TempReq."Demand Quantity" := Buffer."Projected Sales" + Buffer."Reserved Qty" + Buffer."Open Transfer Demand";
                TempReq."Supply Quantity" := Buffer."On Hand Qty" + Buffer."Inbound Arrivals";
                TempReq."Running Balance" := Buffer."On Hand Qty" - Buffer."Qty Required";

                GetItemLoadInfo(Buffer."Item No.", LoadUnitCode, UnitsPerSubUnit);

                RemainingQty := Buffer."Qty Required";

                // Try transfers first
                repeat
                    TransferQty := 0;
                    SourceLocation := '';
                    if not SelectBestTransferDonor(Buffer."Item No.", Buffer."Location Code", SourceLocation, TransferQty) then
                        break;

                    if TransferQty <= 0 then
                        break;

                    if TransferQty > RemainingQty then
                        TransferQty := RemainingQty;

                    DonorKey := BuildLocationBalanceKey(Buffer."Item No.", SourceLocation);
                    if LocationBalances.Get(DonorKey, DonorBalance) then
                        LocationBalances.Set(DonorKey, DonorBalance - TransferQty);

                    QueueSuggestion(
                        TempReq,
                        TransferQty,
                        LoadUnitCode,
                        UnitsPerSubUnit,
                        "WLM Load Suggestion Type"::Transfer,
                        SourceLocation,
                        '');

                    RemainingQty -= TransferQty;
                until RemainingQty <= 0;

                // Purchase remainder
                if RemainingQty > 0 then begin
                    VendorNo := GetPrimaryVendor(Buffer."Item No.");

                    QueueSuggestion(
                        TempReq,
                        RemainingQty,
                        LoadUnitCode,
                        UnitsPerSubUnit,
                        "WLM Load Suggestion Type"::Purchase,
                        '',
                        VendorNo);
                end;
            until Buffer.Next() = 0;
    end;

    local procedure CalcParReorderForBuffer(ItemNo: Code[20]; LocationCode: Code[10]): Decimal
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
        // Identical to WLM Planning Schedule's ComputeParReorderPoint
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
        exit(Round(AvgMonthly * ParMonths, 1, '>'));
    end;

    local procedure CalcOnHandForBuffer(ItemNo: Code[20]; LocationCode: Code[10]): Decimal
    var
        Item: Record Item;
    begin
        Item.Reset();
        Item.SetRange("No.", ItemNo);
        Item.SetRange("Location Filter", LocationCode);
        Item.CalcFields(Inventory);
        exit(Item.Inventory);
    end;

    local procedure CalcOpenSalesForBuffer(ItemNo: Code[20]; LocationCode: Code[10]; BeforeDate: Date): Decimal
    var
        SalesLine: Record "Sales Line";
        TotalQty: Decimal;
    begin
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetRange("No.", ItemNo);
        SalesLine.SetRange("Location Code", LocationCode);
        SalesLine.SetFilter("Outstanding Quantity", '<>0');
        SalesLine.CalcSums("Outstanding Quantity");
        exit(SalesLine."Outstanding Quantity");
    end;

    local procedure CalcInboundForBuffer(ItemNo: Code[20]; LocationCode: Code[10]; BeforeDate: Date; var PurchaseQty: Decimal; var TransferQty: Decimal)
    var
        PurchLine: Record "Purchase Line";
        TransferLine: Record "Transfer Line";
    begin
        PurchaseQty := 0;
        TransferQty := 0;

        PurchLine.Reset();
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
        PurchLine.SetRange(Type, PurchLine.Type::Item);
        PurchLine.SetRange("No.", ItemNo);
        PurchLine.SetRange("Location Code", LocationCode);
        PurchLine.SetFilter("Outstanding Quantity", '<>0');
        if BeforeDate <> 0D then
            PurchLine.SetFilter("Expected Receipt Date", '<=%1', BeforeDate);
        PurchLine.CalcSums("Outstanding Quantity");
        PurchaseQty := PurchLine."Outstanding Quantity";

        TransferLine.Reset();
        TransferLine.SetRange("Item No.", ItemNo);
        TransferLine.SetRange("Transfer-to Code", LocationCode);
        TransferLine.SetFilter("Outstanding Quantity", '<>0');
        if BeforeDate <> 0D then
            TransferLine.SetFilter("Receipt Date", '<=%1', BeforeDate);
        TransferLine.CalcSums("Outstanding Quantity");
        TransferQty := TransferLine."Outstanding Quantity";
    end;

    local procedure CalcOpenTransferForBuffer(ItemNo: Code[20]; LocationCode: Code[10]; BeforeDate: Date): Decimal
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.Reset();
        TransferLine.SetRange("Item No.", ItemNo);
        TransferLine.SetRange("Transfer-from Code", LocationCode);
        TransferLine.SetFilter("Outstanding Quantity", '<>0');
        if BeforeDate <> 0D then
            TransferLine.SetFilter("Shipment Date", '<=%1', BeforeDate);
        TransferLine.CalcSums("Outstanding Quantity");
        exit(TransferLine."Outstanding Quantity");
    end;

    local procedure FinalizeBatchMetrics()
    var
        LoadBatch: Record "WLM Load Batch";
        LoadSuggestion: Record "WLM Load Suggestion";
        MaxPriority: Decimal;
        FillPercent: Decimal;
        TotalSubUnits: Decimal;
        BatchPriorityOrder: Integer;
        PriorityList: List of [Decimal];
        BatchList: List of [Guid];
        i: Integer;
        BatchId: Guid;
        Capacity: Decimal;
        EarliestReqPeriod: Text[10];
        MaxUrgency: Integer;
        CurrentUrgency: Integer;
        ContainersNeeded: Decimal;
        DimensionalContainers: Decimal;
        WeightContainers: Decimal;
        TotalCapacity: Decimal;
        TotalWeight: Decimal;
        MaxWeight: Decimal;
        ItemWeight: Decimal;
        ExpectedReceiptDate: Date;
        ItemLeadTime: Integer;
        ItemCapacity: Decimal;
        TotalFillContribution: Decimal;
    begin
        // First pass: Calculate fill %, total weight, expected receipt date and get priority components for each batch
        LoadBatch.Reset();
        if LoadBatch.FindSet() then
            repeat
                // Sum total sub units from all suggestions in this batch
                TotalSubUnits := 0;
                TotalWeight := 0;
                TotalFillContribution := 0;
                EarliestReqPeriod := 'Z';
                MaxUrgency := 0; // Will track highest urgency in batch (0=ParStock, 1=BelowROP, 2=Stockout)
                ExpectedReceiptDate := 0D;

                LoadSuggestion.Reset();
                LoadSuggestion.SetRange("Load Group ID", LoadBatch."Load Group ID");
                if LoadSuggestion.FindSet() then
                    repeat
                        TotalSubUnits += LoadSuggestion."Sub Units";

                        // Calculate this item's fill contribution based on its specific capacity
                        // Each item takes up (Sub Units / Item's Units Per Parent) of a container
                        ItemCapacity := CalculateUnitsPerParent(LoadBatch."Parent Load Unit Code", LoadSuggestion."Item No.");
                        if ItemCapacity > 0 then
                            TotalFillContribution += LoadSuggestion."Sub Units" / ItemCapacity;

                        // Calculate weight contribution - use WLM Item Loading Unit weight (same as bin-packing)
                        ItemWeight := GetItemUnitWeight(LoadSuggestion."Item No.");
                        TotalWeight += LoadSuggestion."Sub Units" * ItemWeight;

                        // Track earliest requirement period for priority
                        if LoadSuggestion."Requirement Period" < EarliestReqPeriod then
                            EarliestReqPeriod := LoadSuggestion."Requirement Period";

                        // Track highest urgency level in batch (Option is stored as integer: 0=ParStock, 1=BelowROP, 2=Stockout)
                        CurrentUrgency := LoadSuggestion."Urgency Level";
                        if CurrentUrgency > MaxUrgency then
                            MaxUrgency := CurrentUrgency;

                        // Calculate expected receipt date based on longest lead time
                        ItemLeadTime := GetItemLeadTimeDays(LoadSuggestion."Item No.", LoadBatch."Vendor No.", LoadSuggestion."Location Code");
                        if CalcDate(StrSubstNo('+%1D', ItemLeadTime), WorkDate) > ExpectedReceiptDate then
                            ExpectedReceiptDate := CalcDate(StrSubstNo('+%1D', ItemLeadTime), WorkDate);
                    until LoadSuggestion.Next() = 0;

                // Get capacity for batch - use Parent Unit Capacity if set
                Capacity := LoadBatch."Parent Unit Capacity";
                if Capacity <= 0 then begin
                    // Try to derive from first item's fit profile
                    LoadSuggestion.Reset();
                    LoadSuggestion.SetRange("Load Group ID", LoadBatch."Load Group ID");
                    if LoadSuggestion.FindFirst() then begin
                        Capacity := CalculateUnitsPerParent(LoadBatch."Parent Load Unit Code", LoadSuggestion."Item No.");
                        if Capacity > 0 then
                            LoadBatch."Parent Unit Capacity" := Capacity;
                    end;
                end;

                // Calculate Fill % using weighted contribution from each item
                // TotalFillContribution = sum of (Item Sub Units / Item Capacity) for all items
                // This represents how many containers worth of space is used
                // Fill % = (TotalFillContribution / Containers Needed) × 100
                // ContainersNeeded = MAX(dimensional containers, weight-based containers)

                // Calculate dimensional containers (based on volume/units)
                DimensionalContainers := 0;
                if TotalFillContribution > 0 then begin
                    DimensionalContainers := ROUND(TotalFillContribution, 1, '>');
                    if DimensionalContainers < 1 then
                        DimensionalContainers := 1;
                end;

                // Calculate weight-based containers
                WeightContainers := 0;
                MaxWeight := GetParentLoadUnitMaxWeight(LoadBatch."Parent Load Unit Code");
                if (MaxWeight > 0) and (TotalWeight > 0) then begin
                    WeightContainers := ROUND(TotalWeight / MaxWeight, 1, '>');
                    if WeightContainers < 1 then
                        WeightContainers := 1;
                end;

                // Use the larger of dimensional or weight-based containers
                // This ensures we don't exceed EITHER capacity constraint
                ContainersNeeded := DimensionalContainers;
                if WeightContainers > ContainersNeeded then
                    ContainersNeeded := WeightContainers;

                if ContainersNeeded > 0 then begin
                    FillPercent := (TotalFillContribution / ContainersNeeded) * 100;
                    // Update Parent Units Planned to reflect actual containers needed
                    LoadBatch."Parent Units Planned" := ContainersNeeded;
                end else if TotalSubUnits > 0 then begin
                    FillPercent := 100;
                    if LoadBatch."Parent Units Planned" < 1 then
                        LoadBatch."Parent Units Planned" := 1;
                end else
                    FillPercent := 0;

                // Cap at 100%
                if FillPercent > 100 then
                    FillPercent := 100;

                // Calculate batch priority score:
                // Primary: Requirement Period (earlier = higher priority)
                // Secondary: Urgency Level (Stockout > BelowROP > ParStock)
                // Formula: Base from period (alphabetically earlier = higher) + Urgency Bonus
                // Use negative period comparison so earlier periods get higher scores
                MaxPriority := CalculateBatchPriorityScore(EarliestReqPeriod, MaxUrgency);

                // Store in lists for sorting
                PriorityList.Add(MaxPriority);
                BatchList.Add(LoadBatch."Load Group ID");

                // ENFORCE: No batch can exceed max weight
                if (MaxWeight > 0) and (TotalWeight > MaxWeight) then begin
                    Error('Batch %1 exceeds max weight! Total: %2, Max: %3. Please check item weights and packing logic.', LoadBatch."Load Group ID", Format(TotalWeight), Format(MaxWeight));
                end;

                // Update batch metrics
                LoadBatch."Load Fill Percent" := FillPercent;
                LoadBatch."Total Weight" := TotalWeight;
                LoadBatch."Expected Receipt Date" := ExpectedReceiptDate;
                LoadBatch.Modify();
            until LoadBatch.Next() = 0;

        // Second pass: Assign batch priority order (1 = highest priority batch)
        // Higher priority score = higher priority = lower batch number
        BatchPriorityOrder := 0;
        while BatchList.Count > 0 do begin
            // Find batch with highest priority score
            MaxPriority := -999999999;
            BatchId := CreateGuid();
            for i := 1 to PriorityList.Count do begin
                if PriorityList.Get(i) > MaxPriority then begin
                    MaxPriority := PriorityList.Get(i);
                    BatchId := BatchList.Get(i);
                end;
            end;

            // Assign priority order
            BatchPriorityOrder += 1;
            if LoadBatch.Get(BatchId) then begin
                LoadBatch."Batch Priority" := BatchPriorityOrder;
                LoadBatch.Modify();
            end;

            // Remove from lists
            for i := 1 to BatchList.Count do begin
                if BatchList.Get(i) = BatchId then begin
                    BatchList.RemoveAt(i);
                    PriorityList.RemoveAt(i);
                    break;
                end;
            end;
        end;

        // Note: We do NOT delete underfilled batches - the demand is real and needs planning.
        // Underfilled batches indicate that more demand should be pulled in from adjacent periods
        // or the user should manually decide whether to proceed with a partial load.
    end;

    local procedure GetDefaultMinFillPercent(): Decimal
    var
        Setup: Record "WLM FcstSetup";
    begin
        EnsureSetup(Setup);
        exit(Setup."Default Min Fill Percent");
    end;

    local procedure CalculateBatchPriorityScore(ReqPeriod: Text[10]; MaxUrgency: Integer): Decimal
    var
        PeriodScore: Decimal;
        UrgencyBonus: Decimal;
        YearPart: Integer;
        MonthPart: Integer;
    begin
        // Convert period (YYYY-MM) to numeric score where earlier = higher
        // Base year 2040, so 2026-01 -> (2040-2026)*12 + (12-1) = 179
        // 2026-03 -> (2040-2026)*12 + (12-3) = 177
        // This way earlier periods get higher scores
        if StrLen(ReqPeriod) >= 7 then begin
            if Evaluate(YearPart, CopyStr(ReqPeriod, 1, 4)) then
                if Evaluate(MonthPart, CopyStr(ReqPeriod, 6, 2)) then
                    PeriodScore := ((2040 - YearPart) * 12) + (12 - MonthPart);
        end;

        // Scale period score to be the primary factor (multiply by 1000)
        PeriodScore := PeriodScore * 1000;

        // Add urgency bonus as secondary factor
        // MaxUrgency: 0=ParStock, 1=BelowROP, 2=Stockout
        case MaxUrgency of
            2: // Stockout
                UrgencyBonus := 500;
            1: // BelowROP
                UrgencyBonus := 200;
            0: // ParStock
                UrgencyBonus := 50;
            else
                UrgencyBonus := 0;
        end;

        exit(PeriodScore + UrgencyBonus);
    end;

    local procedure QueueSuggestion(var Requirement: Record "WLM Net Requirement";
                                    Quantity: Decimal;
                                    LoadUnitCode: Code[10];
                                    UnitsPerSubUnit: Decimal;
                                    SuggestionType: Enum "WLM Load Suggestion Type";
                                                        SourceLocation: Code[10];
                                                        SourceVendorNo: Code[20])
    var
        SubUnitsNeeded: Decimal;
        ParentUnitsNeeded: Decimal;
        ReleaseDate: Date;
        BucketKey: Text[250];
        EntryNo: Integer;
        ReqMonth: Integer;
        ReqYear: Integer;
        ReqPeriod: Text[10];
        PctOfParent: Decimal;
        DaysUntil: Integer;
        MonthRank: Integer;
        CurrentMonth: Integer;
        CurrentYear: Integer;
        ParentCapacity: Decimal;
    begin
        if Quantity <= 0 then
            exit;

        SubUnitsNeeded := CalculateSubUnits(Quantity, UnitsPerSubUnit, Requirement."Item No.");
        if SubUnitsNeeded <= 0 then
            exit;

        ParentUnitsNeeded := CalculateParentUnits(SubUnitsNeeded, LoadUnitCode, Requirement."Item No.");
        if ParentUnitsNeeded <= 0 then
            exit;

        ReleaseDate := DetermineReleaseDate(Requirement."Required Date", SuggestionType, Requirement."Item No.");

        // Use REQUIREMENT date for bucket grouping (items needed in same month ship together)
        // Release date is only for when to place the order, not which container items go in
        BucketKey := GetBucketKey(SuggestionType, Requirement."Location Code", SourceLocation, SourceVendorNo, Requirement."Required Date");

        EnsureBucketProfileMetadata(BucketKey, SuggestionType, Requirement."Location Code", SourceLocation, SourceVendorNo, Requirement."Item No.");
        AddBucketContribution(BucketKey, SubUnitsNeeded, ParentUnitsNeeded, Requirement."Item No.");

        // Calculate requirement period fields for month-based grouping
        ReqMonth := Date2DMY(Requirement."Required Date", 2);
        ReqYear := Date2DMY(Requirement."Required Date", 3);
        // Zero-pad month properly (1 -> '01', 12 -> '12')
        if ReqMonth < 10 then
            ReqPeriod := StrSubstNo('%1-0%2', Format(ReqYear, 4), Format(ReqMonth))
        else
            ReqPeriod := StrSubstNo('%1-%2', Format(ReqYear, 4), Format(ReqMonth));

        // Calculate % of parent unit (similar to Planning Schedule)
        ParentCapacity := CalculateUnitsPerParent(LoadUnitCode, Requirement."Item No.");
        if ParentCapacity > 0 then
            PctOfParent := SubUnitsNeeded / ParentCapacity
        else
            PctOfParent := 0;

        // Calculate days until required for urgency scoring
        if Requirement."Required Date" <> 0D then
            DaysUntil := Requirement."Required Date" - WorkDate
        else
            DaysUntil := 0;
        if DaysUntil < 0 then
            DaysUntil := 0;

        // Calculate month priority rank (1 = current month = highest priority)
        CurrentMonth := Date2DMY(WorkDate, 2);
        CurrentYear := Date2DMY(WorkDate, 3);
        MonthRank := ((ReqYear - CurrentYear) * 12) + (ReqMonth - CurrentMonth) + 1;
        if MonthRank < 1 then
            MonthRank := 1;

        EntryNo := GetNextPendingEntryNo();
        PendingSuggestions.Init();
        PendingSuggestions."Entry No." := EntryNo;
        PendingSuggestions."Item No." := Requirement."Item No.";
        PendingSuggestions."Location Code" := Requirement."Location Code";
        PendingSuggestions."Required Date" := Requirement."Required Date";
        PendingSuggestions."Load Unit Code" := LoadUnitCode;
        // Sub Units = Base Qty Required (the actual pieces being planned)
        // This ensures Total Units roll-up reflects actual demand, not inflated order multiples
        PendingSuggestions."Sub Units" := Quantity;
        PendingSuggestions."Parent Units" := ParentUnitsNeeded;
        PendingSuggestions."Priority Score" := Requirement."Priority Score";
        PendingSuggestions."Shortage Date" := Requirement."Shortage Date";
        PendingSuggestions."Suggestion Type" := SuggestionType;
        PendingSuggestions."Source Location Code" := SourceLocation;
        PendingSuggestions."Source Vendor No." := SourceVendorNo;
        PendingSuggestions."Release Date" := ReleaseDate;
        PendingSuggestions."Requirement Month" := ReqMonth;
        PendingSuggestions."Requirement Year" := ReqYear;
        PendingSuggestions."Requirement Period" := CopyStr(ReqPeriod, 1, 10);
        PendingSuggestions."Pct of Parent Unit" := PctOfParent;
        PendingSuggestions."Base Qty Required" := Quantity;
        PendingSuggestions."Days Until Required" := DaysUntil;
        PendingSuggestions."Month Priority Rank" := MonthRank;
        PendingSuggestions."Urgency Level" := Requirement."Urgency Level";
        PendingSuggestions."Stockout Qty" := Requirement."Stockout Qty";
        PendingSuggestions."Par Rebuild Qty" := Requirement."Par Rebuild Qty";
        PendingSuggestions.Status := PendingSuggestions.Status::Open;
        PendingSuggestions.Insert();

        RecordPendingBucketKey(EntryNo, BucketKey);
    end;

    local procedure ProcessQueuedSuggestions(Handler: Interface "WLM Load Suggestion Handler")
    var
        BucketKey: Text[250];
        BucketKeys: List of [Text];
        i: Integer;
    begin
        // First: merge buckets from adjacent periods if underfilled
        ConsolidateAdjacentPeriods();

        // Second: merge underfilled buckets with same routing to reach minimum fill
        ConsolidateUnderfilledBuckets();

        EvaluateBucketReleaseRules();

        // NEW: Process suggestions using proper bin-packing that respects weight AND fill
        // Collect all unique bucket keys
        CollectUniqueBucketKeys(BucketKeys);

        // Process each bucket with proper constraint-aware packing
        for i := 1 to BucketKeys.Count do begin
            BucketKey := CopyStr(BucketKeys.Get(i), 1, 250);
            if BucketReadyForRelease(BucketKey) then
                PackBucketIntoBatches(BucketKey, Handler);
        end;
    end;

    local procedure PackBucketIntoBatches(BucketKey: Text[250]; Handler: Interface "WLM Load Suggestion Handler")
    var
        BucketItems: Record "WLM Load Suggestion" temporary;
        ProcessedItems: List of [Integer];
        ParentLoadUnitCode: Code[10];
        MaxWeight: Decimal;
        MaxCapacity: Decimal;
        MinFillPct: Decimal;
        CurrentBatchWeight: Decimal;
        CurrentBatchFill: Decimal;
        ItemWeight: Decimal;
        ItemFill: Decimal;
        ItemCapacity: Decimal;
        BatchWaveIndex: Integer;
        LoadGroupId: Guid;
        ProposedDocNo: Text[30];
        ReleaseDate: Date;
        BucketPeriodDate: Date;
        SuggType: Enum "WLM Load Suggestion Type";
        DestLoc: Code[10];
        SourceLoc: Code[10];
        VendorNo: Code[20];
        BatchCount: Integer;
        AddedAnyItem: Boolean;
        TotalItems: Integer;
        ProcessedCount: Integer;
        EntryNo: Integer;
        Profile: Record "WLM Load Profile";
        ProfileMatchSource: Text[30];
    begin
        // Get bucket configuration
        if not BucketParentLoadUnitCodes.Get(BucketKey, ParentLoadUnitCode) then
            ParentLoadUnitCode := '';

        MaxWeight := GetParentLoadUnitMaxWeight(ParentLoadUnitCode);

        // If no max weight from bucket config, try to get it from the profile
        // This handles cases where bucket metadata wasn't fully initialized
        if MaxWeight = 0 then begin
            // We'll resolve the profile after we know the suggestion type and routing
            // For now, mark that we need to resolve it later
            ParentLoadUnitCode := '';
        end;

        if not BucketParentCapacity.Get(BucketKey, MaxCapacity) then
            MaxCapacity := 0;
        if not BucketMinFillPercent.Get(BucketKey, MinFillPct) then
            MinFillPct := 0;

        // Convert fill % to decimal (80% -> 0.80)
        MinFillPct := MinFillPct / 100;
        if MinFillPct <= 0 then
            MinFillPct := 0; // No minimum fill requirement

        // Collect all items for this bucket
        BucketItems.Reset();
        BucketItems.DeleteAll();
        PendingSuggestions.Reset();
        if PendingSuggestions.FindSet() then
            repeat
                if GetPendingBucketKey(PendingSuggestions."Entry No.") = BucketKey then begin
                    BucketItems := PendingSuggestions;
                    BucketItems.Insert();
                end;
            until PendingSuggestions.Next() = 0;

        if BucketItems.IsEmpty() then
            exit;

        // Get routing info from first item
        BucketItems.FindFirst();
        SuggType := BucketItems."Suggestion Type";
        DestLoc := BucketItems."Location Code";
        SourceLoc := BucketItems."Source Location Code";
        VendorNo := BucketItems."Source Vendor No.";
        ReleaseDate := BucketItems."Release Date";
        BucketPeriodDate := GetDateFromBucketKey(BucketKey);
        if BucketPeriodDate = 0D then
            BucketPeriodDate := BucketItems."Required Date";

        // CRITICAL: If we don't have MaxWeight yet, resolve profile now that we know routing
        if MaxWeight = 0 then begin
            if ResolveLoadProfile(SuggType, DestLoc, SourceLoc, VendorNo, Profile, ProfileMatchSource) then begin
                if Profile."Parent Load Unit Code" <> '' then begin
                    ParentLoadUnitCode := Profile."Parent Load Unit Code";
                    MaxWeight := GetParentLoadUnitMaxWeight(ParentLoadUnitCode);
                end;
            end;
        end;

        // First pass: Split any items that individually exceed weight limit
        if MaxWeight > 0 then
            SplitOversizedItems(BucketItems, MaxWeight, ParentLoadUnitCode);

        // Count total items to process
        TotalItems := BucketItems.Count();
        Clear(ProcessedItems);
        BatchCount := 0;

        // Pack items into batches using First Fit Decreasing approach
        while ProcessedItems.Count < TotalItems do begin
            BatchCount += 1;
            BatchWaveIndex := BatchCount;
            CurrentBatchWeight := 0;
            CurrentBatchFill := 0;
            AddedAnyItem := false;

            // Create new batch/load group for this wave
            LoadGroupId := AssignLoadGroup(SuggType, DestLoc, SourceLoc, VendorNo, BucketPeriodDate, BatchWaveIndex);
            ProposedDocNo := EnsureLoadBatch(
                LoadGroupId, SuggType, DestLoc, SourceLoc, VendorNo,
                BucketPeriodDate, ReleaseDate, ParentLoadUnitCode, 1);

            // Try to add unprocessed items to this batch
            BucketItems.Reset();
            if BucketItems.FindSet() then
                repeat
                    EntryNo := BucketItems."Entry No.";

                    // Skip already processed items
                    if not ProcessedItems.Contains(EntryNo) then begin
                        // Calculate item's weight and fill contribution
                        ItemWeight := GetItemTotalWeight(BucketItems."Item No.", BucketItems."Sub Units");
                        ItemCapacity := CalculateUnitsPerParent(ParentLoadUnitCode, BucketItems."Item No.");
                        if ItemCapacity > 0 then
                            ItemFill := BucketItems."Sub Units" / ItemCapacity
                        else
                            ItemFill := 1; // Assume fills one container if no capacity info

                        // CRITICAL: If item has no weight data but has dimensional data,
                        // calculate an effective weight based on fill proportion
                        // This ensures items without weight are still constrained by container limits
                        if (ItemWeight = 0) and (ItemFill > 0) and (MaxWeight > 0) then
                            ItemWeight := ItemFill * MaxWeight;

                        // Check if this item can fit in current batch
                        if CanAddItemToBatch(CurrentBatchWeight, ItemWeight, MaxWeight,
                                             CurrentBatchFill, ItemFill) then begin
                            // Add item to current batch
                            CurrentBatchWeight += ItemWeight;
                            CurrentBatchFill += ItemFill;

                            // Emit the suggestion with this batch's LoadGroupId
                            EmitPackedSuggestion(BucketItems, Handler, ReleaseDate, LoadGroupId, ProposedDocNo, ParentLoadUnitCode);

                            // Mark as processed
                            ProcessedItems.Add(EntryNo);
                            AddedAnyItem := true;
                        end;
                    end;
                until BucketItems.Next() = 0;

            // Safety: if no item was added, force add the first unprocessed item
            // This prevents infinite loops when an item exceeds limits on its own
            if not AddedAnyItem then begin
                BucketItems.Reset();
                if BucketItems.FindSet() then
                    repeat
                        EntryNo := BucketItems."Entry No.";
                        if not ProcessedItems.Contains(EntryNo) then begin
                            EmitPackedSuggestion(BucketItems, Handler, ReleaseDate, LoadGroupId, ProposedDocNo, ParentLoadUnitCode);
                            ProcessedItems.Add(EntryNo);
                            // Only add one item to force progress
                            break;
                        end;
                    until BucketItems.Next() = 0;
            end;

            // Emergency exit to prevent infinite loop
            if BatchCount > 1000 then begin
                // Force all remaining items into last batch
                BucketItems.Reset();
                if BucketItems.FindSet() then
                    repeat
                        EntryNo := BucketItems."Entry No.";
                        if not ProcessedItems.Contains(EntryNo) then begin
                            EmitPackedSuggestion(BucketItems, Handler, ReleaseDate, LoadGroupId, ProposedDocNo, ParentLoadUnitCode);
                            ProcessedItems.Add(EntryNo);
                        end;
                    until BucketItems.Next() = 0;
                exit;
            end;
        end;
    end;

    local procedure CanAddItemToBatch(CurrentWeight: Decimal; ItemWeight: Decimal; MaxWeight: Decimal;
                                      CurrentFill: Decimal; ItemFill: Decimal): Boolean
    var
        NewWeight: Decimal;
        ContainersNeededByWeight: Decimal;
        ContainersNeededByFill: Decimal;
        MaxContainersPerBatch: Integer;
    begin
        // If batch is empty, always accept first item (even if it exceeds limits on its own)
        if (CurrentWeight = 0) and (CurrentFill = 0) then
            exit(true);

        NewWeight := CurrentWeight + ItemWeight;

        // For ocean shipments, allow multiple containers per batch
        // But each batch should represent one container's worth of constraints
        // Key rule: batch weight must not exceed MaxWeight of ONE container
        if (MaxWeight > 0) and (NewWeight > MaxWeight) then
            exit(false);

        // For fill: allow accumulation beyond 1.0 since batch can have multiple containers
        // But limit to prevent batches from getting too large (e.g., max 2 containers worth)
        MaxContainersPerBatch := 1; // One container per batch for clean weight enforcement
        if (CurrentFill + ItemFill) > MaxContainersPerBatch then
            exit(false);

        exit(true);
    end;

    local procedure SplitOversizedItems(var BucketItems: Record "WLM Load Suggestion" temporary; MaxWeight: Decimal; ParentLoadUnitCode: Code[10])
    var
        ItemsToSplit: Record "WLM Load Suggestion" temporary;
        NewItem: Record "WLM Load Suggestion" temporary;
        ItemTotalWeight: Decimal;
        ItemFill: Decimal;
        ItemCapacity: Decimal;
        UnitWeight: Decimal;
        MaxUnitsPerBatch: Decimal;
        RemainingUnits: Decimal;
        ChunkUnits: Decimal;
        NextEntryNo: Integer;
        ChunksNeeded: Integer;
    begin
        // Find items that exceed weight limit
        ItemsToSplit.Reset();
        ItemsToSplit.DeleteAll();

        BucketItems.Reset();
        if BucketItems.FindSet() then
            repeat
                ItemTotalWeight := GetItemTotalWeight(BucketItems."Item No.", BucketItems."Sub Units");

                // If no weight data, calculate effective weight from dimensional fill
                if ItemTotalWeight = 0 then begin
                    ItemCapacity := CalculateUnitsPerParent(ParentLoadUnitCode, BucketItems."Item No.");
                    if ItemCapacity > 0 then
                        ItemFill := BucketItems."Sub Units" / ItemCapacity
                    else
                        ItemFill := 1;
                    ItemTotalWeight := ItemFill * MaxWeight;
                end;

                if ItemTotalWeight > MaxWeight then begin
                    ItemsToSplit := BucketItems;
                    ItemsToSplit.Insert();
                end;
            until BucketItems.Next() = 0;

        // Get next available entry no
        NextEntryNo := 900000000;
        BucketItems.Reset();
        if BucketItems.FindLast() then
            NextEntryNo := BucketItems."Entry No." + 1;

        // Split oversized items
        if ItemsToSplit.FindSet() then
            repeat
                // Get the item's total weight for calculation
                ItemTotalWeight := GetItemTotalWeight(ItemsToSplit."Item No.", ItemsToSplit."Sub Units");

                // If no weight data, calculate effective weight from dimensional fill
                if ItemTotalWeight <= 0 then begin
                    ItemCapacity := CalculateUnitsPerParent(ParentLoadUnitCode, ItemsToSplit."Item No.");
                    if ItemCapacity > 0 then
                        ItemFill := ItemsToSplit."Sub Units" / ItemCapacity
                    else
                        ItemFill := 1;
                    ItemTotalWeight := ItemFill * MaxWeight;
                end;

                if ItemTotalWeight <= 0 then
                    ItemTotalWeight := MaxWeight + 1; // Force at least one split

                UnitWeight := GetItemUnitWeight(ItemsToSplit."Item No.");

                // Calculate max units per batch
                // If we have unit weight, use it directly
                // Otherwise, calculate proportionally from total weight/fill
                if UnitWeight > 0 then begin
                    // Use 95% of max weight for safety margin
                    MaxUnitsPerBatch := ROUND((MaxWeight * 0.95) / UnitWeight, 1, '<');
                end else begin
                    // No unit weight - calculate how many chunks we need based on effective weight
                    // Then divide units evenly across chunks
                    ChunksNeeded := ROUND(ItemTotalWeight / (MaxWeight * 0.95), 1, '>');
                    if ChunksNeeded < 1 then
                        ChunksNeeded := 1;
                    MaxUnitsPerBatch := ROUND(ItemsToSplit."Sub Units" / ChunksNeeded, 1, '>');
                end;

                if MaxUnitsPerBatch < 1 then
                    MaxUnitsPerBatch := 1;

                // Delete original oversized item from BucketItems
                if BucketItems.Get(ItemsToSplit."Entry No.") then begin
                    RemainingUnits := BucketItems."Sub Units";
                    BucketItems.Delete();

                    // Create split chunks directly in BucketItems
                    while RemainingUnits > 0 do begin
                        ChunkUnits := RemainingUnits;
                        if ChunkUnits > MaxUnitsPerBatch then
                            ChunkUnits := MaxUnitsPerBatch;

                        NewItem := ItemsToSplit;
                        NewItem."Entry No." := NextEntryNo;
                        NewItem."Sub Units" := ChunkUnits;
                        NewItem."Base Qty Required" := ChunkUnits;
                        BucketItems := NewItem;
                        BucketItems.Insert();

                        NextEntryNo += 1;
                        RemainingUnits -= ChunkUnits;
                    end;
                end;
            until ItemsToSplit.Next() = 0;
    end;

    local procedure EmitPackedSuggestion(var Stage: Record "WLM Load Suggestion";
                                         Handler: Interface "WLM Load Suggestion Handler";
                                         ReleaseDate: Date;
                                         LoadGroupId: Guid;
                                         ProposedDocNo: Text[30];
                                         ParentLoadUnitCode: Code[10])
    var
        ItemCapacityPerParent: Decimal;
        ParentUnits: Decimal;
        FinalStage: Record "WLM Load Suggestion";
    begin
        // Calculate parent units needed for this item
        ItemCapacityPerParent := CalculateUnitsPerParent(ParentLoadUnitCode, Stage."Item No.");
        if ItemCapacityPerParent > 0 then
            ParentUnits := ROUND(Stage."Sub Units" / ItemCapacityPerParent, 1, '>')
        else
            ParentUnits := 1;

        FinalStage := Stage;
        FinalStage."Parent Units" := ParentUnits;
        FinalStage."Load Unit Code" := ParentLoadUnitCode;

        // Store original qty before order multiples
        FinalStage."Base Qty Required" := FinalStage."Sub Units";

        // Apply order multiple
        FinalStage."Sub Units" := ApplyOrderMultipleToQty(FinalStage."Sub Units", ParentLoadUnitCode, FinalStage."Item No.");

        // Emit to handler
        EmitStagedSuggestion(FinalStage, Handler, ReleaseDate, LoadGroupId, ProposedDocNo);
    end;

    local procedure CollectUniqueBucketKeys(var BucketKeys: List of [Text])
    var
        TempSugg: Record "WLM Load Suggestion" temporary;
        BucketKey: Text[250];
    begin
        Clear(BucketKeys);
        TempSugg.Copy(PendingSuggestions, true);
        TempSugg.Reset();
        if not TempSugg.FindSet() then
            exit;

        repeat
            BucketKey := GetPendingBucketKey(TempSugg."Entry No.");
            if (BucketKey <> '') and (not BucketKeys.Contains(BucketKey)) then
                BucketKeys.Add(BucketKey);
        until TempSugg.Next() = 0;
    end;

    local procedure ProcessBucketWithBinPacking(BucketKey: Text[250]; Handler: Interface "WLM Load Suggestion Handler")
    var
        BucketItems: Record "WLM Load Suggestion" temporary;
        TotalContainerEquivalent: Decimal;
        OptimalContainerCount: Integer;
        TargetFillPerContainer: Decimal;
        MinFillPct: Decimal;
    begin
        // Calculate total container equivalent for this bucket
        TotalContainerEquivalent := CalculateBucketTotalContainerEquivalent(BucketKey);

        // Get minimum fill % from bucket profile
        if not BucketMinFillPercent.Get(BucketKey, MinFillPct) then
            MinFillPct := 80;
        if MinFillPct <= 0 then
            MinFillPct := 80;

        // Calculate optimal number of containers
        // Goal: each container should be between MinFill% and 100%
        if TotalContainerEquivalent <= 0 then
            exit;

        // Calculate how many containers we need so each is at least MinFill%
        // N containers at MinFill% = N * 0.8 capacity
        // We need: N >= TotalEquiv / 1.0 AND N * 0.8 <= TotalEquiv
        // So: TotalEquiv / 1.0 <= N <= TotalEquiv / 0.8
        OptimalContainerCount := CalculateOptimalContainerCount(TotalContainerEquivalent, MinFillPct / 100);

        // Set target fill per container to distribute evenly
        if OptimalContainerCount > 0 then
            TargetFillPerContainer := TotalContainerEquivalent / OptimalContainerCount
        else
            TargetFillPerContainer := 1.0;

        // Reset wave tracking for this bucket to pack fresh
        ResetBucketWaveTracking(BucketKey);

        // Store target fill for wave allocation
        SetBucketTargetFill(BucketKey, TargetFillPerContainer);

        // Process items sorted by size descending (largest first for better bin packing)
        BucketItems.Copy(PendingSuggestions, true);
        BucketItems.Reset();
        BucketItems.SetCurrentKey("Pct of Parent Unit");
        BucketItems.SetAscending("Pct of Parent Unit", false);
        if not BucketItems.FindSet() then
            exit;

        repeat
            if GetPendingBucketKey(BucketItems."Entry No.") = BucketKey then
                FinalizeQueuedSuggestion(BucketItems, Handler);
        until BucketItems.Next() = 0;
    end;

    local procedure CalculateBucketTotalContainerEquivalent(BucketKey: Text[250]): Decimal
    var
        TempSugg: Record "WLM Load Suggestion" temporary;
        ParentLoadUnitCode: Code[10];
        ItemCapacity: Decimal;
        Total: Decimal;
        TotalWeight: Decimal;
        MaxWeight: Decimal;
        WeightEquivalent: Decimal;
    begin
        Total := 0;
        TotalWeight := 0;
        TempSugg.Copy(PendingSuggestions, true);
        TempSugg.Reset();
        if not TempSugg.FindSet() then
            exit(0);

        if not BucketParentLoadUnitCodes.Get(BucketKey, ParentLoadUnitCode) then
            ParentLoadUnitCode := '';

        // Get max weight for the parent load unit
        MaxWeight := GetParentLoadUnitMaxWeight(ParentLoadUnitCode);

        repeat
            if GetPendingBucketKey(TempSugg."Entry No.") = BucketKey then begin
                if ParentLoadUnitCode = '' then
                    ParentLoadUnitCode := TempSugg."Load Unit Code";

                // Calculate dimensional capacity
                ItemCapacity := CalculateUnitsPerParent(ParentLoadUnitCode, TempSugg."Item No.");
                if ItemCapacity > 0 then
                    Total += TempSugg."Sub Units" / ItemCapacity
                else
                    Total += 1;

                // Accumulate weight for weight-based calculation
                TotalWeight += GetItemTotalWeight(TempSugg."Item No.", TempSugg."Sub Units");
            end;
        until TempSugg.Next() = 0;

        // If weight limit exists, also calculate weight-based container equivalent
        // Use the GREATER of dimensional or weight-based equivalents (most constraining)
        if MaxWeight > 0 then begin
            WeightEquivalent := TotalWeight / MaxWeight;
            if WeightEquivalent > Total then
                Total := WeightEquivalent;
        end;

        exit(Total);
    end;

    local procedure GetParentLoadUnitMaxWeight(ParentLoadUnitCode: Code[10]): Decimal
    var
        ParentUnit: Record "WLM Order Loading Unit";
    begin
        if ParentLoadUnitCode = '' then
            exit(0);
        if not ParentUnit.Get(ParentLoadUnitCode) then
            exit(0);
        exit(ParentUnit.MaxWeight);
    end;

    local procedure GetItemTotalWeight(ItemNo: Code[20]; SubUnits: Decimal): Decimal
    var
        ItemLoad: Record "WLM Item Loading Unit";
        Item: Record Item;
        UnitWeight: Decimal;
    begin
        // Try WLM Item Loading Unit first
        if ItemLoad.Get(ItemNo) then
            if ItemLoad."Unit Weight" > 0 then
                exit(SubUnits * ItemLoad."Unit Weight");

        // Fallback to Item master Net Weight
        if Item.Get(ItemNo) then
            if Item."Net Weight" > 0 then
                exit(SubUnits * Item."Net Weight");

        exit(0);
    end;

    local procedure GetItemUnitWeight(ItemNo: Code[20]): Decimal
    var
        ItemLoad: Record "WLM Item Loading Unit";
        Item: Record Item;
    begin
        // Try WLM Item Loading Unit first
        if ItemLoad.Get(ItemNo) then
            if ItemLoad."Unit Weight" > 0 then
                exit(ItemLoad."Unit Weight");

        // Fallback to Item master Net Weight
        if Item.Get(ItemNo) then
            if Item."Net Weight" > 0 then
                exit(Item."Net Weight");

        exit(0);
    end;

    local procedure CalculateOptimalContainerCount(TotalEquivalent: Decimal; MinFillRatio: Decimal): Integer
    var
        MinContainers: Integer;
        MaxContainers: Integer;
        OptimalContainers: Integer;
        FillAtMin: Decimal;
        FillAtMax: Decimal;
    begin
        // If total demand is less than one container at min fill, we need exactly 1 container
        if TotalEquivalent <= MinFillRatio then
            exit(1);

        // Minimum containers = ceiling of (total / 1.0) - can't exceed 100% per container
        MinContainers := ROUND(TotalEquivalent, 1, '>');
        if MinContainers < 1 then
            MinContainers := 1;

        // Maximum containers = floor of (total / minFill) - each must be at least minFill%
        MaxContainers := ROUND(TotalEquivalent / MinFillRatio, 1, '<');
        if MaxContainers < MinContainers then
            MaxContainers := MinContainers;

        // Choose the minimum number of containers where each is at least minFill
        // Start from minimum and check
        OptimalContainers := MinContainers;
        FillAtMin := TotalEquivalent / MinContainers;

        if FillAtMin >= MinFillRatio then
            exit(MinContainers);

        // If minimum containers results in underfill, we need fewer containers
        // But we can't have fewer than MinContainers (would exceed 100%)
        // So in this case, we accept the underfill on the last container
        // Unless we can redistribute...

        // Actually, let's find the sweet spot
        for OptimalContainers := MinContainers to MaxContainers do begin
            FillAtMin := TotalEquivalent / OptimalContainers;
            if FillAtMin >= MinFillRatio then
                exit(OptimalContainers);
        end;

        // Fallback
        exit(MinContainers);
    end;

    local procedure ResetBucketWaveTracking(BucketKey: Text[250])
    begin
        // Reset wave index for this bucket
        BucketWaveCurrentIndex.Set(BucketKey, 1);
    end;

    local procedure SetBucketTargetFill(BucketKey: Text[250]; TargetFill: Decimal)
    begin
        BucketTargetFillPerWave.Set(BucketKey, TargetFill);
    end;

    local procedure GetBucketTargetFill(BucketKey: Text[250]): Decimal
    var
        TargetFill: Decimal;
    begin
        if BucketTargetFillPerWave.Get(BucketKey, TargetFill) then
            exit(TargetFill);
        exit(1.0); // Default to 100% if not set
    end;

    local procedure PreCalculateBinPackingOrder()
    var
        TempSugg: Record "WLM Load Suggestion" temporary;
        BucketKey: Text[250];
        ParentLoadUnitCode: Code[10];
        ItemCapacity: Decimal;
        ContainerEquivalent: Decimal;
    begin
        // Calculate and store container equivalent for each pending suggestion
        // This is used for sorting (largest first for bin packing)
        TempSugg.Copy(PendingSuggestions, true);
        TempSugg.Reset();
        if not TempSugg.FindSet() then
            exit;

        repeat
            BucketKey := GetPendingBucketKey(TempSugg."Entry No.");
            if not BucketParentLoadUnitCodes.Get(BucketKey, ParentLoadUnitCode) then
                ParentLoadUnitCode := TempSugg."Load Unit Code";

            ItemCapacity := CalculateUnitsPerParent(ParentLoadUnitCode, TempSugg."Item No.");
            if ItemCapacity > 0 then
                ContainerEquivalent := TempSugg."Sub Units" / ItemCapacity
            else
                ContainerEquivalent := 1;

            // Store as percentage (0-100 scale) in Pct of Parent Unit for sorting
            TempSugg."Pct of Parent Unit" := ROUND(ContainerEquivalent * 100, 0.01);
            TempSugg.Modify();
        until TempSugg.Next() = 0;
    end;

    local procedure FinalizeQueuedSuggestion(var Stage: Record "WLM Load Suggestion"; Handler: Interface "WLM Load Suggestion Handler")
    var
        ReleaseDate: Date;
        LoadGroupId: Guid;
        ProposedDocNo: Text[30];
        BucketKey: Text[250];
        ParentCapacity: Decimal;
        RemainingParentUnits: Decimal;
        RemainingSubUnits: Decimal;
        OriginalParentUnits: Decimal;
        SubUnitsPerParent: Decimal;
        ChunkUnits: Decimal;
        ChunkSubUnits: Decimal;
        WaveIndex: Integer;
        ChunkStage: Record "WLM Load Suggestion";
        ParentLoadUnitCode: Code[10];
        ItemCapacityPerParent: Decimal;
        BucketPeriodDate: Date;
        MaxWeightCapacity: Decimal;
        ChunkWeight: Decimal;
        UnitWeight: Decimal;
        MaxUnitsForWeight: Decimal;
    begin
        ReleaseDate := Stage."Release Date";
        if Stage."Suggestion Type" = Stage."Suggestion Type"::Purchase then
            ReleaseDate := EnforceVendorCapacity(Stage."Source Vendor No.", ParentLoadUnitCode, Stage."Parent Units", ReleaseDate);
        ReleaseDate := EnsureFutureDate(ReleaseDate);

        BucketKey := GetPendingBucketKey(Stage."Entry No.");

        // Extract period from BucketKey for consistent grouping
        // This ensures items merged from different periods get the same LoadGroupId
        BucketPeriodDate := GetDateFromBucketKey(BucketKey);
        if BucketPeriodDate = 0D then
            BucketPeriodDate := Stage."Required Date";

        ParentCapacity := GetBucketParentCapacityValue(BucketKey);
        if not BucketParentLoadUnitCodes.Get(BucketKey, ParentLoadUnitCode) then
            ParentLoadUnitCode := Stage."Load Unit Code";
        if ParentCapacity = 0 then
            ParentCapacity := CalculateUnitsPerParent(ParentLoadUnitCode, Stage."Item No.");

        // Store the original raw quantity BEFORE order multiples are applied
        // This matches what Planning Schedule shows as "Qty Required"
        Stage."Base Qty Required" := Stage."Sub Units";

        // Apply order multiple based on Item Load Fit for the parent load unit (e.g., 40CNTR)
        // If Enforce Order Multiples is checked and Order Multiple = 6 (Units/Row), ensure qty is rounded up to full rows
        Stage."Sub Units" := ApplyOrderMultipleToQty(Stage."Sub Units", ParentLoadUnitCode, Stage."Item No.");

        if BucketRequiresLanePacking(BucketKey) then begin
            FinalizeLanePackedSuggestion(Stage, Handler, ReleaseDate, BucketKey, ParentLoadUnitCode, ParentCapacity);
        end else begin
            // Get actual units per parent container from item load fit for the TRUE parent (40CNTR)
            // The Stage."Parent Units" was calculated using the item's sub-unit code, which is wrong
            ItemCapacityPerParent := CalculateUnitsPerParent(ParentLoadUnitCode, Stage."Item No.");

            // Recalculate parent units using the correct parent load unit capacity
            if ItemCapacityPerParent > 0 then
                RemainingParentUnits := ROUND(Stage."Sub Units" / ItemCapacityPerParent, 1, '>')
            else
                RemainingParentUnits := Stage."Parent Units";

            RemainingSubUnits := Stage."Sub Units";
            OriginalParentUnits := RemainingParentUnits;
            if (OriginalParentUnits <> 0) and (Stage."Sub Units" <> 0) then
                SubUnitsPerParent := Stage."Sub Units" / OriginalParentUnits
            else
                SubUnitsPerParent := 0;

            // Get weight capacity for this parent load unit
            MaxWeightCapacity := GetParentLoadUnitMaxWeight(ParentLoadUnitCode);

            repeat
                ChunkUnits := RemainingParentUnits;
                if (ParentCapacity > 0) and (ChunkUnits > ParentCapacity) then
                    ChunkUnits := ParentCapacity;
                if ChunkUnits <= 0 then
                    exit;

                // Calculate sub units for this chunk
                // When we still have more parents to fill, propose FULL parent capacity (maximize load)
                // Only on the last chunk do we use the exact remaining amount
                if RemainingParentUnits > ChunkUnits then begin
                    // Not the last chunk - fill to full parent capacity
                    ChunkSubUnits := ItemCapacityPerParent;
                    if ChunkSubUnits > RemainingSubUnits then
                        ChunkSubUnits := RemainingSubUnits;
                end else begin
                    // Last chunk - use remaining sub units
                    ChunkSubUnits := RemainingSubUnits;
                end;

                // Weight-based chunking: If this chunk exceeds weight, reduce it
                if MaxWeightCapacity > 0 then begin
                    ChunkWeight := GetItemTotalWeight(Stage."Item No.", ChunkSubUnits);
                    if ChunkWeight > MaxWeightCapacity then begin
                        // Calculate max units that fit within weight limit
                        UnitWeight := GetItemUnitWeight(Stage."Item No.");
                        if UnitWeight > 0 then begin
                            MaxUnitsForWeight := ROUND(MaxWeightCapacity / UnitWeight, 1, '<');
                            if MaxUnitsForWeight < ChunkSubUnits then
                                ChunkSubUnits := MaxUnitsForWeight;
                            if ChunkSubUnits <= 0 then
                                ChunkSubUnits := 1; // At least 1 unit per chunk
                        end;
                    end;
                end;

                // NOTE: Order multiples removed - Sub Units should reflect actual pieces planned
                // Order multiples to be applied when creating actual PO/Transfer documents

                // Use container equivalent (sub units / item capacity) for wave allocation
                // Consider both dimensional and weight constraints - pass ParentLoadUnitCode for weight check
                WaveIndex := DetermineBucketWaveIndexWithWeight(BucketKey, ChunkSubUnits, ItemCapacityPerParent, Stage."Item No.", ParentLoadUnitCode);
                // Use BucketPeriodDate (from bucket key) to ensure merged items get same LoadGroupId
                LoadGroupId := AssignLoadGroup(Stage."Suggestion Type", Stage."Location Code", Stage."Source Location Code", Stage."Source Vendor No.", BucketPeriodDate, WaveIndex);
                ProposedDocNo := EnsureLoadBatch(
                    LoadGroupId,
                    Stage."Suggestion Type",
                    Stage."Location Code",
                    Stage."Source Location Code",
                    Stage."Source Vendor No.",
                    BucketPeriodDate,
                    ReleaseDate,
                    ParentLoadUnitCode,
                    ChunkUnits);

                ChunkStage := Stage;
                ChunkStage."Sub Units" := ChunkSubUnits;
                ChunkStage."Parent Units" := ChunkUnits;
                EmitStagedSuggestion(ChunkStage, Handler, ReleaseDate, LoadGroupId, ProposedDocNo);

                RegisterBucketAllocation(BucketKey, ChunkUnits);
                UpdateBucketReleaseState(BucketKey);

                RemainingParentUnits -= ChunkUnits;
                if RemainingParentUnits < 0 then
                    RemainingParentUnits := 0;

                if RemainingParentUnits <= 0 then begin
                    RemainingSubUnits := 0
                end else begin
                    RemainingSubUnits -= ChunkSubUnits;
                    if RemainingSubUnits < 0 then
                        RemainingSubUnits := 0;
                end;
            until (RemainingParentUnits <= 0) or (ChunkUnits = 0);
        end;
    end;

    local procedure FinalizeLanePackedSuggestion(var Stage: Record "WLM Load Suggestion";
                                                 Handler: Interface "WLM Load Suggestion Handler";
                                                 ReleaseDate: Date;
                                                 BucketKey: Text[250];
                                                 ParentLoadUnitCode: Code[10];
                                                 ParentCapacity: Decimal)
    var
        ParentUnit: Record "WLM Order Loading Unit";
        ItemLoad: Record "WLM Item Loading Unit";
        RemainingUnits: Decimal;
        RemainingSubUnits: Decimal;
        Ratio: Decimal;
        UnitsPlaced: Decimal;
        ChunkStage: Record "WLM Load Suggestion";
        WaveIndex: Integer;
        ChunkSubUnits: Decimal;
        LoadGroupId: Guid;
        ProposedDocNo: Text[30];
        ItemCapacityPerParent: Decimal;
        BucketPeriodDate: Date;
    begin
        if (Stage."Parent Units" <= 0) or (Stage."Sub Units" <= 0) then
            exit;

        if ParentLoadUnitCode = '' then
            ParentLoadUnitCode := Stage."Load Unit Code";
        if (ParentLoadUnitCode = '') or not ParentUnit.Get(ParentLoadUnitCode) then
            exit;

        if not ItemLoad.Get(Stage."Item No.") then
            exit;

        if ParentCapacity = 0 then
            ParentCapacity := CalculateUnitsPerParent(ParentLoadUnitCode, Stage."Item No.");

        // Order multiples already applied in FinalizeQueuedSuggestion before this procedure is called

        // Extract period from BucketKey for consistent grouping
        // This ensures items merged from different periods get the same LoadGroupId
        BucketPeriodDate := GetDateFromBucketKey(BucketKey);
        if BucketPeriodDate = 0D then
            BucketPeriodDate := Stage."Required Date";

        // Recalculate parent units using correct parent load unit capacity
        ItemCapacityPerParent := CalculateUnitsPerParent(ParentLoadUnitCode, Stage."Item No.");
        if ItemCapacityPerParent > 0 then
            RemainingUnits := ROUND(Stage."Sub Units" / ItemCapacityPerParent, 1, '>')
        else
            RemainingUnits := Stage."Parent Units";

        RemainingSubUnits := Stage."Sub Units";
        if RemainingUnits <> 0 then
            Ratio := Stage."Sub Units" / RemainingUnits
        else
            Ratio := 0;

        repeat
            UnitsPlaced := AllocateLaneUnits(BucketKey, ParentUnit, ItemLoad, RemainingUnits, ParentCapacity, WaveIndex);
            if UnitsPlaced <= 0 then
                exit;

            if RemainingUnits <= UnitsPlaced then
                ChunkSubUnits := RemainingSubUnits
            else begin
                if Ratio <> 0 then
                    ChunkSubUnits := UnitsPlaced * Ratio
                else begin
                    if RemainingUnits <> 0 then
                        ChunkSubUnits := UnitsPlaced * (RemainingSubUnits / RemainingUnits)
                    else
                        ChunkSubUnits := UnitsPlaced;
                end;
            end;

            // Use BucketPeriodDate (from bucket key) to ensure merged items get same LoadGroupId
            LoadGroupId := AssignLoadGroup(Stage."Suggestion Type", Stage."Location Code", Stage."Source Location Code", Stage."Source Vendor No.", BucketPeriodDate, WaveIndex);
            ProposedDocNo := EnsureLoadBatch(
                LoadGroupId,
                Stage."Suggestion Type",
                Stage."Location Code",
                Stage."Source Location Code",
                Stage."Source Vendor No.",
                BucketPeriodDate,
                ReleaseDate,
                ParentLoadUnitCode,
                UnitsPlaced);

            ChunkStage := Stage;
            ChunkStage."Parent Units" := UnitsPlaced;
            ChunkStage."Sub Units" := ChunkSubUnits;
            EmitStagedSuggestion(ChunkStage, Handler, ReleaseDate, LoadGroupId, ProposedDocNo);

            RegisterBucketAllocation(BucketKey, UnitsPlaced);
            UpdateBucketReleaseState(BucketKey);

            RemainingUnits -= UnitsPlaced;
            if RemainingUnits < 0 then
                RemainingUnits := 0;

            if RemainingUnits <= 0 then
                RemainingSubUnits := 0
            else begin
                RemainingSubUnits -= ChunkSubUnits;
                if RemainingSubUnits < 0 then
                    RemainingSubUnits := 0;
            end;
        until RemainingUnits <= 0;
    end;

    local procedure AllocateLaneUnits(BucketKey: Text[250];
                                      ParentUnit: Record "WLM Order Loading Unit";
                                      ItemLoad: Record "WLM Item Loading Unit";
                                      RequestedUnits: Decimal;
                                      ParentCapacity: Decimal;
                                      var WaveIndex: Integer): Decimal
    var
        LaneWidth: Decimal;
        UnitsPerLane: Decimal;
        MaxLanes: Integer;
        UnitsPlaced: Decimal;
    begin
        if RequestedUnits <= 0 then
            exit(0);

        if not DetermineLaneOrientation(ParentUnit, ItemLoad, LaneWidth, UnitsPerLane, MaxLanes) then
            exit(0);

        if (LaneWidth <= 0) or (UnitsPerLane <= 0) or (MaxLanes <= 0) then
            exit(0);

        WaveIndex := EnsureWaveIndexInitialized(BucketKey);
        repeat
            UnitsPlaced := TryFillLaneWave(BucketKey, WaveIndex, LaneWidth, UnitsPerLane, RequestedUnits, ParentUnit, ParentCapacity);
            if UnitsPlaced > 0 then begin
                RecordLaneWaveUnits(BucketKey, WaveIndex, UnitsPlaced);
                exit(UnitsPlaced);
            end;

            WaveIndex := StartNextLaneWave(BucketKey);
            if WaveIndex = 0 then
                exit(0);
        until false;
    end;

    local procedure TryFillLaneWave(BucketKey: Text[250];
                                    WaveIndex: Integer;
                                    LaneWidth: Decimal;
                                    UnitsPerLane: Decimal;
                                    RequestedUnits: Decimal;
                                    ParentUnit: Record "WLM Order Loading Unit";
                                    ParentCapacity: Decimal): Decimal
    var
        LaneKey: Text[280];
        WidthKey: Text[270];
        LaneCount: Integer;
        LaneUsage: Decimal;
        AvailableExisting: Decimal;
        WidthUsed: Decimal;
        WidthRemaining: Decimal;
        AdditionalLaneCount: Integer;
        AdditionalLaneCountValue: Decimal;
        AdditionalUnits: Decimal;
        NeededLaneCount: Integer;
        NeededLaneCountValue: Decimal;
        CapacityFromNew: Decimal;
        AllowedUnits: Decimal;
        WaveUsageKey: Text[260];
        UnitsAlreadyInWave: Decimal;
        WeightRemaining: Decimal;
    begin
        if RequestedUnits <= 0 then
            exit(0);

        WaveUsageKey := BuildBucketWaveUsageKey(BucketKey, WaveIndex);
        UnitsAlreadyInWave := GetWaveUsage(WaveUsageKey);
        WeightRemaining := ParentCapacity;
        if ParentCapacity > 0 then begin
            WeightRemaining := ParentCapacity - UnitsAlreadyInWave;
            if WeightRemaining <= 0 then
                exit(0);
            if RequestedUnits > WeightRemaining then
                RequestedUnits := WeightRemaining;
        end;

        LaneKey := BuildLaneStateKey(BucketKey, WaveIndex, LaneWidth, UnitsPerLane);
        LaneCount := GetLaneCount(LaneKey);
        LaneUsage := GetLaneUsage(LaneKey);
        AvailableExisting := (LaneCount * UnitsPerLane) - LaneUsage;
        if AvailableExisting > 0 then begin
            AllowedUnits := RequestedUnits;
            if AllowedUnits > AvailableExisting then
                AllowedUnits := AvailableExisting;
            LaneUsage += AllowedUnits;
            SetLaneUsage(LaneKey, LaneUsage);
            exit(AllowedUnits);
        end;

        WidthKey := BuildLaneWaveKey(BucketKey, WaveIndex);
        WidthUsed := GetLaneWidthUsed(WidthKey);
        WidthRemaining := ParentUnit.InteriorWidth - WidthUsed;
        if WidthRemaining <= 0 then
            exit(0);

        AdditionalLaneCountValue := ROUND(WidthRemaining / LaneWidth, 1, '<');
        AdditionalLaneCount := AdditionalLaneCountValue;
        if AdditionalLaneCount <= 0 then
            exit(0);

        AdditionalUnits := AdditionalLaneCount * UnitsPerLane;
        AllowedUnits := RequestedUnits;
        if AllowedUnits > AdditionalUnits then
            AllowedUnits := AdditionalUnits;

        NeededLaneCountValue := ROUND(AllowedUnits / UnitsPerLane, 1, '>');
        NeededLaneCount := NeededLaneCountValue;
        if NeededLaneCount <= 0 then
            NeededLaneCount := 1;
        if NeededLaneCount > AdditionalLaneCount then
            NeededLaneCount := AdditionalLaneCount;

        CapacityFromNew := NeededLaneCount * UnitsPerLane;
        if AllowedUnits > CapacityFromNew then
            AllowedUnits := CapacityFromNew;

        LaneCount += NeededLaneCount;
        LaneUsage += AllowedUnits;
        WidthUsed += NeededLaneCount * LaneWidth;

        SetLaneCount(LaneKey, LaneCount);
        SetLaneUsage(LaneKey, LaneUsage);
        SetLaneWidthUsed(WidthKey, WidthUsed);

        exit(AllowedUnits);
    end;

    local procedure DetermineLaneOrientation(ParentUnit: Record "WLM Order Loading Unit";
                                             ItemLoad: Record "WLM Item Loading Unit";
                                             var LaneWidth: Decimal;
                                             var UnitsPerLane: Decimal;
                                             var MaxLanes: Integer): Boolean
    var
        OptionLaneWidth: Decimal;
        OptionUnitsPerLane: Decimal;
        OptionMaxLanes: Integer;
        OptionCapacity: Decimal;
        BestCapacity: Decimal;
        BestLaneWidth: Decimal;
        BestUnitsPerLane: Decimal;
        BestMaxLanes: Integer;
    begin
        BestCapacity := 0;

        EvaluateLaneOption(
            ParentUnit,
            ItemLoad."Unit Length",
            ItemLoad."Unit Width",
            ItemLoad."Unit Height",
            ItemLoad.CanStack,
            OptionLaneWidth,
            OptionUnitsPerLane,
            OptionMaxLanes,
            OptionCapacity);

        if OptionCapacity > BestCapacity then begin
            BestCapacity := OptionCapacity;
            BestLaneWidth := OptionLaneWidth;
            BestUnitsPerLane := OptionUnitsPerLane;
            BestMaxLanes := OptionMaxLanes;
        end;

        if ItemLoad.CanRotate then begin
            EvaluateLaneOption(
                ParentUnit,
                ItemLoad."Unit Width",
                ItemLoad."Unit Length",
                ItemLoad."Unit Height",
                ItemLoad.CanStack,
                OptionLaneWidth,
                OptionUnitsPerLane,
                OptionMaxLanes,
                OptionCapacity);

            if OptionCapacity > BestCapacity then begin
                BestCapacity := OptionCapacity;
                BestLaneWidth := OptionLaneWidth;
                BestUnitsPerLane := OptionUnitsPerLane;
                BestMaxLanes := OptionMaxLanes;
            end;
        end;

        if BestCapacity <= 0 then
            exit(false);

        LaneWidth := BestLaneWidth;
        UnitsPerLane := BestUnitsPerLane;
        MaxLanes := BestMaxLanes;
        exit(true);
    end;

    local procedure EvaluateLaneOption(ParentUnit: Record "WLM Order Loading Unit";
                                       ItemLength: Decimal;
                                       ItemWidth: Decimal;
                                       ItemHeight: Decimal;
                                       AllowStack: Boolean;
                                       var LaneWidth: Decimal;
                                       var UnitsPerLane: Decimal;
                                       var MaxLanes: Integer;
                                       var TotalCapacity: Decimal)
    var
        UnitsAlongLength: Decimal;
        HeightFit: Decimal;
    begin
        TotalCapacity := 0;
        LaneWidth := 0;
        UnitsPerLane := 0;
        MaxLanes := 0;

        if (ParentUnit.InteriorLength <= 0) or (ParentUnit.InteriorWidth <= 0) then
            exit;
        if (ItemLength <= 0) or (ItemWidth <= 0) or (ItemHeight <= 0) then
            exit;

        UnitsAlongLength := ROUND(ParentUnit.InteriorLength / ItemLength, 1, '<');
        if UnitsAlongLength <= 0 then
            exit;

        HeightFit := ROUND(ParentUnit.InteriorHeight / ItemHeight, 1, '<');
        if not AllowStack then begin
            if HeightFit >= 1 then
                HeightFit := 1
            else
                exit;
        end;

        if HeightFit <= 0 then
            exit;

        UnitsPerLane := UnitsAlongLength * HeightFit;
        LaneWidth := ItemWidth;
        MaxLanes := ROUND(ParentUnit.InteriorWidth / LaneWidth, 1, '<');
        if MaxLanes <= 0 then
            exit;

        TotalCapacity := UnitsPerLane * MaxLanes;
    end;

    local procedure RecordLaneWaveUnits(BucketKey: Text[250]; WaveIndex: Integer; UnitsPlaced: Decimal)
    var
        WaveUsageKey: Text[260];
        Current: Decimal;
    begin
        if UnitsPlaced <= 0 then
            exit;

        WaveUsageKey := BuildBucketWaveUsageKey(BucketKey, WaveIndex);
        Current := GetWaveUsage(WaveUsageKey);
        Current += UnitsPlaced;
        BucketWaveUsage.Set(WaveUsageKey, Current);
    end;

    local procedure BuildLaneWaveKey(BucketKey: Text[250]; WaveIndex: Integer): Text[270]
    begin
        exit(StrSubstNo('%1|LANEWAVE|%2', BucketKey, Format(WaveIndex)));
    end;

    local procedure BuildLaneStateKey(BucketKey: Text[250]; WaveIndex: Integer; LaneWidth: Decimal; UnitsPerLane: Decimal): Text[280]
    begin
        exit(StrSubstNo('%1|LANE|%2|W%3|U%4', BucketKey, Format(WaveIndex), FormatDecimalKey(LaneWidth), FormatDecimalKey(UnitsPerLane)));
    end;

    local procedure FormatDecimalKey(Value: Decimal): Text[30]
    var
        TextValue: Text;
    begin
        TextValue := Format(Value, 0, 9);
        exit(DelChr(TextValue, '=', ' '));
    end;

    local procedure GetLaneWidthUsed(LaneWidthKeyText: Text[270]): Decimal
    var
        WidthUsed: Decimal;
    begin
        if BucketLaneWaveWidthUsed.Get(LaneWidthKeyText, WidthUsed) then
            exit(WidthUsed);
        exit(0);
    end;

    local procedure SetLaneWidthUsed(LaneWidthKeyText: Text[270]; Value: Decimal)
    begin
        BucketLaneWaveWidthUsed.Set(LaneWidthKeyText, Value);
    end;

    local procedure GetLaneCount(LaneStateKeyText: Text[280]): Integer
    var
        LaneCount: Integer;
    begin
        if BucketLaneWaveLaneCount.Get(LaneStateKeyText, LaneCount) then
            exit(LaneCount);
        exit(0);
    end;

    local procedure SetLaneCount(LaneStateKeyText: Text[280]; Value: Integer)
    begin
        BucketLaneWaveLaneCount.Set(LaneStateKeyText, Value);
    end;

    local procedure GetLaneUsage(LaneStateKeyText: Text[280]): Decimal
    var
        LaneUsage: Decimal;
    begin
        if BucketLaneWaveLaneUsage.Get(LaneStateKeyText, LaneUsage) then
            exit(LaneUsage);
        exit(0);
    end;

    local procedure SetLaneUsage(LaneStateKeyText: Text[280]; Value: Decimal)
    begin
        BucketLaneWaveLaneUsage.Set(LaneStateKeyText, Value);
    end;

    local procedure StartNextLaneWave(BucketKey: Text[250]): Integer
    var
        Current: Integer;
    begin
        Current := EnsureWaveIndexInitialized(BucketKey);
        Current += 1;
        BucketWaveCurrentIndex.Set(BucketKey, Current);
        exit(Current);
    end;

    local procedure EmitStagedSuggestion(var Stage: Record "WLM Load Suggestion";
                                         Handler: Interface "WLM Load Suggestion Handler";
                                         ReleaseDate: Date;
                                         LoadGroupId: Guid;
                                         ProposedDocNo: Text[30])
    begin
        if (Stage."Sub Units" <= 0) or (Stage."Parent Units" <= 0) then
            exit;

        Handler.AddSuggestion(
            Stage."Item No.",
            Stage."Location Code",
            Stage."Required Date",
            Stage."Load Unit Code",
            Stage."Sub Units",
            Stage."Parent Units",
            Stage."Priority Score",
            Stage."Shortage Date",
            Stage."Suggestion Type",
            Stage."Source Location Code",
            Stage."Source Vendor No.",
            ReleaseDate,
            LoadGroupId,
            ProposedDocNo,
            Stage."Requirement Month",
            Stage."Requirement Year",
            Stage."Requirement Period",
            Stage."Pct of Parent Unit",
            Stage."Base Qty Required",
            Stage."Days Until Required",
            Stage."Month Priority Rank",
            Stage."Urgency Level",
            Stage."Stockout Qty",
            Stage."Par Rebuild Qty");
    end;

    local procedure ConsolidateAdjacentPeriods()
    var
        Keys: List of [Text[250]];
        CurrentKey: Text[250];
        NextKey: Text[250];
        BaseKey: Text[200];
        CurrentPeriod: Text[10];
        NextPeriod: Text[10];
        i: Integer;
        MinFillPercent: Decimal;
        ParentCapacity: Decimal;
        SubUnits: Decimal;
        NextSubUnits: Decimal;
        CombinedSubUnits: Decimal;
        ParentsNeeded: Decimal;
        FillPct: Decimal;
        MergedBuckets: List of [Text[250]];
        ShouldProcess: Boolean;
    begin
        // Goal: If a bucket is underfilled, look for next month's bucket and pull its demand
        // Only pull from the immediate next period (one month forward)
        if BucketSubUnitTotals.Count() = 0 then
            exit;

        Keys := BucketSubUnitTotals.Keys();
        for i := 1 to Keys.Count() do begin
            CurrentKey := Keys.Get(i);
            ShouldProcess := true;

            // Skip if already merged into another bucket
            if MergedBuckets.Contains(CurrentKey) then
                ShouldProcess := false;

            // Extract base key (without period) and current period
            if ShouldProcess then
                if not ParseBucketKeyParts(CurrentKey, BaseKey, CurrentPeriod) then
                    ShouldProcess := false;

            // Get current bucket's fill status
            if ShouldProcess then begin
                if not BucketMinFillPercent.Get(CurrentKey, MinFillPercent) then
                    MinFillPercent := 0;
                if not BucketParentCapacity.Get(CurrentKey, ParentCapacity) then
                    ParentCapacity := 0;
                if not BucketSubUnitTotals.Get(CurrentKey, SubUnits) then
                    SubUnits := 0;

                if (ParentCapacity <= 0) or (MinFillPercent <= 0) then
                    ShouldProcess := false;
            end;

            if ShouldProcess then begin
                // Calculate current fill %
                ParentsNeeded := ROUND(SubUnits / ParentCapacity, 1, '>');
                if ParentsNeeded <= 0 then
                    ParentsNeeded := 1;
                FillPct := (SubUnits / (ParentsNeeded * ParentCapacity)) * 100;

                // If already meeting minimum, no need to pull from next period
                if FillPct >= MinFillPercent then
                    ShouldProcess := false;
            end;

            if ShouldProcess then begin
                // Build next month's bucket key
                NextPeriod := GetNextMonthPeriod(CurrentPeriod);
                NextKey := BaseKey + '|' + NextPeriod;

                // Check if next period bucket exists
                if BucketSubUnitTotals.Get(NextKey, NextSubUnits) then begin
                    // Calculate combined fill to see if it helps
                    CombinedSubUnits := SubUnits + NextSubUnits;
                    ParentsNeeded := ROUND(CombinedSubUnits / ParentCapacity, 1, '>');
                    if ParentsNeeded <= 0 then
                        ParentsNeeded := 1;
                    FillPct := (CombinedSubUnits / (ParentsNeeded * ParentCapacity)) * 100;

                    // Only merge if it improves fill (doesn't exceed 100% by much)
                    if FillPct <= 110 then begin
                        MergeBucketSuggestions(NextKey, CurrentKey);
                        MergedBuckets.Add(NextKey);
                    end;
                end;
            end;
        end;
    end;

    local procedure ConsolidateUnderfilledBuckets()
    var
        Keys: List of [Text[250]];
        UnderfilledKeys: List of [Text[250]];
        CurrentKey: Text[250];
        TargetKey: Text[250];
        BaseKey: Text[200];
        TargetBaseKey: Text[200];
        Period: Text[10];
        TargetPeriod: Text[10];
        i: Integer;
        j: Integer;
        MinFillPercent: Decimal;
        FillContrib: Decimal;
        TargetFillContrib: Decimal;
        CombinedFillContrib: Decimal;
        ContainersNeeded: Integer;
        FillPct: Decimal;
        Merged: Boolean;
    begin
        // Consolidate underfilled buckets with the same base routing (dest/source/vendor) in same or nearby periods
        if BucketFillContribution.Count() = 0 then
            exit;

        // Find all underfilled buckets
        Keys := BucketFillContribution.Keys();
        for i := 1 to Keys.Count() do begin
            CurrentKey := Keys.Get(i);
            if not BucketMinFillPercent.Get(CurrentKey, MinFillPercent) then
                MinFillPercent := 0;

            if MinFillPercent > 0 then begin
                if BucketFillContribution.Get(CurrentKey, FillContrib) then begin
                    ContainersNeeded := ROUND(FillContrib, 1, '>');
                    if ContainersNeeded <= 0 then
                        ContainersNeeded := 1;
                    FillPct := (FillContrib / ContainersNeeded) * 100;

                    // If underfilled, add to list for consolidation
                    if FillPct < MinFillPercent then
                        UnderfilledKeys.Add(CurrentKey);
                end;
            end;
        end;

        // Try to merge underfilled buckets with each other
        for i := 1 to UnderfilledKeys.Count() do begin
            CurrentKey := UnderfilledKeys.Get(i);

            // Skip if already merged
            if not BucketFillContribution.ContainsKey(CurrentKey) then
                continue;

            if not ParseBucketKeyParts(CurrentKey, BaseKey, Period) then
                continue;

            // Look for another underfilled bucket with same base routing
            Merged := false;
            for j := i + 1 to UnderfilledKeys.Count() do begin
                TargetKey := UnderfilledKeys.Get(j);

                // Skip if already merged
                if not BucketFillContribution.ContainsKey(TargetKey) then
                    continue;

                if not ParseBucketKeyParts(TargetKey, TargetBaseKey, TargetPeriod) then
                    continue;

                // Check if same base routing (everything except period)
                if BaseKey = TargetBaseKey then begin
                    // Check if merging would not exceed 110% fill
                    if BucketFillContribution.Get(CurrentKey, FillContrib) then
                        if BucketFillContribution.Get(TargetKey, TargetFillContrib) then begin
                            CombinedFillContrib := FillContrib + TargetFillContrib;
                            ContainersNeeded := ROUND(CombinedFillContrib, 1, '>');
                            if ContainersNeeded <= 0 then
                                ContainersNeeded := 1;
                            FillPct := (CombinedFillContrib / ContainersNeeded) * 100;

                            // Merge if it keeps fill under 110%
                            if FillPct <= 110 then begin
                                MergeBucketSuggestions(TargetKey, CurrentKey);
                                Merged := true;
                                break;
                            end;
                        end;
                end;
            end;
        end;
    end;

    local procedure ParseBucketKeyParts(BucketKey: Text[250]; var BaseKey: Text[200]; var Period: Text[10]): Boolean
    var
        LastPipe: Integer;
        i: Integer;
    begin
        // Bucket key format: Type|DestLocation|SourceLocation|VendorNo|Period
        // Find the last pipe to split off the period
        LastPipe := 0;
        for i := 1 to StrLen(BucketKey) do
            if BucketKey[i] = '|' then
                LastPipe := i;

        if LastPipe <= 0 then
            exit(false);

        BaseKey := CopyStr(BucketKey, 1, LastPipe - 1);
        Period := CopyStr(BucketKey, LastPipe + 1, 10);
        exit(Period <> '');
    end;

    local procedure GetNextMonthPeriod(CurrentPeriod: Text[10]): Text[10]
    var
        Year: Integer;
        Month: Integer;
    begin
        // Period format: YYYY-MM
        if StrLen(CurrentPeriod) < 7 then
            exit('');

        Evaluate(Year, CopyStr(CurrentPeriod, 1, 4));
        Evaluate(Month, CopyStr(CurrentPeriod, 6, 2));

        Month += 1;
        if Month > 12 then begin
            Month := 1;
            Year += 1;
        end;

        if Month < 10 then
            exit(StrSubstNo('%1-0%2', Format(Year, 4), Format(Month)))
        else
            exit(StrSubstNo('%1-%2', Format(Year, 4), Format(Month)));
    end;

    local procedure MergeBucketSuggestions(SourceBucketKey: Text[250]; TargetBucketKey: Text[250])
    var
        SourceSubUnits: Decimal;
        SourceParentUnits: Decimal;
        TargetSubUnits: Decimal;
        TargetParentUnits: Decimal;
        OldKey: Text[250];
    begin
        // Transfer sub unit totals from source bucket to target bucket
        if BucketSubUnitTotals.Get(SourceBucketKey, SourceSubUnits) then begin
            if BucketSubUnitTotals.Get(TargetBucketKey, TargetSubUnits) then
                BucketSubUnitTotals.Set(TargetBucketKey, TargetSubUnits + SourceSubUnits);
            BucketSubUnitTotals.Remove(SourceBucketKey);
        end;

        if BucketParentUnitTotals.Get(SourceBucketKey, SourceParentUnits) then begin
            if BucketParentUnitTotals.Get(TargetBucketKey, TargetParentUnits) then
                BucketParentUnitTotals.Set(TargetBucketKey, TargetParentUnits + SourceParentUnits);
            BucketParentUnitTotals.Remove(SourceBucketKey);
        end;

        // Transfer fill contribution from source to target
        if BucketFillContribution.Get(SourceBucketKey, SourceSubUnits) then begin
            if BucketFillContribution.Get(TargetBucketKey, TargetSubUnits) then
                BucketFillContribution.Set(TargetBucketKey, TargetSubUnits + SourceSubUnits);
            BucketFillContribution.Remove(SourceBucketKey);
        end;

        // Update pending suggestions to point to the target bucket key
        PendingSuggestions.Reset();
        if PendingSuggestions.FindSet() then
            repeat
                OldKey := GetPendingBucketKey(PendingSuggestions."Entry No.");
                if OldKey = SourceBucketKey then
                    RecordPendingBucketKey(PendingSuggestions."Entry No.", TargetBucketKey);
            until PendingSuggestions.Next() = 0;
    end;

    local procedure EvaluateBucketReleaseRules()
    var
        Keys: List of [Text[250]];
        KeyValue: Text[250];
        i: Integer;
    begin
        if BucketSubUnitTotals.Count() = 0 then
            exit;

        Keys := BucketSubUnitTotals.Keys();
        for i := 1 to Keys.Count() do begin
            KeyValue := Keys.Get(i);
            BucketReleaseApproval.Set(KeyValue, ShouldReleaseBucket(KeyValue));
        end;
    end;

    local procedure ShouldReleaseBucket(BucketKey: Text[250]): Boolean
    begin
        // Always release buckets - all demand should be planned.
        // The goal is to COMBINE items into efficient batches, not to block demand.
        // Underfilled batches will be visible to the user who can decide to:
        // 1. Wait for more demand to accumulate
        // 2. Pull demand from adjacent periods
        // 3. Proceed with a partial load
        exit(true);
    end;

    local procedure BucketReadyForRelease(BucketKey: Text[250]): Boolean
    var
        Approval: Boolean;
    begin
        if BucketReleaseApproval.Get(BucketKey, Approval) then
            exit(Approval);
        // Default to FALSE - unknown buckets should be blocked until evaluated
        exit(false);
    end;

    local procedure GetBucketParentUnits(BucketKey: Text[250]): Decimal
    var
        Total: Decimal;
    begin
        if BucketParentUnitTotals.Get(BucketKey, Total) then
            exit(Total);
        exit(0);
    end;

    local procedure GetBucketParentCapacityValue(BucketKey: Text[250]): Decimal
    var
        ParentCapacity: Decimal;
    begin
        if BucketParentCapacity.Get(BucketKey, ParentCapacity) then
            exit(ParentCapacity);
        exit(0);
    end;

    local procedure GetBucketAllocatedUnits(BucketKey: Text[250]): Decimal
    var
        Allocated: Decimal;
    begin
        if BucketAllocatedParentUnits.Get(BucketKey, Allocated) then
            exit(Allocated);
        exit(0);
    end;

    local procedure RegisterBucketAllocation(BucketKey: Text[250]; ParentUnits: Decimal)
    var
        Allocated: Decimal;
    begin
        if ParentUnits <= 0 then
            exit;

        Allocated := GetBucketAllocatedUnits(BucketKey);
        Allocated += ParentUnits;
        BucketAllocatedParentUnits.Set(BucketKey, Allocated);
    end;

    local procedure GetBucketAvailableUnits(BucketKey: Text[250]): Decimal
    var
        Available: Decimal;
    begin
        Available := GetBucketParentUnits(BucketKey) - GetBucketAllocatedUnits(BucketKey);
        if Available < 0 then
            exit(0);
        exit(Available);
    end;

    local procedure UpdateBucketReleaseState(BucketKey: Text[250])
    begin
        BucketReleaseApproval.Set(BucketKey, ShouldReleaseBucket(BucketKey));
    end;

    local procedure DetermineBucketWaveIndex(BucketKey: Text[250]; SubUnits: Decimal; ItemCapacity: Decimal): Integer
    begin
        // All items in the same bucket go to the same wave (wave 1) for mixed loads
        exit(AllocateBucketWave(BucketKey, SubUnits, ItemCapacity));
    end;

    local procedure DetermineBucketWaveIndexWithWeight(BucketKey: Text[250]; SubUnits: Decimal; ItemCapacity: Decimal; ItemNo: Code[20]; ParentLoadUnitCode: Code[10]): Integer
    var
        WaveIndex: Integer;
        ItemWeight: Decimal;
        MaxWeight: Decimal;
    begin
        // Get item weight for this allocation
        ItemWeight := GetItemTotalWeight(ItemNo, SubUnits);

        // Get max weight from parent load unit (passed in, not looked up)
        MaxWeight := 0;
        if ParentLoadUnitCode <> '' then
            MaxWeight := GetParentLoadUnitMaxWeight(ParentLoadUnitCode);

        // Allocate to wave considering weight constraints
        WaveIndex := AllocateBucketWaveWithWeight(BucketKey, SubUnits, ItemCapacity, ItemWeight, MaxWeight);
        exit(WaveIndex);
    end;

    local procedure AllocateBucketWaveWithWeight(BucketKey: Text[250]; SubUnits: Decimal; ItemCapacity: Decimal; ItemWeight: Decimal; MaxWeight: Decimal): Integer
    var
        WaveIndex: Integer;
        UsageKey: Text[260];
        CurrentUsage: Decimal;
        CurrentWeight: Decimal;
        ContainerEquivalent: Decimal;
    begin
        // Start with current wave index
        WaveIndex := EnsureWaveIndexInitialized(BucketKey);

        if ItemCapacity <= 0 then
            ContainerEquivalent := 1
        else
            ContainerEquivalent := SubUnits / ItemCapacity;

        // Check if adding to current wave would exceed weight limit
        if (MaxWeight > 0) and (ItemWeight > 0) then begin
            UsageKey := BuildBucketWaveUsageKey(BucketKey, WaveIndex);
            CurrentWeight := GetWaveWeight(UsageKey);

            // If adding this item would exceed max weight, create a new wave
            if (CurrentWeight + ItemWeight) > MaxWeight then begin
                WaveIndex := WaveIndex + 1;
                BucketWaveCurrentIndex.Set(BucketKey, WaveIndex);
                UsageKey := BuildBucketWaveUsageKey(BucketKey, WaveIndex);
                CurrentWeight := 0;
                CurrentUsage := 0;
            end else begin
                CurrentUsage := GetWaveUsage(UsageKey);
            end;

            // Update weight tracking for this wave
            BucketWaveWeight.Set(UsageKey, CurrentWeight + ItemWeight);
        end else begin
            UsageKey := BuildBucketWaveUsageKey(BucketKey, WaveIndex);
            CurrentUsage := GetWaveUsage(UsageKey);
        end;

        // Accumulate container equivalents in the wave
        CurrentUsage += ContainerEquivalent;
        BucketWaveUsage.Set(UsageKey, CurrentUsage);

        exit(WaveIndex);
    end;

    local procedure GetWaveWeight(UsageKey: Text[260]): Decimal
    var
        Weight: Decimal;
    begin
        if BucketWaveWeight.Get(UsageKey, Weight) then
            exit(Weight);
        exit(0);
    end;

    local procedure AllocateBucketWave(BucketKey: Text[250]; SubUnits: Decimal; ItemCapacity: Decimal): Integer
    var
        WaveIndex: Integer;
        UsageKey: Text[260];
        CurrentUsage: Decimal;
        ContainerEquivalent: Decimal;
    begin
        // For mixed loads: keep all items from the same bucket in the same wave (wave 1)
        // This allows multiple items to share containers and maximizes fill efficiency
        // The Fill % calculation will determine how many actual containers are needed
        WaveIndex := EnsureWaveIndexInitialized(BucketKey);

        if ItemCapacity <= 0 then
            ContainerEquivalent := 1
        else
            ContainerEquivalent := SubUnits / ItemCapacity;

        UsageKey := BuildBucketWaveUsageKey(BucketKey, WaveIndex);
        CurrentUsage := GetWaveUsage(UsageKey);

        // Accumulate container equivalents in the same wave
        // Don't create new waves - let all items share the same batch for mixed loads
        CurrentUsage += ContainerEquivalent;
        BucketWaveUsage.Set(UsageKey, CurrentUsage);
        exit(WaveIndex);
    end;

    local procedure EnsureWaveIndexInitialized(BucketKey: Text[250]): Integer
    var
        WaveIndex: Integer;
    begin
        if not BucketWaveCurrentIndex.Get(BucketKey, WaveIndex) then begin
            WaveIndex := 1;
            BucketWaveCurrentIndex.Add(BucketKey, WaveIndex);
        end;
        exit(WaveIndex);
    end;

    local procedure BuildBucketWaveUsageKey(BucketKey: Text[250]; WaveIndex: Integer): Text[260]
    begin
        exit(StrSubstNo('%1|W%2', BucketKey, Format(WaveIndex)));
    end;

    local procedure GetWaveUsage(UsageKey: Text[260]): Decimal
    var
        Usage: Decimal;
    begin
        if BucketWaveUsage.Get(UsageKey, Usage) then
            exit(Usage);
        exit(0);
    end;

    local procedure RecordPendingBucketKey(EntryNo: Integer; BucketKey: Text[250])
    begin
        PendingBucketKeyByEntry.Set(EntryNo, BucketKey);
    end;

    local procedure GetPendingBucketKey(EntryNo: Integer): Text[250]
    var
        BucketKey: Text[250];
    begin
        if PendingBucketKeyByEntry.Get(EntryNo, BucketKey) then
            exit(BucketKey);
        exit('');
    end;

    local procedure GetNextPendingEntryNo(): Integer
    begin
        NextPendingEntryNo += 1;
        exit(NextPendingEntryNo);
    end;

    local procedure ResetPendingSuggestions()
    begin
        PendingSuggestions.Reset();
        PendingSuggestions.DeleteAll();
        Clear(PendingBucketKeyByEntry);
        NextPendingEntryNo := 0;
    end;

    local procedure CalculateSubUnits(Quantity: Decimal; UnitsPerSubUnit: Decimal; ItemNo: Code[20]): Decimal
    var
        ItemLoad: Record "WLM Item Loading Unit";
    begin
        if Quantity <= 0 then
            exit(0);

        // UnitsPerSubUnit <= 0 or < 1 means either undefined or misconfigured
        // In these cases, treat Sub Units = Base Quantity (1:1 ratio)
        // This prevents massive inflation when UnitsPerSubUnit is a small fraction
        if UnitsPerSubUnit < 1 then
            exit(ROUND(Quantity, 1, '>'));

        // Respect Allow Partial Sub Unit when enabled on the item loading unit.
        if (ItemNo <> '') and ItemLoad.Get(ItemNo) then
            if ItemLoad.AllowPartialSubUnit then
                exit(ROUND(Quantity / UnitsPerSubUnit, 0.00001, '='));

        exit(ROUND(Quantity / UnitsPerSubUnit, 1, '>'));
    end;

    local procedure DetermineReleaseDate(RequiredDate: Date; SuggestionType: Enum "WLM Load Suggestion Type"; ItemNo: Code[20]): Date
    var
        Item: Record Item;
        LeadFormula: DateFormula;
        LeadText: Text;
        ReleaseDate: Date;
    begin
        ReleaseDate := RequiredDate;
        if ReleaseDate = 0D then
            ReleaseDate := WorkDate;

        if SuggestionType <> SuggestionType::Purchase then
            exit(EnsureFutureDate(ReleaseDate));

        if not Item.Get(ItemNo) then
            exit(ReleaseDate);

        LeadFormula := Item."Lead Time Calculation";
        LeadText := Format(LeadFormula);
        LeadText := DelChr(LeadText, '=', ' ');
        if LeadText = '' then
            exit(EnsureFutureDate(ReleaseDate));

        ReleaseDate := CalcDate(StrSubstNo('<-%1>', LeadText), ReleaseDate);
        if ReleaseDate = 0D then
            ReleaseDate := RequiredDate;
        exit(EnsureFutureDate(ReleaseDate));
    end;

    local procedure EnforceVendorCapacity(VendorNo: Code[20]; LoadUnitCode: Code[10]; ParentUnitsNeeded: Decimal; ProposedReleaseDate: Date): Date
    var
        AttemptDate: Date;
        Attempt: Integer;
        Capacity: Decimal;
        HasRecord: Boolean;
        WeekNo: Integer;
        YearNo: Integer;
        LastHasRecord: Boolean;
        LastYearNo: Integer;
        LastWeekNo: Integer;
        LastCapacity: Decimal;
        LastScheduledDate: Date;
    begin
        if (VendorNo = '') or (LoadUnitCode = '') or (ParentUnitsNeeded <= 0) then
            exit(ProposedReleaseDate);

        AttemptDate := ProposedReleaseDate;
        for Attempt := 1 to 26 do begin
            HasRecord := GetVendorCapacityForDate(VendorNo, LoadUnitCode, AttemptDate, Capacity, WeekNo, YearNo);
            if not HasRecord then
                exit(AttemptDate);

            LastHasRecord := true;
            LastWeekNo := WeekNo;
            LastYearNo := YearNo;
            LastCapacity := Capacity;
            LastScheduledDate := AttemptDate;

            if Capacity > 0 then begin
                if CanReserveVendorCapacity(VendorNo, YearNo, WeekNo, LoadUnitCode, ParentUnitsNeeded, Capacity) then begin
                    ReserveVendorCapacity(VendorNo, YearNo, WeekNo, LoadUnitCode, ParentUnitsNeeded);
                    exit(AttemptDate);
                end;
            end;

            AttemptDate := AttemptDate + 7;
        end;

        if LastHasRecord and (LastCapacity > 0) then
            ReserveVendorCapacity(VendorNo, LastYearNo, LastWeekNo, LoadUnitCode, ParentUnitsNeeded);
        if LastScheduledDate <> 0D then
            exit(LastScheduledDate);

        exit(ProposedReleaseDate);
    end;

    local procedure GetVendorCapacityForDate(VendorNo: Code[20]; LoadUnitCode: Code[10]; TargetDate: Date; var Capacity: Decimal; var WeekNo: Integer; var YearNo: Integer): Boolean
    var
        VendorCap: Record "WLM Vendor Capacity";
    begin
        WeekNo := Date2DWY(TargetDate, 2);
        YearNo := Date2DWY(TargetDate, 3);

        if VendorCap.Get(VendorNo, YearNo, WeekNo, LoadUnitCode) then begin
            Capacity := VendorCap.OutputQty;
            exit(true);
        end;

        Capacity := 0;
        exit(false);
    end;

    local procedure CanReserveVendorCapacity(VendorNo: Code[20]; YearNo: Integer; WeekNo: Integer; LoadUnitCode: Code[10]; ParentUnitsNeeded: Decimal; Capacity: Decimal): Boolean
    var
        Usage: Decimal;
    begin
        if Capacity <= 0 then
            exit(false);

        Usage := GetVendorCapacityUsage(VendorNo, YearNo, WeekNo, LoadUnitCode);
        exit((Capacity - Usage) >= ParentUnitsNeeded);
    end;

    local procedure ReserveVendorCapacity(VendorNo: Code[20]; YearNo: Integer; WeekNo: Integer; LoadUnitCode: Code[10]; ParentUnits: Decimal)
    var
        CapacityKey: Text[80];
        Current: Decimal;
    begin
        if ParentUnits <= 0 then
            exit;

        CapacityKey := BuildVendorCapacityKey(VendorNo, YearNo, WeekNo, LoadUnitCode);
        if not VendorCapacityUsage.Get(CapacityKey, Current) then
            Current := 0;
        Current += ParentUnits;
        VendorCapacityUsage.Set(CapacityKey, Current);
    end;

    local procedure GetVendorCapacityUsage(VendorNo: Code[20]; YearNo: Integer; WeekNo: Integer; LoadUnitCode: Code[10]): Decimal
    var
        UsageKey: Text[80];
        Usage: Decimal;
    begin
        UsageKey := BuildVendorCapacityKey(VendorNo, YearNo, WeekNo, LoadUnitCode);
        if VendorCapacityUsage.Get(UsageKey, Usage) then
            exit(Usage);
        exit(0);
    end;

    local procedure BuildVendorCapacityKey(VendorNo: Code[20]; YearNo: Integer; WeekNo: Integer; LoadUnitCode: Code[10]): Text[80]
    begin
        exit(StrSubstNo('%1|%2|%3|%4', VendorNo, YearNo, WeekNo, LoadUnitCode));
    end;

    local procedure AssignLoadGroup(
        SuggestionType: Enum "WLM Load Suggestion Type";
                            DestLocation: Code[10];
                            SourceLocation: Code[10];
                            SourceVendorNo: Code[20];
                            ReleaseDate: Date;
                            WaveIndex: Integer): Guid
    var
        GroupKey: Text[150];
        GroupId: Guid;
    begin
        GroupKey := BuildLoadGroupKey(SuggestionType, DestLocation, SourceLocation, SourceVendorNo, ReleaseDate, WaveIndex);

        if LoadGroupLookup.Get(GroupKey, GroupId) then begin
            EnsureGroupDisplayOrder(GroupId, DestLocation, ReleaseDate);
            exit(GroupId);
        end;

        GroupId := CreateGuid();
        LoadGroupLookup.Add(GroupKey, GroupId);
        EnsureGroupDisplayOrder(GroupId, DestLocation, ReleaseDate);
        exit(GroupId);
    end;

    local procedure BuildLoadGroupKey(
        SuggestionType: Enum "WLM Load Suggestion Type";
                            DestLocation: Code[10];
                            SourceLocation: Code[10];
                            SourceVendorNo: Code[20];
                            ReleaseDate: Date;
                            WaveIndex: Integer): Text[150]
    var
        PeriodText: Text[10];
        EffectiveDate: Date;
        ReleaseMonth: Integer;
        ReleaseYear: Integer;
        WaveText: Text[10];
    begin
        EffectiveDate := ReleaseDate;
        if EffectiveDate = 0D then
            EffectiveDate := WorkDate;

        // Use period (YYYY-MM) instead of exact date to group items into fuller loads
        ReleaseMonth := Date2DMY(EffectiveDate, 2);
        ReleaseYear := Date2DMY(EffectiveDate, 3);
        if ReleaseMonth < 10 then
            PeriodText := StrSubstNo('%1-0%2', Format(ReleaseYear, 4), Format(ReleaseMonth))
        else
            PeriodText := StrSubstNo('%1-%2', Format(ReleaseYear, 4), Format(ReleaseMonth));

        // Include WaveIndex to enforce weight limits - each wave gets its own batch
        // Wave 1 = first batch, Wave 2 = second batch (created when weight exceeded), etc.
        WaveText := Format(WaveIndex);

        case SuggestionType of
            SuggestionType::Transfer:
                exit(StrSubstNo('TRANSFER|%1|%2|%3|W%4', DestLocation, SourceLocation, PeriodText, WaveText));
            SuggestionType::Purchase:
                exit(StrSubstNo('PURCHASE|%1|%2|%3|W%4', DestLocation, SourceVendorNo, PeriodText, WaveText));
            else
                exit(StrSubstNo('%1|%2|%3|%4|%5|W%6', Format(SuggestionType), DestLocation, SourceLocation, SourceVendorNo, PeriodText, WaveText));
        end;
    end;

    local procedure SelectBestTransferDonor(ItemNo: Code[20]; DestLocation: Code[10]; var SourceLocation: Code[10]; var AvailableQty: Decimal): Boolean
    var
        Keys: List of [Text[60]];
        KeyText: Text;
        Balance: Decimal;
        CandidateKey: Text;
        CandidateBalance: Decimal;
        CandidateLoc: Code[10];
        KeyItem: Code[20];
        KeyLoc: Code[10];
        i: Integer;
        SurplusQty: Decimal;
        ReorderPoint: Decimal;
    begin
        // Transfer logic: Only transfer from locations where:
        // 1. The location has positive balance (surplus)
        // 2. Balance exceeds their own reorder point (true surplus above par)
        // 3. Prefer locations with highest surplus to maximize transfer efficiency
        // DO NOT use the historical "at risk" flag - use real-time balance check

        AvailableQty := 0;
        SourceLocation := '';

        Clear(Keys);
        Keys := LocationBalances.Keys();
        if Keys.Count() = 0 then
            exit(false);

        CandidateKey := '';
        CandidateBalance := 0;
        for i := 1 to Keys.Count() do begin
            KeyText := Keys.Get(i);
            if not LocationBalances.Get(KeyText, Balance) then
                continue;

            ParseLocationBalanceKey(KeyText, KeyItem, KeyLoc);
            if (KeyItem <> ItemNo) or (KeyLoc = DestLocation) then
                continue;
            if Balance <= 0 then
                continue;
            if not LocationIsPlanned(KeyLoc) then
                continue;

            // Calculate true surplus: only transfer qty above the donor's own reorder point
            // This ensures we don't strip a location below their par stock level
            ReorderPoint := GetReorderPoint(KeyItem, KeyLoc);
            SurplusQty := Balance - ReorderPoint;

            // Only consider as donor if they have meaningful surplus above their own ROP
            // Require at least some cushion (e.g., 10% above ROP) to avoid edge cases
            if SurplusQty <= 0 then
                continue;

            // Select the donor with the highest surplus (most to give)
            if (CandidateKey = '') or (SurplusQty > CandidateBalance) then begin
                CandidateKey := KeyText;
                CandidateBalance := SurplusQty;  // Use surplus, not full balance
                CandidateLoc := KeyLoc;
            end;
        end;

        if CandidateKey = '' then
            exit(false);

        AvailableQty := CandidateBalance;
        SourceLocation := CandidateLoc;
        exit(AvailableQty > 0);
    end;

    local procedure StoreLocationBalance(ItemNo: Code[20]; LocationCode: Code[10]; Balance: Decimal; HasShortage: Boolean)
    var
        BalanceKey: Text[60];
    begin
        BalanceKey := BuildLocationBalanceKey(ItemNo, LocationCode);
        LocationBalances.Set(BalanceKey, Balance);
        LocationShortageFlags.Set(BalanceKey, HasShortage);
    end;

    local procedure UpdatePlannedSupply(ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal)
    var
        SupplyKey: Text[60];
        CurrentQty: Decimal;
    begin
        // Track cumulative planned supply so subsequent requirements see it
        // This enables sequential planning where Month A suggestion reduces Month B needs
        SupplyKey := BuildLocationBalanceKey(ItemNo, LocationCode);
        if PlannedSupply.Get(SupplyKey, CurrentQty) then
            PlannedSupply.Set(SupplyKey, CurrentQty + Qty)
        else
            PlannedSupply.Set(SupplyKey, Qty);
    end;

    local procedure GetPlannedSupply(ItemNo: Code[20]; LocationCode: Code[10]): Decimal
    var
        SupplyKey: Text[60];
        SupplyQty: Decimal;
    begin
        SupplyKey := BuildLocationBalanceKey(ItemNo, LocationCode);
        if PlannedSupply.Get(SupplyKey, SupplyQty) then
            exit(SupplyQty);
        exit(0);
    end;

    local procedure BuildLocationBalanceKey(ItemNo: Code[20]; LocationCode: Code[10]): Text[60]
    begin
        exit(ItemNo + '|' + LocationCode);
    end;

    local procedure ParseLocationBalanceKey(FullKey: Text; var ItemNo: Code[20]; var LocationCode: Code[10])
    var
        Pos: Integer;
        ItemText: Text;
        LocText: Text;
    begin
        Pos := StrPos(FullKey, '|');
        if Pos = 0 then begin
            ItemText := FullKey;
            LocText := '';
        end else begin
            ItemText := CopyStr(FullKey, 1, Pos - 1);
            LocText := CopyStr(FullKey, Pos + 1, StrLen(FullKey) - Pos);
        end;

        ItemNo := CopyStr(ItemText, 1, MaxStrLen(ItemNo));
        LocationCode := CopyStr(LocText, 1, MaxStrLen(LocationCode));
    end;

    local procedure EnsureGroupDisplayOrder(GroupId: Guid; DestLocation: Code[10]; ReleaseDate: Date)
    var
        DisplayKey: Text[50];
    begin
        DisplayKey := GuidToDisplayKey(GroupId);
        if LoadGroupDisplayOrder.ContainsKey(DisplayKey) then
            exit;

        LoadGroupDisplayOrder.Set(DisplayKey, GetNextGroupSequence(DestLocation, ReleaseDate));
    end;

    local procedure GetNextGroupSequence(DestLocation: Code[10]; ReleaseDate: Date): Integer
    var
        SeqKey: Text[40];
        Current: Integer;
    begin
        SeqKey := BuildGroupSequenceKey(DestLocation, ReleaseDate);
        if not LoadGroupSequenceCounters.Get(SeqKey, Current) then
            Current := 0;
        Current += 1;
        LoadGroupSequenceCounters.Set(SeqKey, Current);
        exit(Current);
    end;

    local procedure BuildGroupSequenceKey(DestLocation: Code[10]; ReleaseDate: Date): Text[40]
    begin
        exit(StrSubstNo('%1|%2', DestLocation, ReleaseDate));
    end;

    local procedure GuidToDisplayKey(GroupId: Guid): Text[50]
    begin
        exit(Format(GroupId));
    end;

    local procedure GetLoadGroupLabel(GroupId: Guid): Text[30]
    var
        DisplayKey: Text[50];
        Seq: Integer;
    begin
        DisplayKey := GuidToDisplayKey(GroupId);
        if LoadGroupDisplayOrder.Get(DisplayKey, Seq) then
            exit(StrSubstNo('Order %1', Seq));
        exit('');
    end;

    local procedure GetNextLoadBatchNo(): Text[30]
    var
        Setup: Record "WLM FcstSetup";
        NoSeries: Codeunit "No. Series";
        NextNo: Code[20];
    begin
        EnsureSetup(Setup);
        if Setup."Load Batch No. Series" = '' then
            exit(GetNextSequentialBatchNo(Setup));

        NextNo := NoSeries.GetNextNo(Setup."Load Batch No. Series", WorkDate);
        exit(CopyStr(NextNo, 1, 30));
    end;

    local procedure GetNextSequentialBatchNo(var Setup: Record "WLM FcstSetup"): Text[30]
    var
        CounterText: Text[30];
    begin
        Setup.LockTable();
        if not Setup.Get('SETUP') then
            exit('');

        Setup."Load Batch Sequence No." += 1;
        Setup.Modify(true);

        CounterText := Format(Setup."Load Batch Sequence No.");
        exit(CopyStr(CounterText, 1, 30));
    end;

    local procedure EnsureLoadBatch(
        LoadGroupId: Guid;
        SuggestionType: Enum "WLM Load Suggestion Type";
                            DestLocation: Code[10];
                            SourceLocation: Code[10];
                            VendorNo: Code[20];
                            RequiredDate: Date;
                            ReleaseDate: Date;
                            LoadUnitCode: Code[10];
                            ParentUnitsToAdd: Decimal): Text[30]
    var
        LoadBatch: Record "WLM Load Batch";
        Profile: Record "WLM Load Profile";
        BatchDescription: Text[100];
        BatchNo: Text[30];
        ProfileMatchSource: Text[30];
        ReqMonth: Integer;
        ReqYear: Integer;
        ReqPeriod: Text[10];
    begin

        if LoadBatch.Get(LoadGroupId) then begin
            UpdateBatchPlannedUnits(LoadBatch, ParentUnitsToAdd);
            exit(LoadBatch."Batch No.");
        end;

        // Calculate requirement period for the batch
        ReqMonth := Date2DMY(RequiredDate, 2);
        ReqYear := Date2DMY(RequiredDate, 3);
        // Zero-pad month properly (1 -> '01', 12 -> '12')
        if ReqMonth < 10 then
            ReqPeriod := StrSubstNo('%1-0%2', Format(ReqYear, 4), Format(ReqMonth))
        else
            ReqPeriod := StrSubstNo('%1-%2', Format(ReqYear, 4), Format(ReqMonth));

        BatchNo := GetNextLoadBatchNo();
        if BatchNo = '' then begin
            BatchNo := GetLoadGroupLabel(LoadGroupId);
            if BatchNo = '' then
                BatchNo := CopyStr(StrSubstNo('LOAD-%1', CopyStr(GuidToDisplayKey(LoadGroupId), 1, 8)), 1, MaxStrLen(LoadBatch."Batch No."));
        end;

        LoadBatch.Init();
        LoadBatch."Load Group ID" := LoadGroupId;
        LoadBatch."Batch No." := CopyStr(BatchNo, 1, MaxStrLen(LoadBatch."Batch No."));
        LoadBatch."Suggestion Type" := SuggestionType;
        LoadBatch."Destination Location Code" := DestLocation;
        LoadBatch."Source Location Code" := SourceLocation;
        LoadBatch."Vendor No." := VendorNo;
        LoadBatch."Required Date" := RequiredDate;
        LoadBatch."Release Date" := ReleaseDate;
        LoadBatch."Parent Load Unit Code" := LoadUnitCode;
        LoadBatch."Parent Units Planned" := ParentUnitsToAdd;
        LoadBatch."Requirement Period" := CopyStr(ReqPeriod, 1, MaxStrLen(LoadBatch."Requirement Period"));

        if ResolveLoadProfile(SuggestionType, DestLocation, SourceLocation, VendorNo, Profile, ProfileMatchSource) then begin
            LoadBatch."Profile Code" := Profile.Code;
            if Profile."Shipping Method Code" <> '' then
                LoadBatch."Shipping Method Code" := Profile."Shipping Method Code";
            if Profile."Parent Load Unit Code" <> '' then
                LoadBatch."Parent Load Unit Code" := Profile."Parent Load Unit Code";
            if Profile."Parent Unit Capacity" <> 0 then
                LoadBatch."Parent Unit Capacity" := Profile."Parent Unit Capacity";
            if Profile."Min Fill Percent" <> 0 then
                LoadBatch."Min Fill Percent" := Profile."Min Fill Percent";
        end;

        // If no capacity set from profile, derive from item load fit for the first item
        if LoadBatch."Parent Unit Capacity" = 0 then
            LoadBatch."Parent Unit Capacity" := GetDefaultParentCapacityForBatch(LoadBatch."Parent Load Unit Code");

        BatchDescription := BuildBatchDescription(SuggestionType, DestLocation, SourceLocation, VendorNo);
        LoadBatch.Description := CopyStr(BatchDescription, 1, MaxStrLen(LoadBatch.Description));
        LoadBatch.Insert(true);
        exit(LoadBatch."Batch No.");
    end;

    local procedure UpdateBatchPlannedUnits(var LoadBatch: Record "WLM Load Batch"; ParentUnitsToAdd: Decimal)
    begin
        if ParentUnitsToAdd = 0 then
            exit;

        LoadBatch."Parent Units Planned" := LoadBatch."Parent Units Planned" + ParentUnitsToAdd;
        LoadBatch.Modify(true);
    end;

    local procedure ResolveLoadProfile(
        SuggestionType: Enum "WLM Load Suggestion Type";
                            DestLocation: Code[10];
                            SourceLocation: Code[10];
                            VendorNo: Code[20];
        var Profile: Record "WLM Load Profile";
        var MatchSource: Text[30]): Boolean
    begin
        case SuggestionType of
            SuggestionType::Purchase:
                begin
                    if TryLoadProfile(SuggestionType, VendorNo, '', DestLocation, Profile) then begin
                        MatchSource := 'Vendor+Dest';
                        exit(true);
                    end;
                    if TryLoadProfile(SuggestionType, VendorNo, '', '', Profile) then begin
                        MatchSource := 'Vendor';
                        exit(true);
                    end;
                    if TryLoadProfile(SuggestionType, '', '', DestLocation, Profile) then begin
                        MatchSource := 'Dest';
                        exit(true);
                    end;
                end;
            SuggestionType::Transfer:
                begin
                    if TryLoadProfile(SuggestionType, '', SourceLocation, DestLocation, Profile) then begin
                        MatchSource := 'Source+Dest';
                        exit(true);
                    end;
                    if TryLoadProfile(SuggestionType, '', SourceLocation, '', Profile) then begin
                        MatchSource := 'Source';
                        exit(true);
                    end;
                    if TryLoadProfile(SuggestionType, '', '', DestLocation, Profile) then begin
                        MatchSource := 'Dest';
                        exit(true);
                    end;
                end;
            else begin
                if TryLoadProfile(SuggestionType, VendorNo, SourceLocation, DestLocation, Profile) then begin
                    MatchSource := 'Vendor+Source+Dest';
                    exit(true);
                end;
                if TryLoadProfile(SuggestionType, VendorNo, '', DestLocation, Profile) then begin
                    MatchSource := 'Vendor+Dest';
                    exit(true);
                end;
                if TryLoadProfile(SuggestionType, '', '', DestLocation, Profile) then begin
                    MatchSource := 'Dest';
                    exit(true);
                end;
            end;
        end;

        if TryLoadProfile(SuggestionType, '', '', '', Profile) then begin
            MatchSource := 'Global';
            exit(true);
        end;

        MatchSource := '';
        exit(false);
    end;

    local procedure TryLoadProfile(
        SuggestionType: Enum "WLM Load Suggestion Type";
                            VendorNo: Code[20];
                            SourceLocation: Code[10];
                            DestLocation: Code[10];
        var Profile: Record "WLM Load Profile"): Boolean
    begin
        // Find a profile that matches EXACTLY - profile fields must match or be blank (wildcard)
        Profile.Reset();
        Profile.SetRange("Suggestion Type", SuggestionType);

        // For vendor: match exactly if searching by vendor, otherwise find profiles with blank vendor (wildcard)
        if VendorNo <> '' then
            Profile.SetRange("Vendor No.", VendorNo)
        else
            Profile.SetRange("Vendor No.", '');

        // For source location: match exactly if searching by source, otherwise find profiles with blank source (wildcard)
        if SourceLocation <> '' then
            Profile.SetRange("Source Location Code", SourceLocation)
        else
            Profile.SetRange("Source Location Code", '');

        // For dest location: match exactly if searching by dest, otherwise find profiles with blank dest (wildcard)
        if DestLocation <> '' then
            Profile.SetRange("Destination Location Code", DestLocation)
        else
            Profile.SetRange("Destination Location Code", '');

        exit(Profile.FindFirst());
    end;

    local procedure GetDefaultLoadProfileSettings(var ParentLoadUnitCode: Code[10]; var ParentCapacity: Decimal; var MinFillPercent: Decimal; var AllowPartialLoad: Boolean)
    var
        Setup: Record "WLM FcstSetup";
    begin
        EnsureSetup(Setup);
        ParentLoadUnitCode := Setup."Default Parent Load Unit";
        ParentCapacity := Setup."Default Parent Unit Capacity";
        if ParentCapacity <= 0 then
            ParentCapacity := GetFallbackParentCapacity();

        MinFillPercent := Setup."Default Min Fill Percent";
        if MinFillPercent < 0 then
            MinFillPercent := 0;

        AllowPartialLoad := Setup."Default Allow Partial Load";
    end;

    local procedure GetFallbackParentCapacity(): Decimal
    begin
        exit(1);
    end;

    local procedure BuildBatchDescription(
        SuggestionType: Enum "WLM Load Suggestion Type";
                            DestLocation: Code[10];
                            SourceLocation: Code[10];
                            VendorNo: Code[20]): Text[100]
    begin
        case SuggestionType of
            SuggestionType::Transfer:
                exit(StrSubstNo('Transfer load %1 -> %2', SourceLocation, DestLocation));
            SuggestionType::Purchase:
                exit(StrSubstNo('Purchase load for %1 from %2', DestLocation, VendorNo));
        end;

        exit(StrSubstNo('Load for %1', DestLocation));
    end;

    local procedure LoadPlannedLocations()
    var
        FcstLoc: Record "WLM Fcst Location";
    begin
        Clear(PlannedLocations);
        FcstLoc.Reset();
        FcstLoc.SetRange(Active, true);
        if FcstLoc.FindSet() then
            repeat
                if not PlannedLocations.ContainsKey(FcstLoc."Location Code") then
                    PlannedLocations.Add(FcstLoc."Location Code", true);
            until FcstLoc.Next() = 0;
    end;

    local procedure LocationIsPlanned(LocationCode: Code[10]): Boolean
    begin
        if LocationCode = '' then
            exit(false);
        if PlannedLocations.Count() = 0 then
            LoadPlannedLocations();
        exit(PlannedLocations.ContainsKey(LocationCode));
    end;

    local procedure LocationAtRisk(ItemNo: Code[20]; LocationCode: Code[10]): Boolean
    var
        BalanceKey: Text[60];
        Flag: Boolean;
    begin
        BalanceKey := BuildLocationBalanceKey(ItemNo, LocationCode);
        if LocationShortageFlags.Get(BalanceKey, Flag) then
            exit(Flag);
        exit(false);
    end;

    local procedure GetPrimaryVendor(ItemNo: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        if Item.Get(ItemNo) then
            exit(Item."Vendor No.");
        exit('');
    end;

    local procedure ShouldIncludeItem(ItemNo: Code[20]): Boolean
    var
        Setup: Record "WLM FcstSetup";
        ItemRec: Record Item;
    begin
        if ItemNo = '' then
            exit(false);

        EnsureSetup(Setup);

        if ItemRec.Get(ItemNo) then begin
            if Setup."Exclude Blocked" and ItemRec.Blocked then
                exit(false);
            if Setup."Exclude Purchasing Blocked" and ItemRec."Purchasing Blocked" then
                exit(false);
            if Setup."Exclude Non-Inventory Items" and (ItemRec.Type <> ItemRec.Type::Inventory) then
                exit(false);
        end;

        exit(true);
    end;

    local procedure ClearBucketedShortages()
    begin
        Clear(BucketSubUnitTotals);
        Clear(BucketParentUnitTotals);
        Clear(BucketFillContribution);
        Clear(BucketProfileCodes);
        Clear(BucketParentCapacity);
        Clear(BucketMinFillPercent);
        Clear(BucketAllowPartial);
        Clear(BucketReleaseApproval);
        Clear(BucketParentLoadUnitCodes);
        Clear(BucketProfileSource);
        Clear(BucketAllocatedParentUnits);
        Clear(BucketWaveUsage);
        Clear(BucketWaveWeight);
        Clear(BucketWaveCurrentIndex);
        Clear(BucketTargetFillPerWave);
        Clear(BucketLanePackingRequired);
        Clear(BucketLaneWaveWidthUsed);
        Clear(BucketLaneWaveLaneCount);
        Clear(BucketLaneWaveLaneUsage);
        Clear(ParentLanePackingCache);
    end;

    local procedure GetBucketKey(SuggestionType: Enum "WLM Load Suggestion Type"; DestLocation: Code[10];
                                                     SourceLocation: Code[10];
                                                     VendorNo: Code[20];
                                                     ReleaseDate: Date): Text[250]
    var
        ReleasePeriod: Text[10];
        ReleaseMonth: Integer;
        ReleaseYear: Integer;
    begin
        // Group by requirement period (month) instead of exact date to enable efficient mixed loads
        // Items required in the same month from the same source will be bucketed together
        // NOTE: Do NOT include item's Load Unit Code here - that would split items into separate buckets
        // The Parent Load Unit Code comes from the profile, which is resolved after bucketing
        ReleaseMonth := Date2DMY(ReleaseDate, 2);
        ReleaseYear := Date2DMY(ReleaseDate, 3);
        // Zero-pad month properly (1 -> '01', 12 -> '12')
        if ReleaseMonth < 10 then
            ReleasePeriod := StrSubstNo('%1-0%2', Format(ReleaseYear, 4), Format(ReleaseMonth))
        else
            ReleasePeriod := StrSubstNo('%1-%2', Format(ReleaseYear, 4), Format(ReleaseMonth));

        exit(StrSubstNo('%1|%2|%3|%4|%5', Format(SuggestionType), DestLocation, SourceLocation, VendorNo, ReleasePeriod));
    end;

    local procedure GetDateFromBucketKey(BucketKey: Text[250]): Date
    var
        PeriodText: Text;
        YearText: Text;
        MonthText: Text;
        PeriodYear: Integer;
        PeriodMonth: Integer;
        SeparatorPos: Integer;
        LastPipePos: Integer;
        i: Integer;
    begin
        // Bucket key format: Type|DestLocation|SourceLocation|VendorNo|YYYY-MM
        // Extract the last segment (period) and convert to a date (first day of that month)

        if BucketKey = '' then
            exit(0D);

        // Find the last pipe separator
        LastPipePos := 0;
        for i := 1 to StrLen(BucketKey) do
            if BucketKey[i] = '|' then
                LastPipePos := i;

        if LastPipePos = 0 then
            exit(0D);

        // Extract period text (everything after last pipe)
        PeriodText := CopyStr(BucketKey, LastPipePos + 1);
        if StrLen(PeriodText) < 7 then // Minimum 'YYYY-MM'
            exit(0D);

        // Parse YYYY-MM format
        SeparatorPos := StrPos(PeriodText, '-');
        if SeparatorPos = 0 then
            exit(0D);

        YearText := CopyStr(PeriodText, 1, SeparatorPos - 1);
        MonthText := CopyStr(PeriodText, SeparatorPos + 1);

        if not Evaluate(PeriodYear, YearText) then
            exit(0D);
        if not Evaluate(PeriodMonth, MonthText) then
            exit(0D);

        if (PeriodYear < 2000) or (PeriodYear > 2100) then
            exit(0D);
        if (PeriodMonth < 1) or (PeriodMonth > 12) then
            exit(0D);

        // Return first day of the month
        exit(DMY2Date(1, PeriodMonth, PeriodYear));
    end;

    local procedure EnsureBucketProfileMetadata(BucketKey: Text[250]; SuggestionType: Enum "WLM Load Suggestion Type"; DestLocation: Code[10];
                                                                                          SourceLocation: Code[10];
                                                                                          VendorNo: Code[20];
                                                                                          ItemNo: Code[20])
    var
        Profile: Record "WLM Load Profile";
        AllowPartial: Boolean;
        ParentCapacity: Decimal;
        MinFill: Decimal;
        ParentLoadUnitCode: Code[10];
        ProfileMatchSource: Text[30];
        ProfileCode: Code[20];
        Existing: Boolean;
    begin
        Existing := BucketProfileCodes.ContainsKey(BucketKey);

        if not Existing then begin
            if ResolveLoadProfile(SuggestionType, DestLocation, SourceLocation, VendorNo, Profile, ProfileMatchSource) then begin
                ProfileCode := Profile.Code;
                ParentLoadUnitCode := Profile."Parent Load Unit Code";
                ParentCapacity := Profile."Parent Unit Capacity";
                MinFill := Profile."Min Fill Percent";
                AllowPartial := Profile."Allow Partial Load";
            end else begin
                GetDefaultLoadProfileSettings(ParentLoadUnitCode, ParentCapacity, MinFill, AllowPartial);
                ProfileCode := '';
                ProfileMatchSource := 'Fallback';
            end;

            BucketProfileCodes.Add(BucketKey, ProfileCode);
            BucketParentCapacity.Add(BucketKey, ParentCapacity);
            BucketMinFillPercent.Add(BucketKey, MinFill);
            BucketAllowPartial.Add(BucketKey, AllowPartial);

            if ParentLoadUnitCode <> '' then
                BucketParentLoadUnitCodes.Add(BucketKey, ParentLoadUnitCode);
            if ProfileMatchSource <> '' then
                BucketProfileSource.Add(BucketKey, CopyStr(ProfileMatchSource, 1, 50));
        end else begin
            if not BucketParentLoadUnitCodes.Get(BucketKey, ParentLoadUnitCode) then
                ParentLoadUnitCode := '';
        end;

        ApplyContainerCapacity(BucketKey, ParentLoadUnitCode, ItemNo);
        RegisterBucketLanePacking(BucketKey, ParentLoadUnitCode);
    end;

    local procedure RegisterBucketLanePacking(BucketKey: Text[250]; ParentLoadUnitCode: Code[10])
    var
        RequiresLanePacking: Boolean;
    begin
        if BucketKey = '' then
            exit;

        if ParentLoadUnitCode <> '' then
            RequiresLanePacking := ParentUnitUsesLanePacking(ParentLoadUnitCode)
        else
            RequiresLanePacking := false;

        BucketLanePackingRequired.Set(BucketKey, RequiresLanePacking);
    end;

    local procedure BucketRequiresLanePacking(BucketKey: Text[250]): Boolean
    var
        Enabled: Boolean;
    begin
        if BucketLanePackingRequired.Get(BucketKey, Enabled) then
            exit(Enabled);
        exit(false);
    end;

    local procedure ParentUnitUsesLanePacking(ParentLoadUnitCode: Code[10]): Boolean
    var
        ParentUnit: Record "WLM Order Loading Unit";
        CachedValue: Boolean;
    begin
        if ParentLoadUnitCode = '' then
            exit(false);

        if ParentLanePackingCache.Get(ParentLoadUnitCode, CachedValue) then
            exit(CachedValue);

        if (ParentLoadUnitCode <> '') and ParentUnit.Get(ParentLoadUnitCode) then begin
            CachedValue := ParentUnit."Use Lane Packing";
            ParentLanePackingCache.Set(ParentLoadUnitCode, CachedValue);
            exit(CachedValue);
        end;

        ParentLanePackingCache.Set(ParentLoadUnitCode, false);
        exit(false);
    end;

    local procedure ApplyContainerCapacity(BucketKey: Text[250]; ParentLoadUnitCode: Code[10]; ItemNo: Code[20])
    var
        DerivedCapacity: Decimal;
        ExistingCapacity: Decimal;
    begin
        if (BucketKey = '') or (ParentLoadUnitCode = '') or (ItemNo = '') then
            exit;

        DerivedCapacity := CalculateUnitsPerParent(ParentLoadUnitCode, ItemNo);
        if DerivedCapacity <= 0 then
            exit;

        if not BucketParentCapacity.Get(BucketKey, ExistingCapacity) then
            ExistingCapacity := 0;

        if ExistingCapacity > 0 then
            exit; // keep configured capacity when provided

        BucketParentCapacity.Set(BucketKey, DerivedCapacity);
    end;

    local procedure CalculateUnitsPerParent(ParentLoadUnitCode: Code[10]; ItemNo: Code[20]): Decimal
    var
        ParentUnit: Record "WLM Order Loading Unit";
        ItemLoad: Record "WLM Item Loading Unit";
        DimensionalCapacity: Decimal;
        WeightCapacity: Decimal;
        HasWeightLimit: Boolean;
        Fit: Record "WLM Item Load Fit";
        FitMgt: Codeunit "WLM Item Load Fit Mgt";
    begin
        if (ParentLoadUnitCode = '') or (ItemNo = '') then
            exit(0);

        if not ParentUnit.Get(ParentLoadUnitCode) then
            exit(0);

        if not ItemLoad.Get(ItemNo) then
            exit(0);

        // Prefer persisted fit profile; compute and store if missing.
        if FitMgt.GetFit(ParentLoadUnitCode, ItemNo, Fit) then
            DimensionalCapacity := Fit."Units Per Parent"
        else begin
            FitMgt.ComputeAndStoreFit(ParentLoadUnitCode, ItemNo);
            if FitMgt.GetFit(ParentLoadUnitCode, ItemNo, Fit) then
                DimensionalCapacity := Fit."Units Per Parent"
            else
                DimensionalCapacity := 0;
        end;

        WeightCapacity := ComputeWeightCapacity(ParentUnit, ItemLoad, HasWeightLimit);

        if DimensionalCapacity <= 0 then begin
            if HasWeightLimit then
                exit(WeightCapacity);
            exit(0);
        end;

        if not HasWeightLimit then
            exit(DimensionalCapacity);

        if WeightCapacity <= 0 then
            exit(0);

        if WeightCapacity < DimensionalCapacity then
            exit(WeightCapacity);
        exit(DimensionalCapacity);
    end;

    local procedure ComputeDimensionalCapacity(ParentUnit: Record "WLM Order Loading Unit"; ItemLoad: Record "WLM Item Loading Unit"): Decimal
    var
        DefaultOrientation: Decimal;
        RotatedOrientation: Decimal;
    begin
        if (ParentUnit.InteriorLength <= 0) or (ParentUnit.InteriorWidth <= 0) or (ParentUnit.InteriorHeight <= 0) then
            exit(0);
        if (ItemLoad."Unit Length" <= 0) or (ItemLoad."Unit Width" <= 0) or (ItemLoad."Unit Height" <= 0) then
            exit(0);

        DefaultOrientation := EvaluateOrientationCapacity(
            ParentUnit.InteriorLength,
            ParentUnit.InteriorWidth,
            ParentUnit.InteriorHeight,
            ItemLoad."Unit Length",
            ItemLoad."Unit Width",
            ItemLoad."Unit Height",
            ItemLoad.CanStack);

        if not ItemLoad.CanRotate then
            exit(DefaultOrientation);

        RotatedOrientation := EvaluateOrientationCapacity(
            ParentUnit.InteriorLength,
            ParentUnit.InteriorWidth,
            ParentUnit.InteriorHeight,
            ItemLoad."Unit Width",
            ItemLoad."Unit Length",
            ItemLoad."Unit Height",
            ItemLoad.CanStack);

        if RotatedOrientation > DefaultOrientation then
            exit(RotatedOrientation);
        exit(DefaultOrientation);
    end;

    local procedure EvaluateOrientationCapacity(ParentLength: Decimal; ParentWidth: Decimal; ParentHeight: Decimal; ItemLength: Decimal; ItemWidth: Decimal; ItemHeight: Decimal; AllowStack: Boolean): Decimal
    var
        AlongLength: Decimal;
        AlongWidth: Decimal;
        AlongHeight: Decimal;
        HeightFit: Decimal;
    begin
        if (ParentLength <= 0) or (ParentWidth <= 0) or (ParentHeight <= 0) then
            exit(0);
        if (ItemLength <= 0) or (ItemWidth <= 0) or (ItemHeight <= 0) then
            exit(0);

        AlongLength := ROUND(ParentLength / ItemLength, 1, '<');
        AlongWidth := ROUND(ParentWidth / ItemWidth, 1, '<');
        HeightFit := ROUND(ParentHeight / ItemHeight, 1, '<');

        if not AllowStack then begin
            if HeightFit >= 1 then
                AlongHeight := 1
            else
                AlongHeight := 0;
        end else
            AlongHeight := HeightFit;

        if (AlongLength <= 0) or (AlongWidth <= 0) or (AlongHeight <= 0) then
            exit(0);

        exit(AlongLength * AlongWidth * AlongHeight);
    end;

    local procedure ComputeWeightCapacity(ParentUnit: Record "WLM Order Loading Unit"; ItemLoad: Record "WLM Item Loading Unit"; var HasWeightLimit: Boolean): Decimal
    var
        UnitsByWeight: Decimal;
    begin
        HasWeightLimit := (ParentUnit.MaxWeight > 0) and (ItemLoad."Unit Weight" > 0);
        if not HasWeightLimit then
            exit(0);

        UnitsByWeight := ROUND(ParentUnit.MaxWeight / ItemLoad."Unit Weight", 1, '<');
        exit(UnitsByWeight);
    end;

    local procedure AddBucketContribution(BucketKey: Text[250]; SubUnits: Decimal; ParentUnits: Decimal; ItemNo: Code[20])
    var
        CurrentTotal: Decimal;
        ParentTotal: Decimal;
        FillContrib: Decimal;
        ItemCapacity: Decimal;
        ParentLoadUnitCode: Code[10];
        ParentCapacity: Decimal;
    begin
        if SubUnits <= 0 then
            exit;

        if not BucketSubUnitTotals.Get(BucketKey, CurrentTotal) then
            CurrentTotal := 0;

        CurrentTotal += SubUnits;
        BucketSubUnitTotals.Set(BucketKey, CurrentTotal);

        if ParentUnits <= 0 then
            exit;

        if not BucketParentUnitTotals.Get(BucketKey, ParentTotal) then
            ParentTotal := 0;

        ParentTotal += ParentUnits;
        BucketParentUnitTotals.Set(BucketKey, ParentTotal);

        // Accumulate fill contribution: SubUnits / ItemCapacity
        // Try to get item-specific capacity first
        if not BucketFillContribution.Get(BucketKey, FillContrib) then
            FillContrib := 0;

        if BucketParentLoadUnitCodes.Get(BucketKey, ParentLoadUnitCode) then begin
            if ParentLoadUnitCode <> '' then begin
                ItemCapacity := CalculateUnitsPerParent(ParentLoadUnitCode, ItemNo);
                if ItemCapacity > 0 then begin
                    FillContrib += (SubUnits / ItemCapacity);
                    BucketFillContribution.Set(BucketKey, FillContrib);
                    exit;
                end;
            end;
        end;

        // Fallback: use ParentUnits directly as container equivalents
        // This ensures fill contribution is ALWAYS tracked
        FillContrib += ParentUnits;
        BucketFillContribution.Set(BucketKey, FillContrib);
    end;

    local procedure GetReorderPoint(ItemNo: Code[20]; LocationCode: Code[10]): Decimal
    var
        CacheKey: Text[60];
        CachedValue: Decimal;
        SKU: Record "Stockkeeping Unit";
        SKUReorder: Decimal;
        ParReorder: Decimal;
    begin
        CacheKey := BuildLocationBalanceKey(ItemNo, LocationCode);
        if ReorderPointCache.Get(CacheKey, CachedValue) then
            exit(CachedValue);

        if (ItemNo = '') or (LocationCode = '') then begin
            ReorderPointCache.Set(CacheKey, 0);
            exit(0);
        end;

        // Get SKU Reorder Point (manually defined)
        SKUReorder := 0;
        SKU.Reset();
        SKU.SetRange("Item No.", ItemNo);
        SKU.SetRange("Location Code", LocationCode);
        SKU.SetRange("Variant Code", '');
        if SKU.FindFirst() then
            SKUReorder := SKU."Reorder Point";

        // Get Par Reorder Point (auto-calculated from forecast)
        ParReorder := ComputeParReorderPoint(ItemNo, LocationCode);

        // Use the higher of the two values
        if ParReorder > SKUReorder then
            CachedValue := ParReorder
        else
            CachedValue := SKUReorder;

        ReorderPointCache.Set(CacheKey, CachedValue);
        exit(CachedValue);
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

        // Use a 12-month forward window to average forecast demand per month
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

    local procedure GetItemLoadInfo(ItemNo: Code[20]; var LoadUnitCode: Code[10]; var UnitsPerSubUnit: Decimal)
    var
        ItemLoad: Record "WLM Item Loading Unit";
    begin
        LoadUnitCode := '';
        UnitsPerSubUnit := 0;

        if ItemLoad.Get(ItemNo) then begin
            LoadUnitCode := ItemLoad."Default Loading Unit";
            UnitsPerSubUnit := ItemLoad."Units per Sub Unit";

            if UnitsPerSubUnit = 0 then
                UnitsPerSubUnit := 1;
        end else
            UnitsPerSubUnit := 1;
    end;

    local procedure CalculateParentUnits(SubUnitsNeeded: Decimal; LoadUnitCode: Code[10]; ItemNo: Code[20]): Decimal
    var
        Capacity: Decimal;
    begin
        if SubUnitsNeeded <= 0 then
            exit(0);

        Capacity := CalculateUnitsPerParent(LoadUnitCode, ItemNo);
        if Capacity <= 0 then
            exit(ROUND(SubUnitsNeeded, 1, '>'));

        exit(ROUND(SubUnitsNeeded / Capacity, 1, '>'));
    end;

    local procedure ApplyOrderMultiple(var Stage: Record "WLM Load Suggestion"; ParentLoadUnitCode: Code[10])
    var
        Fit: Record "WLM Item Load Fit";
        FitMgt: Codeunit "WLM Item Load Fit Mgt";
        OrderMultiple: Decimal;
        OldSubUnits: Decimal;
        OldParentUnits: Decimal;
        Ratio: Decimal;
    begin
        if (ParentLoadUnitCode = '') or (Stage."Item No." = '') then
            exit;

        if not FitMgt.GetFit(ParentLoadUnitCode, Stage."Item No.", Fit) then begin
            FitMgt.ComputeAndStoreFit(ParentLoadUnitCode, Stage."Item No.");
            if not FitMgt.GetFit(ParentLoadUnitCode, Stage."Item No.", Fit) then
                exit;
        end;

        if not Fit."Enforce Order Multiples" then
            exit;

        OrderMultiple := Fit."Order Multiple";
        if OrderMultiple <= 0 then
            exit;

        OldSubUnits := Stage."Sub Units";
        OldParentUnits := Stage."Parent Units";

        Stage."Sub Units" := ForceToOrderMultiple(OldSubUnits, OrderMultiple);

        if (OldParentUnits > 0) and (OldSubUnits > 0) then
            Ratio := OldSubUnits / OldParentUnits
        else
            Ratio := 0;

        if Ratio > 0 then
            Stage."Parent Units" := ROUND(Stage."Sub Units" / Ratio, 1, '>')
        else
            Stage."Parent Units" := Stage."Sub Units";
    end;

    local procedure ApplyOrderMultipleToQty(Qty: Decimal; ParentLoadUnitCode: Code[10]; ItemNo: Code[20]): Decimal
    var
        Fit: Record "WLM Item Load Fit";
        FitMgt: Codeunit "WLM Item Load Fit Mgt";
        OrderMultiple: Decimal;
    begin
        if (ParentLoadUnitCode = '') or (ItemNo = '') or (Qty <= 0) then
            exit(Qty);

        if not FitMgt.GetFit(ParentLoadUnitCode, ItemNo, Fit) then begin
            FitMgt.ComputeAndStoreFit(ParentLoadUnitCode, ItemNo);
            if not FitMgt.GetFit(ParentLoadUnitCode, ItemNo, Fit) then
                exit(Qty);
        end;

        if not Fit."Enforce Order Multiples" then
            exit(Qty);

        OrderMultiple := Fit."Order Multiple";
        if OrderMultiple <= 0 then
            exit(Qty);

        exit(ForceToOrderMultiple(Qty, OrderMultiple));
    end;

    local procedure ForceToOrderMultiple(Value: Decimal; Multiple: Decimal): Decimal
    var
        Factor: Decimal;
    begin
        if Multiple <= 0 then
            exit(Value);

        Factor := ROUND(Value / Multiple, 1, '>');
        if Factor <= 0 then
            Factor := 1;

        exit(Factor * Multiple);
    end;

    local procedure GetDefaultParentCapacityForBatch(ParentLoadUnitCode: Code[10]): Decimal
    var
        Setup: Record "WLM FcstSetup";
    begin
        // Try setup default - this is the only reliable source for default capacity
        if Setup.Get('SETUP') then
            if Setup."Default Parent Unit Capacity" > 0 then
                exit(Setup."Default Parent Unit Capacity");

        // No default available
        exit(0);
    end;

    local procedure EnsureSetup(var Setup: Record "WLM FcstSetup")
    begin
        if not Setup.Get('SETUP') then begin
            Setup.Init();
            Setup.Insert(true);
        end;
    end;

    local procedure NormalizeFromDate(Value: Date): Date
    begin
        if Value <> 0D then
            exit(Value);
        exit(WorkDate);
    end;

    local procedure NormalizeToDate(Value: Date): Date
    var
        TodayDate: Date;
    begin
        if Value <> 0D then
            exit(Value);
        TodayDate := WorkDate;
        exit(CalcDate('+3M', TodayDate));
    end;

    local procedure EnsureFutureDate(Value: Date): Date
    var
        TodayDate: Date;
    begin
        TodayDate := WorkDate;
        if TodayDate = 0D then
            exit(Value);
        if (Value = 0D) or (Value < TodayDate) then
            exit(TodayDate);
        exit(Value);
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

    local procedure GetItemNetWeight(ItemNo: Code[20]): Decimal
    var
        Item: Record Item;
    begin
        if ItemNo = '' then
            exit(0);

        if not Item.Get(ItemNo) then
            exit(0);

        exit(Item."Net Weight");
    end;

    local procedure GetItemLeadTimeDays(ItemNo: Code[20]; VendorNo: Code[20]; LocationCode: Code[10]): Integer
    var
        SKU: Record "Stockkeeping Unit";
        ItemVendor: Record "Item Vendor";
        Item: Record Item;
        Setup: Record "WLM FcstSetup";
        LeadTimeFormula: DateFormula;
        DefaultDays: Integer;
    begin
        // Default lead time from setup
        DefaultDays := 28;
        if Setup.Get('SETUP') then
            if Setup."Default Lead Time Days" > 0 then
                DefaultDays := Setup."Default Lead Time Days";

        // Priority 1: Try SKU for most specific lead time
        if (ItemNo <> '') and (LocationCode <> '') then begin
            SKU.Reset();
            SKU.SetRange("Item No.", ItemNo);
            SKU.SetRange("Location Code", LocationCode);
            if SKU.FindFirst() then
                if Format(SKU."Lead Time Calculation") <> '' then begin
                    LeadTimeFormula := SKU."Lead Time Calculation";
                    exit(DateFormulaToDays(LeadTimeFormula));
                end;
        end;

        // Priority 2: Try Item Vendor for vendor-specific lead time
        if (ItemNo <> '') and (VendorNo <> '') then begin
            ItemVendor.Reset();
            ItemVendor.SetRange("Item No.", ItemNo);
            ItemVendor.SetRange("Vendor No.", VendorNo);
            if ItemVendor.FindFirst() then
                if Format(ItemVendor."Lead Time Calculation") <> '' then begin
                    LeadTimeFormula := ItemVendor."Lead Time Calculation";
                    exit(DateFormulaToDays(LeadTimeFormula));
                end;
        end;

        // Priority 3: Try Item for generic lead time
        if ItemNo <> '' then begin
            if Item.Get(ItemNo) then
                if Format(Item."Lead Time Calculation") <> '' then begin
                    LeadTimeFormula := Item."Lead Time Calculation";
                    exit(DateFormulaToDays(LeadTimeFormula));
                end;
        end;

        // Default from setup
        exit(DefaultDays);
    end;

    local procedure DateFormulaToDays(Formula: DateFormula): Integer
    var
        StartDate: Date;
        EndDate: Date;
    begin
        StartDate := WorkDate;
        if StartDate = 0D then
            StartDate := Today;

        EndDate := CalcDate(Formula, StartDate);
        if EndDate = 0D then
            exit(28);

        exit(EndDate - StartDate);
    end;

    var
        RemainingQtyIsFlowField: Boolean;
        RemainingQtyChecked: Boolean;
        LocationBalances: Dictionary of [Text[60], Decimal];
        PlannedSupply: Dictionary of [Text[60], Decimal];
        VendorCapacityUsage: Dictionary of [Text[80], Decimal];
        LoadGroupLookup: Dictionary of [Text[150], Guid];
        LoadGroupSequenceCounters: Dictionary of [Text[40], Integer];
        LoadGroupDisplayOrder: Dictionary of [Text[50], Integer];
        LocationShortageFlags: Dictionary of [Text[60], Boolean];
        PlannedLocations: Dictionary of [Code[10], Boolean];
        ReorderPointCache: Dictionary of [Text[60], Decimal];
        BucketSubUnitTotals: Dictionary of [Text[250], Decimal];
        BucketParentUnitTotals: Dictionary of [Text[250], Decimal];
        BucketFillContribution: Dictionary of [Text[250], Decimal];
        BucketProfileCodes: Dictionary of [Text[250], Code[20]];
        BucketParentCapacity: Dictionary of [Text[250], Decimal];
        BucketMinFillPercent: Dictionary of [Text[250], Decimal];
        BucketAllowPartial: Dictionary of [Text[250], Boolean];
        BucketParentLoadUnitCodes: Dictionary of [Text[250], Code[10]];
        BucketProfileSource: Dictionary of [Text[250], Text[50]];
        BucketReleaseApproval: Dictionary of [Text[250], Boolean];
        BucketAllocatedParentUnits: Dictionary of [Text[250], Decimal];
        BucketWaveUsage: Dictionary of [Text[260], Decimal];
        BucketWaveWeight: Dictionary of [Text[260], Decimal];
        BucketWaveCurrentIndex: Dictionary of [Text[250], Integer];
        BucketTargetFillPerWave: Dictionary of [Text[250], Decimal];
        BucketLanePackingRequired: Dictionary of [Text[250], Boolean];
        BucketLaneWaveWidthUsed: Dictionary of [Text[270], Decimal];
        BucketLaneWaveLaneCount: Dictionary of [Text[280], Integer];
        BucketLaneWaveLaneUsage: Dictionary of [Text[280], Decimal];
        ParentLanePackingCache: Dictionary of [Code[10], Boolean];
        PendingSuggestions: Record "WLM Load Suggestion" temporary;
        PendingBucketKeyByEntry: Dictionary of [Integer, Text[250]];
        NextPendingEntryNo: Integer;
}

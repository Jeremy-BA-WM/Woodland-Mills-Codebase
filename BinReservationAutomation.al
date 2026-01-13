// ===============================================
// Blocked Bin Auto Reservation - Full Drop-In (v3.4.1)
// - Per-item two-phase planner (pre-create all anchors, then additive reservations)
// - Per-location FreeAvail budget so first bin can't monopolize supply
// - No-shrink enforcement that never throws (uses TryFunction + logs)
// - Hard Bind (Order-to-Order) after reservation
// - Admin toggles: Use Open Bin Qty, Allow Downsize, Hard Bind
// - Legacy "Bin Code Filter" column retained for data storage only (no runtime usage)
// ===============================================


// =============================================
// Table 80061: Blocked Bin Auto Reservation (Header)
// =============================================
table 80061 "Blocked Bin Auto Reservation"
{
    Caption = 'Blocked Bin Auto Reservation';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Code; Code[20]) { Caption = 'Code'; }
        field(2; Description; Text[100]) { Caption = 'Description'; }
        field(3; Enabled; Boolean) { Caption = 'Enabled'; }

        field(4; "Use Open Bin Qty"; Boolean)
        {
            Caption = 'Use Open Bin Qty (exclude picks)';
            ToolTip = 'If ON, Desired per bin = Quantity (Base) - Pick Quantity (Base). If OFF, Desired = Quantity (Base).';
        }

        field(5; "Allow Downsize"; Boolean)
        {
            Caption = 'Allow Downsize (may cancel existing reservations)';
            ToolTip = 'Keep OFF to preserve existing reservations while enabling more bins.';
        }

        field(6; "Hard Bind Reservations"; Boolean)
        {
            Caption = 'Hard Bind Reservations (Order-to-Order)';
            ToolTip = 'Prevents existing reservations from being reallocated when new bins are enabled.';
            InitValue = true;
        }
    }

    keys { key(PK; Code) { Clustered = true; } }
}


// =============================================
// Table 80062: Blocked Bin Auto Resv. Line
// =============================================
table 80062 "Blocked Bin Auto Resv. Line"
{
    Caption = 'Blocked Bin Auto Reservation Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Header Code"; Code[20])
        {
            Caption = 'Header Code';
            TableRelation = "Blocked Bin Auto Reservation".Code;
        }

        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
        }

        field(3; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location.Code;
            NotBlank = true;

            trigger OnValidate()
            var
                BinRec: Record Bin;
            begin
                if "Bin Code" <> '' then
                    if not BinRec.Get("Location Code", "Bin Code") then
                        "Bin Code" := '';
            end;
        }

        // Legacy filter retained (backward compatibility)
        field(4; "Bin Code Filter"; Text[50])
        {
            Caption = 'Bin Code Filter (legacy)';
            ObsoleteState = Pending;
            ObsoleteReason = 'Use explicit Bin Code.';
            ObsoleteTag = 'v2.1';
        }

        field(6; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = Bin.Code WHERE("Location Code" = FIELD("Location Code"));
            NotBlank = true;
        }

        field(5; Enabled; Boolean) { Caption = 'Enabled'; }
    }

    keys
    {
        key(PK; "Header Code", "Line No.") { Clustered = true; }
        key(Key2; "Header Code", "Location Code", "Bin Code") { }
    }

    trigger OnInsert()
    var
        L2: Record "Blocked Bin Auto Resv. Line";
    begin
        if "Line No." = 0 then begin
            L2.Reset();
            L2.SetCurrentKey("Header Code", "Line No.");
            L2.SetRange("Header Code", "Header Code");
            if L2.FindLast() then "Line No." := L2."Line No." + 1 else "Line No." := 0;
        end;
    end;
}


// =======================================================
// Page 80065: Blocked Bin Auto Resv. Lines (ListPart)
// =======================================================
page 80065 "Blocked Bin Auto Resv. Lines"
{
    PageType = ListPart;
    SourceTable = "Blocked Bin Auto Resv. Line";
    ApplicationArea = All;
    Caption = 'Bin Filters';

    layout
    {
        area(content)
        {
            repeater(Rep)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field("Location Code"; Rec."Location Code") { ApplicationArea = All; }
                field("Bin Code"; Rec."Bin Code") { ApplicationArea = All; }
                field(Enabled; Rec.Enabled) { ApplicationArea = All; }
            }
        }
    }
}


// ====================================================================
// Page 80054: Block Bin Auto-Reservation (Card)
// ====================================================================
page 80054 "Block Bin Auto-Reservation"
{
    PageType = Card;
    SourceTable = "Blocked Bin Auto Reservation";
    ApplicationArea = All;
    Caption = 'Block Bin Auto-Reservation';
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(SetupHeader)
            {
                Caption = 'Setup';
                field(Code; Rec.Code) { ApplicationArea = All; Editable = false; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field(Enabled; Rec.Enabled) { ApplicationArea = All; }
            }

            group(RuntimeInfo)
            {
                Caption = 'Runtime';
                field(JournalTemplate; JnlTemplateName) { ApplicationArea = All; Caption = 'Journal Template'; Editable = false; }
                field(JournalBatch; JnlBatchName) { ApplicationArea = All; Caption = 'Journal Batch'; Editable = false; }

                field(UseOpenQty; UseOpenBinQtyUI)
                {
                    ApplicationArea = All;
                    Caption = 'Use Open Bin Qty (exclude picks)';
                    ToolTip = 'Desired per bin = Quantity (Base) - Pick Quantity (Base).';
                    trigger OnValidate()
                    var
                        C: Codeunit "HSResvDirect";
                    begin
                        C.SetUseOpenBinQty(UseOpenBinQtyUI);
                    end;
                }

                field(ReclaimEnabled; ReclaimWithinAnchorsEnabledUI)
                {
                    ApplicationArea = All;
                    Caption = 'Rebalance across HS anchors (non-preemptive)';
                    ToolTip = 'Short anchors can reclaim EXCESS only (guarded by total Desired vs total Reserved).';
                    trigger OnValidate()
                    var
                        C: Codeunit "HSResvDirect";
                    begin
                        C.SetReclaimEnabled(ReclaimWithinAnchorsEnabledUI);
                    end;
                }

                field(AllowDownsize; AllowDownsizeUI)
                {
                    ApplicationArea = All;
                    Caption = 'Allow Downsize (may cancel existing reservations)';
                    ToolTip = 'Keep OFF to strictly preserve existing reservations while enabling more bins.';
                    trigger OnValidate()
                    var
                        C: Codeunit "HSResvDirect";
                    begin
                        C.SetAllowDownsize(AllowDownsizeUI);
                    end;
                }

                field(HardBind; HardBindUI)
                {
                    ApplicationArea = All;
                    Caption = 'Hard Bind Reservations (Order-to-Order)';
                    ToolTip = 'Prevents existing reservations from being reallocated when new bins are enabled.';
                    trigger OnValidate()
                    var
                        C: Codeunit "HSResvDirect";
                    begin
                        C.SetHardBind(HardBindUI);
                    end;
                }
            }

            group(BinFilters)
            {
                Caption = 'Bin Filters (Scope for Auto-Reservation)';
                part(Lines; "Blocked Bin Auto Resv. Lines")
                {
                    ApplicationArea = All;
                    SubPageLink = "Header Code" = field(Code);
                }
            }

            group(Notes)
            {
                field(Notice; NoticeTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Notes';
                    Editable = false;
                    MultiLine = true;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(SyncNow)
            {
                Caption = 'Sync Now';
                ApplicationArea = All;
                Image = Refresh;
                trigger OnAction()
                var
                    C: Codeunit "HSResvDirect";
                begin
                    C.SyncNow();
                end;
            }

            action(ShowReservations)
            {
                Caption = 'Show Reservations';
                ApplicationArea = All;
                Image = View;
                trigger OnAction()
                var
                    C: Codeunit "HSResvDirect";
                    Res: Record "Reservation Entry";
                    Tmpl: Code[10];
                    Batch: Code[10];
                begin
                    C.GetBatch(Tmpl, Batch);
                    Res.Reset();
                    Res.SetRange("Source Type", Database::"Item Journal Line");
                    Res.SetRange("Source ID", Tmpl);
                    Res.SetRange("Source Batch Name", Batch);
                    PAGE.RunModal(PAGE::"Reservation Entries", Res);
                end;
            }

            action(ShowAllReservations)
            {
                Caption = 'Show All Reservations (No Filters)';
                ApplicationArea = All;
                Image = View;
                trigger OnAction()
                var
                    Res: Record "Reservation Entry";
                begin
                    Res.Reset();
                    PAGE.RunModal(PAGE::"Reservation Entries", Res);
                end;
            }

            action(ShowAnchors)
            {
                Caption = 'Show Anchors (IJL)';
                ApplicationArea = All;
                Image = List;
                trigger OnAction()
                var
                    C: Codeunit "HSResvDirect";
                    Tmpl: Code[10];
                    Batch: Code[10];
                    Anch: Page "HS Resv Anchors";
                begin
                    C.GetBatch(Tmpl, Batch);
                    Anch.SetBatch(Tmpl, Batch);
                    Anch.RunModal();
                end;
            }
        }
    }

    var
        JnlTemplateName: Code[10];
        JnlBatchName: Code[10];
        UseOpenBinQtyUI: Boolean;
        ReclaimWithinAnchorsEnabledUI: Boolean;
        AllowDownsizeUI: Boolean;
        HardBindUI: Boolean;
        NoticeTxt: Label 'Choose exact Location + Bins below. Keep "Allow Downsize" OFF to preserve existing reservations. "Hard Bind" prevents re-pair when new bins join.', Locked = true;

    trigger OnOpenPage()
    var
        C: Codeunit "HSResvDirect";
        H: Record "Blocked Bin Auto Reservation";
    begin
        if H.IsEmpty() then begin
            H.Init();
            H.Code := 'DEFAULT';
            H.Description := 'Bin Filter Set';
            H.Enabled := true;
            H.Insert(true);
        end;

        H.Reset();
        H.SetRange(Enabled, true);
        if not H.FindFirst() then begin H.Reset(); H.FindFirst(); end;
        Rec := H;

        C.GetBatch(JnlTemplateName, JnlBatchName);
        C.GetUseOpenBinQty(UseOpenBinQtyUI);
        C.GetReclaimEnabled(ReclaimWithinAnchorsEnabledUI);
        C.GetAllowDownsize(AllowDownsizeUI);
        C.GetHardBind(HardBindUI);
    end;
}


// =====================================
// Page 80055: HS Resv Anchors (List)
// =====================================
page 80055 "HS Resv Anchors"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "Item Journal Line";
    Caption = 'HS Reservation Anchors';
    Editable = false;

    layout
    {
        area(content)
        {
            repeater(Anchors)
            {
                field("Journal Template Name"; Rec."Journal Template Name") { ApplicationArea = All; }
                field("Journal Batch Name"; Rec."Journal Batch Name") { ApplicationArea = All; }
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field("Item No."; Rec."Item No.") { ApplicationArea = All; }
                field("Variant Code"; Rec."Variant Code") { ApplicationArea = All; }
                field("Location Code"; Rec."Location Code") { ApplicationArea = All; }
                field("Bin Code"; Rec."Bin Code") { ApplicationArea = All; }
                field(Quantity; Rec.Quantity) { ApplicationArea = All; }
                field("Quantity (Base)"; Rec."Quantity (Base)") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field("Entry Type"; Rec."Entry Type") { ApplicationArea = All; }
                field("Posting Date"; Rec."Posting Date") { ApplicationArea = All; }
                field("Document No."; Rec."Document No.") { ApplicationArea = All; }
                field("Unit of Measure Code"; Rec."Unit of Measure Code") { ApplicationArea = All; }
            }
        }
    }

    var
        Tmpl: Code[10];
        Batch: Code[10];

    procedure SetBatch(TemplateName: Code[10]; BatchName: Code[10])
    begin
        Tmpl := TemplateName;
        Batch := BatchName;
    end;

    trigger OnOpenPage()
    begin
        if Tmpl = '' then Tmpl := 'ITEM';
        if Batch = '' then Batch := 'HOLDRESV';
        Rec.Reset();
        Rec.SetRange("Journal Template Name", Tmpl);
        Rec.SetRange("Journal Batch Name", Batch);
    end;
}


// =============================
// Codeunit 80041: HSResvDirect  (per-item additive planner + non-blocking no-shrink)
// =============================
codeunit 80041 "HSResvDirect"
{
    SingleInstance = true;

    var
        IsSyncRunning: Boolean;
        JnlTemplateName: Code[10];
        JnlBatchName: Code[10];

        UseOpenBinQty: Boolean;
        ReclaimWithinAnchorsEnabled: Boolean;
        AllowDownsize: Boolean;
        HardBind: Boolean;

        AnchorSnapshot: Dictionary of [Text, Decimal];
        UsePerItemPlanner: Boolean;

        TelemetrySrc: Label 'HSResvDirect', Locked = true;
        TelemetryAreaSync: Label 'Sync', Locked = true;
        TelemetryAreaReclaim: Label 'Reclaim', Locked = true;
        TelemetryAreaDiagnose: Label 'Diagnose', Locked = true;

    // -------- Entry point --------
    procedure SyncNow()
    begin
        IsSyncRunning := false;
        EnsureJnlInfrastructure();
        LoadAdminSettings();
        TakeAnchorSnapshot();
        SyncFromConfig();
        EnforceNoShrink();
    end;

    // -------- Infra / Admin --------
    procedure EnsureJnlInfrastructure()
    var
        JTmp: Record "Item Journal Template";
        JBat: Record "Item Journal Batch";
    begin
        if JnlTemplateName = '' then JnlTemplateName := 'ITEM';
        if JnlBatchName = '' then JnlBatchName := 'HOLDRESV';

        if not JTmp.Get(JnlTemplateName) then begin
            JTmp.Init();
            JTmp.Name := JnlTemplateName;
            JTmp.Type := JTmp.Type::Item;
            JTmp.Insert(true);
        end;

        if not JBat.Get(JnlTemplateName, JnlBatchName) then begin
            JBat.Init();
            JBat."Journal Template Name" := JnlTemplateName;
            JBat.Name := JnlBatchName;
            JBat.Description := 'Blocked bin reservation anchors';
            JBat.Insert(true);
        end;
    end;

    procedure GetBatch(var TemplateName: Code[10]; var BatchName: Code[10])
    begin
        EnsureJnlInfrastructure();
        TemplateName := JnlTemplateName;
        BatchName := JnlBatchName;
    end;

    procedure GetUseOpenBinQty(var UseOpen: Boolean)
    begin
        LoadAdminSettings();
        UseOpen := UseOpenBinQty;
    end;

    procedure SetUseOpenBinQty(UseOpen: Boolean)
    begin
        UseOpenBinQty := UseOpen;
        SaveAdminSettings();
    end;

    procedure GetReclaimEnabled(var ReclaimEnabled: Boolean)
    begin
        LoadAdminSettings();
        ReclaimEnabled := ReclaimWithinAnchorsEnabled;
    end;

    procedure SetReclaimEnabled(ReclaimEnabled: Boolean)
    begin
        ReclaimWithinAnchorsEnabled := ReclaimEnabled;
    end;

    procedure GetAllowDownsize(var Allow: Boolean)
    begin
        LoadAdminSettings();
        Allow := AllowDownsize;
    end;

    procedure SetAllowDownsize(Allow: Boolean)
    begin
        AllowDownsize := Allow;
        SaveAdminSettings();
    end;

    procedure GetHardBind(var Hard: Boolean)
    begin
        LoadAdminSettings();
        Hard := HardBind;
    end;

    procedure SetHardBind(Hard: Boolean)
    begin
        HardBind := Hard;
        SaveAdminSettings();
    end;

    local procedure LoadAdminSettings()
    var
        H: Record "Blocked Bin Auto Reservation";
    begin
        H.Reset();
        H.SetRange(Enabled, true);
        if not H.FindFirst() then
            if not H.Get('DEFAULT') then begin
                H.Init();
                H.Code := 'DEFAULT';
                H.Description := 'Bin Filter Set';
                H.Enabled := true;
                H.Insert(true);
            end;
        UseOpenBinQty := H."Use Open Bin Qty";
        AllowDownsize := H."Allow Downsize";
        HardBind := H."Hard Bind Reservations";
    end;

    local procedure SaveAdminSettings()
    var
        H: Record "Blocked Bin Auto Reservation";
    begin
        H.Reset();
        H.SetRange(Enabled, true);
        if not H.FindFirst() then
            if not H.Get('DEFAULT') then begin
                H.Init();
                H.Code := 'DEFAULT';
                H.Description := 'Bin Filter Set';
                H.Enabled := true;
                H.Insert(true);
            end;
        H."Use Open Bin Qty" := UseOpenBinQty;
        H."Allow Downsize" := AllowDownsize;
        H."Hard Bind Reservations" := HardBind;
        H.Modify(true);
    end;

    // Warehouse Entry listeners (debounce)
    [EventSubscriber(ObjectType::Table, Database::"Warehouse Entry", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterWhseEntryInsert(var Rec: Record "Warehouse Entry"; RunTrigger: Boolean)
    begin
        if (Rec."Bin Code" <> '') and IsConfiguredBin(Rec."Bin Code", Rec."Location Code") then EnqueueQuickSync();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Entry", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterWhseEntryModify(var Rec: Record "Warehouse Entry"; RunTrigger: Boolean)
    begin
        if (Rec."Bin Code" <> '') and IsConfiguredBin(Rec."Bin Code", Rec."Location Code") then EnqueueQuickSync();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Entry", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterWhseEntryDelete(var Rec: Record "Warehouse Entry"; RunTrigger: Boolean)
    begin
        if (Rec."Bin Code" <> '') and IsConfiguredBin(Rec."Bin Code", Rec."Location Code") then EnqueueQuickSync();
    end;

    local procedure EnqueueQuickSync()
    var
        JQ: Record "Job Queue Entry";
        Earliest: DateTime;
    begin
        Earliest := CurrentDateTime + 60000;
        JQ.Reset();
        JQ.SetRange("Object Type to Run", JQ."Object Type to Run"::Codeunit);
        JQ.SetRange("Object ID to Run", Codeunit::"HS Resv Sync Job");
        if not JQ.FindFirst() then begin
            JQ.Init();
            JQ."Object Type to Run" := JQ."Object Type to Run"::Codeunit;
            JQ."Object ID to Run" := Codeunit::"HS Resv Sync Job";
            JQ."Earliest Start Date/Time" := Earliest;
            JQ.Description := CopyStr(Format(CurrentDateTime) + ' HS Resv Quick Sync', 1, MaxStrLen(JQ.Description));
            JQ.Insert(true);
        end else begin
            if (JQ."Earliest Start Date/Time" = 0DT) or (JQ."Earliest Start Date/Time" > Earliest) then begin
                JQ."Earliest Start Date/Time" := Earliest;
                JQ.Modify(true);
            end;
        end;
    end;

    // -------- Snapshot / No-shrink --------
    local procedure TakeAnchorSnapshot()
    var
        IJL: Record "Item Journal Line";
        KeyTxt: Text;
        ResBase: Decimal;
    begin
        Clear(AnchorSnapshot);
        IJL.Reset();
        IJL.SetRange("Journal Template Name", JnlTemplateName);
        IJL.SetRange("Journal Batch Name", JnlBatchName);
        if IJL.FindSet() then
            repeat
                IJL.CalcFields("Reserved Qty. (Base)");
                ResBase := Abs(IJL."Reserved Qty. (Base)");
                KeyTxt := AnchorKey(IJL);
                if AnchorSnapshot.ContainsKey(KeyTxt) then
                    AnchorSnapshot.Set(KeyTxt, ResBase)
                else
                    AnchorSnapshot.Add(KeyTxt, ResBase);
            until IJL.Next() = 0;
    end;

    // *** FIXED: no-shrink now uses TryReserve_* and never throws; logs + continues
    local procedure EnforceNoShrink()
    var
        IJL: Record "Item Journal Line";
        KeyTxt: Text;
        Snap: Decimal;
        HaveSnap: Boolean;
        NowRes: Decimal;
        Missing: Decimal;
        IsTracked: Boolean;
        Eps: Decimal;
        Needed: Decimal;
    begin
        if AllowDownsize then exit;

        Eps := 0.00001;

        IJL.Reset();
        IJL.SetRange("Journal Template Name", JnlTemplateName);
        IJL.SetRange("Journal Batch Name", JnlBatchName);
        if IJL.FindSet(true) then
            repeat
                KeyTxt := AnchorKey(IJL);
                HaveSnap := AnchorSnapshot.Get(KeyTxt, Snap);
                if not HaveSnap then
                    continue;

                IJL.CalcFields("Reserved Qty. (Base)");
                NowRes := Abs(IJL."Reserved Qty. (Base)");
                Missing := Snap - NowRes;

                if Missing > Eps then begin
                    IsTracked := ItemIsTracked(IJL."Item No.");
                    Needed := Missing;

                    if IsTracked then begin
                        if not TryReserve_Tracked(IJL, Needed, IJL."Bin Code") then
                            LogSyncFailure(IJL, Needed, GetLastErrorText());
                    end else begin
                        if not TryReserve_NonTracked(IJL, Needed, IJL."Bin Code") then
                            LogSyncFailure(IJL, Needed, GetLastErrorText());
                    end;

                    // Regardless of success/failure, continue to next IJL (non-blocking design)
                    if HardBind then HardBindAllPairsForIJL(IJL);
                end;
            until IJL.Next() = 0;
    end;

    local procedure AnchorKey(IJL: Record "Item Journal Line"): Text
    begin
        exit(StrSubstNo('%1|%2|%3|%4|%5|%6',
          IJL."Item No.", IJL."Variant Code", IJL."Location Code", IJL."Bin Code",
          IJL."Journal Template Name", IJL."Line No."));
    end;

    // -------- Main planner --------
    local procedure SyncFromConfig()
    begin
        UsePerItemPlanner := true;
        if UsePerItemPlanner then SyncByItemAcrossBins();
    end;

    local procedure SyncByItemAcrossBins()
    var
        EnabledLinesTmp: Record "Blocked Bin Auto Resv. Line" temporary;
        ItemList: List of [Text];
        ItemTxt: Text;
        ItemNo: Code[20];
    begin
        GetEnabledLines(EnabledLinesTmp);
        if EnabledLinesTmp.IsEmpty() then begin Message('HS Sync: No enabled rows found in setup.'); exit; end;

        ItemList := BuildItemListFromEnabledBins(EnabledLinesTmp);
        if ItemList.Count() = 0 then begin Message('HS Sync: No items with quantity > 0 found in enabled bins.'); exit; end;

        foreach ItemTxt in ItemList do begin
            Clear(ItemNo);
            Evaluate(ItemNo, ItemTxt);
            SyncOneItemAcrossBins(ItemNo, EnabledLinesTmp);
        end;
    end;

    local procedure GetEnabledLines(var LTmp: Record "Blocked Bin Auto Resv. Line" temporary)
    var
        H: Record "Blocked Bin Auto Reservation";
        L: Record "Blocked Bin Auto Resv. Line";
    begin
        LTmp.DeleteAll();
        H.Reset();
        H.SetRange(Enabled, true);
        if H.FindSet() then
            repeat
                L.Reset();
                L.SetRange("Header Code", H.Code);
                L.SetRange(Enabled, true);
                if L.FindSet() then
                    repeat LTmp := L; LTmp.Insert(); until L.Next() = 0;
            until H.Next() = 0;
    end;

    local procedure BuildItemListFromEnabledBins(var LTmp: Record "Blocked Bin Auto Resv. Line" temporary): List of [Text]
    var
        Items: List of [Text];
        BC: Record "Bin Content";
        Bn: Record Bin;
        Desired: Decimal;
        KeyTxt: Text;
    begin
        Clear(Items);

        if LTmp.FindSet() then
            repeat
                if LTmp."Bin Code" = '' then
                    continue;

                BC.Reset();
                if LTmp."Location Code" <> '' then
                    BC.SetRange("Location Code", LTmp."Location Code");
                BC.SetRange("Bin Code", LTmp."Bin Code");
                BC.SetFilter("Quantity (Base)", '<>0');
                if BC.FindSet() then
                    repeat
                        Desired := ComputeDesiredFromBinContent(BC);
                        if Desired > 0 then begin
                            KeyTxt := Format(BC."Item No.");
                            if not Items.Contains(KeyTxt) then
                                Items.Add(KeyTxt);
                        end;
                    until BC.Next() = 0;
            until LTmp.Next() = 0;

        exit(Items);
    end;

    // ---------- Per-item: pre-create all anchors, then additive reservations across bins ----------
    local procedure SyncOneItemAcrossBins(ItemNo: Code[20]; var LTmp: Record "Blocked Bin Auto Resv. Line" temporary)
    var
        Locs: List of [Code[10]];
        Bins: List of [Code[20]];
        Desireds: List of [Decimal];

        L2: Record "Blocked Bin Auto Resv. Line" temporary;
        DesiredBase: Decimal;
        HaveDesired: Boolean;
        BinCodeEff: Code[20];

        idx: Integer;
        loc: Code[10];
        bin: Code[20];
        want: Decimal;

        FreeLeftByLoc: Dictionary of [Code[10], Decimal];

        IJL: Record "Item Journal Line";
        pass: Integer;
        AddedBase: Decimal;
    begin
        Clear(Locs);
        Clear(Bins);
        Clear(Desireds);

        // Build plan (setup order)
        if LTmp.FindSet() then
            repeat
                L2 := LTmp;
                DesiredBase := GetDesiredForItemInLine(ItemNo, L2, HaveDesired, BinCodeEff);
                if HaveDesired and (DesiredBase > 0) and (BinCodeEff <> '') then begin
                    Locs.Add(L2."Location Code");
                    Bins.Add(BinCodeEff);
                    Desireds.Add(DesiredBase);
                end;
            until LTmp.Next() = 0;

        if Bins.Count() = 0 then exit;

        // Phase A: ensure anchors exist
        for idx := 1 to Bins.Count() do begin
            Bins.Get(idx, bin);
            Locs.Get(idx, loc);
            EnsureIJLAnchor(IJL, ItemNo, '', loc, bin, bin);
            if GetReservedBaseForIJL(IJL) = 0 then
                if not NearlyEqual(IJL."Quantity (Base)", 0, 0.00001) then
                    SafeSetIJLQuantity(IJL, 0);
        end;

        // Initialize per-location FreeAvail budget once for this item
        InitFreeLeftByLocForItem(ItemNo, Locs, FreeLeftByLoc);

        // Phase B: 1–2 sweeps through bins until budget is consumed
        for pass := 1 to 2 do begin
            for idx := 1 to Bins.Count() do begin
                Bins.Get(idx, bin);
                Locs.Get(idx, loc);
                Desireds.Get(idx, want);
                AddedBase := TopUpAnchorUpToCap(ItemNo, loc, bin, want, FreeLeftByLoc);
                // continue regardless of outcome
            end;
        end;
    end;

    // Initialize per-location FreeAvail budget for the current item
    local procedure InitFreeLeftByLocForItem(ItemNo: Code[20]; var Locs: List of [Code[10]]; var FreeLeftByLoc: Dictionary of [Code[10], Decimal])
    var
        L: Code[10];
        Seen: Dictionary of [Code[10], Boolean];
        SupplyRemain: Decimal;
        DemandReserved: Decimal;
        FreeAvail: Decimal;
    begin
        Clear(FreeLeftByLoc);
        Clear(Seen);
        foreach L in Locs do begin
            if not Seen.ContainsKey(L) then begin
                Seen.Add(L, true);
                GetLocationAvailability(ItemNo, '', L, SupplyRemain, DemandReserved, FreeAvail);
                if FreeAvail < 0 then FreeAvail := 0;
                FreeLeftByLoc.Add(L, FreeAvail);
            end;
        end;
    end;

    // Top-up only up to remaining budget (non-throwing; uses EnsureAndSyncReservation internally)
    local procedure TopUpAnchorUpToCap(ItemNo: Code[20]; LocCode: Code[10]; BinCode: Code[20]; DesiredBase: Decimal; var FreeLeftByLoc: Dictionary of [Code[10], Decimal]) AddedBase: Decimal
    var
        IJL: Record "Item Journal Line";
        Before: Decimal;
        After: Decimal;
        FreeLeft: Decimal;
        Have: Boolean;
        Cap: Decimal;
        TargetDesired: Decimal;
    begin
        AddedBase := 0;

        Have := FreeLeftByLoc.Get(LocCode, FreeLeft);
        if (not Have) or (FreeLeft <= 0) then exit;

        EnsureIJLAnchor(IJL, ItemNo, '', LocCode, BinCode, BinCode);
        IJL.CalcFields("Reserved Qty. (Base)");
        Before := Abs(IJL."Reserved Qty. (Base)");
        if Before >= DesiredBase - 0.00001 then exit;

        Cap := DesiredBase - Before;
        if Cap > FreeLeft then Cap := FreeLeft;
        if Cap <= 0 then exit;

        TargetDesired := Before + Cap; // desired cannot exceed budget
        EnsureAndSyncReservation(BinCode, ItemNo, '', LocCode, BinCode, TargetDesired);

        IJL.CalcFields("Reserved Qty. (Base)");
        After := Abs(IJL."Reserved Qty. (Base)");
        AddedBase := After - Before;
        if AddedBase < 0 then AddedBase := 0;

        FreeLeftByLoc.Set(LocCode, FreeLeft - AddedBase);
    end;

    // -------- Compute Desired for a bin line --------
    local procedure GetDesiredForItemInLine(ItemNo: Code[20]; L: Record "Blocked Bin Auto Resv. Line"; var HaveDesired: Boolean; var BinCodeEff: Code[20]): Decimal
    var
        BC: Record "Bin Content";
        Desired: Decimal;
    begin
        Desired := 0;
        HaveDesired := false;
        BinCodeEff := '';

        if L."Bin Code" <> '' then begin
            BC.Reset();
            BC.SetRange("Item No.", ItemNo);
            if L."Location Code" <> '' then
                BC.SetRange("Location Code", L."Location Code");
            BC.SetRange("Bin Code", L."Bin Code");
            if BC.FindFirst() then begin
                Desired := ComputeDesiredFromBinContent(BC);
                HaveDesired := true;
                BinCodeEff := L."Bin Code";
            end;
        end;

        exit(Desired);
    end;

    // -------- Desired per bin content --------
    local procedure ComputeDesiredFromBinContent(var BC: Record "Bin Content"): Decimal
    var
        Desired: Decimal;
    begin
        BC.CalcFields("Quantity (Base)");
        Desired := BC."Quantity (Base)";
        if UseOpenBinQty then begin
            BC.CalcFields("Pick Quantity (Base)");
            Desired := Desired - BC."Pick Quantity (Base)";
            if Desired < 0 then Desired := 0;
        end;
        exit(Desired);
    end;

    // -------- Core reservation (safeguarded) --------
    local procedure EnsureAndSyncReservation(
        BinCtx: Text; ItemNo: Code[20]; Variant: Code[10];
        LocationCode: Code[10]; BinCode: Code[20]; DesiredBase: Decimal)
    var
        IJL: Record "Item Journal Line";
        CurrentResBase: Decimal;
        UoM: Decimal;
        TargetDocQty: Decimal;
        Eps: Decimal;
        DeltaWanted: Decimal;
        DeltaBase: Decimal;
        NewResBase: Decimal;
        Before: Decimal;
        NeededAfterTopUp: Decimal;
        Reclaimed: Decimal;
        IsTracked: Boolean;
        After: Decimal;
        NoteExt: Text;
        TotDesiredAll: Decimal;
        TotReservedAll: Decimal;
        CanReclaim: Boolean;
        CanDownsizeNow: Boolean;
        SupplyRemain: Decimal;
        DemandReserved: Decimal;
        FreeAvail: Decimal;
    begin
        EnsureIJLAnchor(IJL, ItemNo, Variant, LocationCode, BinCode, BinCtx);

        Eps := 0.00001;
        IsTracked := ItemIsTracked(ItemNo);

        UoM := IJL."Qty. per Unit of Measure";
        if UoM = 0 then UoM := 1;

        IJL.CalcFields("Reserved Qty. (Base)");
        CurrentResBase := Abs(IJL."Reserved Qty. (Base)");
        Before := CurrentResBase;

        // Global caps (still applied defensively)
        GetTotalsFromConfiguration(ItemNo, Variant, LocationCode, TotReservedAll, TotDesiredAll);
        GetLocationAvailability(ItemNo, Variant, LocationCode, SupplyRemain, DemandReserved, FreeAvail);

        // A) Desired ~ 0 -> clear
        if NearlyEqual(DesiredBase, 0, Eps) then begin
            if CurrentResBase > 0 then CancelReservationForIJL(IJL, CurrentResBase);
            if not NearlyEqual(IJL."Quantity (Base)", 0, Eps) then SafeSetIJLQuantity(IJL, 0);
            exit;
        end;

        // B) Downsize only if admin allows and overall surplus exists
        CanDownsizeNow := AllowDownsize and ((DesiredBase + Eps) < CurrentResBase) and ((TotReservedAll - Eps) > TotDesiredAll);
        if CanDownsizeNow then begin
            CancelReservationForIJL(IJL, CurrentResBase);
            TargetDocQty := -(DesiredBase / UoM);
            SafeSetIJLQuantity(IJL, TargetDocQty);

            if IsTracked then
                AutoReserveIJLTracked_WithReuse(IJL, DesiredBase, BinCode)
            else
                AutoReserveIJL_NonTracked_WithReuse(IJL, DesiredBase, BinCode);

            IJL.CalcFields("Reserved Qty. (Base)");
            NewResBase := Abs(IJL."Reserved Qty. (Base)");
            if not NearlyEqual(NewResBase, DesiredBase, Eps) then begin
                TargetDocQty := -(MaxDec(NewResBase, DesiredBase) / UoM);
                SafeSetIJLQuantity(IJL, TargetDocQty);
            end;

            if DesiredBase > NewResBase + Eps then
                LogSupplyBlocked(IJL, BinCode, DesiredBase, Before, NewResBase, 'Downsize/Rebuild left short');
            exit;
        end;

        // C) Top-up (per-run cap already applied by caller)
        DeltaWanted := DesiredBase - CurrentResBase;
        if (DeltaWanted > Eps) then begin
            DeltaBase := DeltaWanted;
            if DeltaBase > FreeAvail then DeltaBase := FreeAvail;

            if DeltaBase > Eps then begin
                TargetDocQty := -((CurrentResBase + DeltaBase) / UoM);
                if not NearlyEqual(IJL.Quantity, TargetDocQty, Eps) then SafeSetIJLQuantity(IJL, TargetDocQty);

                if IsTracked then begin
                    if not TryReserve_Tracked(IJL, DeltaBase, BinCode) then LogSyncFailure(IJL, DeltaBase, GetLastErrorText());
                end else begin
                    if not TryReserve_NonTracked(IJL, DeltaBase, BinCode) then LogSyncFailure(IJL, DeltaBase, GetLastErrorText());
                end;
            end;
        end;

        // D) Align Quantity >= Reserved
        IJL.CalcFields("Reserved Qty. (Base)");
        NewResBase := Abs(IJL."Reserved Qty. (Base)");
        TargetDocQty := -(MaxDec(NewResBase, DesiredBase) / UoM);
        if not NearlyEqual(IJL.Quantity, TargetDocQty, Eps) then SafeSetIJLQuantity(IJL, TargetDocQty);

        // Optional reclaim
        NeededAfterTopUp := MaxDec(0, DesiredBase - NewResBase);
        Reclaimed := 0;
        CanReclaim := ReclaimWithinAnchorsEnabled and (NeededAfterTopUp > Eps) and ((TotReservedAll - Eps) > TotDesiredAll);
        if CanReclaim then begin
            Reclaimed := TryReclaimWithinAnchors(IJL, ItemNo, Variant, LocationCode, BinCode, NeededAfterTopUp, IsTracked);
            if Reclaimed > 0 then begin
                IJL.CalcFields("Reserved Qty. (Base)");
                NewResBase := Abs(IJL."Reserved Qty. (Base)");
                TargetDocQty := -(MaxDec(NewResBase, DesiredBase) / UoM);
                if not NearlyEqual(IJL.Quantity, TargetDocQty, Eps) then SafeSetIJLQuantity(IJL, TargetDocQty);
            end;
        end;

        if HardBind then HardBindAllPairsForIJL(IJL);

        if Reclaimed > 0 then NoteExt := 'Top-up + Reclaim left short' else NoteExt := 'Top-up left short';
        After := NewResBase;
        if DesiredBase > After + Eps then LogSupplyBlocked(IJL, BinCode, DesiredBase, Before, After, NoteExt);
    end;

    // -------- Availability / Totals --------
    local procedure GetLocationAvailability(ItemNo: Code[20]; Variant: Code[10]; LocationCode: Code[10]; var SupplyRemain: Decimal; var DemandReserved: Decimal; var FreeAvail: Decimal)
    var
        ILE: Record "Item Ledger Entry";
        Res: Record "Reservation Entry";
    begin
        SupplyRemain := 0;
        DemandReserved := 0;
        FreeAvail := 0;

        ILE.Reset();
        ILE.SetRange("Item No.", ItemNo);
        ILE.SetRange("Location Code", LocationCode);
        ILE.SetFilter("Remaining Quantity", '>%1', 0);
        if ILE.FindSet() then repeat SupplyRemain += ILE."Remaining Quantity"; until ILE.Next() = 0;

        Res.Reset();
        Res.SetRange("Item No.", ItemNo);
        Res.SetRange("Location Code", LocationCode);
        Res.SetRange(Positive, false);
        Res.SetRange("Reservation Status", Res."Reservation Status"::Reservation);
        if Res.FindSet() then repeat DemandReserved += Abs(Res."Quantity (Base)"); until Res.Next() = 0;

        FreeAvail := SupplyRemain - DemandReserved;
        if FreeAvail < 0 then FreeAvail := 0;
    end;

    local procedure GetReservedOnILE(ILEEntryNo: Integer): Decimal
    var
        Res: Record "Reservation Entry";
        Total: Decimal;
    begin
        Total := 0;
        Res.Reset();
        Res.SetRange("Item Ledger Entry No.", ILEEntryNo);
        Res.SetRange(Positive, true);
        Res.SetRange("Reservation Status", Res."Reservation Status"::Reservation);
        if Res.FindSet() then repeat Total += Abs(Res."Quantity (Base)"); until Res.Next() = 0;
        exit(Total);
    end;

    local procedure GetTotalsFromConfiguration(ItemNo: Code[20]; Variant: Code[10]; LocationCode: Code[10]; var TotReservedBase: Decimal; var TotDesiredBase: Decimal)
    var
        Anch: Record "Item Journal Line";
        H: Record "Blocked Bin Auto Reservation";
        L: Record "Blocked Bin Auto Resv. Line";
        BC: Record "Bin Content";
    begin
        TotReservedBase := 0;
        TotDesiredBase := 0;

        Anch.Reset();
        Anch.SetRange("Journal Template Name", JnlTemplateName);
        Anch.SetRange("Journal Batch Name", JnlBatchName);
        Anch.SetRange("Item No.", ItemNo);
        Anch.SetRange("Variant Code", Variant);
        Anch.SetRange("Location Code", LocationCode);
        if Anch.FindSet() then
            repeat
                Anch.CalcFields("Reserved Qty. (Base)");
                TotReservedBase += Abs(Anch."Reserved Qty. (Base)");
            until Anch.Next() = 0;

        H.Reset();
        H.SetRange(Enabled, true);
        if H.FindSet() then
            repeat
                L.Reset();
                L.SetRange("Header Code", H.Code);
                L.SetRange(Enabled, true);
                L.SetFilter("Location Code", '%1|%2', LocationCode, '');
                if L.FindSet() then
                    repeat
                        if L."Bin Code" = '' then
                            continue;

                        BC.Reset();
                        BC.SetRange("Item No.", ItemNo);
                        BC.SetRange("Variant Code", Variant);
                        BC.SetRange("Location Code", LocationCode);
                        BC.SetRange("Bin Code", L."Bin Code");
                        if BC.FindFirst() then
                            TotDesiredBase += ComputeDesiredFromBinContent(BC);
                    until L.Next() = 0;
            until H.Next() = 0;
    end;

    // -------- Anchor creation / reuse --------
    local procedure EnsureIJLAnchor(var IJL: Record "Item Journal Line"; ItemNo: Code[20]; Variant: Code[10]; LocationCode: Code[10]; BinCode: Code[20]; BinCtx: Text)
    var
        FindIJL: Record "Item Journal Line";
        NextLineNo: Integer;
        I: Record Item;
        DocNo: Code[20];
        UoMCode: Code[10];
        HasRes: Boolean;
    begin
        // Reuse if exists
        FindIJL.Reset();
        FindIJL.SetRange("Journal Template Name", JnlTemplateName);
        FindIJL.SetRange("Journal Batch Name", JnlBatchName);
        FindIJL.SetRange("Item No.", ItemNo);
        FindIJL.SetRange("Variant Code", Variant);
        FindIJL.SetRange("Location Code", LocationCode);
        FindIJL.SetRange("Bin Code", BinCode);

        if FindIJL.FindFirst() then begin
            IJL := FindIJL;

            if IJL."Posting Date" = 0D then begin IJL."Posting Date" := WorkDate(); IJL.Modify(true); end;

            if IJL."Document No." = '' then begin
                DocNo := CopyStr(StrSubstNo('HSRESV-%1-%2', LocationCode, BinCode), 1, MaxStrLen(IJL."Document No."));
                IJL.Validate("Document No.", DocNo);
                IJL.Modify(true);
            end;

            HasRes := GetReservedBaseForIJL(IJL) > 0;

            if IJL."Entry Type" <> IJL."Entry Type"::Transfer then begin
                if not HasRes then begin
                    IJL.Validate("Entry Type", IJL."Entry Type"::Transfer);
                    IJL.Validate("New Location Code", LocationCode);
                    if BinCode <> '' then IJL.Validate("New Bin Code", BinCode);
                    IJL.Modify(true);
                end;
            end else begin
                if not HasRes then begin
                    if IJL."New Location Code" <> LocationCode then begin IJL.Validate("New Location Code", LocationCode); IJL.Modify(true); end;
                    if (BinCode <> '') and (IJL."New Bin Code" <> BinCode) then begin IJL.Validate("New Bin Code", BinCode); IJL.Modify(true); end;
                end;
            end;

            exit;
        end;

        // Create new
        FindIJL.Reset();
        FindIJL.SetRange("Journal Template Name", JnlTemplateName);
        FindIJL.SetRange("Journal Batch Name", JnlBatchName);
        if FindIJL.FindLast() then NextLineNo := FindIJL."Line No." + 10000 else NextLineNo := 10000;

        IJL.Init();
        IJL."Journal Template Name" := JnlTemplateName;
        IJL."Journal Batch Name" := JnlBatchName;
        IJL."Line No." := NextLineNo;
        IJL.Insert(true);

        IJL.Validate("Entry Type", IJL."Entry Type"::Transfer);
        IJL.Validate("Item No.", ItemNo);
        if Variant <> '' then IJL.Validate("Variant Code", Variant);
        IJL.Validate("Location Code", LocationCode);
        if BinCode <> '' then IJL.Validate("Bin Code", BinCode);
        IJL.Validate("New Location Code", LocationCode);
        if BinCode <> '' then IJL.Validate("New Bin Code", BinCode);
        IJL."Posting Date" := WorkDate();

        if I.Get(ItemNo) then begin UoMCode := I."Base Unit of Measure"; if UoMCode <> '' then IJL.Validate("Unit of Measure Code", UoMCode); end;

        DocNo := CopyStr(StrSubstNo('HSRESV-%1-%2', LocationCode, BinCode), 1, MaxStrLen(IJL."Document No."));
        IJL.Validate("Document No.", DocNo);
        IJL.Modify(true);
    end;

    // -------- Reservation helpers --------
    [TryFunction]
    local procedure TryReserve_NonTracked(var IJL: Record "Item Journal Line"; AddBase: Decimal; BinCode: Code[20])
    begin
        AutoReserveIJL_NonTracked_WithReuse(IJL, AddBase, BinCode);
    end;

    [TryFunction]
    local procedure TryReserve_Tracked(var IJL: Record "Item Journal Line"; AddBase: Decimal; BinCode: Code[20])
    begin
        AutoReserveIJLTracked_WithReuse(IJL, AddBase, BinCode);
    end;

    local procedure AutoReserveIJL_NonTracked_WithReuse(var IJL: Record "Item Journal Line"; AddBase: Decimal; BinCode: Code[20])
    var
        ILE: Record "Item Ledger Entry";
        JnlReserve: Codeunit "Item Jnl. Line-Reserve";
        Track: Record "Tracking Specification" temporary;
        TempRes: Record "Reservation Entry" temporary;
        UoM: Decimal;
        ChunkBase: Decimal;
        ChunkDoc: Decimal;
        SavedNewLoc: Code[10];
        SavedNewBin: Code[20];
        ClearedInbound: Boolean;
        ReservedOnILE: Decimal;
        FreeOnILE: Decimal;
    begin
        if AddBase <= 0 then exit;
        UoM := IJL."Qty. per Unit of Measure";
        if UoM = 0 then UoM := 1;

        Clear(Track);
        JnlReserve.InitFromItemJnlLine(Track, IJL);

        SavedNewLoc := IJL."New Location Code";
        SavedNewBin := IJL."New Bin Code";
        ClearedInbound := false;
        if (not HasDemandReservations(IJL)) and ((SavedNewLoc <> '') or (SavedNewBin <> '')) then begin
            IJL.Validate("New Location Code", '');
            if IJL."New Bin Code" <> '' then IJL.Validate("New Bin Code", '');
            IJL.Modify(true);
            ClearedInbound := true;
        end;

        ILE.Reset();
        ILE.SetRange("Item No.", IJL."Item No.");
        ILE.SetRange("Location Code", IJL."Location Code");
        ILE.SetFilter("Remaining Quantity", '>%1', 0);
        if ILE.FindSet() then
            repeat
                if AddBase <= 0 then break;

                ReservedOnILE := GetReservedOnILE(ILE."Entry No.");
                FreeOnILE := ILE."Remaining Quantity" - ReservedOnILE;
                if FreeOnILE <= 0 then continue;

                ChunkBase := FreeOnILE;
                if ChunkBase > AddBase then ChunkBase := AddBase;
                ChunkDoc := ChunkBase / UoM;

                OverwriteTrackWithILE(Track, ILE, UoM, ChunkBase);
                JnlReserve.CreateReservationSetFrom(Track);
                TempRes.Reset();
                JnlReserve.CreateReservation(IJL, 'HS BLOCKED BIN', WorkDate(), ChunkDoc, ChunkBase, TempRes);

                AddBase -= ChunkBase;
            until ILE.Next() = 0;

        if ClearedInbound then begin
            IJL.Validate("New Location Code", SavedNewLoc);
            if SavedNewBin <> '' then IJL.Validate("New Bin Code", SavedNewBin);
            IJL.Modify(true);
        end;
    end;

    local procedure AutoReserveIJLTracked_WithReuse(var IJL: Record "Item Journal Line"; AddBase: Decimal; BinCode: Code[20])
    var
        ILE: Record "Item Ledger Entry";
        JnlReserve: Codeunit "Item Jnl. Line-Reserve";
        Track: Record "Tracking Specification" temporary;
        TempRes: Record "Reservation Entry" temporary;
        UoM: Decimal;
        ChunkBase: Decimal;
        ChunkDoc: Decimal;
        SavedNewLoc: Code[10];
        SavedNewBin: Code[20];
        ClearedInbound: Boolean;
        ReservedOnILE: Decimal;
        FreeOnILE: Decimal;
    begin
        if AddBase <= 0 then exit;
        UoM := IJL."Qty. per Unit of Measure";
        if UoM = 0 then UoM := 1;

        Clear(Track);
        JnlReserve.InitFromItemJnlLine(Track, IJL);

        SavedNewLoc := IJL."New Location Code";
        SavedNewBin := IJL."New Bin Code";
        ClearedInbound := false;
        if (not HasDemandReservations(IJL)) and ((SavedNewLoc <> '') or (SavedNewBin <> '')) then begin
            IJL.Validate("New Location Code", '');
            if IJL."New Bin Code" <> '' then IJL.Validate("New Bin Code", '');
            IJL.Modify(true);
            ClearedInbound := true;
        end;

        ILE.Reset();
        ILE.SetRange("Item No.", IJL."Item No.");
        ILE.SetRange("Location Code", IJL."Location Code");
        ILE.SetFilter("Remaining Quantity", '>%1', 0);
        ILE.SetCurrentKey("Location Code", "Item No.", "Variant Code", "Posting Date", "Lot No.", "Serial No.");
        if ILE.FindSet() then
            repeat
                if AddBase <= 0 then break;

                ReservedOnILE := GetReservedOnILE(ILE."Entry No.");
                FreeOnILE := ILE."Remaining Quantity" - ReservedOnILE;
                if FreeOnILE <= 0 then continue;

                ChunkBase := FreeOnILE;
                if ChunkBase > AddBase then ChunkBase := AddBase;
                ChunkDoc := ChunkBase / UoM;

                OverwriteTrackWithILE(Track, ILE, UoM, ChunkBase);
                JnlReserve.CreateReservationSetFrom(Track);
                TempRes.Reset();
                JnlReserve.CreateReservation(IJL, 'HS BLOCKED BIN', WorkDate(), ChunkDoc, ChunkBase, TempRes);

                AddBase -= ChunkBase;
            until ILE.Next() = 0;

        if ClearedInbound then begin
            IJL.Validate("New Location Code", SavedNewLoc);
            if SavedNewBin <> '' then IJL.Validate("New Bin Code", SavedNewBin);
            IJL.Modify(true);
        end;
    end;

    // -------- Cancellation / Hard-bind --------
    local procedure CancelReservationForIJL(var IJL: Record "Item Journal Line"; CancelBase: Decimal)
    var
        RDemand: Record "Reservation Entry";
        RSupply: Record "Reservation Entry";
        LeftToCancel: Decimal;
        PairNo: Integer;
    begin
        LeftToCancel := CancelBase;

        RDemand.Reset();
        RDemand.SetRange("Source Type", Database::"Item Journal Line");
        RDemand.SetRange("Source ID", IJL."Journal Template Name");
        RDemand.SetRange("Source Batch Name", IJL."Journal Batch Name");
        RDemand.SetRange("Source Ref. No.", IJL."Line No.");
        RDemand.SetRange(Positive, false);
        RDemand.SetRange("Reservation Status", RDemand."Reservation Status"::Reservation);

        if RDemand.FindSet(true) then
            repeat
                if LeftToCancel <= 0 then break;

                PairNo := RDemand."Entry No.";

                if RDemand."Quantity (Base)" > LeftToCancel then begin
                    RDemand."Quantity (Base)" := RDemand."Quantity (Base)" - LeftToCancel;
                    RDemand.Modify(true);

                    RSupply.Reset();
                    RSupply.SetRange("Entry No.", PairNo);
                    RSupply.SetRange(Positive, true);
                    if RSupply.FindFirst() then begin
                        RSupply."Quantity (Base)" := RSupply."Quantity (Base)" - LeftToCancel;
                        RSupply.Modify(true);
                    end;

                    LeftToCancel := 0;
                end else begin
                    LeftToCancel := LeftToCancel - RDemand."Quantity (Base)";

                    RSupply.Reset();
                    RSupply.SetRange("Entry No.", PairNo);
                    RSupply.SetRange(Positive, true);
                    if RSupply.FindFirst() then RSupply.Delete(true);

                    RDemand.Delete(true);
                end;
            until RDemand.Next() = 0;

        if GetReservedBaseForIJL(IJL) = 0 then
            if not NearlyEqual(IJL."Quantity (Base)", 0, 0.00001) then SafeSetIJLQuantity(IJL, 0);
    end;

    local procedure HardBindAllPairsForIJL(var IJL: Record "Item Journal Line")
    var
        RDemand: Record "Reservation Entry";
        RSupply: Record "Reservation Entry";
        EntryNo: Integer;
    begin
        RDemand.Reset();
        RDemand.SetRange("Source Type", Database::"Item Journal Line");
        RDemand.SetRange("Source ID", IJL."Journal Template Name");
        RDemand.SetRange("Source Batch Name", IJL."Journal Batch Name");
        RDemand.SetRange("Source Ref. No.", IJL."Line No.");
        RDemand.SetRange(Positive, false);
        RDemand.SetRange("Reservation Status", RDemand."Reservation Status"::Reservation);

        if RDemand.FindSet(true) then
            repeat
                if RDemand.Binding <> RDemand.Binding::"Order-to-Order" then begin
                    RDemand.Binding := RDemand.Binding::"Order-to-Order";
                    RDemand.Modify(true);
                end;

                EntryNo := RDemand."Entry No.";

                RSupply.Reset();
                RSupply.SetRange("Entry No.", EntryNo);
                RSupply.SetRange(Positive, true);
                RSupply.SetRange("Reservation Status", RSupply."Reservation Status"::Reservation);
                if RSupply.FindFirst() then
                    if RSupply.Binding <> RSupply.Binding::"Order-to-Order" then begin
                        RSupply.Binding := RSupply.Binding::"Order-to-Order";
                        RSupply.Modify(true);
                    end;
            until RDemand.Next() = 0;
    end;

    // -------- Diagnose --------
    [TryFunction]
    local procedure DoDiagnoseAttempt(var IJL: Record "Item Journal Line"; NeededBase: Decimal; BinCode: Code[20]; IsTracked: Boolean)
    begin
        if IsTracked then
            AutoReserveIJLTracked_WithReuse(IJL, NeededBase, BinCode)
        else
            AutoReserveIJL_NonTracked_WithReuse(IJL, NeededBase, BinCode);
    end;

    procedure DiagnoseAnchorSafe(var IJL: Record "Item Journal Line") ResultTxt: Text[250]
    var
        I: Record Item;
        ILE: Record "Item Ledger Entry";
        Before: Decimal;
        After: Decimal;
        Delta: Decimal;
        IsTracked: Boolean;
        HasSupply: Boolean;
        DesiredBase: Decimal;
        NeededBase: Decimal;
        LastErr: Text;
    begin
        EnsureJnlInfrastructure();

        DesiredBase := Abs(IJL."Quantity (Base)");
        if not I.Get(IJL."Item No.") then exit('Diagnose: Item not found.');
        if not ItemCanReserve(I."No.") then exit(StrSubstNo('Diagnose: Item %1 has Reserve=Never. No reservation attempted.', I."No."));
        IsTracked := ItemIsTracked(I."No.");

        if IJL."Posting Date" = 0D then begin IJL."Posting Date" := WorkDate(); IJL.Modify(true); end;

        if IJL."Document No." = '' then begin
            IJL.Validate("Document No.", CopyStr(StrSubstNo('HSRESV-%1-%2', IJL."Location Code", IJL."Bin Code"), 1, MaxStrLen(IJL."Document No.")));
            IJL.Modify(true);
        end;

        if HardBind then HardBindAllPairsForIJL(IJL);
        if NearlyEqual(DesiredBase, 0, 0.00001) then exit('Diagnose: Desired quantity is 0. No reservation required.');

        ILE.Reset();
        ILE.SetRange("Item No.", I."No.");
        ILE.SetRange("Location Code", IJL."Location Code");
        ILE.SetFilter("Remaining Quantity", '>%1', 0);
        HasSupply := ILE.FindFirst();
        if not HasSupply then exit('Diagnose: No positive supply at location. No reservation possible.');

        IJL.CalcFields("Reserved Qty. (Base)");
        Before := Abs(IJL."Reserved Qty. (Base)");
        if (Before + 0.00001) >= DesiredBase then
            exit(StrSubstNo('Diagnose: Already fully reserved. Before=%1; Desired=%2; Delta=0', Format(Before), Format(DesiredBase)));

        NeededBase := DesiredBase - Before;

        if not DoDiagnoseAttempt(IJL, NeededBase, IJL."Bin Code", IsTracked) then begin
            LastErr := GetLastErrorText();
            exit(StrSubstNo('Diagnose (dry-run): Attempt skipped. Reason="%1". Tracked=%2; Supply@Loc=%3; AlreadyReserved=%4; Needed=%5',
                CopyStr(LastErr, 1, 120), Format(IsTracked), Format(HasSupply), Format(Before), Format(NeededBase)));
        end;

        IJL.CalcFields("Reserved Qty. (Base)");
        After := Abs(IJL."Reserved Qty. (Base)");
        Delta := After - Before;

        if HardBind then HardBindAllPairsForIJL(IJL);
        if Delta <= 0 then
            exit(StrSubstNo('Diagnose: No change. Tracked=%1; Supply@Loc=%2; Before=%3; After=%4; Desired=%5',
                Format(IsTracked), Format(HasSupply), Format(Before), Format(After), Format(DesiredBase)));

        ResultTxt := StrSubstNo('Diagnose: OK. Tracked=%1; Supply@Loc=%2; Before=%3; After=%4; Delta=%5',
            Format(IsTracked), Format(HasSupply), Format(Before), Format(After), Format(Delta));
        exit(ResultTxt);
    end;

    // -------- Utilities --------
    local procedure GetReservedBaseForIJL(var IJL: Record "Item Journal Line"): Decimal
    var
        RDemand: Record "Reservation Entry";
        Total: Decimal;
    begin
        RDemand.Reset();
        RDemand.SetRange("Source Type", Database::"Item Journal Line");
        RDemand.SetRange("Source ID", IJL."Journal Template Name");
        RDemand.SetRange("Source Batch Name", IJL."Journal Batch Name");
        RDemand.SetRange("Source Ref. No.", IJL."Line No.");
        RDemand.SetRange(Positive, false);
        RDemand.SetRange("Reservation Status", RDemand."Reservation Status"::Reservation);
        if RDemand.FindSet() then repeat Total += Abs(RDemand."Quantity (Base)"); until RDemand.Next() = 0;
        exit(Total);
    end;

    local procedure ItemCanReserve(ItemNo: Code[20]): Boolean
    var
        I: Record Item;
    begin
        if not I.Get(ItemNo) then exit(false);
        exit(I.Reserve <> I.Reserve::Never);
    end;

    local procedure ItemIsTracked(ItemNo: Code[20]): Boolean
    var
        I: Record Item;
        ITC: Record "Item Tracking Code";
    begin
        if not I.Get(ItemNo) then exit(false);
        if I."Item Tracking Code" = '' then exit(false);
        if not ITC.Get(I."Item Tracking Code") then exit(false);
        exit(ITC."Lot Specific Tracking" or ITC."SN Specific Tracking");
    end;

    local procedure OverwriteTrackWithILE(var Track: Record "Tracking Specification" temporary; var ILE: Record "Item Ledger Entry"; UoM: Decimal; BaseQty: Decimal)
    begin
        Track."Item No." := ILE."Item No.";
        Track."Variant Code" := ILE."Variant Code";
        Track."Location Code" := ILE."Location Code";
        Track."Lot No." := ILE."Lot No.";
        Track."Serial No." := ILE."Serial No.";
        Track."Qty. per Unit of Measure" := UoM;
        if Track."Qty. per Unit of Measure" = 0 then Track."Qty. per Unit of Measure" := 1;
        Track.Positive := true;
        Track."Quantity (Base)" := BaseQty;
        Track."Source Type" := DATABASE::"Item Ledger Entry";
        Track."Source Subtype" := 0;
        Track."Source Ref. No." := ILE."Entry No.";
        Track."Item Ledger Entry No." := ILE."Entry No.";
    end;

    local procedure HasDemandReservations(var IJL: Record "Item Journal Line"): Boolean
    begin
        exit(GetReservedBaseForIJL(IJL) > 0);
    end;

    local procedure SafeSetIJLQuantity(var IJL: Record "Item Journal Line"; TargetDocQty: Decimal)
    var
        SavedNewLoc: Code[10];
        SavedNewBin: Code[20];
        UoM: Decimal;
        Eps: Decimal;
        CurrResBase: Decimal;
        TargetBaseWanted: Decimal;
        Iter: Integer;
    begin
        Eps := 0.00001;
        UoM := IJL."Qty. per Unit of Measure";
        if UoM = 0 then UoM := 1;

        IJL.CalcFields("Reserved Qty. (Base)");
        CurrResBase := Abs(IJL."Reserved Qty. (Base)");
        TargetBaseWanted := Abs(TargetDocQty * UoM);
        if CurrResBase > TargetBaseWanted + Eps then TargetDocQty := -(CurrResBase / UoM);

        for Iter := 1 to 2 do begin
            SavedNewLoc := IJL."New Location Code";
            SavedNewBin := IJL."New Bin Code";

            IJL.Validate(Quantity, TargetDocQty);

            if IJL."New Location Code" <> SavedNewLoc then IJL."New Location Code" := SavedNewLoc;
            if IJL."New Bin Code" <> SavedNewBin then IJL."New Bin Code" := SavedNewBin;

            IJL.Modify(true);

            IJL.CalcFields("Reserved Qty. (Base)");
            CurrResBase := Abs(IJL."Reserved Qty. (Base)");
            if CurrResBase <= Abs(IJL."Quantity (Base)") + Eps then exit;

            TargetDocQty := -(CurrResBase / UoM);
        end;
    end;

    local procedure LogSyncFailure(var IJL: Record "Item Journal Line"; NeededBase: Decimal; Reason: Text)
    begin
        Session.LogMessage('HSRESV_SYNC_FAIL', CopyStr(Reason, 1, 200), Verbosity::Warning, DataClassification::SystemMetadata,
            TelemetryScope::ExtensionPublisher, TelemetrySrc, TelemetryAreaSync,
            StrSubstNo('%1|%2|%3|%4|Need=%5', IJL."Item No.", IJL."Variant Code", IJL."Location Code", IJL."Bin Code", Format(NeededBase)));
    end;

    local procedure LogSupplyBlocked(var IJL: Record "Item Journal Line"; BinCode: Code[20]; DesiredBase: Decimal; Before: Decimal; After: Decimal; Note: Text)
    var
        Shortfall: Decimal;
    begin
        Shortfall := DesiredBase - After;
        if Shortfall <= 0 then exit;
        Session.LogMessage('HSRESV_SUPPLY_BLOCKED',
            CopyStr(StrSubstNo('%1 | Desired=%2; Before=%3; After=%4; Shortfall=%5', Note, Format(DesiredBase), Format(Before), Format(After), Format(Shortfall)), 1, 200),
            Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, TelemetrySrc, TelemetryAreaSync,
            StrSubstNo('%1|%2|%3|%4', IJL."Item No.", IJL."Variant Code", IJL."Location Code", BinCode));
    end;

    // -------- Optional reclaim --------
    local procedure TryReclaimWithinAnchors(var ReceiverIJL: Record "Item Journal Line"; ItemNo: Code[20]; Variant: Code[10]; LocationCode: Code[10]; ReceiverBin: Code[20]; NeedBase: Decimal; IsTracked: Boolean) ReclaimedBase: Decimal
    var
        DonorIJL: Record "Item Journal Line";
        DesiredDonor: Decimal;
        DonorRes: Decimal;
        Excess: Decimal;
        Take: Decimal;
    begin
        ReclaimedBase := 0;
        if NeedBase <= 0 then exit;

        DonorIJL.Reset();
        DonorIJL.SetRange("Journal Template Name", JnlTemplateName);
        DonorIJL.SetRange("Journal Batch Name", JnlBatchName);
        DonorIJL.SetRange("Item No.", ItemNo);
        DonorIJL.SetRange("Variant Code", Variant);
        DonorIJL.SetRange("Location Code", LocationCode);
        DonorIJL.SetFilter("Line No.", '<>%1', ReceiverIJL."Line No.");

        if DonorIJL.FindSet(true) then
            repeat
                DesiredDonor := GetDesiredBaseFromBin(ItemNo, Variant, LocationCode, DonorIJL."Bin Code");
                DonorIJL.CalcFields("Reserved Qty. (Base)");
                DonorRes := Abs(DonorIJL."Reserved Qty. (Base)");

                Excess := DonorRes - DesiredDonor;
                if Excess <= 0 then continue;

                Take := Excess;
                if Take > (NeedBase - ReclaimedBase) then Take := (NeedBase - ReclaimedBase);
                if Take <= 0 then break;

                CancelReservationForIJL(DonorIJL, Take);

                if IsTracked then begin
                    if not TryReserve_Tracked(ReceiverIJL, Take, ReceiverBin) then LogSyncFailure(ReceiverIJL, Take, GetLastErrorText());
                end else begin
                    if not TryReserve_NonTracked(ReceiverIJL, Take, ReceiverBin) then LogSyncFailure(ReceiverIJL, Take, GetLastErrorText());
                end;

                ReclaimedBase += Take;
            until DonorIJL.Next() = 0;

        exit(ReclaimedBase);
    end;

    local procedure GetDesiredBaseFromBin(ItemNo: Code[20]; Variant: Code[10]; LocationCode: Code[10]; BinCode: Code[20]) Result: Decimal
    var
        BC: Record "Bin Content";
    begin
        Result := 0;
        if (ItemNo = '') or (LocationCode = '') or (BinCode = '') then exit(0);
        BC.Reset();
        BC.SetRange("Item No.", ItemNo);
        BC.SetRange("Variant Code", Variant);
        BC.SetRange("Location Code", LocationCode);
        BC.SetRange("Bin Code", BinCode);
        if BC.FindFirst() then Result := ComputeDesiredFromBinContent(BC);
    end;

    // -------- Configured bin check --------
    local procedure IsConfiguredBin(BinCode: Code[20]; LocationCode: Code[10]) IsTarget: Boolean
    var
        H: Record "Blocked Bin Auto Reservation";
        L: Record "Blocked Bin Auto Resv. Line";
    begin
        H.Reset();
        H.SetRange(Enabled, true);
        if not H.FindSet() then exit(false);
        repeat
            L.Reset();
            L.SetRange("Header Code", H.Code);
            L.SetRange(Enabled, true);
            L.SetRange("Location Code", LocationCode);
            L.SetRange("Bin Code", BinCode);
            if L.FindFirst() then
                exit(true);
        until H.Next() = 0;

        exit(false);
    end;

    local procedure NearlyEqual(A: Decimal; B: Decimal; Tol: Decimal): Boolean
    begin
        exit(Abs(A - B) <= Tol);
    end;

    local procedure MaxDec(A: Decimal; B: Decimal): Decimal
    begin
        if A >= B then exit(A) else exit(B);
    end;
}


// =============================
// Codeunit 80056: HS Resv Sync Job
// =============================
codeunit 80056 "HS Resv Sync Job"
{
    Subtype = Normal;

    trigger OnRun()
    var
        Resv: Codeunit "HSResvDirect";
    begin
        Resv.SyncNow();
    end;
}


// =============================
// Codeunit 80057: HS Resv Install
// =============================
codeunit 80057 "HS Resv Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    begin
        EnsureInfraAndJob();
    end;

    local procedure EnsureInfraAndJob()
    var
        Resv: Codeunit "HSResvDirect";
        JQ: Record "Job Queue Entry";
        Desc: Text[100];
        H: Record "Blocked Bin Auto Reservation";
    begin
        Resv.EnsureJnlInfrastructure();

        if H.IsEmpty() then begin
            H.Init();
            H.Code := 'DEFAULT';
            H.Description := 'Bin Filter Set';
            H.Enabled := true;
            H.Insert(true);
        end;

        JQ.Reset();
        JQ.SetRange("Object Type to Run", JQ."Object Type to Run"::Codeunit);
        JQ.SetRange("Object ID to Run", Codeunit::"HS Resv Sync Job");
        if not JQ.FindFirst() then begin
            JQ.Init();
            JQ."Object Type to Run" := JQ."Object Type to Run"::Codeunit;
            JQ."Object ID to Run" := Codeunit::"HS Resv Sync Job";
            JQ."Earliest Start Date/Time" := CurrentDateTime;
            if HasMinutesBetweenRunsField(JQ) then JQ."No. of Minutes between Runs" := 15;
            Desc := CopyStr(Format(CurrentDateTime) + ' HS Resv Sync', 1, MaxStrLen(JQ.Description));
            JQ.Description := Desc;
            JQ.Insert(true);
        end else begin
            if HasMinutesBetweenRunsField(JQ) then JQ."No. of Minutes between Runs" := 15;
            JQ.Modify(true);
        end;
    end;

    local procedure HasMinutesBetweenRunsField(var JQ: Record "Job Queue Entry"): Boolean
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
        I: Integer;
    begin
        RecRef.GetTable(JQ);
        for I := 1 to RecRef.FieldCount do begin
            FieldRef := RecRef.FieldIndex(I);
            if FieldRef.Name = 'No. of Minutes between Runs' then exit(true);
        end;
        exit(false);
    end;
}


// =============================
// Codeunit 80058: HS Resv Upgrade
// =============================
codeunit 80058 "HS Resv Upgrade"
{
    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
    begin
        Codeunit.Run(Codeunit::"HS Resv Install");
    end;
}
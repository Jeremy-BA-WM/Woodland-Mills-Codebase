page 89720 "WLM Inventory by Location"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "Item Ledger Entry";
    SourceTableTemporary = true;
    Caption = 'WLM Inventory by Location';
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Item No."; Rec."Item No.") { ApplicationArea = All; }
                field(Description; ItemDescription) { ApplicationArea = All; Caption = 'Description'; Editable = false; }
                field("Item Category"; ItemCategory) { ApplicationArea = All; Caption = 'Item Category'; Editable = false; }
                field("Global Dimension 1"; GlobalDim1) { ApplicationArea = All; Editable = false; }
                field("Global Dimension 2"; GlobalDim2) { ApplicationArea = All; Editable = false; }
                field("Shortcut Dim 3"; ShortcutDim3Val) { ApplicationArea = All; Editable = false; }
                field("Shortcut Dim 4"; ShortcutDim4Val) { ApplicationArea = All; Editable = false; }
                field("Shortcut Dim 5"; ShortcutDim5Val) { ApplicationArea = All; Editable = false; }
                field("Shortcut Dim 6"; ShortcutDim6Val) { ApplicationArea = All; Editable = false; }
                field("Shortcut Dim 7"; ShortcutDim7Val) { ApplicationArea = All; Editable = false; }
                field("Shortcut Dim 8"; ShortcutDim8Val) { ApplicationArea = All; Editable = false; }

                field("Location Code"; Rec."Location Code") { ApplicationArea = All; }
                field("Posting Date"; Rec."Posting Date") { ApplicationArea = All; }
                field("Month-Year"; MonthYearTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Month-Year (MM-YYYY)';
                    Editable = false;
                }
                field("Inventory Starting"; InventoryStarting)
                {
                    ApplicationArea = All;
                    Caption = 'Inventory Starting';
                    Editable = false;
                    BlankZero = true;
                    DecimalPlaces = 0 : 0;
                }
                field("Inventory"; InventoryQty)
                {
                    ApplicationArea = All;
                    Caption = 'Avg Inventory (Month)';
                    BlankZero = true;
                    Editable = false;
                    DecimalPlaces = 0 : 0;
                }
                field("Unit Cost"; UnitCost) { ApplicationArea = All; Editable = false; }
                field("Last Direct Cost"; LastDirectCost) { ApplicationArea = All; Editable = false; }
                field("Unit Cost * Inventory"; InventoryUnitCostValue)
                {
                    ApplicationArea = All;
                    Caption = 'Unit Cost * Inventory';
                    BlankZero = true;
                }
                field("Last Direct Cost * Inventory"; InventoryLastDirectCostValue)
                {
                    ApplicationArea = All;
                    Caption = 'Last Direct Cost * Inventory';
                    BlankZero = true;
                }
                field(Cubage; Cubage)
                {
                    ApplicationArea = All;
                    Caption = 'Cubage';
                    BlankZero = true;
                }
                field("Cubage * Inventory"; InventoryCubageValue)
                {
                    ApplicationArea = All;
                    Caption = 'Cubage * Inventory';
                    BlankZero = true;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Refresh)
            {
                Caption = 'Refresh';
                Image = Refresh;
                ApplicationArea = All;
                trigger OnAction()
                begin
                    BuildTempData();
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        EnsureGLSetup();
        BuildTempData();
    end;

    trigger OnAfterGetRecord()
    begin
        LoadItemInfo();
        SetMonthWindow();
        InventoryQty := CalcInventory();
        CalcInventoryValues();
    end;

    local procedure LoadItemInfo()
    begin
        if ItemRec.Get(Rec."Item No.") then begin
            ItemDescription := ItemRec.Description;
            ItemCategory := ItemRec."Item Category Code";
            GlobalDim1 := ItemRec."Global Dimension 1 Code";
            GlobalDim2 := ItemRec."Global Dimension 2 Code";
            UnitCost := ItemRec."Unit Cost";
            LastDirectCost := ItemRec."Last Direct Cost";
            Cubage := GetCubage(ItemRec);

            ShortcutDim3Val := GetDimValue(ItemRec."No.", GLSetup."Shortcut Dimension 3 Code");
            ShortcutDim4Val := GetDimValue(ItemRec."No.", GLSetup."Shortcut Dimension 4 Code");
            ShortcutDim5Val := GetDimValue(ItemRec."No.", GLSetup."Shortcut Dimension 5 Code");
            ShortcutDim6Val := GetDimValue(ItemRec."No.", GLSetup."Shortcut Dimension 6 Code");
            ShortcutDim7Val := GetDimValue(ItemRec."No.", GLSetup."Shortcut Dimension 7 Code");
            ShortcutDim8Val := GetDimValue(ItemRec."No.", GLSetup."Shortcut Dimension 8 Code");
        end else begin
            Clear(ItemDescription);
            Clear(ItemCategory);
            Clear(GlobalDim1);
            Clear(GlobalDim2);
            Clear(UnitCost);
            Clear(LastDirectCost);
            Clear(Cubage);
            Clear(ShortcutDim3Val);
            Clear(ShortcutDim4Val);
            Clear(ShortcutDim5Val);
            Clear(ShortcutDim6Val);
            Clear(ShortcutDim7Val);
            Clear(ShortcutDim8Val);
        end;
    end;

    local procedure CalcInventory(): Decimal
    var
        OpeningBal: Decimal;
        Balance: Decimal;
        TotalDayQty: Decimal;
        PrevDate: Date;
        Days: Integer;
    begin
        InventoryStarting := 0;

        if (Rec."Posting Date" = 0D) or (MonthStart = 0D) or (MonthEnd = 0D) then
            exit(0);

        // Opening balance up to day before month start
        ILE.Reset();
        ILE.SetRange("Item No.", Rec."Item No.");
        ILE.SetRange("Location Code", Rec."Location Code");
        ILE.SetRange("Posting Date", 0D, MonthStart - 1);
        ILE.CalcSums(Quantity);
        OpeningBal := ILE.Quantity;
        InventoryStarting := Round(OpeningBal, 1, '=');

        Balance := OpeningBal;
        PrevDate := MonthStart;
        TotalDayQty := 0;

        // Walk entries within the month ordered by date
        ILE.Reset();
        ILE.SetCurrentKey("Item No.", "Location Code", "Posting Date");
        ILE.SetRange("Item No.", Rec."Item No.");
        ILE.SetRange("Location Code", Rec."Location Code");
        ILE.SetRange("Posting Date", MonthStart, MonthEnd);

        if ILE.FindSet() then
            repeat
                Days := ILE."Posting Date" - PrevDate;
                if Days < 0 then
                    Days := 0;
                if Days > 0 then
                    TotalDayQty += Balance * Days;
                Balance += ILE.Quantity;
                PrevDate := ILE."Posting Date";
            until ILE.Next() = 0;

        // Add last span to month end
        Days := MonthEnd - PrevDate + 1;
        if Days < 0 then
            Days := 0;
        if Days > 0 then
            TotalDayQty += Balance * Days;

        if MonthLength = 0 then begin
            MonthLength := CalcDate('<CM>', MonthStart) - MonthStart;
            if MonthLength <= 0 then
                MonthLength := 1;
        end;

        exit(Round(TotalDayQty / MonthLength, 1, '='));
    end;

    local procedure CalcInventoryValues()
    begin
        InventoryUnitCostValue := InventoryQty * UnitCost;
        InventoryLastDirectCostValue := InventoryQty * LastDirectCost;
        InventoryCubageValue := InventoryQty * Cubage;
    end;

    local procedure GetDimValue(ItemNo: Code[20]; DimCode: Code[20]): Code[20]
    var
        DefDim: Record "Default Dimension";
    begin
        if DimCode = '' then
            exit('');

        DefDim.Reset();
        DefDim.SetRange("Table ID", Database::Item);
        DefDim.SetRange("No.", ItemNo);
        DefDim.SetRange("Dimension Code", DimCode);
        if DefDim.FindFirst() then
            exit(DefDim."Dimension Value Code");
        exit('');
    end;

    local procedure EnsureGLSetup()
    begin
        if not GLSetup.Get() then
            Clear(GLSetup);
    end;

    local procedure SetMonthWindow()
    var
        Month: Integer;
        Year: Integer;
    begin
        MonthStart := 0D;
        MonthEnd := 0D;
        MonthYearTxt := '';

        if Rec."Posting Date" = 0D then
            exit;

        Month := Date2DMY(Rec."Posting Date", 2);
        Year := Date2DMY(Rec."Posting Date", 3);
        MonthStart := DMY2Date(1, Month, Year);
        MonthEnd := CalcDate('<CM>', MonthStart) - 1;
        MonthYearTxt := Format(MonthStart, 0, '<Month,2>-<Year4>');
        MonthLength := MonthEnd - MonthStart + 1;
    end;

    local procedure BuildTempData()
    var
        ItemNoFilter: Text;
        LocFilter: Text;
        DateFilter: Text;
        KeyText: Text;
        MonthStartLocal: Date;
        MonthEndLocal: Date;
        MonthYearLocal: Text[7];
    begin
        EnsureGLSetup();

        ItemNoFilter := Rec.GetFilter("Item No.");
        LocFilter := Rec.GetFilter("Location Code");
        DateFilter := Rec.GetFilter("Posting Date");

        Rec.Reset();
        Rec.DeleteAll();

        Clear(InsertedKeys);
        NextEntryNo := 1;

        ILE.Reset();
        if ItemNoFilter <> '' then
            ILE.SetFilter("Item No.", ItemNoFilter);
        if LocFilter <> '' then
            ILE.SetFilter("Location Code", LocFilter);
        if DateFilter <> '' then
            ILE.SetFilter("Posting Date", DateFilter);

        ILE.SetCurrentKey("Item No.", "Location Code", "Posting Date");
        if ILE.FindSet() then
            repeat
                GetMonthBounds(ILE."Posting Date", MonthStartLocal, MonthEndLocal, MonthYearLocal);
                KeyText := ILE."Item No." + '|' + ILE."Location Code" + '|' + Format(MonthStartLocal);
                if not InsertedKeys.ContainsKey(KeyText) then begin
                    InsertedKeys.Add(KeyText, true);
                    Rec.Init();
                    Rec."Entry No." := NextEntryNo;
                    NextEntryNo += 1;
                    Rec."Item No." := ILE."Item No.";
                    Rec."Location Code" := ILE."Location Code";
                    Rec."Posting Date" := MonthStartLocal; // month anchor
                    Rec.Insert();
                end;
            until ILE.Next() = 0;
    end;

    local procedure GetMonthBounds(BaseDate: Date; var MonthStartOut: Date; var MonthEndOut: Date; var MonthYearOut: Text[7])
    var
        Month: Integer;
        Year: Integer;
    begin
        if BaseDate = 0D then begin
            MonthStartOut := 0D;
            MonthEndOut := 0D;
            MonthYearOut := '';
            exit;
        end;

        Month := Date2DMY(BaseDate, 2);
        Year := Date2DMY(BaseDate, 3);
        MonthStartOut := DMY2Date(1, Month, Year);
        MonthEndOut := CalcDate('<CM>', MonthStartOut) - 1;
        MonthYearOut := Format(MonthStartOut, 0, '<Month,2>-<Year4>');
    end;

    local procedure GetCubage(ItemRec: Record Item): Decimal
    var
        UOM: Record "Item Unit of Measure";
    begin
        if ItemRec."Base Unit of Measure" = '' then
            exit(0);

        UOM.Reset();
        UOM.SetRange("Item No.", ItemRec."No.");
        UOM.SetRange(Code, ItemRec."Base Unit of Measure");
        if UOM.FindFirst() then
            exit(UOM.Cubage);

        exit(0);
    end;

    var
        ItemRec: Record Item;
        GLSetup: Record "General Ledger Setup";
        ILE: Record "Item Ledger Entry";

        ItemDescription: Text[100];
        ItemCategory: Code[20];
        GlobalDim1: Code[20];
        GlobalDim2: Code[20];
        ShortcutDim3Val: Code[20];
        ShortcutDim4Val: Code[20];
        ShortcutDim5Val: Code[20];
        ShortcutDim6Val: Code[20];
        ShortcutDim7Val: Code[20];
        ShortcutDim8Val: Code[20];

        InventoryQty: Decimal;
        InventoryStarting: Decimal;
        UnitCost: Decimal;
        LastDirectCost: Decimal;
        Cubage: Decimal;

        InventoryUnitCostValue: Decimal;
        InventoryLastDirectCostValue: Decimal;
        InventoryCubageValue: Decimal;

        MonthStart: Date;
        MonthEnd: Date;
        MonthYearTxt: Text[7];
        MonthLength: Integer;

        InsertedKeys: Dictionary of [Text, Boolean];
        NextEntryNo: Integer;
}

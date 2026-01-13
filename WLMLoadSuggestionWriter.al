codeunit 89689 "WLM LoadSuggestionWriter" implements "WLM Load Suggestion Handler"
{
    procedure AddSuggestion(
        ItemNo: Code[20];
        LocationCode: Code[10];
        RequiredDate: Date;
        LoadUnitCode: Code[10];
        SubUnitQty: Decimal;
        ParentUnitQty: Decimal;
        PriorityScore: Decimal;
        ShortageDate: Date;
        SuggestionType: Enum "WLM Load Suggestion Type";
        SourceLocationCode: Code[10];
        SourceVendorNo: Code[20];
        ReleaseDate: Date;
        LoadGroupId: Guid;
        ProposedDocumentNo: Text[30];
        RequirementMonth: Integer;
        RequirementYear: Integer;
        RequirementPeriod: Text[10];
        PctOfParentUnit: Decimal;
        BaseQtyRequired: Decimal;
        DaysUntilRequired: Integer;
        MonthPriorityRank: Integer;
        UrgencyLevel: Integer;
        StockoutQty: Decimal;
        ParRebuildQty: Decimal)
    var
        Suggestion: Record "WLM Load Suggestion";
        ExistingSuggestion: Record "WLM Load Suggestion";
    begin
        // Check if a suggestion for this Item + Location + Load Group already exists
        // If so, consolidate by adding quantities to the existing record
        ExistingSuggestion.Reset();
        ExistingSuggestion.SetRange("Load Group ID", LoadGroupId);
        ExistingSuggestion.SetRange("Item No.", ItemNo);
        ExistingSuggestion.SetRange("Location Code", LocationCode);
        if ExistingSuggestion.FindFirst() then begin
            // Consolidate: add quantities to existing suggestion
            ExistingSuggestion."Sub Units" += SubUnitQty;
            ExistingSuggestion."Parent Units" += ParentUnitQty;
            ExistingSuggestion."Base Qty Required" += BaseQtyRequired;
            ExistingSuggestion."Pct of Parent Unit" += PctOfParentUnit;
            ExistingSuggestion."Stockout Qty" += StockoutQty;
            ExistingSuggestion."Par Rebuild Qty" += ParRebuildQty;

            // Use earliest required date and shortage date
            if (RequiredDate <> 0D) and ((ExistingSuggestion."Required Date" = 0D) or (RequiredDate < ExistingSuggestion."Required Date")) then
                ExistingSuggestion."Required Date" := RequiredDate;
            if (ShortageDate <> 0D) and ((ExistingSuggestion."Shortage Date" = 0D) or (ShortageDate < ExistingSuggestion."Shortage Date")) then
                ExistingSuggestion."Shortage Date" := ShortageDate;

            // Use higher priority score
            if PriorityScore > ExistingSuggestion."Priority Score" then
                ExistingSuggestion."Priority Score" := PriorityScore;

            // Use higher urgency level (Stockout > BelowROP > ParStock)
            if UrgencyLevel > ExistingSuggestion."Urgency Level" then
                ExistingSuggestion."Urgency Level" := UrgencyLevel;

            // Use earliest requirement period
            if RequirementPeriod < ExistingSuggestion."Requirement Period" then begin
                ExistingSuggestion."Requirement Period" := CopyStr(RequirementPeriod, 1, MaxStrLen(ExistingSuggestion."Requirement Period"));
                ExistingSuggestion."Requirement Month" := RequirementMonth;
                ExistingSuggestion."Requirement Year" := RequirementYear;
            end;

            // Use minimum days until required
            if DaysUntilRequired < ExistingSuggestion."Days Until Required" then
                ExistingSuggestion."Days Until Required" := DaysUntilRequired;

            // Use minimum month priority rank (lower = higher priority)
            if MonthPriorityRank < ExistingSuggestion."Month Priority Rank" then
                ExistingSuggestion."Month Priority Rank" := MonthPriorityRank;

            ExistingSuggestion.Modify(true);
            exit;
        end;

        // No existing suggestion found - create new one
        Suggestion.Init();
        Suggestion."Item No." := ItemNo;
        Suggestion."Location Code" := LocationCode;
        Suggestion."Required Date" := RequiredDate;
        Suggestion."Load Unit Code" := LoadUnitCode;
        Suggestion."Sub Units" := SubUnitQty;
        Suggestion."Parent Units" := ParentUnitQty;
        Suggestion."Priority Score" := PriorityScore;
        Suggestion."Shortage Date" := ShortageDate;
        Suggestion."Suggestion Type" := SuggestionType;
        Suggestion."Source Location Code" := SourceLocationCode;
        Suggestion."Source Vendor No." := SourceVendorNo;
        Suggestion."Release Date" := ReleaseDate;
        Suggestion."Load Group ID" := LoadGroupId;
        Suggestion."Proposed Document No." := ProposedDocumentNo;
        Suggestion."Requirement Month" := RequirementMonth;
        Suggestion."Requirement Year" := RequirementYear;
        Suggestion."Requirement Period" := CopyStr(RequirementPeriod, 1, MaxStrLen(Suggestion."Requirement Period"));
        Suggestion."Pct of Parent Unit" := PctOfParentUnit;
        Suggestion."Base Qty Required" := BaseQtyRequired;
        Suggestion."Days Until Required" := DaysUntilRequired;
        Suggestion."Month Priority Rank" := MonthPriorityRank;
        Suggestion."Urgency Level" := UrgencyLevel;
        Suggestion."Stockout Qty" := StockoutQty;
        Suggestion."Par Rebuild Qty" := ParRebuildQty;
        Suggestion.Status := Suggestion.Status::Open;
        Suggestion.Insert(true);
    end;
}

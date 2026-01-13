interface "WLM Load Suggestion Handler"
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
        ParRebuildQty: Decimal);
}

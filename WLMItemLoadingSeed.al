codeunit 89684 "WLM ItemLoadingSeed"
{
    procedure SeedAll(): Integer
    var
        Item: Record Item;
        Inserted: Integer;
    begin
        Item.Reset();
        if Item.FindSet() then
            repeat
                if EnsureItem(Item."No.") then
                    Inserted += 1;
            until Item.Next() = 0;

        exit(Inserted);
    end;

    procedure EnsureItem(ItemNo: Code[20]): Boolean
    var
        Load: Record "WLM Item Loading Unit";
    begin
        if ItemNo = '' then
            exit(false);

        if Load.Get(ItemNo) then
            exit(false);

        Load.Init();
        Load.Validate("Item No.", ItemNo);
        Load.Insert(true);
        exit(true);
    end;
}

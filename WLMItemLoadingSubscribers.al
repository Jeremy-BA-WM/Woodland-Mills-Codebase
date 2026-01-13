codeunit 89687 "WLM ItemLoadingSubscribers"
{
    [EventSubscriber(ObjectType::Table, Database::Item, 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertItem(var Rec: Record Item; RunTrigger: Boolean)
    var
        Seeder: Codeunit "WLM ItemLoadingSeed";
    begin
        Seeder.EnsureItem(Rec."No.");
    end;
}

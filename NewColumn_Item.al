// Filename: ItemExtension.al
tableextension 80001 "Item Table Ext JV1" extends Item
{
    fields
    {
        field(80001; "Revision ID"; Code[20])
        {
            Caption = 'Revision ID';
            DataClassification = CustomerContent; // Or ToBeClassified
        }
    }
}

pageextension 80002 "Item Card Ext" extends "Item Card"
{
    layout
    {
        addlast(Content)
        {
            field("Revision ID"; Rec."Revision ID")
            {
                ApplicationArea = All;
            }
        }
    }
}
// Filename: ItemExtension.al
tableextension 80004 "Item Table Ext JV2" extends Item
{
    fields
    {
        field(80004; "Label Output"; Code[20])
        {
            Caption = 'Label Output';
            DataClassification = CustomerContent; // Or ToBeClassified
        }
    }
}

pageextension 80006 "Label Output" extends "Item Card"
{
    layout
    {
        addlast(Content)
        {
            field("Label Output"; Rec."Label Output")
            {
                ApplicationArea = All;
            }
        }
    }
}

tableextension 89651 "WLM Item Shortcut Dims" extends Item
{
    fields
    {
        field(89650; "Shortcut Dim 3 Code FF"; Code[20])
        {
            Caption = 'Shortcut Dimension 3 Code';
            FieldClass = FlowFilter;
        }
        field(89651; "Shortcut Dim 3 Value FF"; Code[20])
        {
            Caption = 'Shortcut Dimension 3';
            FieldClass = FlowField;
            CalcFormula = lookup("Default Dimension"."Dimension Value Code" where("Table ID" = const(Database::Item), "No." = field("No."), "Dimension Code" = field("Shortcut Dim 3 Code FF")));
        }

        field(89652; "Shortcut Dim 4 Code FF"; Code[20])
        {
            Caption = 'Shortcut Dimension 4 Code';
            FieldClass = FlowFilter;
        }
        field(89653; "Shortcut Dim 4 Value FF"; Code[20])
        {
            Caption = 'Shortcut Dimension 4';
            FieldClass = FlowField;
            CalcFormula = lookup("Default Dimension"."Dimension Value Code" where("Table ID" = const(Database::Item), "No." = field("No."), "Dimension Code" = field("Shortcut Dim 4 Code FF")));
        }

        field(89654; "Shortcut Dim 5 Code FF"; Code[20])
        {
            Caption = 'Shortcut Dimension 5 Code';
            FieldClass = FlowFilter;
        }
        field(89655; "Shortcut Dim 5 Value FF"; Code[20])
        {
            Caption = 'Shortcut Dimension 5';
            FieldClass = FlowField;
            CalcFormula = lookup("Default Dimension"."Dimension Value Code" where("Table ID" = const(Database::Item), "No." = field("No."), "Dimension Code" = field("Shortcut Dim 5 Code FF")));
        }

        field(89656; "Shortcut Dim 6 Code FF"; Code[20])
        {
            Caption = 'Shortcut Dimension 6 Code';
            FieldClass = FlowFilter;
        }
        field(89657; "Shortcut Dim 6 Value FF"; Code[20])
        {
            Caption = 'Shortcut Dimension 6';
            FieldClass = FlowField;
            CalcFormula = lookup("Default Dimension"."Dimension Value Code" where("Table ID" = const(Database::Item), "No." = field("No."), "Dimension Code" = field("Shortcut Dim 6 Code FF")));
        }

        field(89658; "Shortcut Dim 7 Code FF"; Code[20])
        {
            Caption = 'Shortcut Dimension 7 Code';
            FieldClass = FlowFilter;
        }
        field(89659; "Shortcut Dim 7 Value FF"; Code[20])
        {
            Caption = 'Shortcut Dimension 7';
            FieldClass = FlowField;
            CalcFormula = lookup("Default Dimension"."Dimension Value Code" where("Table ID" = const(Database::Item), "No." = field("No."), "Dimension Code" = field("Shortcut Dim 7 Code FF")));
        }

        field(89660; "Shortcut Dim 8 Code FF"; Code[20])
        {
            Caption = 'Shortcut Dimension 8 Code';
            FieldClass = FlowFilter;
        }
        field(89661; "Shortcut Dim 8 Value FF"; Code[20])
        {
            Caption = 'Shortcut Dimension 8';
            FieldClass = FlowField;
            CalcFormula = lookup("Default Dimension"."Dimension Value Code" where("Table ID" = const(Database::Item), "No." = field("No."), "Dimension Code" = field("Shortcut Dim 8 Code FF")));
        }
    }
}

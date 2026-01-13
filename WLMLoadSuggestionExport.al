report 89697 "WLM Load Suggestion Export"
{
    Caption = 'WLM Load Suggestion Export';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    ProcessingOnly = true;

    dataset
    {
        dataitem(LoadSuggestion; "WLM Load Suggestion")
        {
            RequestFilterFields = "Load Group ID", "Item No.", "Location Code", "Suggestion Type", Status;

            trigger OnPreDataItem()
            begin
                RowNo := 1;
                // Create headers
                TempExcelBuffer.NewRow();
                AddColumn('Entry No.');
                AddColumn('Item No.');
                AddColumn('Description');
                AddColumn('Vendor No.');
                AddColumn('Location Code');
                AddColumn('Required Date');
                AddColumn('Req. Period');
                AddColumn('Req. Month');
                AddColumn('Req. Year');
                AddColumn('Load Unit Code');
                AddColumn('Sub Units');
                AddColumn('Parent Units');
                AddColumn('% of Parent');
                AddColumn('Units/Sub');
                AddColumn('Base Qty Req.');
                AddColumn('Stockout Qty');
                AddColumn('Par Rebuild Qty');
                AddColumn('Urgency Level');
                AddColumn('Days Until Req.');
                AddColumn('Month Priority');
                AddColumn('Shortage Date');
                AddColumn('Suggestion Type');
                AddColumn('Source Location');
                AddColumn('Source Vendor');
                AddColumn('Release Date');
                AddColumn('Load Group ID');
                AddColumn('Load Batch No.');
                AddColumn('Load Profile Code');
                AddColumn('Proposed Doc No.');
                AddColumn('Priority Score');
                AddColumn('Status');
                AddColumn('Created At');
                AddColumn('Created By');
            end;

            trigger OnAfterGetRecord()
            var
                Item: Record Item;
                ItemDesc: Text[100];
                VendNo: Code[20];
                UnitsPerSub: Integer;
            begin
                ItemDesc := '';
                VendNo := '';
                if Item.Get("Item No.") then begin
                    ItemDesc := Item.Description;
                    VendNo := Item."Vendor No.";
                end;

                // Calculate FlowField
                CalcFields("Units per Sub Unit");
                UnitsPerSub := "Units per Sub Unit";

                TempExcelBuffer.NewRow();
                AddColumnNumber("Entry No.");
                AddColumn("Item No.");
                AddColumn(ItemDesc);
                AddColumn(VendNo);
                AddColumn("Location Code");
                AddColumnDate("Required Date");
                AddColumn("Requirement Period");
                AddColumnNumber("Requirement Month");
                AddColumnNumber("Requirement Year");
                AddColumn("Load Unit Code");
                AddColumnNumber("Sub Units");
                AddColumnNumber("Parent Units");
                AddColumnNumber("Pct of Parent Unit");
                AddColumnNumber(UnitsPerSub);
                AddColumnNumber("Base Qty Required");
                AddColumnNumber("Stockout Qty");
                AddColumnNumber("Par Rebuild Qty");
                AddColumn(Format("Urgency Level"));
                AddColumnNumber("Days Until Required");
                AddColumnNumber("Month Priority Rank");
                AddColumnDate("Shortage Date");
                AddColumn(Format("Suggestion Type"));
                AddColumn("Source Location Code");
                AddColumn("Source Vendor No.");
                AddColumnDate("Release Date");
                AddColumn(Format("Load Group ID"));
                AddColumn("Load Batch No.");
                AddColumn("Load Profile Code");
                AddColumn("Proposed Document No.");
                AddColumnNumber("Priority Score");
                AddColumn(Format(Status));
                AddColumnDateTime("Created At");
                AddColumn("Created By");
            end;

            trigger OnPostDataItem()
            begin
                TempExcelBuffer.CreateNewBook('Load Suggestions');
                TempExcelBuffer.WriteSheet('Load Suggestions', CompanyName, UserId);
                TempExcelBuffer.CloseBook();
                TempExcelBuffer.SetFriendlyFilename('WLM Load Suggestions Export');
                TempExcelBuffer.OpenExcel();
            end;
        }
    }

    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        RowNo: Integer;
        ColNo: Integer;

    local procedure AddColumn(Value: Text)
    begin
        TempExcelBuffer.AddColumn(Value, false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
    end;

    local procedure AddColumnNumber(Value: Decimal)
    begin
        TempExcelBuffer.AddColumn(Value, false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Number);
    end;

    local procedure AddColumnDate(Value: Date)
    begin
        if Value <> 0D then
            TempExcelBuffer.AddColumn(Value, false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Date)
        else
            TempExcelBuffer.AddColumn('', false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
    end;

    local procedure AddColumnDateTime(Value: DateTime)
    begin
        if Value <> 0DT then
            TempExcelBuffer.AddColumn(Value, false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Date)
        else
            TempExcelBuffer.AddColumn('', false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
    end;
}

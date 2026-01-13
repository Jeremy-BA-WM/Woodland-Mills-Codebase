codeunit 89690 "WLM LoadSuggestionMgt"
{
    procedure RebuildSuggestions(FromDate: Date; ToDate: Date)
    var
        Planner: Codeunit "WLM LoadPlanner";
        Writer: Codeunit "WLM LoadSuggestionWriter";
    begin
        ClearOpenSuggestions();
        Planner.BuildLoadSuggestions(FromDate, ToDate, Writer);
    end;

    procedure ClearOpenSuggestions()
    var
        Suggestion: Record "WLM Load Suggestion";
        LoadBatch: Record "WLM Load Batch";
    begin
        Suggestion.Reset();
        Suggestion.SetRange(Status, Suggestion.Status::Open);
        if Suggestion.FindSet() then
            Suggestion.DeleteAll(true);

        LoadBatch.Reset();
        if LoadBatch.FindSet() then
            LoadBatch.DeleteAll(true);
    end;

    procedure ReleaseSuggestion(var Suggestion: Record "WLM Load Suggestion")
    begin
        if Suggestion.Status <> Suggestion.Status::Open then
            exit;

        Suggestion.Status := Suggestion.Status::Released;
        Suggestion.Modify(true);
    end;

    procedure SkipSuggestion(var Suggestion: Record "WLM Load Suggestion")
    begin
        if Suggestion.Status <> Suggestion.Status::Open then
            exit;

        Suggestion.Status := Suggestion.Status::Skipped;
        Suggestion.Modify(true);
    end;

    procedure ReleaseBatch(var Batch: Record "WLM Load Batch")
    var
        Suggestion: Record "WLM Load Suggestion";
    begin
        if Batch.Status = Batch.Status::Released then
            exit;

        Suggestion.Reset();
        Suggestion.SetRange("Load Group ID", Batch."Load Group ID");
        Suggestion.SetRange(Status, Suggestion.Status::Open);
        if Suggestion.FindSet() then
            repeat
                ReleaseSuggestion(Suggestion);
            until Suggestion.Next() = 0;

        Batch.Status := Batch.Status::Released;
        Batch.Modify(true);
    end;

    procedure SkipBatch(var Batch: Record "WLM Load Batch")
    var
        Suggestion: Record "WLM Load Suggestion";
    begin
        if Batch.Status = Batch.Status::Skipped then
            exit;

        Suggestion.Reset();
        Suggestion.SetRange("Load Group ID", Batch."Load Group ID");
        Suggestion.SetRange(Status, Suggestion.Status::Open);
        if Suggestion.FindSet() then
            repeat
                SkipSuggestion(Suggestion);
            until Suggestion.Next() = 0;

        Batch.Status := Batch.Status::Skipped;
        Batch.Modify(true);
    end;

    procedure PromoteBatchesToDocuments(var Batch: Record "WLM Load Batch"): Integer
    var
        CreatedCount: Integer;
    begin
        CreatedCount := 0;

        if not Batch.FindSet() then
            exit(0);

        repeat
            if Batch.Status = Batch.Status::Released then begin
                case Batch."Suggestion Type" of
                    Batch."Suggestion Type"::Purchase:
                        if CreatePurchaseOrder(Batch) then
                            CreatedCount += 1;
                    Batch."Suggestion Type"::Transfer:
                        if CreateTransferOrder(Batch) then
                            CreatedCount += 1;
                end;
            end;
        until Batch.Next() = 0;

        exit(CreatedCount);
    end;

    local procedure CreatePurchaseOrder(var Batch: Record "WLM Load Batch"): Boolean
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        Suggestion: Record "WLM Load Suggestion";
        Item: Record Item;
        LineNo: Integer;
    begin
        if Batch."Vendor No." = '' then begin
            Message('Batch %1 has no vendor specified. Cannot create purchase order.', Batch."Batch No.");
            exit(false);
        end;

        // Create Purchase Header
        PurchHeader.Init();
        PurchHeader."Document Type" := PurchHeader."Document Type"::Order;
        PurchHeader.Insert(true);
        PurchHeader.Validate("Buy-from Vendor No.", Batch."Vendor No.");
        if Batch."Destination Location Code" <> '' then
            PurchHeader.Validate("Location Code", Batch."Destination Location Code");
        // Set Order Date from Release Date (when to place the order)
        if Batch."Release Date" <> 0D then
            PurchHeader.Validate("Order Date", Batch."Release Date");
        if Batch."Expected Receipt Date" <> 0D then
            PurchHeader.Validate("Expected Receipt Date", Batch."Expected Receipt Date");
        if Batch."Shipping Method Code" <> '' then
            PurchHeader.Validate("Shipment Method Code", Batch."Shipping Method Code");
        PurchHeader.Modify(true);

        // Create Purchase Lines from suggestions
        LineNo := 10000;
        Suggestion.Reset();
        Suggestion.SetRange("Load Group ID", Batch."Load Group ID");
        Suggestion.SetFilter(Status, '%1|%2', Suggestion.Status::Open, Suggestion.Status::Released);
        if Suggestion.FindSet(true) then
            repeat
                PurchLine.Init();
                PurchLine."Document Type" := PurchHeader."Document Type";
                PurchLine."Document No." := PurchHeader."No.";
                PurchLine."Line No." := LineNo;
                PurchLine.Insert(true);
                PurchLine.Validate(Type, PurchLine.Type::Item);
                PurchLine.Validate("No.", Suggestion."Item No.");
                PurchLine.Validate(Quantity, Suggestion."Sub Units");
                if Suggestion."Location Code" <> '' then
                    PurchLine.Validate("Location Code", Suggestion."Location Code");
                if Batch."Expected Receipt Date" <> 0D then
                    PurchLine.Validate("Expected Receipt Date", Batch."Expected Receipt Date");
                PurchLine.Modify(true);

                // Update suggestion with document reference and mark as released
                Suggestion."Proposed Document No." := PurchHeader."No.";
                Suggestion.Status := Suggestion.Status::Released;
                Suggestion.Modify(true);

                LineNo += 10000;
            until Suggestion.Next() = 0;

        // Update batch with created document
        Batch."Proposed Document No." := PurchHeader."No.";
        Batch.Status := Batch.Status::Closed;
        Batch.Modify(true);

        exit(true);
    end;

    local procedure CreateTransferOrder(var Batch: Record "WLM Load Batch"): Boolean
    var
        TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
        Suggestion: Record "WLM Load Suggestion";
        LineNo: Integer;
    begin
        if (Batch."Source Location Code" = '') or (Batch."Destination Location Code" = '') then begin
            Message('Batch %1 missing source or destination location. Cannot create transfer order.', Batch."Batch No.");
            exit(false);
        end;

        // Create Transfer Header
        TransHeader.Init();
        TransHeader.Insert(true);
        TransHeader.Validate("Transfer-from Code", Batch."Source Location Code");
        TransHeader.Validate("Transfer-to Code", Batch."Destination Location Code");
        // Set Shipment Date from Release Date (when to initiate the transfer)
        if Batch."Release Date" <> 0D then
            TransHeader.Validate("Shipment Date", Batch."Release Date");
        if Batch."Expected Receipt Date" <> 0D then
            TransHeader.Validate("Receipt Date", Batch."Expected Receipt Date");
        if Batch."Shipping Method Code" <> '' then
            TransHeader.Validate("Shipment Method Code", Batch."Shipping Method Code");
        TransHeader.Modify(true);

        // Create Transfer Lines from suggestions
        LineNo := 10000;
        Suggestion.Reset();
        Suggestion.SetRange("Load Group ID", Batch."Load Group ID");
        Suggestion.SetFilter(Status, '%1|%2', Suggestion.Status::Open, Suggestion.Status::Released);
        if Suggestion.FindSet(true) then
            repeat
                TransLine.Init();
                TransLine."Document No." := TransHeader."No.";
                TransLine."Line No." := LineNo;
                TransLine.Insert(true);
                TransLine.Validate("Item No.", Suggestion."Item No.");
                TransLine.Validate(Quantity, Suggestion."Sub Units");
                if Batch."Expected Receipt Date" <> 0D then
                    TransLine.Validate("Receipt Date", Batch."Expected Receipt Date");
                TransLine.Modify(true);

                // Update suggestion with document reference and mark as released
                Suggestion."Proposed Document No." := TransHeader."No.";
                Suggestion.Status := Suggestion.Status::Released;
                Suggestion.Modify(true);

                LineNo += 10000;
            until Suggestion.Next() = 0;

        // Update batch with created document
        Batch."Proposed Document No." := TransHeader."No.";
        Batch.Status := Batch.Status::Closed;
        Batch.Modify(true);

        exit(true);
    end;
}

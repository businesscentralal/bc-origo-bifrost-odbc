namespace Origo.Bifrost.ODBC;

using Origo.Bifrost;

/// <summary>Runs one read-only SELECT with positional parameters and a row limit.</summary>
codeunit 10035520 "ODBC Query Run Impl ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
{
    Access = Internal;

    var
        Contracts: Codeunit "ODBC Contract Parts ori";
        DescriptionLbl: Label 'Runs one read-only SELECT with positional parameters and a row limit.', MaxLength = 250, Comment = 'is-IS=Keyrir eina SELECT-lesfyrirspurn með stika í röð og línuhámarki.';

    /// <summary>Reports availability.</summary>
    procedure IsEnabled(): Boolean
    begin
        exit(true);
    end;

    /// <summary>No Foundation record filter is used.</summary>
    procedure GetFilterTableNo(): Integer
    begin
        exit(0);
    end;

    /// <summary>Returns localized help.</summary>
    procedure GetDescription(): Text[250]
    begin
        exit(DescriptionLbl);
    end;

    /// <summary>Declares the read direction.</summary>
    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit(Enum::"Msg Direction ori"::Outbound);
    end;

    /// <summary>Returns localized search text.</summary>
    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'ODBC query, read only SQL, SELECT query, positional parameters, row limit', Comment = 'is-IS=ODBC-fyrirspurn, SQL-lestur, SELECT-fyrirspurn, stikar í röð, línuhámark';
    begin
        exit(KeywordsLbl);
    end;

    /// <summary>Returns localized selection help.</summary>
    procedure GetSelectionDescription(): Text
    begin
        exit(DescriptionLbl);
    end;

    /// <summary>Runs the licensed request through the shared read-only handler.</summary>
    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    var
        Handler: Codeunit "ODBC Message Handler ori";
    begin
        Argument.AssertIsLicensed();
        Argument.AssertVersion1();
        Handler.Execute(Enum::"Message Type ori"::"ODBC.Query.Run", Argument);
    end;

    /// <summary>Returns the envelope contract chapter.</summary>
    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    begin
        Envelope := Contracts.Envelope(Enum::"Message Type ori"::"ODBC.Query.Run");
        exit(true);
    end;

    /// <summary>Returns the target contract chapter.</summary>
    procedure GetTarget(var Target: JsonArray): Boolean
    begin
        exit(false);
    end;

    /// <summary>Returns the parameters contract chapter.</summary>
    procedure GetParameters(var Parameters: JsonArray): Boolean
    begin
        Parameters := Contracts.Parameters(Enum::"Message Type ori"::"ODBC.Query.Run");
        exit(true);
    end;

    /// <summary>Returns the response contract chapter.</summary>
    procedure GetResponse(var Response: JsonObject): Boolean
    begin
        Response := Contracts.Response(Enum::"Message Type ori"::"ODBC.Query.Run");
        exit(true);
    end;

    /// <summary>Returns the errors contract chapter.</summary>
    procedure GetErrors(var Errors: JsonArray): Boolean
    begin
        Errors := Contracts.Errors(Enum::"Message Type ori"::"ODBC.Query.Run");
        exit(true);
    end;

    /// <summary>Returns the effect contract chapter.</summary>
    procedure GetEffect(var Effect: JsonObject): Boolean
    begin
        Effect := Contracts.Effect(Enum::"Message Type ori"::"ODBC.Query.Run");
        exit(true);
    end;

    /// <summary>Returns the metering contract chapter.</summary>
    procedure GetMetering(var Metering: JsonObject): Boolean
    begin
        exit(false);
    end;

    /// <summary>Returns the related contract chapter.</summary>
    procedure GetRelated(var Related: JsonArray): Boolean
    begin
        exit(false);
    end;

    /// <summary>Returns the workflow contract chapter.</summary>
    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    begin
        exit(false);
    end;

    /// <summary>Returns the examples contract chapter.</summary>
    procedure GetExamples(var Examples: JsonArray): Boolean
    begin
        Examples := Contracts.Examples(Enum::"Message Type ori"::"ODBC.Query.Run");
        exit(true);
    end;

    /// <summary>Returns the overview contract chapter.</summary>
    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := DescriptionLbl;
        exit(true);
    end;

    /// <summary>Returns the notes contract chapter.</summary>
    procedure GetNotes(var Notes: Text): Boolean
    begin
        Notes := Contracts.Notes();
        exit(true);
    end;
}

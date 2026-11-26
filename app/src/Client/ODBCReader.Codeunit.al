namespace Origo.Bifrost.ODBC;

/// <summary>Forward-only cursor over agent rows. Read must succeed before accessing a value.</summary>
codeunit 10035507 "ODBC Reader ori"
{
    Access = Public;
    InherentPermissions = X;
    InherentEntitlements = X;

    var
        Rows: JsonArray;
        Columns: List of [Text];
        CurrentRow: JsonObject;
        Position: Integer;
        Truncated: Boolean;
        NoRowErr: Label 'Call Read successfully before reading an ODBC value.', Comment = 'is-IS=Kallaðu á Read með árangri áður en ODBC-gildi er lesið.';
        MissingColumnErr: Label 'The ODBC result has no column named %1.', Comment = '%1 = column; is-IS=ODBC-niðurstaðan hefur engan dálk sem heitir %1.';
        InvalidRowsErr: Label 'The ODBC agent returned an invalid row result.', Comment = 'is-IS=ODBC-miðlarinn skilaði ógildri línuniðurstöðu.';

    /// <summary>Advances to the next row. False means the cursor is exhausted.</summary>
    /// <returns>True if there is a current row.</returns>
    procedure Read(): Boolean
    var
        Token: JsonToken;
    begin
        Clear(CurrentRow);
        Position += 1;
        if Position > Rows.Count() then
            exit(false);
        Rows.Get(Position - 1, Token);
        CurrentRow := Token.AsObject();
        exit(true);
    end;

    /// <summary>Returns the text value of a column on the current row.</summary>
    /// <param name="ColumnName">Exact column name.</param>
    /// <returns>The typed value; null or an incompatible type raises an error.</returns>
    procedure GetText(ColumnName: Text): Text
    begin
        exit(GetValue(ColumnName).AsText());
    end;

    /// <summary>Returns an integer from the current row.</summary>
    /// <param name="ColumnName">Exact column name.</param>
    /// <returns>The integer value.</returns>
    procedure GetInteger(ColumnName: Text): Integer
    begin
        exit(GetValue(ColumnName).AsInteger());
    end;

    /// <summary>Returns a decimal from the current row.</summary>
    /// <param name="ColumnName">Exact column name.</param>
    /// <returns>The decimal value.</returns>
    procedure GetDecimal(ColumnName: Text): Decimal
    begin
        exit(GetValue(ColumnName).AsDecimal());
    end;

    /// <summary>Returns a Boolean from the current row.</summary>
    /// <param name="ColumnName">Exact column name.</param>
    /// <returns>The Boolean value.</returns>
    procedure GetBoolean(ColumnName: Text): Boolean
    begin
        exit(GetValue(ColumnName).AsBoolean());
    end;

    /// <summary>Returns an ISO date from the current row.</summary>
    /// <param name="ColumnName">Exact column name.</param>
    /// <returns>The date value.</returns>
    procedure GetDate(ColumnName: Text): Date
    begin
        exit(GetValue(ColumnName).AsDate());
    end;

    /// <summary>Returns an ISO date/time from the current row.</summary>
    /// <param name="ColumnName">Exact column name.</param>
    /// <returns>The date/time value.</returns>
    procedure GetDateTime(ColumnName: Text): DateTime
    begin
        exit(GetValue(ColumnName).AsDateTime());
    end;

    /// <summary>Checks SQL NULL without trying to convert it.</summary>
    /// <param name="ColumnName">Exact column name.</param>
    /// <returns>True for a JSON null value.</returns>
    procedure IsNull(ColumnName: Text): Boolean
    begin
        exit(GetValue(ColumnName).IsNull());
    end;

    /// <summary>Returns the column names, including metadata for an empty result.</summary>
    /// <returns>Column names in agent order.</returns>
    procedure GetColumns(): List of [Text]
    begin
        exit(Columns);
    end;

    /// <summary>Returns whether the agent or BC truncated this result.</summary>
    /// <returns>True if rows were omitted.</returns>
    procedure IsTruncated(): Boolean
    begin
        exit(Truncated);
    end;

    /// <summary>Returns the retained row count.</summary>
    /// <returns>Number of rows, at most the configured cap.</returns>
    procedure RowCount(): Integer
    begin
        exit(Rows.Count());
    end;

    /// <summary>Replaces the cursor with a validated, capped response.</summary>
    /// <param name="Response">Agent rows, optional columns and truncated flag.</param>
    /// <param name="RowCap">Maximum rows retained.</param>
    internal procedure Initialize(Response: JsonObject; RowCap: Integer)
    var
        Token: JsonToken;
        Row: JsonToken;
        Column: Text;
        AllRows: JsonArray;
    begin
        Clear(Rows);
        Clear(Columns);
        Clear(CurrentRow);
        Position := 0;
        Truncated := false;
        if not Response.Get('rows', Token) then
            Error(InvalidRowsErr);
        if not Token.IsArray() then
            Error(InvalidRowsErr);
        AllRows := Token.AsArray();
        foreach Row in AllRows do begin
            if not Row.IsObject() then
                Error(InvalidRowsErr);
            if Rows.Count() < RowCap then begin
                Rows.Add(Row);
                foreach Column in Row.AsObject().Keys() do
                    if not Columns.Contains(Column) then
                        Columns.Add(Column);
            end else
                Truncated := true;
        end;
        if Response.Get('columns', Token) then
            foreach Row in Token.AsArray() do
                if not Columns.Contains(Row.AsValue().AsText()) then
                    Columns.Add(Row.AsValue().AsText());
        if Response.Get('truncated', Token) then
            Truncated := Truncated or Token.AsValue().AsBoolean();
    end;

    local procedure GetValue(ColumnName: Text): JsonValue
    var
        Token: JsonToken;
    begin
        if (Position < 1) or (Position > Rows.Count()) then
            Error(NoRowErr);
        if not CurrentRow.Get(ColumnName, Token) then
            Error(MissingColumnErr, ColumnName);
        exit(Token.AsValue());
    end;
}

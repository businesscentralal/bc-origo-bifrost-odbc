namespace Origo.Bifrost.ODBC;

/// <summary>Conservatively accepts one SELECT before any transport call. Quoted data is not interpreted as SQL.</summary>
codeunit 10035523 "ODBC Read Statement ori"
{
    Access = Internal;

    /// <summary>Checks a SELECT without comments, statement delimiters, write keywords or SELECT INTO.</summary>
    /// <param name="SQL">Untrusted SQL, never logged or echoed in an error.</param>
    /// <param name="ParameterCount">Number of positional parameter values.</param>
    /// <returns>True for a bounded single SELECT whose placeholders match its parameters.</returns>
    procedure IsReadOnly(SQL: Text; ParameterCount: Integer): Boolean
    var
        Index: Integer;
        Placeholders: Integer;
        Depth: Integer;
        Quote: Text[1];
        Character: Text[1];
        Word: Text;
        FirstWord: Boolean;
    begin
        if (SQL.Trim() = '') or (StrLen(SQL) > 65536) then
            exit(false);
        Depth := 0;
        FirstWord := true;
        Index := 1;
        while Index <= StrLen(SQL) do begin
            Character := CopyStr(SQL, Index, 1);
            // Backslash escapes differ between ODBC dialects; do not guess string boundaries.
            if Character = '\' then
                exit(false);
            if Quote <> '' then begin
                if Character = Quote then
                    if CopyStr(SQL, Index + 1, 1) = Quote then
                        Index += 1
                    else
                        Quote := '';
            end else
                case Character of
                    '''', '"', '`', '[':
                        begin
                            if not AcceptWord(Word, FirstWord, Depth) then
                                exit(false);
                            if FirstWord then
                                exit(false);
                            Quote := Character;
                            if Character = '[' then
                                Quote := ']';
                        end;
                    ';', '#', '$':
                        exit(false);
                    '-', '/':
                        begin
                            if (CopyStr(SQL, Index, 2) = '--') or (CopyStr(SQL, Index, 2) = '/*') then
                                exit(false);
                            if not AcceptWord(Word, FirstWord, Depth) then
                                exit(false);
                        end;
                    '?':
                        begin
                            if not AcceptWord(Word, FirstWord, Depth) then
                                exit(false);
                            Placeholders += 1;
                        end;
                    '(':
                        begin
                            if not AcceptWord(Word, FirstWord, Depth) then
                                exit(false);
                            Depth += 1;
                        end;
                    ')':
                        begin
                            if not AcceptWord(Word, FirstWord, Depth) then
                                exit(false);
                            Depth -= 1;
                            if Depth < 0 then
                                exit(false);
                        end;
                    else
                        if StrPos('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_$', Character) > 0 then
                            Word += Character
                        else
                            if not AcceptWord(Word, FirstWord, Depth) then
                                exit(false);
                end;
            Index += 1;
        end;
        exit(AcceptWord(Word, FirstWord, Depth) and not FirstWord and (Quote = '') and (Depth = 0) and (Placeholders = ParameterCount));
    end;

    local procedure AcceptWord(var Word: Text; var FirstWord: Boolean; Depth: Integer): Boolean
    var
        Keyword: Text;
    begin
        if Word = '' then
            exit(true);
        Keyword := UpperCase(Word);
        Clear(Word);
        if FirstWord then begin
            FirstWord := false;
            exit(Keyword = 'SELECT');
        end;
        if (Keyword = 'SELECT') and (Depth = 0) then
            exit(false);
        case Keyword of
            'INSERT', 'UPDATE', 'DELETE', 'MERGE', 'CREATE', 'ALTER', 'DROP', 'TRUNCATE', 'EXEC', 'EXECUTE',
            'GRANT', 'REVOKE', 'DENY', 'INTO', 'CALL', 'COPY', 'LOAD', 'OUTFILE', 'DUMPFILE', 'REPLACE',
            'ATTACH', 'DETACH', 'PRAGMA', 'VACUUM', 'ANALYZE', 'SET', 'USE', 'COMMIT', 'ROLLBACK', 'BEGIN',
            'OPENROWSET', 'OPENQUERY', 'OPENDATASOURCE', 'NEXTVAL', 'FOR', 'LOCK', 'UNLOCK':
                exit(false);
        end;
        exit(true);
    end;
}

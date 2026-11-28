using System.Text;

namespace Origo.Bifrost.Odbc.Agent;

// A conservative statement check, supplementary to database-enforced read-only access.
public static class SqlPolicy
{
    private static readonly HashSet<string> Forbidden = new(StringComparer.OrdinalIgnoreCase)
    {
        "INSERT", "UPDATE", "DELETE", "MERGE", "INTO", "CREATE", "ALTER", "DROP", "TRUNCATE",
        "EXEC", "EXECUTE", "CALL", "GRANT", "REVOKE", "DENY", "COPY", "VACUUM", "ATTACH", "DETACH",
        "PRAGMA", "REPLACE", "UPSERT", "LOAD", "UNLOAD", "OPENROWSET", "OPENDATASOURCE", "OUTFILE",
        "SET", "COMMIT", "ROLLBACK", "BEGIN", "TRANSACTION", "LOCK", "UNLOCK", "RECONFIGURE"
    };

    public static void Validate(string sql, int parameterCount, bool readOnly)
    {
        var words = new List<string>();
        var word = new StringBuilder();
        int placeholders = 0;
        void Flush()
        {
            if (word.Length == 0)
                return;
            words.Add(word.ToString());
            word.Clear();
        }
        for (int i = 0; i < sql.Length; i++)
        {
            char c = sql[i];
            if (c is '\'' or '"' or '`' or '[')
            {
                Flush();
                char end = c == '[' ? ']' : c;
                bool closed = false;
                while (++i < sql.Length)
                {
                    if (sql[i] == '\\')
                        throw new InvalidOperationException("Use standard SQL quoting.");
                    if (sql[i] != end)
                        continue;
                    if (i + 1 < sql.Length && sql[i + 1] == end)
                    {
                        i++;
                        continue;
                    }
                    closed = true;
                    break;
                }
                if (!closed)
                    throw new InvalidOperationException("Unclosed SQL quote.");
            }
            else if (char.IsLetterOrDigit(c) || c == '_')
                word.Append(c);
            else
            {
                Flush();
                if (c == '?')
                    placeholders++;
                if (c is ';' or '@' or ':' or '$' or '#' or '\\' or '\0' ||
                    (i + 1 < sql.Length && ((c == '-' && sql[i + 1] == '-') ||
                        (c == '/' && sql[i + 1] == '*'))))
                    throw new InvalidOperationException("Only one parameterized statement without comments is supported.");
            }
        }
        Flush();
        if (words.Count == 0 || placeholders != parameterCount)
            throw new InvalidOperationException("Invalid statement or parameter count.");
        if (readOnly && (!(words[0].Equals("SELECT", StringComparison.OrdinalIgnoreCase) ||
                          words[0].Equals("WITH", StringComparison.OrdinalIgnoreCase)) || words.Any(Forbidden.Contains)))
            throw new InvalidOperationException("Only read-only queries are supported.");
    }
}

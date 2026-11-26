# Uppsetning Bifröst ODBC-miðlara

Miðlarinn er Windows-þjónusta á .NET 8. Hann opnar útleiðartengingu við Azure Relay hybrid connection og notar `System.Data.Odbc.OdbcConnection` með staðbundnum ODBC-rekli. Business Central opnar aldrei sjálft gagnagrunnstengingu. Þjónustan styður Query, Execute (aðeins AL), TestConnection og GetSchema úr opinbera AL-viðmótinu. Engin skilaboðategund veitir gervigreindarþjónum skrifaðgang.

## Forsendur

- Windows x64, viðeigandi 64-bita ODBC-rekill og gagnagrunnur sem þjónustan nær til. Útgáfupakkinn inniheldur .NET-keyrsluumhverfi. DSN verður að vera **64-bita System DSN**; notanda-DSN sést ekki undir þjónustureikningi. Athugaðu það í 64-bita ODBC Data Source Administrator.
- Azure Relay hybrid connection, með aðskildum Send-heimildum fyrir BC og Listen-heimildum fyrir þjónustuna. Aðeins útleið yfir TLS/WebSocket á gátt 443 er nauðsynleg; ekki opna innleiðargátt.
- Sérstakur Windows-þjónustureikningur með lágmarksheimildir og gagnagrunnsnotandi sem má aðeins lesa gögn og lýsigögn. Ekki nota kerfisstjóra, eiganda gagnagrunns, `sysadmin`, `db_owner` eða reikning sem má keyra skrifandi stefjur. Með Windows-auðkenningu við SQL Server er það Windows-auðkenni þjónustunnar sem tengist. Prófun undir kerfisstjóra sannar ekki að þjónustan hafi réttan aðgang.
- Samþykktur **undirritaður CI-pakki**. Staðfestu gilda Authenticode-undirskrift og réttan útgefanda á `Bifrost.Odbc.Agent.exe` og `Bifrost.Odbc.Agent.dll`, ásamt SHA-256-gildi pakkans. Óundirrituð staðbundin smíð er ekki útgáfa.

## Vernduð stilling og lyklaskipti

Settu eftirfarandi umhverfisbreytur upp með samþykktri leyndarmáladreifingu fyrir þjónustureikninginn. Raungildi mega ekki fara í skriftur, skipanasögu, verkbeiðnir, skipanalínur, skjámyndir eða frumkóða. Notaðu sérstakt umhverfi þjónustunnar með registry-heimildum aðeins fyrir kerfisstjóra, SYSTEM og þjónustureikninginn; ekki vélrænar umhverfisbreytur sem allir sjá. Slökktu á minnisskrám og greiningu sem getur skráð minni eða netbeiðnir. Miðlarinn skráir ekki SQL, færibreytugildi, tengistrengi, lykla eða hráar villur frá rekli.

| Breyta | Tilgangur |
| --- | --- |
| `BIFROST_ODBC_RELAY_CONNECTION` | Relay-stilling með Listen-heimild og EntityPath. |
| `BIFROST_ODBC_AES_KEY` | Base64-kóðaður 16/24/32-bæta AES-lykill, sá sami og varinn lykill í BC. |
| `BIFROST_ODBC_AES_VECTOR` | Base64-kóðaður 16-bæta vigur sem samsvarar AES Vector í BC. |
| `BIFROST_ODBC_READ_CONNECTION` | Nákvæmur DSN-/ODBC-tengistrengur fyrir lestur. Gagnagrunnsauðkennið **verður að vera skrifvarið**. |
| `BIFROST_ODBC_WRITE_CONNECTION` | Valfrjáls, aðskilin tenging fyrir Execute í AL. Sleppið til að óvirkja Execute. Ekki nota skrifauðkennið í lestrartengingu. |
| `BIFROST_ODBC_BLOB_CONNECTION` | Valfrjáls geymslustilling, bundin við sérstakan tímabundinn gám. |
| `BIFROST_ODBC_BLOB_CONTAINER` | Nauðsynleg ef Blob er notað; sami gámur og í BC. |

Deildu nýjum slembilykli um samþykkta örugga leið. Í BC notarðu **Set AES key** og setur samsvarandi vigur. Notaðu **Set connection string** fyrir tengistrenginn. Dulkóðunin er AES-CBC/PKCS7 yfir UTF-8, samhæfð Rijndael-veitu BC. CBC staðfestir ekki sjálft heilleika beiðninnar: Relay-heimildir og TLS eru nauðsynleg. Ekki opna undirferlið fyrir netaðgang. Notaðu sérstakt þjónustutilvik og lykil fyrir hverja gagnaveitu/öryggismörk. Endurnýjaðu stillingar beggja vegna samtímis.

Afkóðaði tengistrengurinn verður að samsvara öðrum vernduðum tengistreng þjónustunnar **nákvæmlega**. Lesaðgerðir samþykkja hvora samþykkta tengingu sem er en opna alltaf `BIFROST_ODBC_READ_CONNECTION`; þannig getur AL-gagnaveita sem styður Execute líka lesið með skrifvörn. Execute samþykkir aðeins `BIFROST_ODBC_WRITE_CONNECTION`. Báðar þjónustutengingar verða að vísa á sömu gagnaveitu með aðskildum les-/skrifauðkennum. Beiðni getur ekki skipt yfir á annan DSN eða gagnagrunn né látið lestur nota skrifandi auðkenni. Fyrir fleiri gagnaveitur eru sett upp aðskilin þjónustutilvik. Afkóðun ein og sér heimilar ekki tengingu.

## Skrifvörn gagnagrunns

SQL-síun er viðbótarvörn; hún sannar ekki að fyrirspurn hafi engar hliðarverkanir. Heimildir gagnagrunnsins eru nauðsynlegar, líka ef SQL-skoðun er sniðgengin með aðgerð eða rekilsérhæfðri setningu.

- **SQL Server:** settu upp ODBC Driver 18 for SQL Server. Notaðu Windows-auðkenningu undir sérstökum þjónustureikningi og aðeins SELECT á tilgreindum hlutum ásamt nauðsynlegum lýsigögnum. Ekki veita skrif-, DDL-, eignarhalds-, auðkennisskipta- eða EXECUTE-heimildir. `ApplicationIntent=ReadOnly` er leiðarstýring, ekki skrifvörn. SQL Server býður ekki almennar skrifvarðar færslur; heimildir notandans verja gögnin. Prófaðu INSERT/UPDATE/DELETE og CREATE TABLE beint undir þessu auðkenni áður en þjónustan er tekin í notkun. Notaðu eingöngu sérstaka prófunartöflu sem kerfisstjóri útbýr, aldrei viðskiptagögn.
- **PostgreSQL:** notaðu SELECT-notanda; lesbeiðnir virkja auk þess `SET TRANSACTION READ ONLY`. Ekki veita aðgang að skrifandi stefjum eða security-definer-aðgerðum.
- **SQLite:** notaðu sérstaka gagnagrunnsskrá og takmarkaðar skráarheimildir. Lestrartengingar virkja `PRAGMA query_only = ON` fyrir lýsigögn/fyrirspurnir. Prófanir sniðganga vísvitandi SQL-síuna, staðfesta að vélin hafni UPDATE og að prófunargögn haldist óbreytt. Sleppið skrifatengingu í skrifvarinni uppsetningu.
- **Aðrir ODBC-reklar:** stilltu skrifvörn rekils og notaðu auðkenni sem getur ekki breytt gagnagrunni/skrá. Prófaðu vörnina sjálfstætt. Engin algild skrifvarin ODBC-færsla er til. Ef gagnaveitan getur ekki framfylgt skrifvörn skal ekki setja hana upp sem lesgagnaveitu.

Á staðbundnum prófunarhýsli starfsmanns er SQL Server `localhost`, Windows-auðkenning er notuð og gagnagrunnsheiti er tenant-auðkenni starfsmannsins (mál #9). Þetta er staðbundið frá miðlaranum séð. Prófun býr aðeins til og fellir eigin tímabundna töflu, aldrei BC-töflur. Heildarprófun í máli #5 fer fram eftir sameiningu miðlara og skilaboðategunda.

## Uppsetning og rekstur

1. Afþjappaðu staðfestum, undirrituðum pakka í möppu sem aðeins kerfisstjórar geta breytt. Þjónustureikningurinn fær les-/keyrsluheimildir á forritið, ekki skrifheimildir. Útbúðu verndað þjónustuumhverfi fyrst.
2. Skráðu þjónustuna í Windows Service Control Manager með sérstökum sýndar- eða stýrðum þjónustureikningi. Dæmi með staðgengilsslóð, án aðgangsgagna á skipanalínu:

   ```powershell
   sc.exe create BifrostODBC binPath= '"C:\Program Files\Bifrost ODBC\Bifrost.Odbc.Agent.exe"' start= auto obj= 'NT SERVICE\BifrostODBC'
   sc.exe failure BifrostODBC reset= 86400 actions= restart/5000/restart/30000
   sc.exe start BifrostODBC
   ```

3. Stilltu sama relay, Blob-gám (ef notaður), AES-lykil/vigur og nákvæman ODBC-tengistreng í BC. Hafðu **Read Only** virkt. **Test connection** fer alla leið gegnum Relay og ODBC og skilar rekli, DBMS-heiti og útgáfu. GetSchema notar ODBC-lýsigagnaföll. Engin opin heilsuprófunargátt er til. Í þróun má keyra sömu keyrsluskrá í stjórnborði undir vernduðu prófunarumhverfi.
4. Prófaðu SELECT með færibreytu á eigin nýjum prófunargögnum, línuhámark og hafnaðri beinni skrifbeiðni undir lesauðkenni. Endurtaktu gegnum BC á ensku (1033) og íslensku (1039). Staðfesting uppsetningar ein og sér prófar hvorki flutning né gagnagrunn.
5. Stöðvaðu þjónustuna fyrir lyklaskipti eða uppfærslu forrits. Haltu fyrri staðfestum pakka til baka. Hreinsaðu tímabundnar BC-færslur og Blob-skrár eftir prófanir og fjarlægðu prófunarþjónustu.

Miðlarinn leyfir mest 10.000 línur, 60 sekúndur, 1.024 einfaldar staðsettar færibreytur, 8 MiB inn-/úttak og fjóra samtímaferla. Beiðni má lækka mörkin, ekki hækka þau. Query tekur eina SELECT- eða skrifvarða WITH-setningu með `?`-færibreytum. Nefndum færibreytum, setningaskilum, athugasemdum og skrifskipunum er hafnað utan gæsalappa. Gildi fara í `OdbcParameter`, aldrei í samsettan SQL-texta. Gefðu dálkum einkvæm samnefni. Of stórt stakt gildi veldur villu fremur en að skila hálfu gildi.

Hver beiðni keyrir í sérstöku undirferli sem er stöðvað þegar tíminn er liðinn. Þannig eru líka takmarkaðir reklar sem hunsa tímamörk eða hanga við tengingu/lýsigögn. Lesfærslur eru aldrei staðfestar. Eftir tímamörk í **Execute** getur niðurstaða verið óviss, því breyting gæti þegar hafa verið staðfest. Athugaðu stöðuna áður en reynt er aftur; ekki endurtaka skrif sjálfvirkt.

## Blob-samskiptareglur og hreinsun

JSON úr sögu B notar `operation`, `query`, `parameters`, `readOnly`, `rowCap`, `timeoutSeconds`, `objectFilter`, `dbConnectionString` og valfrjálst `queryFileId`/`responseViaBlob`. GET sér um Query/GetSchema/TestConnection; PUT sér aðeins um Execute með `readOnly=false` og aðskilda skrifatengingu. Heilsupróf skilar `driverName`, `dbmsName`, `dbmsVersion`; Query skilar `columns`, týpuðum `rows` og `truncated`; GetSchema skilar `objects`; Execute skilar `affectedRows`.

Blob-heiti verða að vera stöðluð GUID í lágstöfum, aldrei slóðir eða URL. Miðlarinn eyðir beiðniskrám eftir lestur, líka við gallaðar eða of stórar beiðnir. BC hreinsar eigin beiðni og svör. Miðlarinn eyðir svörum eftir tíu mínútur eða við eðlilega stöðvun ef kallandi hreinsar ekki. Stilltu einnig stuttan líftíma skráa í sérstökum gámi vegna hruns/hýsilbilunar. Ekki geyma skjöl viðskiptavina þar. Misheppnuð hreinsun er tilkynnt sem villa.

Eldri Data Migration-þjónustan heitir `LocalSQLAgent` / `LocalRelaySQLAgent` (.NET 8, `SqlConnection`, aðeins SQL Server). Hún notar GET/PUT, AES-dulkóðað `dbConnectionString`, Blob-heiti `request-<guid>`/`response-<guid>` og svör `queryResult`/`nonQueryResult`. Nýja þjónustan heldur flutningsmynstrinu en fylgir sameinuðum Bifröst JSON-samningi sögu B og GUID-heiti án forskeyta. Hún kemur **ekki óbreytt í stað eldri AL-biðlarans**. Niðurstaða frumathugunar er skráð á epic #36.

## Smíð, prófanir og undirritun

Þróun krefst .NET SDK 8 og SQLite ODBC-rekils. Á Linux má `BIFROST_TEST_SQLITE_DRIVER` vísa á rekilssafnið. Keyrðu `agent/Build-Agent.ps1`: allar prófanir eru keyrðar og sjálfstæður Windows-pakki smíðaður. Vanti rekil fellur keyrslan; prófum er ekki sleppt. Linux-prófanir búa til einkvæmar tímabundnar gagnagrunnsskrár og eyða þeim ásamt journal/WAL-skrám.

Architect þarf að tengja sérstaka agent-smíð við núverandi undirritunarleið fyrirtækisins: smíða/prófa möppuna, gefa út `win-x64`, Authenticode-undirrita EXE og DLL með vernduðum fyrirtækisundirritara, keyra `agent/Package-SignedAgent.ps1` og birta síðan pakka, fullt commit-SHA, gátsummur og TRX-niðurstöður. Pökkunarskriftan hafnar ógildum/óundirrituðum skrám og opnar aldrei einkalykil. Staðbundin Windows-krosssmíð sannar hvorki uppsetningu þjónustu né CI-undirritun. AC05 er ólokið þar til undirritaður CI-pakki liggur fyrir.

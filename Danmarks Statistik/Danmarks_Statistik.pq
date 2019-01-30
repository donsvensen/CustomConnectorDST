// This file contains your Data Connector logic
section Danmarks_Statistik;
// 


[DataSource.Kind="Danmarks_Statistik", Publish="Danmarks_Statistik.Publish"]
shared Danmarks_Statistik.Contents = Value.ReplaceType(PopulationNavTable, type function (url as text) as any);

PopulationNavTable = (url as text) as table =>
    let
        tblName = url, 
        urlAddress = "http://api.statbank.dk/v1/tableinfo/" & tblName & "?format=JSON",
        source = #table({"Name", "Data", "ItemKind", "ItemName", "IsLeaf"}, {
            { "Region", GetRegion(urlAddress), "Table", "Table", true },
            { "Sex", GetSex(urlAddress), "Table", "Table", true },
            { "Age", GetAge(urlAddress), "Table", "Table", true },
            { "Marital Status", GetMaritalStatus(urlAddress), "Table", "Table", true },
            { "Quarter", GetQuarter(urlAddress), "Table", "Table", true },
            { "Population", GetPopulation(tblName), "Table", "Table", true }
        }),
        navTable = Table.ToNavigationTable(source, {"Name"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf")
    in
        navTable;

GetRegion = (url as text) as table =>
    let
        source = Json.Document(Web.Contents(url)),
        variables = source[variables],
        #"Converted to Table" = Table.FromList(variables, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
        #"Expanded {0}" = Table.ExpandRecordColumn(#"Converted to Table", "Column1", {"id", "text", "elimination", "time", "map", "values"}, {"Column1.id", "Column1.text", "Column1.elimination", "Column1.time", "Column1.map", "Column1.values"}),
        #"Column1 values" = #"Expanded {0}"{0}[Column1.values],
        #"Converted to Table1" = Table.FromList(#"Column1 values", Splitter.SplitByNothing(), null, null, ExtraValues.Error),
        allRegions = Table.ExpandRecordColumn(#"Converted to Table1", "Column1", {"id", "text"}, {"RegionId", "Region"}),
        noTotal = Table.SelectRows(allRegions, each ([RegionId] <> "000")),
        x = Table.AddColumn(noTotal, "Municipality", each if not Text.StartsWith([RegionId], "0") then [Region] else null),
        y = Table.ReplaceValue(x, each [Municipality],null,Replacer.ReplaceValue,{"Region"}),
        z = Table.FillDown(y,{"Region"}),
        result = Table.SelectRows(z, each ([Municipality] <> null))
    in
        result;

GetSex = (url as text) as table =>
    let
        source = Json.Document(Web.Contents(url)),
        variables = source[variables],
        #"Converted to Table" = Table.FromList(variables, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
        #"Expanded {0}" = Table.ExpandRecordColumn(#"Converted to Table", "Column1", {"id", "text", "elimination", "time", "map", "values"}, {"Column1.id", "Column1.text", "Column1.elimination", "Column1.time", "Column1.map", "Column1.values"}),
        #"Column1 values" = #"Expanded {0}"{1}[Column1.values],
        #"Converted to Table1" = Table.FromList(#"Column1 values", Splitter.SplitByNothing(), null, null, ExtraValues.Error),
        preFilterResult = Table.ExpandRecordColumn(#"Converted to Table1", "Column1", {"id", "text"}, {"SexId", "Sex"}),
        result = Table.SelectRows(preFilterResult, each ([SexId] <> "TOT"))
    in
        result;

GetAge = (url as text) as table =>
    let
        source = Json.Document(Web.Contents(url)),
        variables = source[variables],
        #"Converted to Table" = Table.FromList(variables, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
        #"Expanded {0}" = Table.ExpandRecordColumn(#"Converted to Table", "Column1", {"id", "text", "elimination", "time", "map", "values"}, {"Column1.id", "Column1.text", "Column1.elimination", "Column1.time", "Column1.map", "Column1.values"}),
        #"Column1 values" = #"Expanded {0}"{2}[Column1.values],
        #"Converted to Table1" = Table.FromList(#"Column1 values", Splitter.SplitByNothing(), null, null, ExtraValues.Error),
        preFilterResult = Table.ExpandRecordColumn(#"Converted to Table1", "Column1", {"id", "text"}, {"AgeId", "Age"}),
        result = Table.SelectRows(preFilterResult, each ([AgeId] <> "IALT"))
    in
        result;


GetMaritalStatus = (url as text) as table =>
    let
        source = Json.Document(Web.Contents(url)),
        variables = source[variables],
        #"Converted to Table" = Table.FromList(variables, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
        #"Expanded {0}" = Table.ExpandRecordColumn(#"Converted to Table", "Column1", {"id", "text", "elimination", "time", "map", "values"}, {"Column1.id", "Column1.text", "Column1.elimination", "Column1.time", "Column1.map", "Column1.values"}),
        #"Column1 values" = #"Expanded {0}"{3}[Column1.values],
        #"Converted to Table1" = Table.FromList(#"Column1 values", Splitter.SplitByNothing(), null, null, ExtraValues.Error),
        preFilterResult = Table.ExpandRecordColumn(#"Converted to Table1", "Column1", {"id", "text"}, {"MaritalStatusId", "Marital Status"}),
        result = Table.SelectRows(preFilterResult, each ([MaritalStatusId] <> "TOT"))
    in
        result;

GetQuarter = (url as text) as table =>
    let
        source = Json.Document(Web.Contents(url)),
        variables = source[variables],
        #"Converted to Table" = Table.FromList(variables, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
        #"Expanded {0}" = Table.ExpandRecordColumn(#"Converted to Table", "Column1", {"id", "text", "elimination", "time", "map", "values"}, {"Column1.id", "Column1.text", "Column1.elimination", "Column1.time", "Column1.map", "Column1.values"}),
        #"Column1 values" = #"Expanded {0}"{4}[Column1.values],
        #"Converted to Table1" = Table.FromList(#"Column1 values", Splitter.SplitByNothing(), null, null, ExtraValues.Error),
        result = Table.ExpandRecordColumn(#"Converted to Table1", "Column1", {"id", "text"}, {"QuarterId", "Quarter"})
    in
        result;

GetPopulation = (tblName as text) as table =>
    let
    Source = Csv.Document(Web.Contents("http://api.statbank.dk/v1/data/" & tblName & "/CSV?valuePresentation=Code&Omr%C3%A5de=*&Alder=*&Tid=*&K%C3%B8n=*&CIVILSTAND=*"),[Delimiter=";", Columns=6, Encoding=65001, QuoteStyle=QuoteStyle.None]),
    #"Promoted Headers" = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    r = Table.TransformColumnTypes(#"Promoted Headers",{{"OMRÅDE", type text}, {"ALDER", type text}, {"TID", type text}, {"KØN", type text}, {"CIVILSTAND", type text}, {"INDHOLD", Int64.Type}}),
    preFilterResult = Table.RenameColumns(r,{{"OMRÅDE", "RegionId"}, {"ALDER", "AgeId"}, {"TID", "QuarterId"}, {"KØN", "SexId"}, {"CIVILSTAND", "MaritalStatusId"}, {"INDHOLD", "Population"}}),
    filterRegion = Table.SelectRows(preFilterResult, each not Text.StartsWith([RegionId], "0")),
    filterAge = Table.SelectRows(filterRegion, each [AgeId] <> "IALT"), 
    filterSex = Table.SelectRows(filterAge, each [SexId] <> "TOT"), 
    filterMarital = Table.SelectRows(filterSex, each [MaritalStatusId] <> "TOT"),
    result = Table.SelectRows(filterMarital, each [Population] >0)
in
    result;


Table.ToNavigationTable = (
    table as table,
    keyColumns as list,
    nameColumn as text,
    dataColumn as text,
    itemKindColumn as text,
    itemNameColumn as text,
    isLeafColumn as text
) as table =>
    let
        tableType = Value.Type(table),
        newTableType = Type.AddTableKey(tableType, keyColumns, true) meta 
        [
            NavigationTable.NameColumn = nameColumn, 
            NavigationTable.DataColumn = dataColumn,
            NavigationTable.ItemKindColumn = itemKindColumn, 
            Preview.DelayColumn = itemNameColumn, 
            NavigationTable.IsLeafColumn = isLeafColumn
        ],
        navigationTable = Value.ReplaceType(table, newTableType)
    in
        navigationTable;


// Data Source Kind description
Danmarks_Statistik = [
    Authentication = [
        // Key = [],
        // UsernamePassword = [],
        // Windows = [],
        Implicit = []
    ],
    Label = Extension.LoadString("DataSourceLabel")
];

// Data Source UI publishing description
Danmarks_Statistik.Publish = [
    Beta = true,
    Category = "Other",
    ButtonText = { Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp") },
    LearnMoreUrl = "https://powerbi.microsoft.com/",
    SourceImage = Danmarks_Statistik.Icons,
    SourceTypeImage = Danmarks_Statistik.Icons
];

Danmarks_Statistik.Icons = [
    Icon16 = { Extension.Contents("Danmarks_Statistik16.png"), Extension.Contents("Danmarks_Statistik20.png"), Extension.Contents("Danmarks_Statistik24.png"), Extension.Contents("Danmarks_Statistik32.png") },
    Icon32 = { Extension.Contents("Danmarks_Statistik32.png"), Extension.Contents("Danmarks_Statistik40.png"), Extension.Contents("Danmarks_Statistik48.png"), Extension.Contents("Danmarks_Statistik64.png") }
];

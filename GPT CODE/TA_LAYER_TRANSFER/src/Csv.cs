using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text;

namespace TaLayerTransfer {
public sealed class Row : Dictionary<string,string> {
    public int Line;
    public Row() : base(StringComparer.OrdinalIgnoreCase) {}
    public string Get(string key) { return TryGetValue(key, out var value) ? value : ""; }
    public Row Put(string key, object value) { this[key] = Convert.ToString(value, CultureInfo.InvariantCulture) ?? ""; return this; }
}
public sealed class Snapshot {
    public readonly List<Row> Rows = new List<Row>();
    public IEnumerable<Row> Of(string record) { return Rows.Where(r => r.Get("Record").Equals(record, StringComparison.OrdinalIgnoreCase)); }
    public Row Meta { get { return Of("META").Single(); } }
    public static readonly string[] Columns = ("Record,Version,SourceDwg,PlotStyleMode,Viewport,Layout,Handle,Layer,Color,Linetype,Lineweight,Transparency,On,Frozen,Locked,Plot,NewVPFreeze,Description,Material,PlotStyle,Hidden,VPFreeze,VPColor,VPLinetype,VPLineweight,VPTransparency,VPPlotStyle,FilterId,ParentId,Order,FilterName,FilterType,Expression").Split(',');
    public Row Add(string kind) { var r = new Row().Put("Record", kind); Rows.Add(r); return r; }
    public void Validate() {
        if (Of("META").Count() != 1 || Meta.Get("Version") != "1") throw new FormatException("Expected one META record with Version=1.");
        if (Meta.Get("PlotStyleMode") != "CTB" && Meta.Get("PlotStyleMode") != "STB") throw new FormatException("META PlotStyleMode must be CTB or STB.");
        var kinds = new HashSet<string>(new[]{"META","LAYER","VIEWPORT","VPLAYER","FILTER","MEMBER"}, StringComparer.OrdinalIgnoreCase);
        foreach (var r in Rows) if (!kinds.Contains(r.Get("Record"))) Fail(r, "Unknown Record: " + r.Get("Record"));
        Unique(Of("LAYER"), "Layer"); Unique(Of("VIEWPORT"), "Viewport"); Unique(Of("FILTER"), "FilterId");
        var layerNames = new HashSet<string>(Of("LAYER").Select(r => r.Get("Layer")), StringComparer.OrdinalIgnoreCase);
        var views = new HashSet<string>(Of("VIEWPORT").Select(r => r.Get("Viewport")), StringComparer.OrdinalIgnoreCase);
        var vpKeys = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        foreach (var r in Of("VPLAYER")) {
            if (!views.Contains(r.Get("Viewport")) || !layerNames.Contains(r.Get("Layer"))) Fail(r, "VPLAYER must reference a VIEWPORT and LAYER record.");
            if (!vpKeys.Add(r.Get("Viewport") + "\0" + r.Get("Layer"))) Fail(r, "Duplicate VPLAYER record.");
        }
        var filters = Of("FILTER").ToDictionary(r => r.Get("FilterId"), StringComparer.OrdinalIgnoreCase);
        var siblingNames = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        foreach (var r in filters.Values) {
            if (r.Get("FilterType") != "GROUP" && r.Get("FilterType") != "PROPERTY") Fail(r, "FilterType must be GROUP or PROPERTY.");
            if (string.IsNullOrWhiteSpace(r.Get("FilterName"))) Fail(r, "FilterName is required.");
            if (!siblingNames.Add(r.Get("ParentId") + "\0" + r.Get("FilterName"))) Fail(r, "Duplicate filter name under the same parent.");
            int order; if (!int.TryParse(r.Get("Order"), out order) || order < 0) Fail(r, "Order must be a nonnegative integer.");
            var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase) {r.Get("FilterId")};
            string parent = r.Get("ParentId");
            while (parent != "") {
                if (!filters.ContainsKey(parent)) Fail(r, "Missing filter parent: " + parent);
                if (!seen.Add(parent)) Fail(r, "Filter hierarchy contains a cycle.");
                parent = filters[parent].Get("ParentId");
            }
        }
        foreach (var r in Of("MEMBER")) {
            if (!filters.TryGetValue(r.Get("FilterId"), out var f) || f.Get("FilterType") != "GROUP") Fail(r, "MEMBER must reference a GROUP filter.");
            if (!layerNames.Contains(r.Get("Layer"))) Fail(r, "MEMBER must reference a LAYER record.");
        }
    }
    static void Unique(IEnumerable<Row> rows, string key) {
        var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        foreach (var r in rows) if (string.IsNullOrWhiteSpace(r.Get(key)) || !seen.Add(r.Get(key))) Fail(r, "Missing or duplicate " + key + ".");
    }
    public static void Fail(Row r, string message) { throw new FormatException("CSV record " + r.Line + ": " + message); }
}
public static class Csv {
    // RFC 4180 quoting; UTF-8 BOM makes Thai names readable in Excel.
    // Also accept semicolon CSV from regional Excel settings, without using the OS locale.
    public static Snapshot Read(string path) {
        string text = File.ReadAllText(path, new UTF8Encoding(false, true)).TrimStart('\uFEFF');
        int end = text.IndexOfAny(new[]{'\r','\n'}); string header = end < 0 ? text : text.Substring(0,end);
        char delimiter = header.Contains(';') && !header.Contains(',') ? ';' : ',';
        var records = Parse(text, delimiter);
        if (records.Count == 0) throw new FormatException("Empty CSV.");
        var cols = records[0].Select(s => s.Trim()).ToArray();
        if (cols.Distinct(StringComparer.OrdinalIgnoreCase).Count() != cols.Length || !cols.Contains("Record", StringComparer.OrdinalIgnoreCase)) throw new FormatException("Invalid/duplicate CSV headers.");
        foreach (var c in cols) if (!Snapshot.Columns.Contains(c, StringComparer.OrdinalIgnoreCase)) throw new FormatException("Unknown column: " + c);
        var result = new Snapshot();
        for (int i=1; i<records.Count; i++) {
            var cells = records[i]; if (cells.All(string.IsNullOrWhiteSpace)) continue;
            if (cells.Count != cols.Length) throw new FormatException("CSV record " + (i+1) + " has " + cells.Count + " cells; expected " + cols.Length + ".");
            var row = new Row {Line=i+1}; for (int j=0;j<cols.Length;j++) row[cols[j]]=cells[j];
            result.Rows.Add(row);
        }
        result.Validate(); return result;
    }
    internal static List<List<string>> Parse(string text, char delimiter) {
        var rows = new List<List<string>>(); var row = new List<string>(); var cell = new StringBuilder();
        bool quoted=false, closed=false, started=false;
        for (int i=0;i<text.Length;i++) {
            char c=text[i];
            if (quoted) {
                if (c=='"') { if (i+1<text.Length && text[i+1]=='"') {cell.Append('"');i++;} else {quoted=false;closed=true;} }
                else cell.Append(c);
                continue;
            }
            if (c==delimiter || c=='\r' || c=='\n') {
                row.Add(cell.ToString()); cell.Clear(); closed=false;started=false;
                if(c!=delimiter) {rows.Add(row);row=new List<string>();if(c=='\r' && i+1<text.Length && text[i+1]=='\n') i++;}
            } else {
                if(closed) throw new FormatException("Unexpected character after a closing CSV quote.");
                if(c=='"') {if(started) throw new FormatException("Quote inside an unquoted CSV cell.");quoted=true;started=true;}
                else {cell.Append(c);started=true;}
            }
        }
        if(quoted) throw new FormatException("Unclosed CSV quote.");
        if(started || closed || row.Count>0) {row.Add(cell.ToString()); rows.Add(row);} return rows;
    }
    public static void Write(string path, Snapshot snapshot) {
        snapshot.Validate();
        string temp=path+"."+Guid.NewGuid().ToString("N")+".tmp";
        try {
            using(var writer=new StreamWriter(temp,false,new UTF8Encoding(true))) {
                writer.WriteLine(string.Join(",",Snapshot.Columns));
                foreach(var row in snapshot.Rows) writer.WriteLine(string.Join(",",Snapshot.Columns.Select(c=>Quote(row.Get(c)))));
            }
            File.Move(temp,path,true);
        } finally {if(File.Exists(temp)) File.Delete(temp);}
    }
    static string Quote(string s) {return "\""+s.Replace("\"","\"\"")+"\"";}
}
}

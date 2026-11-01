using System;
using System.IO;
using System.Linq;
using System.Collections.Generic;
using System.Reflection;
using System.Text.Json;
using System.Text.RegularExpressions;
using System.Security.Cryptography;
using System.Text;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Colors;
using Autodesk.AutoCAD.Runtime;
using Autodesk.AutoCAD.ApplicationServices.Core;
[assembly: System.Runtime.Versioning.TargetFramework(".NETCoreApp,Version=v8.0")]
[assembly: CommandClass(typeof(WhiteNoExplode))]

public class WhiteNoExplode
{
    static string Root = @"C:\TA\TA_COMPELETE\output\dwg_white_noexplode_20261030";
    [CommandMethod("TAWHITEDIAG",CommandFlags.Session)]
    public void Diagnose() {
        var types=new[]{typeof(MlineStyle),typeof(MlineStyleElement),typeof(GradientColor)};
        File.WriteAllLines(Path.Combine(Root,"extra_api.txt"),types.SelectMany(t=>new[]{"TYPE "+t.FullName}.Concat(t.GetProperties().Select(p=>p.ToString())).Concat(t.GetMethods().Where(m=>!m.IsSpecialName).Select(m=>m.ToString()))));
        var j=JsonSerializer.Deserialize<Job[]>(File.ReadAllText(Path.Combine(Root,"manifest.json")))[0];
        var all=new List<Dictionary<string,Dictionary<string,string>>>();
        foreach(var p in new[]{j.Source,j.Output}) using(var db=new Database(false,true)) {
            db.ReadDwgFile(p,FileOpenMode.OpenForReadAndAllShare,true,"");db.CloseInput(true);
            var info=new Dictionary<string,Dictionary<string,string>>();
            using(var tr=db.TransactionManager.StartTransaction()) foreach(ObjectId bid in (BlockTable)tr.GetObject(db.BlockTableId,OpenMode.ForRead)) {
                var b=(BlockTableRecord)tr.GetObject(bid,OpenMode.ForRead);var ent=new Dictionary<string,string>();
                foreach(ObjectId eid in b) {var e=tr.GetObject(eid,OpenMode.ForRead) as Entity;if(e!=null)ent[e.Handle.ToString()]=e.GetType().Name;}
                info[b.Name]=ent;
            }
            all.Add(info);
        }
        var diff=new List<object>();
        foreach(var b in all[0]) if(!b.Value.Keys.OrderBy(x=>x).SequenceEqual(all[1][b.Key].Keys.OrderBy(x=>x)))diff.Add(new{block=b.Key,before=b.Value.Count,after=all[1][b.Key].Count,removed=b.Value.Where(x=>!all[1][b.Key].ContainsKey(x.Key)),added=all[1][b.Key].Where(x=>!b.Value.ContainsKey(x.Key))});
        File.WriteAllText(Path.Combine(Root,"geometry_diff.json"),JsonSerializer.Serialize(diff));
    }
    static Color White = Color.FromColorIndex(ColorMethod.ByAci,7);
    static Regex InlineColor = new Regex(@"(?<!\\)((?:\\\\)*)\\[Cc][^;\\{}]*;",RegexOptions.Compiled);
    public class Job { public string Source {get;set;} public string Output {get;set;} }
    public class Stats {
        public int Blocks {get;set;} public int Entities {get;set;} public int Attributes {get;set;}
        public int Vertices {get;set;} public int Layers {get;set;} public int Dimstyles {get;set;}
        public int Explodable {get;set;} public int NonWhite {get;set;} public int InlineColors {get;set;}
        public int StableEntities {get;set;}
        public string StableHandleHash {get;set;}
        public int StableBlocks {get;set;}
        public Dictionary<string,string> StableEntityOwners {get;set;} = new Dictionary<string,string>();
        public List<string> Issues {get;set;} = new List<string>();
        public List<string> Embedded {get;set;} = new List<string>();
        public Dictionary<string,int> Classes {get;set;} = new Dictionary<string,int>();
        public Dictionary<string,int> BlockEntityCounts {get;set;} = new Dictionary<string,int>();
    }
    static string Clean(string s) {return string.IsNullOrEmpty(s)?s:InlineColor.Replace(s,"$1");}
    static bool IsWhite(Color c) {return c.ColorMethod==ColorMethod.ByAci && c.ColorIndex==7;}
    static void ColorCheck(Color c,Stats s) { if(!IsWhite(c)) s.NonWhite++; }
    static void DimColors(Dimension d) {if(!IsWhite(d.Dimclrd))d.Dimclrd=White;if(!IsWhite(d.Dimclre))d.Dimclre=White;if(!IsWhite(d.Dimclrt))d.Dimclrt=White;}
    static void TextCheck(string t,Stats s) {if(!string.IsNullOrEmpty(t)) s.InlineColors+=InlineColor.Matches(t).Count;}
    static void EntityPass(Entity e, Transaction tr, Stats s, bool change)
    {
        s.Entities++; var n=e.GetType().Name; s.Classes[n]=s.Classes.TryGetValue(n,out var count)?count+1:1;
        if(change) {if(!IsWhite(e.Color))e.Color=White;} else {ColorCheck(e.Color,s);if(!IsWhite(e.Color) && s.Issues.Count<35)s.Issues.Add(e.Handle+":"+n+":owner="+((BlockTableRecord)tr.GetObject(e.OwnerId,OpenMode.ForRead)).Name+":color="+e.Color.ColorIndex);}
        if((e is RasterImage && !(e is Wipeout)) || e is Ole2Frame || n=="ImpEntity") s.Embedded.Add(e.Handle+":"+n);
        if(e is MText mt) {if(change) {var t=Clean(mt.Contents);if(t!=mt.Contents)mt.Contents=t;} else TextCheck(mt.Contents,s);}
        if(e is AttributeDefinition ad && ad.IsMTextAttributeDefinition) using(var text=ad.MTextAttributeDefinition) {
            if(change) {var t=Clean(text.Contents);if(!IsWhite(text.Color)||t!=text.Contents){text.Color=White;text.Contents=t;ad.MTextAttributeDefinition=text;}}
            else {ColorCheck(text.Color,s);TextCheck(text.Contents,s);}
        }
        if(e is Dimension dim) {
            if(change) {DimColors(dim);var t=Clean(dim.DimensionText);if(t!=dim.DimensionText)dim.DimensionText=t;}
            else {ColorCheck(dim.Dimclrd,s);ColorCheck(dim.Dimclre,s);ColorCheck(dim.Dimclrt,s);TextCheck(dim.DimensionText,s);}
        }
        if(e is Leader ld) {if(change){if(!IsWhite(ld.Dimclrd))ld.Dimclrd=White;}else ColorCheck(ld.Dimclrd,s);}
        if(e is BlockReference br) foreach(ObjectId aid in br.AttributeCollection) {
            var a=(AttributeReference)tr.GetObject(aid,change?OpenMode.ForWrite:OpenMode.ForRead,false,true);s.Attributes++;
            if(change) {if(!IsWhite(a.Color))a.Color=White;} else ColorCheck(a.Color,s);
            if(a.IsMTextAttribute) using(var text=a.MTextAttribute) {
                if(change) {var t=Clean(text.Contents);if(!IsWhite(text.Color)||t!=text.Contents){text.Color=White;text.Contents=t;a.MTextAttribute=text;}}
                else {ColorCheck(text.Color,s);TextCheck(text.Contents,s);}
            }
        }
        if(e is Polyline2d p2) foreach(ObjectId vid in p2) {
            var v=(Entity)tr.GetObject(vid,change?OpenMode.ForWrite:OpenMode.ForRead,false,true);s.Vertices++;if(change)v.Color=White;else ColorCheck(v.Color,s);
        }
        if(e is Polyline3d p3) foreach(ObjectId vid in p3) {
            var v=(Entity)tr.GetObject(vid,change?OpenMode.ForWrite:OpenMode.ForRead,false,true);s.Vertices++;if(change)v.Color=White;else ColorCheck(v.Color,s);
        }
        if(e is Hatch h && !h.IsSolidFill && h.HatchObjectType==HatchObjectType.GradientObject) {
            var cols=h.GetGradientColors();
            for(int i=0;i<cols.Length;i++) { if(change)cols[i]=new GradientColor(White,cols[i].get_Value());else ColorCheck(cols[i].get_Color(),s); }
            if(change)h.SetGradientColors(cols);
        }
        if(e is Hatch bh) {var bg=bh.BackgroundColor;if(bg.ColorMethod.ToString()!="None" && bg.ColorIndex!=257) {if(change){if(!IsWhite(bg))bh.BackgroundColor=White;}else ColorCheck(bg,s);}}
    }
    static Stats Scan(Database db,bool change)
    {
        var s=new Stats();
        using(var tr=db.TransactionManager.StartTransaction()) {
            var bt=(BlockTable)tr.GetObject(db.BlockTableId,OpenMode.ForRead);
            var viewports=new List<ObjectId>();
            var generated=new HashSet<ObjectId>();var stableHandles=new List<string>();
            foreach(ObjectId bid in bt) foreach(ObjectId eid in (BlockTableRecord)tr.GetObject(bid,OpenMode.ForRead)) {
                if(eid.ObjectClass.IsDerivedFrom(RXObject.GetClass(typeof(Dimension)))) {var d=(Dimension)tr.GetObject(eid,OpenMode.ForRead);if(!d.DimBlockId.IsNull)generated.Add(d.DimBlockId);}
            }
            foreach(ObjectId bid in bt) {
                var b=(BlockTableRecord)tr.GetObject(bid,change?OpenMode.ForWrite:OpenMode.ForRead,false,true);s.Blocks++;
                bool isGenerated=generated.Contains(bid)||b.Name.StartsWith("*D",StringComparison.OrdinalIgnoreCase);
                if(!isGenerated)s.StableBlocks++;
                var startCount=s.Entities;
                if(b.IsFromExternalReference || b.IsFromOverlayReference) throw new InvalidOperationException("Unexpected Xref: "+b.Name);
                if(!b.IsLayout) { if(change){if(b.Explodable)b.Explodable=false;}else if(b.Explodable){s.Explodable++;if(s.Issues.Count<35)s.Issues.Add("EXPLODABLE "+b.Name);} }
                foreach(ObjectId eid in b) {
                    var e=tr.GetObject(eid,change?OpenMode.ForWrite:OpenMode.ForRead,false,true) as Entity;
                    if(e==null)continue;
                    if(!isGenerated){s.StableEntities++;stableHandles.Add(e.Handle+":"+e.GetType().Name+":"+bid.Handle);s.StableEntityOwners[e.Handle.ToString()]=b.Name+":"+e.GetType().Name;}
                    if(e is Viewport) viewports.Add(eid);
                    EntityPass(e,tr,s,change);
                }
                s.BlockEntityCounts[b.Name]=s.Entities-startCount;
            }
            var lt=(LayerTable)tr.GetObject(db.LayerTableId,OpenMode.ForRead);
            foreach(ObjectId lid in lt) {
                var l=(LayerTableRecord)tr.GetObject(lid,change?OpenMode.ForWrite:OpenMode.ForRead,false,true);s.Layers++;
                if(change){if(!IsWhite(l.Color))l.Color=White;}else ColorCheck(l.Color,s);
                if(l.HasOverrides) foreach(var vp in viewports) {
                    if(!l.HasViewportOverrides(vp))continue;
                    var ov=l.GetViewportOverrides(vp);
                    if(ov.IsColorOverridden) {if(change)ov.Color=White;else ColorCheck(ov.Color,s);}
                }
            }
            var dt=(DimStyleTable)tr.GetObject(db.DimStyleTableId,OpenMode.ForRead);
            foreach(ObjectId did in dt) {
                var d=(DimStyleTableRecord)tr.GetObject(did,change?OpenMode.ForWrite:OpenMode.ForRead);s.Dimstyles++;
                if(change) {if(!IsWhite(d.Dimclrd))d.Dimclrd=White;if(!IsWhite(d.Dimclre))d.Dimclre=White;if(!IsWhite(d.Dimclrt))d.Dimclrt=White;}
                else {ColorCheck(d.Dimclrd,s);ColorCheck(d.Dimclre,s);ColorCheck(d.Dimclrt,s);}
            }
            var md=(DBDictionary)tr.GetObject(db.MLStyleDictionaryId,OpenMode.ForRead);
            foreach(DBDictionaryEntry entry in md) {
                var style=(MlineStyle)tr.GetObject(entry.Value,change?OpenMode.ForWrite:OpenMode.ForRead);
                for(int i=0;i<style.Elements.Count;i++) {var el=style.Elements[i];if(change){if(!IsWhite(el.Color))style.Elements[i]=new MlineStyleElement(el.Offset,White,el.LinetypeId);}else ColorCheck(el.Color,s);}
                if(style.Filled){if(change){if(!IsWhite(style.FillColor))style.FillColor=White;}else ColorCheck(style.FillColor,s);}
            }
            if(change) {if(!IsWhite(db.Cecolor))db.Cecolor=White;if(!IsWhite(db.Dimclrd))db.Dimclrd=White;if(!IsWhite(db.Dimclre))db.Dimclre=White;if(!IsWhite(db.Dimclrt))db.Dimclrt=White;}
            stableHandles.Sort(StringComparer.Ordinal);s.StableHandleHash=Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(string.Join("\n",stableHandles))));
            tr.Commit();
        }
        return s;
    }
    [CommandMethod("TAWHITEAPPLY",CommandFlags.Session)]
    public void Apply()
    {
        foreach(var job in JsonSerializer.Deserialize<Job[]>(File.ReadAllText(Path.Combine(Root,"manifest.json")))) {
            try {
                Stats before,after;
                var previous=HostApplicationServices.WorkingDatabase;
                using(var db=new Database(false,true)) {
                    db.ReadDwgFile(job.Source,FileOpenMode.OpenForReadAndAllShare,true,"");db.CloseInput(true);
                    try {HostApplicationServices.WorkingDatabase=db;before=Scan(db,true);Scan(db,true);Directory.CreateDirectory(Path.GetDirectoryName(job.Output));db.SaveAs(job.Output,db.OriginalFileVersion);}
                    finally {HostApplicationServices.WorkingDatabase=previous;}
                }
                for(int attempt=0;;attempt++) using(var db=new Database(false,true)) {
                    db.ReadDwgFile(job.Output,FileOpenMode.OpenForReadAndAllShare,true,"");db.CloseInput(true);
                    try {HostApplicationServices.WorkingDatabase=db;after=Scan(db,false);if(after.NonWhite==0 && after.Explodable==0 && after.InlineColors==0)break;if(attempt>=3)break;Scan(db,true);db.SaveAs(job.Output,db.OriginalFileVersion);}
                    finally {HostApplicationServices.WorkingDatabase=previous;}
                }
                if(after.NonWhite!=0 || after.Explodable!=0 || after.InlineColors!=0)throw new InvalidOperationException("Verification failed "+JsonSerializer.Serialize(new{after.NonWhite,after.Explodable,after.InlineColors,after.Issues}));
                if(before.StableEntities!=after.StableEntities || before.StableHandleHash!=after.StableHandleHash || before.StableBlocks!=after.StableBlocks || before.Attributes!=after.Attributes || before.Vertices!=after.Vertices || before.Layers!=after.Layers || before.Dimstyles!=after.Dimstyles)throw new InvalidOperationException("Object structure changed "+JsonSerializer.Serialize(new{before.StableEntities,afterStableEntities=after.StableEntities,before.StableBlocks,afterStableBlocks=after.StableBlocks,removed=before.StableEntityOwners.Where(x=>!after.StableEntityOwners.ContainsKey(x.Key)).GroupBy(x=>x.Value).Select(g=>new{owner=g.Key,count=g.Count()}),added=after.StableEntityOwners.Where(x=>!before.StableEntityOwners.ContainsKey(x.Key)).GroupBy(x=>x.Value).Select(g=>new{owner=g.Key,count=g.Count()})}));
                before.StableEntityOwners.Clear();after.StableEntityOwners.Clear();before.BlockEntityCounts.Clear();after.BlockEntityCounts.Clear();
                File.AppendAllText(Path.Combine(Root,"results.jsonl"),JsonSerializer.Serialize(new{job.Source,job.Output,status="PASS",before,after})+Environment.NewLine);
                Application.DocumentManager.MdiActiveDocument.Editor.WriteMessage("\nPASS "+Path.GetFileName(job.Source)+"\n");
            } catch(System.Exception ex) {
                File.AppendAllText(Path.Combine(Root,"results.jsonl"),JsonSerializer.Serialize(new{job.Source,job.Output,status="FAIL",error=ex.ToString()})+Environment.NewLine);
                Application.DocumentManager.MdiActiveDocument.Editor.WriteMessage("\nFAIL "+Path.GetFileName(job.Source)+" "+ex.Message+"\n");
                break;
            }
        }
        System.Environment.Exit(0);
    }
    [CommandMethod("TAWHITEFINALCHECK",CommandFlags.Session)]
    public void FinalCheck() {
        foreach(var line in File.ReadAllLines(Path.Combine(Root,"results.jsonl"))) {
            using(var result=JsonDocument.Parse(line)) {
                var r=result.RootElement;if(r.GetProperty("status").GetString()!="PASS")throw new InvalidOperationException("Unverified base output");
                var source=r.GetProperty("Source").GetString();var path=r.GetProperty("Output").GetString();
                var baseline=JsonSerializer.Deserialize<Stats>(r.GetProperty("before").GetRawText());Stats after=null;bool corrected=false;
                for(int attempt=0;attempt<4;attempt++)using(var db=new Database(false,true)) {
                    db.ReadDwgFile(path,FileOpenMode.OpenForReadAndAllShare,true,"");db.CloseInput(true);
                    var previous=HostApplicationServices.WorkingDatabase;
                    try {
                        HostApplicationServices.WorkingDatabase=db;after=Scan(db,false);
                        if(after.NonWhite==0 && after.Explodable==0 && after.InlineColors==0)break;
                        corrected=true;Scan(db,true);db.SaveAs(path,db.OriginalFileVersion);
                    }finally{HostApplicationServices.WorkingDatabase=previous;}
                }
                if(after.NonWhite!=0 || after.Explodable!=0 || after.InlineColors!=0 || baseline.StableHandleHash!=after.StableHandleHash)throw new InvalidOperationException("Final verification failed "+path);
                after.StableEntityOwners.Clear();after.BlockEntityCounts.Clear();
                File.AppendAllText(Path.Combine(Root,"final_verified.jsonl"),JsonSerializer.Serialize(new{Source=source,Output=path,status="PASS",corrected,before=baseline,after})+Environment.NewLine);
                Application.DocumentManager.MdiActiveDocument.Editor.WriteMessage("\nFINAL PASS "+Path.GetFileName(path)+"\n");
            }
        }
        System.Environment.Exit(0);
    }
    [CommandMethod("TAWHITEPROBE", CommandFlags.Session)]
    public void Probe()
    {
        var types = new[]{typeof(Entity),typeof(BlockTableRecord),typeof(MLeader),typeof(Table),typeof(Cell),typeof(LayerTableRecord),typeof(LayerViewportProperties),typeof(AttributeReference),typeof(Dimension)};
        File.WriteAllLines(Path.Combine(Root,"probe.txt"), types.SelectMany(t=>new[]{"TYPE "+t.FullName}.Concat(t.GetProperties().Select(p=>p.PropertyType.Name+" "+p.Name+" write="+p.CanWrite)).Concat(t.GetMethods().Where(m=>!m.IsSpecialName).Select(m=>m.ToString()))));
        foreach(var source in File.ReadAllLines(Path.Combine(Root,"sources.txt")))
        {
            using(var db=new Database(false,true))
            {
                db.ReadDwgFile(source,FileOpenMode.OpenForReadAndAllShare,true,""); db.CloseInput(true);
                using(var tr=db.TransactionManager.StartTransaction())
                {
                    var bt=(BlockTable)tr.GetObject(db.BlockTableId,OpenMode.ForRead);
                    int blocks=0, ents=0, explodable=0; var classes=new Dictionary<string,int>(); var xrefs=new List<string>();
                    foreach(ObjectId id in bt) {
                        var b=(BlockTableRecord)tr.GetObject(id,OpenMode.ForRead); blocks++; if(b.Explodable) explodable++;
                        if(b.IsFromExternalReference || b.IsFromOverlayReference) xrefs.Add(b.Name+"="+b.PathName);
                        foreach(ObjectId eid in b) { var e=tr.GetObject(eid,OpenMode.ForRead) as Entity; if(e==null)continue; ents++; string n=e.GetType().Name; classes[n]=classes.ContainsKey(n)?classes[n]+1:1; }
                    }
                    var info=new{source,blocks,ents,explodable,xrefs,classes};
                    File.AppendAllText(Path.Combine(Root,"audit.jsonl"),JsonSerializer.Serialize(info)+Environment.NewLine);
                    Application.DocumentManager.MdiActiveDocument.Editor.WriteMessage("\nAUDITED "+Path.GetFileName(source)+" "+ents+" entities\n");
                }
            }
        }
    }
}

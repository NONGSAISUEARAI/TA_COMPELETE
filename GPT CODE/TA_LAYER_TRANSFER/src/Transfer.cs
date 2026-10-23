using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using Autodesk.AutoCAD.Colors;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.LayerManager;

namespace TaLayerTransfer {
public enum ImportScope { Viewport, Drawing, Both }
public enum FilterMode { Skip, Merge, Replace }
public sealed class ImportOptions {
    public ImportScope Scope = ImportScope.Viewport;
    public bool CreateMissing = true, Overwrite = true;
    public FilterMode Filters = FilterMode.Skip;
    public readonly Dictionary<string,List<ObjectId>> Viewports = new Dictionary<string,List<ObjectId>>(StringComparer.OrdinalIgnoreCase);
}
public sealed class TransferReport {
    public int Created, Updated, VpRows, Filters;
    public readonly List<string> Notes = new List<string>();
    public override string ToString() { return $"Created {Created} layers; updated {Updated} layer records; applied {VpRows} VP layer records; imported {Filters} filters."; }
}
public static class Values {
    static readonly CultureInfo Inv = CultureInfo.InvariantCulture;
    public static string Bit(bool b) {return b?"1":"0";}
    public static bool Bool(string s) {if(s=="1")return true;if(s=="0")return false;throw new FormatException("Expected 0 or 1, got: "+s);}
    public static string ColorText(Color c) {
        if(c.HasBookName) return "BOOK:"+c.DictionaryKey;
        if(c.IsByAci) return "ACI:"+c.ColorIndex;
        if(c.IsByColor) return $"RGB:{c.Red}:{c.Green}:{c.Blue}";
        throw new FormatException("Unsupported layer color: "+c.ColorMethod);
    }
    public static Color ColorValue(string s) {
        if(s.StartsWith("BOOK:",StringComparison.OrdinalIgnoreCase)) return Color.FromDictionaryName(s.Substring(5));
        string[] p=s.Split(':');
        if(p.Length==4 && p[0].Equals("RGB",StringComparison.OrdinalIgnoreCase)) return Color.FromRgb(byte.Parse(p[1]),byte.Parse(p[2]),byte.Parse(p[3]));
        string number=p.Length==2 && p[0].Equals("ACI",StringComparison.OrdinalIgnoreCase)?p[1]:s;
        short index=short.Parse(number,Inv); if(index<1 || index>255) throw new FormatException("ACI must be 1..255.");
        return Color.FromColorIndex(ColorMethod.ByAci,index);
    }
    public static string TransparencyText(Transparency t) {
        if(t.IsByLayer)return "BYLAYER"; if(t.IsByBlock)return "BYBLOCK";
        if(!t.IsByAlpha)throw new FormatException("Invalid layer transparency.");
        return ((255-t.Alpha)*100.0/255).ToString("0.######",Inv);
    }
    public static Transparency TransparencyValue(string s) {
        if(s.Equals("BYLAYER",StringComparison.OrdinalIgnoreCase))return new Transparency(TransparencyMethod.ByLayer);
        if(s.Equals("BYBLOCK",StringComparison.OrdinalIgnoreCase))return new Transparency(TransparencyMethod.ByBlock);
        double percent=double.Parse(s,Inv);
        if(double.IsNaN(percent)||double.IsInfinity(percent)||percent<0||percent>100)throw new FormatException("Transparency must be 0..100.");
        return new Transparency((byte)Math.Round(255*(1-percent/100)));
    }
    public static string WeightText(LineWeight w) {return w==LineWeight.ByLineWeightDefault?"DEFAULT":((int)w/100.0).ToString("0.00",Inv);}
    public static LineWeight WeightValue(string s) {
        if(s.Equals("DEFAULT",StringComparison.OrdinalIgnoreCase))return LineWeight.ByLineWeightDefault;
        decimal value=decimal.Parse(s,Inv)*100;
        if(value!=decimal.Truncate(value)||value<0||value>211||!Enum.IsDefined(typeof(LineWeight),(int)value))throw new FormatException("Unsupported lineweight in mm: "+s);
        return (LineWeight)(int)value;
    }
    public static bool Inherit(string s) {return s.Equals("INHERIT",StringComparison.OrdinalIgnoreCase);}
}
public static class Transfer {
    static string Name(Transaction tr,ObjectId id) {return id.IsNull?"":((SymbolTableRecord)tr.GetObject(id,OpenMode.ForRead)).Name;}
    static string MaterialName(Transaction tr,ObjectId id) {return id.IsNull?"":((Material)tr.GetObject(id,OpenMode.ForRead)).Name;}
    public static List<ObjectId> AllViewports(Database db,Transaction tr) {
        var ids=new List<ObjectId>();
        foreach(DBDictionaryEntry entry in (DBDictionary)tr.GetObject(db.LayoutDictionaryId,OpenMode.ForRead)) {
            var layout=(Layout)tr.GetObject(entry.Value,OpenMode.ForRead); if(layout.ModelType)continue;
            foreach(ObjectId id in (BlockTableRecord)tr.GetObject(layout.BlockTableRecordId,OpenMode.ForRead))
                if(tr.GetObject(id,OpenMode.ForRead) is Viewport vp && vp.Number!=1)ids.Add(id);
        }
        return ids;
    }
    public static Snapshot Capture(Database db,IEnumerable<ObjectId> vpIds,TransferReport report) {
        var s=new Snapshot();s.Add("META").Put("Version",1).Put("SourceDwg",db.Filename).Put("PlotStyleMode",db.PlotStyleMode?"CTB":"STB");
        using(var tr=db.TransactionManager.StartTransaction()) {
            var layers=new List<LayerTableRecord>();
            foreach(ObjectId id in (LayerTable)tr.GetObject(db.LayerTableId,OpenMode.ForRead))layers.Add((LayerTableRecord)tr.GetObject(id,OpenMode.ForRead));
            foreach(var l in layers.OrderBy(l=>l.Name,StringComparer.OrdinalIgnoreCase)) {
                s.Add("LAYER").Put("Layer",l.Name).Put("Color",Values.ColorText(l.Color)).Put("Linetype",Name(tr,l.LinetypeObjectId))
                .Put("Lineweight",Values.WeightText(l.LineWeight)).Put("Transparency",Values.TransparencyText(l.Transparency))
                .Put("On",Values.Bit(!l.IsOff)).Put("Frozen",Values.Bit(l.IsFrozen)).Put("Locked",Values.Bit(l.IsLocked))
                .Put("Plot",Values.Bit(l.IsPlottable)).Put("NewVPFreeze",Values.Bit(l.ViewportVisibilityDefault)).Put("Description",l.Description)
                .Put("Material",MaterialName(tr,l.MaterialId)).Put("PlotStyle",db.PlotStyleMode?"":l.PlotStyleName).Put("Hidden",Values.Bit(l.IsHidden));
            }
            int index=0;
            foreach(var id in vpIds.Distinct()) {
                var vp=(Viewport)tr.GetObject(id,OpenMode.ForRead);if(vp.Number==1)throw new InvalidOperationException("Paper-space viewport #1 cannot be exported.");
                var owner=(BlockTableRecord)tr.GetObject(vp.OwnerId,OpenMode.ForRead);var layout=(Layout)tr.GetObject(owner.LayoutId,OpenMode.ForRead);
                string key="VP"+(++index);
                s.Add("VIEWPORT").Put("Viewport",key).Put("Layout",layout.LayoutName).Put("Handle",vp.Handle.ToString());
                var frozen=new HashSet<ObjectId>(vp.GetFrozenLayers().Cast<ObjectId>());
                foreach(var l in layers.OrderBy(l=>l.Name,StringComparer.OrdinalIgnoreCase)) {
                    var p=l.GetViewportOverrides(id);
                    s.Add("VPLAYER").Put("Viewport",key).Put("Layer",l.Name).Put("VPFreeze",Values.Bit(frozen.Contains(l.ObjectId)))
                    .Put("VPColor",p.IsColorOverridden?Values.ColorText(p.Color):"INHERIT")
                    .Put("VPLinetype",p.IsLinetypeOverridden?Name(tr,p.LinetypeObjectId):"INHERIT")
                    .Put("VPLineweight",p.IsLineWeightOverridden?Values.WeightText(p.LineWeight):"INHERIT")
                    .Put("VPTransparency",p.IsTransparencyOverridden?Values.TransparencyText(p.Transparency):"INHERIT")
                    .Put("VPPlotStyle",p.IsPlotStyleOverridden?p.PlotStyleName:"INHERIT");
                }
            }
            int filterIndex=0;CaptureFilters(db.LayerFilters.Root,"",s,tr,report,ref filterIndex);
            tr.Commit();
        }
        int line=2;foreach(var row in s.Rows)row.Line=line++;
        s.Validate();return s;
    }
    static void CaptureFilters(LayerFilter parent,string parentId,Snapshot s,Transaction tr,TransferReport report,ref int index) {
        int order=0;
        foreach(LayerFilter f in parent.NestedFilters) {
            if(f.DynamicallyGenerated||!f.AllowDelete||f.IsProxy) {report.Notes.Add("System/dynamic/proxy filter omitted: "+f.Name);continue;}
            string id="F"+(++index);
            s.Add("FILTER").Put("FilterId",id).Put("ParentId",parentId).Put("Order",order++).Put("FilterName",f.Name)
              .Put("FilterType",f is LayerGroup?"GROUP":"PROPERTY").Put("Expression",f is LayerGroup?"":f.FilterExpression);
            if(f is LayerGroup group)foreach(ObjectId layer in group.LayerIds) if(!layer.IsErased)s.Add("MEMBER").Put("FilterId",id).Put("Layer",Name(tr,layer));
            CaptureFilters(f,id,s,tr,report,ref index);
        }
    }
    // Check every value before changing the database, including rows not selected for import.
    public static void ValidateValues(Snapshot s) {
        s.Validate();
        foreach(var r in s.Rows) {
            try {
                foreach(var key in new[]{"On","Frozen","Locked","Plot","NewVPFreeze","Hidden","VPFreeze"})if(r.Get(key)!="")Values.Bool(r.Get(key));
                foreach(var key in new[]{"Color","VPColor"})if(r.Get(key)!=""&&!(key.StartsWith("VP")&&Values.Inherit(r.Get(key))))using(var c=Values.ColorValue(r.Get(key))){}
                foreach(var key in new[]{"Lineweight","VPLineweight"})if(r.Get(key)!=""&&!(key.StartsWith("VP")&&Values.Inherit(r.Get(key))))Values.WeightValue(r.Get(key));
                foreach(var key in new[]{"Transparency","VPTransparency"})if(r.Get(key)!=""&&!(key.StartsWith("VP")&&Values.Inherit(r.Get(key))))Values.TransparencyValue(r.Get(key));
                if(r.Get("Record").Equals("LAYER",StringComparison.OrdinalIgnoreCase)&&!r.Get("Layer").Contains('|'))SymbolUtilityServices.ValidateSymbolName(r.Get("Layer"),false);
            }catch(System.Exception ex){Snapshot.Fail(r,ex.Message);}
        }
    }
    public static TransferReport Apply(Database db,Snapshot s,ImportOptions options) {
        ValidateValues(s);var report=new TransferReport();
        if(!db.UndoRecording)throw new InvalidOperationException("Enable UNDO recording before importing (UNDO > Control > All). No settings changed.");
        bool global=options.Scope!=ImportScope.Viewport, viewport=options.Scope!=ImportScope.Drawing;
        if(!global&&options.Filters!=FilterMode.Skip)throw new InvalidOperationException("Viewport-only mode cannot change drawing-wide layer filters.");
        using(var tr=db.TransactionManager.StartTransaction()) {
            var layerTable=(LayerTable)tr.GetObject(db.LayerTableId,OpenMode.ForRead);
            var layers=new Dictionary<string,ObjectId>(StringComparer.OrdinalIgnoreCase);
            var apply=new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            var created=new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            var sourceNames=new HashSet<string>(s.Of("VIEWPORT").Select(r=>r.Get("Viewport")),StringComparer.OrdinalIgnoreCase);
            var targets=new HashSet<ObjectId>();
            if(viewport)foreach(var pair in options.Viewports) {
                if(!sourceNames.Contains(pair.Key))throw new InvalidOperationException("Unknown source viewport: "+pair.Key);
                foreach(var id in pair.Value) {
                    if(!targets.Add(id))throw new InvalidOperationException("A destination viewport can only receive one source snapshot per import.");
                    if(id.Database!=db||!(tr.GetObject(id,OpenMode.ForRead) is Viewport vp)||vp.Number==1)throw new InvalidOperationException("Invalid destination viewport.");
                }
            }
            if(viewport&&targets.Count==0)throw new InvalidOperationException("Select at least one destination viewport.");
            foreach(var row in s.Of("LAYER")) {
                string name=row.Get("Layer");bool exists=layerTable.Has(name);
                if(!exists) {
                    if(!options.CreateMissing){report.Notes.Add("Missing layer skipped: "+name);continue;}
                    if(name.Contains('|')){report.Notes.Add("Xref-dependent layer cannot be created: "+name);continue;}
                    if(!layerTable.IsWriteEnabled)layerTable.UpgradeOpen();
                    var layer=new LayerTableRecord{Name=name};layerTable.Add(layer);tr.AddNewlyCreatedDBObject(layer,true);
                    layers[name]=layer.ObjectId;created.Add(name);apply.Add(name);report.Created++;
                } else {layers[name]=layerTable[name];if(options.Overwrite)apply.Add(name);else report.Notes.Add("Existing layer kept: "+name);}
            }
            // Dependencies are resolved by name, never by source ObjectId/handle.
            using(var resources=new Resources(db,tr,s.Meta.Get("SourceDwg"))) {
                foreach(var row in s.Of("LAYER")) {
                    string name=row.Get("Layer");if(!apply.Contains(name)||(!global&&!created.Contains(name)))continue;
                    var layer=(LayerTableRecord)tr.GetObject(layers[name],OpenMode.ForWrite);
                    if(layer.IsDependent){report.Notes.Add("Global settings of Xref layer kept: "+name);continue;}
                    try {ApplyGlobal(db,layer,row,resources,report);report.Updated++;}catch(System.Exception ex){throw new FormatException("CSV record "+row.Line+" ("+name+"): "+ex.Message,ex);}
                }
                if(viewport)foreach(var row in s.Of("VPLAYER")) {
                    if(!apply.Contains(row.Get("Layer"))||!options.Viewports.TryGetValue(row.Get("Viewport"),out var ids))continue;
                    var layer=(LayerTableRecord)tr.GetObject(layers[row.Get("Layer")],OpenMode.ForWrite);
                    foreach(var vpId in ids)try {
                        var vp=(Viewport)tr.GetObject(vpId,OpenMode.ForWrite);
                        ApplyViewport(db,layer,vp,row,resources,report);report.VpRows++;
                    }catch(System.Exception ex){throw new FormatException("CSV record "+row.Line+" ("+row.Get("Layer")+"): "+ex.Message,ex);}
                }
            }
            if(options.Filters!=FilterMode.Skip)ApplyFilters(db,s,layers,options.Filters,report);
            tr.Commit();
        }
        return report;
    }
    static void ApplyGlobal(Database db,LayerTableRecord l,Row r,Resources resources,TransferReport report) {
        if(r.Get("Color")!="")using(var c=Values.ColorValue(r.Get("Color")))l.Color=c;
        if(r.Get("Linetype")!="")l.LinetypeObjectId=resources.Linetype(r.Get("Linetype"));
        if(r.Get("Lineweight")!="")l.LineWeight=Values.WeightValue(r.Get("Lineweight"));
        if(r.Get("Transparency")!="")l.Transparency=Values.TransparencyValue(r.Get("Transparency"));
        if(r.Get("On")!="")l.IsOff=!Values.Bool(r.Get("On"));
        if(r.Get("Frozen")!="") {
            bool freeze=Values.Bool(r.Get("Frozen"));
            if(freeze&&l.ObjectId==db.Clayer)throw new InvalidOperationException("Cannot freeze the current layer '"+l.Name+"'. Set another current layer and retry.");
            if(l.IsFrozen!=freeze)l.IsFrozen=freeze;
        }
        if(r.Get("Locked")!="")l.IsLocked=Values.Bool(r.Get("Locked"));
        if(r.Get("Plot")!="")l.IsPlottable=Values.Bool(r.Get("Plot"));
        if(r.Get("NewVPFreeze")!="")l.ViewportVisibilityDefault=Values.Bool(r.Get("NewVPFreeze"));
        if(r.ContainsKey("Description"))l.Description=r.Get("Description");
        if(r.Get("Hidden")!="")l.IsHidden=Values.Bool(r.Get("Hidden"));
        if(r.Get("Material")!="")l.MaterialId=resources.Material(r.Get("Material"));
        if(r.Get("PlotStyle")!="") {
            if(db.PlotStyleMode)report.Notes.Add("Named plot style skipped in CTB drawing: "+l.Name);
            else l.PlotStyleNameId=resources.PlotStyle(r.Get("PlotStyle"));
        }
    }
    static void ApplyViewport(Database db,LayerTableRecord l,Viewport vp,Row r,Resources resources,TransferReport report) {
        if(r.Get("VPFreeze")!="") {
            var ids=new ObjectIdCollection(new[]{l.ObjectId});
            if(Values.Bool(r.Get("VPFreeze")))vp.FreezeLayersInViewport(ids.GetEnumerator());
            else {
                vp.ThawLayersInViewport(ids.GetEnumerator());
                if(l.IsOff||l.IsFrozen)report.Notes.Add("VP thawed, but globally off/frozen: "+l.Name+" (VP "+vp.Handle+")");
            }
        }
        var p=l.GetViewportOverrides(vp.ObjectId);
        if(r.Get("VPColor")!="") {if(Values.Inherit(r.Get("VPColor")))p.IsColorOverridden=false;else using(var c=Values.ColorValue(r.Get("VPColor")))p.Color=c;}
        if(r.Get("VPLinetype")!="") {if(Values.Inherit(r.Get("VPLinetype")))p.IsLinetypeOverridden=false;else p.LinetypeObjectId=resources.Linetype(r.Get("VPLinetype"));}
        if(r.Get("VPLineweight")!="") {if(Values.Inherit(r.Get("VPLineweight")))p.IsLineWeightOverridden=false;else p.LineWeight=Values.WeightValue(r.Get("VPLineweight"));}
        if(r.Get("VPTransparency")!="") {if(Values.Inherit(r.Get("VPTransparency")))p.IsTransparencyOverridden=false;else p.Transparency=Values.TransparencyValue(r.Get("VPTransparency"));}
        if(r.Get("VPPlotStyle")!="") {
            if(Values.Inherit(r.Get("VPPlotStyle")))p.IsPlotStyleOverridden=false;
            else if(db.PlotStyleMode)report.Notes.Add("VP named plot style skipped in CTB drawing: "+l.Name);
            else p.PlotStyleNameId=resources.PlotStyle(r.Get("VPPlotStyle"));
        }
    }
    static void ApplyFilters(Database db,Snapshot s,Dictionary<string,ObjectId> layers,FilterMode mode,TransferReport report) {
        var tree=db.LayerFilters;var root=tree.Root;
        if(mode==FilterMode.Replace)foreach(LayerFilter f in root.NestedFilters.Cast<LayerFilter>().ToArray()) {
            if(f.AllowDelete&&!f.DynamicallyGenerated)root.NestedFilters.Remove(f);
        }
        var rows=s.Of("FILTER").ToList();
        Action<LayerFilter,string> add=null;
        add=(parent,parentId)=> {
            var ordered=rows.Where(r=>r.Get("ParentId").Equals(parentId,StringComparison.OrdinalIgnoreCase)).OrderBy(r=>int.Parse(r.Get("Order"))).ToList();
            var imported=new List<LayerFilter>();
            foreach(var row in ordered) {
                var f=parent.NestedFilters.Cast<LayerFilter>().FirstOrDefault(x=>x.Name.Equals(row.Get("FilterName"),StringComparison.OrdinalIgnoreCase));
                bool group=row.Get("FilterType")=="GROUP";
                if(f!=null && (!f.AllowDelete||f.DynamicallyGenerated||f.IsProxy))throw new InvalidOperationException("Filter conflicts with a system/proxy filter: "+f.Name);
                if(f!=null && (f is LayerGroup)!=group)throw new InvalidOperationException("Filter type conflict: "+f.Name+". Use Replace to replace custom filter trees.");
                if(f==null){f=group?(LayerFilter)new LayerGroup():new LayerFilter();f.Name=row.Get("FilterName");parent.NestedFilters.Add(f);}
                if(group) {
                    var g=(LayerGroup)f;g.LayerIds.Clear();
                    foreach(var m in s.Of("MEMBER").Where(m=>m.Get("FilterId").Equals(row.Get("FilterId"),StringComparison.OrdinalIgnoreCase))) {
                        if(layers.TryGetValue(m.Get("Layer"),out var id)){if(!g.LayerIds.Contains(id))g.LayerIds.Add(id);}
                        else report.Notes.Add("Filter member skipped (missing layer): "+m.Get("Layer"));
                    }
                } else f.FilterExpression=row.Get("Expression");
                add(f,row.Get("FilterId"));imported.Add(f);report.Filters++;
            }
            // Keep unrelated filters; append imported siblings together in CSV Order.
            foreach(var f in imported)parent.NestedFilters.Remove(f);
            foreach(var f in imported)parent.NestedFilters.Add(f);
        };
        add(root,"");db.LayerFilters=new LayerFilterTree(root,root);
    }
}
// A CSV carries resource names. Missing definitions can be cloned from the recorded
// source DWG (including custom linetypes and material dependencies). Never substitute
// Continuous or a default material silently. All work is inside the import transaction.
internal sealed class Resources : IDisposable {
    readonly Database target; readonly Transaction tr; readonly string sourcePath;
    Database source;Transaction sourceTr;
    public Resources(Database db,Transaction transaction,string path){target=db;tr=transaction;sourcePath=path;}
    void OpenSource() {
        if(source!=null)return;
        if(!File.Exists(sourcePath))throw new InvalidOperationException("Missing resource definition. Keep the source DWG available, update META SourceDwg, or load the definition in the destination first: "+sourcePath);
        source=new Database(false,true);source.ReadDwgFile(sourcePath,FileOpenMode.OpenForReadAndAllShare,true,"");source.CloseInput(true);sourceTr=source.TransactionManager.StartTransaction();
    }
    public ObjectId Linetype(string name) {
        var table=(LinetypeTable)tr.GetObject(target.LinetypeTableId,OpenMode.ForRead);
        if(table.Has(name))return table[name];
        OpenSource();var src=(LinetypeTable)sourceTr.GetObject(source.LinetypeTableId,OpenMode.ForRead);
        if(!src.Has(name))throw new InvalidOperationException("Linetype not found in source DWG: "+name);
        return Clone(src[name],target.LinetypeTableId);
    }
    public ObjectId Material(string name) {return DictionaryItem(name,target.MaterialDictionaryId,()=>source.MaterialDictionaryId);}
    public ObjectId PlotStyle(string name) {return DictionaryItem(name,target.PlotStyleNameDictionaryId,()=>source.PlotStyleNameDictionaryId);}
    ObjectId DictionaryItem(string name,ObjectId targetDictionary,Func<ObjectId> sourceDictionary) {
        var dict=(DBDictionary)tr.GetObject(targetDictionary,OpenMode.ForRead);if(dict.Contains(name))return dict.GetAt(name);
        OpenSource();var src=(DBDictionary)sourceTr.GetObject(sourceDictionary(),OpenMode.ForRead);
        if(!src.Contains(name))throw new InvalidOperationException("Resource not found in source DWG: "+name);
        return Clone(src.GetAt(name),targetDictionary);
    }
    ObjectId Clone(ObjectId id,ObjectId owner) {
        var mapping=new IdMapping();source.WblockCloneObjects(new ObjectIdCollection(new[]{id}),owner,mapping,DuplicateRecordCloning.Ignore,false);
        foreach(IdPair p in mapping)if(p.Key==id)return p.Value;
        throw new InvalidOperationException("Cannot clone resource "+id.Handle);
    }
    public void Dispose(){if(sourceTr!=null)sourceTr.Dispose();if(source!=null)source.Dispose();}
}
}

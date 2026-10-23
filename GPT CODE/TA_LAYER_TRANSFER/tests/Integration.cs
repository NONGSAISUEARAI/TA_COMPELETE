using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Autodesk.AutoCAD.Colors;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Geometry;
using Autodesk.AutoCAD.LayerManager;
using Autodesk.AutoCAD.Runtime;

[assembly: CommandClass(typeof(TaLayerTransfer.Integration))]
namespace TaLayerTransfer {
public class Integration {
    static string Dir=Path.Combine(Path.GetDirectoryName(typeof(Integration).Assembly.Location),"..");
    static List<string> results=new List<string>();
    static void Check(bool condition,string label){if(!condition)throw new System.Exception("FAILED: "+label);results.Add("PASS: "+label);}
    static void ExpectError(Action action,string label){bool failed=false;try{action();}catch(System.Exception){failed=true;}Check(failed,label);}
    [CommandMethod("MAVPTEST")]
    public void Run() {
        Database previous=HostApplicationServices.WorkingDatabase;
        try {RunTests();results.Add("ALL TESTS PASSED");}
        catch(System.Exception ex){results.Add(ex.ToString());}
        finally {HostApplicationServices.WorkingDatabase=previous;File.WriteAllLines(Path.Combine(Dir,"results.txt"),results);}
    }
    sealed class Fixture : IDisposable {
        public Database Db=new Database(true,true);
        public ObjectId A,B,V1,V2;
        public Fixture(bool source) {
            HostApplicationServices.WorkingDatabase=Db;
            Db.DisableUndoRecording(false);
            using(var tr=Db.TransactionManager.StartTransaction()) {
                var table=(LayerTable)tr.GetObject(Db.LayerTableId,OpenMode.ForWrite);
                var a=new LayerTableRecord{Name="A-WALL",Color=Color.FromColorIndex(ColorMethod.ByAci,(short)(source?1:3)),LineWeight=source?LineWeight.LineWeight035:LineWeight.LineWeight070,Description=source?"ผนัง, \"ทดสอบ\"\r\nบรรทัดสอง":"destination"};
                A=table.Add(a);tr.AddNewlyCreatedDBObject(a,true);
                a.Description=source?"ผนัง, \"ทดสอบ\"\r\nบรรทัดสอง":"destination";
                if(source) {
                    var b=new LayerTableRecord{Name="B-LIGHT",Color=Color.FromRgb(12,34,56),IsOff=true,IsLocked=true,IsPlottable=false,ViewportVisibilityDefault=true};
                    B=table.Add(b);tr.AddNewlyCreatedDBObject(b,true);
                    b.Transparency=new Transparency((byte)128);
                    var lt=(LinetypeTable)tr.GetObject(Db.LinetypeTableId,OpenMode.ForWrite);
                    var dash=new LinetypeTableRecord{Name="TA_CUSTOM_DASH",AsciiDescription="Test custom line",NumDashes=2,PatternLength=.75};dash.SetDashLengthAt(0,.5);dash.SetDashLengthAt(1,-.25);
                    lt.Add(dash);tr.AddNewlyCreatedDBObject(dash,true);a.LinetypeObjectId=dash.ObjectId;
                }
                var layouts=(DBDictionary)tr.GetObject(Db.LayoutDictionaryId,OpenMode.ForRead);
                var layout=(Layout)tr.GetObject(layouts.GetAt("Layout1"),OpenMode.ForRead);
                var btr=(BlockTableRecord)tr.GetObject(layout.BlockTableRecordId,OpenMode.ForWrite);
                var first=new Viewport{CenterPoint=new Point3d(50,50,0),Width=40,Height=30,ViewHeight=30};
                V1=btr.AppendEntity(first);tr.AddNewlyCreatedDBObject(first,true);
                var second=new Viewport{CenterPoint=new Point3d(120,50,0),Width=40,Height=30,ViewHeight=30};
                V2=btr.AppendEntity(second);tr.AddNewlyCreatedDBObject(second,true);
                if(source)first.FreezeLayersInViewport(new ObjectIdCollection(new[]{A}).GetEnumerator());
                var p=a.GetViewportOverrides(V1);p.Color=Color.FromRgb(200,100,50);p.LineWeight=LineWeight.LineWeight018;p.Transparency=new Transparency((byte)180);
                p.LinetypeObjectId=Db.ContinuousLinetype;
                var p2=a.GetViewportOverrides(V2);p2.Color=Color.FromColorIndex(ColorMethod.ByAci,(short)(source?1:6));
                if(!source)p2.LineWeight=LineWeight.LineWeight100;
                tr.Commit();
            }
            var tree=Db.LayerFilters;
            if(source) {
                var z=new LayerGroup{Name="Z-งานผนัง"};z.LayerIds.Add(A);z.LayerIds.Add(B);
                var child=new LayerFilter{Name="Walls only",FilterExpression="NAME==\"A-*\""};z.NestedFilters.Add(child);
                var nested=new LayerGroup{Name="Nested lights"};nested.LayerIds.Add(B);child.NestedFilters.Add(nested);
                tree.Root.NestedFilters.Add(z);tree.Root.NestedFilters.Add(new LayerGroup{Name="A-Empty"});
            } else tree.Root.NestedFilters.Add(new LayerGroup{Name="Destination-only"});
            Db.LayerFilters=tree;
        }
        public Snapshot Snapshot(){HostApplicationServices.WorkingDatabase=Db;return Transfer.Capture(Db,new[]{V1,V2},new TransferReport());}
        public void Dispose(){Db.Dispose();}
    }
    static string Fields(Row r,IEnumerable<string> keys){return string.Join("\0",keys.Select(k=>r.Get(k)));}
    static string LayerState(Snapshot s,string name){return Fields(s.Of("LAYER").Single(r=>r.Get("Layer")==name),Snapshot.Columns);}
    static string VpState(Snapshot s,string vp,string name){return Fields(s.Of("VPLAYER").Single(r=>r.Get("Viewport")==vp&&r.Get("Layer")==name),Snapshot.Columns);}
    static ImportOptions Options(Fixture target,ImportScope scope,bool create=true,bool overwrite=true,FilterMode filters=FilterMode.Skip) {
        HostApplicationServices.WorkingDatabase=target.Db;
        var o=new ImportOptions{Scope=scope,CreateMissing=create,Overwrite=overwrite,Filters=filters};o.Viewports["VP1"]=new List<ObjectId>{target.V1};return o;
    }
    static void RunTests() {
        Directory.CreateDirectory(Dir);
        using(var source=new Fixture(true)) {
            source.Db.SaveAs(Path.Combine(Dir,"source.dwg"),DwgVersion.Current);
            var original=source.Snapshot();original.Meta["SourceDwg"]=Path.Combine(Dir,"source.dwg");
            var csv=Path.Combine(Dir,"sample.csv");Csv.Write(csv,original);var s=Csv.Read(csv);
            Check(s.Rows.Count==original.Rows.Count&&LayerState(s,"A-WALL")==LayerState(original,"A-WALL"),"CSV Unicode, comma, quotes, multiline description round trip");
            Check(s.Of("LAYER").Single(r=>r.Get("Layer")=="A-WALL").Get("Description")=="ผนัง, \"ทดสอบ\"\r\nบรรทัดสอง","Description fixture contains actual Thai, quotes and newlines");
            Check(s.Of("LAYER").Single(r=>r.Get("Layer")=="0").Get("NewVPFreeze")=="0"&&s.Of("LAYER").Single(r=>r.Get("Layer")=="B-LIGHT").Get("NewVPFreeze")=="1","NewVPFreeze 1 means frozen in new viewports");
            Check(s.Of("VPLAYER").Single(r=>r.Get("Viewport")=="VP2"&&r.Get("Layer")=="A-WALL").Get("VPColor")=="ACI:1","Explicit override equal to base value is still an override");
            Check(s.Of("FILTER").Count()==4&&s.Of("MEMBER").Count()==3,"Nested property/group filters and membership exported");
            Check(VpState(s,"VP1","A-WALL")!=VpState(s,"VP2","A-WALL"),"Distinct viewport snapshots captured");
            Check(s.Of("VPLAYER").Single(r=>r.Get("Viewport")=="VP2"&&r.Get("Layer")=="A-WALL").Get("VPLineweight")=="INHERIT","Absent override exported explicitly");
            ExpectError(()=>Csv.Parse("a,b\n\"unterminated,b",','),"Malformed CSV quote rejected");
            Check(Csv.Parse("a;b\r\n\"ไทย;test\";2",';')[1][0]=="ไทย;test","Semicolon CSV dialect");
            var cycle=Csv.Read(csv);cycle.Of("FILTER").First()["ParentId"]=cycle.Of("FILTER").Last().Get("FilterId");
            // Explicit self-cycle avoids depending on the final sibling's location.
            cycle.Of("FILTER").First()["ParentId"]=cycle.Of("FILTER").First().Get("FilterId");
            ExpectError(()=>cycle.Validate(),"Cyclic filter tree rejected");
            var bad=Csv.Read(csv);bad.Of("LAYER").First()["Locked"]="maybe";
            ExpectError(()=>Transfer.ValidateValues(bad),"Invalid booleans rejected before import");
            var invalidBase=Csv.Read(csv);invalidBase.Of("LAYER").First()["Color"]="INHERIT";
            ExpectError(()=>Transfer.ValidateValues(invalidBase),"INHERIT is only allowed for viewport overrides");
            for(int alpha=0;alpha<256;alpha++)if(Values.TransparencyValue(Values.TransparencyText(new Transparency((byte)alpha))).Alpha!=alpha)throw new System.Exception("Alpha mismatch "+alpha);
            Check(true,"All 256 transparency alpha values round trip");
            using(var target=new Fixture(false)) {
                var o=Options(target,ImportScope.Both,true,true,FilterMode.Replace);o.Viewports["VP2"]=new List<ObjectId>{target.V2};
                var report=Transfer.Apply(target.Db,s,o);var actual=target.Snapshot();
                Check(report.Created==1,"Missing layer created");
                Check(LayerState(actual,"A-WALL")==LayerState(s,"A-WALL"),"Global layer settings transferred across DWGs");
                Check(LayerState(actual,"B-LIGHT")==LayerState(s,"B-LIGHT"),"New layer keeps plot, lock, transparency, New VP Freeze");
                Check(VpState(actual,"VP1","A-WALL")==VpState(s,"VP1","A-WALL"),"VP freeze and explicit overrides round trip");
                Check(VpState(actual,"VP2","A-WALL")==VpState(s,"VP2","A-WALL"),"INHERIT removes old target override without losing other VP data");
                Check(actual.Of("FILTER").Select(r=>Fields(r,new[]{"FilterName","ParentId","Order","Expression"})).SequenceEqual(s.Of("FILTER").Select(r=>Fields(r,new[]{"FilterName","ParentId","Order","Expression"}))),"Nested filter order, names, expressions round trip");
                Check(actual.Of("MEMBER").Select(r=>Fields(r,new[]{"FilterId","Layer"})).SequenceEqual(s.Of("MEMBER").Select(r=>Fields(r,new[]{"FilterId","Layer"}))),"Group membership round trip");
                target.Db.SaveAs(Path.Combine(Dir,"destination.dwg"),DwgVersion.Current);
            }
            using(var target=new Fixture(false)) {
                var before=target.Snapshot();var o=Options(target,ImportScope.Viewport,false);
                Transfer.Apply(target.Db,s,o);var after=target.Snapshot();
                Check(LayerState(before,"A-WALL")==LayerState(after,"A-WALL"),"Viewport-only leaves existing drawing-wide properties unchanged");
                Check(VpState(before,"VP2","A-WALL")==VpState(after,"VP2","A-WALL"),"Unselected viewport unchanged");
                Check(!after.Of("LAYER").Any(r=>r.Get("Layer")=="B-LIGHT"),"Missing-layer Skip does not create layers");
                Check(after.Of("FILTER").First().Get("FilterName")=="Destination-only","Viewport-only preserves filters");
                var beforeKeep=target.Snapshot();o=Options(target,ImportScope.Both,true,false);
                Transfer.Apply(target.Db,s,o);var afterKeep=target.Snapshot();
                Check(LayerState(beforeKeep,"A-WALL")==LayerState(afterKeep,"A-WALL")&&VpState(beforeKeep,"VP1","A-WALL")==VpState(afterKeep,"VP1","A-WALL"),"Keep preserves existing global and VP properties");
                Check(afterKeep.Of("LAYER").Any(r=>r.Get("Layer")=="B-LIGHT"),"Keep still permits missing-layer creation");
            }
            using(var target=new Fixture(false)) {
                var before=target.Snapshot();var fail=Csv.Read(csv);fail.Of("LAYER").Single(r=>r.Get("Layer")=="A-WALL")["Linetype"]="DOES_NOT_EXIST";
                ExpectError(()=>Transfer.Apply(target.Db,fail,Options(target,ImportScope.Both)),"Unavailable resource aborts import");
                var after=target.Snapshot();
                if(LayerState(before,"A-WALL")!=LayerState(after,"A-WALL")) {
                    var br=before.Of("LAYER").Single(r=>r.Get("Layer")=="A-WALL");var ar=after.Of("LAYER").Single(r=>r.Get("Layer")=="A-WALL");
                    results.Add("DIFF: "+string.Join("; ",Snapshot.Columns.Where(k=>br.Get(k)!=ar.Get(k)).Select(k=>k+"="+br.Get(k)+" -> "+ar.Get(k))));
                }
                Check(LayerState(before,"A-WALL")==LayerState(after,"A-WALL")&&!after.Of("LAYER").Any(r=>r.Get("Layer")=="B-LIGHT"),"Failure rolls back earlier changes and newly created layers");
                var o=Options(target,ImportScope.Both);o.Viewports["VP2"]=new List<ObjectId>{target.V1};
                ExpectError(()=>Transfer.Apply(target.Db,s,o),"Conflicting source-to-target VP mapping rejected");
                Transfer.Apply(target.Db,s,Options(target,ImportScope.Drawing,true,true,FilterMode.Merge));
                var merged=target.Snapshot();Check(merged.Of("FILTER").Any(r=>r.Get("FilterName")=="Destination-only")&&merged.Of("FILTER").Count()==5,"Filter Merge preserves unrelated folders");
                Check(VpState(before,"VP1","A-WALL")==VpState(merged,"VP1","A-WALL"),"Drawing-only leaves VP overrides unchanged");
            }
            using(var target=new Fixture(false)) {
                var before=target.Snapshot();var o=Options(target,ImportScope.Both,true,true,FilterMode.Merge);
                // Fail after layers, resource cloning, and VP writes, when merging a conflicting filter type.
                var tree=target.Db.LayerFilters;tree.Root.NestedFilters.Add(new LayerFilter{Name="Z-งานผนัง",FilterExpression="NAME==\"*\""});target.Db.LayerFilters=tree;
                ExpectError(()=>Transfer.Apply(target.Db,s,o),"Late filter-type conflict aborts import");
                var after=target.Snapshot();
                Check(LayerState(before,"A-WALL")==LayerState(after,"A-WALL")&&VpState(before,"VP1","A-WALL")==VpState(after,"VP1","A-WALL"),"Late failure restores layers and viewport overrides");
                using(var tr=target.Db.TransactionManager.StartTransaction())Check(!((LinetypeTable)tr.GetObject(target.Db.LinetypeTableId,OpenMode.ForRead)).Has("TA_CUSTOM_DASH"),"Late failure also rolls back cloned resources");
                target.Db.DisableUndoRecording(true);
                ExpectError(()=>Transfer.Apply(target.Db,s,Options(target,ImportScope.Both)),"Import refuses a database with Undo disabled");
            }
        }
    }
}
}

using System;
using System.IO;
using System.Windows.Forms;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Geometry;
using Autodesk.AutoCAD.Runtime;
using App = Autodesk.AutoCAD.ApplicationServices.Core.Application;

namespace TaUpdateBlock {
public static class Integration {
    private static string lastRoot;
    [LispFunction("TAUBTEST-FIXTURE-PATH")]
    public static string FixturePath(ResultBuffer args) { return lastRoot; }
    // Exercises the exact return encoder used by the native folder dialog, without a UI.
    [LispFunction("TAUBTEST-PICKER-RESULT")]
    public static ResultBuffer PickerResult(ResultBuffer args) {
        var values = args.AsArray();
        return FolderPicker.EncodeResult(Convert.ToInt32(values[0].Value) == 0
            ? DialogResult.Cancel : DialogResult.OK, (string)values[1].Value);
    }

    [CommandMethod("TAUBINTEGRATION")]
    public static void Run() {
        var ed = App.DocumentManager.MdiActiveDocument.Editor;
        try {
            string root = Path.Combine(@"C:\Users\tawan.t\Documents\GitHub\TA_COMPELETE\tmp\taub_integration",
                DateTime.Now.ToString("yyyyMMdd_HHmmss_fff"));
            Directory.CreateDirectory(root);
            lastRoot = root;
            string source = Path.Combine(root, "MASTER.dwg");
            string target = Path.Combine(root, "TARGET.dwg");
            CreateDrawing(source, 20, true);
            CreateDrawing(target, 5, false);
            string originalMaster = Convert.ToHexString(System.Security.Cryptography.SHA256.HashData(File.ReadAllBytes(source)));
            using (var args = new ResultBuffer(new TypedValue((int)LispDataType.Text, source),
                new TypedValue((int)LispDataType.Text, "TAUB_TEST_BLOCK"),
                new TypedValue((int)LispDataType.Text, target), new TypedValue((int)LispDataType.Int32, 1)))
            using (var result = Plugin.Update(args)) {
                var values = result.AsArray();
                if (Convert.ToInt32(values[1].Value) != 1 || Convert.ToInt32(values[2].Value) != 0)
                    throw new InvalidOperationException("Update failed: " + values[3].Value);
            }
            using (var db = new Database(false, true)) {
                db.ReadDwgFile(target, FileShare.Read, true, "");
                db.CloseInput(true);
                using (var tr = db.TransactionManager.StartTransaction()) {
                    var bt = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForRead);
                    var block = (BlockTableRecord)tr.GetObject(bt["TAUB_TEST_BLOCK"], OpenMode.ForRead);
                    bool geometry = false;
                    foreach (ObjectId id in block) {
                        if (tr.GetObject(id, OpenMode.ForRead) is Line line && Math.Abs(line.Length - 20) < 0.00001) geometry = true;
                    }
                    Check(geometry, "block geometry redefined from length 5 to 20");
                    var model = (BlockTableRecord)tr.GetObject(bt[BlockTableRecord.ModelSpace], OpenMode.ForRead);
                    foreach (ObjectId id in model) {
                        if (!(tr.GetObject(id, OpenMode.ForRead) is BlockReference br)) continue;
                        Check(br.Position.DistanceTo(new Point3d(100, 200, 0)) < 0.00001, "reference insertion point preserved");
                        bool kept = false, added = false, removed = true;
                        foreach (ObjectId arId in br.AttributeCollection) {
                            var ar = (AttributeReference)tr.GetObject(arId, OpenMode.ForRead);
                            if (ar.Tag == "KEEP") kept = ar.TextString == "USER_VALUE";
                            if (ar.Tag == "NEW") added = ar.TextString == "NEW_DEFAULT";
                            if (ar.Tag == "OLD") removed = false;
                        }
                        Check(kept, "existing attribute value preserved");
                        Check(added, "new attribute created");
                        Check(removed, "obsolete attribute removed");
                    }
                }
            }
            Check(Directory.GetFiles(root, "TARGET.TAUB_*.bak").Length == 1, "backup created");
            string finalMaster = Convert.ToHexString(System.Security.Cryptography.SHA256.HashData(File.ReadAllBytes(source)));
            Check(finalMaster == originalMaster, "source DWG remains unchanged");
            ed.WriteMessage("\nTAUB_INTEGRATION_PASSED\nFixtures: " + root);
        } catch (System.Exception ex) { ed.WriteMessage("\nTAUB_INTEGRATION_FAILED: " + ex); }
    }

    private static void Check(bool condition, string label) {
        if (!condition) throw new InvalidOperationException(label);
        App.DocumentManager.MdiActiveDocument.Editor.WriteMessage("\nPASS: " + label);
    }

    private static void CreateDrawing(string path, double length, bool master) {
        using (var db = new Database(true, true)) {
            using (var tr = db.TransactionManager.StartTransaction()) {
                var bt = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForWrite);
                var block = new BlockTableRecord { Name = "TAUB_TEST_BLOCK" };
                bt.Add(block); tr.AddNewlyCreatedDBObject(block, true);
                var line = new Line(Point3d.Origin, new Point3d(length, 0, 0));
                block.AppendEntity(line); tr.AddNewlyCreatedDBObject(line, true);
                foreach (string tag in new[] { "KEEP", master ? "NEW" : "OLD" }) {
                    var ad = new AttributeDefinition {
                        Position = new Point3d(0, 2, 0), Tag = tag, Prompt = tag,
                        TextString = tag == "NEW" ? "NEW_DEFAULT" : "DEFAULT", Height = 1
                    };
                    block.AppendEntity(ad); tr.AddNewlyCreatedDBObject(ad, true);
                }
                var model = (BlockTableRecord)tr.GetObject(bt[BlockTableRecord.ModelSpace], OpenMode.ForWrite);
                var br = new BlockReference(new Point3d(100, 200, 0), block.ObjectId);
                model.AppendEntity(br); tr.AddNewlyCreatedDBObject(br, true);
                foreach (ObjectId id in block) {
                    if (!(tr.GetObject(id, OpenMode.ForRead) is AttributeDefinition ad)) continue;
                    var ar = new AttributeReference(); ar.SetAttributeFromBlock(ad, br.BlockTransform);
                    if (ad.Tag == "KEEP") ar.TextString = "USER_VALUE";
                    br.AttributeCollection.AppendAttribute(ar); tr.AddNewlyCreatedDBObject(ar, true);
                }
                tr.Commit();
            }
            db.SaveAs(path, DwgVersion.Current);
        }
    }
}
}

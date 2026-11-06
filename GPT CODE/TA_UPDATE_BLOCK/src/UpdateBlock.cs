using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Geometry;
using Autodesk.AutoCAD.Runtime;
using App = Autodesk.AutoCAD.ApplicationServices.Core.Application;

[assembly: System.Runtime.Versioning.TargetFramework(".NETCoreApp,Version=v8.0")]
[assembly: ExtensionApplication(typeof(TaUpdateBlock.Plugin))]

namespace TaUpdateBlock {
public sealed class Plugin : IExtensionApplication {
    public void Initialize() { }
    public void Terminate() { }

    // LISP: (TA-UPDATE-BLOCK source-dwg block-name "a.dwg|b.dwg" T)
    // Returns: (success-count failure-count "one line per file")
    [LispFunction("TA-UPDATE-BLOCK")]
    public static ResultBuffer Update(ResultBuffer args) {
        try {
            var values = args == null ? Array.Empty<TypedValue>() : args.AsArray();
            if (values.Length < 4)
                return Result(0, 1, "Usage: (TA-UPDATE-BLOCK source block targets backup)");
            string source = FullPath(Convert.ToString(values[0].Value, CultureInfo.InvariantCulture));
            string blockName = Convert.ToString(values[1].Value, CultureInfo.InvariantCulture) ?? "";
            string packedTargets = Convert.ToString(values[2].Value, CultureInfo.InvariantCulture) ?? "";
            bool backup = Convert.ToInt32(values[3].Value, CultureInfo.InvariantCulture) != 0;
            var targets = packedTargets.Split(new[] {'|'}, StringSplitOptions.RemoveEmptyEntries)
                .Select(FullPath).Distinct(StringComparer.OrdinalIgnoreCase).ToList();
            if (blockName.Length == 0) throw new ArgumentException("Block name is empty.");
            if (targets.Count == 0) throw new ArgumentException("No target drawings were supplied.");

            int ok = 0, failed = 0;
            var messages = new List<string>();
            using (var sourceOwner = OpenSource(source)) {
                Database sourceDb = sourceOwner.Database;
                ObjectId sourceBlockId = FindBlock(sourceDb, blockName);
                foreach (string target in targets) {
                    try {
                        if (SamePath(source, target)) throw new InvalidOperationException("source drawing was skipped");
                        if (!File.Exists(target)) throw new FileNotFoundException("file not found", target);
                        UpdateOne(sourceDb, sourceBlockId, blockName, target, backup);
                        ok++;
                        messages.Add("OK   " + target);
                    } catch (System.Exception ex) {
                        failed++;
                        messages.Add("FAIL " + target + " : " + OneLine(ex.Message));
                    }
                }
            }
            return Result(ok, failed, string.Join("\n", messages));
        } catch (System.Exception ex) {
            return Result(0, 1, "FATAL: " + OneLine(ex.Message));
        }
    }

    private static void UpdateOne(Database sourceDb, ObjectId sourceBlockId, string blockName,
                                  string targetPath, bool backup) {
        EnsureNotOpen(targetPath);
        if (backup) CreateBackup(targetPath);
        using (var targetDb = new Database(false, true)) {
            targetDb.ReadDwgFile(targetPath, FileShare.ReadWrite, true, "");
            targetDb.CloseInput(true);
            using (var tr = targetDb.TransactionManager.StartTransaction()) {
                var bt = (BlockTable)tr.GetObject(targetDb.BlockTableId, OpenMode.ForRead);
                var ids = new ObjectIdCollection(new[] {sourceBlockId});
                var mapping = new IdMapping();
                sourceDb.WblockCloneObjects(ids, targetDb.BlockTableId, mapping,
                    DuplicateRecordCloning.Replace, false);
                bt = (BlockTable)tr.GetObject(targetDb.BlockTableId, OpenMode.ForRead);
                if (!bt.Has(blockName)) throw new InvalidOperationException("redefine did not create the block");
                var definition = (BlockTableRecord)tr.GetObject(bt[blockName], OpenMode.ForWrite);
                if (definition.IsDynamicBlock) definition.UpdateAnonymousBlocks();
                SyncAttributes(targetDb, tr, definition);
                tr.Commit();
            }
            targetDb.SaveAs(targetPath, DwgVersion.Current);
        }
    }

    private static void SyncAttributes(Database db, Transaction tr, BlockTableRecord definition) {
        var definitions = new Dictionary<string, ObjectId>(StringComparer.OrdinalIgnoreCase);
        foreach (ObjectId id in definition) {
            var ad = tr.GetObject(id, OpenMode.ForRead) as AttributeDefinition;
            if (ad != null && !ad.Constant && !definitions.ContainsKey(ad.Tag)) definitions.Add(ad.Tag, id);
        }
        var referenceIds = new HashSet<ObjectId>();
        AddIds(referenceIds, definition.GetBlockReferenceIds(true, false));
        if (definition.IsDynamicBlock) {
            foreach (ObjectId anonId in definition.GetAnonymousBlockIds()) {
                var anon = tr.GetObject(anonId, OpenMode.ForRead) as BlockTableRecord;
                if (anon != null) AddIds(referenceIds, anon.GetBlockReferenceIds(true, false));
            }
        }
        foreach (ObjectId id in referenceIds) {
            var br = tr.GetObject(id, OpenMode.ForWrite) as BlockReference;
            if (br == null) continue;
            var existing = new Dictionary<string, AttributeReference>(StringComparer.OrdinalIgnoreCase);
            foreach (ObjectId arId in br.AttributeCollection) {
                var ar = tr.GetObject(arId, OpenMode.ForWrite) as AttributeReference;
                if (ar != null && !existing.ContainsKey(ar.Tag)) existing.Add(ar.Tag, ar);
            }
            foreach (var pair in definitions) {
                var ad = (AttributeDefinition)tr.GetObject(pair.Value, OpenMode.ForRead);
                AttributeReference ar;
                if (existing.TryGetValue(pair.Key, out ar)) {
                    string value = ar.TextString;
                    ar.SetAttributeFromBlock(ad, br.BlockTransform);
                    ar.TextString = value;
                    existing.Remove(pair.Key);
                } else {
                    ar = new AttributeReference();
                    ar.SetAttributeFromBlock(ad, br.BlockTransform);
                    br.AttributeCollection.AppendAttribute(ar);
                    tr.AddNewlyCreatedDBObject(ar, true);
                }
            }
            foreach (var orphan in existing.Values) orphan.Erase();
        }
    }

    private static void AddIds(HashSet<ObjectId> set, ObjectIdCollection ids) {
        foreach (ObjectId id in ids) if (!id.IsNull && id.IsValid) set.Add(id);
    }

    private static ObjectId FindBlock(Database db, string name) {
        using (var tr = db.TransactionManager.StartOpenCloseTransaction()) {
            var bt = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForRead);
            if (!bt.Has(name)) throw new InvalidOperationException("Block not found in source: " + name);
            ObjectId id = bt[name];
            var btr = (BlockTableRecord)tr.GetObject(id, OpenMode.ForRead);
            if (btr.IsLayout || btr.IsFromExternalReference || btr.IsDependent)
                throw new InvalidOperationException("Layout/Xref/dependent block is not supported: " + name);
            return id;
        }
    }

    private sealed class SourceOwner : IDisposable {
        public readonly Database Database;
        private readonly bool owns;
        public SourceOwner(Database db, bool ownsDb) { Database = db; owns = ownsDb; }
        public void Dispose() { if (owns) Database.Dispose(); }
    }
    private static SourceOwner OpenSource(string path) {
        foreach (Document doc in App.DocumentManager) {
            if (SamePath(doc.Name, path)) return new SourceOwner(doc.Database, false);
        }
        if (!File.Exists(path)) throw new FileNotFoundException("Source drawing not found", path);
        var db = new Database(false, true);
        try { db.ReadDwgFile(path, FileShare.ReadWrite, true, ""); db.CloseInput(true); return new SourceOwner(db, true); }
        catch { db.Dispose(); throw; }
    }

    private static void EnsureNotOpen(string path) {
        foreach (Document doc in App.DocumentManager)
            if (SamePath(doc.Name, path)) throw new InvalidOperationException("target drawing is open; close it first");
    }
    private static void CreateBackup(string path) {
        string stamp = DateTime.Now.ToString("yyyyMMdd_HHmmss", CultureInfo.InvariantCulture);
        string backup = Path.Combine(Path.GetDirectoryName(path) ?? "", Path.GetFileNameWithoutExtension(path)
            + ".TAUB_" + stamp + ".bak");
        int n = 1;
        while (File.Exists(backup)) backup = Path.Combine(Path.GetDirectoryName(path) ?? "",
            Path.GetFileNameWithoutExtension(path) + ".TAUB_" + stamp + "_" + (n++) + ".bak");
        File.Copy(path, backup, false);
    }
    private static string FullPath(string value) {
        if (string.IsNullOrWhiteSpace(value)) throw new ArgumentException("Drawing path is empty.");
        return Path.GetFullPath(value.Trim().Trim('"'));
    }
    private static bool SamePath(string a, string b) {
        try { return string.Equals(Path.GetFullPath(a), Path.GetFullPath(b), StringComparison.OrdinalIgnoreCase); }
        catch { return false; }
    }
    private static string OneLine(string text) { return (text ?? "unknown error").Replace('\r', ' ').Replace('\n', ' '); }
    private static ResultBuffer Result(int ok, int fail, string report) {
        return new ResultBuffer(new TypedValue((int)LispDataType.ListBegin),
            new TypedValue((int)LispDataType.Int32, ok), new TypedValue((int)LispDataType.Int32, fail),
            new TypedValue((int)LispDataType.Text, report), new TypedValue((int)LispDataType.ListEnd));
    }
}
}

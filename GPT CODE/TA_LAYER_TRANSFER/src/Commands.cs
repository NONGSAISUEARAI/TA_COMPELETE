using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text;
using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.EditorInput;
using Autodesk.AutoCAD.Runtime;
using App = Autodesk.AutoCAD.ApplicationServices.Core.Application;

[assembly: System.Runtime.Versioning.TargetFramework(".NETCoreApp,Version=v8.0")]
[assembly: CommandClass(typeof(TaLayerTransfer.Commands))]
namespace TaLayerTransfer {
public class Commands {
    [CommandMethod("MAVPEXPORT",CommandFlags.Modal)]
    public void Export() {
        var doc=App.DocumentManager.MdiActiveDocument;var ed=doc.Editor;
        try {
            if(Convert.ToInt32(App.GetSystemVariable("DWGTITLED"))==0)
                throw new InvalidOperationException("Save the DWG first so the CSV can use its folder and drawing name.");
            string choice=Keyword(ed,"Viewport snapshots to export","Current Select All None",ActiveVp()?"Current":"Select");
            List<ObjectId> ids;
            if(choice=="None")ids=new List<ObjectId>();
            else if(choice=="All")using(var tr=doc.Database.TransactionManager.StartTransaction()){ids=Transfer.AllViewports(doc.Database,tr);}
            else ids=SelectViewports(doc,choice=="Current");
            var save=new PromptSaveFileOptions("\nExport layers and viewport settings to CSV") {
                Filter="CSV (*.csv)|*.csv",DialogCaption="Export layer settings",
                InitialDirectory=DrawingDirectory(doc),
                InitialFileName=Path.GetFileNameWithoutExtension(doc.Name)+"_"+SafeFileName(Convert.ToString(App.GetSystemVariable("CTAB")))+"_EXPORT_LAYERS_"+DateTime.Now.ToString("yyyyMMdd_HHmmss",CultureInfo.InvariantCulture)+".csv"
            };
            var file=ed.GetFileNameForSave(save);if(file.Status!=PromptStatus.OK)return;
            string csvPath=CsvPath(file.StringResult,doc);
            var report=new TransferReport();var s=Transfer.Capture(doc.Database,ids,report);Csv.Write(csvPath,s);
            ed.WriteMessage($"\nExported {s.Of("LAYER").Count()} layers, {s.Of("VIEWPORT").Count()} VP snapshots, {s.Of("FILTER").Count()} custom filters.\n{csvPath}");
            ShowNotes(ed,report,csvPath+".export.log");
        }catch(OperationCanceledException){ed.WriteMessage("\nCancelled.");}
        catch(System.Exception ex){ed.WriteMessage("\nExport failed: "+ex.Message);}
    }
    [CommandMethod("MAVPIMPORT",CommandFlags.Modal)]
    public void Import() {
        var doc=App.DocumentManager.MdiActiveDocument;var ed=doc.Editor;
        try {
            string selected=SelectImportFile(doc);
            if(selected==null)return;
            string csvPath=CsvPath(selected,doc);
            var snapshot=Csv.Read(csvPath);Transfer.ValidateValues(snapshot);
            var options=new ImportOptions();
            options.Scope=(ImportScope)Enum.Parse(typeof(ImportScope),Keyword(ed,"Apply settings to","Viewport Drawing Both","Viewport"));
            options.CreateMissing=Keyword(ed,"Missing layers","Create Skip","Create")=="Create";
            options.Overwrite=Keyword(ed,"Existing layer names (within selected scope)","Overwrite Keep","Overwrite")=="Overwrite";
            if(options.Scope!=ImportScope.Viewport) {
                options.Filters=(FilterMode)Enum.Parse(typeof(FilterMode),Keyword(ed,"Custom layer filter folders","Merge Replace Skip","Merge"));
                if(options.Filters==FilterMode.Replace)ed.WriteMessage("\nReplace will replace the destination's custom filter tree with the CSV tree.");
            }
            if(options.Scope!=ImportScope.Drawing) {
                var sources=snapshot.Of("VIEWPORT").ToList();
                if(sources.Count==0)throw new InvalidOperationException("CSV contains no viewport snapshots. Use Drawing mode.");
                foreach(var source in sources) {
                    ed.WriteMessage($"\nSource {source.Get("Viewport")}: layout {source.Get("Layout")}, handle {source.Get("Handle")}");
                    if(sources.Count>1 && Keyword(ed,"Map this source snapshot","Apply Skip","Skip")=="Skip")continue;
                    string selection=Keyword(ed,"Destination viewport(s)","Current Select",ActiveVp()?"Current":"Select");
                    options.Viewports[source.Get("Viewport")]=SelectViewports(doc,selection=="Current");
                }
                if(options.Viewports.Count==0)throw new OperationCanceledException();
            }
            var report=Transfer.Apply(doc.Database,snapshot,options);
            ed.WriteMessage("\n"+report.ToString());
            ShowNotes(ed,report,csvPath+".import.log");
            try {ed.Regen();}catch(System.Exception ex){ed.WriteMessage("\nImport completed; REGEN needed: "+ex.Message);}
        }catch(OperationCanceledException){ed.WriteMessage("\nCancelled. No settings imported.");}
        catch(System.Exception ex){ed.WriteMessage("\nImport cancelled; transaction rolled back: "+ex.Message);}
    }
    static string SelectImportFile(Document doc) {
        string directory=DrawingDirectory(doc);
        // Editor.InitialDirectory is only a hint to the remembered AutoCAD dialog.
        // The native dialog flags force the DWG folder for each interactive invocation.
        if(Convert.ToInt32(App.GetSystemVariable("FILEDIA"))!=0 &&
           (Convert.ToInt32(App.GetSystemVariable("CMDACTIVE"))&4)==0) {
            return ImportFileDialog.Pick(directory);
        }
        // Preserve FILEDIA=0 / script operation without opening a modal window.
        var open=new PromptOpenFileOptions("\nSelect layer settings CSV") {
            Filter="CSV (*.csv)|*.csv",DialogCaption="Import layer settings",InitialDirectory=directory
        };
        var file=doc.Editor.GetFileNameForOpen(open);
        return file.Status==PromptStatus.OK?file.StringResult:null;
    }
    static string DrawingDirectory(Document doc) {
        string path=Path.GetDirectoryName(doc.Name);
        if(!string.IsNullOrEmpty(path)&&Path.IsPathFullyQualified(path))return path;
        string prefix=Convert.ToString(App.GetSystemVariable("DWGPREFIX"));
        return string.IsNullOrWhiteSpace(prefix)?Environment.CurrentDirectory:Path.GetFullPath(prefix);
    }
    static string CsvPath(string path,Document doc) {
        path=path.Trim();
        if(path.Length>=2&&path[0]=='"'&&path[path.Length-1]=='"')path=path.Substring(1,path.Length-2);
        if(string.IsNullOrWhiteSpace(path))throw new InvalidOperationException("Select a CSV file.");
        return Path.GetFullPath(path,DrawingDirectory(doc));
    }
    static string SafeFileName(string name) {
        var invalid=Path.GetInvalidFileNameChars();
        string safe=new string(name.Select(c=>invalid.Contains(c)?'_':c).ToArray()).TrimEnd(' ','.');
        return string.IsNullOrWhiteSpace(safe)?"Layout":safe;
    }
    static bool ActiveVp(){return Convert.ToInt32(App.GetSystemVariable("TILEMODE"))==0&&Convert.ToInt32(App.GetSystemVariable("CVPORT"))>1;}
    static string Keyword(Editor ed,string message,string choices,string defaultChoice) {
        var options=new PromptKeywordOptions("\n"+message+": ");
        foreach(var keyword in choices.Split(' '))options.Keywords.Add(keyword);
        options.Keywords.Default=defaultChoice;options.AllowNone=true;
        var result=ed.GetKeywords(options);
        if(result.Status==PromptStatus.Cancel)throw new OperationCanceledException();
        if(result.Status!=PromptStatus.OK&&result.Status!=PromptStatus.None)throw new InvalidOperationException("Invalid option.");
        return result.Status==PromptStatus.None?defaultChoice:result.StringResult;
    }
    static List<ObjectId> SelectViewports(Document doc,bool current) {
        if(current) {
            if(!ActiveVp())throw new InvalidOperationException("Activate a layout viewport first, or choose Select from paper space.");
            return new List<ObjectId>{doc.Editor.CurrentViewportObjectId};
        }
        if(Convert.ToInt32(App.GetSystemVariable("TILEMODE"))!=0||Convert.ToInt32(App.GetSystemVariable("CVPORT"))!=1)
            throw new InvalidOperationException("Select viewport borders from paper space (PSPACE), then run the command again.");
        var result=doc.Editor.GetSelection(new PromptSelectionOptions{MessageForAdding="\nSelect viewport borders: "},new SelectionFilter(new[]{new TypedValue(0,"VIEWPORT")}));
        if(result.Status!=PromptStatus.OK)throw new OperationCanceledException();
        return result.Value.GetObjectIds().Distinct().ToList();
    }
    static void ShowNotes(Editor ed,TransferReport report,string path) {
        var notes=report.Notes.Distinct().ToList();
        foreach(var note in notes.Take(12))ed.WriteMessage("\n- "+note);
        if(notes.Count>12)ed.WriteMessage($"\n... {notes.Count-12} additional notes.");
        try {File.WriteAllLines(path,new[]{DateTimeOffset.Now.ToString("O"),report.ToString()}.Concat(notes),new UTF8Encoding(true));ed.WriteMessage("\nLog: "+path);}
        catch(System.Exception ex){ed.WriteMessage("\nCould not write log: "+ex.Message);}
    }
}
}

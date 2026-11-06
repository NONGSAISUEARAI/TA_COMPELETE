using System;
using System.IO;
using System.Windows.Forms;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Runtime;
using App = Autodesk.AutoCAD.ApplicationServices.Core.Application;

namespace TaUpdateBlock {
public static class FolderPicker {
    // LISP: (TAUB-PICK-FOLDER "D:/PROJECT") -> full path or nil on Cancel.
    // This is Windows' native Explorer folder dialog, not a file-selection workaround.
    [LispFunction("TAUB-PICK-FOLDER")]
    public static ResultBuffer Pick(ResultBuffer args) {
        string initial = "";
        if (args != null) {
            var values = args.AsArray();
            if (values.Length > 0 && values[0].Value is string text) initial = text;
        }
        using (var dialog = CreateDialog(initial)) {
            var owner = new WindowOwner(App.MainWindow.Handle);
            return EncodeResult(dialog.ShowDialog(owner), dialog.SelectedPath);
        }
    }

    internal static ResultBuffer EncodeResult(DialogResult result, string selectedPath) {
        if (result != DialogResult.OK)
            return new ResultBuffer(new TypedValue((int)LispDataType.Nil));
        return new ResultBuffer(new TypedValue((int)LispDataType.Text,
            Path.GetFullPath(selectedPath)));
    }

    internal static FolderBrowserDialog CreateDialog(string initial) {
        return new FolderBrowserDialog {
            AutoUpgradeEnabled = true,
            UseDescriptionForTitle = true,
            Description = "Select TARGET folder containing DWG files",
            ShowNewFolderButton = false,
            SelectedPath = Directory.Exists(initial) ? Path.GetFullPath(initial)
                : Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments)
        };
    }

    private sealed class WindowOwner : IWin32Window {
        public IntPtr Handle { get; }
        public WindowOwner(IntPtr handle) { Handle = handle; }
    }
}
}

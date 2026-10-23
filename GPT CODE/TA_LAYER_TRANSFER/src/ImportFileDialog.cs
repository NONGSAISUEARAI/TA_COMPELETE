
using System;
using System.IO;
using System.Runtime.CompilerServices;
using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.Windows;

namespace TaLayerTransfer
{
    internal static class ImportFileDialog
    {
        [MethodImpl(MethodImplOptions.NoInlining)]
        internal static string Pick(string drawingDirectory = null)
        {
            // Get directory of currently active DWG
            string folder = Application.GetSystemVariable("DWGPREFIX") as string;

            // Fallback if current DWG directory is unavailable
            if (string.IsNullOrWhiteSpace(folder) || !Directory.Exists(folder))
            {
                folder = !string.IsNullOrWhiteSpace(drawingDirectory)
                         && Directory.Exists(drawingDirectory)
                    ? drawingDirectory
                    : Environment.GetFolderPath(
                        Environment.SpecialFolder.MyDocuments);
            }

            var dialog = new OpenFileDialog(
                "Import layer settings",
                folder,
                "csv",
                "TA_MAVPIMPORT_CSV",
                OpenFileDialog.OpenFileDialogFlags.DefaultIsFolder |
                OpenFileDialog.OpenFileDialogFlags.ForceDefaultFolder
            );

            return dialog.ShowDialog() ==
                   System.Windows.Forms.DialogResult.OK
                ? dialog.Filename
                : null;
        }
    }
}

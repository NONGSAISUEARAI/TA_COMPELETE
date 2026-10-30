using System;
using System.Collections.Generic;
using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.EditorInput;
using Autodesk.AutoCAD.LayerManager;
using Autodesk.AutoCAD.Runtime;

namespace TA.FilterFromObject
{
    public sealed class Commands
    {
        private sealed class Match
        {
            public LayerFilter Filter;
            public string Path;
            public int Depth;
        }

        // Reusable subfunction: return the current Group Filter's layer names
        // as a sorted string array. By default, only direct members are read.
        public static string[] GetCurrentFilterLayerNames(Database database,
            bool includeChildGroups)
        {
            if (database == null) throw new ArgumentNullException("database");
            LayerFilter current = database.LayerFilters.Current;
            if (!(current is LayerGroup)) return new string[0];

            HashSet<ObjectId> layerIds = new HashSet<ObjectId>();
            CollectLayerIds(current, includeChildGroups, layerIds);
            List<string> names = new List<string>();
            using (Transaction transaction = database.TransactionManager.StartTransaction())
            {
                foreach (ObjectId id in layerIds)
                {
                    if (id.IsNull || id.IsErased) continue;
                    LayerTableRecord layer = transaction.GetObject(id, OpenMode.ForRead)
                        as LayerTableRecord;
                    if (layer != null) names.Add(layer.Name);
                }
            }
            names.Sort(StringComparer.OrdinalIgnoreCase);
            return names.ToArray();
        }

        private static void CollectLayerIds(LayerFilter filter,
            bool includeChildren, HashSet<ObjectId> result)
        {
            LayerGroup group = filter as LayerGroup;
            if (group != null)
                foreach (ObjectId id in group.LayerIds) result.Add(id);

            if (includeChildren)
                foreach (LayerFilter child in filter.NestedFilters)
                    CollectLayerIds(child, true, result);
        }

        [CommandMethod("TAFILTERLAYERSNET")]
        public static void PrintCurrentFilterLayers()
        {
            Document document = Application.DocumentManager.MdiActiveDocument;
            if (document == null) return;
            Editor editor = document.Editor;
            try
            {
                LayerFilter current = document.Database.LayerFilters.Current;
                if (!(current is LayerGroup))
                {
                    editor.WriteMessage("\nTAHF: the current filter is not a Group Filter.");
                    return;
                }

                string[] layers = GetCurrentFilterLayerNames(document.Database, false);
                editor.WriteMessage("\nTAHF: " + current.Name + " = [");
                for (int i = 0; i < layers.Length; i++)
                    editor.WriteMessage("\n  \"" + layers[i].Replace("\\", "\\\\")
                        .Replace("\"", "\\\"") + "\""
                        + (i + 1 < layers.Length ? "," : ""));
                editor.WriteMessage("\n] (" + layers.Length + " layers)");
            }
            catch (System.Exception exception)
            {
                editor.WriteMessage("\nTAHF: " + exception.Message);
            }
        }

        // Callable from AutoLISP: (TA_GET_CURRENT_FILTER_LAYERS) returns
        // ("Layer 1" "Layer 2" ...), or nil outside a Group Filter.
        [LispFunction("TA_GET_CURRENT_FILTER_LAYERS")]
        public static object GetCurrentFilterLayersForLisp(ResultBuffer arguments)
        {
            Document document = Application.DocumentManager.MdiActiveDocument;
            if (document == null ||
                !(document.Database.LayerFilters.Current is LayerGroup))
                return new TypedValue((int)LispDataType.Nil);

            string[] layers = GetCurrentFilterLayerNames(document.Database, false);
            if (layers.Length == 0)
                return new TypedValue((int)LispDataType.Nil);

            ResultBuffer result = new ResultBuffer();
            foreach (string layer in layers)
                result.Add(new TypedValue((int)LispDataType.Text, layer));
            return result;
        }

        [CommandMethod("TAFILTERFROMOBJECTNET")]
        public static void SelectFilterForLayer()
        {
            Document document = Application.DocumentManager.MdiActiveDocument;
            if (document == null) return;

            Editor editor = document.Editor;
            PromptStringOptions options = new PromptStringOptions("\nObject layer name: ");
            options.AllowSpaces = true;
            PromptResult input = editor.GetString(options);
            if (input.Status != PromptStatus.OK || string.IsNullOrWhiteSpace(input.StringResult))
                return;

            Database database = document.Database;
            try
            {
                ObjectId layerId;
                using (Transaction transaction = database.TransactionManager.StartTransaction())
                {
                    LayerTable table = (LayerTable)transaction.GetObject(
                        database.LayerTableId, OpenMode.ForRead);
                    if (!table.Has(input.StringResult))
                    {
                        editor.WriteMessage("\nTAHF: layer not found: " + input.StringResult);
                        return;
                    }
                    layerId = table[input.StringResult];
                }

                LayerFilterTree tree = database.LayerFilters;
                List<Match> allMatches = new List<Match>();
                FindMatches(tree.Root, layerId, new List<LayerFilter>(), allMatches);
                if (allMatches.Count == 0)
                {
                    editor.WriteMessage("\nTAHF: layer '" + input.StringResult
                        + "' is not a member of any saved Group Filter.");
                    return;
                }

                // The drawing's hierarchy is All > root > main group > component
                // > optional role folders. Prefer the component folder (depth 3).
                int deepest = 0;
                foreach (Match match in allMatches)
                    if (match.Depth > deepest) deepest = match.Depth;

                List<Match> choices = new List<Match>();
                HashSet<string> seenPaths = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                foreach (Match match in allMatches)
                    if (match.Depth == deepest && seenPaths.Add(match.Path))
                        choices.Add(match);

                Match chosen = ChooseMatch(editor, choices);
                if (chosen == null) return;

                database.LayerFilters = new LayerFilterTree(tree.Root, chosen.Filter);
                editor.WriteMessage("\nTAHF: layer '" + input.StringResult
                    + "' -> Layer Filter: " + chosen.Path);
            }
            catch (System.Exception exception)
            {
                editor.WriteMessage("\nTAHF: " + exception.Message);
            }
        }

        private static void FindMatches(LayerFilter filter, ObjectId layerId,
            List<LayerFilter> path, List<Match> results)
        {
            path.Add(filter);
            LayerGroup group = filter as LayerGroup;
            if (group != null && group.LayerIds.Contains(layerId))
            {
                int targetIndex = Math.Min(3, path.Count - 1);
                List<string> names = new List<string>();
                for (int i = 0; i <= targetIndex; i++) names.Add(path[i].Name);
                results.Add(new Match
                {
                    Filter = path[targetIndex],
                    Path = string.Join(" > ", names.ToArray()),
                    Depth = targetIndex
                });
            }

            foreach (LayerFilter child in filter.NestedFilters)
                FindMatches(child, layerId, path, results);
            path.RemoveAt(path.Count - 1);
        }

        private static Match ChooseMatch(Editor editor, List<Match> choices)
        {
            if (choices.Count == 1) return choices[0];

            editor.WriteMessage("\nTAHF: this layer belongs to several filter folders:");
            for (int i = 0; i < choices.Count; i++)
                editor.WriteMessage("\n  " + (i + 1) + " = " + choices[i].Path);

            while (true)
            {
                PromptIntegerResult answer = editor.GetInteger("\nChoose folder number: ");
                if (answer.Status != PromptStatus.OK) return null;
                if (answer.Value >= 1 && answer.Value <= choices.Count)
                    return choices[answer.Value - 1];
                editor.WriteMessage("\nTAHF: choose one of the listed numbers.");
            }
        }
    }
}

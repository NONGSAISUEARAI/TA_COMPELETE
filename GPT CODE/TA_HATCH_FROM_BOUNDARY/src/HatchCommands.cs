using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text.Json;
using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.Colors;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.EditorInput;
using Autodesk.AutoCAD.LayerManager;
using Autodesk.AutoCAD.Runtime;

namespace TA.HatchFromBoundary
{
    public sealed class Commands
    {
        private const string AnnotationScaleCollection = "ACDB_ANNOTATIONSCALES";
        private const string PresetFileName = "TA_HATCH_PRESETS.json";
        private static LispHatchPreset _pendingLispPreset;
        private static string _lastFilterPatternLabel = string.Empty;

        private sealed class PresetFile
        {
            public int Version { get; set; } = 1;
            public string DefaultPreset { get; set; } = "1:50";
            public List<AnnotationPreset> Presets { get; set; } = new List<AnnotationPreset>();
        }

        private sealed class AnnotationPreset
        {
            public string Name { get; set; } = string.Empty;
            public bool Annotative { get; set; }
            public List<ScalePreset> Scales { get; set; } = new List<ScalePreset>();
        }

        private sealed class ScalePreset
        {
            public string Name { get; set; } = string.Empty;
            public double PaperUnits { get; set; }
            public double DrawingUnits { get; set; }
        }

        private sealed class LispHatchPreset
        {
            public string Name { get; set; } = string.Empty;
            public bool UseCurrentFilterSource { get; set; }
            public string PatternName { get; set; } = string.Empty;
            public HatchPatternType PatternType { get; set; }
            public double PatternScale { get; set; }
            public double PatternAngleRadians { get; set; }
            public string LayerName { get; set; } = string.Empty;
            public string ColorSpec { get; set; } = "BYLAYER";
            public AnnotationPreset Annotation { get; set; } = new AnnotationPreset();
            public List<PatternChoice> PatternChoices { get; set; } = new List<PatternChoice>();
            public string LastPatternLabel { get; set; } = string.Empty;
        }

        private sealed class PatternChoice
        {
            public string Label { get; set; } = string.Empty;
            public HatchPatternType PatternType { get; set; }
            public string PatternName { get; set; } = string.Empty;
            public double PatternScale { get; set; }
            public double PatternAngleRadians { get; set; }
        }

        private sealed class HatchItem
        {
            public ObjectId Id { get; set; }
            public string Layer { get; set; } = string.Empty;
            public string Pattern { get; set; } = string.Empty;
            public double Scale { get; set; }
            public double Angle { get; set; }
            public string Handle { get; set; } = string.Empty;
            public bool Annotative { get; set; }
        }

        private sealed class HatchTemplate
        {
            public ObjectId LayerId { get; set; }
            public Autodesk.AutoCAD.Colors.Color Color { get; set; }
            public Autodesk.AutoCAD.Colors.Color BackgroundColor { get; set; }
            public Autodesk.AutoCAD.Colors.Transparency Transparency { get; set; }
            public ObjectId LinetypeId { get; set; }
            public double LinetypeScale { get; set; }
            public LineWeight LineWeight { get; set; }
            public ObjectId MaterialId { get; set; }
            public HatchPatternType PatternType { get; set; }
            public string PatternName { get; set; } = string.Empty;
            public double PatternScale { get; set; }
            public double PatternAngle { get; set; }
            public bool PatternDouble { get; set; }
            public double PatternSpace { get; set; }
            public HatchStyle HatchStyle { get; set; }
            public Autodesk.AutoCAD.Geometry.Vector3d Normal { get; set; }
            public double Elevation { get; set; }
            public Autodesk.AutoCAD.Geometry.Point2d Origin { get; set; }
        }

        // Called by TA_HATCH_FROM_BOUNDARY.lsp immediately before the managed
        // command. Arguments:
        // name, pattern, pattern-type, pattern-scale, angle-degrees,
        // layer, color, annotative(0/1), packed scales.
        [LispFunction("TA_HATCH_SET_LISP_PRESET_V6")]
        public static ResultBuffer SetLispPreset(ResultBuffer arguments)
        {
            try
            {
                TypedValue[] values = arguments == null
                    ? Array.Empty<TypedValue>()
                    : arguments.AsArray();
                if (values.Length < 9)
                    throw new ArgumentException(
                        "TA_HATCH_SET_LISP_PRESET_V6 requires 9 arguments.");

                string patternTypeText = TextValue(values[2]);
                string layerName = TextValue(values[5]);
                bool useCurrentFilterSource = layerName.Equals(
                    "CURRENT-FILTER", StringComparison.OrdinalIgnoreCase);
                HatchPatternType patternType;
                if (!Enum.TryParse(patternTypeText, true, out patternType))
                    throw new ArgumentException("Invalid Hatch pattern type: " + patternTypeText);

                bool annotative = IntValue(values[7]) != 0;
                AnnotationPreset annotation = new AnnotationPreset
                {
                    Name = TextValue(values[0]),
                    Annotative = annotative,
                    Scales = annotative
                        ? ParsePackedScales(TextValue(values[8]))
                        : new List<ScalePreset>()
                };
                if (annotative && annotation.Scales.Count == 0)
                    throw new ArgumentException(
                        "Annotative LISP preset requires at least one scale.");

                _pendingLispPreset = new LispHatchPreset
                {
                    Name = TextValue(values[0]),
                    UseCurrentFilterSource = useCurrentFilterSource,
                    PatternName = TextValue(values[1]),
                    PatternType = patternType,
                    PatternScale = PositiveDouble(values[3], "pattern scale"),
                    PatternAngleRadians = DoubleValue(values[4]) * Math.PI / 180.0,
                    LayerName = layerName,
                    ColorSpec = TextValue(values[6]),
                    Annotation = annotation
                };
                if (string.IsNullOrWhiteSpace(_pendingLispPreset.Name) ||
                    string.IsNullOrWhiteSpace(_pendingLispPreset.PatternName) ||
                    string.IsNullOrWhiteSpace(_pendingLispPreset.LayerName))
                    throw new ArgumentException(
                        "Preset name, hatch pattern and layer cannot be empty.");

                return new ResultBuffer(new TypedValue((int)LispDataType.T_atom));
            }
            catch (System.Exception exception)
            {
                _pendingLispPreset = null;
                Document document = Application.DocumentManager.MdiActiveDocument;
                document?.Editor.WriteMessage("\nTAHB LISP preset error: {0}", exception.Message);
                return new ResultBuffer(new TypedValue((int)LispDataType.Nil));
            }
        }

        [LispFunction("TA_HATCH_SET_FILTER_PRESET_V6")]
        public static ResultBuffer SetFilterPreset(ResultBuffer arguments)
        {
            try
            {
                TypedValue[] values = arguments == null
                    ? Array.Empty<TypedValue>()
                    : arguments.AsArray();
                if (values.Length < 6)
                    throw new ArgumentException(
                        "TA_HATCH_SET_FILTER_PRESET_V6 requires 6 arguments.");

                string name = TextValue(values[0]);
                bool annotative = IntValue(values[2]) != 0;
                List<PatternChoice> choices = ParsePackedPatternChoices(TextValue(values[4]));
                if (choices.Count == 0)
                    throw new ArgumentException("Current Filter preset requires Pattern Presets.");

                AnnotationPreset annotation = new AnnotationPreset
                {
                    Name = name,
                    Annotative = annotative,
                    Scales = annotative
                        ? ParsePackedScales(TextValue(values[3]))
                        : new List<ScalePreset>()
                };
                if (annotative && annotation.Scales.Count == 0)
                    throw new ArgumentException(
                        "Annotative Current Filter preset requires at least one scale.");

                _pendingLispPreset = new LispHatchPreset
                {
                    Name = name,
                    UseCurrentFilterSource = true,
                    LayerName = "CURRENT-FILTER",
                    ColorSpec = TextValue(values[1]),
                    Annotation = annotation,
                    PatternChoices = choices,
                    LastPatternLabel = TextValue(values[5])
                };
                return new ResultBuffer(new TypedValue((int)LispDataType.T_atom));
            }
            catch (System.Exception exception)
            {
                _pendingLispPreset = null;
                Document document = Application.DocumentManager.MdiActiveDocument;
                document?.Editor.WriteMessage("\nTAHB Filter preset error: {0}", exception.Message);
                return new ResultBuffer(new TypedValue((int)LispDataType.Nil));
            }
        }

        [LispFunction("TA_HATCH_CLEAR_LISP_PRESET_V6")]
        public static ResultBuffer ClearLispPreset(ResultBuffer arguments)
        {
            _pendingLispPreset = null;
            return new ResultBuffer(new TypedValue((int)LispDataType.T_atom));
        }

        [LispFunction("TA_HATCH_GET_LAST_PATTERN_V6")]
        public static ResultBuffer GetLastPattern(ResultBuffer arguments)
        {
            if (string.IsNullOrWhiteSpace(_lastFilterPatternLabel))
                return new ResultBuffer(new TypedValue((int)LispDataType.Nil));
            return new ResultBuffer(new TypedValue(
                (int)LispDataType.Text, _lastFilterPatternLabel));
        }

        [CommandMethod("TAHATCHBOUNDARYNET6",
            CommandFlags.Modal | CommandFlags.UsePickSet)]
        public static void CreateHatchFromBoundary()
        {
            Document document = Application.DocumentManager.MdiActiveDocument;
            if (document == null) return;

            Editor editor = document.Editor;
            Database database = document.Database;

            try
            {
                LispHatchPreset lispPreset = _pendingLispPreset;
                _pendingLispPreset = null;
                bool useCurrentFilterPreset = lispPreset != null &&
                    lispPreset.UseCurrentFilterSource;
                bool useFullLispPreset = lispPreset != null &&
                    !lispPreset.UseCurrentFilterSource;
                LayerFilter currentFilter = null;
                HatchItem selectedHatch = null;
                AnnotationPreset annotationPreset = null;
                string sourceDescription;

                if (useFullLispPreset)
                {
                    annotationPreset = lispPreset.Annotation;
                    sourceDescription = "LISP preset '" + lispPreset.Name + "'";
                    editor.WriteMessage(
                        "\nTAHB LISP preset: {0} | Hatch: {1} | Layer: {2} | Color: {3} | Scales: {4}",
                        lispPreset.Name,
                        lispPreset.PatternName,
                        lispPreset.LayerName,
                        lispPreset.ColorSpec,
                        lispPreset.Annotation.Annotative
                            ? string.Join(", ", lispPreset.Annotation.Scales.Select(scale => scale.Name))
                            : "Non-annotative");
                }
                else
                {
                    currentFilter = database.LayerFilters.Current;
                    if (currentFilter == null)
                    {
                        editor.WriteMessage("\nTAHB: ไม่พบ Current Layer Filter.");
                        return;
                    }

                    if (useCurrentFilterPreset)
                    {
                        // Preset 0 does not depend on an existing Hatch. Only
                        // its destination layer is resolved from the selected
                        // Layer Filter folder.
                        lispPreset.LayerName = ResolveLayerNameFromCurrentFilter(
                            database, currentFilter, editor);
                        annotationPreset = lispPreset.Annotation;
                        sourceDescription = "Current Filter '" + currentFilter.Name +
                            "' / LISP preset '" + lispPreset.Name + "'";
                        editor.WriteMessage(
                            "\nTAHB Filter preset: {0} | Pattern presets: {1} | Layer: {2} | Color: {3} | Scales: {4}",
                            lispPreset.Name,
                            lispPreset.PatternChoices.Count,
                            lispPreset.LayerName,
                            lispPreset.ColorSpec,
                            annotationPreset.Annotative
                                ? string.Join(", ", annotationPreset.Scales.Select(scale => scale.Name))
                                : "Non-annotative");
                    }
                    else
                    {
                        List<HatchItem> items = FindHatchesInCurrentFilter(database, currentFilter);
                        if (items.Count == 0)
                        {
                            editor.WriteMessage(
                                "\nTAHB: Filter '{0}' ไม่มี Hatch ในพื้นที่เขียนปัจจุบัน.",
                                currentFilter.Name);
                            return;
                        }

                        editor.WriteMessage("\nTAHB: Current Layer Filter = {0} ({1} hatch)",
                            currentFilter.Name, items.Count);
                        for (int i = 0; i < items.Count; i++)
                        {
                            HatchItem item = items[i];
                            editor.WriteMessage(
                                "\n  {0} = Layer: {1} | Pattern: {2} | Scale: {3} | Angle: {4}° | Handle: {5}{6}",
                                i + 1,
                                item.Layer,
                                item.Pattern,
                                item.Scale.ToString("0.########", CultureInfo.InvariantCulture),
                                item.Angle.ToString("0.###", CultureInfo.InvariantCulture),
                                item.Handle,
                                item.Annotative ? " | Annotative" : string.Empty);
                        }

                        int hatchIndex = PromptForIndex(editor,
                            "\nเลือกหมายเลข Hatch ต้นแบบ", items.Count, 1);
                        if (hatchIndex < 0) return;
                        selectedHatch = items[hatchIndex];

                        PresetFile presetFile = LoadPresets(editor);
                        if (presetFile.Presets.Count == 0)
                        {
                            editor.WriteMessage("\nTAHB: preset file ไม่มีรายการที่ใช้งานได้.");
                            return;
                        }

                        editor.WriteMessage("\nAnnotation Scale presets:");
                        for (int i = 0; i < presetFile.Presets.Count; i++)
                        {
                            AnnotationPreset preset = presetFile.Presets[i];
                            string scales = preset.Annotative
                                ? string.Join(", ", preset.Scales.Select(scale => scale.Name))
                                : "Non-annotative";
                            editor.WriteMessage("\n  {0} = {1} [{2}]", i + 1, preset.Name, scales);
                        }

                        int defaultPreset = FindDefaultPresetIndex(presetFile);
                        int presetIndex = PromptForIndex(editor,
                            "\nเลือก Annotation Scale preset", presetFile.Presets.Count,
                            defaultPreset + 1);
                        if (presetIndex < 0) return;
                        annotationPreset = presetFile.Presets[presetIndex];
                        sourceDescription = "Filter '" + currentFilter.Name + "'";
                    }
                }

                // AutoCAD Pickfirst / AutoLISP (ssget "_I") equivalent.
                // Consume a valid implied selection before prompting manually.
                List<ObjectId> boundaryIds = new List<ObjectId>();
                PromptSelectionResult implied = editor.SelectImplied();
                if (implied.Status == PromptStatus.OK && implied.Value != null)
                {
                    boundaryIds = ValidateBoundaries(
                        database, editor, implied.Value.GetObjectIds());
                    editor.SetImpliedSelection(Array.Empty<ObjectId>());
                    if (boundaryIds.Count > 0)
                        editor.WriteMessage(
                            "\nTAHB: ใช้ Pickfirst selection {0} boundary.",
                            boundaryIds.Count);
                }

                if (boundaryIds.Count == 0)
                {
                    PromptSelectionOptions selectionOptions = new PromptSelectionOptions
                    {
                        MessageForAdding = "\nเลือก closed boundary (แต่ละวัตถุจะสร้าง 1 Hatch): ",
                        MessageForRemoval = "\nRemove boundary: ",
                        AllowDuplicates = false
                    };
                    SelectionFilter selectionFilter = new SelectionFilter(new[]
                    {
                        new TypedValue((int)DxfCode.Start,
                            "LWPOLYLINE,POLYLINE,CIRCLE,ELLIPSE,SPLINE")
                    });
                    PromptSelectionResult selection = editor.GetSelection(
                        selectionOptions, selectionFilter);
                    if (selection.Status != PromptStatus.OK || selection.Value == null)
                        return;

                    boundaryIds = ValidateBoundaries(
                        database, editor, selection.Value.GetObjectIds());
                    if (boundaryIds.Count == 0)
                    {
                        editor.WriteMessage("\nTAHB: ไม่มี closed boundary ที่ใช้งานได้.");
                        return;
                    }
                }

                if (useCurrentFilterPreset)
                {
                    PatternChoice pattern = lispPreset.PatternChoices.Count == 1
                        ? lispPreset.PatternChoices[0]
                        : ChoosePatternPreset(editor, lispPreset);
                    if (pattern == null) return;
                    if (lispPreset.PatternChoices.Count == 1)
                        editor.WriteMessage(
                            "\nTAHB: ใช้ Hatch ที่เลือกจาก LISP: {0} | Pattern: {1} | Scale: {2}",
                            pattern.Label,
                            pattern.PatternName,
                            pattern.PatternScale.ToString(
                                "0.########", CultureInfo.InvariantCulture));
                    lispPreset.PatternType = pattern.PatternType;
                    lispPreset.PatternName = pattern.PatternName;
                    lispPreset.PatternScale = pattern.PatternScale;
                    lispPreset.PatternAngleRadians = pattern.PatternAngleRadians;
                    _lastFilterPatternLabel = pattern.Label;
                }

                int created = (useFullLispPreset || useCurrentFilterPreset)
                    ? CreateHatchesFromLispPreset(
                        database, editor, boundaryIds, lispPreset)
                    : CreateHatches(
                        database, editor, selectedHatch.Id, boundaryIds, annotationPreset);

                editor.WriteMessage(
                    "\nTAHB: สร้าง {0} associative hatch จาก {1} ด้วย Annotation preset '{2}'.",
                    created, sourceDescription, annotationPreset.Name);
            }
            catch (System.Exception exception)
            {
                editor.WriteMessage("\nTAHB error: {0}", exception.Message);
            }
        }

        [CommandMethod("TAHATCHPRESETSNET6", CommandFlags.Modal)]
        public static void ListPresets()
        {
            Document document = Application.DocumentManager.MdiActiveDocument;
            if (document == null) return;
            Editor editor = document.Editor;

            try
            {
                PresetFile file = LoadPresets(editor);
                editor.WriteMessage("\nTAHB preset file: {0}", GetPresetPath());
                for (int i = 0; i < file.Presets.Count; i++)
                {
                    AnnotationPreset preset = file.Presets[i];
                    string values = preset.Annotative
                        ? string.Join(", ", preset.Scales.Select(scale =>
                            string.Format(CultureInfo.InvariantCulture,
                                "{0} ({1}:{2})", scale.Name,
                                scale.PaperUnits, scale.DrawingUnits)))
                        : "Non-annotative";
                    editor.WriteMessage("\n  {0}. {1} = {2}{3}", i + 1, preset.Name,
                        values,
                        string.Equals(preset.Name, file.DefaultPreset,
                            StringComparison.OrdinalIgnoreCase) ? " [default]" : string.Empty);
                }
            }
            catch (System.Exception exception)
            {
                editor.WriteMessage("\nTAHB preset error: {0}", exception.Message);
            }
        }

        private static string ResolveLayerNameFromCurrentFilter(
            Database database, LayerFilter currentFilter, Editor editor)
        {
            List<string> allNames = new List<string>();
            List<string> writableNames = new List<string>();
            string currentLayerName = null;

            using (Transaction transaction = database.TransactionManager.StartTransaction())
            {
                LayerTable table = (LayerTable)transaction.GetObject(
                    database.LayerTableId, OpenMode.ForRead);
                foreach (ObjectId id in table)
                {
                    LayerTableRecord layer = (LayerTableRecord)transaction.GetObject(
                        id, OpenMode.ForRead);
                    if (!FilterTreeMatchesLayer(currentFilter, layer)) continue;

                    allNames.Add(layer.Name);
                    if (!layer.IsDependent) writableNames.Add(layer.Name);
                    if (id == database.Clayer) currentLayerName = layer.Name;
                }
            }

            if (allNames.Count == 0)
                throw new InvalidOperationException(
                    "Current Layer Filter '" + currentFilter.Name + "' ไม่มี Layer สมาชิก.");

            if (!string.IsNullOrWhiteSpace(currentLayerName))
            {
                editor.WriteMessage(
                    "\nTAHB: ใช้ Current Layer '{0}' ซึ่งอยู่ใน Current Filter.",
                    currentLayerName);
                return currentLayerName;
            }

            writableNames.Sort(StringComparer.CurrentCultureIgnoreCase);
            allNames.Sort(StringComparer.CurrentCultureIgnoreCase);
            string hatchLayer = writableNames.FirstOrDefault(name =>
                name.IndexOf("HATCH", StringComparison.OrdinalIgnoreCase) >= 0);
            if (!string.IsNullOrWhiteSpace(hatchLayer))
            {
                editor.WriteMessage(
                    "\nTAHB: Current Layer ไม่ได้อยู่ใน Filter; ใช้ Layer Hatch '{0}'.",
                    hatchLayer);
                return hatchLayer;
            }

            string selected = writableNames.Count > 0 ? writableNames[0] : allNames[0];
            editor.WriteMessage(
                "\nTAHB: Current Layer ไม่ได้อยู่ใน Filter; ใช้ Layer แรก '{0}'.",
                selected);
            return selected;
        }

        private static bool FilterTreeMatchesLayer(
            LayerFilter filter, LayerTableRecord layer)
        {
            if (filter.Filter(layer)) return true;
            foreach (LayerFilter child in filter.NestedFilters)
                if (FilterTreeMatchesLayer(child, layer)) return true;
            return false;
        }

        private static List<HatchItem> FindHatchesInCurrentFilter(
            Database database, LayerFilter currentFilter)
        {
            List<HatchItem> result = new List<HatchItem>();
            using (Transaction transaction = database.TransactionManager.StartTransaction())
            {
                HashSet<ObjectId> matchingLayers = new HashSet<ObjectId>();
                LayerTable layerTable = (LayerTable)transaction.GetObject(
                    database.LayerTableId, OpenMode.ForRead);
                foreach (ObjectId layerId in layerTable)
                {
                    LayerTableRecord layer = (LayerTableRecord)transaction.GetObject(
                        layerId, OpenMode.ForRead);
                    if (currentFilter.Filter(layer)) matchingLayers.Add(layerId);
                }

                BlockTableRecord space = (BlockTableRecord)transaction.GetObject(
                    database.CurrentSpaceId, OpenMode.ForRead);
                foreach (ObjectId id in space)
                {
                    Hatch hatch = transaction.GetObject(id, OpenMode.ForRead) as Hatch;
                    if (hatch == null || !matchingLayers.Contains(hatch.LayerId)) continue;

                    result.Add(new HatchItem
                    {
                        Id = id,
                        Layer = hatch.Layer,
                        Pattern = hatch.IsGradient ? "Gradient: " + hatch.GradientName : hatch.PatternName,
                        Scale = hatch.IsGradient ? 1.0 : hatch.PatternScale,
                        Angle = hatch.IsGradient
                            ? hatch.GradientAngle * 180.0 / Math.PI
                            : hatch.PatternAngle * 180.0 / Math.PI,
                        Handle = hatch.Handle.ToString(),
                        Annotative = hatch.Annotative == AnnotativeStates.True
                    });
                }
            }

            result.Sort((left, right) =>
            {
                int compare = StringComparer.CurrentCultureIgnoreCase.Compare(left.Layer, right.Layer);
                if (compare != 0) return compare;
                compare = StringComparer.CurrentCultureIgnoreCase.Compare(left.Pattern, right.Pattern);
                if (compare != 0) return compare;
                return StringComparer.OrdinalIgnoreCase.Compare(left.Handle, right.Handle);
            });
            return result;
        }

        private static int PromptForIndex(Editor editor, string message, int count, int defaultNumber)
        {
            PromptIntegerOptions options = new PromptIntegerOptions(
                string.Format(CultureInfo.InvariantCulture, "{0} <{1}>: ", message, defaultNumber))
            {
                AllowNone = true,
                AllowNegative = false,
                AllowZero = false,
                LowerLimit = 1,
                UpperLimit = count,
                DefaultValue = defaultNumber,
                UseDefaultValue = true
            };
            PromptIntegerResult answer = editor.GetInteger(options);
            if (answer.Status == PromptStatus.None) return defaultNumber - 1;
            return answer.Status == PromptStatus.OK ? answer.Value - 1 : -1;
        }

        private static PatternChoice ChoosePatternPreset(
            Editor editor, LispHatchPreset preset)
        {
            if (preset.PatternChoices == null || preset.PatternChoices.Count == 0)
                throw new InvalidOperationException("Preset 0 ไม่มี Pattern Preset.");

            editor.WriteMessage("\nPattern presets:");
            for (int i = 0; i < preset.PatternChoices.Count; i++)
            {
                PatternChoice item = preset.PatternChoices[i];
                editor.WriteMessage(
                    "\n  {0} = {1} | Pattern: {2} | Scale: {3} | Angle: {4}°",
                    i + 1,
                    item.Label,
                    item.PatternName,
                    item.PatternScale.ToString("0.########", CultureInfo.InvariantCulture),
                    (item.PatternAngleRadians * 180.0 / Math.PI)
                        .ToString("0.###", CultureInfo.InvariantCulture));
            }

            string preferred = !string.IsNullOrWhiteSpace(preset.LastPatternLabel)
                ? preset.LastPatternLabel
                : _lastFilterPatternLabel;
            int defaultIndex = preset.PatternChoices.FindIndex(item => string.Equals(
                item.Label, preferred, StringComparison.OrdinalIgnoreCase));
            if (defaultIndex < 0) defaultIndex = 0;

            int selected = PromptForIndex(editor,
                "\nเลือก Pattern preset", preset.PatternChoices.Count, defaultIndex + 1);
            return selected >= 0 ? preset.PatternChoices[selected] : null;
        }

        private static List<ObjectId> ValidateBoundaries(
            Database database, Editor editor, IEnumerable<ObjectId> selectedIds)
        {
            List<ObjectId> result = new List<ObjectId>();
            using (Transaction transaction = database.TransactionManager.StartTransaction())
            {
                foreach (ObjectId id in selectedIds)
                {
                    Curve curve = transaction.GetObject(id, OpenMode.ForRead) as Curve;
                    if (curve == null || !curve.Closed)
                    {
                        editor.WriteMessage("\nTAHB: ข้าม Handle {0} เพราะ boundary ไม่ปิด.",
                            id.Handle.ToString());
                        continue;
                    }
                    if (id.Database != database || curve.BlockId != database.CurrentSpaceId)
                    {
                        editor.WriteMessage("\nTAHB: ข้าม Handle {0} เพราะไม่ได้อยู่ใน current space.",
                            id.Handle.ToString());
                        continue;
                    }
                    result.Add(id);
                }
            }
            return result;
        }

        private static int CreateHatchesFromLispPreset(
            Database database,
            Editor editor,
            IList<ObjectId> boundaryIds,
            LispHatchPreset preset)
        {
            int created = 0;
            using (Transaction transaction = database.TransactionManager.StartTransaction())
            {
                ObjectId layerId = EnsureLayer(database, transaction, preset.LayerName);
                Color color = ParseColor(preset.ColorSpec);
                BlockTableRecord space = (BlockTableRecord)transaction.GetObject(
                    database.CurrentSpaceId, OpenMode.ForWrite);

                List<AnnotationScale> contexts = new List<AnnotationScale>();
                if (preset.Annotation.Annotative)
                {
                    ObjectContextCollection collection = database.ObjectContextManager
                        .GetContextCollection(AnnotationScaleCollection);
                    foreach (ScalePreset scale in preset.Annotation.Scales)
                        contexts.Add(EnsureAnnotationScale(collection, scale, editor));
                }

                foreach (ObjectId boundaryId in boundaryIds)
                {
                    Hatch hatch = new Hatch();
                    hatch.SetDatabaseDefaults(database);
                    space.AppendEntity(hatch);
                    transaction.AddNewlyCreatedDBObject(hatch, true);

                    hatch.LayerId = layerId;
                    hatch.Color = color;
                    hatch.HatchStyle = HatchStyle.Normal;
                    ApplyPattern(hatch, preset.PatternType, preset.PatternName,
                        preset.PatternScale, preset.PatternAngleRadians);
                    hatch.Associative = true;
                    hatch.AppendLoop(HatchLoopTypes.External,
                        new ObjectIdCollection(new[] { boundaryId }));

                    if (preset.Annotation.Annotative)
                    {
                        hatch.Annotative = AnnotativeStates.True;
                        foreach (AnnotationScale context in contexts)
                            if (!hatch.HasContext(context)) hatch.AddContext(context);
                    }
                    else
                    {
                        hatch.Annotative = AnnotativeStates.False;
                    }

                    hatch.EvaluateHatch(true);
                    created++;
                }

                transaction.Commit();
            }
            return created;
        }

        private static ObjectId EnsureLayer(
            Database database, Transaction transaction, string layerName)
        {
            LayerTable table = (LayerTable)transaction.GetObject(
                database.LayerTableId, OpenMode.ForRead);
            if (table.Has(layerName)) return table[layerName];

            table.UpgradeOpen();
            LayerTableRecord layer = new LayerTableRecord { Name = layerName };
            ObjectId id = table.Add(layer);
            transaction.AddNewlyCreatedDBObject(layer, true);
            return id;
        }

        private static Color ParseColor(string specification)
        {
            string value = (specification ?? string.Empty).Trim();
            if (value.Equals("BYLAYER", StringComparison.OrdinalIgnoreCase))
                return Color.FromColorIndex(ColorMethod.ByLayer, 256);
            if (value.Equals("BYBLOCK", StringComparison.OrdinalIgnoreCase))
                return Color.FromColorIndex(ColorMethod.ByBlock, 0);

            if (value.StartsWith("ACI:", StringComparison.OrdinalIgnoreCase))
            {
                int index;
                if (!int.TryParse(value.Substring(4), NumberStyles.Integer,
                        CultureInfo.InvariantCulture, out index) || index < 1 || index > 255)
                    throw new ArgumentException("Invalid ACI color: " + specification);
                return Color.FromColorIndex(ColorMethod.ByAci, (short)index);
            }

            if (value.StartsWith("RGB:", StringComparison.OrdinalIgnoreCase))
            {
                string[] parts = value.Substring(4)
                    .Split(new[] { ',', ':' }, StringSplitOptions.RemoveEmptyEntries);
                if (parts.Length != 3)
                    throw new ArgumentException("RGB color must be RGB:R,G,B.");
                byte red = ParseByte(parts[0], specification);
                byte green = ParseByte(parts[1], specification);
                byte blue = ParseByte(parts[2], specification);
                return Color.FromRgb(red, green, blue);
            }

            throw new ArgumentException(
                "Color must be BYLAYER, BYBLOCK, ACI:n or RGB:r,g,b: " + specification);
        }

        private static byte ParseByte(string text, string original)
        {
            byte value;
            if (!byte.TryParse(text.Trim(), NumberStyles.Integer,
                    CultureInfo.InvariantCulture, out value))
                throw new ArgumentException("Invalid RGB color: " + original);
            return value;
        }

        private static void ApplyPattern(
            Hatch hatch,
            HatchPatternType patternType,
            string patternName,
            double patternScale,
            double patternAngle)
        {
            if (patternType == HatchPatternType.UserDefined)
            {
                hatch.PatternAngle = patternAngle;
                hatch.PatternSpace = patternScale;
                hatch.PatternDouble = false;
                hatch.SetHatchPattern(patternType, patternName);
            }
            else
            {
                hatch.SetHatchPattern(patternType, patternName);
                hatch.PatternScale = patternScale;
                hatch.PatternAngle = patternAngle;
            }
        }

        private static int CreateHatches(
            Database database,
            Editor editor,
            ObjectId sourceHatchId,
            IList<ObjectId> boundaryIds,
            AnnotationPreset preset)
        {
            int created = 0;
            using (Transaction transaction = database.TransactionManager.StartTransaction())
            {
                Hatch source = (Hatch)transaction.GetObject(sourceHatchId, OpenMode.ForRead);
                if (source.IsGradient)
                    throw new InvalidOperationException(
                        "รุ่นนี้รองรับ Hatch pattern แต่ยังไม่รองรับ Gradient hatch เป็นต้นแบบ.");

                HatchTemplate template = ReadTemplate(source);
                BlockTableRecord space = (BlockTableRecord)transaction.GetObject(
                    database.CurrentSpaceId, OpenMode.ForWrite);
                ObjectContextCollection annotationScales = null;
                List<AnnotationScale> contexts = new List<AnnotationScale>();
                if (preset.Annotative)
                {
                    if (preset.Scales == null || preset.Scales.Count == 0)
                        throw new InvalidDataException(
                            "Annotative preset ต้องมี scale อย่างน้อยหนึ่งรายการ.");
                    annotationScales = database.ObjectContextManager
                        .GetContextCollection(AnnotationScaleCollection);
                    foreach (ScalePreset scale in preset.Scales)
                        contexts.Add(EnsureAnnotationScale(annotationScales, scale, editor));
                }

                foreach (ObjectId boundaryId in boundaryIds)
                {
                    Hatch hatch = new Hatch();
                    hatch.SetDatabaseDefaults(database);
                    space.AppendEntity(hatch);
                    transaction.AddNewlyCreatedDBObject(hatch, true);

                    // AutoCAD requires an associative Hatch to be database-resident
                    // before Associative is enabled and before its first loop is added.
                    ApplyTemplate(hatch, template);
                    hatch.Associative = true;
                    hatch.AppendLoop(HatchLoopTypes.External,
                        new ObjectIdCollection(new[] { boundaryId }));

                    if (preset.Annotative)
                    {
                        hatch.Annotative = AnnotativeStates.True;
                        foreach (AnnotationScale context in contexts)
                            if (!hatch.HasContext(context)) hatch.AddContext(context);
                    }
                    else
                    {
                        hatch.Annotative = AnnotativeStates.False;
                    }

                    hatch.EvaluateHatch(true);
                    created++;
                }

                transaction.Commit();
            }
            return created;
        }

        private static HatchTemplate ReadTemplate(Hatch source)
        {
            return new HatchTemplate
            {
                LayerId = source.LayerId,
                Color = source.Color,
                BackgroundColor = source.BackgroundColor,
                Transparency = source.Transparency,
                LinetypeId = source.LinetypeId,
                LinetypeScale = source.LinetypeScale,
                LineWeight = source.LineWeight,
                MaterialId = source.MaterialId,
                PatternType = source.PatternType,
                PatternName = source.PatternName,
                PatternScale = source.PatternScale,
                PatternAngle = source.PatternAngle,
                PatternDouble = source.PatternDouble,
                PatternSpace = source.PatternSpace,
                HatchStyle = source.HatchStyle,
                Normal = source.Normal,
                Elevation = source.Elevation,
                Origin = source.Origin
            };
        }

        private static void ApplyTemplate(Hatch target, HatchTemplate source)
        {
            target.LayerId = source.LayerId;
            target.Color = source.Color;
            target.BackgroundColor = source.BackgroundColor;
            target.Transparency = source.Transparency;
            target.LinetypeId = source.LinetypeId;
            target.LinetypeScale = source.LinetypeScale;
            target.LineWeight = source.LineWeight;
            target.MaterialId = source.MaterialId;
            target.Normal = source.Normal;
            target.Elevation = source.Elevation;
            target.Origin = source.Origin;
            target.HatchStyle = source.HatchStyle;
            if (source.PatternType == HatchPatternType.UserDefined)
            {
                // User-defined spacing, angle and double-hatch settings form the
                // definition and must be assigned before SetHatchPattern.
                target.PatternAngle = source.PatternAngle;
                target.PatternDouble = source.PatternDouble;
                target.PatternSpace = source.PatternSpace;
                target.SetHatchPattern(source.PatternType, source.PatternName);
            }
            else
            {
                target.SetHatchPattern(source.PatternType, source.PatternName);
                target.PatternScale = source.PatternScale;
                target.PatternAngle = source.PatternAngle;
            }
        }

        private static AnnotationScale EnsureAnnotationScale(
            ObjectContextCollection collection, ScalePreset scale, Editor editor)
        {
            ValidateScalePreset(scale);
            AnnotationScale existing = collection.GetContext(scale.Name) as AnnotationScale;
            if (existing != null)
            {
                const double tolerance = 1e-9;
                if (Math.Abs(existing.PaperUnits - scale.PaperUnits) > tolerance ||
                    Math.Abs(existing.DrawingUnits - scale.DrawingUnits) > tolerance)
                {
                    editor.WriteMessage(
                        "\nTAHB warning: scale '{0}' มี ratio เดิม {1}:{2}; ใช้ค่าเดิมใน DWG แทน preset {3}:{4}.",
                        scale.Name,
                        existing.PaperUnits.ToString("0.########", CultureInfo.InvariantCulture),
                        existing.DrawingUnits.ToString("0.########", CultureInfo.InvariantCulture),
                        scale.PaperUnits.ToString("0.########", CultureInfo.InvariantCulture),
                        scale.DrawingUnits.ToString("0.########", CultureInfo.InvariantCulture));
                }
                return existing;
            }

            AnnotationScale created = new AnnotationScale
            {
                Name = scale.Name,
                PaperUnits = scale.PaperUnits,
                DrawingUnits = scale.DrawingUnits
            };
            collection.AddContext(created);
            return created;
        }

        private static void ValidateScalePreset(ScalePreset scale)
        {
            if (scale == null || string.IsNullOrWhiteSpace(scale.Name))
                throw new InvalidDataException("Annotation scale ต้องมี name.");
            if (!double.IsFinite(scale.PaperUnits) || scale.PaperUnits <= 0.0 ||
                !double.IsFinite(scale.DrawingUnits) || scale.DrawingUnits <= 0.0)
                throw new InvalidDataException(
                    "Annotation scale '" + scale.Name + "' ต้องมี paperUnits/drawingUnits มากกว่า 0.");
        }

        private static string TextValue(TypedValue value)
        {
            return Convert.ToString(value.Value, CultureInfo.InvariantCulture) ?? string.Empty;
        }

        private static int IntValue(TypedValue value)
        {
            return Convert.ToInt32(value.Value, CultureInfo.InvariantCulture);
        }

        private static double DoubleValue(TypedValue value)
        {
            double result = Convert.ToDouble(value.Value, CultureInfo.InvariantCulture);
            if (!double.IsFinite(result))
                throw new ArgumentException("Preset numeric value must be finite.");
            return result;
        }

        private static double PositiveDouble(TypedValue value, string fieldName)
        {
            double result = DoubleValue(value);
            if (result <= 0.0)
                throw new ArgumentException(fieldName + " must be greater than zero.");
            return result;
        }

        private static List<ScalePreset> ParsePackedScales(string packed)
        {
            List<ScalePreset> result = new List<ScalePreset>();
            foreach (string item in (packed ?? string.Empty)
                .Split(new[] { ';' }, StringSplitOptions.RemoveEmptyEntries))
            {
                string[] parts = item.Split('|');
                if (parts.Length != 3)
                    throw new ArgumentException(
                        "Scale must be packed as name|paperUnits|drawingUnits.");
                double paperUnits;
                double drawingUnits;
                if (!double.TryParse(parts[1], NumberStyles.Float,
                        CultureInfo.InvariantCulture, out paperUnits) ||
                    !double.TryParse(parts[2], NumberStyles.Float,
                        CultureInfo.InvariantCulture, out drawingUnits))
                    throw new ArgumentException("Invalid annotation scale ratio: " + item);

                ScalePreset scale = new ScalePreset
                {
                    Name = parts[0],
                    PaperUnits = paperUnits,
                    DrawingUnits = drawingUnits
                };
                ValidateScalePreset(scale);
                result.Add(scale);
            }
            return result;
        }

        private static List<PatternChoice> ParsePackedPatternChoices(string packed)
        {
            List<PatternChoice> result = new List<PatternChoice>();
            foreach (string item in (packed ?? string.Empty)
                .Split(new[] { ';' }, StringSplitOptions.RemoveEmptyEntries))
            {
                string[] parts = item.Split('|');
                if (parts.Length != 5)
                    throw new ArgumentException(
                        "Pattern preset must be label|type|name|scale|angleDegrees.");

                HatchPatternType patternType;
                if (!Enum.TryParse(parts[1], true, out patternType))
                    throw new ArgumentException("Invalid Hatch pattern type: " + parts[1]);
                double scale;
                double angle;
                if (!double.TryParse(parts[3], NumberStyles.Float,
                        CultureInfo.InvariantCulture, out scale) || scale <= 0.0 ||
                    !double.TryParse(parts[4], NumberStyles.Float,
                        CultureInfo.InvariantCulture, out angle) ||
                    !double.IsFinite(scale) || !double.IsFinite(angle))
                    throw new ArgumentException("Invalid Pattern scale/angle: " + item);
                if (string.IsNullOrWhiteSpace(parts[0]) ||
                    string.IsNullOrWhiteSpace(parts[2]))
                    throw new ArgumentException("Pattern preset label/name cannot be empty.");

                result.Add(new PatternChoice
                {
                    Label = parts[0],
                    PatternType = patternType,
                    PatternName = parts[2],
                    PatternScale = scale,
                    PatternAngleRadians = angle * Math.PI / 180.0
                });
            }
            return result;
        }

        private static PresetFile LoadPresets(Editor editor)
        {
            string path = GetPresetPath();
            if (!File.Exists(path))
            {
                PresetFile defaults = CreateDefaultPresets();
                try
                {
                    Directory.CreateDirectory(Path.GetDirectoryName(path) ?? string.Empty);
                    File.WriteAllText(path, JsonSerializer.Serialize(defaults,
                        new JsonSerializerOptions { WriteIndented = true }));
                    editor.WriteMessage("\nTAHB: สร้าง preset file เริ่มต้นที่ {0}", path);
                }
                catch (System.Exception exception)
                {
                    editor.WriteMessage(
                        "\nTAHB warning: เขียน preset file ไม่ได้ ({0}); ใช้ built-in presets.",
                        exception.Message);
                }
                return defaults;
            }

            PresetFile file = JsonSerializer.Deserialize<PresetFile>(
                File.ReadAllText(path),
                new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
            if (file == null) throw new InvalidDataException("อ่าน preset JSON ไม่สำเร็จ.");
            file.Presets ??= new List<AnnotationPreset>();
            foreach (AnnotationPreset preset in file.Presets)
            {
                preset.Name ??= string.Empty;
                preset.Scales ??= new List<ScalePreset>();
                foreach (ScalePreset scale in preset.Scales) ValidateScalePreset(scale);
            }
            file.Presets = file.Presets
                .Where(preset => !string.IsNullOrWhiteSpace(preset.Name))
                .ToList();
            return file;
        }

        private static int FindDefaultPresetIndex(PresetFile file)
        {
            int index = file.Presets.FindIndex(preset => string.Equals(
                preset.Name, file.DefaultPreset, StringComparison.OrdinalIgnoreCase));
            return index >= 0 ? index : 0;
        }

        private static string GetPresetPath()
        {
            string assemblyPath = Assembly.GetExecutingAssembly().Location;
            string directory = Path.GetDirectoryName(assemblyPath) ?? Environment.CurrentDirectory;
            return Path.Combine(directory, PresetFileName);
        }

        private static PresetFile CreateDefaultPresets()
        {
            double[] ratios = { 1, 2, 5, 10, 20, 25, 50, 100, 200 };
            PresetFile file = new PresetFile();
            file.Presets.Add(new AnnotationPreset
            {
                Name = "ไม่ใช้ Annotative",
                Annotative = false
            });
            foreach (double ratio in ratios)
            {
                string name = "1:" + ratio.ToString("0.########", CultureInfo.InvariantCulture);
                file.Presets.Add(new AnnotationPreset
                {
                    Name = name,
                    Annotative = true,
                    Scales = new List<ScalePreset>
                    {
                        new ScalePreset { Name = name, PaperUnits = 1.0, DrawingUnits = ratio }
                    }
                });
            }
            return file;
        }
    }
}

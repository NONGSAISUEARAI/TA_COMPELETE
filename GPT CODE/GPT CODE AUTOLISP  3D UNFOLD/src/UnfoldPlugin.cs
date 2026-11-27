using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.BoundaryRepresentation;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.EditorInput;
using Autodesk.AutoCAD.Geometry;
using Autodesk.AutoCAD.Runtime;
using App = Autodesk.AutoCAD.ApplicationServices.Core.Application;
using BrepEdge = Autodesk.AutoCAD.BoundaryRepresentation.Edge;
using BrepFace = Autodesk.AutoCAD.BoundaryRepresentation.Face;

[assembly: System.Runtime.Versioning.TargetFramework(".NETCoreApp,Version=v8.0")]
[assembly: ExtensionApplication(typeof(Ta3dUnfold.Plugin))]

namespace Ta3dUnfold {

public sealed class Plugin : IExtensionApplication {
    private const double DirectionTolerance = 0.9990;
    private const double Tiny = 1.0e-7;

    public void Initialize() { }
    public void Terminate() { }

    [CommandMethod("TA3DUNFOLDDLL", CommandFlags.Modal)]
    public static void UnfoldCommand() {
        Document doc = App.DocumentManager.MdiActiveDocument;
        if (doc == null) return;
        Editor ed = doc.Editor;
        Database db = doc.Database;

        var peo = new PromptEntityOptions("\nSelect constant-thickness folded 3D Solid: ");
        peo.SetRejectMessage("\nThe selected object must be a 3D Solid.");
        peo.AddAllowedClass(typeof(Solid3d), true);
        PromptEntityResult per = ed.GetEntity(peo);
        if (per.Status != PromptStatus.OK) return;

        double defaultThickness;
        List<Panel> panels;
        Vector3d axis;
        string report;
        try {
            using (Transaction tr = db.TransactionManager.StartTransaction()) {
                var solid = (Solid3d)tr.GetObject(per.ObjectId, OpenMode.ForRead);
                Analysis analysis = Analyze(solid);
                panels = analysis.Panels;
                axis = analysis.Axis;
                defaultThickness = analysis.Thickness;
                report = analysis.Report;
                tr.Commit();
            }
        } catch (System.Exception ex) {
            ed.WriteMessage("\nTA3DUNFOLD could not analyse this solid: " + OneLine(ex.Message));
            return;
        }

        ed.WriteMessage("\n" + report);
        if (panels.Count < 2) {
            ed.WriteMessage("\nAt least two paired plate panels are required.");
            return;
        }

        var pdoT = new PromptDoubleOptions(
            "\nSheet thickness <" + F(defaultThickness) + ">: ") {
            DefaultValue = defaultThickness,
            UseDefaultValue = true,
            AllowNegative = false,
            AllowZero = false
        };
        PromptDoubleResult pdrT = ed.GetDouble(pdoT);
        if (pdrT.Status != PromptStatus.OK) return;
        double thickness = pdrT.Value;

        var pdoR = new PromptDoubleOptions(
            "\nInside bend radius <" + F(thickness) + ">: ") {
            DefaultValue = thickness,
            UseDefaultValue = true,
            AllowNegative = false,
            AllowZero = true
        };
        PromptDoubleResult pdrR = ed.GetDouble(pdoR);
        if (pdrR.Status != PromptStatus.OK) return;

        var pdoK = new PromptDoubleOptions("\nK-factor <0.33>: ") {
            DefaultValue = 0.33,
            UseDefaultValue = true,
            AllowNegative = false,
            AllowZero = true
        };
        PromptDoubleResult pdrK = ed.GetDouble(pdoK);
        if (pdrK.Status != PromptStatus.OK || pdrK.Value > 1.0) {
            if (pdrK.Status == PromptStatus.OK) ed.WriteMessage("\nK-factor must be from 0 to 1.");
            return;
        }

        PromptPointResult ppr = ed.GetPoint("\nSpecify lower-left insertion point for flat pattern: ");
        if (ppr.Status != PromptStatus.OK) return;

        try {
            DevelopedPattern pattern = Develop(panels, thickness, pdrR.Value, pdrK.Value);
            double width = EstimateWidth(panels);
            using (Transaction tr = db.TransactionManager.StartTransaction()) {
                EnsureLayer(db, tr, "TA_UNFOLD_OUTLINE", 3);
                EnsureLayer(db, tr, "TA_BEND_LINE", 1);
                var bt = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForRead);
                var space = (BlockTableRecord)tr.GetObject(db.CurrentSpaceId, OpenMode.ForWrite);
                Point3d origin = ppr.Value;
                AddOutline(space, tr, origin, pattern.TotalLength, width);
                foreach (double x in pattern.FoldPositions) AddFoldLine(space, tr, origin, x, width);
                tr.Commit();
            }
            ed.WriteMessage(
                "\nTA3DUNFOLD complete. Panels: " + panels.Count.ToString(CultureInfo.InvariantCulture) +
                "; bends: " + pattern.FoldPositions.Count.ToString(CultureInfo.InvariantCulture) +
                "; flat size: " + F(pattern.TotalLength) + " x " + F(width) +
                "; detected axis: " + Vec(axis));
        } catch (System.Exception ex) {
            ed.WriteMessage("\nTA3DUNFOLD failed: " + OneLine(ex.Message));
        }
    }

    [CommandMethod("TA3DINSPECT", CommandFlags.Modal)]
    public static void InspectCommand() {
        Document doc = App.DocumentManager.MdiActiveDocument;
        if (doc == null) return;
        Editor ed = doc.Editor;
        var peo = new PromptEntityOptions("\nSelect 3D Solid to inspect: ");
        peo.SetRejectMessage("\nThe selected object must be a 3D Solid.");
        peo.AddAllowedClass(typeof(Solid3d), true);
        PromptEntityResult per = ed.GetEntity(peo);
        if (per.Status != PromptStatus.OK) return;
        try {
            using (Transaction tr = doc.Database.TransactionManager.StartTransaction()) {
                var solid = (Solid3d)tr.GetObject(per.ObjectId, OpenMode.ForRead);
                Analysis a = Analyze(solid);
                ed.WriteMessage("\n" + a.Report);
                for (int i = 0; i < a.Panels.Count; i++) {
                    Panel p = a.Panels[i];
                    ed.WriteMessage("\n  Panel " + (i + 1) +
                        ": center length=" + F(p.Length) +
                        ", extrusion width=" + F(p.Width) +
                        ", direction=" + Vec((p.B - p.A).GetNormal()));
                }
                tr.Commit();
            }
        } catch (System.Exception ex) {
            ed.WriteMessage("\nTA3DINSPECT failed: " + OneLine(ex.Message));
        }
    }

    private static Analysis Analyze(Solid3d solid) {
        var rawFaces = new List<RawFace>();
        var allLines = new List<LineSegment3d>();
        int faceIndex = 0;
        using (var brep = new Brep(solid)) {
            foreach (BrepFace face in brep.Faces) {
                faceIndex++;
                Plane plane = GetPlane(face);
                if (plane == null) continue;
                var lines = new List<LineSegment3d>();
                foreach (var loop in face.Loops) {
                    foreach (BrepEdge edge in loop.Edges) {
                        LineSegment3d line = GetLine(edge);
                        if (line != null && line.Length > Tiny) {
                            lines.Add(line);
                            allLines.Add(line);
                        }
                    }
                }
                if (lines.Count >= 4) rawFaces.Add(new RawFace(faceIndex, plane, lines));
            }
        }
        if (rawFaces.Count < 4 || allLines.Count < 8)
            throw new InvalidOperationException("Not enough planar B-Rep faces/edges were found.");

        Vector3d axis = DetectAxis(allLines);
        var lateral = new List<LateralFace>();
        foreach (RawFace raw in rawFaces) {
            var axial = raw.Lines.Where(x => Parallel((x.EndPoint - x.StartPoint).GetNormal(), axis)).ToList();
            if (axial.Count < 2) continue;
            // Duplicate/coincident B-Rep edge wrappers are possible; keep the two
            // axial edges whose projected midpoints are furthest apart.
            LineSegment3d first = null, second = null;
            double maxDistance = -1.0;
            for (int i = 0; i < axial.Count; i++) {
                for (int j = i + 1; j < axial.Count; j++) {
                    double d = PerpendicularDistance(Mid(axial[i]), Mid(axial[j]), axis);
                    if (d > maxDistance) { maxDistance = d; first = axial[i]; second = axial[j]; }
                }
            }
            if (first == null || second == null || maxDistance <= Tiny) continue;
            Point3d p0 = ProjectPerpendicular(Mid(first), axis);
            Point3d p1 = ProjectPerpendicular(Mid(second), axis);
            double width = 0.5 * (first.Length + second.Length);
            lateral.Add(new LateralFace(raw.Index, p0, p1, width, raw.Plane.Normal.GetNormal()));
        }
        if (lateral.Count < 4)
            throw new InvalidOperationException("This is not a straight prismatic folded profile (parallel bend axes were not found).");

        List<PairCandidate> nearest = FindNearestPairs(lateral);
        if (nearest.Count < 2)
            throw new InvalidOperationException("Could not identify opposite faces of a constant-thickness sheet.");
        double thickness = Median(nearest.Select(x => x.Distance).ToList());
        double thicknessTolerance = Math.Max(1.0e-4, thickness * 0.20);

        var used = new HashSet<int>();
        var panels = new List<Panel>();
        foreach (PairCandidate pair in nearest.OrderBy(x => x.Distance)) {
            if (Math.Abs(pair.Distance - thickness) > thicknessTolerance) continue;
            if (used.Contains(pair.A) || used.Contains(pair.B)) continue;
            LateralFace a = lateral[pair.A], b = lateral[pair.B];
            if (Math.Min(a.Span, b.Span) < thickness * 3.0) continue;
            Align(a, b, out Point3d b0, out Point3d b1);
            Point3d c0 = Mid(a.P0, b0);
            Point3d c1 = Mid(a.P1, b1);
            double len = c0.DistanceTo(c1);
            if (len <= thickness * 2.0) continue;
            panels.Add(new Panel(c0, c1, 0.5 * (a.Width + b.Width), a.Index, b.Index));
            used.Add(pair.A); used.Add(pair.B);
        }
        if (panels.Count < 2)
            throw new InvalidOperationException("Fewer than two usable sheet panels were paired.");
        panels = OrderPanels(panels, thickness);
        string report =
            "TA3DUNFOLD analysis: planar faces=" + rawFaces.Count +
            ", profile faces=" + lateral.Count +
            ", paired panels=" + panels.Count +
            ", detected thickness=" + F(thickness) +
            ", extrusion width=" + F(EstimateWidth(panels)) +
            ", bend axis=" + Vec(axis) + ".";
        return new Analysis(axis, thickness, panels, report);
    }

    private static Vector3d DetectAxis(List<LineSegment3d> lines) {
        var clusters = new List<DirectionCluster>();
        foreach (LineSegment3d line in lines) {
            Vector3d dir = Canonical((line.EndPoint - line.StartPoint).GetNormal());
            DirectionCluster hit = clusters.FirstOrDefault(x => Math.Abs(x.Direction.DotProduct(dir)) >= DirectionTolerance);
            if (hit == null) clusters.Add(new DirectionCluster(dir, line.Length));
            else hit.Add(dir, line.Length);
        }
        DirectionCluster best = clusters
            .OrderByDescending(x => x.Count)
            .ThenByDescending(x => x.TotalLength)
            .FirstOrDefault();
        if (best == null || best.Count < 4) throw new InvalidOperationException("No repeated straight extrusion direction was found.");
        return best.Direction.GetNormal();
    }

    private static List<PairCandidate> FindNearestPairs(List<LateralFace> faces) {
        var result = new List<PairCandidate>();
        for (int i = 0; i < faces.Count; i++) {
            PairCandidate best = null;
            for (int j = 0; j < faces.Count; j++) {
                if (i == j) continue;
                LateralFace a = faces[i], b = faces[j];
                Vector3d da = (a.P1 - a.P0).GetNormal();
                Vector3d db = (b.P1 - b.P0).GetNormal();
                if (Math.Abs(da.DotProduct(db)) < DirectionTolerance) continue;
                if (Math.Abs(a.Normal.DotProduct(b.Normal)) < DirectionTolerance) continue;
                double distance = SegmentPlaneDistance(a, b);
                if (distance <= Tiny) continue;
                double overlap = ProjectedOverlap(a, b, da);
                if (overlap < 0.45 * Math.Min(a.Span, b.Span)) continue;
                double ratio = Math.Min(a.Span, b.Span) / distance;
                if (ratio < 3.0) continue;
                if (best == null || distance < best.Distance) best = new PairCandidate(i, j, distance);
            }
            if (best != null) result.Add(best);
        }
        // Each physical pair is discovered from both faces. Keep one copy.
        return result
            .GroupBy(x => Math.Min(x.A, x.B).ToString(CultureInfo.InvariantCulture) + ":" + Math.Max(x.A, x.B).ToString(CultureInfo.InvariantCulture))
            .Select(g => g.OrderBy(x => x.Distance).First())
            .ToList();
    }

    private static List<Panel> OrderPanels(List<Panel> source, double thickness) {
        if (source.Count <= 2) return OrientSimple(source);
        int n = source.Count;
        var edges = new List<PanelLink>();
        for (int i = 0; i < n; i++) for (int j = i + 1; j < n; j++)
            edges.Add(new PanelLink(i, j, EndDistance(source[i], source[j])));

        // Kruskal minimum spanning tree on panel endpoint proximity.
        int[] parent = Enumerable.Range(0, n).ToArray();
        Func<int, int> find = null;
        find = x => parent[x] == x ? x : (parent[x] = find(parent[x]));
        var graph = Enumerable.Range(0, n).Select(_ => new List<int>()).ToArray();
        foreach (PanelLink edge in edges.OrderBy(x => x.Distance)) {
            int ra = find(edge.A), rb = find(edge.B);
            if (ra == rb) continue;
            parent[ra] = rb;
            graph[edge.A].Add(edge.B); graph[edge.B].Add(edge.A);
            if (graph.Sum(x => x.Count) == 2 * (n - 1)) break;
        }
        if (graph.Any(x => x.Count > 2))
            throw new InvalidOperationException("Detected panel topology branches; only one open folded strip is supported in this version.");
        int start = Array.FindIndex(graph, x => x.Count == 1);
        if (start < 0) throw new InvalidOperationException("Could not order the folded panels as one open strip.");
        var order = new List<int>();
        int previous = -1, current = start;
        while (current >= 0) {
            order.Add(current);
            int next = graph[current].FirstOrDefault(x => x != previous, -1);
            previous = current; current = next;
        }
        if (order.Count != n) throw new InvalidOperationException("Panel ordering did not reach every panel.");
        var panels = order.Select(x => source[x].Copy()).ToList();
        OrientChain(panels);
        return panels;
    }

    private static List<Panel> OrientSimple(List<Panel> source) {
        var result = source.Select(x => x.Copy()).ToList();
        if (result.Count == 2) OrientChain(result);
        return result;
    }

    private static void OrientChain(List<Panel> panels) {
        if (panels.Count < 2) return;
        if (MinEndDistance(panels[0].B, panels[1]) > MinEndDistance(panels[0].A, panels[1])) panels[0].Reverse();
        for (int i = 1; i < panels.Count; i++) {
            if (panels[i].A.DistanceTo(panels[i - 1].B) > panels[i].B.DistanceTo(panels[i - 1].B)) panels[i].Reverse();
        }
    }

    private static DevelopedPattern Develop(List<Panel> panels, double thickness, double insideRadius, double kFactor) {
        if (panels.Count < 2) throw new InvalidOperationException("No bend chain was found.");
        var corners = new List<Point3d>();
        var angles = new List<double>();
        for (int i = 0; i < panels.Count - 1; i++) {
            Point3d corner = ClosestLineIntersection(panels[i].A, panels[i].B, panels[i + 1].A, panels[i + 1].B);
            corners.Add(corner);
            Vector3d d1 = (panels[i].B - panels[i].A).GetNormal();
            Vector3d d2 = (panels[i + 1].B - panels[i + 1].A).GetNormal();
            double turn = Math.Acos(Clamp(d1.DotProduct(d2), -1.0, 1.0));
            if (turn < Math.PI / 180.0) throw new InvalidOperationException("Two adjacent panels are effectively coplanar.");
            angles.Add(turn);
        }

        Point3d firstEnd = panels[0].A;
        Point3d lastEnd = panels[panels.Count - 1].B;
        double total = firstEnd.DistanceTo(corners[0]);
        for (int i = 0; i < corners.Count - 1; i++) total += corners[i].DistanceTo(corners[i + 1]);
        total += corners[corners.Count - 1].DistanceTo(lastEnd);

        var foldPositions = new List<double>();
        double cursor = firstEnd.DistanceTo(corners[0]);
        double neutralRadius = insideRadius + kFactor * thickness;
        for (int i = 0; i < angles.Count; i++) {
            double angle = angles[i];
            double setback = neutralRadius * Math.Tan(angle * 0.5);
            double allowance = neutralRadius * angle;
            total += allowance - 2.0 * setback;
            cursor -= setback;
            foldPositions.Add(cursor + allowance * 0.5);
            cursor += allowance - setback;
            if (i < corners.Count - 1) cursor += corners[i].DistanceTo(corners[i + 1]);
        }
        if (total <= Tiny || foldPositions.Any(x => x <= 0.0 || x >= total))
            throw new InvalidOperationException("Bend radius is too large for one or more detected panel lengths.");
        return new DevelopedPattern(total, foldPositions);
    }

    private static Point3d ClosestLineIntersection(Point3d a0, Point3d a1, Point3d b0, Point3d b1) {
        var la = new Line3d(a0, a1);
        var lb = new Line3d(b0, b1);
        Point3d[] intersections = la.IntersectWith(lb, new Tolerance(1.0e-6, 1.0e-6));
        if (intersections != null && intersections.Length > 0) return intersections[0];
        // Lines are expected to be coplanar in a prismatic section.  If numeric
        // noise makes them skew, use the midpoint of their closest points.
        return Mid(a1, b0);
    }

    private static void AddOutline(BlockTableRecord space, Transaction tr, Point3d origin, double length, double width) {
        var pl = new Polyline(4) { Layer = "TA_UNFOLD_OUTLINE", Closed = true };
        pl.AddVertexAt(0, new Point2d(origin.X, origin.Y), 0.0, 0.0, 0.0);
        pl.AddVertexAt(1, new Point2d(origin.X + length, origin.Y), 0.0, 0.0, 0.0);
        pl.AddVertexAt(2, new Point2d(origin.X + length, origin.Y + width), 0.0, 0.0, 0.0);
        pl.AddVertexAt(3, new Point2d(origin.X, origin.Y + width), 0.0, 0.0, 0.0);
        space.AppendEntity(pl); tr.AddNewlyCreatedDBObject(pl, true);
    }

    private static void AddFoldLine(BlockTableRecord space, Transaction tr, Point3d origin, double x, double width) {
        var line = new Line(new Point3d(origin.X + x, origin.Y, origin.Z), new Point3d(origin.X + x, origin.Y + width, origin.Z)) {
            Layer = "TA_BEND_LINE"
        };
        space.AppendEntity(line); tr.AddNewlyCreatedDBObject(line, true);
    }

    private static void EnsureLayer(Database db, Transaction tr, string name, short color) {
        var table = (LayerTable)tr.GetObject(db.LayerTableId, OpenMode.ForRead);
        if (table.Has(name)) return;
        table.UpgradeOpen();
        var record = new LayerTableRecord { Name = name, Color = Autodesk.AutoCAD.Colors.Color.FromColorIndex(Autodesk.AutoCAD.Colors.ColorMethod.ByAci, color) };
        table.Add(record); tr.AddNewlyCreatedDBObject(record, true);
    }

    private static Plane GetPlane(BrepFace face) {
        Autodesk.AutoCAD.Geometry.Surface surface = face.Surface;
        var external = surface as ExternalBoundedSurface;
        if (external != null) surface = external.BaseSurface;
        return surface as Plane;
    }

    private static LineSegment3d GetLine(BrepEdge edge) {
        Curve3d curve = edge.Curve;
        var external = curve as ExternalCurve3d;
        if (external != null) curve = external.NativeCurve;
        return curve as LineSegment3d;
    }

    private static double SegmentPlaneDistance(LateralFace a, LateralFace b) {
        return 0.5 * (Math.Abs((b.P0 - a.P0).DotProduct(a.Normal)) + Math.Abs((b.P1 - a.P1).DotProduct(a.Normal)));
    }

    private static double ProjectedOverlap(LateralFace a, LateralFace b, Vector3d direction) {
        Point3d origin = a.P0;
        double a0 = 0.0, a1 = (a.P1 - origin).DotProduct(direction);
        double b0 = (b.P0 - origin).DotProduct(direction), b1 = (b.P1 - origin).DotProduct(direction);
        double amin = Math.Min(a0, a1), amax = Math.Max(a0, a1), bmin = Math.Min(b0, b1), bmax = Math.Max(b0, b1);
        return Math.Max(0.0, Math.Min(amax, bmax) - Math.Max(amin, bmin));
    }

    private static void Align(LateralFace a, LateralFace b, out Point3d b0, out Point3d b1) {
        double same = a.P0.DistanceTo(b.P0) + a.P1.DistanceTo(b.P1);
        double reverse = a.P0.DistanceTo(b.P1) + a.P1.DistanceTo(b.P0);
        if (same <= reverse) { b0 = b.P0; b1 = b.P1; }
        else { b0 = b.P1; b1 = b.P0; }
    }

    private static double EstimateWidth(List<Panel> panels) { return Median(panels.Select(x => x.Width).ToList()); }
    private static bool Parallel(Vector3d a, Vector3d b) { return Math.Abs(a.DotProduct(b)) >= DirectionTolerance; }
    private static Vector3d Canonical(Vector3d v) {
        if (v.X < -Tiny || (Math.Abs(v.X) <= Tiny && v.Y < -Tiny) || (Math.Abs(v.X) <= Tiny && Math.Abs(v.Y) <= Tiny && v.Z < 0.0)) return -v;
        return v;
    }
    private static Point3d Mid(LineSegment3d line) { return Mid(line.StartPoint, line.EndPoint); }
    private static Point3d Mid(Point3d a, Point3d b) { return new Point3d((a.X + b.X) * 0.5, (a.Y + b.Y) * 0.5, (a.Z + b.Z) * 0.5); }
    private static Point3d ProjectPerpendicular(Point3d p, Vector3d axis) { return p - axis * p.GetAsVector().DotProduct(axis); }
    private static double PerpendicularDistance(Point3d a, Point3d b, Vector3d axis) { Vector3d d = b - a; return (d - axis * d.DotProduct(axis)).Length; }
    private static double EndDistance(Panel a, Panel b) { return new[] { a.A.DistanceTo(b.A), a.A.DistanceTo(b.B), a.B.DistanceTo(b.A), a.B.DistanceTo(b.B) }.Min(); }
    private static double MinEndDistance(Point3d p, Panel b) { return Math.Min(p.DistanceTo(b.A), p.DistanceTo(b.B)); }
    private static double Median(List<double> values) { values.Sort(); int n = values.Count; return n % 2 == 1 ? values[n / 2] : 0.5 * (values[n / 2 - 1] + values[n / 2]); }
    private static double Clamp(double value, double min, double max) { return Math.Max(min, Math.Min(max, value)); }
    private static string F(double value) { return value.ToString("0.###", CultureInfo.InvariantCulture); }
    private static string Vec(Vector3d value) { return "(" + F(value.X) + "," + F(value.Y) + "," + F(value.Z) + ")"; }
    private static string OneLine(string value) { return (value ?? "").Replace('\r', ' ').Replace('\n', ' ').Trim(); }

    private sealed class RawFace {
        public readonly int Index; public readonly Plane Plane; public readonly List<LineSegment3d> Lines;
        public RawFace(int index, Plane plane, List<LineSegment3d> lines) { Index = index; Plane = plane; Lines = lines; }
    }
    private sealed class LateralFace {
        public readonly int Index; public readonly Point3d P0, P1; public readonly double Width; public readonly Vector3d Normal;
        public double Span { get { return P0.DistanceTo(P1); } }
        public LateralFace(int index, Point3d p0, Point3d p1, double width, Vector3d normal) { Index = index; P0 = p0; P1 = p1; Width = width; Normal = normal; }
    }
    private sealed class PairCandidate {
        public readonly int A, B; public readonly double Distance;
        public PairCandidate(int a, int b, double distance) { A = a; B = b; Distance = distance; }
    }
    private sealed class PanelLink {
        public readonly int A, B; public readonly double Distance;
        public PanelLink(int a, int b, double distance) { A = a; B = b; Distance = distance; }
    }
    private sealed class DirectionCluster {
        public Vector3d Direction; public int Count; public double TotalLength;
        public DirectionCluster(Vector3d direction, double length) { Direction = direction; Count = 1; TotalLength = length; }
        public void Add(Vector3d direction, double length) { if (Direction.DotProduct(direction) < 0.0) direction = -direction; Direction = (Direction * Count + direction).GetNormal(); Count++; TotalLength += length; }
    }
    private sealed class Panel {
        public Point3d A, B; public readonly double Width; public readonly int FaceA, FaceB;
        public double Length { get { return A.DistanceTo(B); } }
        public Panel(Point3d a, Point3d b, double width, int faceA, int faceB) { A = a; B = b; Width = width; FaceA = faceA; FaceB = faceB; }
        public void Reverse() { Point3d p = A; A = B; B = p; }
        public Panel Copy() { return new Panel(A, B, Width, FaceA, FaceB); }
    }
    private sealed class Analysis {
        public readonly Vector3d Axis; public readonly double Thickness; public readonly List<Panel> Panels; public readonly string Report;
        public Analysis(Vector3d axis, double thickness, List<Panel> panels, string report) { Axis = axis; Thickness = thickness; Panels = panels; Report = report; }
    }
    private sealed class DevelopedPattern {
        public readonly double TotalLength; public readonly List<double> FoldPositions;
        public DevelopedPattern(double totalLength, List<double> foldPositions) { TotalLength = totalLength; FoldPositions = foldPositions; }
    }
}
}

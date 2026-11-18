using System;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Geometry;
using Autodesk.AutoCAD.Runtime;
using App = Autodesk.AutoCAD.ApplicationServices.Core.Application;

// Native geometry verification in a disposable Core Console drawing.
public static class CountPreviewGeometry {
    [CommandMethod("COUNTPREVIEWTEST")]
    public static void Run() {
        var doc = App.DocumentManager.MdiActiveDocument;
        var db = doc.Database;
        int passed = 0;
        try {
            using (var tr = db.TransactionManager.StartTransaction()) {
                var blocks = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForWrite);
                var definition = new BlockTableRecord { Name = "COUNT_TEST_1900MM" };
                blocks.Add(definition); tr.AddNewlyCreatedDBObject(definition, true);
                var outline = new Polyline();
                outline.AddVertexAt(0, new Point2d(0, 0), 0, 0, 0);
                outline.AddVertexAt(1, new Point2d(1900, 0), 0, 0, 0);
                outline.AddVertexAt(2, new Point2d(1900, 50), 0, 0, 0);
                outline.AddVertexAt(3, new Point2d(0, 50), 0, 0, 0);
                outline.Closed = true;
                definition.AppendEntity(outline); tr.AddNewlyCreatedDBObject(outline, true);
                var space = (BlockTableRecord)tr.GetObject(db.CurrentSpaceId, OpenMode.ForWrite);
                foreach (double sourceX in new[] { 1.0, 2.0 }) {
                    var source = new BlockReference(new Point3d(3000, 500, 0), definition.ObjectId);
                    source.ScaleFactors = new Scale3d(sourceX, 1, 1);
                    source.Rotation = Math.PI / 6.0;
                    space.AppendEntity(source); tr.AddNewlyCreatedDBObject(source, true);
                    int angleIndex = 0;
                    foreach (double? angle in new double?[] { null, 0.0, 90.0, -45.0 }) {
                    var wrapper = new BlockTableRecord { Name = "COUNT_TEST_PREVIEW_" + sourceX + "_" + angleIndex++ };
                    blocks.Add(wrapper); tr.AddNewlyCreatedDBObject(wrapper, true);
                    var mapping = new IdMapping();
                    db.DeepCloneObjects(new ObjectIdCollection(new[] { source.ObjectId }), wrapper.ObjectId, mapping, false);
                    var clone = (BlockReference)tr.GetObject(mapping[source.ObjectId].Value, OpenMode.ForWrite);
                    clone.TransformBy(Matrix3d.Displacement(Point3d.Origin - clone.Position));
                    if (angle.HasValue) clone.Rotation = ((angle.Value % 360 + 360) % 360) * Math.PI / 180;
                    double expectedAngle = angle.HasValue ? angle.Value * Math.PI / 180 : Math.PI / 6;
                    double expectedWidth = Math.Abs(1900 * sourceX * Math.Cos(expectedAngle)) + Math.Abs(50 * Math.Sin(expectedAngle));
                    double expectedHeight = Math.Abs(1900 * sourceX * Math.Sin(expectedAngle)) + Math.Abs(50 * Math.Cos(expectedAngle));
                    var ext = clone.GeometricExtents;
                    Check(Math.Abs(ext.MaxPoint.X - ext.MinPoint.X - expectedWidth) < 1e-6,
                        "rotated Preview width matches requested angle", ref passed);
                    Check(Math.Abs(ext.MaxPoint.Y - ext.MinPoint.Y - expectedHeight) < 1e-6,
                        "rotated Preview height matches requested angle", ref passed);
                    Check(source.Position.DistanceTo(new Point3d(3000, 500, 0)) < 1e-6,
                        "original source unchanged", ref passed);
                    Check(Math.Abs(source.Rotation - Math.PI / 6) < 1e-6,
                        "original source rotation unchanged", ref passed);
                    foreach (double tableScale in new[] { 1.0, 2.0 })
                    foreach (double previewScale in new[] { 1.0, 0.1 })
                    foreach (bool autoFit in new[] { false, true }) {
                        var table = new Table { TableStyle = db.Tablestyle, Position = Point3d.Origin };
                        table.SetSize(3, 3); table.SetRowHeight(10); table.SetColumnWidth(100);
                        space.AppendEntity(table); tr.AddNewlyCreatedDBObject(table, true);
                        table.Cells[0, 0].TextString = "Preview scale test";
                        table.Cells[1, 0].TextString = "Name";
                        table.Cells[1, 1].TextString = "Preview";
                        table.Cells[1, 2].TextString = "Count";
                        table.TransformBy(Matrix3d.Scaling(tableScale, Point3d.Origin));
                        var cell = table.Cells[2, 1];
                        cell.BlockTableRecordId = wrapper.ObjectId;
                        cell.Contents[0].IsAutoScale = autoFit;
                        if (!autoFit) {
                            cell.Contents[0].Scale = previewScale;
                            table.Columns[1].Width = Math.Max(table.Columns[1].Width, expectedWidth * previewScale + 10);
                            table.Rows[2].Height = Math.Max(table.Rows[2].Height, expectedHeight * previewScale + 10);
                        }
                        table.GenerateLayout();
                        Check(cell.Contents[0].IsAutoScale == autoFit && (autoFit || Math.Abs(cell.Contents[0].Scale - previewScale) < 1e-6),
                            "Preview scale mode after table scaling", ref passed);
                        Check(autoFit || table.Columns[1].Width >= expectedWidth * previewScale,
                            "cell accommodates physical width", ref passed);
                        var entities = new DBObjectCollection();
                        table.Explode(entities);
                        bool found = false;
                        foreach (DBObject item in entities) {
                            using (item) {
                                if (item is BlockReference image && image.BlockTableRecord == wrapper.ObjectId) {
                                    found = true;
                                    var imageBounds = image.GeometricExtents;
                                    double actual = imageBounds.MaxPoint.X - imageBounds.MinPoint.X;
                                    Check(autoFit || Math.Abs(actual - expectedWidth * previewScale) < 0.001,
                                        "exploded Preview has requested physical length", ref passed);
                                    double actualHeight = imageBounds.MaxPoint.Y - imageBounds.MinPoint.Y;
                                    Check(Math.Abs(actual / actualHeight - expectedWidth / expectedHeight) < 0.001,
                                        "exploded Preview rotation preserved in either scale mode", ref passed);
                                }
                            }
                        }
                        Check(found, "actual Preview geometry available", ref passed);
                    }
                    }
                }
                // Deliberately abort the transaction; fixtures never persist.
                tr.Abort();
            }
            doc.Editor.WriteMessage("\nCOUNT_PREVIEW_GEOMETRY: " + passed + " passed, 0 failed.\n");
        } catch (System.Exception ex) {
            doc.Editor.WriteMessage("\nCOUNT_PREVIEW_GEOMETRY FAILED: " + ex.ToString() + "\n");
        }
    }
    private static void Check(bool ok, string message, ref int passed) {
        if (!ok) throw new InvalidOperationException(message);
        passed++;
    }
}

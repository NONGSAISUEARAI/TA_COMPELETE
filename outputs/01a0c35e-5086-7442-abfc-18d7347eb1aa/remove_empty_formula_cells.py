"""Remove formula placeholders with no expression from the rebuilt workbook."""

from pathlib import Path
from zipfile import ZipFile


OUTPUT_DIR = Path(__file__).resolve().parent
SOURCE = OUTPUT_DIR / "TOTAL_TRAY_REV03_rebuilt.xlsm"
TARGET = OUTPUT_DIR / "TOTAL_TRAY_REV03_recovered.xlsm"


def main() -> None:
    if TARGET.exists():
        raise FileExistsError(TARGET)
    removed = 0
    with ZipFile(SOURCE) as old_zip, ZipFile(TARGET, "w") as new_zip:
        for part in old_zip.infolist():
            data = old_zip.read(part.filename)
            if part.filename.startswith("xl/worksheets/sheet") and part.filename.endswith(".xml"):
                removed += data.count(b"<f></f>")
                data = data.replace(b"<f></f>", b"")
            new_zip.writestr(part, data)
    with ZipFile(TARGET) as checked:
        if checked.testzip() is not None:
            raise ValueError("Recovered workbook failed ZIP integrity validation")
    print("Recovered:", TARGET)
    print("Empty formula placeholders removed:", removed)


if __name__ == "__main__":
    main()

"""Scan-based audit reconciliation for a Jira Service Management Assets export.

Lab tool for portfolio purposes. It compares the asset tags collected during a
scan-based audit with an export of Laptop objects from the Assets (CMDB) schema
and classifies every asset as:

* ``Found``                    -- scanned, and the scan location matches the register;
* ``Found - wrong location``   -- scanned, but in a different location;
* ``Missing``                  -- in the register, not retired, and not scanned;
* ``Unexpected``               -- scanned, but not in the register;
* ``Retired - not expected``   -- retired in the register, so not counted as missing.

Optionally it writes an "Assets import" CSV (Name, Last audit date, Audit
result) that can be used to bulk-update the audited objects in Assets.

All data used with this tool in the repository is entirely synthetic.
"""

from __future__ import annotations

import argparse
import csv
import sys
from collections import Counter
from dataclasses import dataclass
from datetime import date, datetime
from pathlib import Path
from typing import Dict, List

SCAN_COLUMNS = ("asset_tag", "scanned_location", "scanned_at", "scanned_by")
REGISTER_COLUMNS = ("Name", "Status", "Location", "Assigned to")

FOUND = "Found"
WRONG_LOCATION = "Found - wrong location"
MISSING = "Missing"
UNEXPECTED = "Unexpected"
RETIRED = "Retired - not expected"
CATEGORIES = (FOUND, WRONG_LOCATION, MISSING, UNEXPECTED, RETIRED)

RETIRED_STATUS = "RETIRED"

# Only objects that were expected on the audit are written to the import file.
# Unexpected tags have no object to update (an import keyed on Name would
# create a new object), and retired objects were not part of the audit.
IMPORT_CATEGORIES = (FOUND, WRONG_LOCATION, MISSING)

REPORT_COLUMNS = (
    "asset_tag",
    "result",
    "register_status",
    "register_location",
    "scanned_location",
    "assigned_to",
    "scan_count",
    "note",
)
IMPORT_COLUMNS = ("Name", "Last audit date", "Audit result")


@dataclass
class Scan:
    """One row of the scan CSV, with the tag already normalised."""

    asset_tag: str
    scanned_location: str
    scanned_at: datetime
    scanned_by: str


@dataclass
class RegisterObject:
    """One Laptop object from the Assets export, with the tag normalised."""

    name: str
    status: str
    location: str
    assigned_to: str


@dataclass
class AuditLine:
    """Reconciliation result for a single asset tag."""

    asset_tag: str
    result: str
    register_status: str = ""
    register_location: str = ""
    scanned_location: str = ""
    assigned_to: str = ""
    scan_count: int = 0
    note: str = ""

    def as_row(self) -> Dict[str, str]:
        return {
            "asset_tag": self.asset_tag,
            "result": self.result,
            "register_status": self.register_status,
            "register_location": self.register_location,
            "scanned_location": self.scanned_location,
            "assigned_to": self.assigned_to,
            "scan_count": str(self.scan_count),
            "note": self.note,
        }


def _normalise(value: str) -> str:
    """Normalise a tag or location for comparison (trim, collapse spaces, upper-case)."""
    return " ".join(value.split()).upper()


def _open_rows(path: Path, required: tuple) -> List[Dict[str, str]]:
    """Read a CSV file and check that all required columns are present."""
    if not path.exists():
        raise FileNotFoundError(f"CSV file not found: {path}")

    # utf-8-sig accepts files saved by Excel, which start with a byte order mark.
    with path.open(newline="", encoding="utf-8-sig") as handle:
        reader = csv.DictReader(handle)
        header = [name.strip() for name in (reader.fieldnames or [])]
        absent = [column for column in required if column not in header]
        if absent:
            raise ValueError(
                f"Missing column(s) {absent} in {path}; found: {header}"
            )
        rows = []
        for row in reader:
            rows.append(
                {(key or "").strip(): (value or "").strip() for key, value in row.items()}
            )
        return rows


def read_scans(path: Path) -> List[Scan]:
    """Read the scan CSV. Rows with a blank asset tag are ignored.

    ``scanned_at`` must be an ISO 8601 date-time, for example
    ``2026-11-12T10:05``. Raises :class:`ValueError` otherwise.
    """
    scans: List[Scan] = []
    # Line 1 is the header, so data starts on line 2.
    for line_number, row in enumerate(_open_rows(path, SCAN_COLUMNS), start=2):
        if not row["asset_tag"]:
            continue
        try:
            scanned_at = datetime.fromisoformat(row["scanned_at"])
        except ValueError:
            raise ValueError(
                f"{path}, line {line_number}: scanned_at "
                f"'{row['scanned_at']}' is not an ISO 8601 date-time"
            ) from None
        scans.append(
            Scan(
                asset_tag=_normalise(row["asset_tag"]),
                scanned_location=row["scanned_location"],
                scanned_at=scanned_at,
                scanned_by=row["scanned_by"],
            )
        )
    return scans


def read_register(path: Path) -> List[RegisterObject]:
    """Read the Assets export CSV. Rows with a blank Name are ignored.

    Raises :class:`ValueError` if the same Name appears twice, because the
    register is the reference and must have one object per asset tag.
    """
    objects: List[RegisterObject] = []
    seen = set()
    for line_number, row in enumerate(_open_rows(path, REGISTER_COLUMNS), start=2):
        if not row["Name"]:
            continue
        name = _normalise(row["Name"])
        if name in seen:
            raise ValueError(
                f"{path}, line {line_number}: asset tag {name} appears more "
                "than once in the register"
            )
        seen.add(name)
        objects.append(
            RegisterObject(
                name=name,
                status=row["Status"],
                location=row["Location"],
                assigned_to=row["Assigned to"],
            )
        )
    return objects


def reconcile(register: List[RegisterObject], scans: List[Scan]) -> List[AuditLine]:
    """Classify every asset tag found in the register or in the scans.

    Each tag is reported once. When a tag was scanned more than once, the
    latest scan gives the location and the note records the duplicate.

    Returns:
        A list of :class:`AuditLine`, sorted by asset tag.
    """
    scans_by_tag: Dict[str, List[Scan]] = {}
    for scan in scans:
        scans_by_tag.setdefault(scan.asset_tag, []).append(scan)

    lines: List[AuditLine] = []
    register_tags = set()

    for obj in register:
        register_tags.add(obj.name)
        tag_scans = scans_by_tag.get(obj.name, [])
        line = AuditLine(
            asset_tag=obj.name,
            result=MISSING,
            register_status=obj.status,
            register_location=obj.location,
            assigned_to=obj.assigned_to,
            scan_count=len(tag_scans),
        )
        notes: List[str] = []

        if tag_scans:
            latest = max(tag_scans, key=lambda scan: scan.scanned_at)
            line.scanned_location = latest.scanned_location
            if len(tag_scans) > 1:
                notes.append(_duplicate_note(tag_scans))

        if _normalise(obj.status) == RETIRED_STATUS:
            line.result = RETIRED
            if tag_scans:
                notes.append("Retired object was scanned; check the disposal record")
        elif not tag_scans:
            line.result = MISSING
        elif not obj.location:
            line.result = FOUND
            notes.append("No location in register; location not checked")
        elif _normalise(line.scanned_location) == _normalise(obj.location):
            line.result = FOUND
        else:
            line.result = WRONG_LOCATION

        line.note = "; ".join(notes)
        lines.append(line)

    for tag, tag_scans in scans_by_tag.items():
        if tag in register_tags:
            continue
        latest = max(tag_scans, key=lambda scan: scan.scanned_at)
        notes = ["Not in register"]
        if len(tag_scans) > 1:
            notes.append(_duplicate_note(tag_scans))
        lines.append(
            AuditLine(
                asset_tag=tag,
                result=UNEXPECTED,
                scanned_location=latest.scanned_location,
                scan_count=len(tag_scans),
                note="; ".join(notes),
            )
        )

    return sorted(lines, key=lambda line: line.asset_tag)


def _duplicate_note(tag_scans: List[Scan]) -> str:
    locations = sorted({scan.scanned_location for scan in tag_scans})
    return f"Duplicate scan ({len(tag_scans)} times; locations: {', '.join(locations)})"


def summarise(lines: List[AuditLine]) -> Dict[str, int]:
    """Return a count per category, in report order, plus duplicate scans."""
    counts = Counter(line.result for line in lines)
    summary = {category: counts.get(category, 0) for category in CATEGORIES}
    summary["Duplicate scans"] = sum(1 for line in lines if line.scan_count > 1)
    return summary


def write_report(lines: List[AuditLine], path: Path) -> None:
    """Write the full reconciliation report to a CSV file."""
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=REPORT_COLUMNS)
        writer.writeheader()
        writer.writerows(line.as_row() for line in lines)


def write_assets_import(lines: List[AuditLine], audit_date: date, path: Path) -> int:
    """Write the Assets import CSV and return the number of objects written.

    The date is written as ``YYYY-MM-DD``; set the same date format in the
    Assets import configuration.
    """
    rows = [line for line in lines if line.result in IMPORT_CATEGORIES]
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=IMPORT_COLUMNS)
        writer.writeheader()
        for line in rows:
            writer.writerow(
                {
                    "Name": line.asset_tag,
                    "Last audit date": audit_date.isoformat(),
                    "Audit result": line.result,
                }
            )
    return len(rows)


def _format_report(lines: List[AuditLine]) -> str:
    """Render a human-readable console report."""
    output = ["Assets audit reconciliation", "=" * 27, ""]
    header = f"{'Asset tag':<10} {'Result':<23} {'Register location':<18} {'Scanned location':<18} Note"
    output.append(header)
    output.append("-" * len(header))
    for line in lines:
        output.append(
            f"{line.asset_tag:<10} {line.result:<23} {line.register_location:<18} "
            f"{line.scanned_location:<18} {line.note}".rstrip()
        )
    output.extend(["", "Summary"])
    for category, count in summarise(lines).items():
        output.append(f"  {category:<23}: {count}")
    return "\n".join(output) + "\n"


def _parse_audit_date(value: str) -> date:
    try:
        return date.fromisoformat(value)
    except ValueError:
        raise argparse.ArgumentTypeError(
            f"'{value}' is not a date in YYYY-MM-DD format"
        ) from None


def parse_args(argv: List[str]) -> argparse.Namespace:
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    parser.add_argument(
        "--scan",
        required=True,
        type=Path,
        help="Scan CSV (asset_tag, scanned_location, scanned_at, scanned_by).",
    )
    parser.add_argument(
        "--assets",
        required=True,
        type=Path,
        help="Assets export CSV (Name, Status, Location, Assigned to).",
    )
    parser.add_argument(
        "--report",
        type=Path,
        help="Optional path for the full report as CSV.",
    )
    parser.add_argument(
        "--audit-date",
        type=_parse_audit_date,
        help="Audit date (YYYY-MM-DD). When set, an Assets import CSV is written.",
    )
    parser.add_argument(
        "--import-csv",
        type=Path,
        default=Path("assets-import.csv"),
        help="Path for the Assets import CSV (default: assets-import.csv). "
        "Used only with --audit-date.",
    )
    return parser.parse_args(argv)


def main(argv: List[str] | None = None) -> int:
    """Entry point. Returns a process exit code."""
    args = parse_args(sys.argv[1:] if argv is None else argv)
    try:
        scans = read_scans(args.scan)
        register = read_register(args.assets)
    except (FileNotFoundError, ValueError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2

    lines = reconcile(register, scans)
    print(_format_report(lines), end="")

    if args.report or args.audit_date:
        print()
    if args.report:
        write_report(lines, args.report)
        print(f"Report written to {args.report}")
    if args.audit_date:
        written = write_assets_import(lines, args.audit_date, args.import_csv)
        print(f"Assets import written to {args.import_csv} ({written} objects)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

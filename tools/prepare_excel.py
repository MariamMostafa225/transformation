#!/usr/bin/env python3
"""Validate an Excel fleet sheet and create stable JSON import assets."""

import argparse
import collections
import hashlib
import json
from pathlib import Path

import openpyxl

COLORS = [
    "#2B6F78", "#497A69", "#5973A7", "#A66A43", "#765F96", "#4E7C8C",
    "#8A6B48", "#A35C61", "#3F806F", "#536AA0", "#9A7044", "#6D6597",
    "#3D7890", "#A65F52", "#567E62", "#7F6A46", "#5B7393", "#946650",
    "#517F7B", "#785F8A", "#537191", "#9B7257", "#4E7C69", "#86654A",
    "#5B6F9B", "#9A5F64",
]


def as_text(value) -> str:
    if value is None:
        return ""
    if isinstance(value, float) and value.is_integer():
        return str(int(value))
    return str(value).strip()


def stable_id(prefix: str, value: str, length: int) -> str:
    digest = hashlib.sha256(value.encode("utf-8")).hexdigest()[:length]
    return f"{prefix}-{digest}"


def prepare(source: Path, output: Path, sheet_name: str | None, first_data_row: int) -> dict:
    workbook = openpyxl.load_workbook(source, read_only=True, data_only=True)
    sheet = workbook[sheet_name] if sheet_name else workbook.active
    raw_rows = []
    incomplete = []

    for row_number, values in enumerate(
        sheet.iter_rows(min_row=first_data_row, max_col=3, values_only=True),
        start=first_data_row,
    ):
        number, letters, company = (list(values) + [None, None, None])[:3]
        car_number, plate_letters, company_name = map(as_text, (number, letters, company))
        if not any((car_number, plate_letters, company_name)):
            continue
        if not all((car_number, plate_letters, company_name)):
            incomplete.append({
                "sourceRow": row_number,
                "carNumber": car_number,
                "letters": plate_letters,
                "companyName": company_name,
            })
            continue
        raw_rows.append((row_number, car_number, plate_letters, company_name))

    company_names = sorted({row[3] for row in raw_rows})
    companies = []
    for index, name in enumerate(company_names):
        company_id = "co-" + hashlib.sha1(name.encode("utf-8")).hexdigest()[:12]
        companies.append({"id": company_id, "name": name, "color": COLORS[index % len(COLORS)]})
    company_ids = {company["name"]: company["id"] for company in companies}

    cars = []
    duplicates = []
    seen = set()
    for row_number, number, letters, company_name in raw_rows:
        key = (number, letters, company_name)
        if key in seen:
            duplicates.append({
                "sourceRow": row_number,
                "carNumber": number,
                "letters": letters,
                "companyName": company_name,
            })
            continue
        seen.add(key)
        key_text = "|".join(key)
        cars.append({
            "id": stable_id("car", key_text, 24),
            "carNumber": number,
            "letters": letters,
            "companyId": company_ids[company_name],
        })

    counts = collections.Counter(car["companyId"] for car in cars)
    plate_owners = collections.defaultdict(list)
    for car in cars:
        plate_owners[(car["carNumber"], car["letters"])].append(car)
    conflicts = [
        {
            "carNumber": number,
            "letters": letters,
            "companyIds": sorted({car["companyId"] for car in owners}),
        }
        for (number, letters), owners in plate_owners.items()
        if len({car["companyId"] for car in owners}) > 1
    ]

    output.mkdir(parents=True, exist_ok=True)
    report = {
        "sourceFile": source.name,
        "sourceSheet": sheet.title,
        "sourceRowsWithAllFields": len(raw_rows),
        "importedUniqueCars": len(cars),
        "companies": len(companies),
        "exactDuplicateRowsExcluded": len(duplicates),
        "incompleteRowsExcluded": incomplete,
        "duplicateRows": duplicates,
        "plateConflictsAcrossCompanies": conflicts,
        "companyCounts": [
            {"companyId": company["id"], "companyName": company["name"], "cars": counts[company["id"]]}
            for company in companies
        ],
    }
    for name, rows in (("companies.json", companies), ("cars.json", cars)):
        (output / name).write_text(json.dumps(rows, ensure_ascii=False, indent=2), encoding="utf-8")
    (output / "source_import_report.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    return report


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, required=True, help="An .xlsx workbook; save legacy .xls files as .xlsx first")
    parser.add_argument("--sheet", help="Worksheet name; defaults to the first worksheet")
    parser.add_argument("--first-data-row", type=int, default=5, help="First row with car number, letters, and company in columns A:C")
    parser.add_argument("--output-dir", type=Path, default=Path("assets/data"))
    args = parser.parse_args()
    if args.input.suffix.lower() != ".xlsx":
        parser.error("Only .xlsx is supported; open the workbook in Excel and save a copy as .xlsx")
    report = prepare(args.input, args.output_dir, args.sheet, args.first_data_row)
    print(f"Companies: {report['companies']}")
    print(f"Unique cars prepared: {report['importedUniqueCars']}")
    print(f"Duplicate rows excluded: {report['exactDuplicateRowsExcluded']}")
    print(f"Incomplete rows needing review: {len(report['incompleteRowsExcluded'])}")
    print(f"Cross-company plate conflicts needing review: {len(report['plateConflictsAcrossCompanies'])}")
    print(f"Review {args.output_dir / 'source_import_report.json'} before importing.")


if __name__ == "__main__":
    main()

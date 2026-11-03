#!/usr/bin/env python3
"""Import the prepared company and car JSON files into Cloud Firestore."""

import argparse
import json
from pathlib import Path

from firebase_admin import credentials, firestore, initialize_app


def load_rows(path: Path) -> list[dict]:
    with path.open(encoding="utf-8-sig") as file:
        rows = json.load(file)
    if not isinstance(rows, list):
        raise ValueError(f"Expected a JSON array in {path}")
    return rows


def write_batches(client, collection_name: str, rows: list[dict], *, dry_run: bool) -> int:
    written = 0
    collection = client.collection(collection_name) if not dry_run else None
    for start in range(0, len(rows), 450):
        chunk = rows[start : start + 450]
        if not dry_run:
            batch = client.batch()
            for row in chunk:
                row_id = row["id"]
                data = {key: value for key, value in row.items() if key != "id"}
                reference = collection.document(row_id)
                if not reference.get().exists:
                    data["createdAt"] = firestore.SERVER_TIMESTAMP
                data["updatedAt"] = firestore.SERVER_TIMESTAMP
                batch.set(reference, data, merge=True)
            batch.commit()
        written += len(chunk)
    return written


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--service-account", type=Path, required=True)
    parser.add_argument("--companies", type=Path, default=Path("assets/data/companies.json"))
    parser.add_argument("--cars", type=Path, default=Path("assets/data/cars.json"))
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    companies = load_rows(args.companies)
    cars = load_rows(args.cars)
    company_ids = {row["id"] for row in companies}
    missing = sorted({row["companyId"] for row in cars} - company_ids)
    if missing:
        raise ValueError(f"Cars reference companies missing from companies.json: {missing}")

    if args.dry_run:
        client = None
    else:
        initialize_app(credentials.Certificate(str(args.service_account)))
        client = firestore.client()
    write_batches(client, "companies", companies, dry_run=args.dry_run)
    write_batches(client, "cars", cars, dry_run=args.dry_run)
    print(f"Companies: {len(companies)}")
    print(f"Cars: {len(cars)}")
    print("Dry run: no records were sent." if args.dry_run else "Import complete.")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""
Production DB Promo Sweep Script
Deletes any test, smoke, or sample promotions from the Firestore collection.
Can be executed in dry-run mode (default) to show matches before modification.
"""

import os
import re
import sys
from google.cloud import firestore

PROJECT = os.environ.get("GOOGLE_CLOUD_PROJECT")
DRY_RUN = os.environ.get("DRY_RUN", "true").lower() in ("true", "1", "yes")

if not PROJECT:
    print("❌ ERROR: Set GOOGLE_CLOUD_PROJECT environment variable.", file=sys.stderr)
    sys.exit(1)

print(f"🛰️  Target Firebase Project: {PROJECT}")
print(f"⚙️  Dry-Run Mode: {DRY_RUN}")

db = firestore.Client(project=PROJECT)
pattern = re.compile(r"(smoke|test|demo|sample)", re.IGNORECASE)

def find_test_promos():
    promos = db.collection("promotions").stream()
    to_delete = []
    for p in promos:
        data = p.to_dict()
        title = data.get("title", "")
        status = data.get("status", "")
        # Match matches or 'test' parameters
        if pattern.search(title) or pattern.search(status):
            to_delete.append((p.id, title, status))
    return to_delete

def delete_promos(items):
    doc_ref = db.collection("promotions")
    for pid, title, status in items:
        if DRY_RUN:
            print(f"🔍 [DRY-RUN] Will delete: Doc ID: {pid} | Title: '{title}' | Status: '{status}'")
        else:
            print(f"🔥 DELETING: Doc ID: {pid} | Title: '{title}'")
            doc_ref.document(pid).delete()

if __name__ == "__main__":
    print("🧹 Fetching staging/test promotions...")
    try:
        found = find_test_promos()
        if not found:
            print("✅ Code check complete: No test/demo promotions found.")
        else:
            print(f"📣 Found {len(found)} promotions matching sweep pattern.")
            delete_promos(found)
            if not DRY_RUN:
                print("✨ Deleted successfully!")
            else:
                print("ℹ️  Run with DRY_RUN=false to make execution permanent.")
    except Exception as e:
        print(f"❌ Execution failed: {e}", file=sys.stderr)
        sys.exit(1)

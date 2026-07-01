import fs from "fs";
import path from "path";

type SeenRoute = {
  routeName: string;
  projectName: string;
};

type DuplicateRecord = {
  hash: string;
  firstRoute: string;
  duplicateRoute: string;
  project: string;
  ts: string;
};

const seenHashes = new Map<string, SeenRoute>();
const duplicateRecords: DuplicateRecord[] = [];

/**
 * Records a screenshot hash for uniqueness tracking.
 * Returns false (WARN) if a duplicate is detected — does NOT throw.
 * Duplicate hashes indicate auth-gated routes rendering the same login screen.
 */
export function assertUniqueHash(
  hash: string,
  routeName: string,
  projectName: string,
): boolean {
  const seen = seenHashes.get(hash);
  if (!seen) {
    seenHashes.set(hash, { routeName, projectName });
    return true;
  }

  const sameProject = seen.projectName === projectName;
  const differentRoute = seen.routeName !== routeName;

  if (sameProject && differentRoute) {
    console.warn(
      `⚠️  WARN  Duplicate screenshot hash for route '${routeName}' in '${projectName}' — matches '${seen.routeName}'. Routes may be rendering the same screen (auth gate?).`,
    );
    duplicateRecords.push({
      hash,
      firstRoute: seen.routeName,
      duplicateRoute: routeName,
      project: projectName,
      ts: new Date().toISOString(),
    });
  }

  return false;
}

export function getDuplicateRecords(): DuplicateRecord[] {
  return duplicateRecords.slice();
}

/**
 * Writes visual-duplicates.json to test-results/ if any duplicates were found.
 * Returns the file path, or null if no duplicates.
 */
export function writeDuplicateSummaryIfAny(): string | null {
  if (duplicateRecords.length === 0) return null;
  try {
    const outDir = path.resolve(process.cwd(), "test-results");
    if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });
    const out = path.join(outDir, "visual-duplicates.json");
    fs.writeFileSync(out, JSON.stringify(duplicateRecords, null, 2));
    console.warn(`⚠️  Wrote visual duplicates summary → ${out}`);
    return out;
  } catch (err) {
    console.warn("Failed to write visual duplicates summary", err);
    return null;
  }
}

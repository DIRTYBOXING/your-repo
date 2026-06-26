import fs from "node:fs/promises";
import process from "node:process";

function parseArgs(argv) {
  const options = { rules: [] };

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (!arg.startsWith("--")) {
      continue;
    }

    const key = arg.slice(2);
    const value = argv[index + 1];
    if (!value || value.startsWith("--")) {
      options[key] = true;
      continue;
    }

    if (key === "rule") {
      options.rules.push(value);
    } else {
      options[key] = value;
    }
    index += 1;
  }

  return options;
}

function normalizeStatKey(stat) {
  const trimmed = String(stat || "").trim();
  switch (trimmed) {
    case "p95":
    case "p(95)":
      return "p(95)";
    case "p99":
    case "p(99)":
      return "p(99)";
    default:
      return trimmed;
  }
}

function compare(actual, operator, expected) {
  switch (operator) {
    case "<":
      return actual < expected;
    case "<=":
      return actual <= expected;
    case ">":
      return actual > expected;
    case ">=":
      return actual >= expected;
    case "==":
      return actual === expected;
    default:
      throw new Error(`Unsupported operator: ${operator}`);
  }
}

function parseRule(rawRule) {
  const parts = String(rawRule).split(":");
  if (parts.length !== 4) {
    throw new TypeError(
      `Invalid rule "${rawRule}". Expected metric:stat:op:value`,
    );
  }

  const [metricName, statName, operator, expectedRaw] = parts;
  const expected = Number(expectedRaw);
  if (!Number.isFinite(expected)) {
    throw new TypeError(`Invalid numeric value in rule "${rawRule}"`);
  }

  return {
    rawRule,
    metricName,
    statName: normalizeStatKey(statName),
    operator,
    expected,
  };
}

function evaluateRule(metrics, rawRule) {
  const rule = parseRule(rawRule);
  const metric = metrics[rule.metricName];
  if (!metric?.values) {
    return {
      passed: false,
      message: `Missing metric ${rule.metricName} for rule ${rule.rawRule}`,
    };
  }

  const actual = metric.values[rule.statName];
  if (!Number.isFinite(actual)) {
    return {
      passed: false,
      message:
        `Missing stat ${rule.statName} on metric ${rule.metricName} ` +
        `for rule ${rule.rawRule}`,
    };
  }

  const line = `${rule.metricName}.${rule.statName}=${actual} ${rule.operator} ${rule.expected}`;
  return {
    passed: compare(actual, rule.operator, rule.expected),
    message: line,
  };
}

function printResults(results, label) {
  for (const result of results) {
    console.log(`${label}${result.passed ? "PASS" : "FAIL"} ${result.message}`);
  }
}

function failIfNeeded(results, label) {
  const failures = results.filter((result) => !result.passed);
  if (!failures.length) {
    console.log(`${label}All k6 threshold assertions passed.`);
    return;
  }

  console.error(`${label}k6 threshold gate failed:`);
  for (const failure of failures) {
    console.error(`${label}${failure.message}`);
  }
  process.exit(2);
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  if (!options.file) {
    throw new TypeError("Missing required --file argument");
  }
  if (!options.rules.length) {
    throw new TypeError("Provide at least one --rule metric:stat:op:value");
  }

  const raw = await fs.readFile(options.file, "utf8");
  const summary = JSON.parse(raw);
  const metrics = summary.metrics || {};
  const label = options.label ? `[${options.label}] ` : "";
  const results = options.rules.map((rawRule) => evaluateRule(metrics, rawRule));
  printResults(results, label);
  failIfNeeded(results, label);
}

try {
  await main();
} catch (error) {
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
}

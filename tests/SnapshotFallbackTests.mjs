import assert from "node:assert/strict";
import crypto from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";

const root = fs.mkdtempSync(path.join(os.tmpdir(), "quota-bubble-snapshot-tests-"));
const script = path.resolve(import.meta.dirname, "../scripts/codex-usage-snapshot.mjs");

function fingerprint(accountID) {
  return `account:${crypto.createHash("sha256").update(accountID).digest("hex").slice(0, 16)}`;
}

function writeJson(filePath, value) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  fs.writeFileSync(filePath, `${JSON.stringify(value)}\n`);
}

function auth(accountID) {
  return { tokens: { account_id: accountID, access_token: `token-${accountID}` } };
}

function writeSession(home, usedPercentage) {
  const filePath = path.join(home, "sessions", "current.jsonl");
  writeJson(filePath, {
    timestamp: new Date(Date.now() + 1_000).toISOString(),
    payload: {
      rate_limits: {
        primary: { used_percent: usedPercentage, resets_at: 2_000_000_000 },
      },
    },
  });
}

function run(home) {
  const output = path.join(home, "codex-usage-snapshot.json");
  const result = spawnSync(process.execPath, [script, output], {
    env: { ...process.env, CODEX_HOME: home, QUOTA_BUBBLE_DISABLE_NETWORK: "1" },
    encoding: "utf8",
  });
  assert.equal(result.status, 0, result.stderr);
  return JSON.parse(fs.readFileSync(output, "utf8"));
}

try {
  const stableHome = path.join(root, "stable-account");
  const stableFingerprint = fingerprint("account-b");
  writeJson(path.join(stableHome, "auth.json"), auth("account-b"));
  writeJson(path.join(stableHome, "codex-usage-account-state.json"), {
    account_fingerprint: stableFingerprint,
    rate_limits_after_ms: 0,
  });
  writeJson(path.join(stableHome, "codex-usage-snapshot.json"), {
    account_fingerprint: stableFingerprint,
    source: "wham_usage",
    five_hour: { used_percentage: 0, resets_at: 2_000_000_000 },
  });
  writeSession(stableHome, 78);
  const stable = run(stableHome);
  assert.equal(stable.five_hour.used_percentage, 0, "live quota survives an endpoint failure");
  assert.equal(stable.source, "unavailable");
  assert.equal(stable.stale_source, true);

  const switchedHome = path.join(root, "switched-account");
  writeJson(path.join(switchedHome, "auth.json"), auth("account-b"));
  writeJson(path.join(switchedHome, "codex-usage-account-state.json"), {
    account_fingerprint: fingerprint("account-a"),
    rate_limits_after_ms: 0,
  });
  writeJson(path.join(switchedHome, "codex-usage-snapshot.json"), {
    account_fingerprint: fingerprint("account-a"),
    source: "wham_usage",
    five_hour: { used_percentage: 78, resets_at: 2_000_000_000 },
  });
  writeSession(switchedHome, 78);
  const switched = run(switchedHome);
  assert.equal(switched.account_fingerprint, fingerprint("account-b"));
  assert.equal(switched.five_hour, null, "old session quota is not assigned to the new account");
  assert.equal(switched.source, "unavailable");

  console.log("Snapshot fallback tests passed.");
} finally {
  fs.rmSync(root, { recursive: true, force: true });
}

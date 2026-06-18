#!/usr/bin/env node
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

const codexHome = process.env.CODEX_HOME || path.join(os.homedir(), ".codex");
const searchDirs = [
  path.join(codexHome, "sessions"),
  path.join(codexHome, "archived_sessions"),
];
const outputPath = process.argv[2] || path.join(codexHome, "codex-usage-snapshot.json");
const resetCreditsCachePath = path.join(codexHome, "codex-rate-limit-reset-credits-cache.json");
const resetCreditsEndpoint = "https://chatgpt.com/backend-api/wham/rate-limit-reset-credits";
const resetCreditsCacheTtlMs = 30_000;
const auth = readJson(path.join(codexHome, "auth.json"));
const currentAccountId = typeof auth?.tokens?.account_id === "string" ? auth.tokens.account_id : null;
const authLastRefreshMs = typeof auth?.last_refresh === "string" ? Date.parse(auth.last_refresh) : 0;

function listJsonlFiles(dirs) {
  const files = [];

  for (const dir of dirs) {
    if (!fs.existsSync(dir)) continue;

    const stack = [dir];
    while (stack.length) {
      const current = stack.pop();
      let entries = [];
      try {
        entries = fs.readdirSync(current, { withFileTypes: true });
      } catch {
        continue;
      }

      for (const entry of entries) {
        const fullPath = path.join(current, entry.name);
        if (entry.isDirectory()) {
          stack.push(fullPath);
        } else if (entry.isFile() && entry.name.endsWith(".jsonl")) {
          files.push(fullPath);
        }
      }
    }
  }

  return files.sort((a, b) => {
    try {
      return fs.statSync(b).mtimeMs - fs.statSync(a).mtimeMs;
    } catch {
      return 0;
    }
  });
}

function parseEventTimestamp(event) {
  if (typeof event?.timestamp !== "string") return 0;
  const millis = Date.parse(event.timestamp);
  return Number.isFinite(millis) ? millis : 0;
}

function readLatestRateLimits(filePath) {
  let raw = "";
  try {
    raw = fs.readFileSync(filePath, "utf8");
  } catch {
    return null;
  }

  const lines = raw.trim().split("\n");
  for (let index = lines.length - 1; index >= 0; index -= 1) {
    try {
      const event = JSON.parse(lines[index]);
      const limits = event?.payload?.rate_limits;
      const primary = limits?.primary;
      const secondary = limits?.secondary;
      if (typeof primary?.used_percent === "number" || typeof secondary?.used_percent === "number") {
        return {
          primary,
          secondary,
          timestampMs: parseEventTimestamp(event),
          filePath,
        };
      }
    } catch {
      // Ignore partial or non-JSON lines.
    }
  }

  return null;
}

function toWindow(limit) {
  if (!limit || typeof limit.used_percent !== "number") return null;
  return {
    used_percentage: Math.round(Math.max(0, Math.min(100, limit.used_percent))),
    resets_at: typeof limit.resets_at === "number" ? limit.resets_at : null,
  };
}

function keepMonotonicUsage(existingWindow, nextWindow) {
  if (!nextWindow) return null;
  if (!existingWindow || typeof existingWindow.used_percentage !== "number") return nextWindow;
  if (existingWindow.resets_at == null || nextWindow.resets_at == null) return nextWindow;
  if (existingWindow.resets_at !== nextWindow.resets_at) return nextWindow;
  if (nextWindow.used_percentage < existingWindow.used_percentage) {
    return {
      ...nextWindow,
      used_percentage: existingWindow.used_percentage,
    };
  }
  return nextWindow;
}

function readJson(filePath) {
  try {
    return JSON.parse(fs.readFileSync(filePath, "utf8"));
  } catch {
    return null;
  }
}

function writeJson(filePath, value) {
  fs.writeFileSync(filePath, `${JSON.stringify(value, null, 2)}\n`);
}

function readFreshResetCreditsCache() {
  const cached = readJson(resetCreditsCachePath);
  if (typeof cached?.available_count !== "number") return null;
  if (typeof cached?.fetched_at_ms !== "number") return null;
  const cachedAccountId = cached?.account_id ?? null;
  const legacyCacheAfterLogin = cachedAccountId === null && Number.isFinite(authLastRefreshMs) && cached.fetched_at_ms >= authLastRefreshMs;
  if (cachedAccountId !== currentAccountId && !legacyCacheAfterLogin) return null;
  if (Date.now() - cached.fetched_at_ms > resetCreditsCacheTtlMs) return null;
  return {
    available_count: cached.available_count,
    fetched_at: cached.fetched_at ?? new Date(cached.fetched_at_ms).toISOString(),
  };
}

function readAnyResetCreditsCache() {
  const cached = readJson(resetCreditsCachePath);
  if (typeof cached?.available_count !== "number") return null;
  const cachedAccountId = cached?.account_id ?? null;
  const legacyCacheAfterLogin = cachedAccountId === null && typeof cached?.fetched_at_ms === "number" && Number.isFinite(authLastRefreshMs) && cached.fetched_at_ms >= authLastRefreshMs;
  if (cachedAccountId !== currentAccountId && !legacyCacheAfterLogin) return null;
  return {
    available_count: cached.available_count,
    fetched_at: cached.fetched_at ?? null,
    stale: true,
  };
}

async function fetchResetCredits() {
  const fresh = readFreshResetCreditsCache();
  if (fresh) return fresh;

  const accessToken = auth?.tokens?.access_token;
  if (typeof accessToken !== "string" || accessToken.length === 0) {
    return readAnyResetCreditsCache();
  }

  try {
    const response = await fetch(resetCreditsEndpoint, {
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "OAI-Language": "en",
        originator: "Codex Desktop",
      },
      signal: AbortSignal.timeout(3_000),
    });
    if (!response.ok) return readAnyResetCreditsCache();

    const body = await response.json();
    if (typeof body?.available_count !== "number") return readAnyResetCreditsCache();

    const value = {
      account_id: currentAccountId,
      available_count: Math.max(0, Math.round(body.available_count)),
      fetched_at: new Date().toISOString(),
      fetched_at_ms: Date.now(),
    };
    writeJson(resetCreditsCachePath, value);
    return {
      available_count: value.available_count,
      fetched_at: value.fetched_at,
    };
  } catch {
    return readAnyResetCreditsCache();
  }
}

let latestLimits = null;
for (const filePath of listJsonlFiles(searchDirs)) {
  const limits = readLatestRateLimits(filePath);
  if (!limits) continue;
  if (Number.isFinite(authLastRefreshMs) && authLastRefreshMs > 0 && limits.timestampMs < authLastRefreshMs) {
    continue;
  }
  if (!latestLimits || limits.timestampMs > latestLimits.timestampMs) {
    latestLimits = limits;
  }
}

const resetCredits = await fetchResetCredits();
const existingSnapshot = readJson(outputPath);

if (latestLimits) {
  const sameAccount = (existingSnapshot?.account_id ?? null) === currentAccountId;
  const fiveHour = keepMonotonicUsage(sameAccount ? existingSnapshot?.five_hour : null, toWindow(latestLimits.primary));
  const sevenDay = keepMonotonicUsage(sameAccount ? existingSnapshot?.seven_day : null, toWindow(latestLimits.secondary));
  const snapshot = {
    updated_at: new Date().toISOString(),
    account_id: currentAccountId,
    auth_last_refresh: Number.isFinite(authLastRefreshMs) && authLastRefreshMs > 0 ? new Date(authLastRefreshMs).toISOString() : null,
    source_file: latestLimits.filePath,
    source_timestamp: latestLimits.timestampMs ? new Date(latestLimits.timestampMs).toISOString() : null,
    five_hour: fiveHour,
    seven_day: sevenDay,
    reset_credits: resetCredits,
  };

  writeJson(outputPath, snapshot);
  process.exit(0);
}

try {
  const existing = existingSnapshot;
  const sameAccount = (existing?.account_id ?? null) === currentAccountId;
  if (sameAccount && (existing?.five_hour || existing?.seven_day || existing?.reset_credits || resetCredits)) {
    const snapshot = {
      ...existing,
      updated_at: new Date().toISOString(),
      account_id: currentAccountId,
      auth_last_refresh: Number.isFinite(authLastRefreshMs) && authLastRefreshMs > 0 ? new Date(authLastRefreshMs).toISOString() : null,
      stale_source: true,
      reset_credits: resetCredits ?? existing.reset_credits ?? null,
    };
    writeJson(outputPath, snapshot);
  } else {
    writeJson(outputPath, {
      updated_at: new Date().toISOString(),
      account_id: currentAccountId,
      auth_last_refresh: Number.isFinite(authLastRefreshMs) && authLastRefreshMs > 0 ? new Date(authLastRefreshMs).toISOString() : null,
      stale_source: true,
      five_hour: null,
      seven_day: null,
      reset_credits: resetCredits,
    });
  }
} catch {
  // No usable prior snapshot to keep alive.
}

process.exit(0);

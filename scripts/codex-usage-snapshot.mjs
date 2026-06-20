#!/usr/bin/env node
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import crypto from "node:crypto";

const codexHome = process.env.CODEX_HOME || path.join(os.homedir(), ".codex");
const searchDirs = [
  path.join(codexHome, "sessions"),
  path.join(codexHome, "archived_sessions"),
];
const outputPath = process.argv[2] || path.join(codexHome, "codex-usage-snapshot.json");
const resetCreditsCachePath = path.join(codexHome, "codex-rate-limit-reset-credits-cache.json");
const accountStatePath = path.join(codexHome, "codex-usage-account-state.json");
const usageEndpoint = "https://chatgpt.com/backend-api/wham/usage";
const resetCreditsEndpoint = "https://chatgpt.com/backend-api/wham/rate-limit-reset-credits";
const resetCreditsCacheTtlMs = 30_000;
const auth = readJson(path.join(codexHome, "auth.json"));
const currentAccountId = typeof auth?.tokens?.account_id === "string" ? auth.tokens.account_id : null;
const currentAccessToken = typeof auth?.tokens?.access_token === "string" ? auth.tokens.access_token : null;
const currentAccountFingerprint = currentAccountId
  ? accountFingerprint("account", currentAccountId)
  : currentAccessToken
    ? accountFingerprint("token", currentAccessToken)
    : null;
const authLastRefreshMs = typeof auth?.last_refresh === "string" ? Date.parse(auth.last_refresh) : 0;

function accountFingerprint(kind, value) {
  return `${kind}:${crypto.createHash("sha256").update(value).digest("hex").slice(0, 16)}`;
}

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

function toUsageWindow(window) {
  if (!window || typeof window.used_percent !== "number") return null;
  const resetAt = typeof window.reset_at === "number"
    ? window.reset_at
    : typeof window.resets_at === "number"
      ? window.resets_at
      : null;
  return {
    used_percentage: Math.round(Math.max(0, Math.min(100, window.used_percent))),
    resets_at: resetAt,
  };
}

function normalizePlanType(planType) {
  if (typeof planType !== "string") return null;
  const value = planType.trim().toLowerCase();
  if (value === "free") return "free";
  if (value === "plus") return "plus";
  if (value === "pro" || value === "pro5x" || value === "pro_5x" || value === "pro-5x") return "pro5x";
  if (value === "pro20x" || value === "pro_20x" || value === "pro-20x") return "pro20x";
  return null;
}

function normalizeBalanceUsd(balance) {
  if (typeof balance === "number" && Number.isFinite(balance)) return String(balance);
  if (typeof balance !== "string") return null;
  const value = balance.trim();
  return value.length > 0 ? value : null;
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

function mergeWindow(existingWindow, nextWindow, canKeepExisting) {
  if (!nextWindow && canKeepExisting) return existingWindow ?? null;
  return keepMonotonicUsage(canKeepExisting ? existingWindow : null, nextWindow);
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

function readAccountState(existingSnapshot) {
  const state = readJson(accountStatePath);
  const hasExistingSnapshot = existingSnapshot && typeof existingSnapshot === "object";
  const stateFingerprint = state?.account_fingerprint ?? null;
  const stateMissing = typeof stateFingerprint !== "string";
  const accountChanged = stateMissing
    ? hasExistingSnapshot
    : stateFingerprint !== currentAccountFingerprint;
  const rateLimitsAfterMs = accountChanged
    ? Date.now()
    : typeof state?.rate_limits_after_ms === "number"
      ? state.rate_limits_after_ms
      : 0;

  writeJson(accountStatePath, {
    account_fingerprint: currentAccountFingerprint,
    rate_limits_after_ms: rateLimitsAfterMs,
    observed_at: new Date().toISOString(),
  });

  return { accountChanged, rateLimitsAfterMs };
}

function sameAccountFingerprint(value) {
  if (value == null && currentAccountFingerprint == null) return true;
  return value === currentAccountFingerprint;
}

function cacheMatchesCurrentAccount(cached) {
  const cachedFingerprint = cached?.account_fingerprint ?? null;
  if (sameAccountFingerprint(cachedFingerprint)) return true;

  // One-time compatibility with older local cache files that stored raw account_id.
  if (currentAccountId && cached?.account_id === currentAccountId) return true;
  return false;
}

function snapshotMatchesCurrentAccount(snapshot) {
  const snapshotFingerprint = snapshot?.account_fingerprint ?? null;
  if (sameAccountFingerprint(snapshotFingerprint)) return true;

  // One-time compatibility with older local snapshot files that stored raw account_id.
  if (currentAccountId && snapshot?.account_id === currentAccountId) return true;
  return false;
}

function sanitizeResetCreditsCache(cached) {
  if (typeof cached?.available_count !== "number") return;
  if (typeof cached?.fetched_at_ms !== "number") return;
  if (cached.account_id == null && cached.account_fingerprint === currentAccountFingerprint) return;

  writeJson(resetCreditsCachePath, {
    account_fingerprint: currentAccountFingerprint,
    available_count: cached.available_count,
    fetched_at: cached.fetched_at ?? new Date(cached.fetched_at_ms).toISOString(),
    fetched_at_ms: cached.fetched_at_ms,
  });
}

function removeMismatchedLegacyResetCreditsCache(cached) {
  if (cached?.account_id == null) return;
  if (cacheMatchesCurrentAccount(cached)) return;

  try {
    fs.rmSync(resetCreditsCachePath, { force: true });
  } catch {
    // Ignore cache cleanup failures; the cache will not be used.
  }
}

function readFreshResetCreditsCache() {
  const cached = readJson(resetCreditsCachePath);
  if (typeof cached?.available_count !== "number") return null;
  if (typeof cached?.fetched_at_ms !== "number") return null;
  const legacyCacheAfterLogin = cached?.account_fingerprint == null && cached?.account_id == null && Number.isFinite(authLastRefreshMs) && cached.fetched_at_ms >= authLastRefreshMs;
  if (!cacheMatchesCurrentAccount(cached) && !legacyCacheAfterLogin) {
    removeMismatchedLegacyResetCreditsCache(cached);
    return null;
  }
  if (Date.now() - cached.fetched_at_ms > resetCreditsCacheTtlMs) return null;
  sanitizeResetCreditsCache(cached);
  return {
    available_count: cached.available_count,
    fetched_at: cached.fetched_at ?? new Date(cached.fetched_at_ms).toISOString(),
  };
}

function readAnyResetCreditsCache() {
  const cached = readJson(resetCreditsCachePath);
  if (typeof cached?.available_count !== "number") return null;
  const legacyCacheAfterLogin = cached?.account_fingerprint == null && cached?.account_id == null && typeof cached?.fetched_at_ms === "number" && Number.isFinite(authLastRefreshMs) && cached.fetched_at_ms >= authLastRefreshMs;
  if (!cacheMatchesCurrentAccount(cached) && !legacyCacheAfterLogin) {
    removeMismatchedLegacyResetCreditsCache(cached);
    return null;
  }
  sanitizeResetCreditsCache(cached);
  return {
    available_count: cached.available_count,
    fetched_at: cached.fetched_at ?? null,
    stale: true,
  };
}

async function fetchResetCredits() {
  const fresh = readFreshResetCreditsCache();
  if (fresh) return fresh;

  const accessToken = currentAccessToken;
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
      account_fingerprint: currentAccountFingerprint,
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

async function fetchUsage() {
  const accessToken = currentAccessToken;
  if (typeof accessToken !== "string" || accessToken.length === 0) return null;

  try {
    const response = await fetch(usageEndpoint, {
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "OAI-Language": "en",
        originator: "Codex Desktop",
      },
      signal: AbortSignal.timeout(5_000),
    });
    if (!response.ok) return null;

    const body = await response.json();
    const rateLimit = body?.rate_limit;
    const fiveHour = toUsageWindow(rateLimit?.primary_window);
    const sevenDay = toUsageWindow(rateLimit?.secondary_window);
    const planType = normalizePlanType(body?.plan_type);
    const balanceUsd = normalizeBalanceUsd(body?.credits?.balance);
    const availableCount = body?.rate_limit_reset_credits?.available_count;
    const resetCredits = typeof availableCount === "number"
      ? {
          available_count: Math.max(0, Math.round(availableCount)),
          fetched_at: new Date().toISOString(),
        }
      : null;

    if (!fiveHour && !sevenDay && !resetCredits && !balanceUsd) return null;
    return {
      five_hour: fiveHour,
      seven_day: sevenDay,
      plan_type: planType,
      balance_usd: balanceUsd,
      reset_credits: resetCredits,
    };
  } catch {
    return null;
  }
}

const existingSnapshot = readJson(outputPath);
const accountState = readAccountState(existingSnapshot);
const existingSameAccount = !accountState.accountChanged && snapshotMatchesCurrentAccount(existingSnapshot);

let latestLimits = null;
for (const filePath of listJsonlFiles(searchDirs)) {
  const limits = readLatestRateLimits(filePath);
  if (!limits) continue;
  if (accountState.rateLimitsAfterMs > 0 && limits.timestampMs < accountState.rateLimitsAfterMs) continue;

  const isFreshForCurrentLogin = !(Number.isFinite(authLastRefreshMs) && authLastRefreshMs > 0 && limits.timestampMs < authLastRefreshMs);
  if (!isFreshForCurrentLogin) continue;

  if (!latestLimits || limits.timestampMs > latestLimits.timestampMs) {
    latestLimits = limits;
  }
}

const usage = await fetchUsage();
const resetCredits = usage?.reset_credits ?? await fetchResetCredits();

if (usage?.five_hour || usage?.seven_day) {
  const snapshot = {
    updated_at: new Date().toISOString(),
    account_fingerprint: currentAccountFingerprint,
    auth_last_refresh: Number.isFinite(authLastRefreshMs) && authLastRefreshMs > 0 ? new Date(authLastRefreshMs).toISOString() : null,
    source: "wham_usage",
    stale_source: false,
    plan_type: usage.plan_type,
    balance_usd: usage.balance_usd,
    five_hour: usage.five_hour,
    seven_day: usage.seven_day,
    reset_credits: resetCredits,
  };

  writeJson(outputPath, snapshot);
  process.exit(0);
}

const selectedLimits = latestLimits;

if (selectedLimits) {
  const fiveHour = mergeWindow(existingSnapshot?.five_hour, toWindow(selectedLimits.primary), existingSameAccount);
  const sevenDay = mergeWindow(existingSnapshot?.seven_day, toWindow(selectedLimits.secondary), existingSameAccount);
  const snapshot = {
    updated_at: new Date().toISOString(),
    account_fingerprint: currentAccountFingerprint,
    auth_last_refresh: Number.isFinite(authLastRefreshMs) && authLastRefreshMs > 0 ? new Date(authLastRefreshMs).toISOString() : null,
    source_file: selectedLimits.filePath,
    source_timestamp: selectedLimits.timestampMs ? new Date(selectedLimits.timestampMs).toISOString() : null,
    stale_source: false,
    plan_type: null,
    balance_usd: usage?.balance_usd ?? null,
    five_hour: fiveHour,
    seven_day: sevenDay,
    reset_credits: resetCredits,
  };

  writeJson(outputPath, snapshot);
  process.exit(0);
}

try {
  writeJson(outputPath, {
    updated_at: new Date().toISOString(),
    account_fingerprint: currentAccountFingerprint,
    auth_last_refresh: Number.isFinite(authLastRefreshMs) && authLastRefreshMs > 0 ? new Date(authLastRefreshMs).toISOString() : null,
    source: "unavailable",
    stale_source: true,
    plan_type: usage?.plan_type ?? null,
    balance_usd: usage?.balance_usd ?? null,
    five_hour: null,
    seven_day: null,
    reset_credits: resetCredits,
  });
} catch {
  // No usable prior snapshot to keep alive.
}

process.exit(0);

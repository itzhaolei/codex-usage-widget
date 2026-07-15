import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";

const root = path.resolve(import.meta.dirname, "..");
const widget = fs.readFileSync(path.join(root, "windows/QuotaBubble.ps1"), "utf8");
const installer = fs.readFileSync(path.join(root, "windows/install.ps1"), "utf8");
const packager = fs.readFileSync(path.join(root, "scripts/package-windows.sh"), "utf8");

assert.match(widget, /\$script:Version = if \(Test-Path \$versionPath\)/, "version is loaded dynamically");
assert.doesNotMatch(widget, /\$script:Version = "2\.1\.3"/, "legacy hard-coded version removed");
assert.doesNotMatch(widget, /SetupOverlay|Get-SetupIssue|missingCli/, "legacy setup overlay removed");
assert.match(widget, /Read-VerifiedSnapshot/, "snapshot is account verified");
assert.match(widget, /\$credits\.expires_at/, "reset expiration list is rendered");
assert.match(widget, /AccountText/, "account row is present");
assert.match(widget, /SubscriptionText/, "subscription row is present");
assert.match(widget, /Install-LatestUpdate/, "Windows updater is present");
for (const code of ["en", "zh", "ja", "ko", "de", "fr", "es", "pt", "it", "nl"]) {
  assert.match(widget, new RegExp(`\\b${code} = @\\{`), `${code} localization exists`);
}
assert.match(installer, /Set-Content -Path \(Join-Path \$installDir "VERSION"\)/, "installer writes dynamic version");
assert.match(packager, /QuotaBubble-\$VERSION\/VERSION/, "package includes VERSION metadata");

console.log("Windows static tests passed.");

import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";

const root = path.resolve(import.meta.dirname, "..");
const read = (relative) => fs.readFileSync(path.join(root, relative), "utf8");
const project = read("windows/QuotaBubble/QuotaBubble.csproj");
const app = read("windows/QuotaBubble/App.xaml.cs");
const window = read("windows/QuotaBubble/MainWindow.xaml.cs");
const quota = read("windows/QuotaBubble/Services/QuotaService.cs");
const auth = read("windows/QuotaBubble/Services/AuthService.cs");
const updater = read("windows/QuotaBubble/Services/UpdateService.cs");
const installer = read("windows/installer.iss");
const compatibilityInstaller = read("windows/compat/install.ps1");
const workflow = read(".github/workflows/release-windows.yml");

assert.match(project, /<OutputType>WinExe<\/OutputType>/, "Windows client is a compiled GUI app");
assert.match(project, /<SelfContained>true<\/SelfContained>/, "runtime is self-contained");
assert.match(project, /<PublishSingleFile>true<\/PublishSingleFile>/, "app publishes as a single executable");
assert.match(app, /Local\\\\QuotaBubble\.Windows\.App/, "single-instance mutex is present");
assert.match(auth, /accountId is null \? "token" : "account"/, "quota is bound to account identity");
assert.match(quota, /if \(identity\?\.Fingerprint != CurrentIdentity\?\.Fingerprint\)/, "account changes clear cached values");
assert.doesNotMatch(quota, /codex-usage-snapshot\.mjs|node\.exe|powershell/i, "native data service has no script runtime dependency");
assert.match(window, /DispatcherTimer/, "one-second UI refresh timer is present");
assert.match(window, /Forms\.NotifyIcon/, "native tray integration is present");
assert.match(updater, /Windows-Setup\.exe/, "updater downloads the graphical installer");
assert.match(installer, /PrivilegesRequired=lowest/, "installer supports non-admin per-user installation");
assert.match(installer, /\[UninstallRun\]/, "installer provides graphical uninstall support");
assert.match(compatibilityInstaller, /Windows-Setup\.exe/, "legacy updater bridge launches the graphical installer");
assert.match(workflow, /Windows\.zip/, "release retains an automatic migration path for the previous updater");
assert.match(workflow, /dotnet publish/, "Windows CI compiles the application");
assert.match(workflow, /Smoke launch installed application/, "Windows CI launches the installed app");
for (const code of ["en", "zh", "ja", "ko", "de", "fr", "es", "pt", "it", "nl"]) {
  assert.match(read("windows/QuotaBubble/Localization.cs"), new RegExp(`\\["${code}"\\]`), `${code} localization exists`);
}
for (const legacy of ["windows/QuotaBubble.ps1", "windows/install.ps1", "windows/uninstall.ps1"]) {
  assert.equal(fs.existsSync(path.join(root, legacy)), false, `${legacy} was removed`);
}

console.log("Windows native application static tests passed.");

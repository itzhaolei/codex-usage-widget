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
const updateProgressWindow = read("windows/QuotaBubble/UpdateProgressWindow.cs");
const capacity = read("windows/QuotaBubble/Services/SystemCapacityService.cs");
const windowXaml = read("windows/QuotaBubble/MainWindow.xaml");
const installer = read("windows/installer.iss");
const compatibilityInstaller = read("windows/compat/install.ps1");
const workflow = read(".github/workflows/release-windows.yml");

assert.match(project, /<OutputType>WinExe<\/OutputType>/, "Windows client is a compiled GUI app");
assert.match(project, /<SelfContained>true<\/SelfContained>/, "runtime is self-contained");
assert.match(project, /<PublishSingleFile>true<\/PublishSingleFile>/, "app publishes as a single executable");
assert.match(app, /Local\\\\QuotaBubble\.Windows\.App/, "single-instance mutex is present");
assert.match(auth, /accountId is null \? "token" : "account"/, "quota is bound to account identity");
assert.match(quota, /if \(identity\?\.Fingerprint != CurrentIdentity\?\.Fingerprint\)/, "account changes clear cached values");
assert.match(quota, /var fiveHour = secondary is null \? null : primary/, "single quota window is not treated as five-hour quota");
assert.match(quota, /var sevenDay = secondary \?\? primary/, "single quota window maps to weekly quota");
assert.match(quota, /fiveHour is null && sevenDay is not null \? null : Stabilize/, "weekly-only quota clears stale five-hour values");
assert.doesNotMatch(quota, /codex-usage-snapshot\.mjs|node\.exe|powershell/i, "native data service has no script runtime dependency");
assert.match(window, /DispatcherTimer/, "one-second UI refresh timer is present");
assert.match(window, /Forms\.NotifyIcon/, "native tray integration is present");
assert.match(window, /snapshot\?\.SevenDay is null \? null : snapshot\?\.FiveHour/, "five-hour block is shown only when weekly quota also exists");
assert.match(window, /UpdateTrayStatus\(Remaining\(fiveHour \?\? weekly\)\)/, "tray status prioritizes five-hour quota when present");
assert.match(window, /CloseButton\.Click \+= \(_, _\) => HideWindow\(\)/, "window close button hides the window");
assert.match(window, /e\.Cancel = true;\s*HideWindow\(\)/, "system window close is converted to hide");
assert.match(window, /exit\.Click \+= \(_, _\) => ExitApplication\(\)/, "tray exit remains an explicit application exit");
assert.doesNotMatch(window.match(/private void HideWindow\(\)[\s\S]*?\n    }/)?.[0] ?? "", /_timer\.Stop|Shutdown|Dispose/, "hiding keeps background refresh and tray status alive");
assert.match(windowXaml, /FiveHourQuotaPanel/, "Windows UI contains separate five-hour quota block");
assert.match(windowXaml, /StorageText/, "Windows UI contains the C drive capacity row");
assert.match(windowXaml, /MemoryText/, "Windows UI contains the physical memory row");
assert.match(windowXaml, /AccountIcon[\s\S]*SubscriptionIcon[\s\S]*StorageIcon[\s\S]*MemoryIcon/, "information rows use deterministic vector icons");
assert.doesNotMatch(windowXaml, /Content="[●▣☀☾×]"/, "controls and information rows do not depend on font glyph icons");
assert.match(windowXaml, /MetricCards[\s\S]*Height="47"/, "single-line metric cards match the compact macOS height");
assert.match(windowXaml, /x:Name="ResetText"[^>]*MaxWidth="118"/, "weekly reset countdown can extend beyond the progress bar width");
assert.match(windowXaml, /Background="#00C229"/, "Windows exposes the macOS progress color palette");
for (const color of windowXaml.match(/#[0-9A-Fa-f]+/g) ?? []) {
  assert.ok(color.length === 7 || color.length === 9, `XAML color ${color} uses RGB or ARGB syntax`);
}
assert.ok(capacity.includes('new DriveInfo(@"C:\\")'), "system capacity reads the C drive");
assert.match(capacity, /GlobalMemoryStatusEx/, "system capacity reads Windows physical memory through the native API");
assert.match(window, /RenderSystemCapacity\(\)/, "system capacity values refresh with the window");
assert.match(window, /Math\.Round\(value\)/, "balance formatting matches the integer macOS display");
assert.match(updater, /Windows-Setup\.exe/, "updater downloads the graphical installer");
assert.match(updater, /releases\?per_page=30/, "Windows updater scans releases for the newest Windows asset");
assert.doesNotMatch(updater, /api\.github\.com\/repos\/[^\s"]+\/releases\/latest/, "Windows updater does not rely on the API's latest release only");
assert.match(updater, /DefaultProxyCredentials = CredentialCache\.DefaultCredentials/, "Windows updater uses the signed-in user's system proxy credentials");
assert.match(updater, /cdn\.jsdelivr\.net/, "Windows updater has a CDN-hosted manifest fallback");
assert.match(updater, /LatestFromReleaseRedirectAsync/, "Windows updater falls back to the GitHub releases redirect when the API is unavailable");
assert.doesNotMatch(updater, /HttpMethod\.Head/, "release lookup does not fail while probing the installer download host");
assert.match(updater, /IProgress<DownloadProgress>/, "Windows updater reports download progress");
assert.match(updater, /ReadAsync\(buffer\.AsMemory/, "Windows updater streams the installer in measurable chunks");
assert.match(updateProgressWindow, /ProgressBar/, "Windows update dialog contains a progress bar");
assert.match(updateProgressWindow, /percentage[\s\S]*receivedMb[\s\S]*totalBytes/, "Windows update dialog shows percentage and byte progress");
assert.match(window, /new Progress<DownloadProgress>\(progressWindow\.Report\)/, "interactive updates connect download progress to the dialog");
assert.match(window, /if \(_checkingUpdate\) return;/, "only one update check or progress dialog can run at a time");
assert.doesNotMatch(window, /MessageBox\.Show\(this, copy\.Updating/, "download no longer uses a blocking information message box");
assert.match(window, /UpdateService\.OpenReleasesPage/, "interactive update failures open the manual download page");
assert.doesNotMatch(window, /Windows installer asset not found/, "Windows update action does not show missing asset errors for macOS-only releases");
assert.match(installer, /PrivilegesRequired=lowest/, "installer supports non-admin per-user installation");
assert.match(installer, /UsePreviousAppDir=yes/, "upgrades explicitly reuse the existing installation directory");
assert.match(installer, /UsePreviousTasks=yes/, "upgrades preserve the existing startup choice");
assert.match(installer, /\[InstallDelete\][\s\S]*QuotaBubble\.ps1[\s\S]*windows-state\.json[\s\S]*codex-usage-snapshot\.mjs/, "native upgrades remove legacy PowerShell installation files");
assert.match(installer, /Name: "\{autodesktop\}\\Quota Bubble"; Filename: "\{app\}\\QuotaBubble\.exe"\s*$/m, "installer always creates a desktop shortcut");
assert.doesNotMatch(installer, /Name: "desktopicon"/, "desktop shortcut is not optional");
assert.match(installer, /\[UninstallRun\]/, "installer provides graphical uninstall support");
assert.match(compatibilityInstaller, /Windows-Setup\.exe/, "legacy updater bridge launches the graphical installer");
assert.match(workflow, /Windows\.zip/, "release retains an automatic migration path for the previous updater");
assert.match(workflow, /dotnet publish/, "Windows CI compiles the application");
assert.match(workflow, /Smoke launch installed application/, "Windows CI launches the installed app");
assert.match(workflow, /Desktop shortcut was not created/, "Windows CI verifies the desktop shortcut");
assert.match(workflow, /Legacy Windows file was not removed/, "Windows CI verifies legacy installation cleanup");
for (const code of ["en", "zh", "ja", "ko", "de", "fr", "es", "pt", "it", "nl"]) {
  assert.match(read("windows/QuotaBubble/Localization.cs"), new RegExp(`\\["${code}"\\]`), `${code} localization exists`);
}
for (const legacy of ["windows/QuotaBubble.ps1", "windows/install.ps1", "windows/uninstall.ps1"]) {
  assert.equal(fs.existsSync(path.join(root, legacy)), false, `${legacy} was removed`);
}

console.log("Windows native application static tests passed.");

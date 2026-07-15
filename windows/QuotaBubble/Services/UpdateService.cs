using System.Diagnostics;
using System.Net.Http.Headers;
using System.Text.Json;

namespace QuotaBubble.Services;

public sealed record ReleaseInfo(Version Version, string Tag, string? InstallerUrl);

public sealed class UpdateService : IDisposable
{
    private readonly HttpClient _client = new() { Timeout = TimeSpan.FromSeconds(30) };

    public UpdateService() => _client.DefaultRequestHeaders.UserAgent.ParseAdd("Quota-Bubble-Windows/1.0");

    public async Task<ReleaseInfo?> LatestAsync(CancellationToken cancellationToken = default)
    {
        using var response = await _client.GetAsync(
            "https://api.github.com/repos/itzhaolei/codex-usage-widget/releases/latest", cancellationToken);
        response.EnsureSuccessStatusCode();
        using var document = JsonDocument.Parse(await response.Content.ReadAsStreamAsync(cancellationToken));
        var root = document.RootElement;
        var tag = root.GetProperty("tag_name").GetString() ?? "";
        if (!Version.TryParse(tag.TrimStart('v'), out var version)) return null;
        string? installer = null;
        if (root.TryGetProperty("assets", out var assets))
        {
            foreach (var asset in assets.EnumerateArray())
            {
                var name = asset.GetProperty("name").GetString() ?? "";
                if (!name.Contains("Windows", StringComparison.OrdinalIgnoreCase) ||
                    !name.EndsWith("Setup.exe", StringComparison.OrdinalIgnoreCase)) continue;
                installer = asset.GetProperty("browser_download_url").GetString();
                break;
            }
        }
        return new ReleaseInfo(version, tag, installer);
    }

    public async Task DownloadAndInstallAsync(ReleaseInfo release, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(release.InstallerUrl)) throw new InvalidOperationException("Windows installer asset not found.");
        var directory = Path.Combine(Path.GetTempPath(), "QuotaBubble", release.Tag);
        Directory.CreateDirectory(directory);
        var path = Path.Combine(directory, $"QuotaBubble-{release.Version}-Windows-Setup.exe");
        using (var response = await _client.GetAsync(release.InstallerUrl, HttpCompletionOption.ResponseHeadersRead, cancellationToken))
        {
            response.EnsureSuccessStatusCode();
            await using var input = await response.Content.ReadAsStreamAsync(cancellationToken);
            await using var output = File.Create(path);
            await input.CopyToAsync(output, cancellationToken);
        }
        Process.Start(new ProcessStartInfo(path, "/SILENT /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS") { UseShellExecute = true });
    }

    public void Dispose() => _client.Dispose();
}

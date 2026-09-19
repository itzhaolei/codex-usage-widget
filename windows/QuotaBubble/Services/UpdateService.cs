using System.Diagnostics;
using System.IO;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text.Json;

namespace QuotaBubble.Services;

public sealed record ReleaseInfo(Version Version, string Tag, string InstallerUrl);

public sealed class UpdateService : IDisposable
{
    private readonly HttpClient _client = new() { Timeout = TimeSpan.FromSeconds(30) };

    public UpdateService() => _client.DefaultRequestHeaders.UserAgent.ParseAdd("Quota-Bubble-Windows/1.0");

    public async Task<ReleaseInfo?> LatestAsync(CancellationToken cancellationToken = default)
    {
        using var response = await _client.GetAsync(
            "https://api.github.com/repos/itzhaolei/codex-usage-widget/releases?per_page=30", cancellationToken);
        response.EnsureSuccessStatusCode();
        using var document = JsonDocument.Parse(await response.Content.ReadAsStreamAsync(cancellationToken));
        foreach (var release in document.RootElement.EnumerateArray())
        {
            var tag = release.GetProperty("tag_name").GetString() ?? "";
            if (!Version.TryParse(tag.TrimStart('v'), out var version)) continue;
            var installer = WindowsInstallerUrl(release);
            if (!string.IsNullOrWhiteSpace(installer)) return new ReleaseInfo(version, tag, installer);
        }
        return null;
    }

    public async Task DownloadAndInstallAsync(ReleaseInfo release, CancellationToken cancellationToken = default)
    {
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

    private static string? WindowsInstallerUrl(JsonElement release)
    {
        if (!release.TryGetProperty("assets", out var assets)) return null;
        foreach (var asset in assets.EnumerateArray())
        {
            var name = asset.GetProperty("name").GetString() ?? "";
            if (!name.Contains("Windows", StringComparison.OrdinalIgnoreCase) ||
                !name.EndsWith("Setup.exe", StringComparison.OrdinalIgnoreCase)) continue;
            return asset.GetProperty("browser_download_url").GetString();
        }
        return null;
    }

    public void Dispose() => _client.Dispose();
}

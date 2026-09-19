using System.Diagnostics;
using System.IO;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text.Json;

namespace QuotaBubble.Services;

public sealed record ReleaseInfo(Version Version, string Tag, string InstallerUrl);
public sealed record DownloadProgress(long BytesReceived, long? TotalBytes)
{
    public int? Percentage => TotalBytes is > 0
        ? (int)Math.Clamp(BytesReceived * 100 / TotalBytes.Value, 0, 100)
        : null;
}

public sealed class UpdateService : IDisposable
{
    public const string ReleasesUrl = "https://github.com/itzhaolei/codex-usage-widget/releases";
    private const string LatestReleaseUrl = ReleasesUrl + "/latest";
    private const string CdnManifestUrl = "https://cdn.jsdelivr.net/gh/itzhaolei/codex-usage-widget@main/public/update.json";
    private readonly HttpClient _client;

    public UpdateService()
    {
        var handler = new HttpClientHandler
        {
            AutomaticDecompression = DecompressionMethods.All,
            DefaultProxyCredentials = CredentialCache.DefaultCredentials
        };
        _client = new HttpClient(handler) { Timeout = TimeSpan.FromSeconds(30) };
        _client.DefaultRequestHeaders.UserAgent.ParseAdd("Quota-Bubble-Windows/1.0");
    }

    public async Task<ReleaseInfo?> LatestAsync(CancellationToken cancellationToken = default)
    {
        Exception? apiFailure = null;
        try
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
        catch (Exception error) when (error is HttpRequestException or TaskCanceledException)
        {
            apiFailure = error;
        }

        Exception? cdnFailure = null;
        try
        {
            var manifest = await LatestFromCdnManifestAsync(cancellationToken);
            if (manifest is not null) return manifest;
        }
        catch (Exception error) when (error is HttpRequestException or TaskCanceledException or JsonException)
        {
            cdnFailure = error;
        }

        try
        {
            return await LatestFromReleaseRedirectAsync(cancellationToken);
        }
        catch (Exception error) when (error is HttpRequestException or TaskCanceledException)
        {
            throw new HttpRequestException(
                "Unable to connect to the update server.",
                new AggregateException(new[] { apiFailure, cdnFailure, error }.OfType<Exception>()));
        }
    }

    public static void OpenReleasesPage() => Process.Start(new ProcessStartInfo(ReleasesUrl) { UseShellExecute = true });

    public async Task DownloadAndInstallAsync(
        ReleaseInfo release,
        IProgress<DownloadProgress>? progress = null,
        CancellationToken cancellationToken = default)
    {
        var directory = Path.Combine(Path.GetTempPath(), "QuotaBubble", release.Tag);
        Directory.CreateDirectory(directory);
        var path = Path.Combine(directory, $"QuotaBubble-{release.Version}-Windows-Setup.exe");
        using (var response = await _client.GetAsync(release.InstallerUrl, HttpCompletionOption.ResponseHeadersRead, cancellationToken))
        {
            response.EnsureSuccessStatusCode();
            await using var input = await response.Content.ReadAsStreamAsync(cancellationToken);
            await using var output = File.Create(path);
            var totalBytes = response.Content.Headers.ContentLength;
            var bytesReceived = 0L;
            var buffer = new byte[81_920];
            progress?.Report(new DownloadProgress(bytesReceived, totalBytes));
            while (true)
            {
                var count = await input.ReadAsync(buffer.AsMemory(0, buffer.Length), cancellationToken);
                if (count == 0) break;
                await output.WriteAsync(buffer.AsMemory(0, count), cancellationToken);
                bytesReceived += count;
                progress?.Report(new DownloadProgress(bytesReceived, totalBytes));
            }
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

    private async Task<ReleaseInfo?> LatestFromReleaseRedirectAsync(CancellationToken cancellationToken)
    {
        using var response = await _client.GetAsync(LatestReleaseUrl, HttpCompletionOption.ResponseHeadersRead, cancellationToken);
        response.EnsureSuccessStatusCode();
        var finalUri = response.RequestMessage?.RequestUri;
        var tag = finalUri?.Segments.LastOrDefault()?.Trim('/');
        if (string.IsNullOrWhiteSpace(tag) || !Version.TryParse(tag.TrimStart('v'), out var version)) return null;

        var installerUrl = $"{ReleasesUrl}/download/{Uri.EscapeDataString(tag)}/QuotaBubble-{version}-Windows-Setup.exe";
        return new ReleaseInfo(version, tag, installerUrl);
    }

    private async Task<ReleaseInfo?> LatestFromCdnManifestAsync(CancellationToken cancellationToken)
    {
        var cacheKey = DateTimeOffset.UtcNow.ToString("yyyyMMddHH");
        using var response = await _client.GetAsync($"{CdnManifestUrl}?v={cacheKey}", cancellationToken);
        response.EnsureSuccessStatusCode();
        using var document = JsonDocument.Parse(await response.Content.ReadAsStreamAsync(cancellationToken));
        var root = document.RootElement;
        var tag = root.GetProperty("tag").GetString() ?? "";
        var installerUrl = root.GetProperty("windows_installer_url").GetString() ?? "";
        if (!Version.TryParse(tag.TrimStart('v'), out var version) || string.IsNullOrWhiteSpace(installerUrl)) return null;
        return new ReleaseInfo(version, tag, installerUrl);
    }

    public void Dispose() => _client.Dispose();
}

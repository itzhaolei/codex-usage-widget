using System.Globalization;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text.Json;

namespace QuotaBubble.Services;

public sealed class QuotaService : IDisposable
{
    private static readonly Uri UsageUri = new("https://chatgpt.com/backend-api/wham/usage");
    private static readonly Uri ResetUri = new("https://chatgpt.com/backend-api/wham/rate-limit-reset-credits");
    private readonly HttpClient _client = new() { Timeout = TimeSpan.FromSeconds(6) };
    private readonly AuthService _auth = new();
    private QuotaSnapshot? _last;
    private ResetCredits? _resetCache;
    private DateTimeOffset _resetCacheAt = DateTimeOffset.MinValue;
    private DateTimeOffset? _authReadFailureSince;

    public AuthIdentity? CurrentIdentity { get; private set; }

    public async Task<QuotaSnapshot?> RefreshAsync(CancellationToken cancellationToken)
    {
        var identity = _auth.Read();
        if (identity is null && _auth.AuthFileExists && CurrentIdentity is not null)
        {
            _authReadFailureSince ??= DateTimeOffset.UtcNow;
            if (DateTimeOffset.UtcNow - _authReadFailureSince < TimeSpan.FromSeconds(3)) identity = CurrentIdentity;
        }
        else _authReadFailureSince = null;
        if (identity?.Fingerprint != CurrentIdentity?.Fingerprint)
        {
            _last = null;
            _resetCache = null;
            _resetCacheAt = DateTimeOffset.MinValue;
        }
        CurrentIdentity = identity;
        if (identity is null) return null;

        try
        {
            using var request = Request(UsageUri, identity.AccessToken);
            using var response = await _client.SendAsync(request, cancellationToken);
            response.EnsureSuccessStatusCode();
            using var body = JsonDocument.Parse(await response.Content.ReadAsStreamAsync(cancellationToken));
            var confirmedIdentity = _auth.Read();
            if (confirmedIdentity?.Fingerprint != identity.Fingerprint)
            {
                CurrentIdentity = confirmedIdentity;
                _last = null;
                _resetCache = null;
                return null;
            }
            var root = body.RootElement;
            var rateLimit = Property(root, "rate_limit");
            var primary = Window(Property(rateLimit, "primary_window"));
            var secondary = Window(Property(rateLimit, "secondary_window"));
            var reset = ResetCredits(Property(root, "rate_limit_reset_credits"));
            if (reset is null || (reset.AvailableCount > 0 && reset.ExpiresAt.Count == 0))
                reset = await RefreshResetCreditsAsync(identity, cancellationToken) ?? reset;

            var next = new QuotaSnapshot(
                identity.Fingerprint,
                Plan(root),
                Balance(root),
                Stabilize(_last?.FiveHour, primary),
                Stabilize(_last?.SevenDay, secondary),
                reset ?? _last?.ResetCredits,
                DateTimeOffset.UtcNow,
                false);
            if (next.FiveHour is null && next.SevenDay is null && next.ResetCredits is null && next.BalanceUsd is null)
                return _last;
            _last = next;
            return next;
        }
        catch when (!cancellationToken.IsCancellationRequested)
        {
            return _last is null ? null : _last with { Stale = true };
        }
    }

    private async Task<ResetCredits?> RefreshResetCreditsAsync(AuthIdentity identity, CancellationToken cancellationToken)
    {
        if (_resetCache is not null && DateTimeOffset.UtcNow - _resetCacheAt < TimeSpan.FromSeconds(30)) return _resetCache;
        try
        {
            using var request = Request(ResetUri, identity.AccessToken);
            using var response = await _client.SendAsync(request, cancellationToken);
            response.EnsureSuccessStatusCode();
            using var body = JsonDocument.Parse(await response.Content.ReadAsStreamAsync(cancellationToken));
            _resetCache = ResetCredits(body.RootElement);
            _resetCacheAt = DateTimeOffset.UtcNow;
            return _resetCache;
        }
        catch when (!cancellationToken.IsCancellationRequested) { return _resetCache; }
    }

    private static HttpRequestMessage Request(Uri uri, string token)
    {
        var request = new HttpRequestMessage(HttpMethod.Get, uri);
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        request.Headers.TryAddWithoutValidation("OAI-Language", "en");
        request.Headers.TryAddWithoutValidation("originator", "Codex Desktop");
        request.Headers.UserAgent.ParseAdd("Quota-Bubble-Windows/1.0");
        return request;
    }

    private static UsageWindow? Window(JsonElement value)
    {
        var used = Number(value, "used_percent");
        if (used is null) return null;
        var reset = Long(value, "reset_at") ?? Long(value, "resets_at");
        return new UsageWindow(Math.Clamp((int)Math.Round(used.Value), 0, 100), reset);
    }

    private static UsageWindow? Stabilize(UsageWindow? previous, UsageWindow? next)
    {
        if (next is null) return previous;
        if (previous?.ResetsAt is null || next.ResetsAt is null || Math.Abs(previous.ResetsAt.Value - next.ResetsAt.Value) > 300) return next;
        return next with
        {
            UsedPercentage = Math.Max(previous.UsedPercentage, next.UsedPercentage),
            ResetsAt = previous.ResetsAt
        };
    }

    private static ResetCredits? ResetCredits(JsonElement value)
    {
        var count = Integer(value, "available_count");
        if (count is null) return null;
        var dates = new List<DateTimeOffset>();
        CollectExpirations(value, dates);
        dates.Sort();
        return new ResetCredits(Math.Max(0, count.Value), dates.Take(Math.Max(0, count.Value)).ToArray());
    }

    private static void CollectExpirations(JsonElement value, List<DateTimeOffset> output)
    {
        if (value.ValueKind == JsonValueKind.Array)
        {
            foreach (var child in value.EnumerateArray()) CollectExpirations(child, output);
            return;
        }
        if (value.ValueKind != JsonValueKind.Object) return;
        var expirationNames = new[] { "expires_at", "expire_at", "expiration_at", "expiresAt", "expires_on", "valid_until", "validUntil" };
        foreach (var name in expirationNames)
        {
            if (!value.TryGetProperty(name, out var raw) || !Date(raw, out var date)) continue;
            var copies = Integer(value, "count") ?? Integer(value, "quantity") ?? 1;
            for (var i = 0; i < Math.Clamp(copies, 1, 50); i++) output.Add(date);
            break;
        }
        var nestedNames = new[] { "credits", "items", "grants", "available", "reset_credits", "rate_limit_reset_credits", "reset_credit_grants" };
        foreach (var name in nestedNames)
            if (value.TryGetProperty(name, out var child)) CollectExpirations(child, output);
    }

    private static string? Plan(JsonElement root)
    {
        var values = new List<string?>
        {
            Text(root, "plan_type"), Text(root, "plan"), NestedText(root, "plan", "type"), NestedText(root, "plan", "id"),
            NestedText(root, "plan", "name"), NestedText(root, "plan", "tier"), NestedText(root, "subscription", "plan"),
            NestedText(root, "subscription", "plan_type"), NestedText(root, "subscription", "plan_id"), NestedText(root, "subscription", "tier"),
            NestedText(root, "account", "plan"), NestedText(root, "account", "plan_type"), NestedText(root, "account", "plan_id"), NestedText(root, "account", "tier")
        };
        var normalized = values.Select(NormalizePlan).Where(value => value is not null).ToArray();
        return normalized.FirstOrDefault(value => value == "pro20x") ?? normalized.FirstOrDefault(value => value == "pro5x")
            ?? normalized.FirstOrDefault(value => value == "plus") ?? normalized.FirstOrDefault(value => value == "free")
            ?? normalized.FirstOrDefault(value => value == "pro");
    }

    private static string? NormalizePlan(string? raw)
    {
        if (string.IsNullOrWhiteSpace(raw)) return null;
        var value = new string(raw.ToLowerInvariant().Where(char.IsLetterOrDigit).ToArray());
        if (value.Contains("20x") || value.Contains("pro20")) return "pro20x";
        if (value.Contains("5x") || value.Contains("pro5")) return "pro5x";
        if (value == "pro") return "pro20x";
        return value is "free" or "plus" ? value : null;
    }

    private static string? Balance(JsonElement root)
    {
        var value = Property(Property(root, "credits"), "balance");
        return value.ValueKind switch
        {
            JsonValueKind.Number => value.GetRawText(),
            JsonValueKind.String => string.IsNullOrWhiteSpace(value.GetString()) ? null : value.GetString(),
            _ => null
        };
    }

    private static JsonElement Property(JsonElement value, string name) =>
        value.ValueKind == JsonValueKind.Object && value.TryGetProperty(name, out var child) ? child : default;
    private static string? Text(JsonElement value, string name) => Property(value, name).ValueKind == JsonValueKind.String ? Property(value, name).GetString() : null;
    private static string? NestedText(JsonElement value, string parent, string child) => Text(Property(value, parent), child);
    private static double? Number(JsonElement value, string name) => Property(value, name).ValueKind == JsonValueKind.Number && Property(value, name).TryGetDouble(out var result) ? result : null;
    private static int? Integer(JsonElement value, string name) => Property(value, name).ValueKind == JsonValueKind.Number && Property(value, name).TryGetInt32(out var result) ? result : null;
    private static long? Long(JsonElement value, string name) => Property(value, name).ValueKind == JsonValueKind.Number && Property(value, name).TryGetInt64(out var result) ? result : null;
    private static bool Date(JsonElement raw, out DateTimeOffset date)
    {
        if (raw.ValueKind == JsonValueKind.String) return DateTimeOffset.TryParse(raw.GetString(), CultureInfo.InvariantCulture, DateTimeStyles.AssumeUniversal, out date);
        if (raw.ValueKind == JsonValueKind.Number && raw.TryGetInt64(out var epoch))
        {
            date = DateTimeOffset.FromUnixTimeSeconds(epoch > 1_000_000_000_000 ? epoch / 1000 : epoch);
            return true;
        }
        date = default;
        return false;
    }

    public void Dispose() => _client.Dispose();
}

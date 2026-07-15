using System.Text.Json.Serialization;

namespace QuotaBubble;

public sealed record UsageWindow(int UsedPercentage, long? ResetsAt);

public sealed record ResetCredits(int AvailableCount, IReadOnlyList<DateTimeOffset> ExpiresAt);

public sealed record AuthIdentity(string Fingerprint, string AccessToken, string? Email, DateTimeOffset? SubscriptionExpiresAt);

public sealed record QuotaSnapshot(
    string? AccountFingerprint,
    string? PlanType,
    string? BalanceUsd,
    UsageWindow? FiveHour,
    UsageWindow? SevenDay,
    ResetCredits? ResetCredits,
    DateTimeOffset UpdatedAt,
    bool Stale);

public sealed class AppSettings
{
    [JsonPropertyName("light")] public bool Light { get; set; }
    [JsonPropertyName("pinned")] public bool Pinned { get; set; } = true;
    [JsonPropertyName("language")] public string? Language { get; set; }
    [JsonPropertyName("left")] public double? Left { get; set; }
    [JsonPropertyName("top")] public double? Top { get; set; }
}

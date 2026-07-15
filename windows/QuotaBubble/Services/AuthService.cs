using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.IO;

namespace QuotaBubble.Services;

public sealed class AuthService
{
    private readonly string _authPath = Path.Combine(
        Environment.GetEnvironmentVariable("CODEX_HOME")
            ?? Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), ".codex"),
        "auth.json");

    public bool AuthFileExists => File.Exists(_authPath);

    public AuthIdentity? Read()
    {
        try
        {
            using var document = JsonDocument.Parse(File.ReadAllText(_authPath));
            var tokens = document.RootElement.GetProperty("tokens");
            var accessToken = String(tokens, "access_token");
            if (string.IsNullOrWhiteSpace(accessToken)) return null;
            var accountId = String(tokens, "account_id");
            var fingerprint = Fingerprint(accountId is null ? "token" : "account", accountId ?? accessToken);
            var (email, expiration) = ReadClaims(String(tokens, "id_token"));
            return new AuthIdentity(fingerprint, accessToken, email, expiration);
        }
        catch { return null; }
    }

    private static (string? Email, DateTimeOffset? Expiration) ReadClaims(string? idToken)
    {
        try
        {
            var parts = idToken?.Split('.');
            if (parts is null || parts.Length < 2) return (null, null);
            var value = parts[1].Replace('-', '+').Replace('_', '/');
            value += new string('=', (4 - value.Length % 4) % 4);
            using var claims = JsonDocument.Parse(Convert.FromBase64String(value));
            var email = String(claims.RootElement, "email");
            DateTimeOffset? expiration = null;
            if (claims.RootElement.TryGetProperty("https://api.openai.com/auth", out var auth) &&
                auth.TryGetProperty("chatgpt_subscription_active_until", out var raw))
            {
                expiration = ParseDate(raw);
            }
            return (email, expiration);
        }
        catch { return (null, null); }
    }

    private static DateTimeOffset? ParseDate(JsonElement value)
    {
        if (value.ValueKind == JsonValueKind.String && DateTimeOffset.TryParse(value.GetString(), out var date)) return date;
        if (value.ValueKind == JsonValueKind.Number && value.TryGetInt64(out var epoch))
            return DateTimeOffset.FromUnixTimeSeconds(epoch > 1_000_000_000_000 ? epoch / 1000 : epoch);
        return null;
    }

    private static string? String(JsonElement parent, string property) =>
        parent.TryGetProperty(property, out var value) && value.ValueKind == JsonValueKind.String
            ? value.GetString() : null;

    private static string Fingerprint(string kind, string value)
    {
        var hash = SHA256.HashData(Encoding.UTF8.GetBytes(value));
        return $"{kind}:{Convert.ToHexString(hash).ToLowerInvariant()[..16]}";
    }
}

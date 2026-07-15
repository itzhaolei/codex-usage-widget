using QuotaBubble.Services;
using System.Collections.ObjectModel;
using System.Diagnostics;
using System.Globalization;
using System.Runtime.InteropServices;
using System.Windows;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Threading;
using Drawing = System.Drawing;
using Forms = System.Windows.Forms;

namespace QuotaBubble;

public sealed record ResetRow(string Text, Brush Brush, Brush Foreground);

public partial class MainWindow : Window
{
    private readonly SettingsService _settingsService = new();
    private readonly QuotaService _quotaService = new();
    private readonly UpdateService _updateService = new();
    private readonly DispatcherTimer _timer = new() { Interval = TimeSpan.FromSeconds(1) };
    private readonly ObservableCollection<ResetRow> _resetRows = [];
    private readonly AppSettings _settings;
    private Forms.NotifyIcon? _tray;
    private bool _refreshing;
    private bool _closing;
    private DateTimeOffset _lastVersionCheck = DateTimeOffset.MinValue;

    public MainWindow()
    {
        InitializeComponent();
        _settings = _settingsService.Load();
        ResetItems.ItemsSource = _resetRows;
        Topmost = _settings.Pinned;
        RestorePosition();
        ConfigureWindow();
        ConfigureTray();
        ApplyLocalization();
        ApplyTheme();
        _timer.Tick += async (_, _) => await RefreshAsync();
        Loaded += async (_, _) =>
        {
            _timer.Start();
            await RefreshAsync();
            await CheckVersionAsync(false);
        };
    }

    private void ConfigureWindow()
    {
        MouseLeftButtonDown += (_, e) =>
        {
            if (e.ButtonState != MouseButtonState.Pressed || e.OriginalSource is System.Windows.Controls.Button) return;
            try { DragMove(); } catch { }
            SaveSettings();
        };
        LocationChanged += (_, _) => SaveSettings();
        ThemeButton.Click += (_, _) => { _settings.Light = !_settings.Light; ApplyTheme(); SaveSettings(); };
        PinButton.Click += (_, _) => { _settings.Pinned = !_settings.Pinned; Topmost = _settings.Pinned; ApplyTheme(); SaveSettings(); };
        CloseButton.Click += (_, _) => Close();
        Closing += (_, _) => Cleanup();
    }

    private void ConfigureTray()
    {
        _tray = new Forms.NotifyIcon
        {
            Text = "Quota Bubble",
            Icon = LoadTrayIcon(),
            Visible = true
        };
        _tray.DoubleClick += (_, _) => ShowAndActivate();
        RebuildTrayMenu();
    }

    private void RebuildTrayMenu()
    {
        if (_tray is null) return;
        var copy = Localization.Get(_settings.Language);
        var menu = new Forms.ContextMenuStrip();
        var show = menu.Items.Add(copy.Show);
        show.Click += (_, _) => ShowAndActivate();

        var language = new Forms.ToolStripMenuItem(copy.Language);
        menu.Items.Add(language);
        foreach (var entry in Localization.LanguageNames)
        {
            var code = entry.Key;
            var label = code.Length == 0 ? copy.Follow : entry.Value;
            var item = new Forms.ToolStripMenuItem(label)
            {
                Checked = code.Length == 0 ? string.IsNullOrWhiteSpace(_settings.Language) : _settings.Language == code
            };
            item.Click += (_, _) => SelectLanguage(code);
            language.DropDownItems.Add(item);
        }

        var update = menu.Items.Add(copy.Update);
        update.Click += async (_, _) => await CheckVersionAsync(true);
        menu.Items.Add(new Forms.ToolStripSeparator());
        var exit = menu.Items.Add(copy.Exit);
        exit.ForeColor = Drawing.Color.Firebrick;
        exit.Click += (_, _) => Close();
        var previous = _tray.ContextMenuStrip;
        _tray.ContextMenuStrip = menu;
        previous?.Dispose();
    }

    private async Task RefreshAsync()
    {
        if (_refreshing || _closing) return;
        _refreshing = true;
        try
        {
            var snapshot = await _quotaService.RefreshAsync(CancellationToken.None);
            Render(snapshot, _quotaService.CurrentIdentity);
            if (DateTimeOffset.UtcNow - _lastVersionCheck >= TimeSpan.FromMinutes(30))
                await CheckVersionAsync(false);
        }
        finally { _refreshing = false; }
    }

    private void Render(QuotaSnapshot? snapshot, AuthIdentity? identity)
    {
        _lastRenderedCredits = snapshot?.ResetCredits;
        var window = snapshot?.FiveHour;
        var remaining = window is null ? (int?)null : Math.Clamp(100 - window.UsedPercentage, 0, 100);
        ResetText.Text = $"{Localization.Get(_settings.Language).Reset} {FormatDuration(window?.ResetsAt)}";
        PercentText.Text = remaining is null ? "—" : $"{remaining}%";
        SetProgress(remaining);
        SetPlan(snapshot?.PlanType);

        BalanceValue.Text = FormatBalance(snapshot?.BalanceUsd);
        ResetValue.Text = snapshot?.ResetCredits?.AvailableCount.ToString(CultureInfo.InvariantCulture) ?? "—";
        AccountText.Text = identity?.Email ?? "—";
        SubscriptionText.Text = FormatDate(identity?.SubscriptionExpiresAt);
        RenderResets(snapshot?.ResetCredits);
    }

    private void SetProgress(int? remaining)
    {
        ProgressFill.Width = remaining is null ? 0 : 231 * remaining.Value / 100d;
        var color = new SolidColorBrush(remaining is <= 20 ? Color.FromRgb(255, 51, 51) : Color.FromRgb(0, 240, 32));
        color.Freeze();
        ProgressFill.Fill = color;
        if (ProgressPattern.Fill is VisualBrush brush && brush.Visual is System.Windows.Shapes.Ellipse dot) dot.Fill = color;
    }

    private void SetPlan(string? raw)
    {
        var normalized = NormalizePlan(raw);
        PlanText.Text = normalized switch
        {
            "free" => "Free", "plus" => "Plus", "pro" => "Pro", "pro5x" => "Pro5x", "pro20x" => "Pro20x", _ => ""
        };
        PlanBadge.Visibility = PlanText.Text.Length == 0 ? Visibility.Collapsed : Visibility.Visible;
        PlanBadge.Background = new SolidColorBrush(normalized switch
        {
            "plus" => Color.FromRgb(0, 184, 23),
            "pro" or "pro5x" or "pro20x" => Color.FromRgb(242, 140, 40),
            _ => Color.FromRgb(115, 122, 128)
        });
    }

    private void RenderResets(ResetCredits? credits)
    {
        _resetRows.Clear();
        if (credits is null || credits.AvailableCount <= 0) return;
        var foreground = SecondaryBrush();
        for (var index = 0; index < credits.AvailableCount; index++)
        {
            if (index < credits.ExpiresAt.Count)
            {
                var expiration = credits.ExpiresAt[index];
                var soon = expiration - DateTimeOffset.Now <= TimeSpan.FromDays(3);
                _resetRows.Add(new ResetRow(FormatDate(expiration), soon ? Brushes.Red : Brushes.Lime, foreground));
            }
            else _resetRows.Add(new ResetRow("—", Brushes.Gray, foreground));
        }
    }

    private void ApplyLocalization()
    {
        var copy = Localization.Get(_settings.Language);
        TitleText.Text = copy.Title;
        WeekText.Text = copy.Week;
        BalanceTitle.Text = $"{copy.Balance} ($)";
        ResetTitle.Text = $"{copy.Available} ({copy.Times})";
        VersionText.Text = $"v{App.Version}";
        RebuildTrayMenu();
    }

    private void ApplyTheme()
    {
        var primary = new SolidColorBrush(_settings.Light ? Color.FromRgb(17, 24, 39) : Colors.White);
        var secondary = SecondaryBrush();
        Root.Background = new SolidColorBrush(_settings.Light ? Color.FromArgb(235, 243, 247, 248) : Color.FromArgb(235, 17, 29, 24));
        foreach (var text in new[] { TitleText, WeekText, PercentText, BalanceValue, ResetValue }) text.Foreground = primary;
        foreach (var text in new[] { ResetText, AccountText, SubscriptionText, VersionText, BalanceTitle, ResetTitle }) text.Foreground = secondary;
        var card = new SolidColorBrush(_settings.Light ? Color.FromArgb(150, 255, 255, 255) : Color.FromArgb(74, 115, 123, 126));
        BalanceCard.Background = card;
        ResetCard.Background = card;
        ThemeButton.Content = _settings.Light ? "☾" : "☀";
        PinButton.Foreground = _settings.Pinned ? Brushes.LimeGreen : secondary;
        RenderResets(_quotaService.CurrentIdentity is null ? null : _lastRenderedCredits);
    }

    private ResetCredits? _lastRenderedCredits;

    private Brush SecondaryBrush() => new SolidColorBrush(_settings.Light ? Color.FromRgb(89, 99, 107) : Color.FromRgb(174, 185, 191));

    private void SelectLanguage(string code)
    {
        _settings.Language = string.IsNullOrWhiteSpace(code) ? null : code;
        ApplyLocalization();
        SaveSettings();
        _ = RefreshAsync();
    }

    private async Task CheckVersionAsync(bool interactive)
    {
        try
        {
            _lastVersionCheck = DateTimeOffset.UtcNow;
            var release = await _updateService.LatestAsync();
            if (release is null || !Version.TryParse(App.Version, out var current)) return;
            var hasUpdate = release.Version > current;
            UpdateDot.Visibility = hasUpdate ? Visibility.Visible : Visibility.Collapsed;
            if (!interactive) return;
            var copy = Localization.Get(_settings.Language);
            if (!hasUpdate)
            {
                MessageBox.Show(this, copy.Latest, "Quota Bubble", MessageBoxButton.OK, MessageBoxImage.Information);
                return;
            }
            if (string.IsNullOrWhiteSpace(release.InstallerUrl)) throw new InvalidOperationException("Windows installer asset not found.");
            MessageBox.Show(this, copy.Updating, "Quota Bubble", MessageBoxButton.OK, MessageBoxImage.Information);
            await _updateService.DownloadAndInstallAsync(release);
            _closing = true;
            System.Windows.Application.Current.Shutdown();
        }
        catch (Exception error)
        {
            if (interactive) MessageBox.Show(this, $"{Localization.Get(_settings.Language).UpdateFailed}: {error.Message}", "Quota Bubble", MessageBoxButton.OK, MessageBoxImage.Error);
        }
    }

    private static string NormalizePlan(string? raw)
    {
        if (string.IsNullOrWhiteSpace(raw)) return "";
        var value = new string(raw.ToLowerInvariant().Where(char.IsLetterOrDigit).ToArray());
        if (value.Contains("20x") || value.Contains("pro20")) return "pro20x";
        if (value.Contains("5x") || value.Contains("pro5")) return "pro5x";
        return value is "free" or "plus" or "pro" ? value : "";
    }

    private static string FormatBalance(string? raw) =>
        double.TryParse(raw?.TrimStart('$'), NumberStyles.Any, CultureInfo.InvariantCulture, out var value)
            ? value.ToString("0.00", CultureInfo.InvariantCulture) : string.IsNullOrWhiteSpace(raw) ? "—" : raw;

    private static string FormatDuration(long? epoch)
    {
        if (epoch is null) return "—";
        var seconds = Math.Max(1, epoch.Value - DateTimeOffset.UtcNow.ToUnixTimeSeconds());
        var parts = new List<string>();
        var days = seconds / 86400; seconds %= 86400;
        var hours = seconds / 3600; seconds %= 3600;
        var minutes = seconds / 60; seconds %= 60;
        if (days > 0) parts.Add($"{days}d");
        if (hours > 0) parts.Add($"{hours}h");
        if (minutes > 0) parts.Add($"{minutes}m");
        if (seconds > 0 || parts.Count == 0) parts.Add($"{seconds}s");
        return string.Join(' ', parts);
    }

    private static string FormatDate(DateTimeOffset? date) => date?.ToLocalTime().ToString("g", CultureInfo.CurrentCulture) ?? "—";

    private void ShowAndActivate()
    {
        Show();
        WindowState = WindowState.Normal;
        Activate();
    }

    private void RestorePosition()
    {
        if (_settings.Left is not double left || _settings.Top is not double top) return;
        if (left < SystemParameters.VirtualScreenLeft - Width || left > SystemParameters.VirtualScreenLeft + SystemParameters.VirtualScreenWidth ||
            top < SystemParameters.VirtualScreenTop - 60 || top > SystemParameters.VirtualScreenTop + SystemParameters.VirtualScreenHeight) return;
        WindowStartupLocation = WindowStartupLocation.Manual;
        Left = left;
        Top = top;
    }

    private void SaveSettings()
    {
        if (!double.IsNaN(Left) && !double.IsNaN(Top)) { _settings.Left = Left; _settings.Top = Top; }
        _settingsService.Save(_settings);
    }

    private void Cleanup()
    {
        if (_closing) return;
        _closing = true;
        SaveSettings();
        _timer.Stop();
        if (_tray is not null) { _tray.Visible = false; _tray.Dispose(); }
        _quotaService.Dispose();
        _updateService.Dispose();
        System.Windows.Application.Current.Shutdown();
    }

    private static Drawing.Icon LoadTrayIcon()
    {
        try
        {
            var uri = new Uri("pack://application:,,,/Assets/icon.png");
            var resource = System.Windows.Application.GetResourceStream(uri);
            using var bitmap = new Drawing.Bitmap(resource.Stream);
            var handle = bitmap.GetHicon();
            try { return (Drawing.Icon)Drawing.Icon.FromHandle(handle).Clone(); }
            finally { DestroyIcon(handle); }
        }
        catch { return Drawing.SystemIcons.Application; }
    }

    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    private static extern bool DestroyIcon(IntPtr handle);
}

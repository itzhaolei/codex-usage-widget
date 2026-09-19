using QuotaBubble.Services;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Diagnostics;
using System.Globalization;
using System.Net.Http;
using System.Runtime.InteropServices;
using System.Windows;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Threading;
using Drawing = System.Drawing;
using Forms = System.Windows.Forms;
using Brushes = System.Windows.Media.Brushes;
using Color = System.Windows.Media.Color;
using MessageBox = System.Windows.MessageBox;

namespace QuotaBubble;

public sealed record ResetRow(string Text, System.Windows.Media.Brush Brush, System.Windows.Media.Brush Foreground);

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
    private bool _checkingUpdate;
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
        CloseButton.Click += (_, _) => HideWindow();
        Closing += HandleClosing;
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
        exit.Click += (_, _) => ExitApplication();
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
            RenderSystemCapacity();
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
        var fiveHour = snapshot?.SevenDay is null ? null : snapshot?.FiveHour;
        var weekly = snapshot?.SevenDay ?? snapshot?.FiveHour;
        FiveHourQuotaPanel.Visibility = fiveHour is null ? Visibility.Collapsed : Visibility.Visible;
        RenderQuota(fiveHour, FiveHourResetText, FiveHourResetDateText, null, FiveHourPercentText, FiveHourProgressFill, FiveHourProgressPattern);
        RenderQuota(weekly, ResetText, ResetDateText, ResetWeekdayText, PercentText, ProgressFill, ProgressPattern);
        UpdateTrayStatus(Remaining(fiveHour ?? weekly));
        SetPlan(snapshot?.PlanType);

        BalanceValue.Text = FormatBalance(snapshot?.BalanceUsd);
        ResetValue.Text = snapshot?.ResetCredits?.AvailableCount.ToString(CultureInfo.InvariantCulture) ?? "—";
        AccountText.Text = identity?.Email ?? "—";
        SubscriptionText.Text = FormatDate(identity?.SubscriptionExpiresAt);
        RenderResets(snapshot?.ResetCredits);
    }

    private void RenderQuota(
        UsageWindow? window,
        System.Windows.Controls.TextBlock resetText,
        System.Windows.Controls.TextBlock resetDateText,
        System.Windows.Controls.TextBlock? resetWeekdayText,
        System.Windows.Controls.TextBlock percentText,
        System.Windows.Shapes.Rectangle progressFill,
        System.Windows.Shapes.Rectangle progressPattern)
    {
        var remaining = Remaining(window);
        resetText.Text = $"{Localization.Get(_settings.Language).Reset} {FormatDuration(window?.ResetsAt)}";
        resetDateText.Text = FormatResetDate(window?.ResetsAt);
        if (resetWeekdayText is not null) resetWeekdayText.Text = FormatResetWeekday(window?.ResetsAt);
        percentText.Text = remaining is null ? "—" : $"{remaining}%";
        SetProgress(remaining, progressFill, progressPattern);
    }

    private void SetProgress(int? remaining, System.Windows.Shapes.Rectangle progressFill, System.Windows.Shapes.Rectangle progressPattern)
    {
        progressFill.Width = remaining is null ? 0 : 231 * remaining.Value / 100d;
        var color = new SolidColorBrush(remaining is <= 20 ? Color.FromRgb(240, 51, 56) : Color.FromRgb(0, 194, 41));
        color.Freeze();
        progressFill.Fill = color;
        if (progressPattern.Fill is VisualBrush brush && brush.Visual is System.Windows.Shapes.Ellipse dot) dot.Fill = color;
    }

    private void UpdateTrayStatus(int? remaining)
    {
        if (_tray is null) return;
        _tray.Text = remaining is null ? "Quota Bubble" : $"Quota Bubble {remaining}%";
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
        if (credits is not null && credits.AvailableCount > 0)
        {
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
        ResetItems.Visibility = _resetRows.Count == 0 ? Visibility.Collapsed : Visibility.Visible;
        MetricCards.Margin = new Thickness(0, _resetRows.Count == 0 ? 15 : 10, 0, 0);
    }

    private void ApplyLocalization()
    {
        var copy = Localization.Get(_settings.Language);
        TitleText.Text = copy.Title;
        WeekText.Text = copy.Week;
        BalanceTitle.Text = $"{copy.Balance}（{PointsUnit()}）";
        ResetTitle.Text = $"{copy.Available}（{copy.Times}）";
        UpdateMetricCardLayout();
        VersionText.Text = $"v{App.Version}";
        RebuildTrayMenu();
    }

    private void ApplyTheme()
    {
        var primary = new SolidColorBrush(_settings.Light ? Color.FromRgb(17, 24, 39) : Colors.White);
        var secondary = SecondaryBrush();
        Root.Background = new SolidColorBrush(_settings.Light ? Color.FromArgb(235, 243, 247, 248) : Color.FromArgb(235, 17, 29, 24));
        foreach (var text in new[] { TitleText, WeekText, FiveHourPercentText, PercentText, BalanceValue, ResetValue }) text.Foreground = primary;
        foreach (var text in new[] { FiveHourResetText, ResetText, AccountText, SubscriptionText, VersionText, BalanceTitle, ResetTitle }) text.Foreground = secondary;
        foreach (var text in new[] { FiveHourResetDateText, ResetDateText, ResetWeekdayText }) text.Foreground = new SolidColorBrush(_settings.Light ? Color.FromArgb(132, 17, 24, 39) : Color.FromArgb(132, 255, 255, 255));
        var card = new SolidColorBrush(_settings.Light ? Color.FromArgb(31, 255, 255, 255) : Color.FromArgb(18, 255, 255, 255));
        BalanceCard.Background = card;
        ResetCard.Background = card;
        SunIcon.Visibility = _settings.Light ? Visibility.Collapsed : Visibility.Visible;
        MoonIcon.Visibility = _settings.Light ? Visibility.Visible : Visibility.Collapsed;
        PinButton.Foreground = _settings.Pinned ? Brushes.LimeGreen : secondary;
        ThemeButton.Foreground = secondary;
        CloseButton.Foreground = secondary;
        AccountIcon.Stroke = secondary;
        SubscriptionIcon.Stroke = secondary;
        RenderResets(_quotaService.CurrentIdentity is null ? null : _lastRenderedCredits);
        RenderSystemCapacity();
    }

    private ResetCredits? _lastRenderedCredits;

    private System.Windows.Media.Brush SecondaryBrush() => new SolidColorBrush(_settings.Light ? Color.FromRgb(89, 99, 107) : Color.FromRgb(174, 185, 191));

    private void SelectLanguage(string code)
    {
        _settings.Language = string.IsNullOrWhiteSpace(code) ? null : code;
        ApplyLocalization();
        SaveSettings();
        _ = RefreshAsync();
    }

    private async Task CheckVersionAsync(bool interactive)
    {
        if (_checkingUpdate) return;
        _checkingUpdate = true;
        UpdateProgressWindow? progressWindow = null;
        try
        {
            _lastVersionCheck = DateTimeOffset.UtcNow;
            var release = await _updateService.LatestAsync();
            var copy = Localization.Get(_settings.Language);
            if (release is null || !Version.TryParse(App.Version, out var current))
            {
                if (interactive) MessageBox.Show(this, copy.Latest, "Quota Bubble", MessageBoxButton.OK, MessageBoxImage.Information);
                return;
            }
            var hasUpdate = release.Version > current;
            UpdateDot.Visibility = hasUpdate ? Visibility.Visible : Visibility.Collapsed;
            if (!interactive) return;
            if (!hasUpdate)
            {
                MessageBox.Show(this, copy.Latest, "Quota Bubble", MessageBoxButton.OK, MessageBoxImage.Information);
                return;
            }
            progressWindow = new UpdateProgressWindow(copy.Updating) { Owner = this };
            progressWindow.Show();
            progressWindow.Activate();
            var progress = new Progress<DownloadProgress>(progressWindow.Report);
            await _updateService.DownloadAndInstallAsync(release, progress);
            progressWindow.CloseAfterDownload();
            progressWindow = null;
            ExitApplication();
        }
        catch (Exception error)
        {
            if (!interactive) return;
            var copy = Localization.Get(_settings.Language);
            if (error is HttpRequestException)
            {
                try { UpdateService.OpenReleasesPage(); } catch { }
                var message = Localization.ResolveLanguage(_settings.Language) == "zh"
                    ? "无法连接更新服务器。已在浏览器中打开官方下载页，请检查网络、代理或系统证书后重试。"
                    : "Could not connect to the update server. The download page was opened in your browser. Check your network, proxy, or system certificates and try again.";
                MessageBox.Show(this, message, "Quota Bubble", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }
            MessageBox.Show(this, $"{copy.UpdateFailed}: {InnermostMessage(error)}", "Quota Bubble", MessageBoxButton.OK, MessageBoxImage.Error);
        }
        finally
        {
            progressWindow?.CloseAfterDownload();
            _checkingUpdate = false;
        }
    }

    private static string InnermostMessage(Exception error)
    {
        while (error.InnerException is not null) error = error.InnerException;
        return error.Message;
    }

    private static string NormalizePlan(string? raw)
    {
        if (string.IsNullOrWhiteSpace(raw)) return "";
        var value = new string(raw.ToLowerInvariant().Where(char.IsLetterOrDigit).ToArray());
        if (value.Contains("20x") || value.Contains("pro20")) return "pro20x";
        if (value.Contains("5x") || value.Contains("pro5")) return "pro5x";
        if (value == "pro") return "pro20x";
        return value is "free" or "plus" ? value : "";
    }

    private static string FormatBalance(string? raw) =>
        double.TryParse(raw?.TrimStart('$'), NumberStyles.Any, CultureInfo.InvariantCulture, out var value)
            ? Math.Round(value).ToString("0", CultureInfo.InvariantCulture) : string.IsNullOrWhiteSpace(raw) ? "—" : raw;

    private void RenderSystemCapacity()
    {
        var storage = SystemCapacityService.SystemDrive();
        var memory = SystemCapacityService.PhysicalMemory();
        var language = Localization.ResolveLanguage(_settings.Language);
        StorageText.Text = CapacityLabel(language, true, storage is null ? "—" : $"{storage.Available / 1_000_000_000d:0.0}G");
        MemoryText.Text = CapacityLabel(language, false, memory is null ? "—" : $"{memory.Available / 1_073_741_824d:0.0}G / {memory.Total / 1_073_741_824d:0.0}G");

        var storageWarning = storage is not null && storage.Available < 50_000_000_000UL;
        var memoryWarning = memory is not null && memory.Available > 11UL * 1_073_741_824UL;
        ApplyCapacityColor(StorageText, StorageIcon, storage is null ? null : storageWarning);
        ApplyCapacityColor(MemoryText, MemoryIcon, memory is null ? null : memoryWarning);
    }

    private void ApplyCapacityColor(System.Windows.Controls.TextBlock text, System.Windows.Shapes.Path icon, bool? warning)
    {
        var brush = warning is null ? SecondaryBrush() : warning.Value
            ? new SolidColorBrush(Color.FromRgb(240, 51, 56))
            : new SolidColorBrush(Color.FromRgb(0, 194, 41));
        text.Foreground = brush;
        icon.Stroke = brush;
    }

    private string PointsUnit() => Localization.ResolveLanguage(_settings.Language) switch
    {
        "zh" => "点数", "ja" => "ポイント", "ko" => "포인트", "de" => "Punkte", "fr" => "points",
        "es" => "puntos", "pt" => "pontos", "it" => "punti", "nl" => "punten", _ => "points"
    };

    private static string CapacityLabel(string language, bool storage, string value)
    {
        var label = (language, storage) switch
        {
            ("zh", true) => "C盘可用空间", ("zh", false) => "可用运行内存",
            ("ja", true) => "Cドライブ空き容量", ("ja", false) => "利用可能メモリ",
            ("ko", true) => "C 드라이브 여유 공간", ("ko", false) => "사용 가능 메모리",
            ("de", true) => "Freier Speicher auf C", ("de", false) => "Verfügbarer Arbeitsspeicher",
            ("fr", true) => "Espace libre sur C", ("fr", false) => "Mémoire disponible",
            ("es", true) => "Espacio libre en C", ("es", false) => "Memoria disponible",
            ("pt", true) => "Espaço livre em C", ("pt", false) => "Memória disponível",
            ("it", true) => "Spazio libero su C", ("it", false) => "Memoria disponibile",
            ("nl", true) => "Vrije ruimte op C", ("nl", false) => "Beschikbaar geheugen",
            (_, true) => "C drive available", _ => "Available memory"
        };
        return language == "zh" ? $"{label}：{value}" : $"{label}: {value}";
    }

    private void UpdateMetricCardLayout()
    {
        var pixelsPerDip = VisualTreeHelper.GetDpi(this).PixelsPerDip;
        var typeface = new Typeface(BalanceTitle.FontFamily, FontStyles.Normal, FontWeights.Medium, FontStretches.Normal);
        var doubleLine = new[] { BalanceTitle.Text, ResetTitle.Text }.Any(value =>
            new FormattedText(value, CultureInfo.CurrentUICulture, System.Windows.FlowDirection.LeftToRight, typeface, 9, Brushes.Black, pixelsPerDip).Width > 123);
        var height = doubleLine ? 59d : 47d;
        MetricCards.Height = height;
        BalanceCard.Height = height;
        ResetCard.Height = height;
        BalanceTitle.Height = doubleLine ? 22 : 11;
        ResetTitle.Height = doubleLine ? 22 : 11;
    }

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

    private static int? Remaining(UsageWindow? window) => window is null ? null : Math.Clamp(100 - window.UsedPercentage, 0, 100);

    private static string FormatResetDate(long? epoch)
    {
        if (epoch is null) return "—";
        return DateTimeOffset.FromUnixTimeSeconds(epoch.Value > 1_000_000_000_000 ? epoch.Value / 1000 : epoch.Value)
            .ToLocalTime()
            .ToString("MM-dd HH:mm:ss", CultureInfo.InvariantCulture);
    }

    private string FormatResetWeekday(long? epoch)
    {
        if (epoch is null) return "—";
        var date = DateTimeOffset.FromUnixTimeSeconds(epoch.Value > 1_000_000_000_000 ? epoch.Value / 1000 : epoch.Value).ToLocalTime();
        if (Localization.ResolveLanguage(_settings.Language) == "zh")
        {
            var values = new[] { "周日", "周一", "周二", "周三", "周四", "周五", "周六" };
            return values[(int)date.DayOfWeek];
        }
        return date.ToString("ddd", CultureInfo.CurrentUICulture);
    }

    private static string FormatDate(DateTimeOffset? date) => date?.ToLocalTime().ToString("g", CultureInfo.CurrentCulture) ?? "—";

    private void ShowAndActivate()
    {
        Show();
        WindowState = WindowState.Normal;
        Activate();
    }

    private void HideWindow()
    {
        SaveSettings();
        Hide();
    }

    private void HandleClosing(object? sender, CancelEventArgs e)
    {
        if (_closing) return;
        e.Cancel = true;
        HideWindow();
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

    private void ExitApplication()
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

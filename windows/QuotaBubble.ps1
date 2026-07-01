param(
    [switch]$NoSingleInstance
)

$ErrorActionPreference = "SilentlyContinue"

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$mutex = $null
if (-not $NoSingleInstance) {
    $createdNew = $false
    $mutex = New-Object System.Threading.Mutex($true, "Local\QuotaBubble.Windows", [ref]$createdNew)
    if (-not $createdNew) {
        [System.Windows.MessageBox]::Show("Quota Bubble is already running.", "Quota Bubble") | Out-Null
        exit 0
    }
}

$script:Version = "2.1.3"
$script:CodexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $env:USERPROFILE ".codex" }
$script:InstallDir = Join-Path $script:CodexHome "usage-widget"
$script:StatePath = Join-Path $script:InstallDir "windows-state.json"
$script:SnapshotScript = Join-Path $script:CodexHome "scripts\codex-usage-snapshot.mjs"
$script:SnapshotPath = Join-Path $script:CodexHome "codex-usage-snapshot.json"
$script:SnapshotRunning = $false
$script:IsLight = $false
$script:IsPinned = $true
$script:Dragging = $false

function Test-Zh {
    try { return [System.Globalization.CultureInfo]::CurrentUICulture.TwoLetterISOLanguageName -eq "zh" } catch { return $false }
}

function T($zh, $en) {
    if (Test-Zh) { return $zh }
    return $en
}

function Ensure-Directory($path) {
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }
}

function Load-State {
    if (-not (Test-Path $script:StatePath)) { return }
    try {
        $state = Get-Content $script:StatePath -Raw | ConvertFrom-Json
        if ($null -ne $state.light) { $script:IsLight = [bool]$state.light }
        if ($null -ne $state.pinned) { $script:IsPinned = [bool]$state.pinned }
    } catch {}
}

function Save-State {
    Ensure-Directory $script:InstallDir
    $state = [ordered]@{
        light = $script:IsLight
        pinned = $script:IsPinned
        left = $window.Left
        top = $window.Top
    }
    $state | ConvertTo-Json | Set-Content -Path $script:StatePath -Encoding UTF8
}

function Find-CodexCli {
    $command = Get-Command codex -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }
    $candidates = @(
        (Join-Path $env:USERPROFILE ".local\bin\codex.exe"),
        (Join-Path $env:LOCALAPPDATA "Programs\codex\codex.exe"),
        (Join-Path $env:APPDATA "npm\codex.cmd")
    )
    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) { return $candidate }
    }
    return $null
}

function Has-CodexSessionData {
    foreach ($dir in @((Join-Path $script:CodexHome "sessions"), (Join-Path $script:CodexHome "archived_sessions"))) {
        if ((Test-Path $dir) -and (Get-ChildItem -Path $dir -Filter *.jsonl -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1)) {
            return $true
        }
    }
    return $false
}

function Get-SetupIssue {
    if (-not (Find-CodexCli)) { return "missingCli" }
    if (-not (Test-Path (Join-Path $script:CodexHome "auth.json")) -and -not (Has-CodexSessionData)) { return "missingLogin" }
    return "ready"
}

function Run-Snapshot {
    if ($script:SnapshotRunning) { return }
    if (-not (Test-Path $script:SnapshotScript)) { return }
    $node = Get-Command node -ErrorAction SilentlyContinue
    if (-not $node) { return }
    $script:SnapshotRunning = $true
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo.FileName = $node.Source
    $process.StartInfo.Arguments = "`"$script:SnapshotScript`" `"$script:SnapshotPath`""
    $process.StartInfo.UseShellExecute = $false
    $process.StartInfo.CreateNoWindow = $true
    $process.EnableRaisingEvents = $true
    Register-ObjectEvent -InputObject $process -EventName Exited -Action {
        $script:SnapshotRunning = $false
        $Event.Sender.Dispose()
    } | Out-Null
    [void]$process.Start()
}

function Read-Snapshot {
    try {
        if (Test-Path $script:SnapshotPath) {
            return Get-Content $script:SnapshotPath -Raw | ConvertFrom-Json
        }
    } catch {}
    return $null
}

function Format-ResetText($epoch) {
    if ($null -eq $epoch) { return (T "重置 -" "reset -") }
    $seconds = [Math]::Max(1, [int]($epoch - [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()))
    $span = [TimeSpan]::FromSeconds($seconds)
    if (Test-Zh) {
        if ($span.TotalDays -ge 1) { return "重置 $([int]$span.TotalDays) 天 $($span.Hours) 小时后" }
        if ($span.TotalHours -ge 1) { return "重置 $([int]$span.TotalHours) 小时 $($span.Minutes) 分钟后" }
        if ($span.TotalMinutes -ge 1) { return "重置 $($span.Minutes) 分钟 $($span.Seconds) 秒后" }
        return "重置 $seconds 秒后"
    }
    if ($span.TotalDays -ge 1) { return "reset in $([int]$span.TotalDays)d $($span.Hours)h" }
    if ($span.TotalHours -ge 1) { return "reset in $([int]$span.TotalHours)h $($span.Minutes)m" }
    if ($span.TotalMinutes -ge 1) { return "reset in $($span.Minutes)m $($span.Seconds)s" }
    return "reset in ${seconds}s"
}

function Remaining($window) {
    if ($null -eq $window -or $null -eq $window.used_percentage) { return $null }
    return [Math]::Max(0, [Math]::Min(100, 100 - [int]$window.used_percentage))
}

function Set-Bar($fill, $percentText, $remaining) {
    if ($null -eq $remaining) {
        $fill.Width = 0
        $percentText.Text = "-"
        return
    }
    $fill.Width = [Math]::Round(186 * $remaining / 100)
    $fill.Fill = if ($remaining -le 20) { "#ff3333" } else { "#00ff22" }
    $percentText.Text = "$remaining%"
}

function Apply-Theme {
    if ($script:IsLight) {
        $root.Background = "#EFF6FA"
        $title.Foreground = "#111827"
        $fiveLabel.Foreground = "#111827"
        $weekLabel.Foreground = "#111827"
        $versionLabel.Foreground = "#667085"
        $balanceValue.Foreground = "#111827"
        $resetValue.Foreground = "#111827"
    } else {
        $root.Background = "#162C3A"
        $title.Foreground = "White"
        $fiveLabel.Foreground = "White"
        $weekLabel.Foreground = "White"
        $versionLabel.Foreground = "#BBC4CE"
        $balanceValue.Foreground = "White"
        $resetValue.Foreground = "White"
    }
}

function Update-SetupOverlay {
    $issue = Get-SetupIssue
    if ($issue -eq "ready") {
        $overlay.Visibility = "Collapsed"
        return
    }
    $overlay.Visibility = "Visible"
    if ($issue -eq "missingCli") {
        $setupTitle.Text = T "需要安装 Codex CLI" "Codex CLI required"
        $setupMessage.Text = T "Quota Bubble 需要本地 Codex CLI 数据。点击安装后会打开 PowerShell 安装 CLI。" "Quota Bubble needs local Codex CLI data. Click install to open PowerShell and install the CLI."
        $setupButton.Content = T "安装" "Install"
    } else {
        $setupTitle.Text = T "需要登录 Codex CLI" "Codex CLI login required"
        $setupMessage.Text = T "已检测到 CLI，但还没有本地登录数据。请完成 codex login 后等待自动同步。" "CLI is installed, but local login data is missing. Run codex login, then wait for sync."
        $setupButton.Content = T "打开登录" "Log in"
    }
}

function Update-Ui {
    Run-Snapshot
    Update-SetupOverlay
    $snapshot = Read-Snapshot
    $five = Remaining $snapshot.five_hour
    $week = Remaining $snapshot.seven_day
    $fiveReset.Text = Format-ResetText $snapshot.five_hour.resets_at
    $weekReset.Text = Format-ResetText $snapshot.seven_day.resets_at
    Set-Bar $fiveFill $fivePercent $five
    Set-Bar $weekFill $weekPercent $week
    $balanceValue.Text = if ($snapshot.balance_usd) { [string]$snapshot.balance_usd } else { "0.00" }
    $resetValue.Text = if ($null -ne $snapshot.reset_credits.available_count) { [string]$snapshot.reset_credits.available_count } else { "0" }
}

$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Width="330" Height="240" WindowStyle="None" ResizeMode="NoResize" AllowsTransparency="True"
        Background="Transparent" Topmost="True" ShowInTaskbar="True">
  <Border x:Name="Root" CornerRadius="12" Background="#162C3A" Padding="12">
    <Grid>
      <Grid.RowDefinitions>
        <RowDefinition Height="30"/>
        <RowDefinition Height="52"/>
        <RowDefinition Height="52"/>
        <RowDefinition Height="58"/>
        <RowDefinition Height="18"/>
      </Grid.RowDefinitions>
      <Grid Grid.Row="0">
        <StackPanel Orientation="Horizontal">
          <TextBlock x:Name="Title" Text="Codex 额度" FontSize="15" FontWeight="Bold" Foreground="White" VerticalAlignment="Center"/>
          <Border x:Name="PlanBadge" CornerRadius="2" Background="#00B52A" Margin="8,0,0,0" Padding="5,1" VerticalAlignment="Center">
            <TextBlock x:Name="PlanText" Text="Plus" FontSize="10" FontWeight="Bold" Foreground="White"/>
          </Border>
        </StackPanel>
        <Border HorizontalAlignment="Right" Width="111" Height="28" CornerRadius="14" BorderBrush="#587282" BorderThickness="1" Background="#263D4A">
          <Grid>
            <Grid.ColumnDefinitions><ColumnDefinition/><ColumnDefinition/><ColumnDefinition/></Grid.ColumnDefinitions>
            <Button x:Name="ThemeButton" Grid.Column="0" Content="☀" Background="Transparent" BorderThickness="0" Foreground="#DDE6EA"/>
            <Button x:Name="PinButton" Grid.Column="1" Content="📌" Background="Transparent" BorderThickness="0" Foreground="#DDE6EA"/>
            <Button x:Name="CloseButton" Grid.Column="2" Content="×" Background="Transparent" BorderThickness="0" Foreground="#DDE6EA" FontSize="16"/>
          </Grid>
        </Border>
      </Grid>
      <Grid Grid.Row="1" Margin="0,2,0,0">
        <TextBlock x:Name="FiveLabel" Text="5h" FontSize="13" FontWeight="Bold" Foreground="White"/>
        <TextBlock x:Name="FiveReset" Margin="40,1,0,0" Text="重置 -" FontSize="11" FontWeight="Bold" Foreground="#C9D2D8" TextTrimming="CharacterEllipsis"/>
        <Grid Margin="0,24,0,0" Width="186" Height="20" HorizontalAlignment="Left">
          <Rectangle Fill="#122832"/>
          <Rectangle x:Name="FiveFill" Width="0" HorizontalAlignment="Left" Fill="#00ff22"/>
        </Grid>
        <TextBlock x:Name="FivePercent" Margin="202,24,0,0" Text="-" FontSize="12" FontWeight="Bold" Foreground="#EAF0F3"/>
      </Grid>
      <Grid Grid.Row="2">
        <TextBlock x:Name="WeekLabel" Text="周" FontSize="13" FontWeight="Bold" Foreground="White"/>
        <TextBlock x:Name="WeekReset" Margin="40,1,0,0" Text="重置 -" FontSize="11" FontWeight="Bold" Foreground="#C9D2D8" TextTrimming="CharacterEllipsis"/>
        <Grid Margin="0,24,0,0" Width="186" Height="20" HorizontalAlignment="Left">
          <Rectangle Fill="#122832"/>
          <Rectangle x:Name="WeekFill" Width="0" HorizontalAlignment="Left" Fill="#00ff22"/>
        </Grid>
        <TextBlock x:Name="WeekPercent" Margin="202,24,0,0" Text="-" FontSize="12" FontWeight="Bold" Foreground="#EAF0F3"/>
      </Grid>
      <Grid Grid.Row="3" Margin="28,4,0,0" HorizontalAlignment="Left">
        <Grid.ColumnDefinitions><ColumnDefinition Width="132"/><ColumnDefinition Width="10"/><ColumnDefinition Width="132"/></Grid.ColumnDefinitions>
        <Border Grid.Column="0" CornerRadius="8" Background="#344A59" Padding="8">
          <StackPanel HorizontalAlignment="Center">
            <TextBlock Text="余额 ($)" Foreground="#D2DBE2" FontSize="10" FontWeight="Bold" HorizontalAlignment="Center"/>
            <TextBlock x:Name="BalanceValue" Text="0.00" Foreground="White" FontSize="15" FontWeight="Bold" HorizontalAlignment="Center" Margin="0,5,0,0"/>
          </StackPanel>
        </Border>
        <Border Grid.Column="2" CornerRadius="8" Background="#344A59" Padding="8">
          <StackPanel HorizontalAlignment="Center">
            <TextBlock Text="可用重置 (次)" Foreground="#D2DBE2" FontSize="10" FontWeight="Bold" HorizontalAlignment="Center"/>
            <TextBlock x:Name="ResetValue" Text="0" Foreground="White" FontSize="15" FontWeight="Bold" HorizontalAlignment="Center" Margin="0,5,0,0"/>
          </StackPanel>
        </Border>
      </Grid>
      <TextBlock x:Name="VersionLabel" Grid.Row="4" Text="v2.1.3" Foreground="#BBC4CE" FontSize="9" HorizontalAlignment="Right"/>
      <Grid x:Name="Overlay" Grid.RowSpan="5" Background="#A0000000" Visibility="Collapsed">
        <Border Width="294" Height="158" CornerRadius="12" BorderBrush="#3D5360" BorderThickness="1" Background="#111D24" Padding="18">
          <Grid>
            <TextBlock x:Name="SetupTitle" FontSize="14" FontWeight="Bold" Foreground="White" Text="需要安装 Codex CLI"/>
            <TextBlock x:Name="SetupMessage" Margin="0,32,0,0" TextWrapping="Wrap" FontSize="11" Foreground="#C9D2D8"/>
            <StackPanel Orientation="Horizontal" Margin="0,84,0,0">
              <TextBlock Text="● 安装 CLI" Foreground="#20F038" FontSize="10" FontWeight="Bold" Margin="0,0,16,0"/>
              <TextBlock Text="● 完成登录" Foreground="#88FFFFFF" FontSize="10" FontWeight="Bold" Margin="0,0,16,0"/>
              <TextBlock Text="● 同步配额" Foreground="#88FFFFFF" FontSize="10" FontWeight="Bold"/>
            </StackPanel>
            <Button x:Name="SetupButton" Content="打开指引" Width="90" Height="28" HorizontalAlignment="Right" VerticalAlignment="Bottom" Foreground="#46FF57" FontWeight="Bold" Background="#245F2F" BorderBrush="#20F038"/>
          </Grid>
        </Border>
      </Grid>
    </Grid>
  </Border>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)
$root = $window.FindName("Root")
$title = $window.FindName("Title")
$fiveLabel = $window.FindName("FiveLabel")
$weekLabel = $window.FindName("WeekLabel")
$fiveReset = $window.FindName("FiveReset")
$weekReset = $window.FindName("WeekReset")
$fiveFill = $window.FindName("FiveFill")
$weekFill = $window.FindName("WeekFill")
$fivePercent = $window.FindName("FivePercent")
$weekPercent = $window.FindName("WeekPercent")
$balanceValue = $window.FindName("BalanceValue")
$resetValue = $window.FindName("ResetValue")
$versionLabel = $window.FindName("VersionLabel")
$overlay = $window.FindName("Overlay")
$setupTitle = $window.FindName("SetupTitle")
$setupMessage = $window.FindName("SetupMessage")
$setupButton = $window.FindName("SetupButton")
$themeButton = $window.FindName("ThemeButton")
$pinButton = $window.FindName("PinButton")
$closeButton = $window.FindName("CloseButton")

Ensure-Directory $script:InstallDir
Load-State
Apply-Theme
$window.Topmost = $script:IsPinned

try {
    $state = Get-Content $script:StatePath -Raw | ConvertFrom-Json
    if ($null -ne $state.left -and $null -ne $state.top) {
        $window.Left = [double]$state.left
        $window.Top = [double]$state.top
    }
} catch {}

$window.Add_MouseLeftButtonDown({ $window.DragMove(); Save-State })
$themeButton.Add_Click({ $script:IsLight = -not $script:IsLight; Apply-Theme; Save-State })
$pinButton.Add_Click({ $script:IsPinned = -not $script:IsPinned; $window.Topmost = $script:IsPinned; Save-State })
$closeButton.Add_Click({ $window.Hide() })
$setupButton.Add_Click({
    $issue = Get-SetupIssue
    if ($issue -eq "missingLogin") {
        Start-Process "powershell.exe" -ArgumentList "-NoExit", "-Command", "codex login"
    } else {
        $command = "npm install -g @openai/codex; if (`$LASTEXITCODE -eq 0) { Write-Host 'Codex CLI installed. Run codex login next.'; codex --version } else { Write-Host 'Install failed. Install Node.js/npm first, then retry.' }"
        Start-Process "powershell.exe" -ArgumentList "-NoExit", "-Command", $command
    }
})

$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$notifyIcon.Text = "Quota Bubble"
$notifyIcon.Icon = [System.Drawing.SystemIcons]::Application
$notifyIcon.Visible = $true
$menu = New-Object System.Windows.Forms.ContextMenuStrip
$showItem = $menu.Items.Add((T "显示窗口" "Show window"))
$exitItem = $menu.Items.Add((T "退出" "Exit"))
$showItem.Add_Click({ $window.Show(); $window.Activate() })
$exitItem.Add_Click({ Save-State; $notifyIcon.Visible = $false; $window.Close() })
$notifyIcon.ContextMenuStrip = $menu
$notifyIcon.Add_DoubleClick({ $window.Show(); $window.Activate() })

$timer = New-Object Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromSeconds(1)
$timer.Add_Tick({ Update-Ui })
$timer.Start()
Update-Ui

$window.Add_Closing({ Save-State; $notifyIcon.Visible = $false; if ($mutex) { $mutex.ReleaseMutex(); $mutex.Dispose() } })
[void]$window.ShowDialog()

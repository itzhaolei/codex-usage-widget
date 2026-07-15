param([switch]$NoSingleInstance)

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
    if (-not $createdNew) { exit 0 }
}

$script:CodexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $env:USERPROFILE ".codex" }
$script:InstallDir = Join-Path $script:CodexHome "usage-widget"
$script:StatePath = Join-Path $script:InstallDir "windows-state.json"
$script:SnapshotScript = Join-Path $script:CodexHome "scripts\codex-usage-snapshot.mjs"
$script:SnapshotPath = Join-Path $script:CodexHome "codex-usage-snapshot.json"
$script:AuthPath = Join-Path $script:CodexHome "auth.json"
$versionPath = Join-Path $PSScriptRoot "VERSION"
$script:Version = if (Test-Path $versionPath) { (Get-Content $versionPath -Raw).Trim() } else { "3.0.2" }
$script:IsLight = $false
$script:IsPinned = $true
$script:LanguageOverride = $null
$script:SnapshotProcess = $null
$script:Snapshot = $null
$script:LastAuth = $null
$script:LatestRelease = $null
$script:VersionClient = $null
$script:VersionTask = $null
$script:LastVersionCheck = [DateTime]::MinValue

function Ensure-Directory($path) {
    if (-not (Test-Path $path)) { New-Item -ItemType Directory -Path $path -Force | Out-Null }
}

function Get-SystemLanguage {
    $code = [System.Globalization.CultureInfo]::CurrentUICulture.TwoLetterISOLanguageName.ToLowerInvariant()
    if (@("zh", "ja", "ko", "de", "fr", "es", "pt", "it", "nl") -contains $code) { return $code }
    return "en"
}

function Get-Language { if ($script:LanguageOverride) { return $script:LanguageOverride }; return Get-SystemLanguage }

function Get-Copy($code) {
    $copies = @{
        en = @{ Title="Codex Quota"; Week="Week"; Reset="Reset"; Balance="Balance"; Available="Available resets"; Times="times"; Show="Show window"; Update="Check for updates"; Latest="Already up to date"; Updating="Downloading update"; UpdateFailed="Update failed"; Exit="Exit"; Language="Language"; Follow="Follow system" }
        zh = @{ Title="Codex 额度"; Week="周"; Reset="重置"; Balance="余额"; Available="可用重置"; Times="次"; Show="显示窗口"; Update="检查更新"; Latest="已经是最新版本"; Updating="正在下载更新"; UpdateFailed="更新失败"; Exit="退出"; Language="语言"; Follow="跟随系统" }
        ja = @{ Title="Codex 使用量"; Week="週"; Reset="リセット"; Balance="残高"; Available="利用可能なリセット"; Times="回"; Show="ウィンドウを表示"; Update="アップデートを確認"; Latest="最新バージョンです"; Updating="更新をダウンロード中"; UpdateFailed="更新に失敗しました"; Exit="終了"; Language="言語"; Follow="システムに従う" }
        ko = @{ Title="Codex 사용량"; Week="주"; Reset="재설정"; Balance="잔액"; Available="사용 가능 재설정"; Times="회"; Show="창 표시"; Update="업데이트 확인"; Latest="최신 버전입니다"; Updating="업데이트 다운로드 중"; UpdateFailed="업데이트 실패"; Exit="종료"; Language="언어"; Follow="시스템 따르기" }
        de = @{ Title="Codex Limit"; Week="Woche"; Reset="Reset"; Balance="Guthaben"; Available="Verfügbare Resets"; Times="Mal"; Show="Fenster anzeigen"; Update="Nach Updates suchen"; Latest="Bereits aktuell"; Updating="Update wird geladen"; UpdateFailed="Update fehlgeschlagen"; Exit="Beenden"; Language="Sprache"; Follow="System folgen" }
        fr = @{ Title="Quota Codex"; Week="Semaine"; Reset="Réinit."; Balance="Solde"; Available="Réinitialisations dispo."; Times="fois"; Show="Afficher la fenêtre"; Update="Rechercher les mises à jour"; Latest="Déjà à jour"; Updating="Téléchargement de la mise à jour"; UpdateFailed="Échec de la mise à jour"; Exit="Quitter"; Language="Langue"; Follow="Suivre le système" }
        es = @{ Title="Cuota Codex"; Week="Semana"; Reset="Reinicio"; Balance="Saldo"; Available="Reinicios disponibles"; Times="veces"; Show="Mostrar ventana"; Update="Buscar actualizaciones"; Latest="Ya está actualizado"; Updating="Descargando actualización"; UpdateFailed="Error al actualizar"; Exit="Salir"; Language="Idioma"; Follow="Seguir sistema" }
        pt = @{ Title="Cota Codex"; Week="Semana"; Reset="Redefinir"; Balance="Saldo"; Available="Redefinições disponíveis"; Times="vezes"; Show="Mostrar janela"; Update="Verificar atualizações"; Latest="Já está atualizado"; Updating="Baixando atualização"; UpdateFailed="Falha na atualização"; Exit="Sair"; Language="Idioma"; Follow="Seguir sistema" }
        it = @{ Title="Quota Codex"; Week="Settimana"; Reset="Ripristino"; Balance="Saldo"; Available="Ripristini disponibili"; Times="volte"; Show="Mostra finestra"; Update="Controlla aggiornamenti"; Latest="Già aggiornato"; Updating="Download aggiornamento"; UpdateFailed="Aggiornamento non riuscito"; Exit="Esci"; Language="Lingua"; Follow="Segui sistema" }
        nl = @{ Title="Codex-limiet"; Week="Week"; Reset="Reset"; Balance="Saldo"; Available="Beschikbare resets"; Times="keer"; Show="Venster tonen"; Update="Controleren op updates"; Latest="Al bijgewerkt"; Updating="Update downloaden"; UpdateFailed="Bijwerken mislukt"; Exit="Afsluiten"; Language="Taal"; Follow="Systeem volgen" }
    }
    return $copies[$code]
}

function Load-State {
    if (-not (Test-Path $script:StatePath)) { return }
    try {
        $state = Get-Content $script:StatePath -Raw | ConvertFrom-Json
        if ($null -ne $state.light) { $script:IsLight = [bool]$state.light }
        if ($null -ne $state.pinned) { $script:IsPinned = [bool]$state.pinned }
        if ($state.language) { $script:LanguageOverride = [string]$state.language }
    } catch {}
}

function Save-State {
    Ensure-Directory $script:InstallDir
    [ordered]@{ light=$script:IsLight; pinned=$script:IsPinned; language=$script:LanguageOverride; left=$window.Left; top=$window.Top } |
        ConvertTo-Json | Set-Content -Path $script:StatePath -Encoding UTF8
}

function Get-Fingerprint($kind, $value) {
    if (-not $value) { return $null }
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes([string]$value)
        $hex = -join ($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString("x2") })
        return "${kind}:$($hex.Substring(0, 16))"
    } finally { $sha.Dispose() }
}

function Get-AuthInfo {
    try {
        $auth = Get-Content $script:AuthPath -Raw | ConvertFrom-Json
        $tokens = $auth.tokens
        $fingerprint = if ($tokens.account_id) { Get-Fingerprint "account" $tokens.account_id } else { Get-Fingerprint "token" $tokens.access_token }
        $email = $null; $expires = $null
        if ($tokens.id_token) {
            $parts = ([string]$tokens.id_token).Split('.')
            if ($parts.Length -gt 1) {
                $payload = $parts[1].Replace('-', '+').Replace('_', '/')
                while (($payload.Length % 4) -ne 0) { $payload += "=" }
                $claims = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($payload)) | ConvertFrom-Json
                $email = $claims.email
                $authProperty = $claims.PSObject.Properties["https://api.openai.com/auth"]
                if ($authProperty) { $expires = $authProperty.Value.chatgpt_subscription_active_until }
            }
        }
        return [pscustomobject]@{ Fingerprint=$fingerprint; Email=$email; Expires=$expires }
    } catch { return $null }
}

function Get-StableAuth {
    $value = Get-AuthInfo
    if ($value) { $script:LastAuth = $value; return $value }
    if (Test-Path $script:AuthPath) { return $script:LastAuth }
    $script:LastAuth = $null
    return $null
}

function Run-Snapshot {
    if ($script:SnapshotProcess) {
        if (-not $script:SnapshotProcess.HasExited) { return }
        $script:SnapshotProcess.Dispose(); $script:SnapshotProcess = $null
    }
    if (-not (Test-Path $script:SnapshotScript)) { return }
    $node = Get-Command node -ErrorAction SilentlyContinue
    if (-not $node) { return }
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo.FileName = $node.Source
    $process.StartInfo.Arguments = "`"$script:SnapshotScript`" `"$script:SnapshotPath`""
    $process.StartInfo.UseShellExecute = $false
    $process.StartInfo.CreateNoWindow = $true
    if ($process.Start()) { $script:SnapshotProcess = $process }
}

function Read-VerifiedSnapshot($auth) {
    try {
        $value = Get-Content $script:SnapshotPath -Raw | ConvertFrom-Json
        $snapshotFingerprint = [string]$value.account_fingerprint
        $authFingerprint = if ($auth) { [string]$auth.Fingerprint } else { "" }
        if ($snapshotFingerprint -ne $authFingerprint) { $script:Snapshot = $null; return $null }
        $script:Snapshot = $value
    } catch {}
    return $script:Snapshot
}

function Get-Remaining($usageWindow) {
    if ($null -eq $usageWindow -or $null -eq $usageWindow.used_percentage) { return $null }
    return [Math]::Max(0, [Math]::Min(100, 100 - [int]$usageWindow.used_percentage))
}

function Format-Duration($epoch) {
    if ($null -eq $epoch) { return "—" }
    $seconds = [Math]::Max(1, [int64]$epoch - [DateTimeOffset]::UtcNow.ToUnixTimeSeconds())
    $parts = New-Object System.Collections.Generic.List[string]
    $days = [Math]::Floor($seconds / 86400); $seconds %= 86400
    $hours = [Math]::Floor($seconds / 3600); $seconds %= 3600
    $minutes = [Math]::Floor($seconds / 60); $seconds %= 60
    if ($days -gt 0) { $parts.Add("${days}d") }
    if ($hours -gt 0) { $parts.Add("${hours}h") }
    if ($minutes -gt 0) { $parts.Add("${minutes}m") }
    if ($seconds -gt 0 -or $parts.Count -eq 0) { $parts.Add("${seconds}s") }
    return $parts -join " "
}

function Format-Date($raw) {
    if (-not $raw) { return "—" }
    try { return ([DateTimeOffset]::Parse([string]$raw)).ToLocalTime().ToString("g", [System.Globalization.CultureInfo]::CurrentCulture) } catch { return [string]$raw }
}

function Get-Plan($raw) {
    $value = ([string]$raw).ToLowerInvariant().Replace("_", "").Replace("-", "").Replace(" ", "")
    if ($value.Contains("20x") -or $value.Contains("pro20")) { return "Pro20x" }
    if ($value.Contains("5x") -or $value.Contains("pro5")) { return "Pro5x" }
    if ($value -eq "plus") { return "Plus" }
    if ($value -eq "pro") { return "Pro" }
    if ($value -eq "free") { return "Free" }
    return ""
}

function New-DotBrush($color) {
    $drawing = New-Object Windows.Media.GeometryDrawing
    $drawing.Brush = (New-Object Windows.Media.BrushConverter).ConvertFromString($color)
    $drawing.Geometry = [Windows.Media.EllipseGeometry]::new([Windows.Point]::new(0.6, 0.6), 0.55, 0.55)
    $brush = [Windows.Media.DrawingBrush]::new($drawing)
    $brush.TileMode = [Windows.Media.TileMode]::Tile
    $brush.ViewportUnits = [Windows.Media.BrushMappingMode]::Absolute
    $brush.Viewport = [Windows.Rect]::new(0, 0, 3, 3)
    return $brush
}

function Set-Bar($remaining) {
    if ($null -eq $remaining) { $barFill.Width=0; $percentText.Text="—"; return }
    $color = if ($remaining -le 20) { "#FF3333" } else { "#00F020" }
    $barFill.Width = [Math]::Round(231 * $remaining / 100)
    $barFill.Fill = (New-Object Windows.Media.BrushConverter).ConvertFromString($color)
    $barPattern.Fill = New-DotBrush $color
    foreach ($line in $separatorLines) { $line.Background = (New-Object Windows.Media.BrushConverter).ConvertFromString($color) }
    $percentText.Text = "${remaining}%"
}

function Update-ResetRows($credits) {
    $resetList.Children.Clear()
    $values = @(); if ($credits -and $credits.expires_at) { $values = @($credits.expires_at) }
    $count = if ($credits -and $null -ne $credits.available_count) { [Math]::Max(0, [int]$credits.available_count) } else { $values.Count }
    for ($i=0; $i -lt $count; $i++) {
        $row = New-Object Windows.Controls.StackPanel; $row.Orientation="Horizontal"; $row.Height=18
        $dot = New-Object Windows.Shapes.Ellipse; $dot.Width=7; $dot.Height=7; $dot.Margin="0,5,12,0"; $dot.VerticalAlignment="Top"
        if ($i -lt $values.Count) {
            try { $soon = ([DateTimeOffset]::Parse([string]$values[$i]) - [DateTimeOffset]::Now).TotalDays -le 3 } catch { $soon = $false }
            $dot.Fill = (New-Object Windows.Media.BrushConverter).ConvertFromString($(if ($soon) { "#FF3333" } else { "#00E834" }))
            $textValue = Format-Date $values[$i]
        } else { $dot.Fill="#7F8B92"; $textValue="—" }
        $text = New-Object Windows.Controls.TextBlock; $text.Text=$textValue; $text.FontSize=10; $text.FontFamily="Consolas"; $text.VerticalAlignment="Center"; $text.Foreground=$secondaryBrush
        [void]$row.Children.Add($dot); [void]$row.Children.Add($text); [void]$resetList.Children.Add($row)
    }
}

$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Width="330" SizeToContent="Height" MinHeight="234" WindowStyle="None" ResizeMode="NoResize" AllowsTransparency="True" Background="Transparent" ShowInTaskbar="True">
  <Border x:Name="Root" CornerRadius="12" Background="#E6111D18" BorderBrush="#436A6F70" BorderThickness="1" Padding="12">
    <Grid>
      <Grid.RowDefinitions><RowDefinition Height="32"/><RowDefinition Height="66"/><RowDefinition Height="Auto"/><RowDefinition Height="59"/><RowDefinition Height="38"/><RowDefinition Height="16"/></Grid.RowDefinitions>
      <Grid Grid.Row="0">
        <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
          <TextBlock x:Name="Title" FontSize="15" FontWeight="Bold" Foreground="White" VerticalAlignment="Center" TextTrimming="CharacterEllipsis" MaxWidth="174"/>
          <Border x:Name="PlanBadge" CornerRadius="2" Margin="7,0,0,0" Padding="6,1" Height="16" VerticalAlignment="Center"><TextBlock x:Name="PlanText" FontSize="10" FontWeight="SemiBold" Foreground="White"/></Border>
        </StackPanel>
        <Border x:Name="Capsule" HorizontalAlignment="Right" Width="111" Height="28" CornerRadius="14" BorderBrush="#587282" BorderThickness="1" Background="#263D4A">
          <Grid><Grid.ColumnDefinitions><ColumnDefinition/><ColumnDefinition/><ColumnDefinition/></Grid.ColumnDefinitions>
            <Button x:Name="ThemeButton" Grid.Column="0" Content="☀" Background="Transparent" BorderThickness="0" Foreground="#DDE6EA"/>
            <Button x:Name="PinButton" Grid.Column="1" Content="●" Background="Transparent" BorderThickness="0" Foreground="#DDE6EA"/>
            <Button x:Name="CloseButton" Grid.Column="2" Content="×" Background="Transparent" BorderThickness="0" Foreground="#DDE6EA" FontSize="16"/>
          </Grid>
        </Border>
      </Grid>
      <Grid Grid.Row="1" Margin="0,8,0,0">
        <StackPanel Orientation="Horizontal"><TextBlock x:Name="WeekLabel" FontSize="13" FontWeight="Bold" Foreground="White"/><TextBlock Text=" | " FontSize="10" Foreground="#AEB9BF"/><TextBlock x:Name="ResetText" FontSize="10" Foreground="#AEB9BF" TextTrimming="CharacterEllipsis" MaxWidth="238"/></StackPanel>
        <Grid Margin="0,23,0,0" Width="231" Height="35" HorizontalAlignment="Left" ClipToBounds="True">
          <Rectangle x:Name="BarPattern" Opacity="0.75"/><Rectangle x:Name="BarFill" Width="0" HorizontalAlignment="Left"/>
          <Canvas IsHitTestVisible="False"><Border x:Name="Sep1" Canvas.Left="46" Width="1" Height="35" Opacity="0.48"/><Border x:Name="Sep2" Canvas.Left="92" Width="1" Height="35" Opacity="0.48"/><Border x:Name="Sep3" Canvas.Left="138" Width="1" Height="35" Opacity="0.48"/><Border x:Name="Sep4" Canvas.Left="184" Width="1" Height="35" Opacity="0.48"/></Canvas>
        </Grid>
        <TextBlock x:Name="PercentText" Margin="243,31,0,0" FontSize="11" FontFamily="Consolas" Foreground="White"/>
      </Grid>
      <StackPanel x:Name="ResetList" Grid.Row="2" Margin="0,8,0,8"/>
      <Grid Grid.Row="3" HorizontalAlignment="Left"><Grid.ColumnDefinitions><ColumnDefinition Width="131"/><ColumnDefinition Width="10"/><ColumnDefinition Width="131"/></Grid.ColumnDefinitions>
        <Border x:Name="BalanceCard" Grid.Column="0" CornerRadius="9" Background="#25373B3D" BorderBrush="#30FFFFFF" BorderThickness="1" Padding="4,7,4,5"><StackPanel><TextBlock x:Name="BalanceTitle" Foreground="#B8C2C7" FontSize="9" FontFamily="Consolas" FontWeight="Medium" TextAlignment="Center" TextWrapping="Wrap" MaxHeight="24"/><TextBlock x:Name="BalanceValue" Foreground="White" FontSize="13" FontFamily="Consolas" FontWeight="SemiBold" TextAlignment="Center" Margin="0,3,0,0"/></StackPanel></Border>
        <Border x:Name="ResetCard" Grid.Column="2" CornerRadius="9" Background="#25373B3D" BorderBrush="#30FFFFFF" BorderThickness="1" Padding="4,7,4,5"><StackPanel><TextBlock x:Name="ResetTitle" Foreground="#B8C2C7" FontSize="9" FontFamily="Consolas" FontWeight="Medium" TextAlignment="Center" TextWrapping="Wrap" MaxHeight="24"/><TextBlock x:Name="ResetValue" Foreground="White" FontSize="13" FontFamily="Consolas" FontWeight="SemiBold" TextAlignment="Center" Margin="0,3,0,0"/></StackPanel></Border>
      </Grid>
      <StackPanel Grid.Row="4" Margin="0,5,0,0"><StackPanel Orientation="Horizontal" Height="17"><TextBlock Text="●" FontSize="9" Foreground="#AEB9BF" Width="20"/><TextBlock x:Name="AccountText" FontSize="10" FontFamily="Consolas" Foreground="#AEB9BF" TextTrimming="CharacterEllipsis" MaxWidth="270"/></StackPanel><StackPanel Orientation="Horizontal" Height="17"><TextBlock Text="▣" FontSize="9" Foreground="#AEB9BF" Width="20"/><TextBlock x:Name="SubscriptionText" FontSize="10" FontFamily="Consolas" Foreground="#AEB9BF" TextTrimming="CharacterEllipsis" MaxWidth="270"/></StackPanel></StackPanel>
      <StackPanel Grid.Row="5" Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Bottom"><Ellipse x:Name="UpdateDot" Width="4" Height="4" Fill="#FF3333" Margin="0,0,4,2" Visibility="Collapsed"/><TextBlock x:Name="VersionLabel" FontSize="9" FontWeight="Light" FontFamily="Consolas" Foreground="#AEB9BF"/></StackPanel>
    </Grid>
  </Border>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)
$root=$window.FindName("Root"); $title=$window.FindName("Title"); $planBadge=$window.FindName("PlanBadge"); $planText=$window.FindName("PlanText")
$capsule=$window.FindName("Capsule"); $themeButton=$window.FindName("ThemeButton"); $pinButton=$window.FindName("PinButton"); $closeButton=$window.FindName("CloseButton")
$weekLabel=$window.FindName("WeekLabel"); $resetText=$window.FindName("ResetText"); $barPattern=$window.FindName("BarPattern"); $barFill=$window.FindName("BarFill")
$sep1=$window.FindName("Sep1"); $sep2=$window.FindName("Sep2"); $sep3=$window.FindName("Sep3"); $sep4=$window.FindName("Sep4"); $percentText=$window.FindName("PercentText")
$resetList=$window.FindName("ResetList"); $balanceCard=$window.FindName("BalanceCard"); $resetCard=$window.FindName("ResetCard"); $balanceTitle=$window.FindName("BalanceTitle")
$balanceValue=$window.FindName("BalanceValue"); $resetTitle=$window.FindName("ResetTitle"); $resetValue=$window.FindName("ResetValue"); $accountText=$window.FindName("AccountText")
$subscriptionText=$window.FindName("SubscriptionText"); $updateDot=$window.FindName("UpdateDot"); $versionLabel=$window.FindName("VersionLabel")
$separatorLines = @($sep1,$sep2,$sep3,$sep4)

function Apply-Theme {
    $primaryColor = if ($script:IsLight) { "#111827" } else { "#FFFFFF" }
    $secondaryColor = if ($script:IsLight) { "#59636B" } else { "#AEB9BF" }
    $script:secondaryBrush = (New-Object Windows.Media.BrushConverter).ConvertFromString($secondaryColor)
    $root.Background = (New-Object Windows.Media.BrushConverter).ConvertFromString($(if ($script:IsLight) { "#E8F3F7F8" } else { "#E6111D18" }))
    foreach ($control in @($title,$weekLabel,$percentText)) { $control.Foreground=$primaryColor }
    foreach ($control in @($resetText,$accountText,$subscriptionText,$versionLabel,$balanceTitle,$resetTitle)) { $control.Foreground=$secondaryColor }
    foreach ($control in @($balanceValue,$resetValue)) { $control.Foreground=$primaryColor }
    $balanceCard.Background=$(if ($script:IsLight){"#78FFFFFF"}else{"#25373B3D"}); $resetCard.Background=$balanceCard.Background
    $themeButton.Content=$(if ($script:IsLight){"☾"}else{"☀"}); $pinButton.Foreground=$(if ($script:IsPinned){"#20E84A"}else{$secondaryColor})
}

function Apply-Localization {
    $copy = Get-Copy (Get-Language)
    $title.Text=$copy.Title; $weekLabel.Text=$copy.Week; $balanceTitle.Text="$($copy.Balance) (`$)"; $resetTitle.Text="$($copy.Available) ($($copy.Times))"; $versionLabel.Text="v$script:Version"
    if ($showItem) { $showItem.Text=$copy.Show; $updateItem.Text=$copy.Update; $exitItem.Text=$copy.Exit; $languageItem.Text=$copy.Language }
}

function Update-Ui {
    Run-Snapshot
    $auth = Get-StableAuth
    $snapshot = Read-VerifiedSnapshot $auth
    $copy = Get-Copy (Get-Language)
    $plan = Get-Plan $snapshot.plan_type; $planText.Text=$plan; $planBadge.Visibility=$(if($plan){"Visible"}else{"Collapsed"})
    $planBadge.Background=$(if($plan -eq "Plus"){"#00B817"}elseif($plan -like "Pro*"){"#F28C28"}else{"#737A80"})
    $usageWindow = $snapshot.five_hour
    $resetText.Text="$($copy.Reset) $(Format-Duration $usageWindow.resets_at)"
    Set-Bar (Get-Remaining $usageWindow)
    Update-ResetRows $snapshot.reset_credits
    if ($null -ne $snapshot.balance_usd -and [string]$snapshot.balance_usd -ne "") { try { $balanceValue.Text=([double]$snapshot.balance_usd).ToString("0.00") } catch { $balanceValue.Text=[string]$snapshot.balance_usd } } else { $balanceValue.Text="—" }
    $resetValue.Text=if($snapshot.reset_credits -and $null -ne $snapshot.reset_credits.available_count){[string]$snapshot.reset_credits.available_count}else{"—"}
    $accountText.Text=if($auth -and $auth.Email){[string]$auth.Email}else{"—"}; $subscriptionText.Text=if($auth){Format-Date $auth.Expires}else{"—"}
    Process-VersionCheck
}

function Begin-VersionCheck {
    if ($script:VersionTask) { return }
    if (([DateTime]::UtcNow - $script:LastVersionCheck).TotalMinutes -lt 30) { return }
    $script:LastVersionCheck=[DateTime]::UtcNow; $script:VersionClient=New-Object System.Net.WebClient; $script:VersionClient.Headers.Add("User-Agent","Quota-Bubble-Windows")
    $script:VersionTask=$script:VersionClient.DownloadStringTaskAsync([Uri]"https://api.github.com/repos/itzhaolei/codex-usage-widget/releases/latest")
}

function Process-VersionCheck {
    if (-not $script:VersionTask) { Begin-VersionCheck; return }
    if (-not $script:VersionTask.IsCompleted) { return }
    if (-not $script:VersionTask.IsFaulted -and -not $script:VersionTask.IsCanceled) {
        try { $script:LatestRelease=$script:VersionTask.Result | ConvertFrom-Json; $updateDot.Visibility=$(if([version]($script:LatestRelease.tag_name.TrimStart('v')) -gt [version]$script:Version){"Visible"}else{"Collapsed"}) } catch {}
    }
    $script:VersionTask=$null; if($script:VersionClient){$script:VersionClient.Dispose();$script:VersionClient=$null}
}

function Install-LatestUpdate {
    $copy=Get-Copy (Get-Language)
    try {
        $release=Invoke-RestMethod -Headers @{"User-Agent"="Quota-Bubble-Windows"} -Uri "https://api.github.com/repos/itzhaolei/codex-usage-widget/releases/latest"
        if ([version]($release.tag_name.TrimStart('v')) -le [version]$script:Version) { [Windows.MessageBox]::Show($copy.Latest,"Quota Bubble")|Out-Null; return }
        $asset=$release.assets|Where-Object{$_.name -like "*Windows.zip"}|Select-Object -First 1
        if(-not $asset){throw "Windows installer asset not found"}
        $temp=Join-Path $env:TEMP "quota-bubble-update-$([Guid]::NewGuid())"; New-Item -ItemType Directory -Path $temp -Force|Out-Null
        $zip=Join-Path $temp "installer.zip"; Invoke-WebRequest -UseBasicParsing -Uri $asset.browser_download_url -OutFile $zip; Expand-Archive -Path $zip -DestinationPath $temp -Force
        $installer=Get-ChildItem $temp -Filter install.ps1 -Recurse|Select-Object -First 1; if(-not $installer){throw "install.ps1 not found"}
        $escaped=$installer.FullName.Replace("'","''"); Start-Process powershell.exe -ArgumentList "-NoProfile","-ExecutionPolicy","Bypass","-Command","Start-Sleep 2; & '$escaped'"
        $window.Close()
    } catch { [Windows.MessageBox]::Show("$($copy.UpdateFailed): $($_.Exception.Message)","Quota Bubble")|Out-Null }
}

Ensure-Directory $script:InstallDir; Load-State
$window.Topmost=$script:IsPinned; Apply-Theme; Apply-Localization
try { $state=Get-Content $script:StatePath -Raw|ConvertFrom-Json; if($null-ne $state.left-and $null-ne $state.top){$window.Left=[double]$state.left;$window.Top=[double]$state.top} } catch {}
$window.Add_MouseLeftButtonDown({$window.DragMove();Save-State})
$themeButton.Add_Click({$script:IsLight=-not $script:IsLight;Apply-Theme;Save-State})
$pinButton.Add_Click({$script:IsPinned=-not $script:IsPinned;$window.Topmost=$script:IsPinned;Apply-Theme;Save-State})
$closeButton.Add_Click({$window.Close()})

$notifyIcon=New-Object System.Windows.Forms.NotifyIcon; $notifyIcon.Text="Quota Bubble"; $notifyIcon.Icon=[System.Drawing.SystemIcons]::Application; $notifyIcon.Visible=$true
$menu=New-Object System.Windows.Forms.ContextMenuStrip; $showItem=$menu.Items.Add(""); $languageItem=New-Object System.Windows.Forms.ToolStripMenuItem; [void]$menu.Items.Add($languageItem)
$languageChoices=[ordered]@{""="System";en="English";zh="中文";ja="日本語";ko="한국어";de="Deutsch";fr="Français";es="Español";pt="Português";it="Italiano";nl="Nederlands"}
foreach($entry in $languageChoices.GetEnumerator()){$item=$languageItem.DropDownItems.Add($entry.Value);$code=$entry.Key;$item.Checked=($script:LanguageOverride -eq $code -or (-not $script:LanguageOverride -and $code -eq ""));$item.Add_Click({$script:LanguageOverride=$code;if(-not $code){$script:LanguageOverride=$null};foreach($child in $languageItem.DropDownItems){$child.Checked=$false};$this.Checked=$true;Apply-Localization;Save-State}.GetNewClosure())}
$updateItem=$menu.Items.Add(""); [void]$menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator)); $exitItem=$menu.Items.Add(""); Apply-Localization
$showItem.Add_Click({$window.Show();$window.Activate()}); $updateItem.Add_Click({Install-LatestUpdate}); $exitItem.Add_Click({$window.Close()}); $notifyIcon.ContextMenuStrip=$menu; $notifyIcon.Add_DoubleClick({$window.Show();$window.Activate()})

$timer=New-Object Windows.Threading.DispatcherTimer; $timer.Interval=[TimeSpan]::FromSeconds(1); $timer.Add_Tick({Update-Ui}); $timer.Start(); Update-Ui
$window.Add_Closing({Save-State;$notifyIcon.Visible=$false;$timer.Stop();if($script:SnapshotProcess -and -not $script:SnapshotProcess.HasExited){$script:SnapshotProcess.Kill()};if($mutex){$mutex.ReleaseMutex();$mutex.Dispose()}})
[void]$window.ShowDialog()

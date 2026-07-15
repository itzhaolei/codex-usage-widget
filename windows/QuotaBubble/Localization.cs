using System.Globalization;

namespace QuotaBubble;

public sealed record Copy(
    string Title, string Week, string Reset, string Balance, string Available, string Times,
    string Show, string Update, string Latest, string Updating, string UpdateSuccess,
    string UpdateFailed, string Exit, string Language, string Follow);

public static class Localization
{
    public static readonly IReadOnlyDictionary<string, string> LanguageNames = new Dictionary<string, string>
    {
        [""] = "System", ["en"] = "English", ["zh"] = "中文", ["ja"] = "日本語",
        ["ko"] = "한국어", ["de"] = "Deutsch", ["fr"] = "Français", ["es"] = "Español",
        ["pt"] = "Português", ["it"] = "Italiano", ["nl"] = "Nederlands"
    };

    private static readonly IReadOnlyDictionary<string, Copy> Copies = new Dictionary<string, Copy>
    {
        ["en"] = new("Codex Quota", "Week", "Reset", "Balance", "Available resets", "times", "Show window", "Check for updates", "Already up to date", "Downloading update", "Update downloaded. Installing now.", "Update failed", "Exit", "Language", "Follow system"),
        ["zh"] = new("Codex 额度", "周", "重置", "余额", "可用重置", "次", "显示窗口", "检查更新", "已经是最新版本", "正在下载更新", "更新已下载，正在安装", "更新失败", "退出", "语言", "跟随系统"),
        ["ja"] = new("Codex 使用量", "週", "リセット", "残高", "利用可能なリセット", "回", "ウィンドウを表示", "アップデートを確認", "最新バージョンです", "更新をダウンロード中", "更新をインストールします", "更新に失敗しました", "終了", "言語", "システムに従う"),
        ["ko"] = new("Codex 사용량", "주", "재설정", "잔액", "사용 가능 재설정", "회", "창 표시", "업데이트 확인", "최신 버전입니다", "업데이트 다운로드 중", "업데이트를 설치합니다", "업데이트 실패", "종료", "언어", "시스템 따르기"),
        ["de"] = new("Codex Limit", "Woche", "Reset", "Guthaben", "Verfügbare Resets", "Mal", "Fenster anzeigen", "Nach Updates suchen", "Bereits aktuell", "Update wird geladen", "Update wird installiert", "Update fehlgeschlagen", "Beenden", "Sprache", "System folgen"),
        ["fr"] = new("Quota Codex", "Semaine", "Réinit.", "Solde", "Réinitialisations dispo.", "fois", "Afficher la fenêtre", "Rechercher les mises à jour", "Déjà à jour", "Téléchargement de la mise à jour", "Installation de la mise à jour", "Échec de la mise à jour", "Quitter", "Langue", "Suivre le système"),
        ["es"] = new("Cuota Codex", "Semana", "Reinicio", "Saldo", "Reinicios disponibles", "veces", "Mostrar ventana", "Buscar actualizaciones", "Ya está actualizado", "Descargando actualización", "Instalando actualización", "Error al actualizar", "Salir", "Idioma", "Seguir sistema"),
        ["pt"] = new("Cota Codex", "Semana", "Redefinir", "Saldo", "Redefinições disponíveis", "vezes", "Mostrar janela", "Verificar atualizações", "Já está atualizado", "Baixando atualização", "Instalando atualização", "Falha na atualização", "Sair", "Idioma", "Seguir sistema"),
        ["it"] = new("Quota Codex", "Settimana", "Ripristino", "Saldo", "Ripristini disponibili", "volte", "Mostra finestra", "Controlla aggiornamenti", "Già aggiornato", "Download aggiornamento", "Installazione aggiornamento", "Aggiornamento non riuscito", "Esci", "Lingua", "Segui sistema"),
        ["nl"] = new("Codex-limiet", "Week", "Reset", "Saldo", "Beschikbare resets", "keer", "Venster tonen", "Controleren op updates", "Al bijgewerkt", "Update downloaden", "Update installeren", "Bijwerken mislukt", "Afsluiten", "Taal", "Systeem volgen")
    };

    public static string ResolveLanguage(string? selected)
    {
        if (!string.IsNullOrWhiteSpace(selected) && Copies.ContainsKey(selected)) return selected;
        var code = CultureInfo.CurrentUICulture.TwoLetterISOLanguageName.ToLowerInvariant();
        return Copies.ContainsKey(code) ? code : "en";
    }

    public static Copy Get(string? selected) => Copies[ResolveLanguage(selected)];
}

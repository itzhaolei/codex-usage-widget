import Foundation

struct UsageSnapshot: Codable, Equatable {
    var updated_at: String?
    var account_fingerprint: String?
    var plan_type: String?
    var balance_usd: String?
    var five_hour: UsageWindow?
    var seven_day: UsageWindow?
    var reset_credits: ResetCredits?
}

struct UsageWindow: Codable, Equatable {
    var used_percentage: Int?
    var resets_at: TimeInterval?
}

struct ResetCredits: Codable, Equatable {
    var available_count: Int?
    var expires_at: [String]?
}

struct ResetExpirationRow: Identifiable, Equatable {
    let id: Int
    let dateText: String
    let isExpiringSoon: Bool?
}

struct AuthDisplayInfo: Equatable {
    var email: String?
    var subscriptionExpiresAt: String?
    var accountFingerprint: String?
}

struct AppCopy {
    let title: String
    let week: String
    let reset: String
    let availableReset: String
    let balance: String
    let times: String
    let alreadyReset: String
    let language: String
    let website: String
    let followSystem: String
    let update: String
    let uninstall: String
    let switchToDark: String
    let switchToLight: String
    let pin: String
    let unpin: String
    let close: String
}

let officialWebsiteURLString = "https://htmlpreview.github.io/?https://github.com/itzhaolei/codex-usage-widget/blob/main/public/index.html?v=20260716-3"

func localizedWebsiteShareLabel(_ code: String) -> String {
    switch code {
    case "zh": return "分享"
    case "ja": return "共有"
    case "ko": return "공유"
    case "de": return "Teilen"
    case "fr": return "Partager"
    case "es": return "Compartir"
    case "pt": return "Compartilhar"
    case "it": return "Condividi"
    case "nl": return "Delen"
    default: return "Share"
    }
}

func localizedWebsiteCopiedMessage(_ code: String) -> String {
    switch code {
    case "zh": return "已复制官网信息到剪贴板"
    case "ja": return "公式サイトの情報をクリップボードにコピーしました"
    case "ko": return "공식 웹사이트 정보를 클립보드에 복사했습니다"
    case "de": return "Website-Informationen wurden in die Zwischenablage kopiert"
    case "fr": return "Les informations du site ont été copiées dans le presse-papiers"
    case "es": return "La información del sitio se copió al portapapeles"
    case "pt": return "As informações do site foram copiadas para a área de transferência"
    case "it": return "Le informazioni del sito sono state copiate negli appunti"
    case "nl": return "De websitegegevens zijn naar het klembord gekopieerd"
    default: return "Official website information copied to the clipboard"
    }
}

struct DialogCopy {
    let checking: String
    let downloading: String
    let upToDate: String
    let updateComplete: String
    let updateFailed: String
    let uninstallTitle: String
    let uninstallMessage: String
    let confirmUninstall: String
    let cancel: String
}

func localizedDialogCopy(_ code: String) -> DialogCopy {
    switch code {
    case "zh": return DialogCopy(checking: "正在检查最新版本", downloading: "正在下载最新版本", upToDate: "已经是最新版本", updateComplete: "更新成功", updateFailed: "更新失败", uninstallTitle: "卸载 Quota Bubble？", uninstallMessage: "将关闭程序并删除后台任务和本地安装文件。", confirmUninstall: "卸载", cancel: "取消")
    case "ja": return DialogCopy(checking: "最新バージョンを確認中", downloading: "最新バージョンをダウンロード中", upToDate: "最新バージョンです", updateComplete: "更新が完了しました", updateFailed: "更新に失敗しました", uninstallTitle: "Quota Bubbleをアンインストールしますか？", uninstallMessage: "アプリ、バックグラウンドタスク、ローカルファイルを削除します。", confirmUninstall: "アンインストール", cancel: "キャンセル")
    case "ko": return DialogCopy(checking: "최신 버전 확인 중", downloading: "최신 버전 다운로드 중", upToDate: "최신 버전입니다", updateComplete: "업데이트 완료", updateFailed: "업데이트 실패", uninstallTitle: "Quota Bubble을 제거할까요?", uninstallMessage: "앱, 백그라운드 작업 및 로컬 파일을 제거합니다.", confirmUninstall: "제거", cancel: "취소")
    case "de": return DialogCopy(checking: "Neueste Version wird geprüft", downloading: "Neueste Version wird geladen", upToDate: "Bereits aktuell", updateComplete: "Update abgeschlossen", updateFailed: "Update fehlgeschlagen", uninstallTitle: "Quota Bubble deinstallieren?", uninstallMessage: "App, Hintergrundaufgabe und lokale Dateien werden entfernt.", confirmUninstall: "Deinstallieren", cancel: "Abbrechen")
    case "fr": return DialogCopy(checking: "Recherche de la dernière version", downloading: "Téléchargement de la dernière version", upToDate: "Déjà à jour", updateComplete: "Mise à jour terminée", updateFailed: "Échec de la mise à jour", uninstallTitle: "Désinstaller Quota Bubble ?", uninstallMessage: "L’app, la tâche en arrière-plan et les fichiers locaux seront supprimés.", confirmUninstall: "Désinstaller", cancel: "Annuler")
    case "es": return DialogCopy(checking: "Buscando la última versión", downloading: "Descargando la última versión", upToDate: "Ya está actualizado", updateComplete: "Actualización completada", updateFailed: "Error al actualizar", uninstallTitle: "¿Desinstalar Quota Bubble?", uninstallMessage: "Se eliminarán la app, la tarea en segundo plano y los archivos locales.", confirmUninstall: "Desinstalar", cancel: "Cancelar")
    case "pt": return DialogCopy(checking: "Verificando a versão mais recente", downloading: "Baixando a versão mais recente", upToDate: "Já está atualizado", updateComplete: "Atualização concluída", updateFailed: "Falha na atualização", uninstallTitle: "Desinstalar Quota Bubble?", uninstallMessage: "O app, a tarefa em segundo plano e os arquivos locais serão removidos.", confirmUninstall: "Desinstalar", cancel: "Cancelar")
    case "it": return DialogCopy(checking: "Controllo della versione più recente", downloading: "Download della versione più recente", upToDate: "Già aggiornato", updateComplete: "Aggiornamento completato", updateFailed: "Aggiornamento non riuscito", uninstallTitle: "Disinstallare Quota Bubble?", uninstallMessage: "L’app, l’attività in background e i file locali saranno rimossi.", confirmUninstall: "Disinstalla", cancel: "Annulla")
    case "nl": return DialogCopy(checking: "Nieuwste versie controleren", downloading: "Nieuwste versie downloaden", upToDate: "Al bijgewerkt", updateComplete: "Bijwerken voltooid", updateFailed: "Bijwerken mislukt", uninstallTitle: "Quota Bubble verwijderen?", uninstallMessage: "De app, achtergrondtaak en lokale bestanden worden verwijderd.", confirmUninstall: "Verwijderen", cancel: "Annuleren")
    default: return DialogCopy(checking: "Checking the latest version", downloading: "Downloading the latest version", upToDate: "Already up to date", updateComplete: "Update complete", updateFailed: "Update failed", uninstallTitle: "Uninstall Quota Bubble?", uninstallMessage: "This removes the app, background task, and local install files.", confirmUninstall: "Uninstall", cancel: "Cancel")
    }
}

let supportedLanguages: [(code: String, name: String)] = [
    ("en", "English"), ("zh", "中文"), ("ja", "日本語"), ("ko", "한국어"),
    ("de", "Deutsch"), ("fr", "Français"), ("es", "Español"),
    ("pt", "Português"), ("it", "Italiano"), ("nl", "Nederlands"),
]

func languagePreferencePath() -> String {
    NSString(string: "~/.codex/usage-widget/language.txt").expandingTildeInPath
}

func readLanguageOverride() -> String? {
    guard let raw = try? String(contentsOfFile: languagePreferencePath(), encoding: .utf8) else { return nil }
    let value = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    return supportedLanguages.contains(where: { $0.code == value }) ? value : nil
}

func writeLanguageOverride(_ code: String?) {
    let path = languagePreferencePath()
    try? FileManager.default.createDirectory(
        at: URL(fileURLWithPath: path).deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    if let code {
        try? (code + "\n").write(toFile: path, atomically: true, encoding: .utf8)
    } else {
        try? FileManager.default.removeItem(atPath: path)
    }
}

func systemLanguageCode() -> String {
    let value = Locale.preferredLanguages.first?.lowercased() ?? "en"
    return supportedLanguages.first(where: { value.hasPrefix($0.code) })?.code ?? "en"
}

func effectiveLanguageCode() -> String { readLanguageOverride() ?? systemLanguageCode() }

func localizedCopy(_ code: String = effectiveLanguageCode()) -> AppCopy {
    switch code {
    case "zh": return AppCopy(title: "Codex 额度", week: "周", reset: "重置", availableReset: "可用重置", balance: "余额", times: "次", alreadyReset: "已重置", language: "语言", website: "官网", followSystem: "跟随系统", update: "版本更新", uninstall: "卸载", switchToDark: "切换到黑色模式", switchToLight: "切换到白色模式", pin: "置顶", unpin: "取消置顶", close: "关闭窗口")
    case "ja": return AppCopy(title: "Codex 使用量", week: "週", reset: "リセット", availableReset: "利用可能なリセット", balance: "残高", times: "回", alreadyReset: "リセット済み", language: "言語", website: "公式サイト", followSystem: "システムに従う", update: "アップデート", uninstall: "アンインストール", switchToDark: "ダークモード", switchToLight: "ライトモード", pin: "最前面に固定", unpin: "固定解除", close: "閉じる")
    case "ko": return AppCopy(title: "Codex 사용량", week: "주", reset: "재설정", availableReset: "사용 가능 재설정", balance: "잔액", times: "회", alreadyReset: "재설정됨", language: "언어", website: "공식 웹사이트", followSystem: "시스템 따르기", update: "업데이트", uninstall: "제거", switchToDark: "다크 모드", switchToLight: "라이트 모드", pin: "항상 위", unpin: "고정 해제", close: "닫기")
    case "de": return AppCopy(title: "Codex Limit", week: "Woche", reset: "Reset", availableReset: "Verfügbare Resets", balance: "Guthaben", times: "Mal", alreadyReset: "Zurückgesetzt", language: "Sprache", website: "Website", followSystem: "System folgen", update: "Update", uninstall: "Deinstallieren", switchToDark: "Dunkelmodus", switchToLight: "Hellmodus", pin: "Anheften", unpin: "Lösen", close: "Schließen")
    case "fr": return AppCopy(title: "Quota Codex", week: "Semaine", reset: "Réinit.", availableReset: "Réinitialisations dispo.", balance: "Solde", times: "fois", alreadyReset: "Réinitialisé", language: "Langue", website: "Site officiel", followSystem: "Suivre le système", update: "Mettre à jour", uninstall: "Désinstaller", switchToDark: "Mode sombre", switchToLight: "Mode clair", pin: "Épingler", unpin: "Détacher", close: "Fermer")
    case "es": return AppCopy(title: "Cuota Codex", week: "Semana", reset: "Reinicio", availableReset: "Reinicios disponibles", balance: "Saldo", times: "veces", alreadyReset: "Reiniciado", language: "Idioma", website: "Sitio oficial", followSystem: "Seguir sistema", update: "Actualizar", uninstall: "Desinstalar", switchToDark: "Modo oscuro", switchToLight: "Modo claro", pin: "Fijar", unpin: "Desfijar", close: "Cerrar")
    case "pt": return AppCopy(title: "Cota Codex", week: "Semana", reset: "Redefinir", availableReset: "Redefinições disponíveis", balance: "Saldo", times: "vezes", alreadyReset: "Redefinido", language: "Idioma", website: "Site oficial", followSystem: "Seguir sistema", update: "Atualizar", uninstall: "Desinstalar", switchToDark: "Modo escuro", switchToLight: "Modo claro", pin: "Fixar", unpin: "Desafixar", close: "Fechar")
    case "it": return AppCopy(title: "Quota Codex", week: "Settimana", reset: "Ripristino", availableReset: "Ripristini disponibili", balance: "Saldo", times: "volte", alreadyReset: "Ripristinato", language: "Lingua", website: "Sito ufficiale", followSystem: "Segui sistema", update: "Aggiorna", uninstall: "Disinstalla", switchToDark: "Modalità scura", switchToLight: "Modalità chiara", pin: "Fissa", unpin: "Rimuovi fissaggio", close: "Chiudi")
    case "nl": return AppCopy(title: "Codex-limiet", week: "Week", reset: "Reset", availableReset: "Beschikbare resets", balance: "Saldo", times: "keer", alreadyReset: "Gereset", language: "Taal", website: "Officiële website", followSystem: "Systeem volgen", update: "Bijwerken", uninstall: "Verwijderen", switchToDark: "Donkere modus", switchToLight: "Lichte modus", pin: "Vastzetten", unpin: "Losmaken", close: "Sluiten")
    default: return AppCopy(title: "Codex Quota", week: "Week", reset: "Reset", availableReset: "Available resets", balance: "Balance", times: "times", alreadyReset: "Reset", language: "Language", website: "Official Website", followSystem: "Follow System", update: "Check for Updates", uninstall: "Uninstall", switchToDark: "Switch to dark mode", switchToLight: "Switch to light mode", pin: "Pin", unpin: "Unpin", close: "Close")
    }
}

func normalizedPlanType(_ rawValue: String?) -> String? {
    guard let raw = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), !raw.isEmpty else { return nil }
    let value = raw.replacingOccurrences(of: #"[\s_-]+"#, with: "", options: .regularExpression)
    if value.contains("20x") || value.contains("pro20") { return "pro20x" }
    if value.contains("5x") || value.contains("pro5") { return "pro5x" }
    if value == "pro" { return "pro20x" }
    return ["free", "plus"].contains(value) ? value : nil
}

func planBadgeText(_ raw: String?) -> String {
    switch normalizedPlanType(raw) {
    case "free": return "Free"
    case "plus": return "Plus"
    case "pro5x": return "Pro5x"
    case "pro20x": return "Pro20x"
    default: return ""
    }
}

func remainingPercent(fromUsedPercent value: Int?) -> Int? {
    guard let value else { return nil }
    return min(100, max(0, 100 - value))
}

func secondsUntil(_ timestamp: TimeInterval?) -> Int? {
    guard let timestamp, timestamp > 0 else { return nil }
    let date = timestamp > 1_000_000_000_000 ? Date(timeIntervalSince1970: timestamp / 1000) : Date(timeIntervalSince1970: timestamp)
    return Int(ceil(date.timeIntervalSinceNow))
}

func compactDuration(until timestamp: TimeInterval?, copy: AppCopy) -> String {
    guard let interval = secondsUntil(timestamp) else { return "—" }
    guard interval > 0 else { return copy.alreadyReset }
    let value = max(1, interval)
    let day = value / 86_400
    let hour = value % 86_400 / 3_600
    let minute = value % 3_600 / 60
    let second = value % 60
    var parts: [String] = []
    if day > 0 { parts.append("\(day)d") }
    if hour > 0 { parts.append("\(hour)h") }
    if minute > 0 { parts.append("\(minute)m") }
    if second > 0 || parts.isEmpty { parts.append("\(second)s") }
    return parts.joined(separator: " ")
}

func formattedBalance(_ rawValue: String?) -> String {
    guard let raw = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else { return "—" }
    if let value = Double(raw) { return String(format: "%.2f", value) }
    return raw.hasPrefix("$") ? String(raw.dropFirst()) : raw
}

func normalizedVersion(_ value: String?) -> [Int]? {
    guard let value else { return nil }
    let raw = value.trimmingCharacters(in: .whitespacesAndNewlines)
    let version = raw.hasPrefix("v") ? String(raw.dropFirst()) : raw
    let numbers = version.split(separator: ".").compactMap { part -> Int? in
        let digits = part.prefix(while: { $0.isNumber })
        return digits.isEmpty ? nil : Int(digits)
    }
    return numbers.isEmpty ? nil : numbers
}

func compareVersions(_ lhs: [Int], _ rhs: [Int]) -> ComparisonResult {
    for index in 0..<max(lhs.count, rhs.count) {
        let left = index < lhs.count ? lhs[index] : 0
        let right = index < rhs.count ? rhs[index] : 0
        if left < right { return .orderedAscending }
        if left > right { return .orderedDescending }
    }
    return .orderedSame
}

func macOSInstallerDownloadURL(for tagValue: String) -> String? {
    let tag = tagValue.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !tag.isEmpty,
          tag.range(of: #"^v?[0-9]+(?:\.[0-9]+)*$"#, options: .regularExpression) != nil,
          let version = normalizedVersion(tag) else { return nil }
    let versionText = version.map(String.init).joined(separator: ".")
    let normalizedTag = tag.hasPrefix("v") ? tag : "v\(versionText)"
    return "https://github.com/itzhaolei/codex-usage-widget/releases/download/\(normalizedTag)/QuotaBubble-\(versionText)-macOS-Installer.zip"
}

func shellQuote(_ value: String) -> String {
    "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
}

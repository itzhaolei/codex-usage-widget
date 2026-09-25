import 'dart:async';

import 'package:flutter/material.dart';

import '../services/update_service.dart';
import 'widgets/quota_symbol.dart';

Future<void> showQuotaUpdateDialog(
  BuildContext context, {
  required UpdateService service,
  required String language,
  required Future<void> Function() onExit,
}) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) =>
      QuotaUpdateDialog(service: service, language: language, onExit: onExit),
);

class QuotaUpdateDialog extends StatefulWidget {
  const QuotaUpdateDialog({
    super.key,
    required this.service,
    required this.language,
    required this.onExit,
  });
  final UpdateService service;
  final String language;
  final Future<void> Function() onExit;

  @override
  State<QuotaUpdateDialog> createState() => _QuotaUpdateDialogState();
}

class _QuotaUpdateDialogState extends State<QuotaUpdateDialog> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.service.check(force: true));
  }

  @override
  Widget build(BuildContext context) {
    final copy = UpdateDialogCopy.forLanguage(widget.language);
    return AnimatedBuilder(
      animation: widget.service,
      builder: (context, _) {
        final service = widget.service;
        final title = switch (service.state) {
          UpdateState.idle || UpdateState.checking => copy.checking,
          UpdateState.current => copy.upToDate,
          UpdateState.available => copy.available,
          UpdateState.downloading => copy.downloading,
          UpdateState.installing => copy.installing,
          UpdateState.restarting => copy.restarting,
          UpdateState.failed => copy.failed,
        };
        final installing = {
          UpdateState.downloading,
          UpdateState.installing,
          UpdateState.restarting,
        }.contains(service.state);
        return PopScope(
          canPop: !installing,
          child: AlertDialog(
            icon: QuotaSymbol(
              name: service.state == UpdateState.failed
                  ? 'xmark.octagon.fill'
                  : 'info.circle.fill',
              size: 32,
              color: service.state == UpdateState.failed
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
            ),
            scrollable: true,
            insetPadding: const EdgeInsets.all(14),
            titleTextStyle: Theme.of(context).textTheme.titleMedium,
            title: Text(title),
            content: SizedBox(
              width: 272,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.state == UpdateState.failed
                        ? (service.error ?? copy.failed)
                        : service.latest?.tag ?? 'v${service.currentVersion}',
                  ),
                  if (service.busy) ...[
                    const SizedBox(height: 14),
                    LinearProgressIndicator(
                      value: service.state == UpdateState.downloading
                          ? service.progress
                          : null,
                    ),
                    if (service.state == UpdateState.downloading &&
                        service.progress != null) ...[
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text('${(service.progress! * 100).floor()}%'),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            actions: [
              if (!installing)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(copy.close),
                ),
              if (service.state == UpdateState.available)
                FilledButton(
                  onPressed: () =>
                      service.downloadAndInstall(onExit: widget.onExit),
                  child: Text(copy.install),
                ),
              if (service.state == UpdateState.failed)
                FilledButton(
                  onPressed: () => service.check(force: true),
                  child: Text(copy.retry),
                ),
            ],
          ),
        );
      },
    );
  }
}

Future<void> showQuotaUninstallDialog(
  BuildContext context, {
  required UpdateService service,
  required String language,
  required Future<void> Function() onExit,
}) async {
  final copy = UpdateDialogCopy.forLanguage(language);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const QuotaSymbol(
        name: 'exclamationmark.triangle.fill',
        size: 32,
        color: Color(0xffffa000),
      ),
      scrollable: true,
      insetPadding: const EdgeInsets.all(14),
      title: Text(copy.uninstallTitle),
      content: Text(copy.uninstallMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(copy.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(copy.uninstall),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  try {
    await service.uninstall(onExit: onExit);
  } on Object catch (error) {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: QuotaSymbol(
          name: 'xmark.octagon.fill',
          size: 32,
          color: Theme.of(context).colorScheme.error,
        ),
        title: Text(copy.uninstallFailed),
        content: Text(
          error is UpdateException ? error.message : copy.uninstallFailed,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(copy.close),
          ),
        ],
      ),
    );
  }
}

Future<void> showQuotaShareDialog(
  BuildContext context, {
  required UpdateService service,
  required String language,
}) async {
  await service.shareWebsite();
  if (!context.mounted) return;
  final copy = UpdateDialogCopy.forLanguage(language);
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: QuotaSymbol(
        name: 'info.circle.fill',
        size: 32,
        color: Theme.of(context).colorScheme.primary,
      ),
      scrollable: true,
      insetPadding: const EdgeInsets.all(14),
      title: Text(copy.copied),
      content: const SelectableText(quotaWebsite),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(copy.close),
        ),
      ],
    ),
  );
}

class UpdateDialogCopy {
  const UpdateDialogCopy(this._text);
  final List<String> _text;
  String get checking => _text[0];
  String get downloading => _text[1];
  String get upToDate => _text[2];
  String get available => _text[3];
  String get installing => _text[4];
  String get restarting => _text[5];
  String get failed => _text[6];
  String get uninstallFailed => _text[15];
  String get install => _text[7];
  String get retry => _text[8];
  String get close => _text[9];
  String get uninstallTitle => _text[10];
  String get uninstallMessage => _text[11];
  String get uninstall => _text[12];
  String get cancel => _text[13];
  String get copied => _text[14];

  static UpdateDialogCopy forLanguage(String language) =>
      UpdateDialogCopy(_translations[language] ?? _translations['en']!);

  static const _translations = <String, List<String>>{
    'en': [
      'Checking the latest version',
      'Downloading the latest version',
      'Already up to date',
      'Update available',
      'Installing update',
      'Restarting Quota Bubble',
      'Update failed',
      'Update and restart',
      'Retry',
      'Close',
      'Uninstall Quota Bubble?',
      'This closes Quota Bubble and removes the app, startup entry, and local install files.',
      'Uninstall',
      'Cancel',
      'Website link copied',
      'Uninstall failed',
    ],
    'zh': [
      '正在检查最新版本',
      '正在下载最新版本',
      '已经是最新版本',
      '发现新版本',
      '正在安装更新',
      '正在重启 Quota Bubble',
      '更新失败',
      '更新并重启',
      '重试',
      '关闭',
      '卸载 Quota Bubble？',
      '将关闭 Quota Bubble，并删除应用、登录启动项和本地安装文件。',
      '卸载',
      '取消',
      '官网链接已复制',
      '卸载失败',
    ],
    'ja': [
      '最新バージョンを確認中',
      '最新バージョンをダウンロード中',
      '最新バージョンです',
      '更新が利用可能です',
      'アップデートをインストール中',
      'Quota Bubbleを再起動中',
      '更新に失敗しました',
      '更新して再起動',
      '再試行',
      '閉じる',
      'Quota Bubbleをアンインストールしますか？',
      'Quota Bubbleを終了し、アプリ、ログイン時の起動設定、ローカルインストールファイルを削除します。',
      'アンインストール',
      'キャンセル',
      'サイトのリンクをコピーしました',
      'アンインストールに失敗しました',
    ],
    'ko': [
      '최신 버전 확인 중',
      '최신 버전 다운로드 중',
      '최신 버전입니다',
      '새 버전이 있습니다',
      '업데이트 설치 중',
      'Quota Bubble 다시 시작 중',
      '업데이트 실패',
      '업데이트 및 다시 시작',
      '다시 시도',
      '닫기',
      'Quota Bubble을 제거할까요?',
      'Quota Bubble을 종료하고 앱, 로그인 시작 항목 및 로컬 설치 파일을 제거합니다.',
      '제거',
      '취소',
      '웹사이트 링크를 복사했습니다',
      '제거 실패',
    ],
    'de': [
      'Neueste Version wird geprüft',
      'Neueste Version wird geladen',
      'Bereits aktuell',
      'Update verfügbar',
      'Update wird installiert',
      'Quota Bubble wird neu gestartet',
      'Update fehlgeschlagen',
      'Aktualisieren und neu starten',
      'Erneut versuchen',
      'Schließen',
      'Quota Bubble deinstallieren?',
      'Quota Bubble wird beendet; App, Autostart-Eintrag und lokale Installationsdateien werden entfernt.',
      'Deinstallieren',
      'Abbrechen',
      'Website-Link kopiert',
      'Deinstallation fehlgeschlagen',
    ],
    'fr': [
      'Recherche de la dernière version',
      'Téléchargement de la dernière version',
      'Déjà à jour',
      'Mise à jour disponible',
      'Installation de la mise à jour',
      'Redémarrage de Quota Bubble',
      'Échec de la mise à jour',
      'Mettre à jour et redémarrer',
      'Réessayer',
      'Fermer',
      'Désinstaller Quota Bubble ?',
      'Quota Bubble sera fermé, puis l’app, le lancement à la connexion et les fichiers locaux seront supprimés.',
      'Désinstaller',
      'Annuler',
      'Lien du site copié',
      'Échec de la désinstallation',
    ],
    'es': [
      'Buscando la última versión',
      'Descargando la última versión',
      'Ya está actualizado',
      'Actualización disponible',
      'Instalando actualización',
      'Reiniciando Quota Bubble',
      'Error al actualizar',
      'Actualizar y reiniciar',
      'Reintentar',
      'Cerrar',
      '¿Desinstalar Quota Bubble?',
      'Se cerrará Quota Bubble y se eliminarán la app, el inicio de sesión y los archivos locales de instalación.',
      'Desinstalar',
      'Cancelar',
      'Enlace del sitio copiado',
      'Error al desinstalar',
    ],
    'pt': [
      'Verificando a versão mais recente',
      'Baixando a versão mais recente',
      'Já está atualizado',
      'Atualização disponível',
      'Instalando atualização',
      'Reiniciando Quota Bubble',
      'Falha na atualização',
      'Atualizar e reiniciar',
      'Tentar novamente',
      'Fechar',
      'Desinstalar Quota Bubble?',
      'O Quota Bubble será fechado, e o app, a inicialização no login e os arquivos locais serão removidos.',
      'Desinstalar',
      'Cancelar',
      'Link do site copiado',
      'Falha ao desinstalar',
    ],
    'it': [
      'Controllo della versione più recente',
      'Download della versione più recente',
      'Già aggiornato',
      'Aggiornamento disponibile',
      'Installazione aggiornamento',
      'Riavvio di Quota Bubble',
      'Aggiornamento non riuscito',
      'Aggiorna e riavvia',
      'Riprova',
      'Chiudi',
      'Disinstallare Quota Bubble?',
      'Quota Bubble verrà chiuso; l’app, l’avvio all’accesso e i file locali saranno rimossi.',
      'Disinstalla',
      'Annulla',
      'Link del sito copiato',
      'Disinstallazione non riuscita',
    ],
    'nl': [
      'Nieuwste versie controleren',
      'Nieuwste versie downloaden',
      'Al bijgewerkt',
      'Update beschikbaar',
      'Update installeren',
      'Quota Bubble opnieuw starten',
      'Bijwerken mislukt',
      'Bijwerken en herstarten',
      'Opnieuw proberen',
      'Sluiten',
      'Quota Bubble verwijderen?',
      'Quota Bubble wordt afgesloten; de app, het opstartitem en lokale installatiebestanden worden verwijderd.',
      'Verwijderen',
      'Annuleren',
      'Websitelink gekopieerd',
      'Verwijderen mislukt',
    ],
  };
}

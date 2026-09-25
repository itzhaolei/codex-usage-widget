import '../core/models.dart';

class AppCopy {
  const AppCopy({
    required this.title,
    required this.week,
    required this.fiveHour,
    required this.reset,
    required this.availableReset,
    required this.balance,
    required this.times,
    required this.alreadyReset,
    required this.language,
    required this.website,
    required this.followSystem,
    required this.update,
    required this.uninstall,
    required this.switchToDark,
    required this.switchToLight,
    required this.pin,
    required this.unpin,
    required this.close,
    required this.show,
    required this.exit,
    required this.availableMemory,
    required this.availableStorage,
  });

  final String title;
  final String week;
  final String fiveHour;
  final String reset;
  final String availableReset;
  final String balance;
  final String times;
  final String alreadyReset;
  final String language;
  final String website;
  final String followSystem;
  final String update;
  final String uninstall;
  final String switchToDark;
  final String switchToLight;
  final String pin;
  final String unpin;
  final String close;
  final String show;
  final String exit;
  final String availableMemory;
  final String availableStorage;
}

const _en = AppCopy(
  title: 'Codex Quota',
  week: 'Week',
  fiveHour: '5h',
  reset: 'Reset',
  availableReset: 'Available reset credits',
  balance: 'Balance',
  times: 'times',
  alreadyReset: 'Reset',
  language: 'Language',
  website: 'Official Website',
  followSystem: 'Follow System',
  update: 'Check for Updates',
  uninstall: 'Uninstall',
  switchToDark: 'Switch to dark mode',
  switchToLight: 'Switch to light mode',
  pin: 'Pin',
  unpin: 'Unpin',
  close: 'Hide window',
  show: 'Show',
  exit: 'Exit',
  availableMemory: 'Available memory',
  availableStorage: 'Available storage',
);

const _zh = AppCopy(
  title: 'Codex 配额',
  week: '周',
  fiveHour: '5h',
  reset: '重置',
  availableReset: '可用重置额度',
  balance: '余额',
  times: '次',
  alreadyReset: '已重置',
  language: '语言',
  website: '官网',
  followSystem: '跟随系统',
  update: '版本更新',
  uninstall: '卸载',
  switchToDark: '切换到深色模式',
  switchToLight: '切换到浅色模式',
  pin: '置顶',
  unpin: '取消置顶',
  close: '隐藏窗口',
  show: '显示窗口',
  exit: '退出',
  availableMemory: '可用内存',
  availableStorage: '可用存储空间',
);

const _ja = AppCopy(
  title: 'Codex 使用量',
  week: '週',
  fiveHour: '5h',
  reset: 'リセット',
  availableReset: '利用可能なリセットクレジット',
  balance: '残高',
  times: '回',
  alreadyReset: 'リセット済み',
  language: '言語',
  website: '公式サイト',
  followSystem: 'システムに従う',
  update: 'アップデート',
  uninstall: 'アンインストール',
  switchToDark: 'ダークモード',
  switchToLight: 'ライトモード',
  pin: '最前面に固定',
  unpin: '固定解除',
  close: 'ウインドウを隠す',
  show: '表示',
  exit: '終了',
  availableMemory: '利用可能メモリ',
  availableStorage: '利用可能なストレージ',
);

const _ko = AppCopy(
  title: 'Codex 사용량',
  week: '주',
  fiveHour: '5h',
  reset: '재설정',
  availableReset: '사용 가능한 재설정 크레딧',
  balance: '잔액',
  times: '회',
  alreadyReset: '재설정됨',
  language: '언어',
  website: '공식 웹사이트',
  followSystem: '시스템 따르기',
  update: '업데이트',
  uninstall: '제거',
  switchToDark: '다크 모드',
  switchToLight: '라이트 모드',
  pin: '항상 위',
  unpin: '고정 해제',
  close: '창 숨기기',
  show: '표시',
  exit: '종료',
  availableMemory: '사용 가능 메모리',
  availableStorage: '사용 가능 저장 공간',
);

const _de = AppCopy(
  title: 'Codex Limit',
  week: 'Woche',
  fiveHour: '5h',
  reset: 'Reset',
  availableReset: 'Verfügbare Reset-Guthaben',
  balance: 'Guthaben',
  times: 'Mal',
  alreadyReset: 'Zurückgesetzt',
  language: 'Sprache',
  website: 'Website',
  followSystem: 'System folgen',
  update: 'Update',
  uninstall: 'Deinstallieren',
  switchToDark: 'Dunkelmodus',
  switchToLight: 'Hellmodus',
  pin: 'Anheften',
  unpin: 'Lösen',
  close: 'Fenster ausblenden',
  show: 'Anzeigen',
  exit: 'Beenden',
  availableMemory: 'Verfügbarer Speicher',
  availableStorage: 'Verfügbarer Speicherplatz',
);

const _fr = AppCopy(
  title: 'Quota Codex',
  week: 'Semaine',
  fiveHour: '5h',
  reset: 'Réinit.',
  availableReset: 'Crédits de réinitialisation',
  balance: 'Solde',
  times: 'fois',
  alreadyReset: 'Réinitialisé',
  language: 'Langue',
  website: 'Site officiel',
  followSystem: 'Suivre le système',
  update: 'Mettre à jour',
  uninstall: 'Désinstaller',
  switchToDark: 'Mode sombre',
  switchToLight: 'Mode clair',
  pin: 'Épingler',
  unpin: 'Détacher',
  close: 'Masquer la fenêtre',
  show: 'Afficher',
  exit: 'Quitter',
  availableMemory: 'Mémoire disponible',
  availableStorage: 'Stockage disponible',
);

const _es = AppCopy(
  title: 'Cuota Codex',
  week: 'Semana',
  fiveHour: '5h',
  reset: 'Reinicio',
  availableReset: 'Créditos de reinicio',
  balance: 'Saldo',
  times: 'veces',
  alreadyReset: 'Reiniciado',
  language: 'Idioma',
  website: 'Sitio oficial',
  followSystem: 'Seguir sistema',
  update: 'Actualizar',
  uninstall: 'Desinstalar',
  switchToDark: 'Modo oscuro',
  switchToLight: 'Modo claro',
  pin: 'Fijar',
  unpin: 'Desfijar',
  close: 'Ocultar ventana',
  show: 'Mostrar',
  exit: 'Salir',
  availableMemory: 'Memoria disponible',
  availableStorage: 'Almacenamiento disponible',
);

const _pt = AppCopy(
  title: 'Cota Codex',
  week: 'Semana',
  fiveHour: '5h',
  reset: 'Redefinição',
  availableReset: 'Créditos de redefinição',
  balance: 'Saldo',
  times: 'vezes',
  alreadyReset: 'Redefinido',
  language: 'Idioma',
  website: 'Site oficial',
  followSystem: 'Seguir sistema',
  update: 'Atualizar',
  uninstall: 'Desinstalar',
  switchToDark: 'Modo escuro',
  switchToLight: 'Modo claro',
  pin: 'Fixar',
  unpin: 'Desafixar',
  close: 'Ocultar janela',
  show: 'Mostrar',
  exit: 'Sair',
  availableMemory: 'Memória disponível',
  availableStorage: 'Armazenamento disponível',
);

const _it = AppCopy(
  title: 'Quota Codex',
  week: 'Settimana',
  fiveHour: '5h',
  reset: 'Ripristino',
  availableReset: 'Crediti di ripristino',
  balance: 'Saldo',
  times: 'volte',
  alreadyReset: 'Ripristinato',
  language: 'Lingua',
  website: 'Sito ufficiale',
  followSystem: 'Segui sistema',
  update: 'Aggiorna',
  uninstall: 'Disinstalla',
  switchToDark: 'Modalità scura',
  switchToLight: 'Modalità chiara',
  pin: 'Fissa',
  unpin: 'Rimuovi fissaggio',
  close: 'Nascondi finestra',
  show: 'Mostra',
  exit: 'Esci',
  availableMemory: 'Memoria disponibile',
  availableStorage: 'Spazio disponibile',
);

const _nl = AppCopy(
  title: 'Codex-limiet',
  week: 'Week',
  fiveHour: '5h',
  reset: 'Reset',
  availableReset: 'Beschikbare resetcredits',
  balance: 'Saldo',
  times: 'keer',
  alreadyReset: 'Gereset',
  language: 'Taal',
  website: 'Officiële website',
  followSystem: 'Systeem volgen',
  update: 'Bijwerken',
  uninstall: 'Verwijderen',
  switchToDark: 'Donkere modus',
  switchToLight: 'Lichte modus',
  pin: 'Vastzetten',
  unpin: 'Losmaken',
  close: 'Venster verbergen',
  show: 'Tonen',
  exit: 'Afsluiten',
  availableMemory: 'Beschikbaar geheugen',
  availableStorage: 'Beschikbare opslag',
);

AppCopy localizedCopy(String language) => switch (effectiveLanguage(language)) {
  'zh' => _zh,
  'ja' => _ja,
  'ko' => _ko,
  'de' => _de,
  'fr' => _fr,
  'es' => _es,
  'pt' => _pt,
  'it' => _it,
  'nl' => _nl,
  _ => _en,
};

String pointsUnit(String language) => switch (effectiveLanguage(language)) {
  'zh' => '点数',
  'ja' => 'ポイント',
  'ko' => '포인트',
  'de' => 'Punkte',
  'es' => 'puntos',
  'pt' => 'pontos',
  'it' => 'punti',
  'nl' => 'punten',
  _ => 'points',
};

String localizedLanguageName(String code) =>
    const {
      'en': 'English',
      'zh': '中文',
      'ja': '日本語',
      'ko': '한국어',
      'de': 'Deutsch',
      'fr': 'Français',
      'es': 'Español',
      'pt': 'Português',
      'it': 'Italiano',
      'nl': 'Nederlands',
    }[code] ??
    code;

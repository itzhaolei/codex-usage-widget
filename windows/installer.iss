#ifndef MyAppVersion
  #define MyAppVersion "0.0.0"
#endif
#ifndef PublishDir
  #define PublishDir ".\publish"
#endif

[Setup]
AppId={{45E554B4-7DD5-4D8C-B425-55D8C6DAEAF8}
AppName=Quota Bubble
AppVersion={#MyAppVersion}
AppPublisher=itzhaolei
AppPublisherURL=https://github.com/itzhaolei/codex-usage-widget
AppSupportURL=https://github.com/itzhaolei/codex-usage-widget/issues
AppUpdatesURL=https://github.com/itzhaolei/codex-usage-widget/releases/latest
DefaultDirName={localappdata}\Programs\Quota Bubble
DefaultGroupName=Quota Bubble
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
OutputDir=..\dist
OutputBaseFilename=QuotaBubble-{#MyAppVersion}-Windows-Setup
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
SetupIconFile=QuotaBubble.ico
UninstallDisplayIcon={app}\QuotaBubble.exe
CloseApplications=yes
RestartApplications=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "chinesesimplified"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"
Name: "japanese"; MessagesFile: "compiler:Languages\Japanese.isl"
Name: "korean"; MessagesFile: "compiler:Languages\Korean.isl"
Name: "german"; MessagesFile: "compiler:Languages\German.isl"
Name: "french"; MessagesFile: "compiler:Languages\French.isl"
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"
Name: "portuguese"; MessagesFile: "compiler:Languages\Portuguese.isl"
Name: "italian"; MessagesFile: "compiler:Languages\Italian.isl"
Name: "dutch"; MessagesFile: "compiler:Languages\Dutch.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "startup"; Description: "Start Quota Bubble when I sign in"; GroupDescription: "Startup"; Flags: checkedonce

[Files]
Source: "{#PublishDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Quota Bubble"; Filename: "{app}\QuotaBubble.exe"
Name: "{group}\Uninstall Quota Bubble"; Filename: "{uninstallexe}"
Name: "{autodesktop}\Quota Bubble"; Filename: "{app}\QuotaBubble.exe"; Tasks: desktopicon
Name: "{userstartup}\Quota Bubble"; Filename: "{app}\QuotaBubble.exe"; WorkingDir: "{app}"; Tasks: startup

[Run]
Filename: "{app}\QuotaBubble.exe"; Description: "{cm:LaunchProgram,Quota Bubble}"; Flags: nowait postinstall skipifsilent

[UninstallRun]
Filename: "{cmd}"; Parameters: "/C taskkill /IM QuotaBubble.exe /F"; Flags: runhidden; RunOnceId: "StopQuotaBubble"

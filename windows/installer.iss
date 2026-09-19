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
UsePreviousAppDir=yes
UsePreviousGroup=yes
UsePreviousTasks=yes
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

[Tasks]
Name: "startup"; Description: "Start Quota Bubble when I sign in"; GroupDescription: "Startup"; Flags: checkedonce

[Files]
Source: "{#PublishDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[InstallDelete]
Type: files; Name: "{userprofile}\.codex\usage-widget\QuotaBubble.ps1"
Type: files; Name: "{userprofile}\.codex\usage-widget\VERSION"
Type: files; Name: "{userprofile}\.codex\usage-widget\windows-state.json"
Type: files; Name: "{userprofile}\.codex\scripts\codex-usage-snapshot.mjs"

[Icons]
Name: "{group}\Quota Bubble"; Filename: "{app}\QuotaBubble.exe"
Name: "{group}\Uninstall Quota Bubble"; Filename: "{uninstallexe}"
Name: "{autodesktop}\Quota Bubble"; Filename: "{app}\QuotaBubble.exe"
Name: "{userstartup}\Quota Bubble"; Filename: "{app}\QuotaBubble.exe"; WorkingDir: "{app}"; Tasks: startup

[Run]
Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; Parameters: "-NoProfile -NonInteractive -EncodedCommand RwBlAHQALQBDAGkAbQBJAG4AcwB0AGEAbgBjAGUAIABXAGkAbgAzADIAXwBQAHIAbwBjAGUAcwBzACAAfAAgAFcAaABlAHIAZQAtAE8AYgBqAGUAYwB0ACAAewAgACgAJABfAC4ATgBhAG0AZQAgAC0AaQBuACAAQAAoACIAcABvAHcAZQByAHMAaABlAGwAbAAuAGUAeABlACIALAAiAHAAdwBzAGgALgBlAHgAZQAiACkAKQAgAC0AYQBuAGQAIAAkAF8ALgBQAHIAbwBjAGUAcwBzAEkAZAAgAC0AbgBlACAAJABQAEkARAAgAC0AYQBuAGQAIAAkAF8ALgBDAG8AbQBtAGEAbgBkAEwAaQBuAGUAIAAtAGwAaQBrAGUAIAAiACoAUQB1AG8AdABhAEIAdQBiAGIAbABlAC4AcABzADEAKgAiACAAfQAgAHwAIABGAG8AcgBFAGEAYwBoAC0ATwBiAGoAZQBjAHQAIAB7ACAAUwB0AG8AcAAtAFAAcgBvAGMAZQBzAHMAIAAtAEkAZAAgACQAXwAuAFAAcgBvAGMAZQBzAHMASQBkACAALQBGAG8AcgBjAGUAIAAtAEUAcgByAG8AcgBBAGMAdABpAG8AbgAgAFMAaQBsAGUAbgB0AGwAeQBDAG8AbgB0AGkAbgB1AGUAIAB9AA=="; Flags: runhidden waituntilterminated
Filename: "{app}\QuotaBubble.exe"; Description: "{cm:LaunchProgram,Quota Bubble}"; Flags: nowait postinstall skipifsilent

[UninstallRun]
Filename: "{cmd}"; Parameters: "/C taskkill /IM QuotaBubble.exe /F"; Flags: runhidden; RunOnceId: "StopQuotaBubble"

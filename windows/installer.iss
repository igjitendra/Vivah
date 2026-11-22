#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif

[Setup]
AppId={{95FF0533-E7FF-4523-A0D4-5FF87B7A80A5}
AppName=Vyavahaar
AppVersion={#AppVersion}
AppVerName=Vyavahaar {#AppVersion}
AppPublisher=Vyavahaar
AppPublisherURL=https://github.com/igjitendra/Vivah.git
AppSupportURL=https://github.com/igjitendra/Vivah/issues
AppUpdatesURL=https://github.com/igjitendra/Vivah/releases
DefaultDirName={autopf}\Vyavahaar
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir=..\build\installer
OutputBaseFilename=Vyavahaar-windows-x64-setup
SetupIconFile=runner\resources\app_icon.ico
UninstallDisplayIcon={app}\Vyavahaar.exe
UninstallDisplayName=Vyavahaar
WizardStyle=modern
Compression=lzma2
SolidCompression=yes
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"
Name: "german"; MessagesFile: "compiler:Languages\German.isl"
Name: "french"; MessagesFile: "compiler:Languages\French.isl"
Name: "dutch"; MessagesFile: "compiler:Languages\Dutch.isl"
Name: "korean"; MessagesFile: "compiler:Languages\Korean.isl"
Name: "portuguese"; MessagesFile: "compiler:Languages\Portuguese.isl"
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"
Name: "ukrainian"; MessagesFile: "compiler:Languages\Ukrainian.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Vyavahaar"; Filename: "{app}\Vyavahaar.exe"; AppUserModelID: "com.procsctools.vyavahaar"
Name: "{autodesktop}\Vyavahaar"; Filename: "{app}\Vyavahaar.exe"; Tasks: desktopicon; AppUserModelID: "com.procsctools.vyavahaar"

[Run]
Filename: "{app}\Vyavahaar.exe"; Description: "{cm:LaunchProgram,Vyavahaar}"; Flags: nowait postinstall skipifsilent

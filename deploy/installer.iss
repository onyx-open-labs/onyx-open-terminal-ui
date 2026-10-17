#ifndef PublishDir
  #error PublishDir is required
#endif
[Setup]
AppId=OnyxOpenTerminal-{#Architecture}
AppName=Onyx Open Terminal
AppVersion={#CandidateVersion}
AppPublisher=Onyx Open Labs
AppPublisherURL=https://github.com/onyx-open-labs/onyx-open-terminal-ui
AppSupportURL=https://github.com/onyx-open-labs/onyx-open-terminal-ui/issues
VersionInfoVersion={#NumericVersion}
VersionInfoCompany=Onyx Open Labs
VersionInfoDescription=Onyx Open Terminal test installer (MIT)
VersionInfoProductName=Onyx Open Terminal
VersionInfoProductVersion={#NumericVersion}
VersionInfoProductTextVersion={#CandidateVersion}
DefaultDirName={localappdata}\Programs\Onyx Open Terminal\{#Architecture}
DefaultGroupName=Onyx Open Terminal ({#Architecture})
PrivilegesRequired=lowest
LicenseFile=..\LICENSE
MinVersion=10.0.17763
#if Architecture == "x64"
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
#endif
OutputDir={#OutputDir}
OutputBaseFilename=OnyxOpenTerminal-{#CandidateVersion}-{#Architecture}-setup
Compression=lzma2
SolidCompression=yes
CloseApplications=yes
RestartApplications=no
UninstallDisplayIcon={app}\Onyx.OpenTerminal.WinUI.exe
[Files]
Source: "{#PublishDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\LICENSE"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#OutputDir}\release.json"; DestDir: "{app}"; Flags: ignoreversion
[Icons]
Name: "{group}\Onyx Open Terminal"; Filename: "{app}\Onyx.OpenTerminal.WinUI.exe"

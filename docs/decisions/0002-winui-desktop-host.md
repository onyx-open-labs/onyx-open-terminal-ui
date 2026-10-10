# 0002: WinUI desktop host

Status: Accepted for OOT-2.

## Decision

Add Onyx.OpenTerminal.WinUI under src/ as a Windows-specific .NET 10 WinUI 3
application. Remove the unused Onyx.OpenTerminal.UI library and its scaffold test project; the WinUI host is the sole solution project. OOT-2 explicitly selects the desktop UI
framework, superseding the framework-selection restriction of the initial scaffold.

Use unpackaged deployment with the Windows App SDK runtime bundled in the output.
This provides an initial window without package registration or a separate Windows
App Runtime installation. The .NET 10 desktop runtime is still required.
MSIX distribution and application features remain future decisions.

Pin Microsoft.WindowsAppSDK 2.5.1 and Microsoft.Windows.SDK.BuildTools
10.0.28000.2705. These provide WinUI, its runtime, and Windows build tools.
Build x64 by default, with x86 available through solution configurations.
Move solution validation to Windows because the WinUI XAML compiler runs on Windows.

## Validation

Restore, build, and test the solution using the repository validation commands.
Launch the unpackaged application and verify its initial Onyx Open Terminal window.

The shared Onyx.OpenTerminal.slnLaunch profile starts WinUI with debugging.
No automated test projects remain after removing the unused library scaffold.

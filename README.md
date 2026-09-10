# Discord Call Bridge

A portable Codex plugin and Windows setup wizard for routing assistant Voice into Discord and caller audio back into Voice. Version 0.1.0 is a private second-machine trial, not a universal or unattended calling product.

## Start on the second Windows machine

1. Download the release ZIP while signed into the private GitHub repository. Verify its SHA-256 against the release checksum file. Extract all files into a normal user folder. Do not run inside the ZIP.
2. Review the scripts, then double-click **Setup.cmd**. It launches the Windows Forms wizard using Windows PowerShell 5.1 and a process-only script execution setting. It does not change machine execution policy or run Codex as administrator. If organizational policy blocks scripts, use the approved administrator process; do not bypass it.
3. **Detect** is read-only. **Install** offers missing OBS/Discord apps, verified vendor cable installers, Codex account/download guidance, and plugin installation. Approve vendor/UI/UAC steps yourself. Restart only when ready, reopen Setup.cmd and Detect again. Settings persist locally.
4. **Configure** saves your recipient and device preferences plus a previous-settings restore sheet. The guide walks through dedicated OBS setup and separate send/return routes. The skill can operate available supported native UI; when unavailable, the wizard gives manual app steps. Audio is not automatically configured by editing the preferences file.
5. **Verify** checks configured endpoint names, then tracks the real two-way call stages. **Finish / Restore** writes a local user-attested acceptance report and explains restoration/uninstall.

The wizard automates supported software acquisition, narrowly scoped driver elevation and plugin registration/installation. Voice activation, account login, secure-desktop UAC, driver compatibility choices and app audio controls without a supported native automation interface remain user steps. It does not claim to fully automate every host.

## Requirements and installation details

Windows x64, Windows PowerShell 5.1, Windows 10 build 19041+ or Windows 11, OBS 28+, Discord, and a Codex/ChatGPT desktop environment with working Voice and plugin support. Use two independent virtual cable pairs and headphones. Read [routing and dependency terms](skills/discord-call/references/windows-routing.md), including the older Hi-Fi driver compatibility limitation. No vendor binaries, credentials, licenses, private logs or API keys are included. No paid API voice is substituted.

Python, Node, Git and GitHub CLI are not required to use the ZIP. WinGet is needed only for the app-install button; if missing use Microsoft's App Installer from Microsoft Store or the official OBS/Discord installers. Existing custom install paths can be entered in the local config before running InstallApps.

The plugin installer copies to `%USERPROFILE%\plugins\discord-call-bridge`, appends a personal marketplace entry preserving unrelated entries, and runs `codex plugin add discord-call-bridge@<actual marketplace name>`. It refuses to overwrite an existing destination. Registration backups are adjacent to the marketplace file. The standard personal marketplace is implicitly discovered; no marketplace-add command is needed. If CLI is unavailable, registration remains available for the Codex plugin browser. Start a **new Codex task** after installation and request `$discord-call` setup or test; verify it actually loads the plugin skill.

Current commands were checked with local Codex CLI 0.153.4 using `plugin add --help` and `plugin remove --help`. Official [plugin packaging documentation](https://developers.openai.com/plugins/build/plugins) supplies the manifest/marketplace conventions. Runtime plugin installation on the second host still needs validation.

## Command-line fallback

From the extracted folder in ordinary PowerShell:

```powershell
.\scripts\Bootstrap.ps1                         # read-only audit
.\scripts\Bootstrap.ps1 -Mode Prepare           # local templates only
.\scripts\Bootstrap.ps1 -Mode InstallApps       # missing OBS / Discord
.\scripts\InstallDriver.ps1 -Driver VBCable -WhatIf
.\scripts\InstallDriver.ps1 -Driver VBCable     # download, signature, UAC
.\scripts\InstallDriver.ps1 -Driver HiFiCable   # review compatibility first
.\scripts\InstallPlugin.ps1
```

Installer consoles remain visible for vendor prompts and errors. Do not close one mid-install or start duplicate installs. The wizard does not automatically infer an install completed from an opened console; rerun Detect. Driver cancellation, invalid signatures and installer failures leave setup partial. Driver downloads are kept only in local application data and are excluded from the release.

Preferences default to no recipient and no selected devices, stored under `%LOCALAPPDATA%\DiscordCallBridge`. Do not copy this private state into a redistributable package. A saved recipient never supplies permission for unsolicited calls or DMs.

## Validation and recovery

See [VALIDATION.md](VALIDATION.md) for first-machine evidence and [acceptance checklist](skills/discord-call/references/acceptance.md) for the required second-machine trial. Read [RESTORE.md](RESTORE.md) before changing audio. Successful packaging, device detection, local mic-test playback, connected call, remote hearing and inbound speech are separate evidence stages.

No public listing, sale, third-party binary redistribution, account permission or commercial compatibility claim is included in this private trial.

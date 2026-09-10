# Discord Call Bridge

Use a separate Discord account dedicated to ChatGPT/Codex. Do not use your personal or main Discord account for this bridge. Set up and sign in to the dedicated account before continuing.

Explicitly confirm that the dedicated account is currently signed in and in use before setup, testing, or dialing. Do not treat reading the warning, a stored recipient, old acceptance report, or prior user permissions as this confirmation. The wizard requires a fresh acknowledgement each session. If using the skill directly, obtain this explicit confirmation before proceeding; do not switch accounts or handle credentials on the user's behalf. Ending a call or restoring existing settings must remain possible without this prerequisite.

A portable Codex plugin and Windows setup wizard for routing assistant Voice into Discord and caller audio back into Voice. Version 0.1.3 is a private second-machine trial, not a universal or unattended calling product.

## Start on the second Windows machine

1. Download the release ZIP while signed into the private GitHub repository. Verify its SHA-256 against the release checksum file. Extract all files into a normal user folder. Do not run inside the ZIP.
2. Review the scripts, then double-click **Setup.cmd**. It launches the Windows Forms wizard using Windows PowerShell 5.1 and a process-only script execution setting. It does not change machine execution policy or run Codex as administrator. If organizational policy blocks scripts, use the approved administrator process; do not bypass it.
3. **Dedicated account** blocks navigation until you confirm the dedicated account is in use. **Detect** is read-only. **Install** offers missing OBS/Discord apps, verified vendor cable installers, Codex account/download guidance, and plugin installation. Approve vendor/UI/UAC steps yourself. Restart only when ready, reopen Setup.cmd and Detect again. Settings persist locally.
4. **Configure** saves your recipient and device preferences plus a previous-settings restore sheet. The guide walks through dedicated OBS setup and separate send/return routes. The skill can operate available supported native UI; when unavailable, the wizard gives manual app steps. Audio is not automatically configured by editing the preferences file.
5. **Verify** checks configured endpoint names, then tracks the real two-way call stages. **Finish / Restore** writes a local user-attested acceptance report and explains restoration/uninstall.

The wizard automates supported software acquisition, narrowly scoped driver elevation and plugin registration/installation. When Codex runs setup, it also operates available supported app controls for audio routing and Voice activation. Account login, secure-desktop UAC, unresolved driver compatibility choices and controls actually unavailable to Codex need narrow user handoffs. It does not claim to fully automate every host.

## Requirements and installation details

Windows x64, Windows PowerShell 5.1, Windows 10 build 19041+ or Windows 11, OBS 28+, Discord, and a Codex/ChatGPT desktop environment with working Voice and plugin support. Use two independent virtual cable pairs and headphones. Read [routing and dependency terms](skills/discord-call/references/windows-routing.md), including the older Hi-Fi driver compatibility limitation. No vendor binaries, credentials, licenses, private logs or API keys are included. No paid API voice is substituted.

Python, Node, Git and GitHub CLI are not required to use the ZIP. WinGet is needed only for the app-install button; if missing use Microsoft's App Installer from Microsoft Store or the official OBS/Discord installers. Existing custom install paths can be entered in the local config before running InstallApps.

The plugin installer copies to `%USERPROFILE%\plugins\discord-call-bridge`, appends a personal marketplace entry preserving unrelated entries, and runs `codex plugin add discord-call-bridge@<actual marketplace name>`. Updates stage the new source and automatically preserve the previous source in a scoped backup under `%USERPROFILE%\plugins\discord-call-bridge-backups`; marketplace identity is validated before replacement. Junction/link destinations are refused. Registration backups are adjacent to the marketplace file. The standard personal marketplace is implicitly discovered; no marketplace-add command is needed. If CLI is unavailable, registration remains available for the Codex plugin browser. Start a **new Codex task** after installation and request `$discord-call` setup or test; verify it actually loads the plugin skill.

Current commands were checked with local Codex CLI 0.153.4 using `plugin add --help` and `plugin remove --help`. Official [plugin packaging documentation](https://developers.openai.com/plugins/build/plugins) supplies the manifest/marketplace conventions. Runtime plugin installation on the second host still needs validation.

## Command-line fallback

From the extracted folder in ordinary PowerShell. For every mutating entry point, `-DedicatedAccountConfirmed` explicitly asserts that you are already signed in to the dedicated account; omit it and the command stops before making changes. Never pass it automatically without that user confirmation:

```powershell
.\scripts\Bootstrap.ps1                         # read-only audit
.\scripts\Invoke-AutomaticSetup.ps1 -DedicatedAccountConfirmed -InstallMissing -VoiceApplication 'actual observed Voice app' # Codex setup runner
.\scripts\Bootstrap.ps1 -Mode Prepare -DedicatedAccountConfirmed           # local templates only
.\scripts\Bootstrap.ps1 -Mode InstallApps -DedicatedAccountConfirmed       # missing OBS / Discord
.\scripts\InstallDriver.ps1 -Driver VBCable -DedicatedAccountConfirmed -WhatIf
.\scripts\InstallDriver.ps1 -Driver VBCable -DedicatedAccountConfirmed     # download, signature, UAC
.\scripts\InstallDriver.ps1 -Driver HiFiCable -DedicatedAccountConfirmed   # review compatibility first
.\scripts\InstallPlugin.ps1 -DedicatedAccountConfirmed
```

Installer consoles remain visible for vendor prompts and errors. Do not close one mid-install or start duplicate installs. The wizard does not automatically infer an install completed from an opened console; rerun Detect. Driver cancellation, invalid signatures and installer failures leave setup partial. Driver downloads are kept only in local application data and are excluded from the release.

Preferences default to no recipient and no selected devices, stored under `%LOCALAPPDATA%\DiscordCallBridge`. Do not copy this private state into a redistributable package. A saved recipient never supplies permission for unsolicited calls or DMs.

## Validation and recovery

See [VALIDATION.md](VALIDATION.md) for first-machine evidence and [acceptance checklist](skills/discord-call/references/acceptance.md) for the required second-machine trial. Read [RESTORE.md](RESTORE.md) before changing audio. Successful packaging, device detection, local mic-test playback, connected call, remote hearing and inbound speech are separate evidence stages.

No public listing, sale, third-party binary redistribution, account permission or commercial compatibility claim is included in this private trial.

## Updating from earlier versions

Keep the old ZIP/release for rollback. Run the new extracted package installer; it stages the update and preserves the existing source automatically in a dated scoped backup. No manual rename is required. Keep local device preferences and restore records. The new wizard always starts with the dedicated-account confirmation unchecked, including after reboot. Start a new Codex task after installing the update. Existing personal marketplace entries are preserved.

## Preflight, visible installers and resume

Read [host preflight and Windows 10 screenshot fallback](skills/discord-call/references/host-preflight.md) before installation. Detect reports executable selection, native-control/Voice unknowns and cable evidence. WinGet is required only when an app is missing; already-installed apps are reused without requiring it. Windows 10 can use an available supported screenshot-based Computer Use interface instead of a failed capture path; otherwise manual controls remain necessary.

Driver installers now open visibly after UAC. Their progress records distinguish Downloading, Downloaded, AwaitingUac, Pending, Cancelled, Failed, RestartRequired and DevicesDetected. A launched process or exit code never establishes working audio. Complete or cancel the visible installer; if its window is unusable, inspect that pending process before retrying. The wizard blocks launching a second console for the same helper while its previous console remains open. After any user-approved reboot, reopen Setup.cmd, confirm the dedicated account, use Detect for fresh endpoint evidence, then Finish / Restore > Refresh saved setup progress. Saved timestamps are historical evidence, not current readiness. Close an old helper console only after resolving its installer before retrying.

App/plugin stage records live in `%LOCALAPPDATA%\DiscordCallBridge`; driver records are in its downloads subfolder. Separate per-stage files preserve progress without overwriting other stages. Plugin installation reports InstalledNeedsReload until the user verifies a new task has loaded the skill. Routes, local intelligibility, remote hearing and inbound conversation remain separate user-attested acceptance stages. No saved progress unlocks the account prerequisite or auto-dials.

## Codex must execute requested setup

Ask Codex to "set up and verify this bridge" or "fix the missing dependencies and finish setup". After the required current dedicated-account confirmation, the skill explicitly requires Codex to run the bundled setup/install helpers, apply supported native or screenshot-based routing controls, start available Voice controls and verify results. It must not stop at a checklist telling you to use the wizard while it can execute those steps itself. For audit-only or verification-only requests, it stays read-only.

Manual steps are limited to actual UAC/credential/license/restart decisions or controls unavailable on the host. A native screenshot failure does not excuse skipping independent shell preparation and installer launch. See [automatic execution workflow](skills/discord-call/references/automatic-execution.md). These instructions improve agent behavior; they do not add a missing Voice engine or native automation runtime.

The executable setup runner reuses detected dependencies, manages missing-dependency helper launches, avoids duplicate pending driver launches, selects unambiguous enabled cable endpoints and saves a concrete send/return route plan. Codex must apply that plan through supported OBS/Discord/Voice controls, activate Voice when available, and read back settings. Saved preferences and `ReadyForAgentApplication` are explicitly pending app application; neither is proof of configured audio. This version provides automatic device selection and an agent execution workflow, not a standalone app-routing driver.

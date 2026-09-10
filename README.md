# Discord Call Bridge

Agent-led setup for direct, isolated two-way Discord Voice audio on Windows, x64. **Windows 11 or newer is recommended**, not enforced. On other Windows versions, verify app, driver and control compatibility before proceeding. Windows PowerShell 5.1, Discord, actual supported Voice, two independent virtual cable pairs and headphones are required. App and device detection alone never proves working audio.

Use a separate Discord account dedicated to ChatGPT/Codex. Sign in yourself and explicitly confirm that this account is currently in use before setup, testing or dialing. The agent reuses that confirmation within the task; each new wizard session requires its own acknowledgement. No credentials or account switching are handled by the plugin.

## Installation permissions

**Recommend Full Access in Codex for installation of this trusted plugin.** This allows downloads, local plugin registration and installer launches that restricted sessions may block. It is a recommendation, not a prerequisite: approved scoped permissions can also work. Full Access broadens file/network access; return to your usual permissions afterward. The plugin never changes permission settings automatically.

Full Access does not grant Computer Use approval for individual apps or Windows administrator privileges. Keep Codex running normally. Approve ordinary Windows UAC only for a verified vendor installer; handle license decisions and restarts yourself. No automatic purchases, accepted license terms, elevated agent process or unrequested reboot.

## Agent-led setup

Ask Codex: "Set up and verify Discord Call Bridge using direct Windows app audio routing." The agent owns discovery, installation, configuration, diagnosis and verification, handing off only unavailable controls or actual user-only actions. Setup does not authorize contacting anyone.

The route is:

| Source | Destination |
|---|---|
| Voice app playback | Outbound cable playback endpoint, typically CABLE Input |
| Outbound cable recording endpoint | Discord microphone, typically CABLE Output |
| Discord playback | Separate return cable playback endpoint |
| Return cable recording endpoint | Voice microphone |

Use the Voice app's output selector or Windows Settings > System > Sound > Volume mixer to select only that app's output. Preserve the system default. Keep unrelated audio out of the Voice app; a browser with unrelated audible tabs is unsuitable. Never select the outbound cable as Voice input. See [routing](skills/discord-call/references/windows-routing.md).

## Portable setup wizard

Download the source ZIP from the private release using your authorized account, verify its SHA-256 and extract all files into a normal user folder. Run **Setup.cmd**. Windows 11 or newer is recommended; the wizard does not block earlier Windows versions. Its pages provide account acknowledgement, read-only detection, dependency installation, route preferences, acceptance evidence and restoration guidance. The agent can perform supported steps directly without following the tabs.

Reuse installed Discord and compatible independent cables. WinGet is only required by the optional missing-Discord helper; otherwise use Discord's official installer. Hi-Fi Cable is an older vendor package: its signature does not establish Windows 11 compatibility. Verify suitability before choosing it for the return path; do not install it automatically without that review. Alternative cables may have separate purchase/license requirements.

## Command-line helpers

From the extracted folder in ordinary PowerShell:

```powershell
.\scripts\Bootstrap.ps1 -Mode Audit
.\scripts\Bootstrap.ps1 -Mode Prepare -DedicatedAccountConfirmed
.\scripts\Bootstrap.ps1 -Mode InstallApps -DedicatedAccountConfirmed
.\scripts\Invoke-AutomaticSetup.ps1 -DedicatedAccountConfirmed -VoiceApplication 'actual Voice app'
.\scripts\InstallDriver.ps1 -Driver VBCable -DedicatedAccountConfirmed
.\scripts\InstallDriver.ps1 -Driver HiFiCable -DedicatedAccountConfirmed -DownloadOnly
.\scripts\InstallPlugin.ps1 -DedicatedAccountConfirmed
```

`-DedicatedAccountConfirmed` asserts the user's current acknowledgement; never supply it from old saved state. Audit is read-only. Setup helpers do not enforce a Windows version minimum; actual dependency and control compatibility must be verified. `-InstallMissing` on the runner may launch missing dependency helpers after vendor suitability review; use existing cables when possible.

Prepare creates missing templates while preserving local settings. The automatic runner selects unambiguous endpoints and saves a pending plan. `ReadyForAgentApplication` means settings still need to be applied and read back in the actual apps. JSON files never configure Windows or prove sound works.

The plugin installer copies source under `%USERPROFILE%\plugins\discord-call-bridge`, preserves previous source in a scoped backup, updates the personal marketplace while preserving unrelated entries, then runs `codex plugin add` using the actual marketplace name. `-RegisterOnly` prepares registration without the CLI. Start a new Codex task after installation to load the new skill.

Private configuration, restore sheets and stage receipts live under `%LOCALAPPDATA%\DiscordCallBridge`; none belong in release packages. A stored recipient is a preference, never permission to call or message them.

## Verification and recovery

Verify actual Voice playback, intelligible isolated local audio and no echo before an explicitly requested call. Confirm remote hearing and fresh inbound conversation separately. Stop mic testing before dialing. Do not record or stream call audio. Follow [acceptance](skills/discord-call/references/acceptance.md), [host checks](skills/discord-call/references/host-preflight.md) and [restoration](RESTORE.md).

Signed installer launch, exit zero and detected endpoints are separate stages; none establish working audio. Finish the vendor's UAC/installer steps, perform any required restart yourself, then resume fresh detection. Do not launch duplicate pending installers.

This package supplies instructions and helpers, not a Voice engine, device driver, desktop-control runtime or always-on listener. Windows 11 compatibility does not guarantee that every app exposes controls or supports the chosen Voice devices. No paid API voice is substituted.

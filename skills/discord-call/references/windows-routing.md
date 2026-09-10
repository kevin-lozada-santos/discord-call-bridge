# Windows setup and fault isolation

Use the setup wizard's Detect page first. Windows 10 build 19041+ or Windows 11 and OBS 28+ are required for the application-capture design. This release targets Windows x64. Other architectures and individual app/capture combinations need separate qualification. A detected device or configured name does not establish working audio.

## Installation and cost boundaries

Reuse existing OBS, Discord and compatible independent cables. Enter nonstandard executable locations in the local config before installing duplicates. The wizard's app button invokes WinGet exact package IDs OBSProject.OBSStudio and Discord.Discord from the winget source, with vendor installers and manifest hash checks. Review the displayed package agreements and UAC. If WinGet is absent, install Microsoft's App Installer via Microsoft Store. Install/sign into the current Codex desktop app through its official distribution; account Voice availability is verified in-app, not inferred from CLI presence.

The driver helper downloads official VB-Audio ZIPs into local application data, extracts, checks Authenticode status and expected publisher, and launches only the identified installer with RunAs. It does not elevate Codex. If a legacy certificate/package fails verification, nothing is elevated: obtain a supported package from the vendor and review it manually. Do not disable signature checks. After the vendor-required restart, reopen Setup.cmd and Detect; saved configuration survives. There is no automatic restart, persistent service or startup task.

VB-CABLE is donationware. Hi-Fi Cable's vendor page describes free end-user use/donationware but lists an older Windows package; compatibility on a fresh current machine is not guaranteed. Additional VB-CABLE A/B or C/D packages and distribution/commercial use have separate vendor licensing terms. Choose and acquire any alternative yourself. No licenses or drivers are bundled. OBS is GPL software; Discord is proprietary. Codex/Voice account access and usage limits are separate. The plugin makes no paid API calls and includes no API key.

## Save and configure

Before changes, fill the wizard's previous-settings sheet. Never change a live call, stream or recording. Use OBS Profile > New and Scene Collection > New, both named Discord Call Bridge. These are supported UI operations: if native control is available, the agent may perform them through the observed documented UI. The wizard does not write undocumented OBS/Discord internal configuration files. Without native control, perform the following in the apps; the Configure page keeps this guide visible.

| Application | Required route |
|---|---|
| OBS global audio | Disable Desktop Audio and Mic/Aux in the dedicated profile |
| OBS source | Application Audio Capture of ONLY the Voice-producing application; name Voice Bridge Audio |
| OBS monitoring device | Outbound cable playback endpoint, typically CABLE Input |
| OBS monitoring | Enable monitoring to that endpoint. Older UI: Monitor Only (mute output). OBS 32.2+ changed to independent mute/monitor controls; inspect current controls and actual signal |
| OBS source | Ensure source active and not inadvertently muted; check meter and monitoring |
| Discord microphone | Outbound cable recording endpoint, typically CABLE Output |
| Discord playback | Independent return cable playback endpoint, typically Hi-Fi Cable Input |
| Voice microphone | Return cable recording endpoint, typically Hi-Fi Cable Output |
| Local listening | Headphones only; optional Windows Listen on return recording device to explicit headphones, never either cable |

Windows Sound > More sound settings > Playback/Recording > each Hi-Fi endpoint > Properties > Advanced: match the sample rate on both sides (e.g. 48000 Hz). Verify matching formats for the chosen route and apps; do not assume configuration JSON applies Windows settings. If Voice cannot choose an input, use its supported device selection or a user-approved Windows input change with original default recorded. If neither is supported, two-way operation is blocked.

The cable's Input is a Windows playback endpoint and Output is its recording endpoint. Never return Discord playback to the outbound cable or capture Discord with the outbound source. Never use outbound recording as Voice input. A browser process can contain multiple tabs: isolate Voice from Discord and unrelated audio. No recording, streaming, Virtual Camera or ASIO Bridge process is required for the basic cable route.

Start/reuse actual Voice through its supported control. Labels and availability vary; do not promise a Start Voice button exists. Dictate is not live Voice. If only text or browser controls are exposed to the agent, user activation/native settings are required. Do not substitute paid API voice.

## Test and repair

1. Play a short nonsensitive Voice phrase. Confirm actual source playback, OBS source meter and return to silence.
2. Confirm monitoring enabled and source unmuted. A muted source caused a startup failure in the reference setup; unmuting fixed that setup but is not proof of this machine's state.
3. Run Discord Voice & Video > Mic Test / Let's Check. Temporarily direct mic-test playback to headphones if the return route would feed Voice; record and restore the output afterward. Hear intelligible speech; meters alone are insufficient. Stop Testing before calling (mic test can mute/deafen channel communication).
4. Ensure silence/unrelated audio is not forwarded. Mute immediately if echo occurs. Check broad capture, duplicate direct/OBS feeds, shared browser audio, Windows Listen, and cable self-capture before gain/processing changes.
5. Restore return routing, select Voice input, then make only the requested call. Confirm remote hearing and fresh inbound speech as separate stages.

If Voice plays but OBS does not respond, verify capture window/process and app mixer volume. If OBS responds but Discord is silent, check source mute, monitor enable/device and paired Discord microphone. After driver changes, restart apps or Windows only with the user's explicit choice. For clipping/cut-off speech, test Discord sensitivity/noise processing one setting at a time and preserve previous values.

If application capture is incompatible, supported Windows app-specific Volume Mixer routing may send Voice directly to the outbound playback cable. Explain this OBS-free alternative and use only one outbound feed. Keep return audio isolated. Do not reset all settings or remove existing drivers as a troubleshooting shortcut.

## Sources checked during packaging

- https://obsproject.com/kb/application-audio-capture-guide
- https://github.com/obsproject/obs-studio/releases/tag/32.2.1 (monitoring UI changes)
- https://vb-audio.com/Cable/ (both cables, installation, sample rates and terms)
- https://support.discord.com/hc/en-us/articles/360020641332-Mic-Testing
- https://developers.openai.com/plugins/build/plugins (plugin packaging)

Documentation describes design and prerequisites; only local/remote acceptance establishes actual audio behavior.

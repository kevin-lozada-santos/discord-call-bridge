# Direct Windows audio routing

Recommend Windows 11 or newer, without enforcing a version minimum. Require compatible x64 Windows, Discord, working supported Voice, two independent virtual cable pairs and headphones. Verify actual compatibility on the host. Confirm the dedicated Discord account is currently in use. Preserve live unrelated audio activity.

Recommend Full Access in Codex for trusted installation; it is optional and does not supply app-control approvals or administrator rights. Restore normal permissions afterward. Only verified vendor installers request UAC. Read [host checks](host-preflight.md) before setup.

## Dependencies

Reuse installed Discord and compatible cables. The optional app helper installs only Discord.Discord using WinGet; if unavailable, use the official Discord installer. No package manager is installed automatically. Vendor ZIPs are downloaded from official sources and publisher signatures checked before execution. No binaries, licenses or credentials are bundled.

VB-CABLE is donationware. Hi-Fi Cable is a legacy vendor option: a valid signature is not Windows 11 compatibility evidence. Review vendor suitability and licensing before choosing it, or use an existing compatible independent cable. Additional A/B or C/D cable packages have separate licensing/purchase terms; do not purchase automatically. See [vendor information](https://vb-audio.com/Cable/).

## Preserve and apply

Record original Discord and Voice devices, input mode/processing, Windows app routes/defaults, volume/mute and Listen settings before changes. Save a restore sheet or equivalent record; preferences in JSON do not apply app settings.

| Setting | Direct route |
|---|---|
| Voice app output | Outbound playback endpoint, typically CABLE Input |
| Discord input | Outbound recording endpoint, typically CABLE Output |
| Discord output | Independent return playback endpoint |
| Voice input | Independent return recording endpoint |

Use an in-app output selector or Windows Settings > System > Sound > Volume mixer > Apps to select the Voice app's output. The app may need to play audio before appearing. Preserve the system default. Read back the actual selections. Do not capture all desktop audio or mix physical microphones, Discord returns or unrelated tabs into outbound. If the app cannot isolate Voice or honor its selected devices, stop and diagnose that specific constraint.

Never use the outbound recording endpoint as Voice input. Never send Discord playback to the outbound cable. Optional Windows Listen must target explicit headphones, never either cable. Match playback and recording sample rates for each cable according to vendor guidance, such as 48000 Hz where supported. Do not infer Windows settings from a saved plan.

## Verify and troubleshoot

1. Start/reuse actual supported Voice; verify listening, speaking and playback. Dictate is not Voice.
2. Play a short nonsensitive phrase. Use Discord mic testing with test playback on headphones to verify intelligibility without feeding Voice. Stop the test and restore the separate return output afterward.
3. Check silence, unrelated sound exclusion and no echo. Meters alone cannot prove speech quality.
4. Only for an explicitly requested call, verify the recipient and connection, then remote hearing and a fresh inbound phrase followed by an appropriate spoken reply.

If speech is silent, inspect actual app output, cable pair, app volume/mute and Discord input. If the app ignores a device change, restart that idle app when in scope and read back settings. For echo, mute outbound first and check crossed devices, shared app audio and Windows Listen. Preserve prior values while adjusting sensitivity or processing. Do not reset all settings or remove shared drivers.

After installation, complete the visible vendor prompts and user-approved restart, then detect both endpoints again. Avoid duplicate pending installers. Installer exit zero and device presence are not audio tests. Local tests do not prove remote hearing or inbound conversation.

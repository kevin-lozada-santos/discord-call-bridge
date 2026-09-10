# First-machine validation - 2026-09-10

This report covers packaging and safe local tests, not installation or audio acceptance on a second machine.

Verified:

- Official plugin manifest validator and skill frontmatter validator pass.
- PowerShell 5.1 parses all helper scripts; behavioral fixture tests cover missing/unknown dependencies, unset recipient/devices, independent cables, feedback rejection and preservation of local configuration across repeated Prepare runs.
- Plugin registration/copy runs against an isolated profile path containing spaces. Existing marketplace name, display metadata and unrelated entry are preserved; retry from destination does not duplicate the entry.
- Driver and plugin WhatIf modes perform no installations. Fault injection verifies a cancelled UAC launch is reported as incomplete and an unsigned installer is refused before elevation. These are simulated failures; no real UAC prompt was invoked.
- Both official vendor ZIPs were actually downloaded and extracted in DownloadOnly mode. The selected executable signatures were Valid: current VB-CABLE publisher BUREL VINCENT Entrepreneur individuel and legacy Hi-Fi publisher Vincent Burel. No vendor binary is in this release; no installer was launched.
- Windows Forms controls are constructed and all five pages selected in the smoke test. Offscreen rendering was used for visual inspection of the wizard, without invoking install/audio actions. This is limited local UI validation, not a fresh-machine interactive acceptance pass.
- Read-only inventory detects existing source-machine OBS/Discord and endpoints. Endpoint-name variants such as Speakers are recognized without treating other virtual microphones as cables. No audio settings were modified.

Not run here:

- Actual dependency install, UAC approval/cancellation, driver restart/resume, or uninstall on a new machine.
- Plugin activation/new-task pickup on the source machine (deliberately avoided to protect the existing call skill).
- Second-machine Voice availability/native automation capability, audio route configuration, local intelligibility, remote hearing, inbound speech or hang-up.

Use tests/Validate.ps1 for safe fixture checks. Use the acceptance checklist for the actual trial. Wizard checkboxes record user attestation; neither checked boxes nor exit code alone establish measured signal flow. A downloaded/installed dependency is not proof of two-way calling.

## Version 0.1.1 account prerequisite update

- Required initial wizard page uses an unchecked confirmation that the dedicated Discord account is currently in use. No saved configuration or old acceptance record unlocks it.
- Native Windows Forms smoke test attempts every setup tab before acknowledgement and confirms navigation is blocked. It then confirms acknowledgement unlocks Configure and revocation relocks it. The test shows the form offscreen only and invokes no installer/audio actions.
- Bootstrap Prepare, driver installer and plugin installer are invoked without acknowledgement and verified to stop before mutation. Existing positive-path fixture tests now supply explicit test confirmation. Audit remains read-only with the warning.
- CLI flags are attestations, not account identity verification. The skill separately requires user confirmation before setup/testing/dialing. No account creation, switching, login inspection or credential handling was added.
- ZIP content and a downloaded private release are revalidated for this update. Actual Discord account state and second-machine audio remain untested.

## Version 0.1.2 email-report fixes

Source report: email subject "Discord Call Bridge: blockers to a one-click install and call", September 10, 2026, 4:16 AM. The report describes a Windows 10 build 19045 x64 trial; its account/participant details and full private message are not bundled.

Regression.ps1 first failed on three observed package contracts: repeated extracted-package install refused an existing folder; driver launch requested Hidden rather than a visible UI; inventory ignored the running Discord executable. The same regression test passes after the fixes. Installer execution remains mocked: it proves visible RunAs arguments, progress semantics and endpoint classification, not an actual UAC or driver installation.

Updates now stage source and preserve scoped prior-source backups and marketplace entries. Running Discord executable paths take priority over inactive folders (explicit user path still wins). Driver progress is persisted across restarts, visible interactive installation is requested, and both enabled endpoints are checked separately from process exit. Existing account gate, cancellation/signature refusal, isolated profile fixtures and wizard smoke tests remain required.

Native capture error on Windows 10 (`SetIsBorderRequired`, 0x80004002) was reported by email, not reproduced on this packaging machine. The new capability-discovered screenshot-based Computer Use fallback is guidance for supported hosts, not an implementation or verification of a new capture runtime. Voice activation and second-machine two-way audio remain unverified. No calls, account changes or audio mutations are performed by these tests.

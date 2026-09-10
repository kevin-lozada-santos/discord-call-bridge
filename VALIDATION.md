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

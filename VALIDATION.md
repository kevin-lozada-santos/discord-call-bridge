# Validation

This release recommends Windows 11 or newer without enforcing a version minimum, and uses direct per-app audio routing. Full Access in Codex is recommended for trusted installation, not required or enabled by the plugin. App-control approvals and vendor UAC remain separate.

## Automated package checks

- Validate.ps1: script parsing, dedicated-account gates, missing/unknown dependencies, independent routes, feedback rejection, state preservation, isolated marketplace registration, installer signature/cancellation fixtures and wizard construction.
- Regression.ps1: safe repeated extracted-package updates, scoped backups, visible vendor installer handoff/status and running Discord detection.
- AutomaticSetup.ps1: independent endpoint selection, ambiguity and missing-device refusal, pending-plan persistence and resume without claiming application.
- Manifest and skill validators; source-only release ZIP integrity and private-data checks.

Tests use an explicit Windows 10 fixture to check that setup is not blocked solely by OS version. No test approves UAC, installs a driver, changes live app audio or places a call. Wizard SmokeTest constructs controls only. There is no Windows version gate.

## Runtime evidence limits

Windows 11 end-to-end installation, native control, direct audio routing, local intelligibility, remote hearing and inbound conversation have not been verified for this update. Earlier host trials established that package/driver success does not establish screenshot-control or working audio. No prior trial is treated as acceptance of the new supported route.

Use the acceptance checklist for a fresh supported-host trial. Preserve previous source/settings for restoration, and record every audio stage separately.

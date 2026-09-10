# Host preflight and Windows 10 fallback

Before installing dependencies or dialing, establish these independent facts:

1. Read-only Detect: Windows build/architecture, OBS and Discord versions and executable paths, enabled send/return cable pairs, WinGet and Codex CLI presence. Running Discord path is preferred over inactive app folders unless the user configured an explicit executable. Multiple running paths or denied process metadata are unresolved, not proof of a particular active version.
2. Through the current host's documented Computer Use capability, check that the intended native window can be observed and controlled. A sparse accessibility tree alone does not establish usable control. Do not start or change a call to probe this.
3. Independently verify actual Voice activation, audible output and input selection. Text mode, Dictate or an end-Voice tool is not sufficient. If no supported activation interface exists, have the user start Voice in the chosen app; no paid API substitution.
4. Report each missing capability and choose supported screenshot-based control or manual setup before installing more software in the hope it will repair the host.

## Screenshot-based Computer Use substitute

On Windows 10, a supported screenshot-based Computer Use interface can substitute for an unavailable accessibility/capture path. Discover the tools actually exposed in this session and read their current documentation. Capture a fresh screenshot, verify the intended window/recipient visually, then use only that interface's documented input controls and observed coordinates. Reobserve after each change; never guess coordinates or native APIs.

The trial on Windows 10 build 19045 reported `SetIsBorderRequired failed: No such interface supported (0x80004002)` twice, including after refreshing the window. This is a capture-runtime failure, not proof Discord or the audio route is broken. If one documented refresh/retry still fails, discover an independently available screenshot-and-input Computer Use capability. Merely renaming the same failing API or repeating its capture loop is not a fallback. If no such interface works, use manual app controls and the routing guide; report automated recipient verification/calling as unavailable. A browser-only tool does not control native Discord/OBS. Explain and obtain the user's product choice before any browser substitution.

Do not install a replacement runtime/driver, fabricate screenshot APIs, bypass host capture restrictions, or alter Discord/audio merely to work around this failure. No Windows 10 capture repair is claimed by this plugin; qualify the selected fallback on that machine.

## Private ZIP access and Git certificate errors

Private GitHub resources return 404 when unauthenticated. Sign in to the authorized GitHub account and download the release ZIP through GitHub. Do not make the repository public to resolve access. Git is optional for ZIP installation.

For a Git checkout reporting `unable to get local issuer certificate`, inspect the installed Git TLS backend and corporate trust requirements. On supported Git for Windows, an explicit per-command `git -c http.sslBackend=schannel clone <authorized-private-repository-url>` uses the Windows certificate store. This is a compatibility option, not proof the certificate chain is valid; keep certificate verification enabled and use the organization's approved trust setup if the error persists. Never use sslVerify=false or copy another user's credentials.

See the official [Git HTTP configuration reference](https://github.com/git/git/blob/master/Documentation/config/http.adoc) for backend support and certificate-store behavior.

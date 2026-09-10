# Supported host and permissions

Recommend Windows 11 or newer, x64, without enforcing an OS version minimum. Bootstrap Audit is read-only. On other Windows versions, verify the actual app, driver and control compatibility; report concrete failures rather than blocking solely on version. Ending existing calls and restoring settings remain possible.

Recommend Full Access in Codex for this trusted plugin installation. It allows broader local files/network and can resolve sandbox download or installer-launch restrictions. It is optional; approved scoped permissions may work. Restore normal permissions afterward. Never change the access mode automatically or instruct the user to run Codex as administrator. Full Access does not grant Computer Use approval for Discord/Windows Settings, does not bypass UAC and does not repair incompatible screenshot APIs.

Inspect actual OS/build, Discord path/version, enabled cable pairs and pending installer processes. A running Discord path takes precedence over inactive install folders unless explicitly configured. Missing or denied inventory is unknown, not absence. Verify current supported native/screenshot controls independently of the shell inventory. Read Computer Use guidance first; text or keyboard success is not screenshot/click capability.

Verify actual Voice activation, speech playback and device selection. A text chat or end-Voice tool proves none of those. If a supported control fails, refresh its target and retry once, then investigate an available supported alternative. Do not invent APIs, repeat the same failing capture path or silently change to a browser product. Complete independent setup before handing off the exact unavailable action.

## Installers and resume

Use only official packages and validate publisher signatures before UAC. Secure-desktop approval, license decisions and user-controlled restarts remain handoffs. Elevated installer windows may be inaccessible to the helper even with Full Access. A launched process is not completion; inspect it before any retry. After restart, detect endpoints again and keep historical receipts labelled historical.

## Private release and Git access

Private GitHub ZIPs require the user's authorized signed-in account. Do not make a repository public to resolve 404 errors. Git is optional for ZIP installation.

For Git certificate errors, inspect the trust setup. A per-command `git -c http.sslBackend=schannel` may use the Windows certificate store on supported Git for Windows. Keep certificate verification enabled; do not bypass trust checks or copy credentials.

## References

- [Windows sandbox and permissions](https://learn.chatgpt.com/docs/windows/windows-sandbox)
- [Windows capture API availability](https://learn.microsoft.com/en-us/uwp/api/windows.graphics.capture.graphicscapturesession.isborderrequired)
- [Git HTTP configuration](https://github.com/git/git/blob/master/Documentation/config/http.adoc)

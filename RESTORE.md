# Restore and uninstall

End only the calls you explicitly intend to end. Mute outbound before changing routes. Stop any mic test. Open %LOCALAPPDATA%\DiscordCallBridge\previous-settings.json and restore the recorded Discord input/output/mode/processing, Voice input, Windows app routing/Listen settings, OBS monitoring and previous profile/collection through current app controls. Do not reset all settings.

The wizard's configuration step saves preferences and a restore sheet; it does not silently snapshot undocumented app settings. Fill the sheet before UI changes. If it is blank, those original values are unknown: do not guess or claim restoration.

Remove the plugin in Codex's plugin browser, or run:

    codex plugin remove discord-call-bridge@personal

Use your actual marketplace name if different. This removes the installed cache. To remove its availability entry, back up %USERPROFILE%\.agents\plugins\marketplace.json and remove only the entry named discord-call-bridge; preserve every other entry and root metadata. Do not restore an old whole-marketplace backup over newer unrelated changes.

Rename %USERPROFILE%\plugins\discord-call-bridge to an archive name once the plugin is removed. Keep %LOCALAPPDATA%\DiscordCallBridge until restoration is verified; archive it afterward if desired. It can contain local recipient preferences, setup receipts, acceptance and downloads; none are part of the release.

Leave pre-existing/shared OBS, Discord and drivers installed. If you explicitly want to remove a dependency installed for this bridge, use Windows Installed Apps or the official driver uninstall procedure, review other consumers, and approve UAC/reboot yourself. There is no persistent privileged helper, automatic reboot task, API subscription or service to remove.

For an updated source, the installer prints its scoped backup path under the plugins folder. To roll back, remove the installed plugin in Codex, preserve the current source under a different name, and restore the chosen backup to the exact discord-call-bridge folder. Reinstall that version and start a new task. Do not replace the whole marketplace with an old backup; keep newer unrelated entries. Update staging is reversible and never deletes prior source files.

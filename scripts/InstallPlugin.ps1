[CmdletBinding(SupportsShouldProcess)]
param([switch]$DedicatedAccountConfirmed, [switch]$RegisterOnly, [string]$ProfileRoot = $env:USERPROFILE)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Bridge.psm1') -Force
Assert-DedicatedAccount $DedicatedAccountConfirmed.IsPresent
$source = Split-Path $PSScriptRoot -Parent
$target = Join-Path $ProfileRoot 'plugins\discord-call-bridge'
$market = Join-Path $ProfileRoot '.agents\plugins\marketplace.json'
if (-not $PSCmdlet.ShouldProcess($target, 'Copy plugin, append personal marketplace entry, and install unless RegisterOnly')) { return }
$entry = [pscustomobject]@{name='discord-call-bridge';source=[pscustomobject]@{source='local';path='./plugins/discord-call-bridge'};policy=[pscustomobject]@{installation='AVAILABLE';authentication='ON_INSTALL'};category='Productivity'}
if (Test-Path -LiteralPath $market) {
    $data = Get-Content -LiteralPath $market -Raw | ConvertFrom-Json
    if ($data.name -notmatch '^[A-Za-z0-9_-]+$' -or $null -eq $data.plugins) { throw 'Existing marketplace is invalid; it has not been changed.' }
    $matching = @($data.plugins | Where-Object name -eq 'discord-call-bridge')
    if ($matching.Count -gt 1 -or ($matching.Count -eq 1 -and ($matching[0].source.source -ne 'local' -or $matching[0].source.path -ne $entry.source.path))) { throw 'Existing entry points elsewhere; resolve without overwriting it.' }
    if (-not $matching.Count) {
        Copy-Item -LiteralPath $market -Destination ($market+'.bridge-backup-'+[guid]::NewGuid().ToString('N'))
        $data.plugins = @($data.plugins) + @($entry)
    }
} else {
    $data = [pscustomobject]@{name='personal';interface=[pscustomobject]@{displayName='Personal'};plugins=@($entry)}
}
$progressDir=if ([IO.Path]::GetFullPath($ProfileRoot) -eq [IO.Path]::GetFullPath($env:USERPROFILE)) { Join-Path $env:LOCALAPPDATA 'DiscordCallBridge' } else { Join-Path $ProfileRoot '.bridge-state' }
# Validate the existing marketplace before staging an update.
$source=[IO.Path]::GetFullPath($source)
$target=[IO.Path]::GetFullPath($target)
$pluginParent=[IO.Path]::GetFullPath((Join-Path $ProfileRoot 'plugins'))
if ((Split-Path $target) -ne $pluginParent -or (Split-Path $target -Leaf) -ne 'discord-call-bridge') { throw 'Update target escaped the plugin directory.' }
if ($source -ne $target) {
    if ($source.StartsWith($target+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) { throw 'Extract the new package outside the existing plugin folder.' }
    foreach ($boundary in @($source,$target,$pluginParent)) {
        $cursor=$boundary
        while ($cursor) {
            if ((Test-Path -LiteralPath $cursor) -and ((Get-Item -LiteralPath $cursor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Update through a junction or symbolic link is unsupported; use a normal folder.' }
            $parent=Split-Path $cursor -Parent
            if ($parent -eq $cursor) { break }; $cursor=$parent
        }
    }
    $sourceManifest=Get-Content -LiteralPath (Join-Path $source '.codex-plugin\plugin.json') -Raw | ConvertFrom-Json
    if ($sourceManifest.name -ne 'discord-call-bridge') { throw 'Source plugin identity mismatch.' }
    if (Test-Path -LiteralPath $target) {
        $existing=Get-Content -LiteralPath (Join-Path $target '.codex-plugin\plugin.json') -Raw | ConvertFrom-Json
        if ($existing.name -ne 'discord-call-bridge') { throw 'Destination belongs to a different plugin; no move performed.' }
    }
    $stage=Join-Path $pluginParent ('.bridge-stage-'+[guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $stage -Force | Out-Null
    $items=@(Get-ChildItem -LiteralPath $source -Force | Where-Object { $_.Name -notin @('.git','dist','local') })
    if (@($items | Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint }).Count) { throw 'Source contains linked content; no existing plugin changed.' }
    $items | Copy-Item -Destination $stage -Recurse -Force
    $backup=$null
    if (Test-Path -LiteralPath $target) {
        $backupParent=Join-Path $pluginParent 'discord-call-bridge-backups'
        if ((Test-Path -LiteralPath $backupParent) -and ((Get-Item -LiteralPath $backupParent -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Backup directory is a link; refusing update.' }
        $backup=Join-Path $backupParent ([DateTime]::UtcNow.ToString('yyyyMMddTHHmmss')+'-'+[guid]::NewGuid().ToString('N'))
        if (-not ([IO.Path]::GetFullPath($backup).StartsWith($pluginParent+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase))) { throw 'Backup path escaped plugin directory.' }
        New-Item -ItemType Directory -Path $backupParent -Force | Out-Null
        Move-Item -LiteralPath $target -Destination $backup
        Write-Output "Previous source preserved at $backup"
    }
    try { Move-Item -LiteralPath $stage -Destination $target }
    catch {
        if ($backup -and -not (Test-Path -LiteralPath $target)) { Move-Item -LiteralPath $backup -Destination $target }
        throw
    }
}
New-Item -ItemType Directory -Path (Split-Path $market) -Force | Out-Null
$temp = $market+'.'+[guid]::NewGuid().ToString('N')+'.tmp'
$data | ConvertTo-Json -Depth 40 | Set-Content -LiteralPath $temp -Encoding UTF8
Move-Item -LiteralPath $temp -Destination $market -Force
Save-BridgeProgress $progressDir 'Plugin' 'Registered' 'Source and personal marketplace registered; plugin loading not confirmed.'
if (-not $RegisterOnly) {
    if (-not (Get-Command codex -ErrorAction SilentlyContinue)) { throw "Registered but not installed: Codex CLI unavailable. Open plugin browser and select the personal discord-call-bridge entry, or install a supported Codex CLI then rerun from $target." }
    & codex plugin add ('discord-call-bridge@'+$data.name) --json
    if ($LASTEXITCODE -ne 0) { Save-BridgeProgress $progressDir 'Plugin' 'Failed' 'Codex plugin add failed; registration preserved.'; throw 'Plugin registration preserved; installation failed. Inspect Codex output, then retry from the destination folder.' }
    Save-BridgeProgress $progressDir 'Plugin' 'InstalledNeedsReload' 'Codex CLI reported installation; start a new task and verify skill discovery. Audio not verified.'
}
Write-Output 'Plugin registration complete. Start a NEW Codex task and request the discord-call skill. Audio and Voice still require acceptance testing.'

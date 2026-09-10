[CmdletBinding()]
param([switch]$DedicatedAccountConfirmed, [ValidateSet('Audit','Prepare','InstallApps')][string]$Mode = 'Audit',
    [string]$StateDir=(Join-Path $env:LOCALAPPDATA 'DiscordCallBridge'))
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Bridge.psm1') -Force
$root = Split-Path $PSScriptRoot -Parent
if ($Mode -ne 'Audit') { Assert-DedicatedAccount $DedicatedAccountConfirmed.IsPresent }
else { Write-Warning (Get-DedicatedAccountWarning) }
$before = Get-BridgeInventory -ConfigPath (Join-Path $StateDir 'config.json')
if ($Mode -eq 'Audit') {
    [pscustomobject]@{Inventory=$before;Plan=@(Get-BridgePlan $before)} | ConvertTo-Json -Depth 8
    return
}
$stateDir = Initialize-BridgeState $root $StateDir
try {
if ($Mode -eq 'InstallApps') {
    if ($before.WindowsBuild -lt 19041) { throw 'Windows 10 build 19041 or newer is required for this route.' }
    if ((-not $before.ObsPresent -or -not $before.DiscordPresent) -and -not $before.WingetPresent) { throw 'Install/update Microsoft App Installer from Microsoft Store, then reopen this wizard. No alternate package manager is installed automatically.' }
    foreach ($app in @(@('ObsPresent','OBSProject.OBSStudio'),@('DiscordPresent','Discord.Discord'))) {
        if (-not $before.($app[0])) {
            Write-Output "Installing $($app[1]); review vendor installer/UAC/license prompts."
            Save-BridgeProgress $stateDir 'Apps' 'Pending' ('Installing '+$app[1]+'; complete visible prompts.')
            & winget install --id $app[1] --exact --source winget --interactive --no-upgrade
            if ($LASTEXITCODE -ne 0) { throw "Installer stopped with exit $LASTEXITCODE. Setup is partial; re-run Audit. No restart was requested by this script." }
        }
    }
}
$after = Get-BridgeInventory -ConfigPath (Join-Path $StateDir 'config.json')
Save-BridgeProgress $stateDir 'Apps' $(if ($after.ObsPresent -and $after.DiscordPresent) {'AppsDetected'} else {'NeedsAttention'}) 'App paths detected only; check versions, host capture/control and active Voice separately.'
[pscustomobject]@{Inventory=$after;Plan=@(Get-BridgePlan $after)} | ConvertTo-Json -Depth 8

} catch { Save-BridgeProgress $stateDir 'Apps' 'Failed' $_.Exception.Message; throw }

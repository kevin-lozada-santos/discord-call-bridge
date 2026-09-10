[CmdletBinding()]
param([switch]$DedicatedAccountConfirmed,[switch]$InstallMissing,[string]$VoiceApplication,
    [string]$StateDir=(Join-Path $env:LOCALAPPDATA 'DiscordCallBridge'))
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'Bridge.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'AutomaticSetup.psm1') -Force
Assert-DedicatedAccount $DedicatedAccountConfirmed.IsPresent
Write-Output (Get-BridgeInstallationAdvice)
$root=Split-Path $PSScriptRoot -Parent
$null=Initialize-BridgeState $root $StateDir
$configPath=Join-Path $StateDir 'config.json'
$config=Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
if ($VoiceApplication) {
    $config.voiceApplication=$VoiceApplication
    $config | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $configPath -Encoding UTF8
}
$inventory=Get-BridgeInventory -ConfigPath $configPath
if ($InstallMissing) {
    if (-not $inventory.DiscordPresent) {
        & (Join-Path $PSScriptRoot 'Bootstrap.ps1') -Mode InstallApps -DedicatedAccountConfirmed -StateDir $StateDir
    }
    foreach ($driver in @('VBCable','HiFiCable')) {
        $inventory=Get-BridgeInventory -ConfigPath $configPath
        if ($inventory.EndpointError) { throw 'Cannot classify missing drivers while endpoint enumeration is unavailable.' }
        $fields=if ($driver -eq 'VBCable') { @('outboundPlayback','outboundRecording') } else { @('returnPlayback','returnRecording') }
        $configuredPair=@($fields | Where-Object {
            $name=$config.$_
            $name -and @($inventory.Endpoints | Where-Object { $_.Status -eq 'OK' -and $_.FriendlyName -eq $name }).Count -eq 1
        }).Count -eq 2
        if (-not $configuredPair -and -not (Test-BridgeDriverEndpoints $driver $inventory)) {
            $progressPath=Join-Path $StateDir ('downloads\'+$driver+'-progress.json')
            if (Test-Path -LiteralPath $progressPath) {
                $saved=Get-Content -LiteralPath $progressPath -Raw | ConvertFrom-Json
                if ($saved.status -in @('Pending','AwaitingUac','RestartRequired')) {
                    Write-Output "$driver is $($saved.status). Resolve its existing installer/restart handoff and rerun; no duplicate launch."
                    continue
                }
            }
            & (Join-Path $PSScriptRoot 'InstallDriver.ps1') -Driver $driver -DedicatedAccountConfirmed -DownloadRoot (Join-Path $StateDir 'downloads')
        }
    }
}
$inventory=Get-BridgeInventory -ConfigPath $configPath
$plan=Get-AutomaticRoutePlan $inventory $config
if (-not $plan.blockers.Count) {
    Copy-Item -LiteralPath $configPath -Destination ($configPath+'.before-routes-'+[guid]::NewGuid().ToString('N'))
    foreach ($field in $plan.selected.Keys) { $config.$field=$plan.selected[$field] }
    $config | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $configPath -Encoding UTF8
}
$plan | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $StateDir 'routing-plan.json') -Encoding UTF8
Save-BridgeProgress $StateDir 'Routing' $plan.status 'Plan prepared for Codex execution. Saved endpoint preferences do not apply app settings; native/screenshot/API action and verification still required.'
$plan | ConvertTo-Json -Depth 10
Write-Output 'CODEX NEXT ACTION: apply or adapt the suggested route using available supported methods now. Do not return this plan as a user checklist. For a missing control, finish independent actions and give only the exact handoff. Record applied routes only after reading back actual app settings.'

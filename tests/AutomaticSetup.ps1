$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'TestHost.ps1')
$root=Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $root 'scripts\AutomaticSetup.psm1') -Force
$cfg=Get-Content -LiteralPath (Join-Path $root 'config\config.example.json') -Raw | ConvertFrom-Json
$cfg.voiceApplication='Test Voice App'
$inv=[pscustomobject]@{EndpointError=$null;Endpoints=@('CABLE Input','CABLE Output','Hi-Fi Cable Input','Hi-Fi Cable Output') | ForEach-Object {[pscustomobject]@{FriendlyName=$_;Status='OK'}}}
$plan=Get-AutomaticRoutePlan $inv $cfg
if ($plan.status -ne 'ReadyForAgentApplication' -or $plan.actions.Count -ne 5 -or $plan.applied) { throw 'Valid independent route plan not produced honestly' }
if ($plan.selected.returnRecording -ne 'Hi-Fi Cable Output' -or $plan.selected.outboundRecording -ne 'CABLE Output') { throw 'Send/return were reversed' }
if ($plan.actions[1].surface -ne 'Windows Volume mixer' -or $plan.actions[1].action -notmatch 'Test Voice App' -or $plan.actions[1].action -notmatch 'Preserve the system default') { throw 'Direct output route lost app isolation or system-default preservation' }
$inv.Endpoints+= [pscustomobject]@{FriendlyName='CABLE Input';Status='OK'}
if ((Get-AutomaticRoutePlan $inv $cfg).status -ne 'NeedsPreparation') { throw 'Ambiguous endpoint auto-selected' }
$inv.Endpoints=@()
if ((Get-AutomaticRoutePlan $inv $cfg).actions.Count) { throw 'Missing devices produced actionable routing' }
$inv.EndpointError='fixture failure'
if ((Get-AutomaticRoutePlan $inv $cfg).status -ne 'NeedsPreparation') { throw 'Enumeration failure ignored' }
$rejected=$false
try { & (Join-Path $root 'scripts\Invoke-AutomaticSetup.ps1') } catch { $rejected=$_.Exception.Message -match 'dedicated account is currently in use' }
if (-not $rejected) { throw 'Automatic entry point bypassed account confirmation' }
$fixtureRoot=Join-Path ([IO.Path]::GetTempPath()) ('bridge automatic '+[guid]::NewGuid().ToString('N'))
try {
    function global:Get-PnpDevice {
        param($Class,[switch]$PresentOnly,$ErrorAction)
        @('CABLE Input','CABLE Output','Hi-Fi Cable Input','Hi-Fi Cable Output') | ForEach-Object {
            [pscustomobject]@{FriendlyName=$_;Status='OK';InstanceId='fixture'}
        }
    }
    $null=& (Join-Path $root 'scripts\Invoke-AutomaticSetup.ps1') -DedicatedAccountConfirmed -VoiceApplication 'Fixture Voice' -StateDir $fixtureRoot
    $saved=Get-Content -LiteralPath (Join-Path $fixtureRoot 'config.json') -Raw | ConvertFrom-Json
    $savedPlan=Get-Content -LiteralPath (Join-Path $fixtureRoot 'routing-plan.json') -Raw | ConvertFrom-Json
    if ($saved.returnRecording -ne 'Hi-Fi Cable Output' -or $saved.voiceApplication -ne 'Fixture Voice' -or $savedPlan.applied) { throw 'Runner did not persist honest pending route preferences' }
    $null=& (Join-Path $root 'scripts\Invoke-AutomaticSetup.ps1') -DedicatedAccountConfirmed -StateDir $fixtureRoot
    $resumed=Get-Content -LiteralPath (Join-Path $fixtureRoot 'routing-plan.json') -Raw | ConvertFrom-Json
    if ($resumed.status -ne 'ReadyForAgentApplication' -or $resumed.applied) { throw 'Resume lost the route or fabricated application' }
} finally {
    Remove-Item Function:\Get-PnpDevice -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $fixtureRoot) {
        $resolved=[IO.Path]::GetFullPath($fixtureRoot)
        if (-not $resolved.StartsWith([IO.Path]::GetFullPath([IO.Path]::GetTempPath()),[StringComparison]::OrdinalIgnoreCase)) { throw 'Fixture cleanup escaped temp' }
        Remove-Item -LiteralPath $resolved -Recurse -Force
    }
}
'PASS: independent endpoint selection, correct send/return, ambiguity/missing-device refusal, no false applied claim, account prerequisite.'

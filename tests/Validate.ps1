$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'TestHost.ps1')
$root=Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $root 'scripts\Bridge.psm1') -Force
$failures=@()
Get-ChildItem -LiteralPath (Join-Path $root 'scripts') -Filter '*.ps*1' | ForEach-Object {
    $tokens=$null; $errors=$null
    $null=[Management.Automation.Language.Parser]::ParseFile($_.FullName,[ref]$tokens,[ref]$errors)
    if ($errors.Count) { $failures+= $errors }
}
if ($failures.Count) { throw ($failures | Out-String) }
foreach ($entry in @(@('Bootstrap.ps1','-Mode','Prepare'),@('InstallDriver.ps1'),@('InstallPlugin.ps1'))) {
    $blocked=$false
    try {
        if ($entry[0] -eq 'Bootstrap.ps1') { & (Join-Path $root ('scripts\'+$entry[0])) -Mode Prepare }
        else { & (Join-Path $root ('scripts\'+$entry[0])) }
    } catch { $blocked=$_.Exception.Message -match 'dedicated account is currently in use' }
    if (-not $blocked) { throw "Unacknowledged entry point allowed: $($entry[0])" }
}
$cfg=Get-Content -LiteralPath (Join-Path $root 'config\config.example.json') -Raw | ConvertFrom-Json
$empty=[pscustomobject]@{WindowsBuild=19045;DiscordPresent=$false;Endpoints=@();EndpointError=$null}
if (@(Get-BridgePlan $empty).Count -lt 4) { throw 'Missing dependencies not surfaced' }
$empty.EndpointError='denied'
if (-not ((Get-BridgePlan $empty) -match 'unknown')) { throw 'Enumeration failure treated as absence' }
if (@(Test-BridgeConfig $cfg $empty).Count -ne 5) { throw 'Unset configuration accepted' }
$cfg.outboundPlayback='Send In';$cfg.outboundRecording='Send Out';$cfg.returnPlayback='Return In';$cfg.returnRecording='Return Out';$cfg.defaultRecipient='test-recipient'
$ready=[pscustomobject]@{Endpoints=@('Send In','Send Out','Return In','Return Out') | ForEach-Object {[pscustomobject]@{FriendlyName=$_;Status='OK'}}}
if (@(Test-BridgeConfig $cfg $ready).Count) { throw 'Valid independent fixture rejected' }
$cfg.returnRecording='Send Out'
if (-not ((Test-BridgeConfig $cfg $ready) -match 'Voice input')) { throw 'Feedback configuration accepted' }
$scratch=Join-Path ([IO.Path]::GetTempPath()) ('bridge-validation-'+[guid]::NewGuid().ToString('N'))
$null=Initialize-BridgeState $root $scratch
$localConfig=Join-Path $scratch 'config.json'
$before=(Get-FileHash -LiteralPath $localConfig).Hash
$null=Initialize-BridgeState $root $scratch
if ((Get-FileHash -LiteralPath $localConfig).Hash -ne $before) { throw 'Prepare overwrote existing configuration' }
$profileFixture=Join-Path $scratch 'profile with spaces'
$market=Join-Path $profileFixture '.agents\plugins\marketplace.json'
New-Item -ItemType Directory -Path (Split-Path $market) -Force | Out-Null
'{"name":"fixture","interface":{"displayName":"Keep Me"},"plugins":[{"name":"existing","custom":"preserved"}]}' | Set-Content -LiteralPath $market
& (Join-Path $root 'scripts\InstallPlugin.ps1') -DedicatedAccountConfirmed -RegisterOnly -ProfileRoot $profileFixture
$registered=Get-Content -LiteralPath $market -Raw | ConvertFrom-Json
if ($registered.plugins.Count -ne 2 -or $registered.plugins[0].custom -ne 'preserved' -or $registered.interface.displayName -ne 'Keep Me') { throw 'Marketplace preservation failed' }
if (-not (Test-Path -LiteralPath (Join-Path $profileFixture 'plugins\discord-call-bridge\.codex-plugin\plugin.json'))) { throw 'Plugin copy missing manifest' }
# Retry from the destination as documented; preserve the same entry.
& (Join-Path $profileFixture 'plugins\discord-call-bridge\scripts\InstallPlugin.ps1') -DedicatedAccountConfirmed -RegisterOnly -ProfileRoot $profileFixture
if ((Get-Content -LiteralPath $market -Raw | ConvertFrom-Json).plugins.Count -ne 2) { throw 'Retry duplicated marketplace entry' }
# Leave this small isolated fixture for inspection, never recursively delete computed roots.
& (Join-Path $root 'scripts\InstallDriver.ps1') -DedicatedAccountConfirmed -WhatIf
& (Join-Path $root 'scripts\InstallPlugin.ps1') -DedicatedAccountConfirmed -WhatIf
& {
    # Fault injection never downloads or elevates. Exercise the actual helper's boundaries.
    function Invoke-WebRequest { param($Uri,$OutFile,[switch]$UseBasicParsing,$MaximumRedirection) Set-Content -LiteralPath $OutFile -Value 'fixture' }
    function Expand-Archive { param($LiteralPath,$DestinationPath) New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null; Set-Content -LiteralPath (Join-Path $DestinationPath 'VBCABLE_Setup_x64.exe') -Value 'fixture' }
    function Get-AuthenticodeSignature { param($LiteralPath) [pscustomobject]@{Status='Valid';SignerCertificate=[pscustomobject]@{Subject='CN=BUREL VINCENT Entrepreneur individuel, O=fixture'}} }
    function Start-Process { throw (New-Object ComponentModel.Win32Exception(1223)) }
    $cancelled=$false
    try { & (Join-Path $root 'scripts\InstallDriver.ps1') -DedicatedAccountConfirmed -DownloadRoot (Join-Path $scratch 'mock downloads') }
    catch { $cancelled=$_.Exception.Message -match 'cancelled or failed to launch' }
    if (-not $cancelled) { throw 'UAC cancellation did not remain incomplete' }
    if ((Get-Content -LiteralPath (Join-Path $scratch 'mock downloads\VBCable-progress.json') -Raw | ConvertFrom-Json).status -ne 'Cancelled') { throw 'Cancellation progress was lost' }
    function Get-AuthenticodeSignature { param($LiteralPath) [pscustomobject]@{Status='NotSigned';SignerCertificate=$null} }
    $rejected=$false
    try { & (Join-Path $root 'scripts\InstallDriver.ps1') -DedicatedAccountConfirmed -DownloadRoot (Join-Path $scratch 'mock downloads') }
    catch { $rejected=$_.Exception.Message -match 'signature could not be validated' }
    if (-not $rejected) { throw 'Unsigned installer not rejected' }
    if ((Get-Content -LiteralPath (Join-Path $scratch 'mock downloads\VBCable-progress.json') -Raw | ConvertFrom-Json).status -ne 'Failed') { throw 'Signature failure progress was not recorded' }
}
& (Join-Path $root 'scripts\SetupWizard.ps1') -SmokeTest
Write-Output 'PASS: PowerShell syntax; missing/unknown dependencies; unset config; independent routes; feedback rejection; resumable state; installer dry runs; wizard page construction.'

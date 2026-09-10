$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $root 'scripts\Bridge.psm1') -Force
$failures=@()
Get-ChildItem -LiteralPath (Join-Path $root 'scripts') -Filter '*.ps*1' | ForEach-Object {
    $tokens=$null; $errors=$null
    $null=[Management.Automation.Language.Parser]::ParseFile($_.FullName,[ref]$tokens,[ref]$errors)
    if ($errors.Count) { $failures+= $errors }
}
if ($failures.Count) { throw ($failures | Out-String) }
$cfg=Get-Content -LiteralPath (Join-Path $root 'config\config.example.json') -Raw | ConvertFrom-Json
$empty=[pscustomobject]@{WindowsBuild=22631;ObsPresent=$false;DiscordPresent=$false;Endpoints=@();EndpointError=$null}
if (@(Get-BridgePlan $empty).Count -lt 5) { throw 'Missing dependencies not surfaced' }
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
& (Join-Path $root 'scripts\InstallPlugin.ps1') -RegisterOnly -ProfileRoot $profileFixture
$registered=Get-Content -LiteralPath $market -Raw | ConvertFrom-Json
if ($registered.plugins.Count -ne 2 -or $registered.plugins[0].custom -ne 'preserved' -or $registered.interface.displayName -ne 'Keep Me') { throw 'Marketplace preservation failed' }
if (-not (Test-Path -LiteralPath (Join-Path $profileFixture 'plugins\discord-call-bridge\.codex-plugin\plugin.json'))) { throw 'Plugin copy missing manifest' }
# Retry from the destination as documented; preserve the same entry.
& (Join-Path $profileFixture 'plugins\discord-call-bridge\scripts\InstallPlugin.ps1') -RegisterOnly -ProfileRoot $profileFixture
if ((Get-Content -LiteralPath $market -Raw | ConvertFrom-Json).plugins.Count -ne 2) { throw 'Retry duplicated marketplace entry' }
# Leave this small isolated fixture for inspection, never recursively delete computed roots.
& (Join-Path $root 'scripts\InstallDriver.ps1') -WhatIf
& (Join-Path $root 'scripts\InstallPlugin.ps1') -WhatIf
& {
    # Fault injection never downloads or elevates. Exercise the actual helper's boundaries.
    function Invoke-WebRequest { param($Uri,$OutFile,[switch]$UseBasicParsing,$MaximumRedirection) Set-Content -LiteralPath $OutFile -Value 'fixture' }
    function Expand-Archive { param($LiteralPath,$DestinationPath) New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null; Set-Content -LiteralPath (Join-Path $DestinationPath 'VBCABLE_Setup_x64.exe') -Value 'fixture' }
    function Get-AuthenticodeSignature { param($LiteralPath) [pscustomobject]@{Status='Valid';SignerCertificate=[pscustomobject]@{Subject='CN=BUREL VINCENT Entrepreneur individuel, O=fixture'}} }
    function Start-Process { throw (New-Object ComponentModel.Win32Exception(1223)) }
    $cancelled=$false
    try { & (Join-Path $root 'scripts\InstallDriver.ps1') -DownloadRoot (Join-Path $scratch 'mock downloads') }
    catch { $cancelled=$_.Exception.Message -match 'cancelled or failed to launch' }
    if (-not $cancelled) { throw 'UAC cancellation did not remain incomplete' }
    function Get-AuthenticodeSignature { param($LiteralPath) [pscustomobject]@{Status='NotSigned';SignerCertificate=$null} }
    $rejected=$false
    try { & (Join-Path $root 'scripts\InstallDriver.ps1') -DownloadRoot (Join-Path $scratch 'mock downloads') }
    catch { $rejected=$_.Exception.Message -match 'signature could not be validated' }
    if (-not $rejected) { throw 'Unsigned installer not rejected' }
}
& (Join-Path $root 'scripts\SetupWizard.ps1') -SmokeTest
Write-Output 'PASS: PowerShell syntax; missing/unknown dependencies; unset config; independent routes; feedback rejection; resumable state; installer dry runs; wizard page construction.'

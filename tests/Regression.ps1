$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'TestHost.ps1')
$root=Split-Path $PSScriptRoot -Parent
$scratch=Join-Path ([IO.Path]::GetTempPath()) ('bridge-regression-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $scratch | Out-Null
$failures=New-Object 'System.Collections.Generic.List[string]'
try {
    $profile=Join-Path $scratch 'profile with spaces'
    & (Join-Path $root 'scripts\InstallPlugin.ps1') -DedicatedAccountConfirmed -RegisterOnly -ProfileRoot $profile | Out-Null
    $target=Join-Path $profile 'plugins\discord-call-bridge'
    Set-Content -LiteralPath (Join-Path $target 'keep-local.txt') -Value 'preserve me'
    # A second extracted-package install must update safely without manual rename.
    & (Join-Path $root 'scripts\InstallPlugin.ps1') -DedicatedAccountConfirmed -RegisterOnly -ProfileRoot $profile | Out-Null
    $backups=@(Get-ChildItem -LiteralPath (Join-Path $profile 'plugins\discord-call-bridge-backups') -Directory)
    if ($backups.Count -ne 1 -or (Get-Content -LiteralPath (Join-Path $backups[0].FullName 'keep-local.txt')) -ne 'preserve me') { throw 'Prior source not preserved in scoped backup' }
    if ((Get-Content -LiteralPath (Join-Path $profile '.agents\plugins\marketplace.json') -Raw | ConvertFrom-Json).plugins.Count -ne 1) { throw 'Duplicate marketplace entry' }
} catch { $failures.Add('Update: '+$_.Exception.Message) }
try { & {
    function Invoke-WebRequest { param($Uri,$OutFile,[switch]$UseBasicParsing,$MaximumRedirection) Set-Content -LiteralPath $OutFile -Value 'fixture' }
    function Expand-Archive { param($LiteralPath,$DestinationPath) New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null; Set-Content -LiteralPath (Join-Path $DestinationPath 'VBCABLE_Setup_x64.exe') -Value 'fixture' }
    function Get-AuthenticodeSignature { param($LiteralPath) [pscustomobject]@{Status='Valid';SignerCertificate=[pscustomobject]@{Subject='CN=BUREL VINCENT Entrepreneur individuel, O=fixture'}} }
    function Start-Process {
        param($FilePath,$WorkingDirectory,$Verb,$WindowStyle,[switch]$PassThru,[switch]$Wait)
        if ($WindowStyle -ne 'Normal' -or $Verb -ne 'RunAs') { throw 'Interactive driver did not receive visible UAC handoff' }
        function global:Get-PnpDevice { param($Class,[switch]$PresentOnly,$ErrorAction) return @() }
        $p=[pscustomobject]@{ExitCode=0;Id=1}; $p | Add-Member ScriptMethod WaitForExit {}; return $p
    }
    & (Join-Path $root 'scripts\InstallDriver.ps1') -DedicatedAccountConfirmed -DownloadRoot (Join-Path $scratch 'downloads') | Out-Null
    Remove-Item Function:\Get-PnpDevice
    $progress=Get-Content -LiteralPath (Join-Path $scratch 'downloads\VBCable-progress.json') -Raw | ConvertFrom-Json
    if ($progress.status -ne 'RestartRequired') { throw 'Exit zero without endpoints was incorrectly treated as device readiness' }
} } catch { $failures.Add('Driver: '+$_.Exception.Message) }
try {
    Import-Module (Join-Path $root 'scripts\Bridge.psm1') -Force
    & (Get-Module Bridge) {
        param($scratch)
        $script:runningFixture=Join-Path $scratch 'active\Discord.exe'
        $script:olderFixture=Join-Path $scratch 'inactive\Discord.exe'
        foreach ($p in @($script:runningFixture,$script:olderFixture)) { New-Item -ItemType Directory -Path (Split-Path $p) -Force | Out-Null; Set-Content -LiteralPath $p -Value 'fixture' }
        function Get-Process { param($Name,$ErrorAction) if ($Name -eq 'Discord') { [pscustomobject]@{Path=$script:runningFixture} } }
        function Get-ChildItem { param($Path,$ErrorAction) if ($Path -like '*Discord*') { Get-Item -LiteralPath $script:olderFixture } }
        $inventory=Get-BridgeInventory -ConfigPath (Join-Path $scratch 'absent.json')
        if (-not $inventory.PSObject.Properties['DiscordExecutable'] -or $inventory.DiscordExecutable -ne $script:runningFixture) { throw 'Inventory did not prioritize running Discord executable' }
    } $scratch
} catch { $failures.Add('Inventory: '+$_.Exception.Message) }
if ($failures.Count) { throw ($failures -join "`n") }
'PASS: repeated extracted-package update, scoped backup, visible driver handoff/status, active Discord detection.'

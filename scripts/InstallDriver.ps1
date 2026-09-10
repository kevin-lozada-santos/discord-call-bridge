[CmdletBinding(SupportsShouldProcess)]
param([switch]$DedicatedAccountConfirmed, [ValidateSet('VBCable','HiFiCable')][string]$Driver = 'VBCable', [switch]$DownloadOnly,
    [string]$DownloadRoot = (Join-Path $env:LOCALAPPDATA 'DiscordCallBridge\downloads'))
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Bridge.psm1') -Force
Assert-DedicatedAccount $DedicatedAccountConfirmed.IsPresent
if ($Driver -eq 'VBCable') {
    $uri = 'https://download.vb-audio.com/Download_CABLE/VBCABLE_Driver_Pack45.zip'
    $name = 'VBCABLE_Driver_Pack45.zip'
} else {
    $uri = 'https://download.vb-audio.com/Download_CABLE/HiFiCableAsioBridgeSetup_v1007.zip'
    $name = 'HiFiCableAsioBridgeSetup_v1007.zip'
}
if (-not $PSCmdlet.ShouldProcess($uri, 'Download, verify, and request UAC for selected vendor driver installer')) { return }
Save-BridgeProgress $DownloadRoot $Driver 'Downloading' 'Downloading official vendor package; no installation yet.'
try {
$work = Join-Path $DownloadRoot ([guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $work -Force | Out-Null
$archive = Join-Path $work $name
Invoke-WebRequest -Uri $uri -OutFile $archive -UseBasicParsing -MaximumRedirection 0
Expand-Archive -LiteralPath $archive -DestinationPath (Join-Path $work 'extracted')
$setups = @(Get-ChildItem -LiteralPath (Join-Path $work 'extracted') -Recurse -Filter '*.exe' | Where-Object { $_.Name -match 'Setup' })
if ($Driver -eq 'VBCable') {
    $setups = @($setups | Where-Object { $_.Name -eq 'VBCABLE_Setup_x64.exe' })
    if ($env:PROCESSOR_ARCHITECTURE -ne 'AMD64') { throw 'Automatic driver selection supports x64 only. Use the vendor architecture-specific installer manually.' }
}
if ($setups.Count -ne 1) { throw 'Could not identify exactly one supported installer. Review official package manually; nothing elevated.' }
$exe = $setups[0].FullName
$sig = Get-AuthenticodeSignature -LiteralPath $exe
if ($sig.Status -ne 'Valid' -or $sig.SignerCertificate.Subject -notmatch 'CN=(BUREL VINCENT Entrepreneur individuel|Vincent Burel)(,|$)') { throw 'Vendor signature could not be validated. No elevation. Review the official vendor package and certificate; do not bypass verification.' }
$hash = (Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash
[pscustomobject]@{Driver=$Driver;Sha256=$hash;Signer=$sig.SignerCertificate.Subject;State='Verified download; installation not confirmed'} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $work 'receipt.json') -Encoding UTF8
Save-BridgeProgress $DownloadRoot $Driver 'Downloaded' 'Official installer signature verified; not installed.'
if ($DownloadOnly) { Write-Output "Verified installer prepared at $exe"; return }
try {
    # Elevate only the signed vendor installer. No shell command or user argument is elevated.
    Save-BridgeProgress $DownloadRoot $Driver 'AwaitingUac' 'Approve or cancel Windows UAC yourself; the vendor installer will be visible.'
    $process = Start-Process -FilePath $exe -WorkingDirectory $setups[0].DirectoryName -Verb RunAs -WindowStyle Normal -PassThru
    Save-BridgeProgress $DownloadRoot $Driver 'Pending' 'Installer launched. Complete its visible steps; a running process does not prove installation. Do not launch a duplicate.'
    Write-Output 'Complete the visible vendor installer. If it has no usable window, setup remains pending; inspect the vendor process before retrying. No audio success is assumed.'
    $process.WaitForExit()
} catch {
    $cancelled=$_.Exception.NativeErrorCode -eq 1223 -or ($_.Exception.InnerException -and $_.Exception.InnerException.NativeErrorCode -eq 1223)
    Save-BridgeProgress $DownloadRoot $Driver $(if ($cancelled) {'Cancelled'} else {'Failed'}) $_.Exception.Message
    throw "Driver installer cancelled or failed to launch; partial setup preserved. $($_.Exception.Message)"
}
if ($process.ExitCode -notin @(0,3010)) {
    Save-BridgeProgress $DownloadRoot $Driver 'Failed' "Vendor installer exited $($process.ExitCode)."
    throw 'Driver installer did not report success; inspect vendor result and run Detect again.'
}
$inventory=Get-BridgeInventory
$status=if ($process.ExitCode -eq 3010) {'RestartRequired'} elseif (Test-BridgeDriverEndpoints $Driver $inventory) {'DevicesDetected'} else {'RestartRequired'}
Save-BridgeProgress $DownloadRoot $Driver $status "Installer exited $($process.ExitCode). Both enabled endpoints detected: $(Test-BridgeDriverEndpoints $Driver $inventory). Vendor requires restart; save work and restart yourself, then Detect. Audio remains untested."
Write-Output "$status. Installer exit alone is not readiness. Save work and perform the vendor-required restart yourself, reopen Setup.cmd, confirm the dedicated account and run Detect. No automatic reboot or startup task created."
} catch {
    $progressPath=Join-Path $DownloadRoot ($Driver+'-progress.json')
    $current=if (Test-Path -LiteralPath $progressPath) { (Get-Content -LiteralPath $progressPath -Raw | ConvertFrom-Json).status } else { '' }
    if ($current -ne 'Cancelled') { Save-BridgeProgress $DownloadRoot $Driver 'Failed' $_.Exception.Message }
    throw
}

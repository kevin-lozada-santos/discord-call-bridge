[CmdletBinding(SupportsShouldProcess)]
param([ValidateSet('VBCable','HiFiCable')][string]$Driver = 'VBCable', [switch]$DownloadOnly,
    [string]$DownloadRoot = (Join-Path $env:LOCALAPPDATA 'DiscordCallBridge\downloads'))
$ErrorActionPreference = 'Stop'
if ($Driver -eq 'VBCable') {
    $uri = 'https://download.vb-audio.com/Download_CABLE/VBCABLE_Driver_Pack45.zip'
    $name = 'VBCABLE_Driver_Pack45.zip'
} else {
    $uri = 'https://download.vb-audio.com/Download_CABLE/HiFiCableAsioBridgeSetup_v1007.zip'
    $name = 'HiFiCableAsioBridgeSetup_v1007.zip'
}
if (-not $PSCmdlet.ShouldProcess($uri, 'Download, verify, and request UAC for selected vendor driver installer')) { return }
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
if ($DownloadOnly) { Write-Output "Verified installer prepared at $exe"; return }
try {
    # Elevate only the signed vendor installer. No shell command or user argument is elevated.
    $process = Start-Process -FilePath $exe -WorkingDirectory $setups[0].DirectoryName -Verb RunAs -WindowStyle Hidden -PassThru -Wait
} catch { throw "Driver installer cancelled or failed to launch; partial setup preserved. $($_.Exception.Message)" }
Write-Output "Installer exited $($process.ExitCode). This is not proof of device readiness. Save work and perform the vendor-required restart yourself, then reopen Setup.cmd and run Detect. No automatic reboot or startup task was created."
if ($process.ExitCode -notin @(0,3010)) { throw 'Driver installer did not report success; inspect vendor result and run Detect again.' }

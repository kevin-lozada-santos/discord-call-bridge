[CmdletBinding(SupportsShouldProcess)]
param([switch]$RegisterOnly, [string]$ProfileRoot = $env:USERPROFILE)
$ErrorActionPreference = 'Stop'
$source = Split-Path $PSScriptRoot -Parent
$target = Join-Path $ProfileRoot 'plugins\discord-call-bridge'
$market = Join-Path $ProfileRoot '.agents\plugins\marketplace.json'
if (-not $PSCmdlet.ShouldProcess($target, 'Copy plugin, append personal marketplace entry, and install unless RegisterOnly')) { return }
if (([IO.Path]::GetFullPath($source)) -ne ([IO.Path]::GetFullPath($target))) {
    if (Test-Path -LiteralPath $target) { throw 'Destination exists. Preserve it: rename the existing plugin folder as a backup before installing this version.' }
    New-Item -ItemType Directory -Path $target -Force | Out-Null
    Get-ChildItem -LiteralPath $source -Force | Where-Object { $_.Name -notin @('.git','dist','local') } | Copy-Item -Destination $target -Recurse -Force
}
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
New-Item -ItemType Directory -Path (Split-Path $market) -Force | Out-Null
$temp = $market+'.'+[guid]::NewGuid().ToString('N')+'.tmp'
$data | ConvertTo-Json -Depth 40 | Set-Content -LiteralPath $temp -Encoding UTF8
Move-Item -LiteralPath $temp -Destination $market -Force
if (-not $RegisterOnly) {
    if (-not (Get-Command codex -ErrorAction SilentlyContinue)) { throw "Registered but not installed: Codex CLI unavailable. Open plugin browser and select the personal discord-call-bridge entry, or install a supported Codex CLI then rerun from $target." }
    & codex plugin add ('discord-call-bridge@'+$data.name) --json
    if ($LASTEXITCODE -ne 0) { throw 'Plugin registration preserved; installation failed. Inspect Codex output, then retry from the destination folder.' }
}
Write-Output 'Plugin registration complete. Start a NEW Codex task and request the discord-call skill. Audio and Voice still require acceptance testing.'

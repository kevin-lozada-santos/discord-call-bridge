Set-StrictMode -Version Latest
function Get-BridgeInventory {
    param([string]$ConfigPath = (Join-Path $env:LOCALAPPDATA 'DiscordCallBridge\config.json'))
    $cfg = $null
    if (Test-Path -LiteralPath $ConfigPath) { $cfg = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json }
    $obs = Join-Path $env:ProgramFiles 'obs-studio\bin\64bit\obs64.exe'
    if ($cfg -and $cfg.obsExecutable) { $obs = $cfg.obsExecutable }
    $discord = @(Get-ChildItem -Path (Join-Path $env:LOCALAPPDATA 'Discord\app-*\Discord.exe') -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1)
    if ($cfg -and $cfg.discordExecutable) { $discord = @(Get-Item -LiteralPath $cfg.discordExecutable -ErrorAction SilentlyContinue) }
    $endpointError = $null
    try { $endpoints = @(Get-PnpDevice -Class AudioEndpoint -PresentOnly -ErrorAction Stop | Select-Object FriendlyName,Status,InstanceId) }
    catch { $endpoints = @(); $endpointError = $_.Exception.Message }
    $obsVersion = $null
    if (Test-Path -LiteralPath $obs) { $obsVersion = (Get-Item -LiteralPath $obs).VersionInfo.ProductVersion }
    [pscustomobject]@{
        WindowsBuild = [Environment]::OSVersion.Version.Build
        Architecture = $env:PROCESSOR_ARCHITECTURE
        ObsPresent = (Test-Path -LiteralPath $obs)
        ObsVersion = $obsVersion
        DiscordPresent = ($discord.Count -gt 0)
        DiscordVersion = $(if ($discord.Count) { $discord[0].VersionInfo.ProductVersion } else { $null })
        WingetPresent = [bool](Get-Command winget -ErrorAction SilentlyContinue)
        CodexCliPresent = [bool](Get-Command codex -ErrorAction SilentlyContinue)
        Endpoints = $endpoints
        EndpointError = $endpointError
        VoiceAvailability = 'Requires in-app verification'
        SignalFlow = 'Not tested by inventory'
    }
}
function Get-BridgePlan {
    param($Inventory)
    $steps = @()
    if ($Inventory.WindowsBuild -lt 19041) { $steps += 'Unsupported Windows build for application capture: update Windows manually.' }
    if (-not $Inventory.ObsPresent) { $steps += 'OBS not found at configured/default path: locate custom install or install OBSProject.OBSStudio.' }
    if (-not $Inventory.DiscordPresent) { $steps += 'Discord not found: locate custom install or install Discord.Discord.' }
    if ($Inventory.EndpointError) { $steps += 'Audio enumeration unknown: resolve error before installing drivers.' }
    else {
        $names=@($Inventory.Endpoints | ForEach-Object { $_.FriendlyName })
        if (-not ($names -match '^CABLE Input|^Speakers \(VB-Audio Virtual Cable\)')) { $steps += 'Outbound cable missing or differently named: verify existing cable before VB-CABLE install.' }
        if (-not ($names -match 'Hi-Fi Cable Input|^Speakers \(VB-Audio Hi-Fi Cable\)')) { $steps += 'Return cable missing or differently named: select a separate compatible cable; Hi-Fi compatibility needs vendor/user review.' }
    }
    $steps += 'Configure isolated OBS profile, Discord and Voice input; verify intelligible two-way audio manually/in supported UI.'
    return $steps
}
function Initialize-BridgeState {
    param([string]$Root, [string]$StateDir = (Join-Path $env:LOCALAPPDATA 'DiscordCallBridge'))
    New-Item -ItemType Directory -Path $StateDir -Force | Out-Null
    foreach ($pair in @(@('config.example.json','config.json'),@('previous-settings.example.json','previous-settings.json'))) {
        $target = Join-Path $StateDir $pair[1]
        if (-not (Test-Path -LiteralPath $target)) { Copy-Item -LiteralPath (Join-Path $Root ('config\'+$pair[0])) -Destination $target }
    }
    return $StateDir
}
function Test-BridgeConfig {
    param($Config, $Inventory)
    $issues = @()
    foreach ($field in @('outboundPlayback','outboundRecording','returnPlayback','returnRecording')) {
        if (-not $Config.$field) { $issues += "$field is unset" }
        elseif (-not (@($Inventory.Endpoints | Where-Object { $_.FriendlyName -eq $Config.$field -and $_.Status -eq 'OK' }).Count)) { $issues += "$field does not match an enabled endpoint" }
    }
    if ($Config.outboundPlayback -and $Config.outboundPlayback -eq $Config.returnPlayback) { $issues += 'Send and return playback must use independent cables' }
    if ($Config.outboundRecording -and $Config.outboundRecording -eq $Config.returnRecording) { $issues += 'Voice input cannot be the outbound recording endpoint' }
    if (-not $Config.defaultRecipient) { $issues += 'Recipient unset: ask before dialing' }
    return $issues
}
Export-ModuleMember -Function Get-BridgeInventory,Get-BridgePlan,Initialize-BridgeState,Test-BridgeConfig

function Get-DedicatedAccountWarning {
    return 'Use a separate Discord account dedicated to ChatGPT/Codex. Do not use your personal or main Discord account for this bridge. Set up and sign in to the dedicated account before continuing.'
}
function Assert-DedicatedAccount {
    param([bool]$Confirmed = $false)
    if (-not $Confirmed) { throw ((Get-DedicatedAccountWarning) + ' Explicitly confirm that the dedicated account is currently in use. For CLI setup, pass -DedicatedAccountConfirmed only after making that confirmation.') }
}
Export-ModuleMember -Function Get-DedicatedAccountWarning,Assert-DedicatedAccount

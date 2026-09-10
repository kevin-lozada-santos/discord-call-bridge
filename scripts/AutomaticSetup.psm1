Set-StrictMode -Version Latest
function Get-AutomaticRoutePlan {
    param($Inventory,$Config)
    $problems=New-Object 'System.Collections.Generic.List[string]'
    $selected=[ordered]@{}
    $patterns=[ordered]@{
        outboundPlayback='^(CABLE Input|Speakers \(VB-Audio Virtual Cable\))'
        outboundRecording='^CABLE Output'
        returnPlayback='^(Hi-Fi Cable Input|Speakers \(VB-Audio Hi-Fi Cable\))'
        returnRecording='^Hi-Fi Cable Output'
    }
    if ($Inventory.EndpointError) { $problems.Add('Endpoint enumeration failed: '+$Inventory.EndpointError) }
    foreach ($field in $patterns.Keys) {
        $configured=$Config.$field
        $matches=@($Inventory.Endpoints | Where-Object {
            $_.Status -eq 'OK' -and $(if ($configured) { $_.FriendlyName -eq $configured } else { $_.FriendlyName -match $patterns[$field] })
        })
        if ($matches.Count -eq 1) { $selected[$field]=$matches[0].FriendlyName }
        else { $selected[$field]=$null; $problems.Add("$field has $($matches.Count) eligible endpoints; detect/install missing devices or resolve ambiguity before applying routes.") }
    }
    if ($selected.outboundPlayback -and $selected.outboundPlayback -eq $selected.returnPlayback) { $problems.Add('Outbound and return must use independent playback endpoints.') }
    if ($selected.outboundRecording -and $selected.outboundRecording -eq $selected.returnRecording) { $problems.Add('Outbound and return must use independent recording endpoints.') }
    if (-not $Config.voiceApplication) { $problems.Add('Voice application is unknown: Codex must identify the actual Voice-producing application before capture.') }
    $actions=@()
    if (-not $problems.Count) {
        $actions=@(
            [pscustomobject]@{id='preserve';surface='OBS/Discord/Voice';action='Read and save the actual original profile, collection, devices, mute and monitoring settings before changing them.'},
            [pscustomobject]@{id='obs';surface='OBS';action="Create/select isolated profile and scene collection; capture ONLY $($Config.voiceApplication); exclude Discord/desktop/microphone audio; monitor to $($selected.outboundPlayback), enable monitoring and unmute source."},
            [pscustomobject]@{id='discord';surface='Discord';action="Set microphone to $($selected.outboundRecording) and playback to $($selected.returnPlayback). Verify actual selected devices; do not dial during setup."},
            [pscustomobject]@{id='voice';surface='Voice';action="Start/reuse actual Voice and select $($selected.returnRecording) as its input. Verify actual listening/speaking; do not use Dictate or the outbound recording endpoint."},
            [pscustomobject]@{id='test';surface='OBS/Discord/Voice';action='Verify source playback, monitoring, intelligible mic test and no echo. Stop mic test. A call requires explicit call authorization; confirm remote hearing and inbound speech separately.'}
        )
    }
    [pscustomobject]@{status=$(if ($problems.Count) {'NeedsPreparation'} else {'ReadyForAgentApplication'});applied=$false;selected=$selected;blockers=@($problems);actions=$actions}
}
Export-ModuleMember -Function Get-AutomaticRoutePlan

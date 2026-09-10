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
    if (-not $Config.voiceApplication) { $problems.Add('Voice application is unknown: Codex must identify the actual Voice-producing application before routing.') }
    $actions=@()
    if (-not $problems.Count) {
        $actions=@(
            [pscustomobject]@{id='preserve';surface='Windows/Discord/Voice';action='Read and save the actual per-app playback/input devices, volume, mute and Windows Listen settings before changing them.'},
            [pscustomobject]@{id='output';surface='Windows Volume mixer';action="Set ONLY $($Config.voiceApplication) playback to $($selected.outboundPlayback) using per-app or in-app output selection. Preserve the system default. Exclude unrelated audio from this app and keep Discord on the separate return device. Read back the selected output."},
            [pscustomobject]@{id='discord';surface='Discord';action="Set microphone to $($selected.outboundRecording) and playback to $($selected.returnPlayback). Verify actual selected devices; do not dial during setup."},
            [pscustomobject]@{id='voice';surface='Voice';action="Start/reuse actual Voice and select $($selected.returnRecording) as its input. Verify actual listening/speaking; do not use Dictate or the outbound recording endpoint."},
            [pscustomobject]@{id='test';surface='Windows/Discord/Voice';action='Verify actual Voice playback, intelligible mic test and no echo. Stop mic test. A call requires explicit call authorization; confirm remote hearing and inbound speech separately.'}
        )
    }
    [pscustomobject]@{status=$(if ($problems.Count) {'NeedsPreparation'} else {'ReadyForAgentApplication'});applied=$false;selected=$selected;blockers=@($problems);actions=$actions}
}
Export-ModuleMember -Function Get-AutomaticRoutePlan

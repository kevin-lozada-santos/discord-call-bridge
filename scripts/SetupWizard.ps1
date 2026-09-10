[CmdletBinding()]
param([switch]$SmokeTest, [string]$SmokeImageDirectory)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Import-Module (Join-Path $PSScriptRoot 'Bridge.psm1') -Force
$root = Split-Path $PSScriptRoot -Parent
$stateDir = Join-Path $env:LOCALAPPDATA 'DiscordCallBridge'
$form = New-Object Windows.Forms.Form
$form.Text = 'Discord Call Bridge - Setup'
$form.Size = New-Object Drawing.Size(900,720)
$form.MinimumSize = New-Object Drawing.Size(900,720)
$form.StartPosition = 'CenterScreen'
$tabs = New-Object Windows.Forms.TabControl
$tabs.Dock = 'Fill'
$form.Controls.Add($tabs)
$pages = @{}
foreach ($name in @('0 Dedicated account','1 Detect','2 Install','3 Configure','4 Verify','5 Finish / Restore')) {
    $page = New-Object Windows.Forms.TabPage
    $page.Text = $name
    $tabs.TabPages.Add($page)
    $pages[$name] = $page
}
function Add-Text($page,$text,$top,$height=70) {
    $box = New-Object Windows.Forms.TextBox
    $box.Multiline=$true; $box.ReadOnly=$true; $box.ScrollBars='Vertical'
    $box.Text=($text -replace "`r?`n","`r`n"); $box.SetBounds(15,$top,830,$height); $page.Controls.Add($box)
    return $box
}
function Add-Button($page,$text,$top,$action) {
    $button=New-Object Windows.Forms.Button
    $button.Text=$text; $button.SetBounds(15,$top,390,32)
    $button.Add_Click($action); $page.Controls.Add($button)
    return $button
}
$accountPage = $pages['0 Dedicated account']
$null=Add-Text $accountPage (Get-DedicatedAccountWarning) 25 100
$accountCheck=New-Object Windows.Forms.CheckBox
$accountCheck.Text='I confirm I am signed in to a separate Discord account dedicated to ChatGPT/Codex.'
$accountCheck.SetBounds(15,150,830,50)
$accountPage.Controls.Add($accountCheck)
$null=Add-Text $accountPage 'Setup stays locked until you confirm the dedicated account is in use. This confirmation applies to this wizard session only. This wizard does not create accounts, switch accounts, or inspect credentials. Close it if you need to set up the account first. After confirming, use any relevant page; the agent can perform setup without following these tabs.' 220 110
$null=Add-Text $accountPage 'Prefer agent-led setup: ask Codex to act as your setup wizard and technical expert, choose supported methods, configure and troubleshoot, and verify the result. These pages and scripts are optional aids. Only the dedicated-account acknowledgement and actual user-controlled boundaries require your action.' 350 120
$tabs.Add_Selecting({ param($sender,$eventArgs)
    if ($eventArgs.TabPage -ne $accountPage -and -not $accountCheck.Checked) { $eventArgs.Cancel=$true }
})
$accountCheck.Add_CheckedChanged({
    foreach ($page in $tabs.TabPages) { if ($page -ne $accountPage) { $page.Enabled=$accountCheck.Checked } }
    if (-not $accountCheck.Checked) { $tabs.SelectedTab=$accountPage }
})
foreach ($page in $tabs.TabPages) { if ($page -ne $accountPage) { $page.Enabled=$false } }
function Show-Failure($err) { [Windows.Forms.MessageBox]::Show([string]$err,'Setup incomplete') | Out-Null }
$script:helperProcesses=@{}
function Run-Helper($file,$arguments='') {
    # Only fixed helper names and fixed mode arguments are supplied by wizard buttons.
    Assert-DedicatedAccount $accountCheck.Checked
    if ($script:helperProcesses.ContainsKey($file) -and -not $script:helperProcesses[$file].HasExited) {
        [Windows.Forms.MessageBox]::Show('An installer console for this step is still open. Complete or cancel it and close its console before retrying. Detect / saved progress shows current evidence.','Step still open') | Out-Null; return
    }
    $arguments += ' -DedicatedAccountConfirmed'
    $helper=Join-Path $PSScriptRoot $file
    $proc=Start-Process -FilePath 'powershell.exe' -ArgumentList ('-NoProfile -ExecutionPolicy Bypass -NoExit -File "'+$helper+'" '+$arguments) -PassThru
    $script:helperProcesses[$file]=$proc
    $null=$proc # Visible interactive installer/status console deliberately requested by wizard action.
}
$null=Add-Text $pages['1 Detect'] 'Optional read-only inventory. Codex can drive setup using supported tools; these buttons are conveniences, not required steps. Do not configure while a call/recording/stream is active. Detect is read-only; presence is not audio proof.' 15
$inventoryBox=Add-Text $pages['1 Detect'] 'Click Detect to inspect installed apps, versions and audio endpoints.' 135 445
$null=Add-Button $pages['1 Detect'] 'Detect / refresh (read-only)' 95 {
    try { $script:inventory=Get-BridgeInventory; $inventoryBox.Text=([pscustomobject]@{Inventory=$script:inventory;HostPreflight='Before installation: can the host capture and control native apps, or provide a working screenshot-based Computer Use substitute? Can you start actual Voice and select its input? If unavailable, investigate other supported methods and complete independent setup; hand off only the specific inaccessible action. Software presence does not prove control capability.';Next=@(Get-BridgePlan $script:inventory)} | ConvertTo-Json -Depth 8) } catch { Show-Failure $_ }
}
$null=Add-Text $pages['2 Install'] 'Reuse existing software. If Detect missed a custom install, enter its executable path in config.json before installing. App installs use WinGet official vendor packages with hash checks. Driver buttons download signed vendor packages and request UAC only for the installer. Review vendor terms first. After any required reboot, reopen this wizard and Detect again.' 15 105
$null=Add-Button $pages['2 Install'] 'Install missing OBS / Discord apps' 140 { Run-Helper 'Bootstrap.ps1' '-Mode InstallApps' }
$null=Add-Button $pages['2 Install'] 'Install outbound VB-CABLE (UAC)' 185 { Run-Helper 'InstallDriver.ps1' '-Driver VBCable' }
$null=Add-Button $pages['2 Install'] 'Install return Hi-Fi Cable (UAC)' 230 {
    if ([Windows.Forms.MessageBox]::Show('Hi-Fi Cable is an older vendor package. Confirm vendor compatibility and terms for this machine. Existing compatible independent cables can be used instead. Continue?','Review driver','YesNo') -eq 'Yes') { Run-Helper 'InstallDriver.ps1' '-Driver HiFiCable' }
}
$null=Add-Button $pages['2 Install'] 'Vendor cable requirements / licensing' 275 { Start-Process 'https://vb-audio.com/Cable/' }
$null=Add-Button $pages['2 Install'] 'Codex download / account setup' 320 { Start-Process 'https://chatgpt.com/codex' }
$null=Add-Button $pages['2 Install'] 'Install plugin into Codex' 365 { Run-Helper 'InstallPlugin.ps1' }
$null=Add-Text $pages['2 Install'] 'Install consoles show progress, cancellation and failures. Finish there, then return to Detect. The wizard never approves UAC, accepts paid purchases, changes login credentials, or restarts Windows. Old/unsigned driver packages fail closed. Cancelled or failed steps remain incomplete.' 415 130
$null=Add-Text $pages['3 Configure'] 'Create local configuration, then record previous settings BEFORE changing audio. Set recipient explicitly (blank means ask each call). Select independent playback/recording pairs in the configuration file. This wizard saves preferences; Codex should apply routes using supported controls or another suitable design. The guide is advice, not a manual-only requirement.' 15 85
$recipient=New-Object Windows.Forms.TextBox
$recipient.SetBounds(15,110,600,28); $pages['3 Configure'].Controls.Add($recipient)
if (Test-Path -LiteralPath (Join-Path $stateDir 'config.json')) {
    try { $recipient.Text=(Get-Content -LiteralPath (Join-Path $stateDir 'config.json') -Raw | ConvertFrom-Json).defaultRecipient } catch { Show-Failure $_ }
}
$null=Add-Button $pages['3 Configure'] 'Save recipient / create local templates' 150 {
    try {
        $null=Initialize-BridgeState $root
        $path=Join-Path $stateDir 'config.json'
        $cfg=Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
        $cfg.defaultRecipient=$(if ($recipient.Text.Trim()) {$recipient.Text.Trim()} else {$null})
        $cfg | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $path -Encoding UTF8
        [Windows.Forms.MessageBox]::Show('Saved locally. This preference does not authorize a call.','Saved') | Out-Null
    } catch { Show-Failure $_ }
}
$null=Add-Button $pages['3 Configure'] 'Record previous settings (restore sheet)' 195 {
    try { $null=Initialize-BridgeState $root; Start-Process notepad.exe -ArgumentList ('"'+(Join-Path $stateDir 'previous-settings.json')+'"') } catch { Show-Failure $_ }
}
$null=Add-Button $pages['3 Configure'] 'Edit device preferences / custom app paths' 240 {
    try { $null=Initialize-BridgeState $root; Start-Process notepad.exe -ArgumentList ('"'+(Join-Path $stateDir 'config.json')+'"') } catch { Show-Failure $_ }
}
$routing=Get-Content -LiteralPath (Join-Path $root 'skills\discord-call\references\windows-routing.md') -Raw
$null=Add-Text $pages['3 Configure'] $routing 290 295
$verifyBox=Add-Text $pages['4 Verify'] 'Refresh configured endpoint checks, then complete the acceptance stages below. Checks cannot verify actual OBS/Discord settings or sound.' 65 180
$null=Add-Button $pages['4 Verify'] 'Check configuration against devices' 15 {
    try {
        $cfg=Get-Content -LiteralPath (Join-Path $stateDir 'config.json') -Raw | ConvertFrom-Json
        $issues=@(Test-BridgeConfig $cfg (Get-BridgeInventory))
        $verifyBox.Text=$(if($issues.Count){$issues -join "`r`n"}else{'Configured names match present endpoints. Signal flow remains untested.'})
    } catch { Show-Failure $_ }
}
$script:checks=@()
$labels=@('New Codex task loaded the plugin skill','Voice active and produces speech','Isolated route configured; no echo/unrelated sound','Local Discord mic test intelligible; mic test stopped','Requested Discord destination connected','Participant confirmed hearing assistant speech','Fresh participant speech reached Voice; relevant reply heard','Discord disconnected AND associated Voice ended')
for ($i=0;$i -lt $labels.Count;$i++) {
    $check=New-Object Windows.Forms.CheckBox; $check.Text=$labels[$i]
    $check.SetBounds(15,(255+$i*35),830,30); $pages['4 Verify'].Controls.Add($check); $script:checks+= $check
}
$finishBox=Add-Text $pages['5 Finish / Restore'] 'Acceptance has not been recorded. Finish records user attestations, not automatic audio measurements. Recheck these boxes after each new setup or material route change.' 65 160
$null=Add-Button $pages['5 Finish / Restore'] 'Save acceptance / incomplete report' 15 {
    try {
        $null=Initialize-BridgeState $root
        $stages=@($script:checks | ForEach-Object { [pscustomobject]@{stage=$_.Text;userConfirmed=$_.Checked} })
        $result=[pscustomobject]@{at=[DateTime]::UtcNow.ToString('o');evidence='User attestation in setup wizard';complete=(@($stages | Where-Object {-not $_.userConfirmed}).Count -eq 0);stages=$stages}
        $result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $stateDir 'acceptance.json') -Encoding UTF8
        $finishBox.Text=$result | ConvertTo-Json -Depth 8
    } catch { Show-Failure $_ }
}
$null=Add-Button $pages['5 Finish / Restore'] 'Refresh saved setup progress (historical evidence)' 590 {
    try {
        $progressFiles=@(Get-ChildItem -Path (Join-Path $stateDir '*-progress.json'),(Join-Path $stateDir 'downloads\*-progress.json') -ErrorAction SilentlyContinue)
        $saved=@($progressFiles | ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json })
        $finishBox.Text=($saved | ConvertTo-Json -Depth 8)
        if (-not $saved.Count) { $finishBox.Text='No saved progress yet. Missing stages remain unverified.' }
    } catch { Show-Failure $_ }
}
$null=Add-Text $pages['5 Finish / Restore'] (Get-Content -LiteralPath (Join-Path $root 'RESTORE.md') -Raw) 245 340
if ($SmokeTest) {
    if ($tabs.TabPages.Count -ne 6 -or $script:checks.Count -ne 8) { throw 'Wizard structure invalid' }
    if ($SmokeTest) {
        $form.StartPosition='Manual'
        $form.Location=New-Object Drawing.Point(-10000,-10000)
        $form.ShowInTaskbar=$false
        $form.Show()
        [Windows.Forms.Application]::DoEvents()
    }
    foreach ($page in $tabs.TabPages) {
        if ($page -eq $accountPage) { continue }
        $tabs.SelectedTab=$page
        if ($tabs.SelectedTab -ne $accountPage -or $page.Enabled) { throw 'Account gate allowed unacknowledged navigation' }
    }
    $accountCheck.Checked=$true
    $tabs.SelectedTab=$pages['3 Configure']
    if ($tabs.SelectedTab -ne $pages['3 Configure'] -or -not $pages['3 Configure'].Enabled) { throw 'Acknowledgement failed to unlock setup' }
    $accountCheck.Checked=$false
    if ($tabs.SelectedTab -ne $accountPage -or $pages['3 Configure'].Enabled) { throw 'Revoked acknowledgement did not relock setup' }
    foreach ($page in $tabs.TabPages) {
        $accountCheck.Checked=($page -ne $accountPage)
        $tabs.SelectedTab=$page
        [Windows.Forms.Application]::DoEvents()
        if ($SmokeImageDirectory) {
            New-Item -ItemType Directory -Path $SmokeImageDirectory -Force | Out-Null
            $form.CreateControl(); $tabs.CreateControl(); $page.CreateControl()
            $form.PerformLayout()
            $bitmap=New-Object Drawing.Bitmap($form.Width,$form.Height)
            $form.DrawToBitmap($bitmap,(New-Object Drawing.Rectangle(0,0,$form.Width,$form.Height)))
            $bitmap.Save((Join-Path $SmokeImageDirectory ('page-'+$tabs.SelectedIndex+'.png')))
            $bitmap.Dispose()
        }
    }
    $form.Dispose()
    Write-Output 'Wizard controls constructed and all 6 pages checked; unacknowledged navigation blocked, confirmation unlocks, revocation relocks; no setup actions invoked.'
    return
}
[Windows.Forms.Application]::EnableVisualStyles()
[void]$form.ShowDialog()

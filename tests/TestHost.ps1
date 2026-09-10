# Fixture host only: never dot-source in production setup.
function global:Get-CimInstance {
    param($ClassName,$ErrorAction)
    if ($ClassName -ne 'Win32_OperatingSystem') { throw 'Unexpected fixture query' }
    [pscustomobject]@{BuildNumber=19045;ProductType=1}
}

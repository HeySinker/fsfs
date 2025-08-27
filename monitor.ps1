# monitor.ps1
$ErrorActionPreference = 'SilentlyContinue'
$svcName = 'svchost'

while ($true) {
    $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue

    if ($null -eq $svc) {
        # الخدمة غير موجودة
        Start-Sleep -Seconds 5
        continue
    }

    if ($svc.Status -ne 'Running') {
        try {
            # إذا كانت الخدمة Disabled، اجعلها Manual أولاً
            if ($svc.StartType -eq 'Disabled') {
                Set-Service -Name $svcName -StartupType Manual
            }
            Start-Service -Name $svcName -ErrorAction Stop
            Write-Host "$svcName started successfully."
        } catch {
            Write-Host "Failed to start $svcName: $_"
        }
    }

    Start-Sleep -Seconds 5
}

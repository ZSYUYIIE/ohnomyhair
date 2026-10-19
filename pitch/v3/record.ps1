param([string[]]$Shots = @('sling','failure','parry','dryer','swap'))
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path
$reviewRoot = Join-Path $projectRoot 'build/pitch-review'
$mediaRoot = Join-Path $projectRoot 'pitch/editor/public/v3'
New-Item -ItemType Directory -Force -Path $reviewRoot,$mediaRoot | Out-Null
$consoleGodot = 'F:/godot/Godot_v4.7.2-stable_win64_console.exe'
$guiGodot = 'F:/godot/Godot_v4.7.2-stable_win64.exe'
$importProcess = Start-Process -FilePath $consoleGodot -ArgumentList @('--headless','--editor','--path',$projectRoot,'--import','--quit') -WorkingDirectory $projectRoot -WindowStyle Hidden -PassThru -Wait -RedirectStandardOutput "$reviewRoot/v3-import.out.log" -RedirectStandardError "$reviewRoot/v3-import.err.log"
if ($null -ne $importProcess.ExitCode -and $importProcess.ExitCode -ne 0) { throw 'Godot asset import failed; see v3-import.err.log' }
$scripts = @{sling='capture_l1.gd'; failure='capture_l1.gd'; parry='capture_l2.gd'; dryer='capture_l3.gd'; swap='capture_swap.gd'; boss='capture_boss.gd'; ui='capture_ui.gd'}
foreach ($shot in $Shots) {
    if (-not $scripts.ContainsKey($shot)) { throw "Unknown shot: $shot" }
    $rawMovie = Join-Path $reviewRoot "raw-$shot.avi"
    $scriptPath = 'res://pitch/v3/' + $scripts[$shot]
    $argsList = @('--path',$projectRoot,'--script',$scriptPath,'--write-movie',$rawMovie,'--fixed-fps','60','--disable-vsync','--resolution','1280x720','--quit-after','3600','--',"--shot=$shot")
    Write-Output "RECORD $shot"
    $captureProcess = Start-Process -FilePath $guiGodot -ArgumentList $argsList -WorkingDirectory $projectRoot -WindowStyle Hidden -PassThru -Wait -RedirectStandardOutput "$reviewRoot/v3-$shot.out.log" -RedirectStandardError "$reviewRoot/v3-$shot.err.log"
    if ($null -ne $captureProcess.ExitCode -and $captureProcess.ExitCode -ne 0) { Get-Content "$reviewRoot/v3-$shot.err.log"; throw "Capture failed: $shot" }
    & ffmpeg -y -v error -i $rawMovie -c:v libx264 -preset fast -crf 17 -r 30 -pix_fmt yuv420p -c:a aac -b:a 160k -movflags +faststart "$mediaRoot/$shot.mp4"
    if ($LASTEXITCODE -ne 0) { throw "Video conversion failed: $shot" }
    Write-Output "DONE $shot"
}

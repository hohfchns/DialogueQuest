param([string]$Godot = "godot")

$ErrorActionPreference = "Stop"
$projectDirectory = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$godotCommand = (Get-Command $Godot -ErrorAction Stop).Source
$logDirectory = Join-Path $projectDirectory ".godot"
New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
$importLog = Join-Path $logDirectory "test_import.log"
$testLog = Join-Path $logDirectory "regression_tests.log"

& $godotCommand --headless --path $projectDirectory --editor --import --quit --log-file $importLog
if ($LASTEXITCODE -ne 0 -or (Get-Content -Raw $importLog) -match "SCRIPT ERROR:") {
    throw "Godot project import failed. See $importLog"
}

& $godotCommand --headless --path $projectDirectory --log-file $testLog res://tests/regression_tests.tscn --quit-after 10000
$testExitCode = $LASTEXITCODE
$testOutput = Get-Content -Raw $testLog
if ($testExitCode -ne 0 -or $testOutput -match "(?m)^(SCRIPT ERROR:|ERROR:)" -or $testOutput -notmatch "DialogueQuest regression tests: 0 failure\(s\)") {
    throw "DialogueQuest tests failed or did not finish. See $testLog"
}

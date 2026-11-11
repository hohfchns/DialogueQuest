param([string]$Godot = "godot")

$ErrorActionPreference = "Stop"
$projectDirectory = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$godotCommand = (Get-Command $Godot -ErrorAction Stop).Source
$logDirectory = Join-Path $projectDirectory ".godot"
New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
$importLog = Join-Path $logDirectory "test_import.log"
$editorLog = Join-Path $logDirectory "editor_setup_tests.log"
$testLog = Join-Path $logDirectory "regression_tests.log"

& $godotCommand --headless --path $projectDirectory --editor --import --quit --log-file $importLog
if ($LASTEXITCODE -ne 0 -or (Get-Content -Raw $importLog) -match "SCRIPT ERROR:") {
    throw "Godot project import failed. See $importLog"
}

& $godotCommand --headless --path $projectDirectory --editor --script res://tests/editor_setup_tests.gd --log-file $editorLog --quit-after 10000
$editorExitCode = $LASTEXITCODE
$editorOutput = Get-Content -Raw $editorLog
# Godot 4.6 also reports these native shutdown leaks with an empty --editor --script SceneTree.
$editorErrors = $editorOutput -split "`n" | Where-Object { $_ -match "^(SCRIPT ERROR:|ERROR:)" -and $_ -notmatch "^ERROR: \d+ RID allocations of type '.+' were leaked at exit\.\s*$" }
if ($editorExitCode -ne 0 -or $editorErrors -or $editorOutput -notmatch "DialogueQuest editor tests: 0 failure\(s\)") {
    throw "DialogueQuest editor tests failed or did not finish. See $editorLog"
}

& $godotCommand --headless --path $projectDirectory --log-file $testLog res://tests/regression_tests.tscn --quit-after 10000
$testExitCode = $LASTEXITCODE
$testOutput = Get-Content -Raw $testLog
if ($testExitCode -ne 0 -or $testOutput -match "(?m)^(SCRIPT ERROR:|ERROR:)" -or $testOutput -notmatch "DialogueQuest regression tests: 0 failure\(s\)") {
    throw "DialogueQuest tests failed or did not finish. See $testLog"
}

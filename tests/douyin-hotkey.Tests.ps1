$ErrorActionPreference = "Stop"

$scriptContent = Get-Content -Raw -Encoding UTF8 "$PSScriptRoot/../pwa-toggle.ahk"
$readme = Get-Content -Raw -Encoding UTF8 "$PSScriptRoot/../README.md"

if ($scriptContent -notmatch 'MakeApp\(.*"\^!d".*"Douyin".*"douyin\.exe"') {
    throw "Douyin rule missing"
}

if ($readme -notmatch 'Ctrl \+ Alt \+ D') {
    throw "Douyin shortcut docs missing"
}

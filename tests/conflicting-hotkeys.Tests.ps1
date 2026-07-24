$ErrorActionPreference = "Stop"

$scriptContent = Get-Content -Raw -Encoding UTF8 "$PSScriptRoot/../pwa-toggle.ahk"
$readme = Get-Content -Raw -Encoding UTF8 "$PSScriptRoot/../README.md"

if ($scriptContent -notmatch '(?m)^#UseHook\s+True\s*$') {
    throw "Keyboard-hook hotkeys are not enabled"
}

if ($scriptContent -notmatch 'MakeApp\(.*"\^!w".*"Weixin\.exe"') {
    throw "WeChat Ctrl+Alt+W rule missing"
}

if ($scriptContent -notmatch 'MakeApp\(.*"\^!z".*"QQ\.exe"') {
    throw "QQ Ctrl+Alt+Z rule missing"
}

foreach ($shortcut in @(
    'Ctrl \+ Alt \+ W',
    'Ctrl \+ Alt \+ Z',
    'Ctrl \+ Alt \+ C',
    'Alt \+ C'
)) {
    if ($readme -notmatch $shortcut) {
        throw "Shortcut documentation missing: $shortcut"
    }
}

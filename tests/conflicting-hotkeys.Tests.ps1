$ErrorActionPreference = "Stop"

$scriptContent = Get-Content -Raw -Encoding UTF8 "$PSScriptRoot/../pwa-toggle.ahk"
$readme = Get-Content -Raw -Encoding UTF8 "$PSScriptRoot/../README.md"

if ($scriptContent -notmatch '(?m)^#UseHook\s+True\s*$') {
    throw "Keyboard-hook hotkeys are not enabled"
}

if ($scriptContent -match 'MakeApp\(.*"\^!w".*"Weixin\.exe"') {
    throw "WeChat Ctrl+Alt+W must be left to WeChat"
}

if ($scriptContent -match 'MakeApp\(.*"\^!z".*"QQ\.exe"') {
    throw "QQ Ctrl+Alt+Z must be left to QQ"
}

foreach ($shortcut in @(
    'Ctrl \+ Alt \+ C',
    'Alt \+ C'
)) {
    if ($readme -notmatch $shortcut) {
        throw "Shortcut documentation missing: $shortcut"
    }
}

foreach ($shortcut in @(
    'Ctrl \+ Alt \+ W',
    'Ctrl \+ Alt \+ Z'
)) {
    if ($readme -match $shortcut) {
        throw "Shortcut documentation must be removed: $shortcut"
    }
}

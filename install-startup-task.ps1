param(
    [string]$TaskName = 'PWA Toggle Hotkeys',
    [switch]$NoStart
)

$ErrorActionPreference = 'Stop'

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Resolve-AutoHotkeyPath {
    $candidates = @(
        "$env:LOCALAPPDATA\Programs\AutoHotkey\v2\AutoHotkey64.exe",
        "$env:LOCALAPPDATA\Programs\AutoHotkey\v2\AutoHotkey.exe",
        "$env:ProgramFiles\AutoHotkey\v2\AutoHotkey64.exe",
        "$env:ProgramFiles\AutoHotkey\v2\AutoHotkey.exe",
        "$env:ProgramFiles\AutoHotkey\AutoHotkey.exe"
    )

    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate)) {
            return $candidate
        }
    }

    $command = Get-Command AutoHotkey64.exe, AutoHotkey.exe -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($command) {
        return $command.Source
    }

    throw 'AutoHotkey v2 was not found. Install AutoHotkey v2, then run this script again.'
}

function Remove-StartupShortcutsForScript {
    param(
        [string]$ScriptPath
    )

    $startup = [Environment]::GetFolderPath('Startup')
    if (!(Test-Path -LiteralPath $startup)) {
        return
    }

    $shell = New-Object -ComObject WScript.Shell
    Get-ChildItem -LiteralPath $startup -Filter '*.lnk' -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            $shortcut = $shell.CreateShortcut($_.FullName)
            $target = [string]$shortcut.TargetPath
            $arguments = [string]$shortcut.Arguments
            if ($target -like '*AutoHotkey*' -and $arguments -like "*$ScriptPath*") {
                Remove-Item -LiteralPath $_.FullName -Force
            }
        } catch {
            Write-Warning "Could not inspect startup shortcut '$($_.FullName)': $($_.Exception.Message)"
        }
    }
}

if (!(Test-IsAdministrator)) {
    $scriptArgs = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"")
    if ($TaskName -ne 'PWA Toggle Hotkeys') {
        $scriptArgs += @('-TaskName', "`"$TaskName`"")
    }
    if ($NoStart) {
        $scriptArgs += '-NoStart'
    }

    Start-Process -FilePath 'powershell.exe' -ArgumentList $scriptArgs -Verb RunAs
    return
}

$root = Split-Path -Parent $PSCommandPath
$hotkeyScript = Join-Path $root 'pwa-toggle.ahk'
if (!(Test-Path -LiteralPath $hotkeyScript)) {
    throw "Could not find pwa-toggle.ahk next to this installer: $hotkeyScript"
}

$autoHotkey = Resolve-AutoHotkeyPath
$userId = [Security.Principal.WindowsIdentity]::GetCurrent().Name

$action = New-ScheduledTaskAction -Execute $autoHotkey -Argument ('"' + $hotkeyScript + '"')
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $userId
$principal = New-ScheduledTaskPrincipal -UserId $userId -LogonType Interactive -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
Remove-StartupShortcutsForScript -ScriptPath $hotkeyScript

if (!$NoStart) {
    Start-ScheduledTask -TaskName $TaskName
}

Write-Host "Installed scheduled task '$TaskName' for $userId."
Write-Host "The hotkey script will now start at logon with highest privileges, without a repeated UAC prompt."

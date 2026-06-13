#Requires AutoHotkey v2.0
#SingleInstance Force

; Relaunch elevated so hotkeys work when target apps run as administrator.
if !A_IsAdmin {
    try {
        Run('*RunAs "' A_AhkPath '" "' A_ScriptFullPath '"')
    } catch as err {
        MsgBox("This script needs administrator permission to control elevated app windows.`n`n" err.Message)
    }
    ExitApp
}

; One-key show/hide toggle for Google Gemini, ChatGPT, VS Code, Clash for Windows, and Codex.
; Hotkey syntax: ^ = Ctrl, ! = Alt, # = Win, + = Shift.

DetectHiddenWindows(true)
SetTitleMatchMode(2)
SetWorkingDir(A_ScriptDir)
Persistent(true)

; Optional: paste the exact PWA shortcut path here if auto-detection opens a normal browser tab.
; Example: "C:\Users\akun\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Chrome Apps\Google Gemini.lnk"
geminiLaunchPath := A_AppData . "\Microsoft\Windows\Start Menu\Programs\Chrome 应用\Google Gemini.lnk"
chatgptLaunchPath := A_AppData . "\Microsoft\Windows\Start Menu\Programs\Chrome 应用\ChatGPT 中文.lnk"
vscodeLaunchPath := "D:\tool\encoder\Microsoft VS Code\Code.exe"
clashLaunchPath := "D:\tool\cross network\Clash for Windows\Clash for Windows.exe"
codexLaunchPath := "shell:AppsFolder\OpenAI.Codex_2p2nqsd0c76g0!App"

apps := []
apps.Push(MakeApp("Google Gemini", "^!g", ["Google Gemini", "Gemini"], ["Google Gemini.lnk", "Gemini.lnk"], "https://gemini.google.com/app", geminiLaunchPath, BrowserProcessNames(), false))
apps.Push(MakeApp("ChatGPT中文", "^!c", ["ChatGPT中文", "ChatGPT"], ["ChatGPT 中文.lnk", "ChatGPT中文.lnk", "ChatGPT.lnk"], "https://chatgpt.com/", chatgptLaunchPath, BrowserProcessNames(), false))
apps.Push(MakeApp("VS Code", "^!v", ["Visual Studio Code", "VS Code"], ["Visual Studio Code.lnk", "VS Code.lnk", "Code.lnk"], "", vscodeLaunchPath, ["Code.exe"], false))
apps.Push(MakeApp("Clash for Windows", "^+c", ["Clash for Windows", "Clash"], ["Clash for Windows.lnk", "Clash.lnk"], "", clashLaunchPath, ["Clash for Windows.exe"], false, true))
apps.Push(MakeApp("Codex", "!c", ["Codex"], ["Codex.lnk"], "", codexLaunchPath, ["Codex.exe"], true))

HiddenWindows := Map()

OnMessage(0x007E, HandleDisplayChange) ; WM_DISPLAYCHANGE
OnMessage(0x02E0, HandleDisplayChange) ; WM_DPICHANGED

for _, app in apps {
    Hotkey(app.hotkey, ToggleApp.Bind(app), "On")
}

; Rescue key: show and repair all windows managed by this script.
Hotkey("^!r", ShowAllApps, "On")
OnExit(ShowHiddenBeforeExit)

return

MakeApp(name, hotkey, titles, shortcutNames, fallbackUrl, launchPath := "", processNames := "", closeToTray := false, restoreByLaunch := false) {
    if processNames = "" {
        processNames := BrowserProcessNames()
    }

    return {
        name: name,
        hotkey: hotkey,
        titles: titles,
        shortcutNames: shortcutNames,
        fallbackUrl: fallbackUrl,
        launchPath: launchPath,
        processNames: processNames,
        closeToTray: closeToTray,
        restoreByLaunch: restoreByLaunch
    }
}

BrowserProcessNames() {
    return [
        "chrome.exe",
        "chrome_proxy.exe",
        "msedge.exe",
        "msedge_proxy.exe",
        "brave.exe",
        "brave_proxy.exe",
        "vivaldi.exe",
        "opera.exe",
        "firefox.exe"
    ]
}

ToggleApp(app, *) {
    global HiddenWindows

    if app.closeToTray {
        ToggleCloseToTrayApp(app)
        return
    }

    if app.restoreByLaunch {
        ToggleRestoreByLaunchApp(app)
        return
    }

    hwnd := FindAppWindow(app)
    if hwnd {
        target := "ahk_id " hwnd
        if WinActive(target) && IsWindowVisible(hwnd) {
            WinHide(target)
            HiddenWindows[hwnd] := true
            return
        }

        ActivateWindow(hwnd)

        if HiddenWindows.Has(hwnd) {
            HiddenWindows.Delete(hwnd)
        }
        return
    }

    RunApp(app)
}

ToggleRestoreByLaunchApp(app) {
    global HiddenWindows

    if IsActiveApp(app) {
        activeHwnd := WinExist("A")
        WinHide("ahk_id " activeHwnd)
        HiddenWindows[activeHwnd] := true
        return
    }

    hwnd := FindVisibleAppWindow(app)
    if hwnd {
        ActivateWindow(hwnd)
        if HiddenWindows.Has(hwnd) {
            HiddenWindows.Delete(hwnd)
        }
        return
    }

    launchTarget := ResolveLaunchTarget(app)
    if launchTarget != "" {
        RunTarget(launchTarget)
        hwnd := WaitForVisibleAppWindow(app, 12000)
        if hwnd {
            Sleep(400)
            ActivateWindow(hwnd)
            if HiddenWindows.Has(hwnd) {
                HiddenWindows.Delete(hwnd)
            }
        }
        return
    }

    MsgBox("No launcher was found for " app.name ". Edit launchPath in this script.")
}

ToggleCloseToTrayApp(app) {
    if IsActiveApp(app) {
        activeHwnd := WinExist("A")
        SendCloseButton(activeHwnd)
        return
    }

    hwnd := FindVisibleAppWindow(app)
    if hwnd {
        ActivateWindow(hwnd)
        return
    }

    launchTarget := ResolveLaunchTarget(app)
    if launchTarget != "" {
        RunTarget(launchTarget)
        hwnd := WaitForVisibleAppWindow(app, 10000)
        if hwnd {
            ActivateWindow(hwnd)
        }
        return
    }

    MsgBox("No launcher was found for " app.name ". Edit launchPath in this script.")
}

FindAppWindow(app) {
    global HiddenWindows

    activeHwnd := WinExist("A")
    if activeHwnd && IsActiveApp(app) {
        return activeHwnd
    }

    matches := FindAppWindows(app)
    for _, hwnd in matches {
        if HiddenWindows.Has(hwnd) {
            return hwnd
        }
    }

    if matches.Length {
        return matches[1]
    }
    return 0
}

FindAppWindows(app) {
    seen := Map()
    matches := []

    for _, title in app.titles {
        for _, hwnd in WinGetList(title) {
            if seen.Has(hwnd) {
                continue
            }
            seen[hwnd] := true

            if IsAppCandidate(hwnd, app) {
                matches.Push(hwnd)
            }
        }
    }

    return matches
}

FindVisibleAppWindow(app) {
    for _, hwnd in FindAppWindows(app) {
        if IsWindowVisible(hwnd) {
            return hwnd
        }
    }

    return 0
}

IsAppCandidate(hwnd, app) {
    try {
        title := WinGetTitle("ahk_id " hwnd)
        if title = "" {
            return false
        }

        exe := WinGetProcessName("ahk_id " hwnd)
        return ArrayContains(app.processNames, exe)
    } catch {
        return false
    }
}

TitleMatchesApp(hwnd, app) {
    try {
        title := WinGetTitle("ahk_id " hwnd)
        for _, appTitle in app.titles {
            if InStr(title, appTitle) {
                return true
            }
        }
    }
    return false
}

IsActiveApp(app) {
    activeHwnd := WinExist("A")
    return activeHwnd && IsWindowVisible(activeHwnd) && IsAppCandidate(activeHwnd, app) && TitleMatchesApp(activeHwnd, app)
}

RunApp(app) {
    launchTarget := ResolveLaunchTarget(app)

    if launchTarget != "" {
        RunTarget(launchTarget)
    } else if app.fallbackUrl != "" {
        Run(app.fallbackUrl)
    } else {
        MsgBox("No launcher was found for " app.name ". Edit launchPath in this script.")
        return
    }

    hwnd := WaitForAppWindow(app, 10000)
    if hwnd {
        ActivateWindow(hwnd)
    }
}

ResolveLaunchTarget(app) {
    if IsShellTarget(app.launchPath) {
        return app.launchPath
    }

    if app.launchPath != "" && FileExist(app.launchPath) {
        return app.launchPath
    }

    shortcut := FindShortcut(app.shortcutNames)
    if shortcut != "" {
        return shortcut
    }

    return ""
}

RunTarget(target) {
    if IsShellTarget(target) {
        Run(target)
    } else {
        Run(Quote(target))
    }
}

IsShellTarget(target) {
    return target != "" && InStr(StrLower(target), "shell:") = 1
}

FindShortcut(shortcutNames) {
    userPrograms := A_AppData . "\Microsoft\Windows\Start Menu\Programs"
    commonPrograms := EnvGet("ProgramData") . "\Microsoft\Windows\Start Menu\Programs"
    publicDesktop := EnvGet("Public") . "\Desktop"

    exactFolders := [
        userPrograms . "\Chrome 应用",
        userPrograms . "\Chrome Apps",
        userPrograms . "\Microsoft Edge Apps",
        userPrograms,
        commonPrograms,
        A_Desktop,
        publicDesktop
    ]

    for _, folder in exactFolders {
        if !DirExist(folder) {
            continue
        }

        for _, name in shortcutNames {
            path := folder . "\" . name
            if FileExist(path) {
                return path
            }
        }
    }

    recursiveFolders := [userPrograms, commonPrograms]
    for _, folder in recursiveFolders {
        if !DirExist(folder) {
            continue
        }

        Loop Files, folder "\*.lnk", "R" {
            for _, name in shortcutNames {
                needle := StrReplace(StrLower(name), ".lnk")
                if InStr(StrLower(A_LoopFileName), needle) {
                    return A_LoopFileFullPath
                }
            }
        }
    }

    return ""
}

WaitForAppWindow(app, timeoutMs) {
    startedAt := A_TickCount

    while A_TickCount - startedAt < timeoutMs {
        hwnd := FindAppWindow(app)
        if hwnd {
            return hwnd
        }
        Sleep(150)
    }

    return 0
}

WaitForVisibleAppWindow(app, timeoutMs) {
    startedAt := A_TickCount

    while A_TickCount - startedAt < timeoutMs {
        hwnd := FindVisibleAppWindow(app)
        if hwnd {
            return hwnd
        }
        Sleep(150)
    }

    return 0
}

HandleDisplayChange(*) {
    SetTimer(RepairManagedWindows, -800)
}

RepairManagedWindows(*) {
    global apps

    for _, app in apps {
        for _, hwnd in FindAppWindows(app) {
            if IsWindowVisible(hwnd) {
                RepairWindowForCurrentDisplays(hwnd)
                ForceWindowLayoutRefresh(hwnd)
            }
        }
    }
}

ActivateWindow(hwnd) {
    target := "ahk_id " hwnd
    try WinShow(target)
    RestoreIfMinimized(hwnd)
    RepairWindowForCurrentDisplays(hwnd)
    ForceWindowLayoutRefresh(hwnd)
    WinActivate(target)
}

RestoreIfMinimized(hwnd) {
    target := "ahk_id " hwnd
    try {
        if (WinGetMinMax(target) = -1) {
            WinRestore(target)
        }
    }
}

RepairWindowForCurrentDisplays(hwnd) {
    target := "ahk_id " hwnd

    try {
        if (WinGetMinMax(target) = 1) {
            return
        }

        WinGetPos(&x, &y, &width, &height, target)
    } catch {
        return
    }

    if (width <= 0 || height <= 0) {
        return
    }

    overlapArea := 0
    monitorIndex := GetBestMonitorForRect(x, y, width, height, &overlapArea)

    try MonitorGetWorkArea(monitorIndex, &left, &top, &right, &bottom)
    catch {
        return
    }

    workWidth := right - left
    workHeight := bottom - top
    if (workWidth <= 0 || workHeight <= 0) {
        return
    }

    windowArea := width * height
    visibleThreshold := Min(windowArea, workWidth * workHeight) * 0.2
    offScreen := overlapArea < visibleThreshold
    tooSmall := width < 360 || height < 260
    tooLarge := width > workWidth * 1.25 || height > workHeight * 1.25

    if !(offScreen || tooSmall || tooLarge) {
        return
    }

    newWidth := Min(Max(width, Min(1200, workWidth)), workWidth)
    newHeight := Min(Max(height, Min(800, workHeight)), workHeight)

    if (tooSmall || width > workWidth * 1.25) {
        newWidth := Min(Round(workWidth * 0.82), workWidth)
    }
    if (tooSmall || height > workHeight * 1.25) {
        newHeight := Min(Round(workHeight * 0.82), workHeight)
    }

    newX := left + Round((workWidth - newWidth) / 2)
    newY := top + Round((workHeight - newHeight) / 2)
    try WinMove(newX, newY, newWidth, newHeight, target)
}

GetBestMonitorForRect(x, y, width, height, &bestArea) {
    bestIndex := 1
    bestArea := -1
    rectRight := x + width
    rectBottom := y + height

    Loop MonitorGetCount() {
        MonitorGetWorkArea(A_Index, &left, &top, &right, &bottom)
        overlapWidth := Max(0, Min(rectRight, right) - Max(x, left))
        overlapHeight := Max(0, Min(rectBottom, bottom) - Max(y, top))
        area := overlapWidth * overlapHeight

        if (area > bestArea) {
            bestArea := area
            bestIndex := A_Index
        }
    }

    return bestIndex
}

ForceWindowLayoutRefresh(hwnd) {
    target := "ahk_id " hwnd

    try WinGetPos(&x, &y, &width, &height, target)
    catch {
        return
    }

    flags := 0x0001 | 0x0002 | 0x0004 | 0x0010 | 0x0020
    DllCall("SetWindowPos", "Ptr", hwnd, "Ptr", 0, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", flags)
    try WinRedraw(target)
    DllCall("RedrawWindow", "Ptr", hwnd, "Ptr", 0, "Ptr", 0, "UInt", 0x0001 | 0x0080 | 0x0100 | 0x0400)

    sizeParam := ((height & 0xFFFF) << 16) | (width & 0xFFFF)
    try PostMessage(0x0005, 0, sizeParam, "", target)
}

SendCloseButton(hwnd) {
    DllCall("PostMessage", "Ptr", hwnd, "UInt", 0x112, "Ptr", 0xF060, "Ptr", 0)
}

IsWindowVisible(hwnd) {
    return DllCall("IsWindowVisible", "Ptr", hwnd, "Int")
}

ShowAllApps(*) {
    global apps, HiddenWindows

    for _, app in apps {
        for _, hwnd in FindAppWindows(app) {
            target := "ahk_id " hwnd
            try WinShow(target)
            RestoreIfMinimized(hwnd)
            RepairWindowForCurrentDisplays(hwnd)
            ForceWindowLayoutRefresh(hwnd)
            if HiddenWindows.Has(hwnd) {
                HiddenWindows.Delete(hwnd)
            }
        }
    }
}

ShowHiddenBeforeExit(exitReason, exitCode) {
    ShowAllApps()
}

ArrayContains(items, value) {
    value := StrLower(value)
    for _, item in items {
        if StrLower(item) = value {
            return true
        }
    }
    return false
}

Quote(value) {
    return Chr(34) . value . Chr(34)
}

#Requires AutoHotkey v2.0
#SingleInstance Force

; One-key show/hide toggle for Google Gemini, ChatGPT, VS Code, Clash for Windows, and Codex.
; Hotkey syntax: ^ = Ctrl, ! = Alt, # = Win, + = Shift.

DetectHiddenWindows(true)
SetTitleMatchMode(2)
SetWorkingDir(A_ScriptDir)
Persistent(true)

; Optional: paste the exact PWA shortcut path here if auto-detection opens a normal browser tab.
; Example: "C:\Users\akun\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Chrome Apps\Google Gemini.lnk"
geminiLaunchPath := ""
chatgptLaunchPath := ""
vscodeLaunchPath := "D:\tool\encoder\Microsoft VS Code\Code.exe"
clashLaunchPath := "D:\tool\cross network\Clash for Windows\Clash for Windows.exe"
codexLaunchPath := "shell:AppsFolder\OpenAI.Codex_2p2nqsd0c76g0!App"

apps := []
apps.Push(MakeApp("Google Gemini", "^!g", ["Google Gemini", "Gemini"], ["Google Gemini.lnk", "Gemini.lnk"], "https://gemini.google.com/app", geminiLaunchPath, BrowserProcessNames(), false))
apps.Push(MakeApp("ChatGPT中文", "^!c", ["ChatGPT中文", "ChatGPT"], ["ChatGPT中文.lnk", "ChatGPT.lnk"], "https://chatgpt.com/", chatgptLaunchPath, BrowserProcessNames(), false))
apps.Push(MakeApp("VS Code", "^!v", ["Visual Studio Code", "VS Code"], ["Visual Studio Code.lnk", "VS Code.lnk", "Code.lnk"], "", vscodeLaunchPath, ["Code.exe"], false))
apps.Push(MakeApp("Clash for Windows", "^+c", ["Clash for Windows", "Clash"], ["Clash for Windows.lnk", "Clash.lnk"], "", clashLaunchPath, ["Clash for Windows.exe"], false))
apps.Push(MakeApp("Codex", "!c", ["Codex"], ["Codex.lnk"], "", codexLaunchPath, ["Codex.exe"], true))

HiddenWindows := Map()

for _, app in apps {
    Hotkey(app.hotkey, ToggleApp.Bind(app), "On")
}

; Rescue key: show all windows managed by this script.
Hotkey("^!r", ShowAllApps, "On")
OnExit(ShowHiddenBeforeExit)

return

MakeApp(name, hotkey, titles, shortcutNames, fallbackUrl, launchPath := "", processNames := "", closeToTray := false) {
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
        closeToTray: closeToTray
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

    hwnd := FindAppWindow(app)
    if hwnd {
        target := "ahk_id " hwnd
        if WinActive(target) && IsWindowVisible(hwnd) {
            WinHide(target)
            HiddenWindows[hwnd] := true
            return
        }

        WinShow(target)
        try WinRestore(target)
        WinActivate(target)

        if HiddenWindows.Has(hwnd) {
            HiddenWindows.Delete(hwnd)
        }
        return
    }

    RunApp(app)
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
        target := "ahk_id " hwnd
        WinShow(target)
        try WinRestore(target)
        WinActivate(target)
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

ActivateWindow(hwnd) {
    target := "ahk_id " hwnd
    try WinShow(target)
    try WinRestore(target)
    WinActivate(target)
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
            try WinRestore(target)
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

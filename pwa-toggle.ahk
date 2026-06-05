#Requires AutoHotkey v2.0
#SingleInstance Force

; PWA one-key show/hide toggle for Google Gemini and ChatGPT.
; Hotkey syntax: ^ = Ctrl, ! = Alt, # = Win, + = Shift.

DetectHiddenWindows(true)
SetTitleMatchMode(2)
SetWorkingDir(A_ScriptDir)
Persistent(true)

; Optional: paste the exact PWA shortcut path here if auto-detection opens a normal browser tab.
; Example: "C:\Users\akun\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Chrome Apps\Google Gemini.lnk"
geminiLaunchPath := ""
chatgptLaunchPath := ""

apps := []
apps.Push(MakeApp("Google Gemini", "^!g", ["Google Gemini", "Gemini"], ["Google Gemini.lnk", "Gemini.lnk"], "https://gemini.google.com/app", geminiLaunchPath))
apps.Push(MakeApp("ChatGPT中文", "^!c", ["ChatGPT中文", "ChatGPT"], ["ChatGPT中文.lnk", "ChatGPT.lnk"], "https://chatgpt.com/", chatgptLaunchPath))

HiddenWindows := Map()

for _, app in apps {
    Hotkey(app.hotkey, ToggleApp.Bind(app), "On")
}

; Rescue key: show all windows managed by this script.
Hotkey("^!r", ShowAllApps, "On")
OnExit(ShowHiddenBeforeExit)

return

MakeApp(name, hotkey, titles, shortcutNames, fallbackUrl, launchPath := "") {
    return {
        name: name,
        hotkey: hotkey,
        titles: titles,
        shortcutNames: shortcutNames,
        fallbackUrl: fallbackUrl,
        launchPath: launchPath,
        processNames: BrowserProcessNames()
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

    hwnd := FindAppWindow(app)
    if hwnd {
        target := "ahk_id " hwnd
        if WinActive(target) {
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

FindAppWindow(app) {
    global HiddenWindows

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

RunApp(app) {
    launchTarget := ResolveLaunchTarget(app)

    if launchTarget != "" {
        Run(Quote(launchTarget))
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
    if app.launchPath != "" && FileExist(app.launchPath) {
        return app.launchPath
    }

    shortcut := FindShortcut(app.shortcutNames)
    if shortcut != "" {
        return shortcut
    }

    return ""
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

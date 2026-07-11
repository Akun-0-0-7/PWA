# Douyin Hotkey Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a portable `Ctrl + Alt + D` Douyin toggle rule, deploy it locally, and publish it to GitHub.

**Architecture:** Register Douyin through the existing `MakeApp` configuration so it automatically reuses the established hide, restore, launch, rescue, and display-repair behavior. Use shortcut discovery in the repository and a detected executable path only in the deployed local copy.

**Tech Stack:** AutoHotkey v2, PowerShell, Git

## Global Constraints

- Bind Douyin to `Ctrl + Alt + D` (`^!d`).
- Match `抖音` or `Douyin` windows owned by `douyin.exe`.
- Preserve all existing hotkeys and behavior.
- Keep machine-specific paths out of the published repository.

---

### Task 1: Add and document the Douyin rule

**Files:**
- Create: `tests/douyin-hotkey.Tests.ps1`
- Modify: `pwa-toggle.ahk`
- Modify: `README.md`

**Interfaces:**
- Consumes: `MakeApp(name, hotkey, titles, shortcutNames, fallbackUrl, launchPath, processNames, closeToTray, restoreByLaunch)`
- Produces: an `apps` entry for Douyin bound to `^!d`

- [ ] **Step 1: Write the failing static rule test**

```powershell
$script = Get-Content -Raw "$PSScriptRoot/../pwa-toggle.ahk"
$readme = Get-Content -Raw "$PSScriptRoot/../README.md"
if ($script -notmatch 'MakeApp\("抖音", "\^!d".*"douyin\.exe"') { throw "Douyin rule missing" }
if ($readme -notmatch 'Ctrl \+ Alt \+ D.*抖音') { throw "Douyin shortcut docs missing" }
```

- [ ] **Step 2: Run the test and verify it fails**

Run: `powershell -ExecutionPolicy Bypass -File tests/douyin-hotkey.Tests.ps1`

Expected: FAIL with `Douyin rule missing`.

- [ ] **Step 3: Add the minimal rule and documentation**

Add this portable configuration to `pwa-toggle.ahk`:

```ahk
apps.Push(MakeApp("抖音", "^!d", ["抖音", "Douyin"], ["抖音.lnk", "Douyin.lnk"], "", "", ["douyin.exe"], false))
```

Update `README.md` to list Douyin, its shortcut, its standard toggle behavior, the configuration example, and `douyin.exe` process matching.

- [ ] **Step 4: Run the test and AutoHotkey syntax check**

Run: `powershell -ExecutionPolicy Bypass -File tests/douyin-hotkey.Tests.ps1`

Expected: exit code 0.

Run: `AutoHotkey64.exe /ErrorStdOut pwa-toggle.ahk`

Expected: no syntax error output.

- [ ] **Step 5: Commit the repository change**

```powershell
git add pwa-toggle.ahk README.md tests/douyin-hotkey.Tests.ps1 docs/superpowers/plans/2026-07-11-douyin-hotkey.md
git commit -m "feat: add Douyin toggle hotkey"
```

### Task 2: Deploy, verify, and publish

**Files:**
- Modify: `D:/Tool_LiuYongKun/WorkPlace/PWA/pwa-toggle.ahk`
- Modify: `D:/Tool_LiuYongKun/WorkPlace/PWA/README.md`

**Interfaces:**
- Consumes: the committed portable Douyin rule
- Produces: a running scheduled hotkey task and updated GitHub `main`

- [ ] **Step 1: Deploy while preserving local launch paths**

Copy the updated repository files to the deployed directory, then set the local Douyin launch target to:

```ahk
douyinLaunchPath := "D:\Tool_LiuYongKun\douyin\douyin.exe"
```

Pass `douyinLaunchPath` to the deployed Douyin `MakeApp` entry.

- [ ] **Step 2: Reload and inspect the scheduled task**

Run: `Stop-ScheduledTask -TaskName 'PWA Toggle Hotkeys'; Start-ScheduledTask -TaskName 'PWA Toggle Hotkeys'; Get-ScheduledTask -TaskName 'PWA Toggle Hotkeys'`

Expected: task state `Running`.

- [ ] **Step 3: Exercise the shortcut**

Send `Ctrl + Alt + D`, then verify a visible `抖音` window owned by `douyin.exe` is active. Send it again and verify the same window is hidden; send it a third time and verify it returns.

- [ ] **Step 4: Push both commits**

Run: `git push origin main`

Expected: remote `main` advances to the local commit.

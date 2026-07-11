# Douyin Hotkey Design

## Goal

Add a `Ctrl + Alt + D` shortcut for the Douyin desktop application while preserving the repository's existing one-key toggle behavior.

## Behavior

- If the Douyin window is active and visible, hide it.
- If the Douyin window exists in the background or was hidden, show and activate it.
- If Douyin is not running, launch it and activate its main window when available.
- The existing rescue shortcut continues to restore any Douyin window hidden by the script.

## Integration

Add Douyin to the existing `apps` configuration using the `^!d` AutoHotkey binding, the `抖音` and `Douyin` window titles, `抖音.lnk` and `Douyin.lnk` shortcut names, and the `douyin.exe` process name. Keep the repository launch path portable by relying on shortcut discovery; the deployed local copy may use the detected executable path.

Update the README application list, shortcut list, behavior description, configuration example, and process-identification notes.

## Verification

- Confirm the script contains the expected Douyin mapping and no duplicate hotkey.
- Parse or launch the script with AutoHotkey v2 to catch syntax errors.
- Reload the scheduled task and verify it remains running.
- Confirm `Ctrl + Alt + D` activates the existing Douyin window.
- Commit and push the repository changes to `main`.

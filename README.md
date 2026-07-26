# PWA 一键唤醒与隐藏

这是一个 AutoHotkey v2 脚本，用来给网页应用/PWA 和桌面应用做“一键唤醒与隐藏/最小化”。

当前内置六个应用：

- Google Gemini
- ChatGPT 中文（PWA）
- VS Code
- 抖音
- Clash for Windows
- ChatGPT（桌面版，原 Codex）

## 默认热键

- `Ctrl + Alt + G`：Google Gemini
- `Ctrl + Alt + C`：ChatGPT 中文 PWA
- `Ctrl + Alt + V`：VS Code
- `Ctrl + Alt + D`：抖音
- `Ctrl + Shift + C`：Clash for Windows
- `Alt + C`：ChatGPT 桌面版
- `Ctrl + Alt + R`：救援键，重新显示被脚本隐藏的窗口

Gemini、ChatGPT 中文 PWA、VS Code、抖音和 Clash for Windows 的行为：

- 如果窗口已经在前台：隐藏窗口
- 如果窗口在后台或已被隐藏：显示并激活窗口
- 如果窗口还没打开：启动对应快捷方式或程序入口

ChatGPT 桌面版的行为：

- 如果窗口已经在前台：发送右上角关闭按钮动作，收进托盘
- 如果窗口在后台：激活窗口
- 如果窗口已在托盘或还没打开：启动 ChatGPT 应用入口，把窗口唤回

## 使用前准备

1. 安装 [AutoHotkey v2](https://www.autohotkey.com/)。
2. 在 Chrome、Edge 或其他浏览器中把 Gemini 和 ChatGPT 安装为 PWA。
3. 如需使用 VS Code 或 Clash for Windows 热键，请先安装对应应用。
4. 双击运行 `pwa-toggle.ahk`。
5. 脚本会自动请求管理员权限，这样可以控制以管理员身份运行的 VS Code 等窗口。
6. 如需开机自动运行且不想每次开机弹权限确认，请运行一次 `install-startup-task.ps1`。

## 如果打开成普通浏览器标签页

脚本会自动寻找常见位置里的 PWA 快捷方式。如果它没有找到，就会退回到网页 URL，因此可能打开普通浏览器标签页。

这时请打开 `pwa-toggle.ahk`，把 PWA 快捷方式路径填到顶部：

```ahk
geminiLaunchPath := ""
chatgptLaunchPath := ""
```

示例：

```ahk
geminiLaunchPath := "C:\Users\akun\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Chrome Apps\Google Gemini.lnk"
chatgptLaunchPath := "C:\Users\akun\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Chrome Apps\ChatGPT中文.lnk"
```

获取快捷方式路径的方法：

1. 在开始菜单或桌面找到 PWA 图标。
2. 右键图标，选择“打开文件所在的位置”。
3. 复制对应 `.lnk` 文件的完整路径。

## 如果 VS Code 没有启动

脚本会通过 `vscodeLaunchPath` 启动 VS Code。当前默认路径是：

```ahk
vscodeLaunchPath := "D:\tool\encoder\Microsoft VS Code\Code.exe"
```

如果你的 VS Code 安装在其他位置，请把这个路径改成实际的 `Code.exe` 路径。

## 如果 Clash for Windows 没有启动

脚本会通过 `clashLaunchPath` 启动 Clash for Windows。当前默认路径是：

```ahk
clashLaunchPath := "D:\tool\cross network\Clash for Windows\Clash for Windows.exe"
```

如果你的 Clash for Windows 安装在其他位置，请把这个路径改成实际的 `Clash for Windows.exe` 路径。

## 修改热键

热键在脚本顶部这些行：

```ahk
apps.Push(MakeApp("Google Gemini", "^!g", ["Google Gemini", "Gemini"], ["Google Gemini.lnk", "Gemini.lnk"], "https://gemini.google.com/app", geminiLaunchPath, BrowserProcessNames(), false))
apps.Push(MakeApp("ChatGPT中文", "^!c", ["ChatGPT中文", "ChatGPT"], ["ChatGPT中文.lnk", "ChatGPT.lnk"], "https://chatgpt.com/", chatgptLaunchPath, BrowserProcessNames(), false))
apps.Push(MakeApp("VS Code", "^!v", ["Visual Studio Code", "VS Code"], ["Visual Studio Code.lnk", "VS Code.lnk", "Code.lnk"], "", vscodeLaunchPath, ["Code.exe"], false))
apps.Push(MakeApp("抖音", "^!d", ["抖音", "Douyin"], ["抖音.lnk", "Douyin.lnk"], "", "", ["douyin.exe"], false))
apps.Push(MakeApp("Clash for Windows", "^+c", ["Clash for Windows", "Clash"], ["Clash for Windows.lnk", "Clash.lnk"], "", clashLaunchPath, ["Clash for Windows.exe"], false, true))
apps.Push(MakeApp("ChatGPT", "!c", ["ChatGPT"], ["ChatGPT.lnk", "Codex.lnk"], "", chatgptDesktopLaunchPath, ["ChatGPT.exe"], true))
```

AutoHotkey 热键符号：

- `^` 表示 `Ctrl`
- `!` 表示 `Alt`
- `#` 表示 `Win`
- `+` 表示 `Shift`

例如 `^!g` 就是 `Ctrl + Alt + G`。

## 开机自动运行

运行一次安装脚本：

```powershell
powershell -ExecutionPolicy Bypass -File .\install-startup-task.ps1
```

它会请求一次管理员权限，创建名为 `PWA Toggle Hotkeys` 的计划任务，并在登录时以最高权限启动 `pwa-toggle.ahk`。这样脚本仍然能控制管理员权限运行的窗口，但开机时不会每次弹权限确认。

安装脚本也会清理启动文件夹里指向 `pwa-toggle.ahk` 的旧快捷方式。不要再把脚本快捷方式放回 `shell:startup`，否则开机时仍会从普通权限启动并再次请求管理员权限。

## 说明

这个脚本使用窗口标题和进程名来识别窗口。PWA 支持 Chrome、Edge、Brave、Vivaldi、Opera 和 Firefox 的常见进程名；VS Code 使用 `Code.exe` 识别；抖音使用 `douyin.exe` 识别；Clash for Windows 使用 `Clash for Windows.exe` 识别；ChatGPT 桌面版使用 `ChatGPT.exe` 识别，并通过系统关闭按钮动作进入托盘。

如果你误隐藏了窗口，可以按 `Ctrl + Alt + R` 恢复。退出脚本时，它也会尽量自动恢复被隐藏的窗口。

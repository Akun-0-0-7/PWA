# PWA 一键唤醒与隐藏

这是一个 AutoHotkey v2 脚本，用来给网页应用/PWA 和桌面应用做“一键唤醒与隐藏/最小化”。

当前内置四个应用：

- Google Gemini
- ChatGPT中文
- VS Code
- Codex

## 默认热键

- `Ctrl + Alt + G`：Google Gemini
- `Ctrl + Alt + C`：ChatGPT中文
- `Ctrl + Alt + V`：VS Code
- `Alt + C`：Codex
- `Ctrl + Alt + R`：救援键，重新显示被脚本隐藏的窗口

Gemini、ChatGPT 和 VS Code 的行为：

- 如果窗口已经在前台：隐藏窗口
- 如果窗口在后台或已被隐藏：显示并激活窗口
- 如果窗口还没打开：启动对应快捷方式或程序入口

Codex 的行为：

- 如果窗口已经在前台：发送右上角关闭按钮动作，收进托盘
- 如果窗口在后台：激活窗口
- 如果窗口已在托盘或还没打开：启动 Codex 应用入口，把窗口唤回

## 使用前准备

1. 安装 [AutoHotkey v2](https://www.autohotkey.com/)。
2. 在 Chrome、Edge 或其他浏览器中把 Gemini 和 ChatGPT 安装为 PWA。
3. 如需使用 VS Code 热键，请先安装 VS Code。
4. 双击运行 `pwa-toggle.ahk`。

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

## 修改热键

热键在脚本顶部这些行：

```ahk
apps.Push(MakeApp("Google Gemini", "^!g", ["Google Gemini", "Gemini"], ["Google Gemini.lnk", "Gemini.lnk"], "https://gemini.google.com/app", geminiLaunchPath, BrowserProcessNames(), false))
apps.Push(MakeApp("ChatGPT中文", "^!c", ["ChatGPT中文", "ChatGPT"], ["ChatGPT中文.lnk", "ChatGPT.lnk"], "https://chatgpt.com/", chatgptLaunchPath, BrowserProcessNames(), false))
apps.Push(MakeApp("VS Code", "^!v", ["Visual Studio Code", "VS Code"], ["Visual Studio Code.lnk", "VS Code.lnk", "Code.lnk"], "", vscodeLaunchPath, ["Code.exe"], false))
apps.Push(MakeApp("Codex", "!c", ["Codex"], ["Codex.lnk"], "", codexLaunchPath, ["Codex.exe"], true))
```

AutoHotkey 热键符号：

- `^` 表示 `Ctrl`
- `!` 表示 `Alt`
- `#` 表示 `Win`
- `+` 表示 `Shift`

例如 `^!g` 就是 `Ctrl + Alt + G`。

## 开机自动运行

按 `Win + R`，输入：

```text
shell:startup
```

把 `pwa-toggle.ahk` 的快捷方式放到打开的文件夹里。

## 说明

这个脚本使用窗口标题和进程名来识别窗口。PWA 支持 Chrome、Edge、Brave、Vivaldi、Opera 和 Firefox 的常见进程名；VS Code 使用 `Code.exe` 识别；Codex 使用 `Codex.exe` 识别，并通过系统关闭按钮动作进入托盘。

如果你误隐藏了窗口，可以按 `Ctrl + Alt + R` 恢复。退出脚本时，它也会尽量自动恢复被隐藏的窗口。

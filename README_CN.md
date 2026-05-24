<p align="center"><img src="favicon.png" width="80" alt="Subtitle Overlay"></p>

# 字幕叠加

实时语音识别字幕，从 Mac 系统音频采集。可捕获任意应用的音频，设备端转写，悬浮窗口显示——可选机器翻译。

**关键词：** 语音识别、实时转写、系统音频采集、设备端 ASR、悬浮字幕、ScreenCaptureKit、Apple 神经网络引擎、离线字幕、语言学习、机器翻译、macOS 无障碍、实时字幕、SFSpeechRecognizer、TranslationSession、whisper.cpp

[English](README.md) | 简体中文

![platform](https://img.shields.io/badge/platform-macOS%2026%2B-blue)
![swift](https://img.shields.io/badge/swift-5.0-orange)

## 功能特性

### 语音识别（音频 → 文字）

- **指定应用系统音频采集** — 选择任意运行中的应用（浏览器、播放器、会议工具），通过 ScreenCaptureKit 单独捕获其音频，不影响其他系统声音
- **实时设备端转写** — 基于 Apple Speech 框架的低延迟语音转文字，Apple 神经网络引擎驱动，部分结果实时流式输出
- **双识别引擎** — Apple Speech（默认，零配置，50+ 语言）或 Whisper（自定义 GGML 模型导入，基于 whisper.cpp）
- **多语言识别** — 在设置中从 14 种识别语言中选择：英语（美/英）、中文（普通话/粤语）、日语、韩语、法语、德语、西班牙语、葡萄牙语、俄语、意大利语、荷兰语、阿拉伯语。模型首次使用时自动下载

### 机器翻译（文字 → 文字）

- **设备端翻译** — Apple Translation 框架，完全在神经网络引擎上本地运行；模型下载后无需网络
- **17 种目标语言** — 在设置中选择翻译目标语言：中文（简体/繁体）、日语、韩语、法语、德语、西班牙语、葡萄牙语、俄语、意大利语、荷兰语、阿拉伯语、泰语、越南语、波兰语、土耳其语、印尼语
- **一键开关** — 在设置中随时开启/关闭翻译；翻译文本渲染在原文字幕下方

### 显示与交互

- **悬浮覆盖层** — 半透明、始终置顶的 NSPanel，全屏视频上方依然可见；可拖拽、自动调整大小
- **历史字幕行** — 最近说过的内容淡出显示在当前字幕上方；可调节行数（1–5 行）
- **外观可定制** — 可调节字体大小（14–36pt）、背景不透明度（10–90%）和窗口宽度
- **完全设备端处理** — 语音识别和翻译全部在 Apple Silicon 上本地运行；模型下载后离线可用，数据不出 Mac
- **界面语言切换** — 英文 / 中文界面，在设置中切换（需重启）

## 环境要求

- macOS 26.0 或更高版本
- Apple Silicon Mac
- 目标语言的语音识别模型 — 首次使用时 macOS 自动下载
- 翻译模型 — 需从系统设置为每对语言手动下载（一次性设置）

## 快速开始

1. 在 Xcode 中打开 `SubtitleOverlay.xcodeproj`
2. 选择 **SubtitleOverlay** scheme，目标选择你的 Mac
3. 按 **Cmd+R** 构建并运行
4. 根据提示授予屏幕录制和语音识别权限

## 使用说明

1. 在任意应用中播放音频（Netflix、YouTube、Zoom、Safari、Chrome 等）
2. 在字幕叠加应用的下拉菜单中选择目标应用
3. 点击**开始**即可开始音频采集和转写
4. 字幕悬浮窗口出现——可拖拽至屏幕任意位置
5. 打开设置（**Cmd+,**）可：
   - 从下拉菜单中选择识别语言和翻译目标语言
   - 开关翻译
   - 调整字体大小、背景不透明度和历史行数
   - 切换识别引擎或导入 Whisper 模型
   - 更改界面语言

### 翻译功能设置

设备端翻译需要从系统设置下载语言模型：

1. 打开**系统设置** → **通用** → **语言与地区**
2. 滚动到底部 → **翻译语言**
3. 下载源语言和目标语言的模型
4. 在字幕叠加中点击**刷新**确认状态

> 翻译模型与系统语言包是不同的东西。将某种语言设为系统首选语言并不会自动安装其翻译模型。

## 识别与翻译 — 两个独立系统

本应用将**语音识别**（音频 → 文字）和**机器翻译**（文字 → 文字）分为两个独立模块，可通过设置界面各自配置。

### 语音识别

| 项目 | 详情 |
|------|------|
| **框架** | `Speech` (SFSpeechRecognizer) |
| **引擎选项** | Apple Speech（设备端）或 Whisper（自定义 GGML） |
| **如何切换语言** | 设置 → Model 标签页 → 识别语言下拉菜单 — 从 14 种支持的语言中选择 |
| **支持的语言** | 阿拉伯语、中文（普通话、粤语）、荷兰语、英语（美/英）、法语、德语、意大利语、日语、韩语、葡萄牙语、俄语、西班牙语等 |
| **模型下载** | 自动 — macOS 在首次使用时下载对应 locale 的设备端模型 |

### 翻译

| 项目 | 详情 |
|------|------|
| **框架** | `Translation` (TranslationSession) |
| **如何切换目标语言** | 设置 → Model 标签页 → 翻译为下拉菜单 — 从 17 种目标语言中选择 |
| **支持的目标语言** | 阿拉伯语、中文（简体/繁体）、荷兰语、法语、德语、印尼语、意大利语、日语、韩语、波兰语、葡萄牙语、俄语、西班牙语、泰语、土耳其语、越南语 |
| **模型下载** | 手动 — 系统设置 → 通用 → 语言与地区 → 翻译语言 |

## 工作原理

```
 目标应用音频 → ScreenCaptureKit → SCStream (16kHz 单声道 PCM)
                                            ↓
                            ┌─── 语音识别层 ──────────┐
                            │ SFSpeechRecognizer（设备端）│
                            │ 或 whisper.cpp（自定义模型） │
                            └──────────┬──────────────┘
                                       ↓
                                   识别文字
                                       ↓
                            ┌─── 翻译层（可选）─────────┐
                            │ TranslationSession（设备端）│
                            └──────────┬──────────────┘
                                       ↓
                            ┌────── 翻译文字 ──────┐
                            ↓                      ↓
                   ContentView 预览         SubtitlePanelView
                   （实时转写）              （悬浮字幕窗口）
```

| 层级 | 框架 | 说明 |
|------|------|------|
| 音频采集 | ScreenCaptureKit | 16kHz 单声道指定应用音频，队列深度 1 最小延迟 |
| **语音识别** | **Speech** (SFSpeechRecognizer) | 设备端 ASR，Apple 神经网络引擎；`.search` 模式低延迟；支持 50+ 语言 |
| **翻译** | **Translation** (TranslationSession) | 设备端神经机器翻译，Apple 神经网络引擎；支持 15+ 语言对 |
| 悬浮窗口 | SwiftUI + AppKit | NSPanel（`.nonActivatingPanel`、`.floating` 层级、无边框），通过 NSHostingView 嵌入 SwiftUI |

## 项目结构

```
SubtitleOverlay/
├── SubtitleOverlay.xcodeproj/
├── SubtitleOverlay/
│   ├── App/                        # 应用入口和代理
│   ├── Services/                   # AudioCaptureManager, SpeechRecognizer,
│   │                                 TranslationService, WhisperRecognizer
│   ├── UI/                         # ContentView, SettingsView, SubtitlePanelView,
│   │                                 SubtitleWindowController
│   ├── Models/                     # AppSettings, LanguageManager, LanguageOptions
│   ├── Resources/                  # Localizable.xcstrings, entitlements
│   └── Assets.xcassets/            # App 图标
├── Info.plist
├── favicon.png
├── LICENSE
├── README.md
└── README_CN.md
```

## 常见问题

| 问题 | 解决方法 |
|------|----------|
| 下拉菜单中无应用 | 在系统设置 > 隐私与安全性 > 屏幕录制中授权，然后重启应用 |
| 语音识别不可用 | 确认已下载所选语言的语音模型：系统设置 > 隐私与安全性 > 语音识别 |
| 翻译不显示 | 在设置中开启翻译；从系统设置 > 通用 > 语言与地区 > 翻译语言下载模型；点击刷新 |
| 翻译显示"模型未安装" | 翻译模型 ≠ 系统语言包。滚动到语言与地区页面底部找到翻译语言部分 |
| 无法采集音频 | 确认目标应用正在播放音频且其窗口在屏幕上可见 |
| 字幕延迟 | 减小 AudioCaptureManager 中的 `queueDepth`（默认 1）；确保使用 `.search` 模式 |

## 开源协议

Copyright (c) 2025 SweelLong。详见 [LICENSE](LICENSE)。

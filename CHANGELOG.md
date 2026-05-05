# Changelog

所有版本变更记录，格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)。

---

## [Unreleased]

---

## [0.3.0] - 2026-05-05

### Added
- **录音页声波动画**：录音时 30 根柱子根据麦克风振幅实时跳动（100ms 采样），停止后平滑归零
- **快速记录字数统计**：底部弹层实时显示已输入字数
- **保存触觉反馈**：快速记录保存时轻震（HapticFeedback.lightImpact）
- **提醒倒计时标签**：提醒卡片显示距提醒时间的倒计时（X天后/X小时后/即将提醒），过期显示红色「已过期」

### Changed
- 提醒卡片过期状态图标从 `alarm` 改为 `alarm_off`

---

## [0.2.0] - 2026-05-05

### Added
- **首页日期分组**：笔记列表按「今天 / 昨天 / 本周 / 月份」分组，每组显示数量
- **类型筛选栏数量角标**：每个类型筛选按钮旁实时显示该类型笔记数量
- **卡片长按上下文菜单**：长按弹出底部菜单，支持查看详情 / AI 分析 / 复制内容 / 设置提醒 / 删除（二次确认）
- **首页直接触发 AI 分析**：无需进入详情页，长按菜单即可触发分析
- **复制内容**：长按菜单一键复制笔记摘要或正文到剪贴板
- `noteCountByType` provider：按类型统计笔记数量的实时 Stream

---

## [0.1.0] - 2026-05-04

### Added
- **类型筛选栏**：首页横向滑动筛选语音 / 会议 / 对话 / 文字
- **AI action_items 转提醒**：详情页 AI Tab 中，待办事项可一键转为系统提醒
- **录音后自动 AI 分析**：设置中开启后，录音保存时自动触发分析
- **Snooze 稍后提醒**：通知到达后可选择 5 分钟 / 30 分钟 / 明天再提醒
- **aiServiceProvider**：Riverpod provider，支持全局注入 AiService

### Fixed
- NDK 版本从 flutter 默认值升级至 27.0.12077973（兼容插件要求）
- `StateProvider` missing import（note_providers.dart）
- speech_to_text 升级至 7.3.0（6.x Registrar API 与当前 Kotlin 不兼容）

---

## [0.0.1] - 2026-05-03

### Added
- 项目初始化：Flutter Android 应用框架
- 录音功能（record + speech_to_text 实时转写）
- 快速文字记录（底部弹层 + 图片附件）
- 笔记详情页（内容 Tab / AI Tab / 提醒 Tab）
- AI 分析（OpenAI 兼容接口，JSON 结构化输出）
- 本地提醒（flutter_local_notifications）
- Drift 本地数据库（Schema v2：notes + reminders + settings）
- 深色主题 + 类型色系（AppTheme）
- GitHub Actions CI 自动构建 APK

# ⚡ 闪记 Flash Note

> 想法到笔记，3秒以内。

一款极简的 Android/iOS 语音/文字记录应用，以"快"为核心：按下按钮即录，说完即存，AI 自动整理。

---

## ✨ 功能全览

### 📝 记录
- **语音录音**：一键录音，实时声波可视化，录音结束自动保存
- **实时语音转写**：录音过程中同步显示转写文字（zh_CN）
- **快速文字记录**：首页浮动按钮弹出底部输入框，实时字数统计，保存后触觉反馈
- **图片附件**：录音/文字记录均支持附加最多 9 张图片
- **记录类型**：语音 / 会议 / 对话 / 文字，颜色区分，图标标注

### 🤖 AI 分析
- **自动分析**：录音保存后可自动触发 AI 分析（设置中开关控制）
- **手动分析**：首页卡片长按菜单 → "AI 分析"，或进入详情页点击按钮
- **分析内容**：摘要、待办事项、提醒建议、标签、情绪倾向（positive/neutral/negative）
- **情绪标注**：首页卡片右上角显示情绪色点（绿/灰/红）
- **AI 待办角标**：分析完成后卡片直接显示「N项待办」橙色角标
- **一键转提醒**：AI 识别出的 action_items 可直接转换为系统提醒
- **全局 AI 问答**：跨所有笔记提问，如「这周有哪些待办？」

### ⏰ 提醒
- **自定义提醒**：为任意笔记设置一个或多个提醒时间
- **重复周期**：支持不重复 / 每天 / 每周 / 每月
- **倒计时标签**：提醒卡片实时显示"X天后 / X小时后 / 即将提醒 / 已过期"
- **Snooze 功能**：通知到达后可选择稍后提醒（5分钟 / 30分钟 / 明天）
- **日历导出**：提醒一键导出为 `.ics` 文件，导入系统日历
- **开关控制**：每条提醒可单独启用/禁用

### 🏠 首页
- **日期分组**：今天 / 昨天 / 本周 / 月份，每组显示笔记数量
- **类型筛选栏**：横向滑动筛选类型，每项实时显示数量角标
- **列表 / 时间线视图**：AppBar 一键切换，时间线视图更有日记感
- **卡片长按菜单**：查看详情 / AI 分析 / 复制内容 / 设置提醒 / 删除（二次确认）
- **滑动删除**：卡片左滑快速删除
- **标签展示**：AI 分析后的标签直接显示在卡片上

### 🔍 搜索
- **全文搜索**：按内容 / 转写 / 摘要搜索
- **热门标签云**：搜索框为空时展示高频标签，点击直接过滤

### 📤 分享与导出
- **导出格式**：TXT / JSON / Markdown 三种格式
- **单条笔记分享**：复制摘要 / 分享为文本 / 分享原始录音文件
- **飞书分享**：一键复制内容并跳转飞书

### 📊 数据统计
- **统计页面**：本周新增、各类型分布、AI 分析覆盖率、最常用标签 TOP5

### 🎨 个性化
- **主题切换**：深色 / 浅色 / 跟随系统，设置页 SegmentedButton 切换

### ⚡ 快捷入口
- **Android 快捷方式**：长按桌面图标 → 「快速录音」直接进录音页
- **iOS Siri URL Scheme**：支持 `flashnote://action/quick_record` 深度链接

---

## 🛠 技术栈

| 层 | 技术 |
|---|---|
| UI 框架 | Flutter 3.29 |
| 状态管理 | Riverpod + riverpod_annotation |
| 路由 | go_router |
| 本地数据库 | Drift (SQLite) |
| 语音录制 | record |
| 语音转写 | speech_to_text |
| 本地通知 | flutter_local_notifications |
| AI 接入 | 自定义 HTTP（OpenAI 兼容接口） |
| 分享 | share_plus |
| 图片选择 | image_picker |
| 滑动操作 | flutter_slidable |

---

## 🗄 数据库 Schema

| 表 | 说明 |
|---|---|
| Notes | 笔记主表（含 sentiment、imagePaths 字段） |
| Reminders | 提醒表（含 repeat 周期字段） |
| AiChats | AI 对话历史（noteId 为 null 表示全局问答） |
| AppSettings | 用户设置（含 theme_mode 等） |

当前 schemaVersion = **4**，支持自动升级迁移。

---

## 🚀 构建

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter build apk --release
```

CI/CD 由 GitHub Actions 自动触发，每次 push main 分支后构建 APK 并上传 Artifacts。

---

## 📁 项目结构

```
lib/
├── core/
│   ├── ai/          # AI 服务
│   ├── database/    # Drift 数据库 + 表定义
│   ├── reminder/    # 提醒服务
│   ├── router/      # GoRouter 路由
│   └── theme/       # 主题 + ThemeProvider
├── features/
│   ├── home/        # 首页（列表/时间线）
│   ├── record/      # 录音页
│   ├── detail/      # 笔记详情
│   ├── search/      # 搜索 + 标签云
│   ├── stats/       # 统计页
│   ├── ai_chat/     # 全局 AI 问答
│   └── settings/    # 设置 + 导出
└── main.dart
```

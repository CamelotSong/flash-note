# ⚡ 闪记 Flash Note

> 想法到笔记，3秒以内。

一款极简的 Android 语音/文字记录应用，以"快"为核心：按下按钮即录，说完即存，AI 自动整理。

---

## ✨ 核心功能

### 📝 记录
- **语音录音**：一键录音，实时声波可视化，录音结束自动保存
- **实时语音转写**：录音过程中同步显示转写文字（zh_CN）
- **快速文字记录**：首页浮动按钮弹出底部输入框，实时字数统计，保存后触觉反馈
- **图片附件**：录音/文字记录均支持附加最多 9 张图片
- **记录类型**：语音 / 会议 / 对话 / 文字，颜色区分，图标标注

### 🤖 AI 分析
- **自动分析**：录音保存后可自动触发 AI 分析（设置中开关控制）
- **手动分析**：首页卡片长按菜单 → "AI 分析"，或进入详情页点击按钮
- **分析内容**：摘要、待办事项（action_items）、提醒建议、标签、情绪倾向
- **一键转提醒**：AI 识别出的 action_items 可直接转换为系统提醒

### ⏰ 提醒
- **自定义提醒**：为任意笔记设置一个或多个提醒时间
- **倒计时标签**：提醒卡片实时显示"X天后 / X小时后 / 即将提醒 / 已过期"
- **Snooze 功能**：通知到达后可选择稍后提醒（5分钟 / 30分钟 / 明天）
- **开关控制**：每条提醒可单独启用/禁用

### 🏠 首页
- **日期分组**：今天 / 昨天 / 本周 / 月份，每组显示笔记数量
- **类型筛选栏**：横向滑动筛选类型，每项实时显示数量角标
- **卡片长按菜单**：查看详情 / AI 分析 / 复制内容 / 设置提醒 / 删除（二次确认）
- **滑动删除**：卡片左滑快速删除
- **标签展示**：AI 分析后的标签直接显示在卡片上

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

---

## ⚙️ AI 配置

进入「设置」页面配置：
- **Base URL**：OpenAI 兼容 API 地址（如 `https://api.openai.com/v1`）
- **API Key**：你的密钥
- **Model**：模型名称（如 `gpt-4o-mini`）

配置完成后，录音保存时可自动触发分析，或在首页长按卡片手动触发。

---

## 🏗 构建

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter build apk --release
```

CI/CD 通过 GitHub Actions 自动构建，每次 push 触发，产物为 `flash-note-release.zip`。

---

## 📋 数据库 Schema

版本：**2**

| 表 | 说明 |
|---|---|
| `notes` | 笔记主表（content, type, title, summary, tags, analyzed, imagePaths, audioPath） |
| `reminders` | 提醒表（noteId, title, remindAt, enabled, status） |
| `settings` | 键值配置表（ai_base_url, ai_api_key, ai_model, auto_analyze） |

# Bookkeeping - 记账本

一款功能完整的 iOS 记账应用，基于 SwiftUI + SwiftData 构建。

## 功能特性

### 核心功能
- 📝 **记账管理** - 收入/支出记录，支持多分类
- 💰 **多账户** - 现金、银行卡、支付宝、微信等
- 📊 **预算管理** - 总预算、分类预算，超支提醒
- 📒 **多账本** - 个人、家庭、旅行、工作分类管理
- 🎯 **储蓄目标** - 目标设定与进度追踪
- 🔄 **周期账单** - 自动生成周期性交易
- 💳 **债务管理** - 借出/借入追踪 (IOU)
- 🏷️ **标签系统** - 多维度交易分类

### 智能功能
- 🎤 **语音记账** - 语音识别自动填入金额和分类
- 📷 **收据扫描** - OCR 识别收据金额
- 💱 **汇率转换** - 支持 8 种货币实时汇率
- 📅 **财务日历** - 按日查看收支明细
- 📈 **趋势分析** - 消费趋势预测

### 数据管理
- ☁️ **iCloud 同步** - 数据云端备份
- 📤 **导入导出** - 支持 CSV/JSON 格式
- 🔔 **通知提醒** - 账单提醒、预算预警、月度报告
- 🔒 **应用锁** - Face ID / Touch ID 保护
- 🌐 **多语言** - 中文简体、繁体、英文、法文

## 技术栈

| 技术 | 用途 |
|------|------|
| SwiftUI | UI 框架 |
| SwiftData | 数据持久化 |
| Vision | OCR 识别 |
| Speech | 语音识别 |
| UserNotifications | 本地通知 |
| App Intents | Siri 集成 |

## 项目结构

```
Bookkeeping/
├── Models/           # 数据模型
├── ViewModels/       # 业务逻辑
├── Views/            # 视图界面
├── Services/         # 服务层
├── Resources/        # 资源文件
└── BookkeepingWidget/# 小组件
```

## 安装要求

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## 快速开始

1. 克隆项目
```bash
git clone https://github.com/luosicx/Bookkeeping.git
```

2. 使用 XcodeGen 生成项目（可选）
```bash
xcodegen generate
```

3. 打开 `Bookkeeping.xcodeproj` 运行

## 许可证

MIT License

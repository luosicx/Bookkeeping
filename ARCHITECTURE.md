# Bookkeeping 架构文档

## 项目概览

iOS 记账应用，基于 SwiftUI + SwiftData 构建，支持多账本、预算管理、周期账单、数据分析等功能。

## 技术栈

- **UI**: SwiftUI
- **数据层**: SwiftData (ORM)
- **最低版本**: iOS 17.0
- **语言**: Swift 5.9
- **本地化**: 中文简体、中文繁体、英文、法文

## 目录结构

```
Bookkeeping/
├── BookkeepingApp.swift      # App 入口，配置 ModelContainer
├── Models/                   # 数据模型层
│   ├── Transaction.swift     # 交易记录 (收入/支出)
│   ├── Account.swift         # 账户 (现金/银行卡/支付宝/微信等)
│   ├── Budget.swift          # 预算 (总预算/分类预算)
│   ├── Ledger.swift          # 账本 (个人/家庭/旅行/工作)
│   ├── SavingsGoal.swift     # 储蓄目标
│   ├── RecurringTransaction.swift  # 周期性交易
│   ├── BillReminder.swift    # 账单提醒
│   ├── CustomCategory.swift  # 自定义分类
│   └── Category.swift        # 预设分类
├── ViewModels/               # 业务逻辑层
│   ├── TransactionViewModel.swift
│   ├── AccountViewModel.swift
│   ├── BudgetViewModel.swift
│   ├── LedgerViewModel.swift
│   ├── SavingsGoalViewModel.swift
│   ├── RecurringTransactionViewModel.swift
│   └── BillReminderViewModel.swift
├── Views/                    # 视图层
│   ├── MainTabView.swift     # 主 Tab 导航
│   ├── HomeView.swift        # 首页
│   ├── StatisticsView.swift  # 统计分析
│   ├── SettingsView.swift    # 设置
│   └── ...                   # 其他功能页面
├── Services/                 # 服务层
│   ├── BackupService.swift   # iCloud 备份
│   ├── ExportService.swift   # 导出功能
│   ├── ImportService.swift   # 导入功能
│   ├── NotificationService.swift  # 通知
│   ├── SpeechRecognizer.swift     # 语音输入
│   ├── ThemeManager.swift    # 主题管理
│   └── ...
└── Resources/                # 资源文件
    ├── Info.plist
    ├── Localizable.strings
    └── Assets.xcassets

BookkeepingWidget/            # 桌面小组件
```

## 架构模式

采用 **MVVM** 模式：

```
View → ViewModel → Model (SwiftData)
```

- **View**: 纯 UI 层，通过 `@StateObject` / `@ObservedObject` 绑定 ViewModel
- **ViewModel**: 业务逻辑，使用 `@Observable` 宏 (iOS 17+)
- **Model**: SwiftData `@Model` 标注的数据模型

## 数据模型关系

```
┌─────────────┐     ┌─────────────┐
│   Ledger    │────<│ Transaction │
└─────────────┘     └─────────────┘
                           │
                           ▼
                    ┌─────────────┐
                    │   Account   │
                    └─────────────┘

┌─────────────┐     ┌─────────────┐
│   Budget    │     │   Savings   │
└─────────────┘     └─────────────┘
       │
       ▼ (category 绑定)
```

## 核心功能模块

| 模块 | 功能 | 关键文件 |
|------|------|----------|
| 交易管理 | 收入/支出记录、分类、账户关联 | TransactionViewModel |
| 账户管理 | 多账户、余额追踪 | AccountViewModel |
| 预算管理 | 总预算、分类预算、超支提醒 | BudgetViewModel, BudgetAlertManager |
| 账本管理 | 多账本隔离 (个人/家庭/旅行) | LedgerViewModel |
| 储蓄目标 | 目标设定、进度追踪 | SavingsGoalViewModel |
| 周期账单 | 自动生成周期性交易 | RecurringTransactionViewModel |
| 数据统计 | 图表分析、趋势预测 | StatisticsView, TrendPredictor |
| 导入导出 | CSV/Excel 导入导出 | ImportService, ExportService |
| 语音输入 | 语音识别记账 | SpeechRecognizer |
| 小组件 | 首页显示月度收支 | BookkeepingWidget |
| 通知提醒 | 账单提醒、预算预警 | NotificationService, BillReminderViewModel |
| 备份恢复 | iCloud 同步、数据备份 | BackupService, CloudSyncService |

## 数据共享

应用与小组件通过 App Groups 共享数据：

```swift
UserDefaults(suiteName: "group.com.bookkeeping.app")
```

SharedDataManager 负责读写共享数据。

## 状态管理

- ViewModel 使用 `@Observable` 宏 (iOS 17 Observation 框架)
- 主题通过单例 `ThemeManager.shared` 管理
- 通知通过 `NotificationService.shared` 管理

## 构建配置

使用 **XcodeGen** 生成 Xcode 项目，配置文件为 `project.yml`：

```yaml
# project.yml 核心配置
name: Bookkeeping
options:
  bundleIdPrefix: com.bookkeeping
  deploymentTarget:
    iOS: "17.0"
  xcodeVersion: "15.0"

targets:
  Bookkeeping:        # 主应用
  BookkeepingWidget:  # 小组件扩展
  BookkeepingTests:   # 单元测试
  BookkeepingUITests: # UI 测试
```

生成项目：`xcodegen generate`

## 权限与能力

| 权限 | 用途 |
|------|------|
| iCloud / CloudKit | 数据云端同步 |
| App Groups | 主应用与小组件数据共享 |
| 语音识别 | 语音输入记账 |
| Face ID / Touch ID | 应用锁 |
| 本地通知 | 账单提醒、预算预警 |

## 服务层设计

Services 层采用 **单例模式** (`static let shared`)，提供全局访问：

```
┌─────────────────────────────────────────────┐
│              Services                       │
├─────────────────────────────────────────────┤
│ ThemeManager.shared      → 主题切换         │
│ NotificationService.shared → 推送通知       │
│ BudgetAlertManager.shared  → 预算预警       │
│ SharedDataManager.shared   → Widget 数据    │
│ CloudSyncService.shared    → iCloud 同步    │
│ BackupService              → 数据备份       │
│ SpeechRecognizer           → 语音识别       │
│ CurrencyService            → 汇率/货币      │
│ ExportService / ImportService → 导入导出    │
│ SampleData                 → 示例数据       │
└─────────────────────────────────────────────┘
```

## 小组件数据流

```
┌──────────┐     App Groups      ┌──────────┐
│   App    │ ──────────────────> │  Widget  │
│          │  SharedDataManager  │          │
│          │ <────────────────── │          │
└──────────┘                     └──────────┘
```

数据通过 `UserDefaults(suiteName: "group.com.bookkeeping.app")` 共享月度收支数据。

## 导航结构

```
MainTabView
├── Tab 0: HomeView (首页)
├── Tab 1: StatisticsView (统计)
└── Tab 2: SettingsView (设置)
```

HomeView 内部使用 NavigationStack 管理子页面导航。

# 记账应用 (Bookkeeping)

一个基于 SwiftUI 和 SwiftData 的 iOS 记账应用。

## 功能特性

### 核心功能
- 记录收入和支出
- 分类管理（餐饮、交通、购物等 12 个分类）
- 月度统计和图表
- 数据持久化（SwiftData）

### 新增功能
- **滑动删除**：左滑删除交易记录
- **编辑功能**：点击记录可编辑详情
- **搜索功能**：按分类或备注搜索
- **月份筛选**：按月份查看统计数据
- **数据导出**：支持 CSV、Excel 和 JSON 格式导出
- **支出排行**：查看各分类支出排名
- **多语言支持**：简体中文、繁体中文、英语、法语
- **数据备份**：JSON 格式备份，支持恢复
- **预算管理**：设置总预算和分类预算，超支时自动提醒
- **多账户支持**：现金、银行卡、支付宝、微信等分开管理
- **定期记账**：自动记录房租、工资等固定收支
- **年度报告**：全年收支汇总、同比分析
- **多账本管理**：支持个人、家庭、旅行等不同账本
- **储蓄目标**：设定存钱目标并追踪进度
- **应用锁**：指纹/面容解锁保护隐私
- **深色模式**：自动跟随系统深色/浅色模式
- **账单提醒**：信用卡还款日、水电费等提醒
- **Widget 小组件**：桌面显示本月收支概览
- **iCloud 同步**：多设备数据同步
- **账本统计**：查看每个账本的收支统计
- **数据导入**：从 CSV/JSON 文件导入已有数据
- **多币种支持**：支持12种货币和汇率转换，零小数货币格式化
- **自定义分类**：添加自定义支出/收入分类
- **数据分享**：分享账单给家人或朋友
- **趋势预测**：基于历史数据预测支出趋势，含置信区间和异常检测
- **预算超支提醒**：超支时自动发送通知提醒
- **图表美化**：渐变填充、自定义配色、动画效果
- **语音记账**：语音输入自动解析金额和分类
- **报告分享图片**：生成可分享的月度报告图片

## 技术栈

- SwiftUI - 声明式 UI 框架
- SwiftData - 数据持久化（iOS 17+）
- Swift Charts - 图表展示
- MVVM - 架构模式

## 项目结构

```
Bookkeeping/
├── Models/           # 数据模型
│   ├── Transaction.swift
│   ├── Category.swift
│   ├── Budget.swift
│   ├── Account.swift
│   ├── RecurringTransaction.swift
│   ├── Ledger.swift
│   └── SavingsGoal.swift
├── ViewModels/       # 视图模型
│   ├── TransactionViewModel.swift
│   ├── BudgetViewModel.swift
│   ├── AccountViewModel.swift
│   ├── RecurringTransactionViewModel.swift
│   ├── LedgerViewModel.swift
│   └── SavingsGoalViewModel.swift
├── Views/            # 视图
│   ├── MainTabView.swift
│   ├── HomeView.swift
│   ├── AddTransactionView.swift
│   ├── TransactionDetailView.swift
│   ├── StatisticsView.swift
│   ├── SettingsView.swift
│   ├── BackupView.swift
│   ├── ExportView.swift
│   ├── BudgetView.swift
│   ├── AddBudgetView.swift
│   ├── AccountView.swift
│   ├── AddAccountView.swift
│   ├── RecurringTransactionView.swift
│   ├── AddRecurringTransactionView.swift
│   ├── AnnualReportView.swift
│   ├── LedgerView.swift
│   ├── SavingsGoalView.swift
│   └── AppLockView.swift
├── Services/         # 服务层
│   ├── Localization.swift
│   ├── BackupService.swift
│   ├── ExportService.swift
│   ├── SampleData.swift
│   ├── BiometricAuth.swift
│   └── ThemeManager.swift
├── Resources/        # 资源文件
│   ├── Assets.xcassets
│   ├── Info.plist
│   ├── zh-Hans.lproj/
│   ├── zh-Hant.lproj/
│   ├── en.lproj/
│   └── fr.lproj/
└── BookkeepingApp.swift  # 应用入口
```

## 使用方法

1. 在 Xcode 中打开 `Bookkeeping.xcodeproj`
2. 选择模拟器（iPhone 17 Pro）
3. 按 `Cmd + R` 运行应用

## 功能说明

### 首页
- 账本选择器（个人、家庭、旅行等）
- 显示当月收支汇总
- 按月份切换查看
- 搜索交易记录
- 筛选收入/支出
- 点击记录查看详情

### 添加记录
- 选择收入/支出类型
- 输入金额
- 选择分类
- 添加备注
- 选择日期

### 统计页面
- 月度收支汇总
- 预算管理入口
- 年度报告入口
- 支出分类饼图
- 收支趋势折线图
- 支出分类排行

### 设置页面
- 货币单位设置
- 主题切换（深色/浅色模式）
- 应用锁（指纹/面容解锁）
- 账单提醒
- 储蓄目标
- 定期记账
- 账本管理
- 账户管理
- 数据备份与恢复
- 数据导出（CSV/Excel/JSON）
- 清除所有数据

## 后续优化

- [ ] 通知提醒完善
- [ ] 图表美化
- [ ] 数据导入
- [ ] 汇率转换

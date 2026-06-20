import Foundation

extension String {
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
    
    func localized(_ args: CVarArg...) -> String {
        String(format: NSLocalizedString(self, comment: ""), arguments: args)
    }
}

struct Localization {
    static let shared = Localization()
    
    private init() {}
    
    // MARK: - General
    var appName: String { "app_name".localized }
    var cancel: String { "cancel".localized }
    var save: String { "save".localized }
    var delete: String { "delete".localized }
    var edit: String { "edit".localized }
    var search: String { "search".localized }
    var done: String { "done".localized }
    var confirm: String { "confirm".localized }
    var close: String { "close".localized }
    
    // MARK: - Tabs
    var tabHome: String { "tab_home".localized }
    var tabStatistics: String { "tab_statistics".localized }
    var tabSettings: String { "tab_settings".localized }
    
    // MARK: - Home
    var homeTitle: String { "home_title".localized }
    var monthlyBalance: String { "monthly_balance".localized }
    var income: String { "income".localized }
    var expense: String { "expense".localized }
    var recentTransactions: String { "recent_transactions".localized }
    var noTransactions: String { "no_transactions".localized }
    var addFirstRecord: String { "add_first_record".localized }
    var all: String { "all".localized }
    
    func transactionCount(_ count: Int) -> String {
        "transaction_count".localized(count)
    }
    
    // MARK: - Add Transaction
    var addTransaction: String { "add_transaction".localized }
    var transactionType: String { "transaction_type".localized }
    var amount: String { "amount".localized }
    var category: String { "category".localized }
    var note: String { "note".localized }
    var date: String { "date".localized }
    var selectDate: String { "select_date".localized }
    var addNote: String { "add_note".localized }
    var amountPlaceholder: String { "amount_placeholder".localized }
    
    // MARK: - Transaction Detail
    var transactionDetail: String { "transaction_detail".localized }
    var basicInfo: String { "basic_info".localized }
    var deleteRecord: String { "delete_record".localized }
    var editRecord: String { "edit_record".localized }
    var confirmDelete: String { "confirm_delete".localized }
    var deleteMessage: String { "delete_message".localized }
    
    // MARK: - Categories - Expense
    var categoryFood: String { "category_food".localized }
    var categoryTransport: String { "category_transport".localized }
    var categoryShopping: String { "category_shopping".localized }
    var categoryEntertainment: String { "category_entertainment".localized }
    var categoryHousing: String { "category_housing".localized }
    var categoryMedical: String { "category_medical".localized }
    var categoryEducation: String { "category_education".localized }
    var categoryOtherExpense: String { "category_other_expense".localized }
    
    // MARK: - Categories - Income
    var categorySalary: String { "category_salary".localized }
    var categoryBonus: String { "category_bonus".localized }
    var categoryInvestment: String { "category_investment".localized }
    var categoryOtherIncome: String { "category_other_income".localized }
    
    // MARK: - Statistics
    var statisticsTitle: String { "statistics_title".localized }
    var periodWeek: String { "period_week".localized }
    var periodMonth: String { "period_month".localized }
    var periodYear: String { "period_year".localized }
    var expenseCategory: String { "expense_category".localized }
    var incomeExpenseTrend: String { "income_expense_trend".localized }
    var topExpenses: String { "top_expenses".localized }
    var noData: String { "no_data".localized }
    
    func transactionCountFormat(_ count: Int) -> String {
        "transaction_count_format".localized(count)
    }
    
    // MARK: - Settings
    var settingsTitle: String { "settings_title".localized }
    var basicSettings: String { "basic_settings".localized }
    var security: String { "security".localized }
    var tools: String { "tools".localized }
    var currencyUnit: String { "currency_unit".localized }
    var theme: String { "theme".localized }
    var themeSystem: String { "theme_system".localized }
    var themeLight: String { "theme_light".localized }
    var themeDark: String { "theme_dark".localized }
    var dataManagement: String { "data_management".localized }
    var exportData: String { "export_data".localized }
    var clearAllData: String { "clear_all_data".localized }
    var about: String { "about".localized }
    var version: String { "version".localized }
    var developer: String { "developer".localized }
    var exportSuccess: String { "export_success".localized }
    var confirmClear: String { "confirm_clear".localized }
    var clearMessage: String { "clear_message".localized }
    
    func exportMessage(_ path: String) -> String {
        "export_message".localized(path)
    }
    
    func exportFailed(_ error: String) -> String {
        "export_failed".localized(error)
    }
    
    // MARK: - Transaction Types
    var incomeType: String { "income_type".localized }
    var expenseType: String { "expense_type".localized }
    
    // MARK: - Month Selection
    var previousMonth: String { "previous_month".localized }
    var nextMonth: String { "next_month".localized }
    
    // MARK: - Backup & Restore
    var backupRestore: String { "backup_restore".localized }
    var backupData: String { "backup_data".localized }
    var restoreData: String { "restore_data".localized }
    var backupList: String { "backup_list".localized }
    var backupSuccess: String { "backup_success".localized }
    var backupFailed: String { "backup_failed".localized }
    var restoreSuccess: String { "restore_success".localized }
    var restoreFailed: String { "restore_failed".localized }
    var restoreConfirm: String { "restore_confirm".localized }
    var restoreConfirmMessage: String { "restore_confirm_message".localized }
    var deleteBackup: String { "delete_backup".localized }
    var deleteBackupConfirm: String { "delete_backup_confirm".localized }
    var deleteBackupMessage: String { "delete_backup_message".localized }
    var noBackups: String { "no_backups".localized }
    var backupDate: String { "backup_date".localized }
    
    func backupMessage(_ path: String) -> String {
        "backup_message".localized(path)
    }
    
    func backupCount(_ count: Int) -> String {
        "backup_count".localized(count)
    }
    
    func restoreMessage(_ count: Int) -> String {
        "restore_message".localized(count)
    }
    
    func backupRecords(_ count: Int) -> String {
        "backup_records".localized(count)
    }
    
    // MARK: - Export
    var exportFormat: String { "export_format".localized }
    var exportHistory: String { "export_history".localized }
    var noExports: String { "no_exports".localized }
    var deleteFileMessage: String { "delete_file_message".localized }
    
    func exportTo(_ format: String) -> String {
        "export_to".localized(format)
    }
    
    // MARK: - Budget
    var budgetManagement: String { "budget_management".localized }
    var totalBudget: String { "total_budget".localized }
    var remaining: String { "remaining".localized }
    var spent: String { "spent".localized }
    var categoryBudgets: String { "category_budgets".localized }
    var noBudgets: String { "no_budgets".localized }
    var addBudget: String { "add_budget".localized }
    var budgetAmount: String { "budget_amount".localized }
    var month: String { "month".localized }
    var selectMonth: String { "select_month".localized }
    var allCategoriesHaveBudget: String { "all_categories_have_budget".localized }
    var overBudget: String { "over_budget".localized }
    var budgetWarning: String { "budget_warning".localized }
    var onTrack: String { "on_track".localized }
    
    func budgetOverrun(_ amount: Double) -> String {
        "budget_overrun".localized(amount)
    }
    
    // MARK: - Overall Budget
    var overallBudget: String { "overall_budget".localized }
    var setBudget: String { "set_budget".localized }
    var tapToSetBudget: String { "tap_to_set_budget".localized }
    var budgetHint: String { "budget_hint".localized }
    var active: String { "active".localized }
    var used: String { "used".localized }
    
    // MARK: - Account
    var accountManagement: String { "account_management".localized }
    var myAccounts: String { "my_accounts".localized }
    var noAccounts: String { "no_accounts".localized }
    var addAccount: String { "add_account".localized }
    var editAccount: String { "edit_account".localized }
    var deleteAccount: String { "delete_account".localized }
    var accountDetail: String { "account_detail".localized }
    var accountType: String { "account_type".localized }
    var accountName: String { "account_name".localized }
    var enterAccountName: String { "enter_account_name".localized }
    var initialBalance: String { "initial_balance".localized }
    var currentBalance: String { "current_balance".localized }
    var setDefault: String { "set_default".localized }
    var defaultAccount: String { "default_account".localized }
    var totalAssets: String { "total_assets".localized }
    var accountInfo: String { "account_info".localized }
    var transactionCount: String { "transaction_count".localized }
    var deleteAccountMessage: String { "delete_account_message".localized }
    var yes: String { "yes".localized }
    var no: String { "no".localized }
    
    // MARK: - Recurring
    var recurringTransactions: String { "recurring_transactions".localized }
    var recurringList: String { "recurring_list".localized }
    var noRecurring: String { "no_recurring".localized }
    var addRecurring: String { "add_recurring".localized }
    var frequency: String { "frequency".localized }
    var dayOfMonth: String { "day_of_month".localized }
    var dayOfWeek: String { "day_of_week".localized }
    var day: String { "day".localized }
    var dateRange: String { "date_range".localized }
    var startDate: String { "start_date".localized }
    var endDate: String { "end_date".localized }
    var hasEndDate: String { "has_end_date".localized }
    var autoGenerate: String { "auto_generate".localized }
    var generateNow: String { "generate_now".localized }
    var lastGenerated: String { "last_generated".localized }
    var paused: String { "paused".localized }
    var pause: String { "pause".localized }
    var resume: String { "resume".localized }
    var none: String { "none".localized }
    
    // MARK: - Weekdays
    var sunday: String { "sunday".localized }
    var monday: String { "monday".localized }
    var tuesday: String { "tuesday".localized }
    var wednesday: String { "wednesday".localized }
    var thursday: String { "thursday".localized }
    var friday: String { "friday".localized }
    var saturday: String { "saturday".localized }
    
    // MARK: - Annual Report
    var annualReport: String { "annual_report".localized }
    var yearSummary: String { "year_summary".localized }
    var balance: String { "balance".localized }
    var avgPerMonth: String { "avg_per_month".localized }
    var monthlyTrend: String { "monthly_trend".localized }
    var yearOverYear: String { "year_over_year".localized }
    var topExpenseMonths: String { "top_expense_months".localized }
    var topIncomeMonths: String { "top_income_months".localized }
    var monthAbbr: String { "month_abbr".localized }
    var type: String { "type".localized }
    
    // MARK: - Ledger
    var ledgerManagement: String { "ledger_management".localized }
    var myLedgers: String { "my_ledgers".localized }
    var noLedgers: String { "no_ledgers".localized }
    var addLedger: String { "add_ledger".localized }
    var editLedger: String { "edit_ledger".localized }
    var deleteLedger: String { "delete_ledger".localized }
    var ledgerType: String { "ledger_type".localized }
    var ledgerName: String { "ledger_name".localized }
    var enterLedgerName: String { "enter_ledger_name".localized }
    var defaultLedger: String { "default_ledger".localized }
    var selectLedger: String { "select_ledger".localized }
    var allLedgers: String { "all_ledgers".localized }
    
    // MARK: - Ledger Stats
    var ledgerStats: String { "ledger_stats".localized }
    var totalIncome: String { "total_income".localized }
    var totalExpense: String { "total_expense".localized }
    var savingsRate: String { "savings_rate".localized }
    var topTransactions: String { "top_transactions".localized }
    
    // MARK: - Import
    var importData: String { "import_data".localized }
    var importFromCSV: String { "import_from_csv".localized }
    var importFromJSON: String { "import_from_json".localized }
    var importCSVHint: String { "import_csv_hint".localized }
    var importJSONHint: String { "import_json_hint".localized }
    var importSuccess: String { "import_success".localized }
    var importFailed: String { "import_failed".localized }
    var importFormat: String { "import_format".localized }
    var csvFormat: String { "csv_format".localized }
    var jsonFormat: String { "json_format".localized }
    var importNote: String { "import_note".localized }
    
    func importSuccessMessage(_ count: Int) -> String {
        "import_success_message".localized(count)
    }
    
    // MARK: - Currency
    var currencyConverter: String { "currency_converter".localized }
    var baseCurrency: String { "base_currency".localized }
    var selectCurrency: String { "select_currency".localized }
    var exchangeRate: String { "exchange_rate".localized }
    var lastUpdated: String { "last_updated".localized }
    var updateRates: String { "update_rates".localized }
    var fromAmount: String { "from_amount".localized }
    var toAmount: String { "to_amount".localized }
    
    // MARK: - Custom Categories
    var categoryManagement: String { "category_management".localized }
    var customCategories: String { "custom_categories".localized }
    var noCustomCategories: String { "no_custom_categories".localized }
    var addCategory: String { "add_category".localized }
    var categoryName: String { "category_name".localized }
    var enterCategoryName: String { "enter_category_name".localized }
    var defaultCategories: String { "default_categories".localized }
    var defaultTag: String { "default_tag".localized }
    
    // MARK: - Share
    var shareData: String { "share_data".localized }
    var shareOptions: String { "share_options".localized }
    var shareAsText: String { "share_as_text".localized }
    var shareAsJSON: String { "share_as_json".localized }
    var shareAsCSV: String { "share_as_csv".localized }
    var shareTextHint: String { "share_text_hint".localized }
    var shareJSONHint: String { "share_json_hint".localized }
    var shareCSVHint: String { "share_csv_hint".localized }
    var sharePreview: String { "share_preview".localized }
    var sharedFrom: String { "shared_from".localized }
    var exportTitle: String { "export_title".localized }
    var exportDate: String { "export_date".localized }
    var transactions_: String { "transactions".localized }
    
    // MARK: - Trend
    var trendAnalysis: String { "trend_analysis".localized }
    var trendDirection: String { "trend_direction".localized }
    var prediction: String { "prediction".localized }
    var nextMonthPredicted: String { "next_month_predicted".localized }
    var basedOn: String { "based_on".localized }
    var weightedAverage: String { "weighted_average".localized }
    var changeRate: String { "change_rate".localized }
    var average3Months: String { "average_3_months".localized }
    var average6Months: String { "average_6_months".localized }
    var categoryTrends: String { "category_trends".localized }
    var noTrendData: String { "no_trend_data".localized }
    var trendDataHint: String { "trend_data_hint".localized }
    
    // MARK: - Savings Goals
    var savingsGoals: String { "savings_goals".localized }
    var myGoals: String { "my_goals".localized }
    var noGoals: String { "no_goals".localized }
    var addGoal: String { "add_goal".localized }
    var editGoal: String { "edit_goal".localized }
    var goalDetail: String { "goal_detail".localized }
    var goalName: String { "goal_name".localized }
    var enterGoalName: String { "enter_goal_name".localized }
    var icon: String { "icon".localized }
    var targetAmount: String { "target_amount".localized }
    var deadline: String { "deadline".localized }
    var setDeadline: String { "set_deadline".localized }
    var currentAmount: String { "current_amount".localized }
    var progress: String { "progress".localized }
    var completed: String { "completed".localized }
    var deposit: String { "deposit".localized }
    var withdraw: String { "withdraw".localized }
    var depositAmount: String { "deposit_amount".localized }
    var withdrawAmount: String { "withdraw_amount".localized }
    var availableBalance: String { "available_balance".localized }
    var totalSaved: String { "total_saved".localized }
    
    func daysRemaining(_ days: Int) -> String {
        "days_remaining".localized(days)
    }
    
    func goalCount(_ count: Int) -> String {
        "goal_count".localized(count)
    }
    
    // MARK: - App Lock
    var appLock: String { "app_lock".localized }
    var appLockSettings: String { "app_lock_settings".localized }
    var appLocked: String { "app_locked".localized }
    var authToContinue: String { "auth_to_continue".localized }
    var unlock: String { "unlock".localized }
    var authReason: String { "auth_reason".localized }
    var authFailed: String { "auth_failed".localized }
    var authFailedMessage: String { "auth_failed_message".localized }
    var retry: String { "retry".localized }
    var enableAppLock: String { "enable_app_lock".localized }
    var biometricType: String { "biometric_type".localized }
    var lockSettings: String { "lock_settings".localized }
    var requireOnLaunch: String { "require_on_launch".localized }
    var autoLock: String { "auto_lock".localized }
    var immediately: String { "immediately".localized }
    var after1Minute: String { "after_1_minute".localized }
    var after5Minutes: String { "after_5_minutes".localized }
    var after15Minutes: String { "after_15_minutes".localized }
    
    // MARK: - Bill Reminders
    var billReminders: String { "bill_reminders".localized }
    var billReminder: String { "bill_reminder".localized }
    var upcoming: String { "upcoming".localized }
    var overdue: String { "overdue".localized }
    var paid: String { "paid".localized }
    var noReminders: String { "no_reminders".localized }
    var addReminder: String { "add_reminder".localized }
    var reminderTitle: String { "reminder_title".localized }
    var enterReminderTitle: String { "enter_reminder_title".localized }
    var hasAmount: String { "has_amount".localized }
    var dueDate: String { "due_date".localized }
    var repeat_: String { "repeat".localized }
    var dueSoon: String { "due_soon".localized }
    var markUnpaid: String { "mark_unpaid".localized }
    var disable: String { "disable".localized }
    var enable: String { "enable".localized }
    var notificationPermission: String { "notification_permission".localized }
    var notificationPermissionMessage: String { "notification_permission_message".localized }
    var openSettings: String { "open_settings".localized }
    var upcomingBill: String { "upcoming_bill".localized }
    
    // MARK: - Notification Settings
    var notificationSettings: String { "notification_settings".localized }
    var notificationsEnabled: String { "notifications_enabled".localized }
    var notificationsDisabled: String { "notifications_disabled".localized }
    var notificationTypes: String { "notification_types".localized }
    var budgetAlertDesc: String { "budget_alert_desc".localized }
    var billReminderDesc: String { "bill_reminder_desc".localized }
    var savingsGoalReminder: String { "savings_goal_reminder".localized }
    var savingsGoalReminderDesc: String { "savings_goal_reminder_desc".localized }
    var pendingNotifications: String { "pending_notifications".localized }
    var noPendingNotifications: String { "no_pending_notifications".localized }
    var cancelAllNotifications: String { "cancel_all_notifications".localized }
    var budgetAlert: String { "budget_alert".localized }
    
    func reminderWithAmount(_ title: String, _ amount: Double) -> String {
        "reminder_with_amount".localized(title, amount)
    }
    
    func reminderWithoutAmount(_ title: String) -> String {
        "reminder_without_amount".localized(title)
    }
    
    func billDueSoon(_ title: String, _ days: Int) -> String {
        "bill_due_soon".localized(title, days)
    }
    
    // MARK: - Voice Input
    var voiceInput: String { "voice_input".localized }
    var stopRecording: String { "stop_recording".localized }
    var voiceResult: String { "voice_result".localized }
    var voiceResultMessage: String { "voice_result_message".localized }
    
    // MARK: - Report Share
    var reportShare: String { "report_share".localized }
    var generateReport: String { "generate_report".localized }
    var share: String { "share".localized }
    var saveToPhotos: String { "save_to_photos".localized }
    var reportGenerated: String { "report_generated".localized }
    var shareReport: String { "share_report".localized }
    
    // MARK: - Trend Enhanced
    var confidenceInterval: String { "confidence_interval".localized }
    var anomalyDetected: String { "anomaly_detected".localized }
    var seasonalPattern: String { "seasonal_pattern".localized }
    
    // MARK: - Debt Management
    var debtManagement: String { "debt_management".localized }
    var debtLend: String { "debt_lend".localized }
    var debtBorrow: String { "debt_borrow".localized }
    var debtLent: String { "debt_lent".localized }
    var debtBorrowed: String { "debt_borrowed".localized }
    var unsettledDebts: String { "unsettled_debts".localized }
    var settledDebts: String { "settled_debts".localized }
    var noDebts: String { "no_debts".localized }
    var noSettledDebts: String { "no_settled_debts".localized }
    var addDebt: String { "add_debt".localized }
    var debtType: String { "debt_type".localized }
    var debtPerson: String { "debt_person".localized }
    var enterPersonName: String { "enter_person_name".localized }
    var hasDueDate: String { "has_due_date".localized }
    var settleDebt: String { "settle_debt".localized }
    
    // MARK: - Tags
    var tagManagement: String { "tag_management".localized }
    var tags: String { "tags".localized }
    var noTags: String { "no_tags".localized }
    var addTag: String { "add_tag".localized }
    var editTag: String { "edit_tag".localized }
    var deleteTag: String { "delete_tag".localized }
    var tagName: String { "tag_name".localized }
    var enterTagName: String { "enter_tag_name".localized }
    var tagColor: String { "tag_color".localized }
    var selectTags: String { "select_tags".localized }
    var allTags: String { "all_tags".localized }
    
    // MARK: - Calendar
    var calendar: String { "calendar".localized }
    var today: String { "today".localized }
    var dailySummary: String { "daily_summary".localized }
    
    // MARK: - Budget Comparison
    var budgetComparison: String { "budget_comparison".localized }
    var actualVsPlanned: String { "actual_vs_planned".localized }
    
    // MARK: - Monthly Report
    var monthlyReport: String { "monthly_report".localized }
    var monthlyReportScheduled: String { "monthly_report_scheduled".localized }
    
    // MARK: - Receipt Scan
    var receiptScan: String { "receipt_scan".localized }
    var scanningReceipt: String { "scanning_receipt".localized }
    var receiptScanned: String { "receipt_scanned".localized }
    var estimatedAmount: String { "estimated_amount".localized }
    var useThisAmount: String { "use_this_amount".localized }
    var scanReceiptHint: String { "scan_receipt_hint".localized }
    var scanReceiptDescription: String { "scan_receipt_description".localized }
    var takePhoto: String { "take_photo".localized }
    var chooseFromLibrary: String { "choose_from_library".localized }
    
    // MARK: - Currency
    var before: String { "before".localized }
}

let L = Localization.shared

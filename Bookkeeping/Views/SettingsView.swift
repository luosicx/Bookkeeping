import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("currency") private var currency = "¥"
    @AppStorage("theme") private var theme = "system"
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(L.basicSettings)) {
                    HStack {
                        Text(L.currencyUnit)
                        Spacer()
                        Text(currency)
                            .foregroundColor(.gray)
                    }
                    
                    Picker(L.theme, selection: $theme) {
                        Text(L.themeSystem).tag("system")
                        Text(L.themeLight).tag("light")
                        Text(L.themeDark).tag("dark")
                    }
                }
                
                Section(header: Text(L.security)) {
                    NavigationLink {
                        AppLockSettingsView()
                    } label: {
                        Label(L.appLock, systemImage: "lock.shield")
                    }
                    
                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        Label(L.notificationSettings, systemImage: "bell.badge")
                    }
                }
                
                Section(header: Text(L.tools)) {
                    NavigationLink {
                        BillReminderView()
                    } label: {
                        Label(L.billReminders, systemImage: "bell.badge")
                    }
                    
                    NavigationLink {
                        SavingsGoalView()
                    } label: {
                        Label(L.savingsGoals, systemImage: "target")
                    }
                    
                    NavigationLink {
                        RecurringTransactionView()
                    } label: {
                        Label(L.recurringTransactions, systemImage: "clock.arrow.circlepath")
                    }
                    
                    NavigationLink {
                        DebtView()
                    } label: {
                        Label(L.debtManagement, systemImage: "person.2.badge.gearshape")
                    }
                    
                    NavigationLink {
                        TagView()
                    } label: {
                        Label(L.tagManagement, systemImage: "tag.fill")
                    }
                    
                    NavigationLink {
                        CalendarView()
                    } label: {
                        Label(L.calendar, systemImage: "calendar")
                    }
                    
                    NavigationLink {
                        BudgetComparisonView()
                    } label: {
                        Label(L.budgetComparison, systemImage: "chart.bar.fill")
                    }
                    
                    NavigationLink {
                        CurrencyConverterView()
                    } label: {
                        Label(L.currencyConverter, systemImage: "arrow.left.arrow.right")
                    }
                    
                    NavigationLink {
                        TrendAnalysisView()
                    } label: {
                        Label(L.trendAnalysis, systemImage: "chart.line.uptrend.xyaxis")
                    }
                    
                    NavigationLink {
                        ReportShareView()
                    } label: {
                        Label(L.reportShare, systemImage: "photo.on.rectangle")
                    }
                    
                    NavigationLink {
                        CustomCategoryView()
                    } label: {
                        Label(L.categoryManagement, systemImage: "tag")
                    }
                }
                
                Section(header: Text(L.dataManagement)) {
                    NavigationLink {
                        LedgerView()
                    } label: {
                        Label(L.ledgerManagement, systemImage: "book.closed")
                    }
                    
                    NavigationLink {
                        LedgerStatsView()
                    } label: {
                        Label(L.ledgerStats, systemImage: "chart.pie")
                    }
                    
                    NavigationLink {
                        AccountView()
                    } label: {
                        Label(L.accountManagement, systemImage: "wallet.bifold")
                    }
                    
                    NavigationLink {
                        ImportView()
                    } label: {
                        Label(L.importData, systemImage: "arrow.down.doc")
                    }
                    
                    NavigationLink {
                        ShareView()
                    } label: {
                        Label(L.shareData, systemImage: "square.and.arrow.up")
                    }
                    
                    NavigationLink {
                        BackupView()
                    } label: {
                        Label(L.backupRestore, systemImage: "arrow.triangle.2.circlepath")
                    }
                    
                    NavigationLink {
                        ExportView()
                    } label: {
                        Label(L.exportData, systemImage: "square.and.arrow.up")
                    }
                    
                    Button(action: { showingDeleteAlert = true }) {
                        HStack {
                            Label(L.clearAllData, systemImage: "trash")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
                
                Section(header: Text(L.about)) {
                    HStack {
                        Text(L.version)
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text(L.developer)
                        Spacer()
                        Text("Bookkeeping Team")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle(L.settingsTitle)
            .alert(L.confirmClear, isPresented: $showingDeleteAlert) {
                Button(L.cancel, role: .cancel) { }
                Button(L.delete, role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text(L.clearMessage)
            }
        }
    }
    
    private func deleteAllData() {
        do {
            try modelContext.delete(model: Transaction.self)
            try modelContext.delete(model: Account.self)
            try modelContext.delete(model: RecurringTransaction.self)
            try modelContext.delete(model: Ledger.self)
            try modelContext.delete(model: SavingsGoal.self)
            try modelContext.delete(model: BillReminder.self)
            try modelContext.delete(model: CustomCategory.self)
            try modelContext.delete(model: Debt.self)
            try modelContext.delete(model: Tag.self)
            try modelContext.save()
        } catch {
            print("Delete failed: \(error)")
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Transaction.self, Account.self, RecurringTransaction.self, Ledger.self, SavingsGoal.self, BillReminder.self, CustomCategory.self])
}

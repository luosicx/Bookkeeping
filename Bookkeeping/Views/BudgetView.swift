import SwiftUI
import SwiftData

struct BudgetView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var budgetViewModel = BudgetViewModel()
    @State private var transactionViewModel = TransactionViewModel()
    @State private var showingAddBudget = false
    @State private var showingSetOverallBudget = false
    @State private var selectedDate = Date()
    
    var overallBudgetStatus: OverallBudgetStatus? {
        budgetViewModel.getOverallBudgetStatus(transactions: transactionViewModel.transactions, date: selectedDate)
    }
    
    var budgetStatuses: [BudgetStatus] {
        budgetViewModel.getAllBudgetStatus(transactions: transactionViewModel.transactions, date: selectedDate)
    }
    
    var totalBudget: Double {
        budgetViewModel.totalBudget
    }
    
    var totalSpent: Double {
        budgetStatuses.reduce(0) { $0 + $1.spent }
    }
    
    var body: some View {
        List {
            Section {
                MonthSelector(selectedDate: $selectedDate)
                
                OverallBudgetCard(status: overallBudgetStatus, onTap: {
                    showingSetOverallBudget = true
                })
                
                BudgetSummaryCard(totalBudget: totalBudget, totalSpent: totalSpent)
            }
            
            Section(header: Text(L.categoryBudgets)) {
                if budgetStatuses.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "chart.pie")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            Text(L.noBudgets)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        Spacer()
                    }
                } else {
                    ForEach(budgetStatuses, id: \.budget.id) { status in
                        BudgetRow(status: status)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    budgetViewModel.deleteBudget(status.budget)
                                } label: {
                                    Label(L.delete, systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .navigationTitle(L.budgetManagement)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddBudget = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
            }
        }
        .sheet(isPresented: $showingAddBudget) {
            AddBudgetView(budgetViewModel: budgetViewModel)
        }
        .sheet(isPresented: $showingSetOverallBudget) {
            SetOverallBudgetView(budgetViewModel: budgetViewModel)
        }
        .onAppear {
            budgetViewModel.modelContext = modelContext
            transactionViewModel.modelContext = modelContext
            transactionViewModel.fetchTransactions()
            budgetViewModel.fetchBudgets(for: selectedDate)
            budgetViewModel.fetchOverallBudget(for: selectedDate)
        }
        .onChange(of: selectedDate) { _, _ in
            budgetViewModel.fetchBudgets(for: selectedDate)
            budgetViewModel.fetchOverallBudget(for: selectedDate)
        }
        .onChange(of: showingAddBudget) { _, isShowing in
            if !isShowing {
                budgetViewModel.fetchBudgets(for: selectedDate)
                transactionViewModel.fetchTransactions()
            }
        }
        .onChange(of: showingSetOverallBudget) { _, isShowing in
            if !isShowing {
                budgetViewModel.fetchOverallBudget(for: selectedDate)
                transactionViewModel.fetchTransactions()
            }
        }
    }
}

struct OverallBudgetCard: View {
    let status: OverallBudgetStatus?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "target")
                        .font(.title2)
                        .foregroundColor(.blue)
                    Text(L.overallBudget)
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                
                if let status = status {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(L.setBudget)
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("¥\(status.budget.amount, specifier: "%.0f")")
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                        
                        Spacer()
                        
                    VStack(alignment: .center) {
                        Text("\(Int(status.percentage * 100))%")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(statusColor(for: status))
                        Text(L.used)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text(L.remaining)
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("¥\(status.remaining, specifier: "%.0f")")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(status.remaining >= 0 ? .green : .red)
                        }
                    }
                    
                    ProgressView(value: min(status.percentage, 1.0))
                        .tint(statusColor(for: status))
                        .scaleEffect(y: 2.0)
                } else {
                    Text(L.tapToSetBudget)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct SetOverallBudgetView: View {
    @Environment(\.dismiss) private var dismiss
    let budgetViewModel: BudgetViewModel
    
    @State private var amount: String = ""
    
    init(budgetViewModel: BudgetViewModel) {
        self.budgetViewModel = budgetViewModel
        if let status = budgetViewModel.overallBudgets.first {
            _amount = State(initialValue: String(format: "%.0f", status.amount))
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(L.overallBudget)) {
                    HStack {
                        Text("¥")
                            .font(.title2)
                        TextField("0", text: $amount)
                            .keyboardType(.numberPad)
                            .font(.title2)
                    }
                }
                
                Section {
                    Text(L.budgetHint)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle(L.setBudget)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L.cancel) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L.save) {
                        saveBudget()
                    }
                    .disabled(Double(amount) == nil || (Double(amount) ?? 0) <= 0)
                }
            }
        }
    }
    
    private func saveBudget() {
        guard let amountValue = Double(amount), amountValue > 0 else { return }
        budgetViewModel.setOverallBudget(amount: amountValue)
        dismiss()
    }
}

struct BudgetSummaryCard: View {
    let totalBudget: Double
    let totalSpent: Double
    
    var remaining: Double {
        totalBudget - totalSpent
    }
    
    var percentage: Double {
        guard totalBudget > 0 else { return 0 }
        return totalSpent / totalBudget
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(L.categoryBudgets)
                    .font(.headline)
                Spacer()
                Text("\(budgetStatuses.count) \(L.active)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text(L.totalBudget)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("¥\(totalBudget, specifier: "%.0f")")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(L.remaining)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("¥\(remaining, specifier: "%.0f")")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(remaining >= 0 ? .green : .red)
                }
            }
            
            ProgressView(value: min(percentage, 1.0))
                .tint(budgetStatusColor(percentage: percentage))
                .scaleEffect(y: 2.0)
            
            HStack {
                Text(L.spent)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("¥\(totalSpent, specifier: "%.0f")")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text("\(Int(percentage * 100))%")
                    .font(.caption)
                    .foregroundColor(budgetStatusColor(percentage: percentage))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var budgetStatuses: [BudgetStatus] {
        []
    }
}

struct BudgetRow: View {
    let status: BudgetStatus
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(status.budget.category)
                    .font(.headline)
                
                Spacer()
                
                Text("¥\(status.spent, specifier: "%.0f") / ¥\(status.budget.amount, specifier: "%.0f")")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            ProgressView(value: min(status.percentage, 1.0))
                .tint(statusColor(for: status))
                .scaleEffect(y: 1.5)
            
            HStack {
                if status.isOverBudget {
                    Label(L.overBudget, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                } else if status.isWarning {
                    Label(L.budgetWarning, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundColor(.orange)
                } else {
                    Text(L.onTrack)
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                Text("¥\(status.remaining, specifier: "%.0f") \(L.remaining)")
                    .font(.caption)
                    .foregroundColor(status.remaining >= 0 ? .green : .red)
            }
        }
        .padding(.vertical, 4)
    }
}

private func statusColor(for status: BudgetStatus) -> Color {
    if status.isOverBudget { return .red }
    if status.isWarning { return .orange }
    return .blue
}

private func statusColor(for status: OverallBudgetStatus) -> Color {
    if status.isOverBudget { return .red }
    if status.isWarning { return .orange }
    return .blue
}

private func budgetStatusColor(percentage: Double) -> Color {
    if percentage >= 1.0 { return .red }
    if percentage >= 0.8 { return .orange }
    return .blue
}

#Preview {
    NavigationStack {
        BudgetView()
    }
    .modelContainer(for: [Budget.self, OverallBudget.self, Transaction.self])
}

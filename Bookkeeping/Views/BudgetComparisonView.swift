import SwiftUI
import SwiftData

struct BudgetComparisonView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var categoryBudgets: [Budget] = []
    @State private var transactions: [Transaction] = []
    @State private var selectedMonth = Date()
    
    private let calendar = Calendar.current
    
    var body: some View {
        NavigationStack {
            List {
                Section(L.overallBudget) {
                    let totalBudget = categoryBudgets.reduce(0) { $0 + $1.amount }
                    let totalSpent = monthTransactions.reduce(0) { $0 + $1.amount }
                    let remaining = totalBudget - totalSpent
                    let percentage = totalBudget > 0 ? totalSpent / totalBudget : 0
                    
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(L.budgetAmount)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("¥\(totalBudget, specifier: "%.0f")")
                                    .font(.title3)
                                    .fontWeight(.bold)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(L.spent)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("¥\(totalSpent, specifier: "%.0f")")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(percentage > 1 ? .red : .primary)
                            }
                        }
                        
                        GeometryReader { geometry in
                            let progressColor: Color = {
                                if percentage > 1 { return .red }
                                if percentage > 0.8 { return .orange }
                                return .green
                            }()
                            
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(.systemGray5))
                                    .frame(height: 8)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(progressColor)
                                    .frame(width: geometry.size.width * min(percentage, 1), height: 8)
                            }
                        }
                        .frame(height: 8)
                        
                        HStack {
                            Text("\(Int(percentage * 100))%")
                            Spacer()
                            Text("\(L.remaining): ¥\(remaining, specifier: "%.0f")")
                                .foregroundColor(remaining < 0 ? .red : .green)
                        }
                        .font(.caption)
                    }
                    .padding(.vertical, 8)
                }
                
                Section(L.categoryBudgets) {
                    if categoryBudgets.isEmpty {
                        Text(L.noBudgets)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(categoryBudgets) { budget in
                            CategoryBudgetRow(
                                budget: budget,
                                spent: spentForCategory(budget.category)
                            )
                        }
                    }
                }
            }
            .navigationTitle(L.budgetComparison)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { changeMonth(by: -1) }) {
                            Label(L.previousMonth, systemImage: "chevron.left")
                        }
                        Button(action: { changeMonth(by: 1) }) {
                            Label(L.nextMonth, systemImage: "chevron.right")
                        }
                    } label: {
                        Image(systemName: "calendar")
                    }
                }
            }
            .onAppear {
                loadData()
            }
        }
    }
    
    private var monthTransactions: [Transaction] {
        transactions.filter { calendar.isDate($0.date, equalTo: selectedMonth, toGranularity: .month) }
    }
    
    private func spentForCategory(_ category: String) -> Double {
        monthTransactions
            .filter { $0.category == category }
            .reduce(0) { $0 + $1.amount }
    }
    
    private func loadData() {
        let budgetDescriptor = FetchDescriptor<Budget>()
        categoryBudgets = (try? modelContext.fetch(budgetDescriptor)) ?? []
        
        let transactionDescriptor = FetchDescriptor<Transaction>()
        transactions = (try? modelContext.fetch(transactionDescriptor)) ?? []
    }
    
    private func changeMonth(by value: Int) {
        selectedMonth = calendar.date(byAdding: .month, value: value, to: selectedMonth) ?? selectedMonth
    }
}

struct CategoryBudgetRow: View {
    let budget: Budget
    let spent: Double
    
    private var percentage: Double {
        guard budget.amount > 0 else { return 0 }
        return spent / budget.amount
    }
    
    private var status: BudgetStatusType {
        if percentage > 1 { return .overBudget }
        if percentage > 0.8 { return .warning }
        return .onTrack
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(budget.category)
                    .font(.headline)
                Spacer()
                Text("¥\(spent, specifier: "%.0f") / ¥\(budget.amount, specifier: "%.0f")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(status.color)
                        .frame(width: geometry.size.width * min(percentage, 1), height: 6)
                }
            }
            .frame(height: 6)
            
            HStack {
                Text("\(Int(percentage * 100))%")
                    .font(.caption)
                Spacer()
                Text(status.label)
                    .font(.caption)
                    .foregroundColor(status.color)
            }
        }
        .padding(.vertical, 4)
    }
}

enum BudgetStatusType {
    case onTrack
    case warning
    case overBudget
    
    var color: Color {
        switch self {
        case .onTrack: return .green
        case .warning: return .orange
        case .overBudget: return .red
        }
    }
    
    var label: String {
        switch self {
        case .onTrack: return L.onTrack
        case .warning: return L.budgetWarning
        case .overBudget: return L.overBudget
        }
    }
}

#Preview {
    BudgetComparisonView()
        .modelContainer(for: [Budget.self, Transaction.self])
}

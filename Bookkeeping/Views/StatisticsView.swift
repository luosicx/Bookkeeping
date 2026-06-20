import SwiftUI
import Charts

struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = TransactionViewModel()
    @State private var selectedPeriod: TimePeriod = .month
    @State private var selectedDate = Date()
    
    enum TimePeriod: String, CaseIterable {
        case week
        case month
        case year
        
        var localizedName: String {
            switch self {
            case .week: return L.periodWeek
            case .month: return L.periodMonth
            case .year: return L.periodYear
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    PeriodPicker(selectedPeriod: $selectedPeriod)
                    
                    MonthSelector(selectedDate: $selectedDate)
                    
                    SummarySection(viewModel: viewModel, selectedDate: selectedDate)
                    
                    NavigationLink {
                        BudgetView()
                    } label: {
                        HStack {
                            Image(systemName: "chart.pie")
                                .foregroundColor(.blue)
                            Text(L.budgetManagement)
                                .font(.headline)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                    .buttonStyle(.plain)
                    
                    NavigationLink {
                        AnnualReportView()
                    } label: {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.orange)
                            Text(L.annualReport)
                                .font(.headline)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                    .buttonStyle(.plain)
                    
                    CategoryChart(viewModel: viewModel, selectedDate: selectedDate)
                    
                    TrendChart(viewModel: viewModel, selectedDate: selectedDate)
                    
                    TopCategoriesView(viewModel: viewModel, selectedDate: selectedDate)
                }
                .padding()
            }
            .navigationTitle(L.statisticsTitle)
            .onAppear {
                viewModel.modelContext = modelContext
                viewModel.fetchTransactions()
            }
        }
    }
}

struct PeriodPicker: View {
    @Binding var selectedPeriod: StatisticsView.TimePeriod
    
    var body: some View {
        Picker(L.transactionType, selection: $selectedPeriod) {
            ForEach(StatisticsView.TimePeriod.allCases, id: \.self) { period in
                Text(period.localizedName).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }
}

struct SummarySection: View {
    let viewModel: TransactionViewModel
    let selectedDate: Date
    
    var body: some View {
        HStack(spacing: 15) {
            StatCard(title: L.income, amount: viewModel.totalIncomeForMonth(selectedDate), color: .green)
            StatCard(title: L.expense, amount: viewModel.totalExpenseForMonth(selectedDate), color: .red)
            StatCard(title: L.monthlyBalance, amount: viewModel.balanceForMonth(selectedDate), color: .blue)
        }
    }
}

struct StatCard: View {
    let title: String
    let amount: Double
    let color: Color
    
    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text("¥\(amount, specifier: "%.0f")")
                .font(.headline)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct CategoryChart: View {
    let viewModel: TransactionViewModel
    let selectedDate: Date
    
    var categoryData: [(String, Double)] {
        var data: [String: Double] = [:]
        let transactions = viewModel.transactionsForMonth(selectedDate)
        for transaction in transactions where transaction.type == .expense {
            data[transaction.category, default: 0] += transaction.amount
        }
        return data.sorted { $0.value > $1.value }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(L.expenseCategory)
                .font(.headline)
            
            if categoryData.isEmpty {
                Text(L.noData)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                Chart(categoryData, id: \.0) { category, amount in
                    SectorMark(
                        angle: .value(L.amount, amount),
                        innerRadius: 0.6
                    )
                    .foregroundStyle(by: .value(L.category, category))
                }
                .frame(height: 200)
                .chartLegend(position: .bottom)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct TrendChart: View {
    let viewModel: TransactionViewModel
    let selectedDate: Date
    
    var dailyData: [(Date, Double, TransactionType)] {
        let calendar = Calendar.current
        let transactions = viewModel.transactionsForMonth(selectedDate)
        
        var dailyTotals: [Date: (income: Double, expense: Double)] = [:]
        
        for transaction in transactions {
            let day = calendar.startOfDay(for: transaction.date)
            if dailyTotals[day] == nil {
                dailyTotals[day] = (0, 0)
            }
            if transaction.type == .income {
                dailyTotals[day]!.income += transaction.amount
            } else {
                dailyTotals[day]!.expense += transaction.amount
            }
        }
        
        var result: [(Date, Double, TransactionType)] = []
        for (date, totals) in dailyTotals.sorted(by: { $0.key < $1.key }) {
            result.append((date, totals.income, .income))
            result.append((date, totals.expense, .expense))
        }
        
        return result
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(L.incomeExpenseTrend)
                .font(.headline)
            
            if dailyData.isEmpty {
                Text(L.noData)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                Chart(dailyData, id: \.0) { date, amount, type in
                    LineMark(
                        x: .value(L.date, date),
                        y: .value(L.amount, amount)
                    )
                    .foregroundStyle(by: .value(L.transactionType, type.localizedName))
                    .symbol(by: .value(L.transactionType, type.localizedName))
                }
                .frame(height: 200)
                .chartLegend(position: .bottom)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.day())
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct TopCategoriesView: View {
    let viewModel: TransactionViewModel
    let selectedDate: Date
    
    var topCategories: [(String, Double, Int)] {
        let transactions = viewModel.transactionsForMonth(selectedDate).filter { $0.type == .expense }
        var categoryStats: [String: (total: Double, count: Int)] = [:]
        
        for transaction in transactions {
            if categoryStats[transaction.category] == nil {
                categoryStats[transaction.category] = (0, 0)
            }
            categoryStats[transaction.category]!.total += transaction.amount
            categoryStats[transaction.category]!.count += 1
        }
        
        return categoryStats
            .map { ($0.key, $0.value.total, $0.value.count) }
            .sorted { $0.1 > $1.1 }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(L.topExpenses)
                .font(.headline)
            
            if topCategories.isEmpty {
                Text(L.noData)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(Array(topCategories.enumerated()), id: \.offset) { index, category in
                    HStack {
                        Text("\(index + 1)")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .frame(width: 30)
                        
                        Text(category.0)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("¥\(category.1, specifier: "%.2f")")
                                .fontWeight(.semibold)
                            Text(L.transactionCountFormat(category.2))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    if index < topCategories.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    StatisticsView()
        .modelContainer(for: Transaction.self)
}

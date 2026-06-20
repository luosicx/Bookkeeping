import SwiftUI
import Charts

struct AnnualReportView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = TransactionViewModel()
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                YearSelector(selectedYear: $selectedYear)
                
                AnnualSummaryCard(viewModel: viewModel, year: selectedYear)
                
                MonthlyTrendChart(viewModel: viewModel, year: selectedYear)
                
                CategoryBreakdown(viewModel: viewModel, year: selectedYear)
                
                YearOverYearComparison(viewModel: viewModel, year: selectedYear)
                
                TopExpenseMonths(viewModel: viewModel, year: selectedYear)
                
                TopIncomeMonths(viewModel: viewModel, year: selectedYear)
            }
            .padding()
        }
        .navigationTitle(L.annualReport)
        .onAppear {
            viewModel.modelContext = modelContext
            viewModel.fetchTransactions()
        }
    }
}

struct YearSelector: View {
    @Binding var selectedYear: Int
    
    var body: some View {
        HStack {
            Button(action: { selectedYear -= 1 }) {
                Image(systemName: "chevron.left")
                    .font(.title3)
            }
            
            Spacer()
            
            Text("\(selectedYear)")
                .font(.title)
                .fontWeight(.bold)
            
            Spacer()
            
            Button(action: { selectedYear += 1 }) {
                Image(systemName: "chevron.right")
                    .font(.title3)
            }
        }
        .padding(.horizontal)
    }
}

struct AnnualSummaryCard: View {
    let viewModel: TransactionViewModel
    let year: Int
    
    var yearTransactions: [Transaction] {
        viewModel.transactions.filter {
            Calendar.current.component(.year, from: $0.date) == year
        }
    }
    
    var totalIncome: Double {
        yearTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }
    
    var totalExpense: Double {
        yearTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }
    
    var balance: Double {
        totalIncome - totalExpense
    }
    
    var transactionCount: Int {
        yearTransactions.count
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text(L.yearSummary)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 20) {
                VStack {
                    Text(L.income)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("¥\(totalIncome, specifier: "%.0f")")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity)
                
                VStack {
                    Text(L.expense)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("¥\(totalExpense, specifier: "%.0f")")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
                .frame(maxWidth: .infinity)
                
                VStack {
                    Text(L.balance)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("¥\(balance, specifier: "%.0f")")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(balance >= 0 ? .green : .red)
                }
                .frame(maxWidth: .infinity)
            }
            
            Divider()
            
            HStack {
                Text(L.transactionCount)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("\(transactionCount)")
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(L.avgPerMonth)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("¥\(totalExpense / 12, specifier: "%.0f")")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct MonthlyTrendChart: View {
    let viewModel: TransactionViewModel
    let year: Int
    
    var monthlyData: [(String, Double, String)] {
        let calendar = Calendar.current
        var data: [(String, Double, String)] = []
        
        for month in 1...12 {
            let monthTransactions = viewModel.transactions.filter {
                calendar.component(.year, from: $0.date) == year &&
                calendar.component(.month, from: $0.date) == month
            }
            
            let income = monthTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
            let expense = monthTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
            
            data.append(("\(month)\(L.monthAbbr)", income, "income"))
            data.append(("\(month)\(L.monthAbbr)", expense, "expense"))
        }
        
        return data
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(L.monthlyTrend)
                .font(.headline)
            
            Chart(monthlyData, id: \.0) { month, amount, type in
                BarMark(
                    x: .value(L.month, month),
                    y: .value(L.amount, amount)
                )
                .foregroundStyle(by: .value(L.type, type == "income" ? L.income : L.expense))
                .position(by: .value(L.type, type == "income" ? L.income : L.expense))
            }
            .frame(height: 200)
            .chartLegend(position: .bottom)
            .chartForegroundStyleScale([
                L.income: .green,
                L.expense: .red
            ])
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct CategoryBreakdown: View {
    let viewModel: TransactionViewModel
    let year: Int
    
    var categoryData: [(String, Double)] {
        let calendar = Calendar.current
        let yearTransactions = viewModel.transactions.filter {
            calendar.component(.year, from: $0.date) == year && $0.type == .expense
        }
        
        var data: [String: Double] = [:]
        for transaction in yearTransactions {
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
                
                VStack(spacing: 8) {
                    ForEach(categoryData.prefix(5), id: \.0) { category, amount in
                        HStack {
                            Text(category)
                                .font(.subheadline)
                            Spacer()
                            Text("¥\(amount, specifier: "%.0f")")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct YearOverYearComparison: View {
    let viewModel: TransactionViewModel
    let year: Int
    
    var currentYearExpense: Double {
        let calendar = Calendar.current
        return viewModel.transactions.filter {
            calendar.component(.year, from: $0.date) == year && $0.type == .expense
        }.reduce(0) { $0 + $1.amount }
    }
    
    var previousYearExpense: Double {
        let calendar = Calendar.current
        return viewModel.transactions.filter {
            calendar.component(.year, from: $0.date) == year - 1 && $0.type == .expense
        }.reduce(0) { $0 + $1.amount }
    }
    
    var changePercentage: Double {
        guard previousYearExpense > 0 else { return 0 }
        return (currentYearExpense - previousYearExpense) / previousYearExpense * 100
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L.yearOverYear)
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("\(year - 1)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("¥\(previousYearExpense, specifier: "%.0f")")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .foregroundColor(.gray)
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(year)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("¥\(currentYearExpense, specifier: "%.0f")")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }
            
            HStack {
                Spacer()
                
                HStack {
                    Image(systemName: changePercentage >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .foregroundColor(changePercentage >= 0 ? .red : .green)
                    Text("\(abs(changePercentage), specifier: "%.1f")%")
                        .fontWeight(.semibold)
                        .foregroundColor(changePercentage >= 0 ? .red : .green)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct TopExpenseMonths: View {
    let viewModel: TransactionViewModel
    let year: Int
    
    var monthlyExpenses: [(Int, Double)] {
        let calendar = Calendar.current
        var data: [Int: Double] = [:]
        
        for month in 1...12 {
            let expense = viewModel.transactions.filter {
                calendar.component(.year, from: $0.date) == year &&
                calendar.component(.month, from: $0.date) == month &&
                $0.type == .expense
            }.reduce(0) { $0 + $1.amount }
            
            if expense > 0 {
                data[month] = expense
            }
        }
        
        return data.sorted { $0.value > $1.value }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(L.topExpenseMonths)
                .font(.headline)
            
            if monthlyExpenses.isEmpty {
                Text(L.noData)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(Array(monthlyExpenses.prefix(3).enumerated()), id: \.element.0) { index, item in
                    HStack {
                        Text("\(index + 1)")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .frame(width: 30)
                        
                        Text("\(item.0)\(L.month)")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("¥\(item.1, specifier: "%.0f")")
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }
                    .padding(.vertical, 4)
                    
                    if index < 2 {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct TopIncomeMonths: View {
    let viewModel: TransactionViewModel
    let year: Int
    
    var monthlyIncomes: [(Int, Double)] {
        let calendar = Calendar.current
        var data: [Int: Double] = [:]
        
        for month in 1...12 {
            let income = viewModel.transactions.filter {
                calendar.component(.year, from: $0.date) == year &&
                calendar.component(.month, from: $0.date) == month &&
                $0.type == .income
            }.reduce(0) { $0 + $1.amount }
            
            if income > 0 {
                data[month] = income
            }
        }
        
        return data.sorted { $0.value > $1.value }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(L.topIncomeMonths)
                .font(.headline)
            
            if monthlyIncomes.isEmpty {
                Text(L.noData)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(Array(monthlyIncomes.prefix(3).enumerated()), id: \.element.0) { index, item in
                    HStack {
                        Text("\(index + 1)")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .frame(width: 30)
                        
                        Text("\(item.0)\(L.month)")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("¥\(item.1, specifier: "%.0f")")
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                    .padding(.vertical, 4)
                    
                    if index < 2 {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    NavigationStack {
        AnnualReportView()
    }
    .modelContainer(for: Transaction.self)
}

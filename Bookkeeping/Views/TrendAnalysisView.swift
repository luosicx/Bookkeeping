import SwiftUI
import SwiftData
import Charts

struct TrendAnalysisView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = TransactionViewModel()
    @State private var selectedType: TransactionType = .expense
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                TypePicker(selectedType: $selectedType)
                
                if let trend = TrendPredictor.shared.analyzeTrend(transactions: viewModel.transactions, type: selectedType) {
                    TrendSummaryCard(trend: trend, type: selectedType)
                    
                    PredictionCard(trend: trend, type: selectedType)
                    
                    TrendLineChart(transactions: viewModel.transactions, type: selectedType)
                } else {
                    EmptyTrendView()
                }
                
                CategoryTrendSection(transactions: viewModel.transactions)
            }
            .padding()
        }
        .navigationTitle(L.trendAnalysis)
        .onAppear {
            viewModel.modelContext = modelContext
            viewModel.fetchTransactions()
        }
    }
}

struct TypePicker: View {
    @Binding var selectedType: TransactionType
    
    var body: some View {
        Picker(L.type, selection: $selectedType) {
            ForEach(TransactionType.allCases, id: \.self) { type in
                Text(type.localizedName).tag(type)
            }
        }
        .pickerStyle(.segmented)
    }
}

struct TrendSummaryCard: View {
    let trend: TrendPredictor.TrendData
    let type: TransactionType
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: trend.trend.icon)
                    .font(.title2)
                    .foregroundColor(Color(trend.trend.color))
                Text(L.trendDirection)
                    .font(.headline)
                Spacer()
                Text(trend.trend.description)
                    .font(.headline)
                    .foregroundColor(Color(trend.trend.color))
            }
            
            Divider()
            
            HStack(spacing: 20) {
                StatItem(title: "本月", value: String(format: "¥%.0f", trend.currentMonth))
                StatItem(title: "上月", value: String(format: "¥%.0f", trend.lastMonth))
                StatItem(title: L.changeRate, value: String(format: "%.1f%%", trend.changeRate))
            }
            
            HStack(spacing: 20) {
                StatItem(title: L.average3Months, value: String(format: "¥%.0f", trend.average3Months))
                StatItem(title: L.average6Months, value: String(format: "¥%.0f", trend.average6Months))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct PredictionCard: View {
    let trend: TrendPredictor.TrendData
    let type: TransactionType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain")
                    .foregroundColor(.purple)
                Text(L.prediction)
                    .font(.headline)
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text(L.nextMonthPredicted)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text(String(format: "¥%.0f", trend.prediction))
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(L.basedOn)
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(L.weightedAverage)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct TrendLineChart: View {
    let transactions: [Transaction]
    let type: TransactionType
    
    private var monthlyData: [(String, Double)] {
        let calendar = Calendar.current
        var data: [Date: Double] = [:]
        
        for transaction in transactions where transaction.type == type {
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: transaction.date))!
            data[monthStart, default: 0] += transaction.amount
        }
        
        return data.sorted { $0.key < $1.key }.map { (date, amount) in
            let formatter = DateFormatter()
            formatter.dateFormat = "M月"
            return (formatter.string(from: date), amount)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(L.monthlyTrend)
                .font(.headline)
            
            if monthlyData.isEmpty {
                Text(L.noData)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                Chart(monthlyData, id: \.0) { month, amount in
                    BarMark(
                        x: .value(L.month, month),
                        y: .value(L.amount, amount)
                    )
                    .foregroundStyle(type == .income ? .green : .red)
                    
                    if monthlyData.count > 1 {
                        LineMark(
                            x: .value(L.month, month),
                            y: .value(L.amount, amount)
                        )
                        .foregroundStyle(.blue)
                    }
                }
                .frame(height: 200)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct CategoryTrendSection: View {
    let transactions: [Transaction]
    
    private var categoryTrends: [(String, TrendPredictor.TrendData)] {
        TrendPredictor.shared.analyzeAllCategories(transactions: transactions)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(L.categoryTrends)
                .font(.headline)
            
            if categoryTrends.isEmpty {
                Text(L.noData)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(categoryTrends.prefix(5), id: \.0) { category, trend in
                    HStack {
                        Text(category)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        HStack {
                            Image(systemName: trend.trend.icon)
                                .foregroundColor(Color(trend.trend.color))
                            Text(String(format: "%.1f%%", trend.changeRate))
                                .font(.caption)
                                .foregroundColor(Color(trend.trend.color))
                        }
                    }
                    .padding(.vertical, 4)
                    
                    if category != categoryTrends.prefix(5).last?.0 {
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

struct EmptyTrendView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.largeTitle)
                .foregroundColor(.gray)
            Text(L.noTrendData)
                .foregroundColor(.gray)
            Text(L.trendDataHint)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
}

#Preview {
    NavigationStack {
        TrendAnalysisView()
    }
    .modelContainer(for: Transaction.self)
}

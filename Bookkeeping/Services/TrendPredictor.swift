import Foundation

class TrendPredictor {
    static let shared = TrendPredictor()
    
    private init() {}
    
    struct TrendData {
        let currentMonth: Double
        let lastMonth: Double
        let average3Months: Double
        let average6Months: Double
        let changeRate: Double
        let prediction: Double
        let trend: TrendDirection
        let confidenceInterval: (lower: Double, upper: Double)
        let anomalies: [Transaction]
        let seasonalPattern: SeasonalPattern?
    }
    
    struct SeasonalPattern {
        let peakMonth: Int
        let lowMonth: Int
        let variance: Double
    }
    
    enum TrendDirection {
        case increasing
        case stable
        case decreasing
        
        var description: String {
            switch self {
            case .increasing: return "上升"
            case .stable: return "稳定"
            case .decreasing: return "下降"
            }
        }
        
        var icon: String {
            switch self {
            case .increasing: return "arrow.up.right"
            case .stable: return "arrow.right"
            case .decreasing: return "arrow.down.right"
            }
        }
        
        var color: String {
            switch self {
            case .increasing: return "red"
            case .stable: return "gray"
            case .decreasing: return "green"
            }
        }
    }
    
    func analyzeTrend(transactions: [Transaction], type: TransactionType) -> TrendData? {
        let calendar = Calendar.current
        
        var monthlyTotals: [Date: Double] = [:]
        
        for transaction in transactions where transaction.type == type {
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: transaction.date))!
            monthlyTotals[monthStart, default: 0] += transaction.amount
        }
        
        let sortedMonths = monthlyTotals.sorted { $0.key > $1.key }
        
        guard sortedMonths.count >= 2 else { return nil }
        
        let currentMonth = sortedMonths[0].value
        let lastMonth = sortedMonths[1].value
        
        let threeMonths = Array(sortedMonths.prefix(3)).map { $0.value }
        let average3Months = threeMonths.reduce(0, +) / Double(threeMonths.count)
        
        let sixMonths = Array(sortedMonths.prefix(6)).map { $0.value }
        let average6Months = sixMonths.reduce(0, +) / Double(sixMonths.count)
        
        let changeRate = lastMonth > 0 ? (currentMonth - lastMonth) / lastMonth * 100 : 0
        
        let prediction = predictNextMonth(recentMonths: threeMonths)
        let confidence = calculateConfidenceInterval(recentMonths: threeMonths)
        
        let allTransactions = transactions.filter { $0.type == type }
        let anomalies = detectAnomalies(transactions: allTransactions)
        
        let seasonalPattern = detectSeasonalPatterns(transactions: allTransactions)
        
        let trend: TrendDirection
        if changeRate > 10 {
            trend = .increasing
        } else if changeRate < -10 {
            trend = .decreasing
        } else {
            trend = .stable
        }
        
        return TrendData(
            currentMonth: currentMonth,
            lastMonth: lastMonth,
            average3Months: average3Months,
            average6Months: average6Months,
            changeRate: changeRate,
            prediction: prediction,
            trend: trend,
            confidenceInterval: confidence,
            anomalies: anomalies,
            seasonalPattern: seasonalPattern
        )
    }
    
    private func predictNextMonth(recentMonths: [Double]) -> Double {
        guard recentMonths.count >= 2 else {
            return recentMonths.first ?? 0
        }
        
        var weightedSum = 0.0
        var weightSum = 0.0
        
        for (index, value) in recentMonths.enumerated() {
            let weight = Double(recentMonths.count - index)
            weightedSum += value * weight
            weightSum += weight
        }
        
        return weightedSum / weightSum
    }
    
    private func calculateConfidenceInterval(recentMonths: [Double]) -> (lower: Double, upper: Double) {
        guard recentMonths.count >= 2 else {
            let value = recentMonths.first ?? 0
            return (value, value)
        }
        
        let mean = recentMonths.reduce(0, +) / Double(recentMonths.count)
        let variance = recentMonths.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(recentMonths.count)
        let stdDev = sqrt(variance)
        
        let prediction = predictNextMonth(recentMonths: recentMonths)
        
        return (prediction - 1.96 * stdDev, prediction + 1.96 * stdDev)
    }
    
    func detectAnomalies(transactions: [Transaction]) -> [Transaction] {
        guard transactions.count >= 3 else { return [] }
        
        let amounts = transactions.map(\.amount)
        let mean = amounts.reduce(0, +) / Double(amounts.count)
        let variance = amounts.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(amounts.count)
        let stdDev = sqrt(variance)
        
        guard stdDev > 0 else { return [] }
        
        return transactions.filter { abs($0.amount - mean) > 2 * stdDev }
    }
    
    private func detectSeasonalPatterns(transactions: [Transaction]) -> SeasonalPattern? {
        guard transactions.count >= 12 else { return nil }
        
        let calendar = Calendar.current
        var monthlyAverages: [Int: Double] = [:]
        var monthlyCounts: [Int: Int] = [:]
        
        for transaction in transactions {
            let month = calendar.component(.month, from: transaction.date)
            monthlyAverages[month, default: 0] += transaction.amount
            monthlyCounts[month, default: 0] += 1
        }
        
        for (month, total) in monthlyAverages {
            monthlyAverages[month] = total / Double(monthlyCounts[month] ?? 1)
        }
        
        guard let peakMonth = monthlyAverages.max(by: { $0.value < $1.value })?.key,
              let lowMonth = monthlyAverages.min(by: { $0.value < $1.value })?.key else {
            return nil
        }
        
        let values = Array(monthlyAverages.values)
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(values.count)
        
        return SeasonalPattern(peakMonth: peakMonth, lowMonth: lowMonth, variance: variance)
    }
    
    func analyzeAllCategories(transactions: [Transaction]) -> [(String, TrendData)] {
        let expenseTransactions = transactions.filter { $0.type == .expense }
        
        let grouped = Dictionary(grouping: expenseTransactions) { $0.category }
        
        var results: [(String, TrendData)] = []
        
        for (category, categoryTransactions) in grouped {
            if let trend = analyzeTrend(transactions: categoryTransactions, type: .expense) {
                results.append((category, trend))
            }
        }
        
        return results.sorted { $0.1.changeRate > $1.1.changeRate }
    }
}

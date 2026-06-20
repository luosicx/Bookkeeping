import Foundation

@Observable
class CurrencyService {
    static let shared = CurrencyService()
    
    var baseCurrency: String = "CNY"
    var exchangeRates: [String: Double] = [:]
    var lastUpdate: Date?
    var isLoading = false
    
    private let defaults = UserDefaults.standard
    private let ratesKey = "exchange_rates"
    private let lastUpdateKey = "rates_last_update"
    
    struct Currency: Identifiable, Hashable {
        let id: String
        let name: String
        let symbol: String
        
        static let all: [Currency] = [
            Currency(id: "CNY", name: "人民币", symbol: "¥"),
            Currency(id: "USD", name: "美元", symbol: "$"),
            Currency(id: "EUR", name: "欧元", symbol: "€"),
            Currency(id: "GBP", name: "英镑", symbol: "£"),
            Currency(id: "JPY", name: "日元", symbol: "¥"),
            Currency(id: "KRW", name: "韩元", symbol: "₩"),
            Currency(id: "HKD", name: "港币", symbol: "HK$"),
            Currency(id: "TWD", name: "新台币", symbol: "NT$"),
        ]
    }
    
    private init() {
        loadSavedRates()
    }
    
    func convert(_ amount: Double, from: String, to: String) -> Double {
        guard from != to else { return amount }
        
        let fromRate = exchangeRates[from] ?? 1.0
        let toRate = exchangeRates[to] ?? 1.0
        
        return amount / fromRate * toRate
    }
    
    func formatAmount(_ amount: Double, currency: String) -> String {
        if let currencyInfo = Currency.all.first(where: { $0.id == currency }) {
            return "\(currencyInfo.symbol)\(String(format: "%.2f", amount))"
        }
        return "\(currency) \(String(format: "%.2f", amount))"
    }
    
    func updateRates() async {
        isLoading = true
        
        // Simulate API call - in production, use a real exchange rate API
        // Example: https://api.exchangerate-api.com/v4/latest/CNY
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Mock rates (base: CNY)
        exchangeRates = [
            "CNY": 1.0,
            "USD": 0.14,
            "EUR": 0.13,
            "GBP": 0.11,
            "JPY": 21.5,
            "KRW": 185.0,
            "HKD": 1.09,
            "TWD": 4.5,
        ]
        
        lastUpdate = Date()
        saveRates()
        isLoading = false
    }
    
    private func saveRates() {
        defaults.set(exchangeRates, forKey: ratesKey)
        defaults.set(lastUpdate, forKey: lastUpdateKey)
    }
    
    private func loadSavedRates() {
        if let rates = defaults.dictionary(forKey: ratesKey) as? [String: Double] {
            exchangeRates = rates
        }
        lastUpdate = defaults.object(forKey: lastUpdateKey) as? Date
    }
}

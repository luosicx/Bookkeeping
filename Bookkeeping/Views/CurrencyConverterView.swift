import SwiftUI

struct CurrencyConverterView: View {
    @State private var currencyService = CurrencyService.shared
    @State private var inputAmount = ""
    @State private var fromCurrency: CurrencyService.Currency = .init(id: "CNY", name: "人民币", symbol: "¥")
    @State private var toCurrency: CurrencyService.Currency = .init(id: "USD", name: "美元", symbol: "$")
    @State private var showFromCurrencyPicker = false
    @State private var showToCurrencyPicker = false
    
    private var convertedAmount: Double {
        guard let amount = Double(inputAmount), amount > 0 else { return 0 }
        return currencyService.convert(amount, from: fromCurrency.id, to: toCurrency.id)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Input section
                VStack(spacing: 16) {
                    HStack {
                        Text(L.fromAmount)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button(action: { showFromCurrencyPicker = true }) {
                            HStack(spacing: 4) {
                                Text(fromCurrency.id)
                                    .fontWeight(.medium)
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                    
                    HStack {
                        Text(fromCurrency.symbol)
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        TextField("0", text: $inputAmount)
                            .keyboardType(.decimalPad)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
                
                // Swap button
                Button(action: swapCurrencies) {
                    Image(systemName: "arrow.up.arrow.down.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                // Output section
                VStack(spacing: 16) {
                    HStack {
                        Text(L.toAmount)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button(action: { showToCurrencyPicker = true }) {
                            HStack(spacing: 4) {
                                Text(toCurrency.id)
                                    .fontWeight(.medium)
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                    
                    HStack {
                        Text(toCurrency.symbol)
                            .font(.largeTitle)
                            .foregroundColor(.blue)
                        Text(String(format: "%.2f", convertedAmount))
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
                
                // Exchange rate info
                if let lastUpdate = currencyService.lastUpdate {
                    VStack(spacing: 4) {
                        Text("\(L.exchangeRate): 1 \(fromCurrency.id) = \(String(format: "%.4f", currencyService.convert(1, from: fromCurrency.id, to: toCurrency.id))) \(toCurrency.id)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("\(L.lastUpdated): \(lastUpdate, style: .relative) \(L.before)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if currencyService.isLoading {
                    ProgressView()
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle(L.currencyConverter)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await currencyService.updateRates()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .sheet(isPresented: $showFromCurrencyPicker) {
                CurrencyPicker(selectedCurrency: $fromCurrency, title: L.selectCurrency)
            }
            .sheet(isPresented: $showToCurrencyPicker) {
                CurrencyPicker(selectedCurrency: $toCurrency, title: L.selectCurrency)
            }
            .task {
                if currencyService.exchangeRates.isEmpty {
                    await currencyService.updateRates()
                }
            }
        }
    }
    
    private func swapCurrencies() {
        let temp = fromCurrency
        fromCurrency = toCurrency
        toCurrency = temp
    }
}

struct CurrencyPicker: View {
    @Binding var selectedCurrency: CurrencyService.Currency
    let title: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List(CurrencyService.Currency.all) { currency in
                Button(action: {
                    selectedCurrency = currency
                    dismiss()
                }) {
                    HStack {
                        Text(currency.symbol)
                            .frame(width: 30)
                            .foregroundColor(.secondary)
                        VStack(alignment: .leading) {
                            Text(currency.name)
                                .foregroundColor(.primary)
                            Text(currency.id)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if currency.id == selectedCurrency.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L.done) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CurrencyConverterView()
}

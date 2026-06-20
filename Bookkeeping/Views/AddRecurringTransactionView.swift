import SwiftUI
import SwiftData

struct AddRecurringTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let viewModel: RecurringTransactionViewModel
    
    @State private var amount: String = ""
    @State private var type: TransactionType = .expense
    @State private var selectedCategory: Category?
    @State private var note: String = ""
    @State private var frequency: Frequency = .monthly
    @State private var dayOfMonth: Int = 1
    @State private var dayOfWeek: Int = 1
    @State private var startDate: Date = Date()
    @State private var hasEndDate: Bool = false
    @State private var endDate: Date = Date()
    @State private var selectedAccount: Account?
    @State private var accounts: [Account] = []
    
    var body: some View {
        NavigationStack {
            Form(content: {
                Section(header: Text(L.transactionType)) {
                    Picker(L.transactionType, selection: $type) {
                        ForEach(TransactionType.allCases, id: \.self) { type in
                            Text(type.localizedName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text(L.amount)) {
                    HStack {
                        Text("¥")
                            .font(.title2)
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .font(.title2)
                    }
                }
                
                Section(header: Text(L.category)) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 15) {
                        ForEach(Category.categories(for: type)) { category in
                            CategoryButton(
                                category: category,
                                isSelected: selectedCategory?.id == category.id
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.vertical, 5)
                }
                
                Section(header: Text(L.frequency)) {
                    Picker(L.frequency, selection: $frequency) {
                        ForEach(Frequency.allCases, id: \.self) { freq in
                            HStack {
                                Image(systemName: freq.icon)
                                Text(freq.localizedName)
                            }
                            .tag(freq)
                        }
                    }
                    
                    if frequency == .monthly {
                        Picker(L.dayOfMonth, selection: $dayOfMonth) {
                            ForEach(1...31, id: \.self) { day in
                                Text("\(day)\(L.day)").tag(day)
                            }
                        }
                    }
                    
                    if frequency == .weekly {
                        Picker(L.dayOfWeek, selection: $dayOfWeek) {
                            ForEach(1...7, id: \.self) { day in
                                Text(weekdayName(day)).tag(day)
                            }
                        }
                    }
                }
                
                Section(header: Text(L.dateRange)) {
                    DatePicker(L.startDate, selection: $startDate, displayedComponents: .date)
                    
                    Toggle(L.hasEndDate, isOn: $hasEndDate)
                    
                    if hasEndDate {
                        DatePicker(L.endDate, selection: $endDate, displayedComponents: .date)
                    }
                }
                
                Section(header: Text(L.accountName)) {
                    Picker(L.accountName, selection: $selectedAccount) {
                        Text(L.none).tag(nil as Account?)
                        ForEach(accounts) { account in
                            HStack {
                                Image(systemName: account.icon)
                                Text(account.name)
                            }
                            .tag(account as Account?)
                        }
                    }
                }
                
                Section(header: Text(L.note)) {
                    TextField(L.addNote, text: $note)
                }
            })
            .navigationTitle(L.addRecurring)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L.cancel) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L.save) {
                        saveRecurring()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                loadAccounts()
            }
        }
    }
    
    private var isValid: Bool {
        guard let amountValue = Double(amount), amountValue > 0 else { return false }
        return selectedCategory != nil
    }
    
    private func loadAccounts() {
        let descriptor = FetchDescriptor<Account>(sortBy: [SortDescriptor(\.name)])
        accounts = (try? modelContext.fetch(descriptor)) ?? []
    }
    
    private func saveRecurring() {
        guard let amountValue = Double(amount), let category = selectedCategory else { return }
        
        viewModel.addRecurringTransaction(
            amount: amountValue,
            type: type,
            category: category.localizedName,
            note: note,
            frequency: frequency,
            dayOfMonth: dayOfMonth,
            dayOfWeek: dayOfWeek,
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil,
            account: selectedAccount
        )
        dismiss()
    }
    
    private func weekdayName(_ day: Int) -> String {
        let names = [L.sunday, L.monday, L.tuesday, L.wednesday, L.thursday, L.friday, L.saturday]
        return names[day - 1]
    }
}

#Preview {
    AddRecurringTransactionView(viewModel: RecurringTransactionViewModel())
}

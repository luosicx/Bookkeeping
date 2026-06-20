import SwiftUI
import SwiftData

struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let viewModel: TransactionViewModel
    let ledgerViewModel: LedgerViewModel
    
    @State private var amount: String = ""
    @State private var type: TransactionType = .expense
    @State private var selectedCategoryId: String?
    @State private var note: String = ""
    @State private var date: Date = Date()
    @State private var selectedAccount: Account?
    @State private var selectedLedger: Ledger?
    @State private var selectedTags: [Tag] = []
    @State private var accounts: [Account] = []
    @State private var availableTags: [Tag] = []
    
    private var selectedCategory: Category? {
        guard let id = selectedCategoryId else { return nil }
        return Category.categories(for: type).first { $0.id == id }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(L.transactionType)) {
                    HStack {
                        Picker(L.transactionType, selection: $type) {
                            ForEach(TransactionType.allCases, id: \.self) { type in
                                Text(type.localizedName).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: type) { _, _ in
                            selectedCategoryId = nil
                        }
                        
                        VoiceInputButton(
                            amount: $amount,
                            category: $selectedCategoryId,
                            note: $note,
                            transactionType: $type
                        )
                    }
                }
                
                Section(header: Text(L.amount)) {
                    HStack {
                        Text("¥")
                            .font(.title2)
                        TextField(L.amountPlaceholder, text: $amount)
                            .keyboardType(.decimalPad)
                            .font(.title2)
                    }
                }
                
                Section(header: Text(L.category)) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 15) {
                        ForEach(Category.categories(for: type)) { category in
                            CategoryButton(
                                category: category,
                                isSelected: selectedCategoryId == category.id
                            ) {
                                withAnimation {
                                    selectedCategoryId = category.id
                                }
                            }
                        }
                    }
                    .padding(.vertical, 5)
                }
                
                Section(header: Text(L.selectLedger)) {
                    Picker(L.selectLedger, selection: $selectedLedger) {
                        Text(L.none).tag(nil as Ledger?)
                        ForEach(ledgerViewModel.ledgers) { ledger in
                            HStack {
                                Image(systemName: ledger.icon)
                                Text(ledger.name)
                            }
                            .tag(ledger as Ledger?)
                        }
                    }
                }
                
                Section(header: Text(L.account)) {
                    Picker(L.account, selection: $selectedAccount) {
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
                
                Section(header: Text(L.date)) {
                    DatePicker(L.selectDate, selection: $date, displayedComponents: .date)
                }
                
                Section(header: Text(L.tags)) {
                    TagPickerView(selectedTags: $selectedTags, availableTags: availableTags)
                }
            }
            .navigationTitle(L.addTransaction)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L.cancel) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L.save) {
                        saveTransaction()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                loadAccounts()
                selectedLedger = ledgerViewModel.selectedLedger
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
        
        let tagDescriptor = FetchDescriptor<Tag>(sortBy: [SortDescriptor(\.name)])
        availableTags = (try? modelContext.fetch(tagDescriptor)) ?? []
    }
    
    private func saveTransaction() {
        guard let amountValue = Double(amount), let category = selectedCategory else { return }
        viewModel.addTransaction(
            amount: amountValue,
            type: type,
            category: category.localizedName,
            note: note,
            date: date,
            account: selectedAccount,
            ledger: selectedLedger
        )
        dismiss()
    }
}

struct CategoryButton: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                Text(category.localizedName)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)
            }
            .frame(width: 70, height: 60)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AddTransactionView(viewModel: TransactionViewModel(), ledgerViewModel: LedgerViewModel())
        .modelContainer(for: [Transaction.self, Ledger.self, Account.self])
}

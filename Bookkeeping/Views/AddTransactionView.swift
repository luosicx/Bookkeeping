import SwiftUI
import SwiftData

struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let viewModel: TransactionViewModel
    let ledgerViewModel: LedgerViewModel
    
    @State private var formViewModel = AddTransactionFormViewModel()
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(L.transactionType)) {
                    HStack {
                        Picker(L.transactionType, selection: $formViewModel.type) {
                            ForEach(TransactionType.allCases, id: \.self) { type in
                                Text(type.localizedName).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: formViewModel.type) { _, _ in
                            formViewModel.resetCategory()
                        }
                        
                        VoiceInputButton(
                            amount: $formViewModel.amount,
                            category: $formViewModel.selectedCategoryId,
                            note: $formViewModel.note,
                            transactionType: $formViewModel.type
                        )
                    }
                }
                
                Section(header: Text(L.amount)) {
                    HStack {
                        Text("¥")
                            .font(.title2)
                        TextField(L.amountPlaceholder, text: $formViewModel.amount)
                            .keyboardType(.decimalPad)
                            .font(.title2)
                    }
                }
                
                Section(header: Text(L.category)) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 15) {
                        ForEach(Category.categories(for: formViewModel.type)) { category in
                            CategoryButton(
                                category: category,
                                isSelected: formViewModel.selectedCategoryId == category.id
                            ) {
                                withAnimation {
                                    formViewModel.selectedCategoryId = category.id
                                }
                            }
                        }
                    }
                    .padding(.vertical, 5)
                }
                
                Section(header: Text(L.selectLedger)) {
                    Picker(L.selectLedger, selection: $formViewModel.selectedLedger) {
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
                
                Section(header: Text(L.accountName)) {
                    Picker(L.accountName, selection: $formViewModel.selectedAccount) {
                        Text(L.none).tag(nil as Account?)
                        ForEach(formViewModel.accounts) { account in
                            HStack {
                                Image(systemName: account.icon)
                                Text(account.name)
                            }
                            .tag(account as Account?)
                        }
                    }
                }
                
                Section(header: Text(L.note)) {
                    TextField(L.addNote, text: $formViewModel.note)
                }
                
                Section(header: Text(L.date)) {
                    DatePicker(L.selectDate, selection: $formViewModel.date, displayedComponents: .date)
                }
                
                Section(header: Text(L.tags)) {
                    TagPickerView(selectedTags: $formViewModel.selectedTags, availableTags: formViewModel.availableTags)
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
                        formViewModel.saveTransaction(viewModel: viewModel)
                        dismiss()
                    }
                    .disabled(!formViewModel.isValid)
                }
            }
            .onAppear {
                formViewModel.loadAccounts(modelContext: modelContext)
                formViewModel.loadTags(modelContext: modelContext)
                formViewModel.selectedLedger = ledgerViewModel.selectedLedger
            }
        }
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

import SwiftUI

struct TransactionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let transaction: Transaction
    let viewModel: TransactionViewModel
    
    @State private var showingEditView = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        List {
            Section(header: Text(L.basicInfo)) {
                HStack {
                    Text(L.transactionType)
                    Spacer()
                    Text(transaction.type.localizedName)
                        .foregroundColor(transaction.type == .income ? .green : .red)
                }
                
                HStack {
                    Text(L.amount)
                    Spacer()
                    Text("¥\(transaction.amount, specifier: "%.2f")")
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text(L.category)
                    Spacer()
                    Text(transaction.category)
                }
                
                HStack {
                    Text(L.date)
                    Spacer()
                    Text(transaction.date, format: .dateTime.year().month().day())
                }
            }
            
            if !transaction.note.isEmpty {
                Section(header: Text(L.note)) {
                    Text(transaction.note)
                }
            }
            
            Section {
                Button(action: { showingEditView = true }) {
                    HStack {
                        Image(systemName: "pencil")
                        Text(L.editRecord)
                    }
                    .foregroundColor(.blue)
                }
                
                Button(action: { showingDeleteAlert = true }) {
                    HStack {
                        Image(systemName: "trash")
                        Text(L.deleteRecord)
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .navigationTitle(L.transactionDetail)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditView) {
            EditTransactionView(transaction: transaction, viewModel: viewModel)
        }
        .alert(L.confirmDelete, isPresented: $showingDeleteAlert) {
            Button(L.cancel, role: .cancel) { }
            Button(L.delete, role: .destructive) {
                deleteTransaction()
            }
        } message: {
            Text(L.deleteMessage)
        }
    }
    
    private func deleteTransaction() {
        viewModel.deleteTransaction(transaction)
        dismiss()
    }
}

struct EditTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    let transaction: Transaction
    let viewModel: TransactionViewModel
    
    @State private var amount: String
    @State private var type: TransactionType
    @State private var selectedCategory: Category?
    @State private var note: String
    @State private var date: Date
    
    init(transaction: Transaction, viewModel: TransactionViewModel) {
        self.transaction = transaction
        self.viewModel = viewModel
        _amount = State(initialValue: String(format: "%.2f", transaction.amount))
        _type = State(initialValue: transaction.type)
        _note = State(initialValue: transaction.note)
        _date = State(initialValue: transaction.date)
        
        let categories = Category.categories(for: transaction.type)
        let matchedCategory = categories.first { $0.localizedName == transaction.category }
        _selectedCategory = State(initialValue: matchedCategory)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(L.transactionType)) {
                    Picker(L.transactionType, selection: $type) {
                        ForEach(TransactionType.allCases, id: \.self) { type in
                            Text(type.localizedName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: type) { _, newValue in
                        selectedCategory = Category.categories(for: newValue).first
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
                                isSelected: selectedCategory?.id == category.id
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.vertical, 5)
                }
                
                Section(header: Text(L.note)) {
                    TextField(L.addNote, text: $note)
                }
                
                Section(header: Text(L.date)) {
                    DatePicker(L.selectDate, selection: $date, displayedComponents: .date)
                }
            }
            .navigationTitle(L.editRecord)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L.cancel) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L.save) {
                        saveChanges()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        guard let amountValue = Double(amount), amountValue > 0 else { return false }
        return selectedCategory != nil
    }
    
    private func saveChanges() {
        guard let amountValue = Double(amount), let category = selectedCategory else { return }
        
        transaction.amount = amountValue
        transaction.type = type
        transaction.category = category.localizedName
        transaction.note = note
        transaction.date = date
        
        viewModel.fetchTransactions()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        TransactionDetailView(
            transaction: Transaction(amount: 100, type: .expense, category: "餐饮", note: "午餐", date: Date()),
            viewModel: TransactionViewModel()
        )
    }
    .modelContainer(for: Transaction.self)
}

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
    
    @State private var editViewModel = EditTransactionViewModel()
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(L.transactionType)) {
                    Picker(L.transactionType, selection: $editViewModel.type) {
                        ForEach(TransactionType.allCases, id: \.self) { type in
                            Text(type.localizedName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: editViewModel.type) { _, _ in
                        editViewModel.selectedCategoryId = nil
                    }
                }
                
                Section(header: Text(L.amount)) {
                    HStack {
                        Text("¥")
                            .font(.title2)
                        TextField(L.amountPlaceholder, text: $editViewModel.amount)
                            .keyboardType(.decimalPad)
                            .font(.title2)
                    }
                }
                
                Section(header: Text(L.category)) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 15) {
                        ForEach(Category.categories(for: editViewModel.type)) { category in
                            CategoryButton(
                                category: category,
                                isSelected: editViewModel.selectedCategoryId == category.id
                            ) {
                                editViewModel.selectedCategoryId = category.id
                            }
                        }
                    }
                    .padding(.vertical, 5)
                }
                
                Section(header: Text(L.note)) {
                    TextField(L.addNote, text: $editViewModel.note)
                }
                
                Section(header: Text(L.date)) {
                    DatePicker(L.selectDate, selection: $editViewModel.date, displayedComponents: .date)
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
                        editViewModel.saveChanges(transaction: transaction)
                        viewModel.fetchTransactions()
                        dismiss()
                    }
                    .disabled(!editViewModel.isValid)
                }
            }
            .onAppear {
                editViewModel.loadFromTransaction(transaction)
            }
        }
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

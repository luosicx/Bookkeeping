import SwiftUI
import SwiftData

struct DebtView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = DebtViewModel()
    @State private var showAddDebt = false
    @State private var selectedType: DebtType = .lend
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(L.debtLent)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("¥\(viewModel.totalLent, specifier: "%.2f")")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(L.debtBorrowed)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("¥\(viewModel.totalBorrowed, specifier: "%.2f")")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.purple)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section(L.unsettledDebts) {
                    if viewModel.unsettledDebts.isEmpty {
                        Text(L.noDebts)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(viewModel.unsettledDebts) { debt in
                            DebtRowView(debt: debt) {
                                viewModel.settleDebt(debt)
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                viewModel.deleteDebt(viewModel.unsettledDebts[index])
                            }
                        }
                    }
                }
                
                Section(L.settledDebts) {
                    let settled = viewModel.debts.filter { $0.isSettled }
                    if settled.isEmpty {
                        Text(L.noSettledDebts)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(settled) { debt in
                            DebtRowView(debt: debt, showSettle: false)
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                viewModel.deleteDebt(settled[index])
                            }
                        }
                    }
                }
            }
            .navigationTitle(L.debtManagement)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddDebt = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddDebt) {
                AddDebtView(viewModel: viewModel)
            }
            .onAppear {
                viewModel.modelContext = modelContext
                viewModel.fetchDebts()
            }
            .onChange(of: showAddDebt) { _, isShowing in
                if !isShowing {
                    viewModel.fetchDebts()
                }
            }
        }
    }
}

struct DebtRowView: View {
    let debt: Debt
    var onSettle: (() -> Void)?
    var showSettle: Bool = true
    
    var body: some View {
        HStack {
            Image(systemName: debt.type.icon)
                .foregroundColor(debt.type == .lend ? .orange : .purple)
                .frame(width: 30)
            
            VStack(alignment: .leading) {
                Text(debt.name)
                    .font(.headline)
                HStack {
                    Text(debt.type.localizedName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let dueDate = debt.dueDate {
                        Text("·")
                            .foregroundColor(.secondary)
                        Text(dueDate, style: .date)
                            .font(.caption)
                            .foregroundColor(dueDate < Date() ? .red : .secondary)
                    }
                }
            }
            
            Spacer()
            
            Text("¥\(debt.amount, specifier: "%.2f")")
                .fontWeight(.semibold)
            
            if showSettle, let onSettle = onSettle {
                Button(action: onSettle) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddDebtView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: DebtViewModel
    
    @State private var name = ""
    @State private var amount = ""
    @State private var type: DebtType = .lend
    @State private var note = ""
    @State private var date = Date()
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    
    var body: some View {
        NavigationStack {
            Form {
                Section(L.debtType) {
                    Picker(L.debtType, selection: $type) {
                        ForEach(DebtType.allCases, id: \.self) { type in
                            Text(type.localizedName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(L.debtPerson) {
                    TextField(L.enterPersonName, text: $name)
                }
                
                Section(L.amount) {
                    HStack {
                        Text("¥")
                            .font(.title2)
                        TextField(L.amountPlaceholder, text: $amount)
                            .keyboardType(.decimalPad)
                            .font(.title2)
                    }
                }
                
                Section(L.note) {
                    TextField(L.addNote, text: $note)
                }
                
                Section(L.date) {
                    DatePicker(L.selectDate, selection: $date, displayedComponents: .date)
                    
                    Toggle(L.hasDueDate, isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker(L.dueDate, selection: $dueDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle(L.addDebt)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L.cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L.save) {
                        saveDebt()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        guard let amountValue = Double(amount), amountValue > 0 else { return false }
        return !name.isEmpty
    }
    
    private func saveDebt() {
        guard let amountValue = Double(amount) else { return }
        viewModel.addDebt(
            name: name,
            amount: amountValue,
            type: type,
            note: note,
            date: date,
            dueDate: hasDueDate ? dueDate : nil
        )
        dismiss()
    }
}

#Preview {
    DebtView()
        .modelContainer(for: [Debt.self])
}

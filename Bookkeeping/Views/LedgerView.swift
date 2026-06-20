import SwiftUI
import SwiftData

struct LedgerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = LedgerViewModel()
    @State private var showingAddLedger = false
    
    var body: some View {
        List {
            Section(header: Text(L.myLedgers)) {
                if viewModel.ledgers.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "book.closed")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            Text(L.noLedgers)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        Spacer()
                    }
                } else {
                    ForEach(viewModel.ledgers) { ledger in
                        LedgerRow(ledger: ledger, isSelected: viewModel.selectedLedger?.id == ledger.id)
                            .onTapGesture {
                                viewModel.selectLedger(ledger)
                            }
                            .swipeActions(edge: .trailing) {
                                if !ledger.isDefault {
                                    Button(role: .destructive) {
                                        viewModel.deleteLedger(ledger)
                                    } label: {
                                        Label(L.delete, systemImage: "trash")
                                    }
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    viewModel.updateLedger(ledger, isDefault: true)
                                } label: {
                                    Label(L.setDefault, systemImage: "star")
                                }
                                .tint(.yellow)
                            }
                    }
                }
            }
            
            Section {
                Button(action: { showingAddLedger = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                        Text(L.addLedger)
                    }
                }
            }
        }
        .navigationTitle(L.ledgerManagement)
        .sheet(isPresented: $showingAddLedger) {
            AddLedgerView(viewModel: viewModel)
        }
        .onAppear {
            viewModel.modelContext = modelContext
            viewModel.fetchLedgers()
        }
    }
}

struct LedgerRow: View {
    let ledger: Ledger
    let isSelected: Bool
    
    var body: some View {
        HStack {
            Image(systemName: ledger.icon)
                .font(.title2)
                .foregroundColor(Color(ledger.color))
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(ledger.name)
                        .font(.headline)
                    if ledger.isDefault {
                        Text(L.defaultLedger)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.yellow.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                Text(L.transactionCountFormat(ledger.transactions?.count ?? 0))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddLedgerView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: LedgerViewModel
    
    @State private var name: String = ""
    @State private var selectedType: LedgerType = .personal
    @State private var isDefault: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(L.ledgerType)) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 15) {
                        ForEach(LedgerType.allCases, id: \.self) { type in
                            LedgerTypeButton(
                                type: type,
                                isSelected: selectedType == type
                            ) {
                                selectedType = type
                            }
                        }
                    }
                    .padding(.vertical, 5)
                }
                
                Section(header: Text(L.ledgerName)) {
                    TextField(L.enterLedgerName, text: $name)
                }
                
                Section {
                    Toggle(L.setDefault, isOn: $isDefault)
                }
            }
            .navigationTitle(L.addLedger)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L.cancel) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L.save) {
                        saveLedger()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        !name.isEmpty
    }
    
    private func saveLedger() {
        viewModel.addLedger(name: name, icon: selectedType.icon, color: selectedType.color, isDefault: isDefault)
        dismiss()
    }
}

struct LedgerTypeButton: View {
    let type: LedgerType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : Color(type.color))
                Text(type.localizedName)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(width: 80, height: 60)
            .background(isSelected ? Color(type.color) : Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}

#Preview {
    NavigationStack {
        LedgerView()
    }
    .modelContainer(for: [Ledger.self, Transaction.self])
}

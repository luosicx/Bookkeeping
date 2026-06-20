import SwiftUI

struct AddAccountView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: AccountViewModel
    
    @State private var name: String = ""
    @State private var selectedType: AccountType = .cash
    @State private var balance: String = "0"
    @State private var isDefault: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(L.accountType)) {
                    Picker(L.accountType, selection: $selectedType) {
                        ForEach(AccountType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.localizedName)
                            }
                            .tag(type)
                        }
                    }
                }
                
                Section(header: Text(L.accountName)) {
                    TextField(L.enterAccountName, text: $name)
                }
                
                Section(header: Text(L.initialBalance)) {
                    HStack {
                        Text("¥")
                            .font(.title2)
                        TextField("0", text: $balance)
                            .keyboardType(.decimalPad)
                            .font(.title2)
                    }
                }
                
                Section {
                    Toggle(L.setDefault, isOn: $isDefault)
                }
            }
            .navigationTitle(L.addAccount)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L.cancel) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L.save) {
                        saveAccount()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        !name.isEmpty && Double(balance) != nil
    }
    
    private func saveAccount() {
        guard let balanceValue = Double(balance) else { return }
        viewModel.addAccount(name: name, type: selectedType, icon: selectedType.icon, balance: balanceValue, isDefault: isDefault)
        dismiss()
    }
}

struct EditAccountView: View {
    @Environment(\.dismiss) private var dismiss
    let account: Account
    let viewModel: AccountViewModel
    
    @State private var name: String
    @State private var selectedType: AccountType
    @State private var balance: String
    @State private var isDefault: Bool
    
    init(account: Account, viewModel: AccountViewModel) {
        self.account = account
        self.viewModel = viewModel
        _name = State(initialValue: account.name)
        _selectedType = State(initialValue: account.type)
        _balance = State(initialValue: String(format: "%.2f", account.balance))
        _isDefault = State(initialValue: account.isDefault)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(L.accountType)) {
                    Picker(L.accountType, selection: $selectedType) {
                        ForEach(AccountType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.localizedName)
                            }
                            .tag(type)
                        }
                    }
                }
                
                Section(header: Text(L.accountName)) {
                    TextField(L.enterAccountName, text: $name)
                }
                
                Section(header: Text(L.currentBalance)) {
                    HStack {
                        Text("¥")
                            .font(.title2)
                        TextField("0", text: $balance)
                            .keyboardType(.decimalPad)
                            .font(.title2)
                    }
                }
                
                Section {
                    Toggle(L.setDefault, isOn: $isDefault)
                }
            }
            .navigationTitle(L.editAccount)
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
        !name.isEmpty && Double(balance) != nil
    }
    
    private func saveChanges() {
        guard let balanceValue = Double(balance) else { return }
        viewModel.updateAccount(account, name: name, icon: selectedType.icon, type: selectedType, balance: balanceValue, isDefault: isDefault)
        dismiss()
    }
}

#Preview {
    AddAccountView(viewModel: AccountViewModel())
}

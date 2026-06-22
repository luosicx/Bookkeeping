import SwiftUI
import SwiftData

struct AccountView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = AccountViewModel()
    @State private var showingAddAccount = false
    
    var body: some View {
        List {
            Section {
                AccountSummaryCard(totalBalance: viewModel.totalBalance)
            }
            
            Section(header: Text(L.myAccounts)) {
                if viewModel.accounts.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "wallet.bifold")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            Text(L.noAccounts)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        Spacer()
                    }
                } else {
                    ForEach(viewModel.accounts) { account in
                        NavigationLink {
                            AccountDetailView(account: account, viewModel: viewModel)
                        } label: {
                            AccountRow(account: account)
                        }
                        .swipeActions(edge: .trailing) {
                            if !account.isDefault {
                                Button(role: .destructive) {
                                    viewModel.deleteAccount(account)
                                } label: {
                                    Label(L.delete, systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(L.accountManagement)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddAccount = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
            }
        }
        .sheet(isPresented: $showingAddAccount) {
            AddAccountView(viewModel: viewModel)
        }
        .onAppear {
            viewModel.modelContext = modelContext
            viewModel.fetchAccounts()
        }
        .onChange(of: showingAddAccount) { _, isShowing in
            if !isShowing {
                viewModel.fetchAccounts()
            }
        }
    }
}

struct AccountSummaryCard: View {
    let totalBalance: Double
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(L.totalAssets)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("¥\(totalBalance, specifier: "%.2f")")
                        .font(.system(size: 32, weight: .bold))
                }
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct AccountRow: View {
    let account: Account
    
    var body: some View {
        HStack {
            Image(systemName: account.icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(account.name)
                        .font(.headline)
                    if account.isDefault {
                        Text(L.defaultAccount)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                Text(account.type.localizedName)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text("¥\(account.balance, specifier: "%.2f")")
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(account.balance >= 0 ? .primary : .red)
        }
        .padding(.vertical, 4)
    }
}

struct AccountDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let account: Account
    let viewModel: AccountViewModel
    
    @State private var showingEditView = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: account.icon)
                        .font(.largeTitle)
                        .foregroundColor(.blue)
                    
                    Text(account.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(account.type.localizedName)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text("¥\(account.balance, specifier: "%.2f")")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(account.balance >= 0 ? .primary : .red)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            
            Section(header: Text(L.accountInfo)) {
                HStack {
                    Text(L.accountType)
                    Spacer()
                    Text(account.type.localizedName)
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Text(L.defaultAccount)
                    Spacer()
                    Text(account.isDefault ? L.yes : L.no)
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Text(L.transactionCount)
                    Spacer()
                    Text("\(account.transactions?.count ?? 0)")
                        .foregroundColor(.gray)
                }
            }
            
            Section {
                Button(action: { showingEditView = true }) {
                    HStack {
                        Image(systemName: "pencil")
                        Text(L.editAccount)
                    }
                    .foregroundColor(.blue)
                }
                
                if !account.isDefault {
                    Button(action: { showingDeleteAlert = true }) {
                        HStack {
                            Image(systemName: "trash")
                            Text(L.deleteAccount)
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
        .navigationTitle(L.accountDetail)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditView) {
            EditAccountView(account: account, viewModel: viewModel)
        }
        .alert(L.confirmDelete, isPresented: $showingDeleteAlert) {
            Button(L.cancel, role: .cancel) { }
            Button(L.delete, role: .destructive) {
                viewModel.deleteAccount(account)
                dismiss()
            }
        } message: {
            Text(L.deleteAccountMessage)
        }
    }
}

#Preview {
    NavigationStack {
        AccountView()
    }
    .modelContainer(for: [Account.self, Transaction.self])
}

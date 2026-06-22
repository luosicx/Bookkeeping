import SwiftUI
import SwiftData

struct RecurringTransactionView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = RecurringTransactionViewModel()
    @State private var showingAddView = false
    
    var body: some View {
        List {
            Section(header: Text(L.autoGenerate)) {
                Button(action: {
                    viewModel.generateTransactions(modelContext: modelContext)
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.blue)
                        Text(L.generateNow)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Section(header: Text(L.recurringList)) {
                if viewModel.recurringTransactions.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            Text(L.noRecurring)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        Spacer()
                    }
                } else {
                    ForEach(viewModel.recurringTransactions) { recurring in
                        RecurringRow(recurring: recurring, viewModel: viewModel)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    viewModel.deleteRecurringTransaction(recurring)
                                } label: {
                                    Label(L.delete, systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    viewModel.toggleActive(recurring)
                                } label: {
                                    Label(recurring.isActive ? L.pause : L.resume, 
                                          systemImage: recurring.isActive ? "pause" : "play")
                                }
                                .tint(recurring.isActive ? .orange : .green)
                            }
                    }
                }
            }
        }
        .navigationTitle(L.recurringTransactions)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddView = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
            }
        }
        .sheet(isPresented: $showingAddView) {
            AddRecurringTransactionView(viewModel: viewModel)
        }
        .onAppear {
            viewModel.modelContext = modelContext
            viewModel.fetchRecurringTransactions()
        }
        .onChange(of: showingAddView) { _, isShowing in
            if !isShowing {
                viewModel.fetchRecurringTransactions()
            }
        }
    }
}

struct RecurringRow: View {
    let recurring: RecurringTransaction
    let viewModel: RecurringTransactionViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: recurring.type == .income ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                    .foregroundColor(recurring.type == .income ? .green : .red)
                
                Text(recurring.category)
                    .font(.headline)
                
                Spacer()
                
                Text("\(recurring.type == .income ? "+" : "-")¥\(recurring.amount, specifier: "%.0f")")
                    .fontWeight(.semibold)
                    .foregroundColor(recurring.type == .income ? .green : .red)
            }
            
            HStack {
                Image(systemName: recurring.frequency.icon)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(recurring.frequency.localizedName)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                if !recurring.note.isEmpty {
                    Text("·")
                        .foregroundColor(.gray)
                    Text(recurring.note)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if !recurring.isActive {
                    Text(L.paused)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            
            if let lastGenerated = recurring.lastGenerated {
                Text("\(L.lastGenerated): \(lastGenerated, format: .dateTime.month().day())")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
        .opacity(recurring.isActive ? 1.0 : 0.6)
    }
}

#Preview {
    NavigationStack {
        RecurringTransactionView()
    }
    .modelContainer(for: [RecurringTransaction.self, Transaction.self])
}

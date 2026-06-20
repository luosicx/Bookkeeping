import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedDate = Date()
    @State private var transactions: [Transaction] = []
    
    private let calendar = Calendar.current
    
    private var dayTransactions: [Transaction] {
        transactions.filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DatePicker(
                    "",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding()
                
                Divider()
                
                List {
                    Section {
                        if dayTransactions.isEmpty {
                            Text(L.noTransactions)
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(dayTransactions) { transaction in
                                TransactionRowView(transaction: transaction)
                            }
                        }
                    } header: {
                        HStack {
                            Text(selectedDate, format: .dateTime.year().month().day())
                            Spacer()
                            let total = dayTransactions.reduce(0) { $0 + $1.amount }
                            Text("¥\(total, specifier: "%.2f")")
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            .navigationTitle(L.calendar)
            .onAppear {
                loadTransactions()
            }
            .onChange(of: selectedDate) { _, _ in
                loadTransactions()
            }
        }
    }
    
    private func loadTransactions() {
        let descriptor = FetchDescriptor<Transaction>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        transactions = (try? modelContext.fetch(descriptor)) ?? []
    }
    
    private func transactionsForDay(_ date: Date) -> [Transaction] {
        transactions.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }
}

struct TransactionRowView: View {
    let transaction: Transaction
    
    var body: some View {
        HStack {
            Image(systemName: transaction.type == .income ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .foregroundColor(transaction.type == .income ? .green : .red)
                .frame(width: 24)
            
            VStack(alignment: .leading) {
                Text(transaction.category)
                    .font(.headline)
                if !transaction.note.isEmpty {
                    Text(transaction.note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text("\(transaction.type == .income ? "+" : "-")¥\(transaction.amount, specifier: "%.2f")")
                .fontWeight(.semibold)
                .foregroundColor(transaction.type == .income ? .green : .red)
        }
    }
}

#Preview {
    CalendarView()
        .modelContainer(for: [Transaction.self])
}

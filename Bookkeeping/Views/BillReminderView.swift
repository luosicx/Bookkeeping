import SwiftUI
import SwiftData

struct BillReminderView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = BillReminderViewModel()
    @State private var showingAddReminder = false
    @State private var showingPermissionAlert = false
    
    var body: some View {
        List {
            if !viewModel.overdueReminders.isEmpty {
                Section(header: Text(L.overdue).foregroundColor(.red)) {
                    ForEach(viewModel.overdueReminders) { reminder in
                        BillReminderRow(reminder: reminder, viewModel: viewModel)
                    }
                }
            }
            
            Section(header: Text(L.upcoming)) {
                if viewModel.upcomingReminders.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "bell.slash")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            Text(L.noReminders)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        Spacer()
                    }
                } else {
                    ForEach(viewModel.upcomingReminders) { reminder in
                        BillReminderRow(reminder: reminder, viewModel: viewModel)
                    }
                }
            }
            
            if !viewModel.paidReminders.isEmpty {
                Section(header: Text(L.paid)) {
                    ForEach(viewModel.paidReminders) { reminder in
                        BillReminderRow(reminder: reminder, viewModel: viewModel)
                            .opacity(0.6)
                    }
                }
            }
        }
        .navigationTitle(L.billReminders)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddReminder = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
            }
        }
        .sheet(isPresented: $showingAddReminder) {
            NavigationStack {
                AddBillReminderView(viewModel: viewModel)
            }
        }
        .alert(L.notificationPermission, isPresented: $showingPermissionAlert) {
            Button(L.openSettings) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button(L.cancel, role: .cancel) { }
        } message: {
            Text(L.notificationPermissionMessage)
        }
        .onAppear {
            viewModel.modelContext = modelContext
            viewModel.fetchReminders()
            checkNotificationPermission()
        }
        .onChange(of: showingAddReminder) { _, isShowing in
            if !isShowing {
                viewModel.fetchReminders()
            }
        }
    }
    
    private func checkNotificationPermission() {
        NotificationService.shared.checkPermission { granted in
            if !granted {
                showingPermissionAlert = true
            }
        }
    }
}

struct BillReminderRow: View {
    let reminder: BillReminder
    let viewModel: BillReminderViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(reminder.title)
                        .font(.headline)
                        .strikethrough(reminder.isPaid)
                    
                    if reminder.isOverdue {
                        Text(L.overdue)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    } else if reminder.isDueSoon {
                        Text(L.dueSoon)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                }
                
                HStack {
                    if let amount = reminder.amount {
                        Text("¥\(amount, specifier: "%.2f")")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    Text(reminder.dueDate, format: .dateTime.month().day())
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    if !reminder.note.isEmpty {
                        Text("·")
                            .foregroundColor(.gray)
                        Text(reminder.note)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            if reminder.isPaid {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
            } else {
                Button(action: { viewModel.markAsPaid(reminder) }) {
                    Image(systemName: "circle")
                        .foregroundColor(.gray)
                        .font(.title2)
                }
            }
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                viewModel.deleteReminder(reminder)
            } label: {
                Label(L.delete, systemImage: "trash")
            }
            
            Button {
                viewModel.toggleEnabled(reminder)
            } label: {
                Label(reminder.isEnabled ? L.disable : L.enable, 
                      systemImage: reminder.isEnabled ? "bell.slash" : "bell")
            }
            .tint(reminder.isEnabled ? .orange : .green)
        }
        .swipeActions(edge: .leading) {
            if reminder.isPaid {
                Button {
                    viewModel.markAsUnpaid(reminder)
                } label: {
                    Label(L.markUnpaid, systemImage: "arrow.uturn.backward")
                }
                .tint(.orange)
            }
        }
    }
}

struct AddBillReminderView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: BillReminderViewModel
    
    @State private var title: String = ""
    @State private var hasAmount: Bool = false
    @State private var amount: String = ""
    @State private var dueDate: Date = Date()
    @State private var repeatFrequency: Frequency = .monthly
    @State private var note: String = ""
    
    var body: some View {
        List {
            Section(header: Text(L.reminderTitle)) {
                TextField(L.enterReminderTitle, text: $title)
            }
            
            Section(header: Text(L.amount)) {
                Toggle(L.hasAmount, isOn: $hasAmount)
                
                if hasAmount {
                    HStack {
                        Text("¥")
                            .font(.title2)
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .font(.title2)
                    }
                }
            }
            
            Section(header: Text(L.dueDate)) {
                DatePicker(L.selectDate, selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
            }
            
            Section(header: Text(L.repeat_)) {
                Picker(L.frequency, selection: $repeatFrequency) {
                    ForEach(Frequency.allCases, id: \.self) { freq in
                        Text(freq.localizedName).tag(freq)
                    }
                }
            }
            
            Section(header: Text(L.note)) {
                TextField(L.addNote, text: $note)
            }
        }
        .navigationTitle(L.addReminder)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(L.cancel) {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(L.save) {
                    saveReminder()
                }
                .disabled(!isValid)
            }
        }
    }
    
    private var isValid: Bool {
        !title.isEmpty && (!hasAmount || Double(amount) != nil)
    }
    
    private func saveReminder() {
        let amountValue = hasAmount ? Double(amount) : nil
        viewModel.addReminder(title: title, amount: amountValue, dueDate: dueDate, repeatFrequency: repeatFrequency, note: note)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        BillReminderView()
    }
    .modelContainer(for: BillReminder.self)
}

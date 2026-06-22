import SwiftUI
import SwiftData

struct SavingsGoalView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = SavingsGoalViewModel()
    @State private var showingAddGoal = false
    
    var body: some View {
        List {
            Section {
                SavingsSummaryCard(viewModel: viewModel)
            }
            
            Section(header: Text(L.myGoals)) {
                if viewModel.goals.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "target")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            Text(L.noGoals)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        Spacer()
                    }
                } else {
                    ForEach(viewModel.goals) { goal in
                        NavigationLink {
                            SavingsGoalDetailView(goal: goal, viewModel: viewModel)
                        } label: {
                            SavingsGoalRow(goal: goal)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                viewModel.deleteGoal(goal)
                            } label: {
                                Label(L.delete, systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(L.savingsGoals)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddGoal = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
            }
        }
        .sheet(isPresented: $showingAddGoal) {
            AddSavingsGoalView(viewModel: viewModel)
        }
        .onAppear {
            viewModel.modelContext = modelContext
            viewModel.fetchGoals()
        }
        .onChange(of: showingAddGoal) { _, isShowing in
            if !isShowing {
                viewModel.fetchGoals()
            }
        }
    }
}

struct SavingsSummaryCard: View {
    let viewModel: SavingsGoalViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(L.totalSaved)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("¥\(viewModel.totalSaved, specifier: "%.0f")")
                        .font(.system(size: 32, weight: .bold))
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text(L.targetAmount)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("¥\(viewModel.totalTarget, specifier: "%.0f")")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }
            
            ProgressView(value: viewModel.overallProgress)
                .tint(.green)
                .scaleEffect(y: 2.0)
            
            HStack {
                Text("\(Int(viewModel.overallProgress * 100))%")
                    .font(.caption)
                    .foregroundColor(.green)
                Spacer()
                Text(L.goalCount(viewModel.goals.count))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct SavingsGoalRow: View {
    let goal: SavingsGoal
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: goal.icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading) {
                    Text(goal.name)
                        .font(.headline)
                    if let days = goal.daysRemaining {
                        Text(L.daysRemaining(days))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("¥\(goal.currentAmount, specifier: "%.0f")")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("/ ¥\(goal.targetAmount, specifier: "%.0f")")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            ProgressView(value: goal.progress)
                .tint(goal.isCompleted ? .green : .blue)
            
            HStack {
                if goal.isCompleted {
                    Label(L.completed, systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text("\(L.remaining): ¥\(goal.remaining, specifier: "%.0f")")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
                Text("\(Int(goal.progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
}

struct SavingsGoalDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let goal: SavingsGoal
    let viewModel: SavingsGoalViewModel
    
    @State private var showingDeposit = false
    @State private var showingWithdraw = false
    @State private var showingEdit = false
    
    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    Image(systemName: goal.icon)
                        .font(.largeTitle)
                        .foregroundColor(.blue)
                    
                    Text(goal.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                        
                        Circle()
                            .trim(from: 0, to: goal.progress)
                            .stroke(goal.isCompleted ? Color.green : Color.blue, lineWidth: 20)
                            .rotationEffect(.degrees(-90))
                        
                        VStack {
                            Text("\(Int(goal.progress * 100))%")
                                .font(.system(size: 36, weight: .bold))
                            Text(L.progress)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(width: 150, height: 150)
                    
                    HStack(spacing: 30) {
                        VStack {
                            Text(L.currentAmount)
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("¥\(goal.currentAmount, specifier: "%.0f")")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        
                        VStack {
                            Text(L.targetAmount)
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("¥\(goal.targetAmount, specifier: "%.0f")")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                    }
                    
                    if let deadline = goal.deadline {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.gray)
                            Text(L.deadline)
                                .foregroundColor(.gray)
                            Text(deadline, format: .dateTime.year().month().day())
                        }
                        .font(.subheadline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            
            Section {
                Button(action: { showingDeposit = true }) {
                    HStack {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.green)
                        Text(L.deposit)
                            .foregroundColor(.primary)
                    }
                }
                
                Button(action: { showingWithdraw = true }) {
                    HStack {
                        Image(systemName: "minus.circle")
                            .foregroundColor(.red)
                        Text(L.withdraw)
                            .foregroundColor(.primary)
                    }
                }
                
                Button(action: { showingEdit = true }) {
                    HStack {
                        Image(systemName: "pencil")
                            .foregroundColor(.blue)
                        Text(L.editGoal)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .navigationTitle(L.goalDetail)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingDeposit) {
            DepositView(goal: goal, viewModel: viewModel, isDeposit: true)
        }
        .sheet(isPresented: $showingWithdraw) {
            DepositView(goal: goal, viewModel: viewModel, isDeposit: false)
        }
        .sheet(isPresented: $showingEdit) {
            EditSavingsGoalView(goal: goal, viewModel: viewModel)
        }
    }
}

struct AddSavingsGoalView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: SavingsGoalViewModel
    
    @State private var name: String = ""
    @State private var selectedIcon: String = "target"
    @State private var targetAmount: String = ""
    @State private var hasDeadline: Bool = false
    @State private var deadline: Date = Date()
    
    let icons = ["target", "car", "house", "airplane", "graduationcap", "gift", "iphone", "heart"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(L.goalName)) {
                    TextField(L.enterGoalName, text: $name)
                }
                
                Section(header: Text(L.icon)) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 15) {
                        ForEach(icons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title2)
                                .frame(width: 50, height: 50)
                                .background(selectedIcon == icon ? Color.blue : Color(.systemGray6))
                                .foregroundColor(selectedIcon == icon ? .white : .primary)
                                .cornerRadius(10)
                                .onTapGesture {
                                    selectedIcon = icon
                                }
                        }
                    }
                    .padding(.vertical, 5)
                }
                
                Section(header: Text(L.targetAmount)) {
                    HStack {
                        Text("¥")
                            .font(.title2)
                        TextField("0", text: $targetAmount)
                            .keyboardType(.numberPad)
                            .font(.title2)
                    }
                }
                
                Section(header: Text(L.deadline)) {
                    Toggle(L.setDeadline, isOn: $hasDeadline)
                    
                    if hasDeadline {
                        DatePicker(L.selectDate, selection: $deadline, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle(L.addGoal)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L.cancel) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L.save) {
                        saveGoal()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        !name.isEmpty && Double(targetAmount) != nil && (Double(targetAmount) ?? 0) > 0
    }
    
    private func saveGoal() {
        guard let amount = Double(targetAmount) else { return }
        viewModel.addGoal(name: name, icon: selectedIcon, targetAmount: amount, deadline: hasDeadline ? deadline : nil)
        dismiss()
    }
}

struct EditSavingsGoalView: View {
    @Environment(\.dismiss) private var dismiss
    let goal: SavingsGoal
    let viewModel: SavingsGoalViewModel
    
    @State private var name: String
    @State private var selectedIcon: String
    @State private var targetAmount: String
    @State private var hasDeadline: Bool
    @State private var deadline: Date
    
    let icons = ["target", "car", "house", "airplane", "graduationcap", "gift", "iphone", "heart"]
    
    init(goal: SavingsGoal, viewModel: SavingsGoalViewModel) {
        self.goal = goal
        self.viewModel = viewModel
        _name = State(initialValue: goal.name)
        _selectedIcon = State(initialValue: goal.icon)
        _targetAmount = State(initialValue: String(format: "%.0f", goal.targetAmount))
        _hasDeadline = State(initialValue: goal.deadline != nil)
        _deadline = State(initialValue: goal.deadline ?? Date())
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(L.goalName)) {
                    TextField(L.enterGoalName, text: $name)
                }
                
                Section(header: Text(L.icon)) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 15) {
                        ForEach(icons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title2)
                                .frame(width: 50, height: 50)
                                .background(selectedIcon == icon ? Color.blue : Color(.systemGray6))
                                .foregroundColor(selectedIcon == icon ? .white : .primary)
                                .cornerRadius(10)
                                .onTapGesture {
                                    selectedIcon = icon
                                }
                        }
                    }
                    .padding(.vertical, 5)
                }
                
                Section(header: Text(L.targetAmount)) {
                    HStack {
                        Text("¥")
                            .font(.title2)
                        TextField("0", text: $targetAmount)
                            .keyboardType(.numberPad)
                            .font(.title2)
                    }
                }
                
                Section(header: Text(L.deadline)) {
                    Toggle(L.setDeadline, isOn: $hasDeadline)
                    
                    if hasDeadline {
                        DatePicker(L.selectDate, selection: $deadline, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle(L.editGoal)
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
        !name.isEmpty && Double(targetAmount) != nil && (Double(targetAmount) ?? 0) > 0
    }
    
    private func saveChanges() {
        guard let amount = Double(targetAmount) else { return }
        viewModel.updateGoal(goal, name: name, icon: selectedIcon, targetAmount: amount, deadline: hasDeadline ? deadline : nil)
        dismiss()
    }
}

struct DepositView: View {
    @Environment(\.dismiss) private var dismiss
    let goal: SavingsGoal
    let viewModel: SavingsGoalViewModel
    let isDeposit: Bool
    
    @State private var amount: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(isDeposit ? L.depositAmount : L.withdrawAmount)) {
                    HStack {
                        Text("¥")
                            .font(.title2)
                        TextField("0", text: $amount)
                            .keyboardType(.numberPad)
                            .font(.title2)
                    }
                }
                
                if !isDeposit {
                    Section {
                        Text("\(L.availableBalance): ¥\(goal.currentAmount, specifier: "%.0f")")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle(isDeposit ? L.deposit : L.withdraw)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L.cancel) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L.confirm) {
                        performAction()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        guard let amountValue = Double(amount), amountValue > 0 else { return false }
        if !isDeposit {
            return amountValue <= goal.currentAmount
        }
        return true
    }
    
    private func performAction() {
        guard let amountValue = Double(amount) else { return }
        if isDeposit {
            viewModel.addDeposit(to: goal, amount: amountValue)
        } else {
            viewModel.withdraw(from: goal, amount: amountValue)
        }
        dismiss()
    }
}

#Preview {
    NavigationStack {
        SavingsGoalView()
    }
    .modelContainer(for: SavingsGoal.self)
}

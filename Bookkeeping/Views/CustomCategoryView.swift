import SwiftUI
import SwiftData

struct CustomCategoryView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var categoryManager = CustomCategoryManager.shared
    @State private var showingAddCategory = false
    @State private var selectedType: TransactionType = .expense
    
    var filteredCategories: [CustomCategory] {
        categoryManager.customCategories.filter { $0.type == selectedType }
    }
    
    var body: some View {
        List {
            Section {
                Picker(L.type, selection: $selectedType) {
                    ForEach(TransactionType.allCases, id: \.self) { type in
                        Text(type.localizedName).tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Section(header: Text(L.customCategories)) {
                if filteredCategories.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "tag")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            Text(L.noCustomCategories)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        Spacer()
                    }
                } else {
                    ForEach(filteredCategories) { category in
                        HStack {
                            Image(systemName: category.icon)
                                .foregroundColor(.blue)
                            Text(category.name)
                            Spacer()
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            categoryManager.deleteCategory(filteredCategories[index], modelContext: modelContext)
                        }
                    }
                }
            }
            
            Section(header: Text(L.defaultCategories)) {
                ForEach(Category.categories(for: selectedType)) { category in
                    HStack {
                        Image(systemName: category.icon)
                            .foregroundColor(.blue)
                        Text(category.localizedName)
                        Spacer()
                        Text(L.defaultTag)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .navigationTitle(L.categoryManagement)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddCategory = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
            }
        }
        .sheet(isPresented: $showingAddCategory) {
            AddCustomCategoryView(categoryManager: categoryManager, type: selectedType)
        }
        .onAppear {
            categoryManager.fetchCategories(modelContext: modelContext)
        }
        .onChange(of: showingAddCategory) { _, isShowing in
            if !isShowing {
                categoryManager.fetchCategories(modelContext: modelContext)
            }
        }
    }
}

struct AddCustomCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    let categoryManager: CustomCategoryManager
    let type: TransactionType
    
    @Environment(\.modelContext) private var modelContext
    @State private var name: String = ""
    @State private var selectedIcon: String = "tag"
    
    let icons = ["tag", "star", "heart", "cart", "bag", "gift", "game", "music", "film", "book", "home", "car", "plane", "coffee", "food", "health", "education", "other"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(L.categoryName)) {
                    TextField(L.enterCategoryName, text: $name)
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
            }
            .navigationTitle(L.addCategory)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L.cancel) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L.save) {
                        categoryManager.addCategory(name: name, icon: selectedIcon, type: type, modelContext: modelContext)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        CustomCategoryView()
    }
    .modelContainer(for: CustomCategory.self)
}

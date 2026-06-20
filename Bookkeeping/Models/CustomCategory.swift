import Foundation
import SwiftData

@Model
class CustomCategory {
    var id: UUID
    var name: String
    var icon: String
    var type: TransactionType
    var createdAt: Date
    
    init(name: String, icon: String, type: TransactionType) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.type = type
        self.createdAt = Date()
    }
    
    var localizedName: String {
        name
    }
}

class CustomCategoryManager: ObservableObject {
    static let shared = CustomCategoryManager()
    
    @Published var customCategories: [CustomCategory] = []
    
    private init() {}
    
    func fetchCategories(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<CustomCategory>(sortBy: [SortDescriptor(\.createdAt)])
        do {
            customCategories = try modelContext.fetch(descriptor)
        } catch {
            print("Fetch custom categories failed: \(error)")
        }
    }
    
    func addCategory(name: String, icon: String, type: TransactionType, modelContext: ModelContext) {
        let category = CustomCategory(name: name, icon: icon, type: type)
        modelContext.insert(category)
        
        do {
            try modelContext.save()
            fetchCategories(modelContext: modelContext)
        } catch {
            print("Save failed: \(error)")
        }
    }
    
    func deleteCategory(_ category: CustomCategory, modelContext: ModelContext) {
        modelContext.delete(category)
        
        do {
            try modelContext.save()
            fetchCategories(modelContext: modelContext)
        } catch {
            print("Delete failed: \(error)")
        }
    }
    
    func getAllCategories(for type: TransactionType) -> [String] {
        let defaultCategories = Category.categories(for: type).map { $0.localizedName }
        let custom = customCategories.filter { $0.type == type }.map { $0.name }
        return defaultCategories + custom
    }
}

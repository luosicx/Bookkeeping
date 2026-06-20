import Foundation
import SwiftData

@Observable
class TagViewModel {
    var modelContext: ModelContext?
    var tags: [Tag] = []
    
    func fetchTags() {
        guard let modelContext = modelContext else { return }
        let descriptor = FetchDescriptor<Tag>(sortBy: [SortDescriptor(\.name)])
        do {
            tags = try modelContext.fetch(descriptor)
        } catch {
            print("Fetch tags failed: \(error)")
        }
    }
    
    func addTag(name: String, color: String) {
        guard let modelContext = modelContext else { return }
        let tag = Tag(name: name, color: color)
        modelContext.insert(tag)
        saveContext()
        fetchTags()
    }
    
    func updateTag(_ tag: Tag, name: String, color: String) {
        tag.name = name
        tag.color = color
        saveContext()
        fetchTags()
    }
    
    func deleteTag(_ tag: Tag) {
        guard let modelContext = modelContext else { return }
        modelContext.delete(tag)
        saveContext()
        fetchTags()
    }
    
    private func saveContext() {
        guard let modelContext = modelContext else { return }
        do {
            try modelContext.save()
        } catch {
            print("Save failed: \(error)")
        }
    }
}

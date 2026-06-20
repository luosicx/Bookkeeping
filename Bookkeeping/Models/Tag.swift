import Foundation
import SwiftData

@Model
class Tag {
    var id: UUID
    var name: String
    var color: String
    var createdAt: Date
    
    init(name: String, color: String = "blue") {
        self.id = UUID()
        self.name = name
        self.color = color
        self.createdAt = Date()
    }
}

struct TagColors {
    static let colors: [(name: String, color: String)] = [
        ("红色", "red"),
        ("橙色", "orange"),
        ("黄色", "yellow"),
        ("绿色", "green"),
        ("蓝色", "blue"),
        ("紫色", "purple"),
        ("粉色", "pink"),
        ("灰色", "gray")
    ]
    
    static func swiftUIColor(named name: String) -> String {
        return name
    }
}

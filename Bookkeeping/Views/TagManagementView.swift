import SwiftUI
import SwiftData

struct TagView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = TagViewModel()
    @State private var showAddTag = false
    @State private var editingTag: Tag?
    
    var body: some View {
        List {
            Section {
                if viewModel.tags.isEmpty {
                    Text(L.noTags)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(viewModel.tags) { tag in
                        HStack {
                            Circle()
                                .fill(tagColor(tag.color))
                                .frame(width: 12, height: 12)
                            Text(tag.name)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editingTag = tag
                            showAddTag = true
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            viewModel.deleteTag(viewModel.tags[index])
                        }
                    }
                }
            } header: {
                Text(L.tags)
            }
        }
        .navigationTitle(L.tagManagement)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddTag = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddTag) {
            AddTagView(viewModel: viewModel, editingTag: editingTag)
        }
        .onAppear {
            viewModel.modelContext = modelContext
            viewModel.fetchTags()
        }
        .onChange(of: showAddTag) { _, newValue in
            if !newValue {
                editingTag = nil
            }
        }
    }
    
    private func tagColor(_ colorName: String) -> Color {
        switch colorName {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "pink": return .pink
        default: return .gray
        }
    }
}

struct AddTagView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: TagViewModel
    var editingTag: Tag?
    
    @State private var name = ""
    @State private var selectedColor = "blue"
    
    var body: some View {
        NavigationStack {
            Form {
                Section(L.tagName) {
                    TextField(L.enterTagName, text: $name)
                }
                
                Section(L.tagColor) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                        ForEach(TagColors.colors, id: \.name) { colorItem in
                            Button(action: { selectedColor = colorItem.color }) {
                                Circle()
                                    .fill(tagColor(colorItem.color))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        selectedColor == colorItem.color ?
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.white)
                                            .font(.caption) : nil
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle(editingTag == nil ? L.addTag : L.editTag)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L.cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L.save) {
                        saveTag()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                if let tag = editingTag {
                    name = tag.name
                    selectedColor = tag.color
                }
            }
        }
    }
    
    private func saveTag() {
        if let tag = editingTag {
            viewModel.updateTag(tag, name: name, color: selectedColor)
        } else {
            viewModel.addTag(name: name, color: selectedColor)
        }
        dismiss()
    }
    
    private func tagColor(_ colorName: String) -> Color {
        switch colorName {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "pink": return .pink
        default: return .gray
        }
    }
}

struct TagPickerView: View {
    @Binding var selectedTags: [Tag]
    let availableTags: [Tag]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L.selectTags)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            FlowLayout(spacing: 8) {
                ForEach(availableTags) { tag in
                    TagChip(
                        tag: tag,
                        isSelected: selectedTags.contains { $0.id == tag.id }
                    ) {
                        toggleTag(tag)
                    }
                }
            }
        }
    }
    
    private func toggleTag(_ tag: Tag) {
        if let index = selectedTags.firstIndex(where: { $0.id == tag.id }) {
            selectedTags.remove(at: index)
        } else {
            selectedTags.append(tag)
        }
    }
}

struct TagChip: View {
    let tag: Tag
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Circle()
                    .fill(tagColor(tag.color))
                    .frame(width: 8, height: 8)
                Text(tag.name)
                    .font(.caption)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? tagColor(tag.color).opacity(0.2) : Color(.systemGray6))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? tagColor(tag.color) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func tagColor(_ colorName: String) -> Color {
        switch colorName {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "pink": return .pink
        default: return .gray
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }
    
    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            totalHeight = currentY + lineHeight
        }
        
        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}

#Preview {
    TagView()
        .modelContainer(for: [Tag.self])
}

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ImportView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingCSVPicker = false
    @State private var showingJSONPicker = false
    @State private var importResult: ImportResult?
    @State private var showingResult = false
    
    var body: some View {
        List {
            Section(header: Text(L.importData)) {
                Button(action: { showingCSVPicker = true }) {
                    HStack {
                        Image(systemName: "arrow.up.doc")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text(L.importFromCSV)
                            Text(L.importCSVHint)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
                
                Button(action: { showingJSONPicker = true }) {
                    HStack {
                        Image(systemName: "arrow.up.doc.fill")
                            .foregroundColor(.orange)
                        VStack(alignment: .leading) {
                            Text(L.importFromJSON)
                            Text(L.importJSONHint)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Section(header: Text(L.importFormat)) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(L.csvFormat)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(L.jsonFormat)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(L.importNote)
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(.vertical, 5)
            }
        }
        .navigationTitle(L.importData)
        .fileImporter(
            isPresented: $showingCSVPicker,
            allowedContentTypes: [
                UTType.commaSeparatedText,
                UTType.plainText
            ],
            allowsMultipleSelection: false
        ) { result in
            handleCSVImport(result: result)
        }
        .fileImporter(
            isPresented: $showingJSONPicker,
            allowedContentTypes: [
                UTType.json
            ],
            allowsMultipleSelection: false
        ) { result in
            handleJSONImport(result: result)
        }
        .alert(L.importSuccess, isPresented: $showingResult) {
            Button(L.confirm) { }
        } message: {
            if let result = importResult {
                Text(result.message)
            }
        }
    }
    
    private func handleCSVImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            do {
                let count = try ImportService.shared.importFromCSV(url: url, modelContext: modelContext)
                importResult = ImportResult(success: true, count: count)
                showingResult = true
            } catch {
                importResult = ImportResult(success: false, count: 0, error: error.localizedDescription)
                showingResult = true
            }
        case .failure(let error):
            importResult = ImportResult(success: false, count: 0, error: error.localizedDescription)
            showingResult = true
        }
    }
    
    private func handleJSONImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            do {
                let count = try ImportService.shared.importFromJSON(url: url, modelContext: modelContext)
                importResult = ImportResult(success: true, count: count)
                showingResult = true
            } catch {
                importResult = ImportResult(success: false, count: 0, error: error.localizedDescription)
                showingResult = true
            }
        case .failure(let error):
            importResult = ImportResult(success: false, count: 0, error: error.localizedDescription)
            showingResult = true
        }
    }
}

struct ImportResult {
    let success: Bool
    let count: Int
    var error: String?
    
    var message: String {
        if success {
            return L.importSuccessMessage(count)
        } else {
            return error ?? L.importFailed
        }
    }
}

#Preview {
    NavigationStack {
        ImportView()
    }
    .modelContainer(for: Transaction.self)
}

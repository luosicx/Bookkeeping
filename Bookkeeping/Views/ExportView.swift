import SwiftUI
import SwiftData

struct ExportView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var exportFiles: [URL] = []
    @State private var selectedFormat: ExportFormat = .csv
    @State private var showingExportAlert = false
    @State private var showingDeleteAlert = false
    @State private var selectedFile: URL?
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    @State private var showingShareSheet = false
    @State private var fileToShare: URL?
    
    var body: some View {
        List {
            Section(header: Text(L.exportData)) {
                Picker(L.exportFormat, selection: $selectedFormat) {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .pickerStyle(.segmented)
                
                Button(action: exportData) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.blue)
                        Text(L.exportTo(selectedFormat.rawValue))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Section(header: Text(L.exportHistory)) {
                if exportFiles.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "doc.text")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            Text(L.noExports)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        Spacer()
                    }
                } else {
                    ForEach(exportFiles, id: \.self) { file in
                        ExportFileRow(file: file)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    selectedFile = file
                                    showingDeleteAlert = true
                                } label: {
                                    Label(L.delete, systemImage: "trash")
                                }
                            }
                            .onTapGesture {
                                fileToShare = file
                                showingShareSheet = true
                            }
                    }
                }
            }
        }
        .navigationTitle(L.exportData)
        .onAppear {
            loadExportFiles()
        }
        .alert(alertTitle, isPresented: $showingExportAlert) {
            Button(L.confirm) { }
        } message: {
            Text(alertMessage)
        }
        .alert(L.confirmDelete, isPresented: $showingDeleteAlert) {
            Button(L.cancel, role: .cancel) { }
            Button(L.delete, role: .destructive) {
                if let file = selectedFile {
                    deleteFile(file)
                }
            }
        } message: {
            Text(L.deleteFileMessage)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let file = fileToShare {
                ShareSheet(activityItems: [file])
            }
        }
    }
    
    private func loadExportFiles() {
        exportFiles = ExportService.shared.getExportFiles()
    }
    
    private func exportData() {
        do {
            let fileURL = try ExportService.shared.exportData(modelContext: modelContext, format: selectedFormat)
            alertTitle = L.exportSuccess
            alertMessage = L.exportMessage(fileURL.lastPathComponent)
            showingExportAlert = true
            loadExportFiles()
        } catch {
            alertTitle = L.exportFailed(error.localizedDescription)
            alertMessage = error.localizedDescription
            showingExportAlert = true
        }
    }
    
    private func deleteFile(_ file: URL) {
        do {
            try ExportService.shared.deleteExportFile(at: file)
            loadExportFiles()
        } catch {
            print("Delete failed: \(error)")
        }
    }
}

struct ExportFileRow: View {
    let file: URL
    
    @State private var creationDate: Date?
    @State private var fileSize: Int64 = 0
    
    var body: some View {
        HStack {
            Image(systemName: file.pathExtension == "csv" ? "doc.text" : (file.pathExtension == "json" ? "doc.badge.gearshape" : "tablecells"))
                .foregroundColor(file.pathExtension == "csv" ? .green : (file.pathExtension == "json" ? .orange : .blue))
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(file.lastPathComponent)
                    .font(.subheadline)
                    .lineLimit(1)
                
                HStack {
                    if let date = creationDate {
                        Text(date, format: .dateTime.year().month().day().hour().minute())
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Text(formatFileSize(fileSize))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Image(systemName: "square.and.arrow.up")
                .foregroundColor(.blue)
                .font(.subheadline)
        }
        .padding(.vertical, 4)
        .onAppear {
            loadFileInfo()
        }
    }
    
    private func loadFileInfo() {
        if let resources = try? file.resourceValues(forKeys: [.creationDateKey, .fileSizeKey]) {
            creationDate = resources.creationDate
            fileSize = Int64(resources.fileSize ?? 0)
        }
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        if bytes < 1024 {
            return "\(bytes) B"
        } else if bytes < 1024 * 1024 {
            return String(format: "%.1f KB", Double(bytes) / 1024)
        } else {
            return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
        }
    }
}

#Preview {
    NavigationStack {
        ExportView()
    }
    .modelContainer(for: Transaction.self)
}

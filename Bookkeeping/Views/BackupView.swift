import SwiftUI
import SwiftData

struct BackupView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var backupFiles: [URL] = []
    @State private var showingExportAlert = false
    @State private var showingImportPicker = false
    @State private var showingDeleteAlert = false
    @State private var selectedBackup: URL?
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    @State private var showingRestoreConfirm = false
    @State private var fileToRestore: URL?
    
    var body: some View {
        List {
            Section {
                Button(action: createBackup) {
                    HStack {
                        Image(systemName: "arrow.up.doc.fill")
                            .foregroundColor(.blue)
                        Text(L.backupData)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
                
                Button(action: { showingImportPicker = true }) {
                    HStack {
                        Image(systemName: "arrow.down.doc.fill")
                            .foregroundColor(.green)
                        Text(L.restoreData)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Section(header: Text(L.backupList)) {
                if backupFiles.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "doc.text")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            Text(L.noBackups)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        Spacer()
                    }
                } else {
                    ForEach(backupFiles, id: \.self) { file in
                        BackupFileRow(file: file)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    selectedBackup = file
                                    showingDeleteAlert = true
                                } label: {
                                    Label(L.delete, systemImage: "trash")
                                }
                            }
                            .onTapGesture {
                                fileToRestore = file
                                showingRestoreConfirm = true
                            }
                    }
                }
            }
        }
        .navigationTitle(L.backupRestore)
        .onAppear {
            loadBackupFiles()
        }
        .alert(alertTitle, isPresented: $showingExportAlert) {
            Button(L.confirm) { }
        } message: {
            Text(alertMessage)
        }
        .alert(L.deleteBackupConfirm, isPresented: $showingDeleteAlert) {
            Button(L.cancel, role: .cancel) { }
            Button(L.delete, role: .destructive) {
                if let file = selectedBackup {
                    deleteBackup(file)
                }
            }
        } message: {
            Text(L.deleteBackupMessage)
        }
        .alert(L.restoreConfirm, isPresented: $showingRestoreConfirm) {
            Button(L.cancel, role: .cancel) { }
            Button(L.confirm) {
                if let file = fileToRestore {
                    restoreBackup(file)
                }
            }
        } message: {
            Text(L.restoreConfirmMessage)
        }
        .fileImporter(
            isPresented: $showingImportPicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
    }
    
    private func loadBackupFiles() {
        backupFiles = BackupService.shared.getBackupFiles()
    }
    
    private func createBackup() {
        do {
            let fileURL = try BackupService.shared.exportData(modelContext: modelContext)
            alertTitle = L.backupSuccess
            alertMessage = L.backupMessage(fileURL.lastPathComponent)
            showingExportAlert = true
            loadBackupFiles()
        } catch {
            alertTitle = L.backupFailed
            alertMessage = L.backupFailed
            showingExportAlert = true
        }
    }
    
    private func restoreBackup(_ file: URL) {
        do {
            let count = try BackupService.shared.importData(from: file, modelContext: modelContext)
            alertTitle = L.restoreSuccess
            alertMessage = L.restoreMessage(count)
            showingExportAlert = true
        } catch {
            alertTitle = L.restoreFailed
            alertMessage = L.restoreFailed
            showingExportAlert = true
        }
    }
    
    private func deleteBackup(_ file: URL) {
        do {
            try BackupService.shared.deleteBackupFile(at: file)
            loadBackupFiles()
        } catch {
            print("Delete failed: \(error)")
        }
    }
    
    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                fileToRestore = url
                showingRestoreConfirm = true
            }
        case .failure(let error):
            alertTitle = L.restoreFailed
            alertMessage = error.localizedDescription
            showingExportAlert = true
        }
    }
}

struct BackupFileRow: View {
    let file: URL
    
    @State private var creationDate: Date?
    @State private var recordCount: Int = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "doc.fill")
                    .foregroundColor(.blue)
                Text(file.lastPathComponent)
                    .font(.subheadline)
                    .lineLimit(1)
            }
            
            HStack {
                if let date = creationDate {
                    Text(date, format: .dateTime.year().month().day().hour().minute())
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text(L.backupRecords(recordCount))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            loadFileInfo()
        }
    }
    
    private func loadFileInfo() {
        if let resources = try? file.resourceValues(forKeys: [.creationDateKey]) {
            creationDate = resources.creationDate
        }
        
        if let data = try? Data(contentsOf: file),
           let backup = try? JSONDecoder().decode(BackupData.self, from: data) {
            recordCount = backup.transactions.count
        }
    }
}

#Preview {
    NavigationStack {
        BackupView()
    }
    .modelContainer(for: Transaction.self)
}

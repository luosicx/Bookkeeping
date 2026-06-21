import SwiftUI

struct ReportShareView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = TransactionViewModel()
    @State private var selectedDate = Date()
    @State private var reportImage: UIImage?
    @State private var showingShareSheet = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                MonthSelector(selectedDate: $selectedDate)
                
                if let image = reportImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                } else {
                    generateButton
                }
                
                if reportImage != nil {
                    shareButtons
                }
            }
            .padding()
        }
        .navigationTitle(L.reportShare)
        .sheet(isPresented: $showingShareSheet) {
            if let image = reportImage {
                ShareSheet(activityItems: [image])
            }
        }
        .onAppear {
            viewModel.modelContext = modelContext
            viewModel.fetchTransactions()
            generateReport()
        }
        .onChange(of: selectedDate) { _, _ in
            generateReport()
        }
    }
    
    private var generateButton: some View {
        Button(action: generateReport) {
            HStack {
                Image(systemName: "doc.richtext")
                Text(L.generateReport)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }
    
    private var shareButtons: some View {
        HStack(spacing: 16) {
            Button(action: shareImage) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text(L.share)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
            Button(action: saveToPhotos) {
                HStack {
                    Image(systemName: "photo")
                    Text(L.saveToPhotos)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
    }
    
    @MainActor
    private func generateReport() {
        reportImage = ReportExporter.exportMonthlyReport(
            date: selectedDate,
            transactions: viewModel.transactions
        )
    }
    
    private func shareImage() {
        showingShareSheet = true
    }
    
    private func saveToPhotos() {
        guard let image = reportImage else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
}

#Preview {
    NavigationStack {
        ReportShareView()
    }
    .modelContainer(for: Transaction.self)
}

import SwiftUI
import PhotosUI

struct ReceiptScanView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var scanner = ReceiptScanner()
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var scannedImageData: Data?
    
    let onResult: (Double?, String?) -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if scanner.isProcessing {
                    ProgressView(L.scanningReceipt)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let amount = scanner.scannedAmount {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text(L.receiptScanned)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        VStack(spacing: 8) {
                            Text(L.estimatedAmount)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("¥\(amount, specifier: "%.2f")")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                        }
                        
                        if let note = scanner.scannedNote {
                            Text(note)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding()
                    
                    Spacer()
                    
                    Button(action: {
                        onResult(scanner.scannedAmount, scanner.scannedNote)
                        dismiss()
                    }) {
                        Text(L.useThisAmount)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text.viewfinder")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text(L.scanReceiptHint)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        
                        Text(L.scanReceiptDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        VStack(spacing: 12) {
                            Button(action: { showCamera = true }) {
                                Label(L.takePhoto, systemImage: "camera.fill")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                            
                            Button(action: { showImagePicker = true }) {
                                Label(L.chooseFromLibrary, systemImage: "photo.on.rectangle")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .foregroundColor(.primary)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 40)
                    }
                    .padding()
                    
                    Spacer()
                }
                
                if let error = scanner.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                }
            }
            .navigationTitle(L.receiptScan)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L.cancel) {
                        dismiss()
                    }
                }
            }
            .photosPicker(isPresented: $showImagePicker, selection: $selectedItem)
            .fullScreenCover(isPresented: $showCamera) {
                CameraView(imageData: $scannedImageData)
            }
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        scannedImageData = data
                    }
                }
            }
            .onChange(of: scannedImageData) { _, newData in
                if let data = newData {
                    scanner.scanReceipt(from: data)
                }
            }
        }
    }
}

struct CameraView: UIViewControllerRepresentable {
    @Binding var imageData: Data?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage,
               let data = image.jpegData(compressionQuality: 0.8) {
                parent.imageData = data
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    ReceiptScanView { amount, note in
        print("Amount: \(amount ?? 0), Note: \(note ?? "")")
    }
}

import Foundation
import Vision
import UIKit

class ReceiptScanner: ObservableObject {
    @Published var scannedAmount: Double?
    @Published var scannedNote: String?
    @Published var isProcessing = false
    @Published var errorMessage: String?
    
    func scanReceipt(from imageData: Data) {
        isProcessing = true
        errorMessage = nil
        
        guard let image = UIImage(data: imageData),
              let cgImage = image.cgImage else {
            errorMessage = "无法处理图片"
            isProcessing = false
            return
        }
        
        let request = VNRecognizeTextRequest { [weak self] request, error in
            self?.handleRecognitionResult(request, error: error)
        }
        
        request.recognitionLanguages = ["zh-Hans", "zh-Hant", "en"]
        request.recognitionLevel = .accurate
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    self?.isProcessing = false
                    self?.errorMessage = "识别失败: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func handleRecognitionResult(_ request: VNRequest, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?.isProcessing = false
            
            if let error = error {
                self?.errorMessage = "识别失败: \(error.localizedDescription)"
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                self?.errorMessage = "未识别到文字"
                return
            }
            
            let text = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
            self?.parseReceiptText(text)
        }
    }
    
    private func parseReceiptText(_ text: String) {
        let lines = text.components(separatedBy: .newlines)
        
        // Try to find amount
        for line in lines.reversed() {
            if let amount = extractAmount(from: line) {
                scannedAmount = amount
                break
            }
        }
        
        // Try to find merchant/store name (usually first few lines)
        let nameLines = lines.prefix(3).filter { !$0.isEmpty }
        scannedNote = nameLines.joined(separator: " ")
    }
    
    private func extractAmount(from text: String) -> Double? {
        let patterns = [
            #"合计[：:]\s*[¥￥]?\s*(\d+\.?\d*)"#,
            #"总计[：:]\s*[¥￥]?\s*(\d+\.?\d*)"#,
            #"实付[：:]\s*[¥￥]?\s*(\d+\.?\d*)"#,
            #"[¥￥]\s*(\d+\.?\d*)"#,
            #"(\d+\.\d{2})"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text) {
                return Double(text[range])
            }
        }
        
        return nil
    }
}

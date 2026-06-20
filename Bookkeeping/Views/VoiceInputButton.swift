import SwiftUI

struct VoiceInputButton: View {
    @Binding var amount: String
    @Binding var category: String?
    @Binding var note: String
    @Binding var transactionType: TransactionType
    
    @State private var isRecording = false
    @State private var speechRecognizer = SpeechRecognizer()
    @State private var parser = VoiceCommandParser()
    @State private var showResult = false
    @State private var recognizedText = ""
    
    var body: some View {
        Button(action: toggleRecording) {
            HStack {
                Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.title2)
                Text(isRecording ? L.stopRecording : L.voiceInput)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isRecording ? Color.red : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(20)
        }
        .onChange(of: speechRecognizer.transcribedText) { _, newValue in
            if !newValue.isEmpty && !isRecording {
                recognizedText = newValue
                parseAndApply(text: newValue)
            }
        }
        .alert(L.voiceResult, isPresented: $showResult) {
            Button(L.confirm) { }
        } message: {
            VStack(alignment: .leading, spacing: 8) {
                Text(L.voiceResultMessage)
                if !recognizedText.isEmpty {
                    Text("「\(recognizedText)」")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private func toggleRecording() {
        if isRecording {
            speechRecognizer.stopRecording()
            isRecording = false
        } else {
            Task {
                await speechRecognizer.startRecording()
                isRecording = true
            }
        }
    }
    
    private func parseAndApply(text: String) {
        let result = parser.parse(text)
        
        if let amountValue = result.amount {
            amount = String(amountValue)
        }
        
        if let categoryId = result.categoryId {
            category = categoryId
        }
        
        if let noteValue = result.note {
            note = noteValue
        }
        
        if let typeValue = result.type {
            transactionType = typeValue
        }
        
        showResult = true
    }
}

#Preview {
    VoiceInputButton(
        amount: .constant(""),
        category: .constant(nil),
        note: .constant(""),
        transactionType: .constant(.expense)
    )
}

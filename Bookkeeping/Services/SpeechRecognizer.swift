import Foundation
import Speech
import AVFoundation

@Observable
class SpeechRecognizer {
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    var isRecording = false
    var transcribedText = ""
    var errorMessage: String?
    
    func startRecording() async {
        guard let recognizer = recognizer, recognizer.isAvailable else {
            errorMessage = "语音识别不可用"
            return
        }
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else { return }
            
            recognitionRequest.shouldReportPartialResults = true
            
            recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }
                
                if let result = result {
                    self.transcribedText = result.bestTranscription.formattedString
                }
                
                if error != nil || (result?.isFinal ?? false) {
                    self.stopRecording()
                }
            }
            
            let inputBus = AVAudioNodeBus(0)
            inputNode.installTap(onBus: inputBus, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                self?.recognitionRequest?.append(buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            
            isRecording = true
            errorMessage = nil
            
        } catch {
            errorMessage = "启动语音识别失败: \(error.localizedDescription)"
            isRecording = false
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        isRecording = false
        recognitionRequest = nil
        recognitionTask = nil
    }
}

class VoiceCommandParser {
    struct ParseResult {
        let amount: Double?
        let categoryId: String?
        let note: String?
        let type: TransactionType?
    }
    
    private let expenseCategoryMap: [String: (id: String, keywords: [String])] = [
        "餐饮": ("food", ["午餐", "晚餐", "早餐", "吃饭", "外卖", "餐厅", "咖啡", "奶茶", "小吃", "火锅", "烧烤", "米饭", "面条", "快餐", "零食", "饮料"]),
        "交通": ("transport", ["打车", "地铁", "公交", "加油", "停车", "高铁", "飞机", "出租", "滴滴", "骑车", "过路费"]),
        "购物": ("shopping", ["买", "购物", "淘宝", "京东", "超市", "商场", "网购", "衣服", "鞋子", "日用品"]),
        "娱乐": ("entertainment", ["电影", "游戏", "KTV", "旅游", "唱歌", "运动", "健身", "门票", "景点"]),
        "住房": ("housing", ["房租", "水电", "物业", "维修", "家具", "装修", "燃气", "宽带"]),
        "医疗": ("medical", ["看病", "药", "医院", "体检", "牙医", "挂号", "住院"]),
        "教育": ("education", ["课程", "培训", "书", "学费", "学习", "网课", "考试"]),
    ]
    
    private let incomeCategoryMap: [String: (id: String, keywords: [String])] = [
        "工资": ("salary", ["工资", "薪资", "薪水", "发工资", "到手"]),
        "奖金": ("bonus", ["奖金", "年终奖", "绩效", "提成", "分红"]),
        "投资": ("investment", ["投资", "理财", "利息", "股息", "收益"]),
    ]
    
    private let incomeIndicators = ["收到", "到账", "入账", "进账", "赚到", "工资发了"]
    private let expenseIndicators = ["花了", "支出", "消费", "付了", "花了钱", "开销"]
    
    func parse(_ input: String) -> ParseResult {
        let amount = extractAmount(from: input)
        let type = inferType(from: input)
        let categoryId = inferCategory(from: input, type: type)
        let note = extractNote(from: input)
        
        return ParseResult(amount: amount, categoryId: categoryId, note: note, type: type)
    }
    
    private func extractAmount(from text: String) -> Double? {
        let patterns = [
            #"(\d+\.?\d*)\s*[元块圆]"#,
            #"(\d+\.?\d*)"#
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
    
    private func inferType(from text: String) -> TransactionType {
        let lowercased = text.lowercased()
        
        for indicator in incomeIndicators where lowercased.contains(indicator) {
            return .income
        }
        
        for indicator in expenseIndicators where lowercased.contains(indicator) {
            return .expense
        }
        
        for (_, info) in incomeCategoryMap {
            for keyword in info.keywords where lowercased.contains(keyword) {
                return .income
            }
        }
        
        return .expense
    }
    
    private func inferCategory(from text: String, type: TransactionType) -> String? {
        let lowercased = text.lowercased()
        let categoryMap = type == .income ? incomeCategoryMap : expenseCategoryMap
        
        for (_, info) in categoryMap {
            for keyword in info.keywords where lowercased.contains(keyword) {
                return info.id
            }
        }
        
        return nil
    }
    
    private func extractNote(from text: String) -> String? {
        let amountPattern = #"(\d+\.?\d*)\s*[元块圆]?"#
        let cleaned = text.replacingOccurrences(of: amountPattern, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleaned.isEmpty ? nil : cleaned
    }
}

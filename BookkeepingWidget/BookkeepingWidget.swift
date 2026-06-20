import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), income: 15000, expense: 9500, balance: 5500)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let data = getWidgetData()
        let entry = SimpleEntry(date: Date(), income: data.income, expense: data.expense, balance: data.balance)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let data = getWidgetData()
        let entry = SimpleEntry(date: Date(), income: data.income, expense: data.expense, balance: data.balance)
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(3600)))
        completion(timeline)
    }
    
    private func getWidgetData() -> (income: Double, expense: Double, balance: Double) {
        // 尝试从共享 UserDefaults 读取
        if let defaults = UserDefaults(suiteName: "group.com.bookkeeping.app") {
            let income = defaults.double(forKey: "widget_income")
            let expense = defaults.double(forKey: "widget_expense")
            let balance = defaults.double(forKey: "widget_balance")
            
            // 如果有数据则返回
            if income > 0 || expense > 0 {
                return (income, expense, balance)
            }
        }
        
        // 默认测试数据（用于模拟器调试）
        return (15000, 9500, 5500)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let income: Double
    let expense: Double
    let balance: Double
}

struct BookkeepingWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct SmallWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                Text("本月概览")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
            }
            
            Spacer()
            
            Text("¥\(entry.balance, specifier: "%.0f")")
                .font(.system(size: 28, weight: .bold))
            
            Text("结余")
                .font(.caption2)
                .foregroundColor(.gray)
            
            HStack(spacing: 12) {
                VStack(alignment: .leading) {
                    Text("收")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text("¥\(entry.income, specifier: "%.0f")")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                VStack(alignment: .leading) {
                    Text("支")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text("¥\(entry.expense, specifier: "%.0f")")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
    }
}

struct MediumWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.blue)
                    Text("本月概览")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Text("¥\(entry.balance, specifier: "%.0f")")
                    .font(.system(size: 32, weight: .bold))
                
                Text("结余")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 12) {
                VStack(alignment: .trailing) {
                    Text("收入")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text("¥\(entry.income, specifier: "%.0f")")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
                
                VStack(alignment: .trailing) {
                    Text("支出")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text("¥\(entry.expense, specifier: "%.0f")")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
    }
}

@main
struct BookkeepingWidget: Widget {
    let kind: String = "BookkeepingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                BookkeepingWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                BookkeepingWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("记账本")
        .description("查看本月收支概览")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    BookkeepingWidget()
} timeline: {
    SimpleEntry(date: .now, income: 15000, expense: 9500, balance: 5500)
    SimpleEntry(date: .now, income: 20000, expense: 12000, balance: 8000)
}

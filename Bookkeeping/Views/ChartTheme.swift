import SwiftUI

struct ChartTheme {
    static let gradientColors: [Color] = [
        .blue, .cyan, .teal, .green,
        .orange, .red, .pink, .purple
    ]
    
    static let categoryColors: [String: Color] = [
        "餐饮": .orange,
        "交通": .blue,
        "购物": .pink,
        "娱乐": .purple,
        "住房": .teal,
        "医疗": .red,
        "教育": .green,
        "其他": .gray,
        "工资": .green,
        "奖金": .yellow,
        "投资": .blue,
    ]
    
    static func color(for index: Int) -> Color {
        gradientColors[index % gradientColors.count]
    }
    
    static func categoryGradient(_ category: String) -> LinearGradient {
        let baseColor = categoryColors[category] ?? .blue
        return LinearGradient(
            colors: [baseColor.opacity(0.9), baseColor.opacity(0.5)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static func incomeGradient() -> LinearGradient {
        LinearGradient(
            colors: [.green.opacity(0.8), .green.opacity(0.4)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static func expenseGradient() -> LinearGradient {
        LinearGradient(
            colors: [.red.opacity(0.8), .red.opacity(0.4)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static func balanceGradient() -> LinearGradient {
        LinearGradient(
            colors: [.blue.opacity(0.8), .cyan.opacity(0.5)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    struct CardStyle: ViewModifier {
        func body(content: Content) -> some View {
            content
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(15)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        }
    }
    
    struct GradientCardStyle: ViewModifier {
        let colors: [Color]
        
        func body(content: Content) -> some View {
            content
                .padding()
                .background(
                    LinearGradient(
                        colors: colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(15)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        }
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(ChartTheme.CardStyle())
    }
    
    func gradientCardStyle(colors: [Color] = [.blue.opacity(0.1), .cyan.opacity(0.05)]) -> some View {
        modifier(ChartTheme.GradientCardStyle(colors: colors))
    }
}

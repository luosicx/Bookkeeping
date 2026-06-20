import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label(L.tabHome, systemImage: "house.fill")
                }
                .tag(0)
            
            StatisticsView()
                .tabItem {
                    Label(L.tabStatistics, systemImage: "chart.bar.fill")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Label(L.tabSettings, systemImage: "gearshape.fill")
                }
                .tag(2)
        }
        .preferredColorScheme(themeManager.colorScheme)
    }
}

#Preview {
    MainTabView()
}

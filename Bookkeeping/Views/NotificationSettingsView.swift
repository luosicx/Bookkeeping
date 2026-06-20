import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @State private var isNotificationEnabled = false
    @State private var pendingNotifications: [UNNotificationRequest] = []
    @State private var showingPermissionAlert = false
    
    var body: some View {
        List {
            Section(header: Text(L.notificationPermission)) {
                HStack {
                    Image(systemName: isNotificationEnabled ? "bell.fill" : "bell.slash")
                        .foregroundColor(isNotificationEnabled ? .green : .red)
                    
                    Text(isNotificationEnabled ? L.notificationsEnabled : L.notificationsDisabled)
                    
                    Spacer()
                    
                    if !isNotificationEnabled {
                        Button(L.enable) {
                            requestPermission()
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            
            Section(header: Text(L.notificationTypes)) {
                NotificationTypeRow(
                    icon: "exclamationmark.triangle.fill",
                    title: L.budgetAlert,
                    description: L.budgetAlertDesc,
                    isEnabled: isNotificationEnabled
                )
                
                NotificationTypeRow(
                    icon: "bell.badge.fill",
                    title: L.billReminder,
                    description: L.billReminderDesc,
                    isEnabled: isNotificationEnabled
                )
                
                NotificationTypeRow(
                    icon: "target",
                    title: L.savingsGoalReminder,
                    description: L.savingsGoalReminderDesc,
                    isEnabled: isNotificationEnabled
                )
            }
            
            Section(header: Text(L.pendingNotifications)) {
                if pendingNotifications.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "bell.slash")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            Text(L.noPendingNotifications)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        Spacer()
                    }
                } else {
                    ForEach(pendingNotifications, id: \.identifier) { notification in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(notification.content.title)
                                .font(.headline)
                            Text(notification.content.body)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .lineLimit(2)
                        }
                    }
                }
            }
            
            Section {
                Button(action: cancelAllNotifications) {
                    HStack {
                        Image(systemName: "xmark.circle")
                            .foregroundColor(.red)
                        Text(L.cancelAllNotifications)
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .navigationTitle(L.notificationSettings)
        .onAppear {
            checkPermissionStatus()
            loadPendingNotifications()
        }
        .alert(L.notificationPermission, isPresented: $showingPermissionAlert) {
            Button(L.openSettings) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button(L.cancel, role: .cancel) { }
        } message: {
            Text(L.notificationPermissionMessage)
        }
    }
    
    private func requestPermission() {
        NotificationService.shared.requestPermission { granted in
            isNotificationEnabled = granted
            if !granted {
                showingPermissionAlert = true
            }
        }
    }
    
    private func checkPermissionStatus() {
        NotificationService.shared.checkPermission { enabled in
            isNotificationEnabled = enabled
        }
    }
    
    private func loadPendingNotifications() {
        NotificationService.shared.getPendingReminders { notifications in
            pendingNotifications = notifications
        }
    }
    
    private func cancelAllNotifications() {
        NotificationService.shared.cancelAllReminders()
        BudgetAlertManager.shared.cancelAllBudgetAlerts()
        pendingNotifications = []
    }
}

struct NotificationTypeRow: View {
    let icon: String
    let title: String
    let description: String
    let isEnabled: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(isEnabled ? .blue : .gray)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .opacity(isEnabled ? 1.0 : 0.5)
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
}

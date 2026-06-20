import Foundation
import UserNotifications

class NotificationService {
    static let shared = NotificationService()
    
    private init() {}
    
    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    func checkPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus == .authorized)
            }
        }
    }
    
    func scheduleBillReminder(_ reminder: BillReminder) {
        let content = UNMutableNotificationContent()
        content.title = L.billReminder
        content.body = reminder.amount != nil 
            ? L.reminderWithAmount(reminder.title, reminder.amount!)
            : L.reminderWithoutAmount(reminder.title)
        content.sound = .default
        content.badge = 1
        
        let calendar = Calendar.current
        let triggerDate = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.dueDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(identifier: reminder.id.uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
        
        scheduleReminderBefore(reminder, daysBefore: 1)
        scheduleReminderBefore(reminder, daysBefore: 3)
    }
    
    private func scheduleReminderBefore(_ reminder: BillReminder, daysBefore: Int) {
        let content = UNMutableNotificationContent()
        content.title = L.upcomingBill
        content.body = L.billDueSoon(reminder.title, daysBefore)
        content.sound = .default
        
        guard let triggerDate = Calendar.current.date(byAdding: .day, value: -daysBefore, to: reminder.dueDate) else { return }
        
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let identifier = "\(reminder.id.uuidString)-\(daysBefore)days"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelReminder(_ reminder: BillReminder) {
        var identifiers = [reminder.id.uuidString]
        identifiers.append("\(reminder.id.uuidString)-1days")
        identifiers.append("\(reminder.id.uuidString)-3days")
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    func cancelAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func getPendingReminders(completion: @escaping ([UNNotificationRequest]) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                completion(requests)
            }
        }
    }
}

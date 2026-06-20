import Foundation
import SwiftData
import SwiftUI

@Observable
class BillReminderViewModel {
    var modelContext: ModelContext?
    var reminders: [BillReminder] = []
    
    var upcomingReminders: [BillReminder] {
        reminders.filter { !$0.isPaid && $0.isEnabled }
            .sorted { $0.dueDate < $1.dueDate }
    }
    
    var overdueReminders: [BillReminder] {
        reminders.filter { $0.isOverdue }
    }
    
    var paidReminders: [BillReminder] {
        reminders.filter { $0.isPaid }
    }
    
    func fetchReminders() {
        guard let modelContext = modelContext else { return }
        let descriptor = FetchDescriptor<BillReminder>(sortBy: [SortDescriptor(\.dueDate)])
        do {
            reminders = try modelContext.fetch(descriptor)
        } catch {
            print("Fetch reminders failed: \(error)")
        }
    }
    
    func addReminder(title: String, amount: Double?, dueDate: Date, repeatFrequency: Frequency, note: String) {
        guard let modelContext = modelContext else { return }
        let reminder = BillReminder(title: title, amount: amount, dueDate: dueDate, repeatFrequency: repeatFrequency, note: note)
        modelContext.insert(reminder)
        saveContext()
        
        if reminder.isEnabled {
            NotificationService.shared.scheduleBillReminder(reminder)
        }
        
        fetchReminders()
    }
    
    func updateReminder(_ reminder: BillReminder, title: String? = nil, amount: Double? = nil, dueDate: Date? = nil, repeatFrequency: Frequency? = nil, note: String? = nil, isEnabled: Bool? = nil) {
        if let title = title { reminder.title = title }
        if let amount = amount { reminder.amount = amount }
        if let dueDate = dueDate { reminder.dueDate = dueDate }
        if let repeatFrequency = repeatFrequency { reminder.repeatFrequency = repeatFrequency }
        if let note = note { reminder.note = note }
        if let isEnabled = isEnabled { reminder.isEnabled = isEnabled }
        
        saveContext()
        
        if reminder.isEnabled {
            NotificationService.shared.scheduleBillReminder(reminder)
        } else {
            NotificationService.shared.cancelReminder(reminder)
        }
        
        fetchReminders()
    }
    
    func markAsPaid(_ reminder: BillReminder) {
        reminder.isPaid = true
        saveContext()
        NotificationService.shared.cancelReminder(reminder)
        fetchReminders()
    }
    
    func markAsUnpaid(_ reminder: BillReminder) {
        reminder.isPaid = false
        saveContext()
        if reminder.isEnabled {
            NotificationService.shared.scheduleBillReminder(reminder)
        }
        fetchReminders()
    }
    
    func deleteReminder(_ reminder: BillReminder) {
        guard let modelContext = modelContext else { return }
        NotificationService.shared.cancelReminder(reminder)
        modelContext.delete(reminder)
        saveContext()
        fetchReminders()
    }
    
    func toggleEnabled(_ reminder: BillReminder) {
        reminder.isEnabled.toggle()
        saveContext()
        
        if reminder.isEnabled {
            NotificationService.shared.scheduleBillReminder(reminder)
        } else {
            NotificationService.shared.cancelReminder(reminder)
        }
        
        fetchReminders()
    }
    
    private func saveContext() {
        guard let modelContext = modelContext else { return }
        do {
            try modelContext.save()
        } catch {
            print("Save failed: \(error)")
        }
    }
}

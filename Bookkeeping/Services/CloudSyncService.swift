import Foundation
import CloudKit

class CloudSyncService {
    static let shared = CloudSyncService()
    
    private let container: CKContainer
    private let database: CKDatabase
    
    private init() {
        container = CKContainer.default()
        database = container.privateCloudDatabase
    }
    
    func checkAccountStatus(completion: @escaping (Bool, Error?) -> Void) {
        container.accountStatus { status, error in
            DispatchQueue.main.async {
                switch status {
                case .available:
                    completion(true, nil)
                default:
                    completion(false, error)
                }
            }
        }
    }
    
    func saveRecord(recordType: String, fields: [String: Any], completion: @escaping (Bool, Error?) -> Void) {
        let record = CKRecord(recordType: recordType)
        
        for (key, value) in fields {
            if let stringValue = value as? String {
                record[key] = stringValue
            } else if let intValue = value as? Int {
                record[key] = intValue as NSNumber
            } else if let doubleValue = value as? Double {
                record[key] = doubleValue as NSNumber
            } else if let dateValue = value as? Date {
                record[key] = dateValue
            } else if let boolValue = value as? Bool {
                record[key] = boolValue as NSNumber
            }
        }
        
        database.save(record) { _, error in
            DispatchQueue.main.async {
                completion(error == nil, error)
            }
        }
    }
    
    func fetchRecords(recordType: String, completion: @escaping ([CKRecord]?, Error?) -> Void) {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: recordType, predicate: predicate)
        
        database.fetch(withQuery: query) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let result):
                    completion(result.matchResults.compactMap { try? $0.1.get() }, nil)
                case .failure(let error):
                    completion(nil, error)
                }
            }
        }
    }
    
    func deleteRecord(recordID: CKRecord.ID, completion: @escaping (Bool, Error?) -> Void) {
        database.delete(withRecordID: recordID) { _, error in
            DispatchQueue.main.async {
                completion(error == nil, error)
            }
        }
    }
}

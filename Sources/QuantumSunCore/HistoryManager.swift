import Foundation

public struct DailyTraffic: Codable {
    public var date: Date
    public var uploadBytes: UInt64
    public var downloadBytes: UInt64
    
    public var totalBytes: UInt64 {
        return uploadBytes + downloadBytes
    }
}

public class HistoryManager {
    public static let shared = HistoryManager()
    
    private let storageKey = "QuantumSun_DailyTraffic"
    private var currentTraffic: DailyTraffic
    
    private init() {
        // Privacy Check
        guard PrivacyManager.shared.allowHistoryPersistence else {
            self.currentTraffic = DailyTraffic(date: Date(), uploadBytes: 0, downloadBytes: 0)
            return
        }
        
        // Load existing or start fresh
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let traffic = try? JSONDecoder().decode(DailyTraffic.self, from: data),
           Calendar.current.isDateInToday(traffic.date) {
            self.currentTraffic = traffic
        } else {
            self.currentTraffic = DailyTraffic(date: Date(), uploadBytes: 0, downloadBytes: 0)
        }
    }
    
    public func addTraffic(upload: UInt64, download: UInt64) {
        // Check if day changed
        if !Calendar.current.isDateInToday(currentTraffic.date) {
            reset()
        }
        
        currentTraffic.uploadBytes += upload
        currentTraffic.downloadBytes += download
        
        if PrivacyManager.shared.allowHistoryPersistence {
            save()
        }
    }
    
    public func getTodayTraffic() -> DailyTraffic {
        if !Calendar.current.isDateInToday(currentTraffic.date) {
            reset()
        }
        return currentTraffic
    }
    
    public func reset() {
        currentTraffic = DailyTraffic(date: Date(), uploadBytes: 0, downloadBytes: 0)
        save()
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(currentTraffic) {
             UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}

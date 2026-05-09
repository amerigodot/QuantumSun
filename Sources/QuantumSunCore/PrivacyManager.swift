import Foundation

public class PrivacyManager {
    public static let shared = PrivacyManager()
    
    private let ipKey = "QuantumSun_AllowIPFetching"
    private let historyKey = "QuantumSun_AllowHistoryPersistence"
    
    // Default to strict privacy (false) or user preference? 
    // Plan says "Default to Privacy First". So false initially.
    
    public var allowIPFetching: Bool {
        get { UserDefaults.standard.bool(forKey: ipKey) }
        set { UserDefaults.standard.set(newValue, forKey: ipKey) }
    }
    
    public var allowHistoryPersistence: Bool {
        get { UserDefaults.standard.bool(forKey: historyKey) }
        set { UserDefaults.standard.set(newValue, forKey: historyKey) }
    }
    
    private init() {
        // Register defaults if needed, but bool defaults to false which matches "Privacy First"
    }
}

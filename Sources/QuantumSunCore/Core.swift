import Foundation

public struct IPResponse: Codable {
    public let ip: String
    public let country_code: String
}

public enum RefreshRate: Double, CaseIterable {
    // Implementing hertz_value = hertz_value * 0.1
    // Previous: 1.0, 2.0, 5.0
    // New: 0.1, 0.2, 0.5
    case relaxed = 0.1
    case standard = 2
    case reactive = 5
    case dynamic = 0 // Special case
    
    public var label: String {
        switch self {
        case .relaxed: return "Relaxed (0.1 Hz)"
        case .standard: return "Standard (2 Hz)"
        case .reactive: return "Reactive (5 Hz)"
        case .dynamic: return "Dynamic (Auto)"
        }
    }
}

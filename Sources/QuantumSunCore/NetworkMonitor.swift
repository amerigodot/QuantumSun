import Foundation
import Darwin

public class NetworkMonitor {
    private var previousUploadBytes: UInt64 = 0
    private var previousDownloadBytes: UInt64 = 0
    private var lastCheckTime: TimeInterval = 0
    
    public init() {}
    
    public func getTrafficStatistics() -> (speedUp: Double, speedDown: Double, deltaUp: UInt64, deltaDown: UInt64) {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return (0, 0, 0, 0) }
        
        var totalUpload: UInt64 = 0
        var totalDownload: UInt64 = 0
        
        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }
            guard let interface = ptr?.pointee else { continue }
            
            let name = String(cString: interface.ifa_name)
            // Exclude loopback
            if name.hasPrefix("lo") { continue }
            
            // Filter loopback and non-active interfaces if needed
            if interface.ifa_addr.pointee.sa_family == UInt8(AF_LINK) {
                if let data = interface.ifa_data?.assumingMemoryBound(to: if_data.self) {
                     totalUpload += UInt64(data.pointee.ifi_obytes)
                     totalDownload += UInt64(data.pointee.ifi_ibytes)
                }
            }
        }
        freeifaddrs(ifaddr)
        
        let now = Date().timeIntervalSince1970
        var uploadSpeed: Double = 0
        var downloadSpeed: Double = 0
        var deltaUp: UInt64 = 0
        var deltaDown: UInt64 = 0
        
        if lastCheckTime > 0 {
            let timeDelta = now - lastCheckTime
            if timeDelta > 0 {
                // Handle potential overflow or reset (reboot)
                if totalUpload >= previousUploadBytes {
                    deltaUp = totalUpload - previousUploadBytes
                }
                if totalDownload >= previousDownloadBytes {
                    deltaDown = totalDownload - previousDownloadBytes
                }
                
                uploadSpeed = Double(deltaUp) / timeDelta
                downloadSpeed = Double(deltaDown) / timeDelta
            }
        }
        
        previousUploadBytes = totalUpload
        previousDownloadBytes = totalDownload
        lastCheckTime = now
        
        return (uploadSpeed, downloadSpeed, deltaUp, deltaDown)
    }
    
    public func formatBytes(_ bytes: Double) -> String {
        let count = bytes
        let formatted: String
        if count < 1024 {
            formatted = String(format: "%4.0f B/s", count)
        } else if count < 1024 * 1024 {
            formatted = String(format: "%4.1f KB/s", count / 1024)
        } else {
            formatted = String(format: "%4.1f MB/s", count / (1024 * 1024))
        }
        let targetLength = 10
        let padding = String(repeating: "\u{2007}", count: max(0, targetLength - formatted.count))
        return padding + formatted
    }
    
    public func formatTotalBytes(_ bytes: UInt64) -> String {
        let count = Double(bytes)
        if count < 1024 {
            return String(format: "%.0f B", count)
        } else if count < 1024 * 1024 {
            return String(format: "%.1f KB", count / 1024)
        } else if count < 1024 * 1024 * 1024 {
            return String(format: "%.1f MB", count / (1024 * 1024))
        } else {
            return String(format: "%.1f GB", count / (1024 * 1024 * 1024))
        }
    }
}
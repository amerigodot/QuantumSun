import Foundation

public class IPService {
    public static let shared = IPService()
    
    // Callbacks
    public typealias IPResult = (ip: String, flag: String)
    
    private init() {}
    
    public func fetchIP(completion: @escaping (IPResult) -> Void) {
        // 1. Privacy Check
        guard PrivacyManager.shared.allowIPFetching else {
            completion(("Hidden", ""))
            return
        }
        
        // Step 1: Force IPv4 via ipify
        guard let ipv4Url = URL(string: "https://api.ipify.org") else { return }
        
        let taskIPv4 = URLSession.shared.dataTask(with: ipv4Url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            // Check for IPv4 fetch error
            guard let data = data, error == nil, let ipv4 = String(data: data, encoding: .utf8) else {
                DispatchQueue.main.async { completion(("Error", "")) }
                return
            }
            
            // Step 2: Get Location for this IPv4
            guard let locUrl = URL(string: "https://ipapi.co/\(ipv4)/json/") else { return }
            
            let taskLoc = URLSession.shared.dataTask(with: locUrl) { [weak self] data, response, error in
                guard let self = self else { return }
                guard let data = data, error == nil else {
                    DispatchQueue.main.async { completion((ipv4, "")) } // Return IP without flag
                    return
                }
                
                do {
                    let result = try JSONDecoder().decode(IPResponse.self, from: data)
                    let flag = self.flag(from: result.country_code)
                    
                    DispatchQueue.main.async { completion((ipv4, flag)) }
                } catch {
                    DispatchQueue.main.async { completion((ipv4, "")) }
                }
            }
            taskLoc.resume()
        }
        taskIPv4.resume()
    }
    
    private func flag(from country: String) -> String {
        let base: UInt32 = 127397
        var s = ""
        for v in country.unicodeScalars {
            s.unicodeScalars.append(UnicodeScalar(base + v.value)!)
        }
        return s
    }
}

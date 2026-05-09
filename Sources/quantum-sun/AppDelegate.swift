import Cocoa
import QuantumSunCore

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem!
    var ipTimer: Timer?
    var refreshTimer: Timer?
    
    var currentRefreshRate: RefreshRate = .dynamic
    var previousInterval: TimeInterval = 1.0 // For smoothing
    
    let networkMonitor = NetworkMonitor()
    let historyManager = HistoryManager.shared
    let privacyManager = PrivacyManager.shared
    
    // UI Components
    var historyView: HistoryView?
    
    var currentIP: String = "Loading..."
    var currentFlag: String = ""

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        setupMenu()
        startTimer()
        
        // Initial Fetch (will respect privacy default)
        fetchIP()
        
        // IP Refresh: 60s
        ipTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.fetchIP()
        }
    }

    func setupMenu() {
        let menu = NSMenu()
        
        // History View Item
        let historyItem = NSMenuItem()
        historyItem.view = layoutHistoryView()
        menu.addItem(historyItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Privacy Submenu
        let privacyItem = NSMenuItem(title: "Privacy Settings", action: nil, keyEquivalent: "")
        let privacyMenu = NSMenu()
        
        let ipToggle = NSMenuItem(title: "Allow IP Fetching", action: #selector(togglePrivacyIP(_:)), keyEquivalent: "")
        ipToggle.target = self
        ipToggle.state = privacyManager.allowIPFetching ? .on : .off
        privacyMenu.addItem(ipToggle)
        
        let histToggle = NSMenuItem(title: "Allow History Save", action: #selector(togglePrivacyHistory(_:)), keyEquivalent: "")
        histToggle.target = self
        histToggle.state = privacyManager.allowHistoryPersistence ? .on : .off
        privacyMenu.addItem(histToggle)
        
        privacyItem.submenu = privacyMenu
        menu.addItem(privacyItem)

        // Refresh Rate Submenu
        let rateItem = NSMenuItem(title: "Refresh Rate", action: nil, keyEquivalent: "")
        let rateMenu = NSMenu()
        for rate in RefreshRate.allCases {
            let item = NSMenuItem(title: rate.label, action: #selector(setRefreshRate(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = rate
            item.state = (rate == currentRefreshRate) ? .on : .off
            rateMenu.addItem(item)
        }
        rateItem.submenu = rateMenu
        menu.addItem(rateItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let refreshItem = NSMenuItem(title: "Refresh Now", action: #selector(refreshClicked), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)
        
        let copyItem = NSMenuItem(title: "Copy IP", action: #selector(copyClicked), keyEquivalent: "c")
        copyItem.target = self
        menu.addItem(copyItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitClicked), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusBarItem.menu = menu
    }
    
    // MARK: - Privacy Actions
    
    @objc func togglePrivacyIP(_ sender: NSMenuItem) {
        let newState = !privacyManager.allowIPFetching
        privacyManager.allowIPFetching = newState
        sender.state = newState ? .on : .off
        
        if newState {
            fetchIP()
        } else {
            currentIP = "Hidden"
            currentFlag = ""
            updateDisplay()
        }
    }
    
    @objc func togglePrivacyHistory(_ sender: NSMenuItem) {
        let newState = !privacyManager.allowHistoryPersistence
        privacyManager.allowHistoryPersistence = newState
        sender.state = newState ? .on : .off
        // No immediate action needed, HistoryManager checks this flag on write
    }
    
    func layoutHistoryView() -> HistoryView {
        let frame = NSRect(x: 0, y: 0, width: 320, height: 100) 
        let view = HistoryView(frame: frame)
        view.onReset = { [weak self] in
            self?.historyManager.reset()
            self?.updateHistoryDisplay()
        }
        self.historyView = view
        updateHistoryDisplay()
        return view
    }
    
    @objc func setRefreshRate(_ sender: NSMenuItem) {
        guard let rate = sender.representedObject as? RefreshRate else { return }
        currentRefreshRate = rate
        
        if let menu = sender.menu {
            for item in menu.items {
                item.state = (item == sender) ? .on : .off
            }
        }
        startTimer()
    }
    
    func startTimer() {
        refreshTimer?.invalidate()
        
        switch currentRefreshRate {
        case .dynamic:
            refreshTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateDisplay), userInfo: nil, repeats: false)
        default:
            let interval = 1.0 / currentRefreshRate.rawValue
            refreshTimer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(updateDisplay), userInfo: nil, repeats: true)
        }
        
        if let timer = refreshTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    @objc func updateDisplay() {
        // Collect new stats
        let (speedUp, speedDown, deltaUp, deltaDown) = networkMonitor.getTrafficStatistics()
        let maxSpeed = max(speedUp, speedDown)
        
        // 1. Update Menu Bar
        let speedText = networkMonitor.formatBytes(maxSpeed)
        let arrow = speedDown >= speedUp ? "↓" : "↑"
        
        let mutAttrString = NSMutableAttributedString()
        let trafficAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular),
            .foregroundColor: NSColor.white
        ]
        mutAttrString.append(NSAttributedString(string: "\(speedText) \(arrow)", attributes: trafficAttrs))
        
        if !currentIP.isEmpty {
            var ipText = ""
            if mutAttrString.length > 0 { ipText += " " }
            if !currentFlag.isEmpty { ipText += "\(currentFlag)" }
            ipText += "\(currentIP)"
            
            let ipAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular),
                .kern: -0.75,
                .foregroundColor: NSColor.white
            ]
            mutAttrString.append(NSAttributedString(string: ipText, attributes: ipAttrs))
        }
        
        if let button = statusBarItem.button {
            button.attributedTitle = mutAttrString
        }
        
        // 2. Persist History (checks privacy internally)
        if deltaUp > 0 || deltaDown > 0 {
            historyManager.addTraffic(upload: deltaUp, download: deltaDown)
            updateHistoryDisplay()
        }
        
        // Dynamic Scheduling
        if currentRefreshRate == .dynamic {
            // Linear Interval with Smoothing
            let maxSpeedThreshold: Double = 10 * 1024 * 1024 // 10 MB/s
            let maxInterval: TimeInterval = 10.0 // Idle
            // Cap the minimum interval to 1.0s to reduce CPU load from rapid updates
            let minInterval: TimeInterval = 1.0 
            
            // Calculate ratio (0.0 to 1.0)
            let ratio = min(maxSpeed / maxSpeedThreshold, 1.0)
            
            // Target Interval
            let targetInterval = maxInterval - (ratio * (maxInterval - minInterval))
            
            // Apply Smoothing (Weighted Average)
            var smoothed = (previousInterval * 0.7) + (targetInterval * 0.3)
            
            // BRAKE LOGIC: If target is idle (slow) but current is fast, apply stronger braking
            if targetInterval > 5.0 && smoothed < 2.0 {
                 smoothed = (previousInterval * 0.5) + (targetInterval * 0.5)
            }
            
            previousInterval = smoothed
            
            refreshTimer = Timer.scheduledTimer(timeInterval: smoothed, target: self, selector: #selector(updateDisplay), userInfo: nil, repeats: false)
            RunLoop.current.add(refreshTimer!, forMode: .common)
        }
    }
    
    func updateHistoryDisplay() {
        // Only update UI if the window is actually visible to save resources
        guard let view = historyView, let window = view.window, window.isVisible else { return }
        
        // Dispatch to background for data fetch if needed, but HistoryManager is in-memory mostly
        let today = historyManager.getTodayTraffic()
        
        let downStr = networkMonitor.formatTotalBytes(today.downloadBytes)
        let upStr = networkMonitor.formatTotalBytes(today.uploadBytes)
        let totalStr = networkMonitor.formatTotalBytes(today.totalBytes)
        
        view.update(download: downStr, upload: upStr, total: totalStr)
    }
    
    @objc func refreshClicked() {
        if let button = statusBarItem.button { button.title = "Ref..." }
        fetchIP()
        updateDisplay() 
    }
    
    @objc func copyClicked() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(currentIP, forType: .string)
    }

    @objc func quitClicked() {
        NSApplication.shared.terminate(self)
    }

    func fetchIP() {
        // Run network tasks on background thread automatically via URLSession
        IPService.shared.fetchIP { [weak self] result in
            DispatchQueue.main.async {
                self?.currentIP = result.ip
                self?.currentFlag = result.flag
                self?.updateDisplay()
            }
        }
    }
}

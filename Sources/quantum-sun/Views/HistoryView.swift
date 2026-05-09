import Cocoa
import QuantumSunCore

class HistoryView: NSView {
    
    // Labels
    private let todayLabel = NSTextField(labelWithString: "Today")
    private let downLabel = NSTextField(labelWithString: "↓")
    private let upLabel = NSTextField(labelWithString: "↑")
    private let totalLabel = NSTextField(labelWithString: "⇅")
    
    private let downValueLabel = NSTextField(labelWithString: "-")
    private let upValueLabel = NSTextField(labelWithString: "-")
    private let totalValueLabel = NSTextField(labelWithString: "-")
    
    private let resetButton: NSButton = {
        let btn = NSButton(title: "Reset...", target: nil, action: nil)
        btn.bezelStyle = .recessed
        btn.controlSize = .small
        btn.font = NSFont.systemFont(ofSize: 10)
        return btn
    }()
    
    var onReset: (() -> Void)?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Style
        let headerFont = NSFont.boldSystemFont(ofSize: 12)
        let valueFont = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        
        todayLabel.font = headerFont
        downLabel.font = NSFont.systemFont(ofSize: 11)
        upLabel.font = NSFont.systemFont(ofSize: 11)
        totalLabel.font = NSFont.systemFont(ofSize: 11)
        
        downValueLabel.font = valueFont
        upValueLabel.font = valueFont
        totalValueLabel.font = valueFont
        
        // Layout Config
        let padding: CGFloat = 16
        let colWidth: CGFloat = 70
        let rowHeight: CGFloat = 20
        
        // Row 1: Headers
        todayLabel.frame = NSRect(x: padding, y: 55, width: 60, height: rowHeight)
        
        downLabel.frame = NSRect(x: 80, y: 55, width: colWidth, height: rowHeight)
        downLabel.alignment = .right
        
        upLabel.frame = NSRect(x: 160, y: 55, width: colWidth, height: rowHeight)
        upLabel.alignment = .right
        
        totalLabel.frame = NSRect(x: 240, y: 55, width: colWidth, height: rowHeight)
        totalLabel.alignment = .right
        
        // Row 2: Values (Wi-Fi/Network)
        // Ideally we'd list interfaces, but for now we aggregate "Total" by default
        let row2Y: CGFloat = 30
        
        // "Total" label for the row
        let rowLabel = NSTextField(labelWithString: "Total")
        rowLabel.font = NSFont.systemFont(ofSize: 11)
        rowLabel.textColor = .secondaryLabelColor
        rowLabel.frame = NSRect(x: padding, y: row2Y, width: 60, height: rowHeight)
        
        downValueLabel.frame = NSRect(x: 80, y: row2Y, width: colWidth, height: rowHeight)
        downValueLabel.alignment = .right
        
        upValueLabel.frame = NSRect(x: 160, y: row2Y, width: colWidth, height: rowHeight)
        upValueLabel.alignment = .right
        
        totalValueLabel.frame = NSRect(x: 240, y: row2Y, width: colWidth, height: rowHeight)
        totalValueLabel.alignment = .right
        
        // Reset Button
        resetButton.frame = NSRect(x: padding - 4, y: 4, width: 60, height: 16)
        resetButton.target = self
        resetButton.action = #selector(resetClicked)
        
        addSubview(todayLabel)
        addSubview(downLabel)
        addSubview(upLabel)
        addSubview(totalLabel)
        
        addSubview(rowLabel)
        addSubview(downValueLabel)
        addSubview(upValueLabel)
        addSubview(totalValueLabel)
        
        addSubview(resetButton)
    }
    
    @objc func resetClicked() {
        onReset?()
    }
    
    func update(download: String, upload: String, total: String) {
        downValueLabel.stringValue = download
        upValueLabel.stringValue = upload
        totalValueLabel.stringValue = total
    }
}

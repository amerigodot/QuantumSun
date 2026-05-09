import Cocoa

class ModernGraphView: NSView {
    
    private let drawingView: GraphDrawingView
    
    override init(frame frameRect: NSRect) {
        let graphFrame = NSRect(origin: .zero, size: frameRect.size)
        self.drawingView = GraphDrawingView(frame: graphFrame)
        
        super.init(frame: frameRect)
        self.wantsLayer = true
        self.layer?.cornerRadius = 12
        self.layer?.masksToBounds = true
        
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        // 1. Background (Glass)
        let visualEffectView = NSVisualEffectView(frame: self.bounds)
        visualEffectView.autoresizingMask = [.width, .height]
        visualEffectView.material = .hudWindow
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        self.addSubview(visualEffectView)
        
        // 2. Drawing Content (On Top)
        drawingView.autoresizingMask = [.width, .height]
        self.addSubview(drawingView)
    }
    
    func addPoint(up: Double, down: Double) {
        drawingView.addPoint(up: up, down: down)
    }
}

private class GraphDrawingView: NSView {
    // Store tuples of (up, down)
    var history: [(up: Double, down: Double)] = []
    let maxPoints = 60
    let padding: CGFloat = 12.0
    
    // Gradients
    // Download (Upward): Cyan -> Green
    let downStartColor = NSColor(srgbRed: 0.0, green: 1.0, blue: 0.8, alpha: 1.0).cgColor // Cyan
    let downEndColor = NSColor(srgbRed: 0.0, green: 1.0, blue: 0.2, alpha: 1.0).cgColor   // Green
    
    // Upload (Downward): Pink -> Purple
    let upStartColor = NSColor(srgbRed: 1.0, green: 0.0, blue: 0.5, alpha: 1.0).cgColor   // Pink
    let upEndColor = NSColor(srgbRed: 0.8, green: 0.0, blue: 1.0, alpha: 1.0).cgColor     // Purple
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    func addPoint(up: Double, down: Double) {
        history.append((up: up, down: down))
        if history.count > maxPoints {
            history.removeFirst()
        }
        self.needsDisplay = true
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        let drawRect = self.bounds.insetBy(dx: padding, dy: padding)
        
        drawHeader(in: drawRect)
        
        if history.isEmpty { return }

        let barWidth = drawRect.width / CGFloat(maxPoints)
        
        // Calculate max value across both Up and Down for shared scaling?
        // Or should we handle them independently? 
        // Shared scaling is better for proportional visualization.
        let allUps = history.map { $0.up }
        let allDowns = history.map { $0.down }
        let maxVal = max( (allUps.max() ?? 0), (allDowns.max() ?? 0), 1024.0 )
        
        let midY = drawRect.midY
        let halfHeight = drawRect.height / 2.0
        
        // Paths
        let downPath = CGMutablePath() // Grows Up
        let upPath = CGMutablePath()   // Grows Down
        
        for (index, point) in history.enumerated() {
            let x = drawRect.origin.x + CGFloat(index) * barWidth
            let w = max(1.0, barWidth - 1.5)
            
            // --- Download (Down stream -> Grows Upward visually per user request "download upward")
            // point.down is the value. 
            let downH = CGFloat(point.down / maxVal) * (halfHeight - 10) // Leave margin
            let downRect = CGRect(x: x, y: midY + 1, width: w, height: max(1.0, downH))
            downPath.addPath(CGPath(roundedRect: downRect, cornerWidth: 1, cornerHeight: 1, transform: nil))
            
            // --- Upload (Up stream -> Grows Downward visually per user request "uploads downward")
            // point.up is the value.
            let upH = CGFloat(point.up / maxVal) * (halfHeight - 10)
            let upRect = CGRect(x: x, y: midY - 1 - max(1.0, upH), width: w, height: max(1.0, upH))
            upPath.addPath(CGPath(roundedRect: upRect, cornerWidth: 1, cornerHeight: 1, transform: nil))
        }
        
        // Draw Download (Upward) - Cyan/Green
        context.saveGState()
        context.addPath(downPath)
        context.clip()
        let downColors = [downStartColor, downEndColor] as CFArray
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        if let grad = CGGradient(colorsSpace: colorSpace, colors: downColors, locations: [0.0, 1.0]) {
            context.drawLinearGradient(grad, start: CGPoint(x: 0, y: midY), end: CGPoint(x: 0, y: drawRect.maxY), options: [])
        }
        context.restoreGState()
        
        // Draw Upload (Downward) - Pink/Purple
        context.saveGState()
        context.addPath(upPath)
        context.clip()
        let upColors = [upStartColor, upEndColor] as CFArray
        if let grad = CGGradient(colorsSpace: colorSpace, colors: upColors, locations: [0.0, 1.0]) {
            // Gradient from center (start) to bottom (end)
            context.drawLinearGradient(grad, start: CGPoint(x: 0, y: midY), end: CGPoint(x: 0, y: drawRect.minY), options: [])
        }
        context.restoreGState()
        
        // Center Line (Optional)
        context.setStrokeColor(NSColor.white.withAlphaComponent(0.1).cgColor)
        context.setLineWidth(1.0)
        context.move(to: CGPoint(x: drawRect.minX, y: midY))
        context.addLine(to: CGPoint(x: drawRect.maxX, y: midY))
        context.strokePath()
    }
    
    private func drawHeader(in rect: CGRect) {
        let text = "NETWORK FLOW"
        let font = NSFont.monospacedSystemFont(ofSize: 10, weight: .bold)
        let color = NSColor(srgbRed: 0.0, green: 1.0, blue: 0.8, alpha: 0.9)
        
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .kern: 2.0
        ]
        
        let size = (text as NSString).size(withAttributes: attrs)
        let x = rect.maxX - size.width
        let y = rect.maxY - 12
        
        (text as NSString).draw(at: CGPoint(x: x, y: y), withAttributes: attrs)
    }
}

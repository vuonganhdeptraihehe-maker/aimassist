import Foundation
import CoreGraphics
import UIKit
import AVFoundation

enum AimMode {
    case off
    case normal
    case headshot
}

class AimEngine: ObservableObject {
    @Published var smooth: Double = 0.35
    var aimMode: AimMode = .off
    var headshotOffset: CGFloat = 22
    
    private var isRunning = false
    private var timer: Timer?
    
    private let screenW: CGFloat = 414
    private let screenH: CGFloat = 896
    
    func start() {
        guard !isRunning else { return }
        isRunning = true
        
        timer = Timer.scheduledTimer(
            withTimeInterval: 1.0/45.0,
            repeats: true
        ) { [weak self] _ in
            self?.tick()
        }
    }
    
    func stop() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    private func tick() {
        guard aimMode != .off else { return }
        
        if let screenshot = takeScreenshot(),
           let target = findEnemy(in: screenshot) {
            moveAim(to: target)
        }
    }
    
    private func takeScreenshot() -> CGImage? {
        guard let window = UIApplication.shared.windows.first else { return nil }
        
        let renderer = UIGraphicsImageRenderer(size: window.bounds.size)
        let image = renderer.image { ctx in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: false)
        }
        
        return image.cgImage
    }
    
    private func findEnemy(in image: CGImage) -> CGPoint? {
        let w = image.width
        let h = image.height
        let scaleX = screenW / CGFloat(w)
        let scaleY = screenH / CGFloat(h)
        
        guard let data = image.dataProvider?.data,
              let ptr = CFDataGetBytePtr(data) else { return nil }
        
        let bpr = image.bytesPerRow
        let bpp = 4
        let cx = w / 2, cy = h / 2
        
        var bestPoint: CGPoint?
        var bestScore: Float = -999999
        
        for y in stride(from: 0, to: h, by: 6) {
            for x in stride(from: 0, to: w, by: 6) {
                let off = y * bpr + x * bpp
                let r = Float(ptr[off]) / 255.0
                let g = Float(ptr[off+1]) / 255.0
                let b = Float(ptr[off+2]) / 255.0
                
                let mx = max(r, g, b)
                let mn = min(r, g, b)
                let delta = mx - mn
                
                var hue: Float = 0
                if delta > 0.01 {
                    if mx == r {
                        hue = ((g - b) / delta).truncatingRemainder(dividingBy: 6) * 60
                    } else if mx == g {
                        hue = ((b - r) / delta + 2) * 60
                    } else {
                        hue = ((r - g) / delta + 4) * 60
                    }
                }
                hue = hue < 0 ? hue + 360 : hue
                hue /= 360
                
                let sat = mx > 0 ? delta / mx : 0
                let val = mx
                
                let isRed = (hue <= 0.03 && sat >= 0.40 && val >= 0.25) ||
                            (hue >= 0.95 && sat >= 0.40 && val >= 0.25)
                
                if isRed {
                    let dx = Float(x - cx)
                    let dy = Float(y - cy)
                    let dist = dx*dx + dy*dy
                    let score = -dist
                    
                    if score > bestScore {
                        bestScore = score
                        bestPoint = CGPoint(x: CGFloat(x) * scaleX, y: CGFloat(y) * scaleY)
                    }
                }
            }
        }
        
        return bestPoint
    }
    
    private func moveAim(to point: CGPoint) {
        var finalY = point.y
        if aimMode == .headshot {
            finalY = max(0, point.y - headshotOffset)
        }
        
        let target = CGPoint(x: point.x, y: finalY)
        performTouch(at: target)
    }
    
    private func performTouch(at point: CGPoint) {
        let event = createHIDEvent(at: point)
        if let e = event {
            UIApplication.shared.sendEvent(e)
        }
    }
    
    private func createHIDEvent(at point: CGPoint) -> UIEvent? {
        return nil
    }
}

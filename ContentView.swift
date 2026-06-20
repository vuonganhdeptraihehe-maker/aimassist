import SwiftUI

struct ContentView: View {
    @StateObject private var engine = AimEngine()
    @State private var isActive = false
    @State private var mode = 0
    @State private var pullUp: Double = 22
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 18) {
                Text("AIMLOCK FF")
                    .font(.system(size: 30, weight: .black))
                    .foregroundColor(.red)
                
                Text("iPhone XS Max | iOS 15+")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Divider().background(Color.red.opacity(0.4))
                
                // ON/OFF
                HStack {
                    Text("Trạng thái")
                        .foregroundColor(.white)
                        .font(.headline)
                    Spacer()
                    Toggle("", isOn: $isActive)
                        .onChange(of: isActive) { v in
                            v ? engine.start() : engine.stop()
                        }
                }
                .padding(.horizontal)
                
                // Chế độ
                VStack(alignment: .leading, spacing: 8) {
                    Text("CHẾ ĐỘ").foregroundColor(.orange).font(.caption)
                    Picker("", selection: $mode) {
                        Text("Tắt (tự bắn)").tag(0)
                        Text("Bắn thường - máu vàng").tag(1)
                        Text("Kéo lên - headshot").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: mode) { v in
                        switch v {
                        case 0: engine.aimMode = .off
                        case 1: engine.aimMode = .normal
                        case 2: engine.aimMode = .headshot
                        default: break
                        }
                    }
                }
                .padding(.horizontal)
                
                // Kéo lên
                if mode == 2 {
                    VStack(spacing: 4) {
                        Text("Kéo lên: \(Int(pullUp)) px")
                            .foregroundColor(.white)
                            .font(.caption)
                        Slider(value: $pullUp, in: 5...50, step: 1)
                            .accentColor(.red)
                            .onChange(of: pullUp) { v in
                                engine.headshotOffset = CGFloat(v)
                            }
                    }
                    .padding(.horizontal)
                }
                
                // Độ mượt
                VStack(spacing: 4) {
                    Text("Độ mượt: \(String(format: "%.1f", engine.smooth))")
                        .foregroundColor(.white)
                        .font(.caption)
                    Slider(value: $engine.smooth, in: 0.1...0.8, step: 0.05)
                        .accentColor(.white)
                }
                .padding(.horizontal)
                
                Spacer()
                
                Text("Vào game → ADS → Tự ngắm")
                    .foregroundColor(.gray)
                    .font(.caption2)
                    .padding(.bottom, 25)
            }
            .padding(.top, 40)
        }
    }
}

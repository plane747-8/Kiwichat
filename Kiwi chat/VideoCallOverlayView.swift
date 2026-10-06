import SwiftUI

struct VideoCallOverlayView: View {
    @EnvironmentObject var engine: MockLiveEngine
    let friend: FriendContact
    
    @State private var isMuted: Bool = false
    @State private var callDurationSeconds: Int = 0
    @State private var timer: Timer? = nil
    
    var body: some View {
        ZStack {
            // Video Preview Background
            LinearGradient(
                colors: [Color(hex: "#0F172A"), Color(hex: "#1E1B4B")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack {
                // MARK: - Top Bar
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color(hex: "#2ED573"))
                                .frame(width: 10, height: 10)
                            
                            Text("KidTime Safe Video Call 🛡️")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "#2ED573"))
                        }
                        
                        Text(friend.displayName)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("\(callDurationSeconds / 60):\(String(format: "%02d", callDurationSeconds % 60))")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)
                
                Spacer()
                
                // MARK: - Simulated Friend Video Feed
                ZStack {
                    RoundedRectangle(cornerRadius: 32)
                        .fill(Color(hex: friend.avatarColorHex).opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 32)
                                .stroke(Color.white.opacity(0.2), lineWidth: 2)
                        )
                    
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: friend.avatarColorHex))
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: friend.avatarSymbol)
                                .font(.system(size: 64))
                                .foregroundColor(.white)
                        }
                        
                        Text("Connected with \(friend.displayName) 🎉")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: 380)
                .padding(.horizontal, 24)
                
                Spacer()
                
                // MARK: - Bottom Control Buttons
                HStack(spacing: 32) {
                    // Mute Button
                    Button(action: {
                        isMuted.toggle()
                    }) {
                        ZStack {
                            Circle()
                                .fill(isMuted ? Color.red : Color.white.opacity(0.2))
                                .frame(width: 64, height: 64)
                            
                            Image(systemName: isMuted ? "mic.slash.fill" : "mic.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                    }
                    
                    // End Call Button (Emergency SOS End)
                    Button(action: {
                        engine.endVideoCall()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 76, height: 76)
                                .shadow(color: Color.red.opacity(0.5), radius: 10, x: 0, y: 4)
                            
                            Image(systemName: "phone.down.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Camera Switch Button
                    Button(action: {
                        // Switch camera simulation
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 64, height: 64)
                            
                            Image(systemName: "camera.rotate.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            callDurationSeconds = 0
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                callDurationSeconds += 1
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
}

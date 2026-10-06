import SwiftUI

struct AudioCallOverlayView: View {
    @EnvironmentObject var engine: MockLiveEngine
    let friend: FriendContact
    
    @State private var isMuted: Bool = false
    @State private var callDurationSeconds: Int = 0
    @State private var timer: Timer? = nil
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#48DBFB"), Color(hex: "#5F27CD")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Friend Avatar Ring
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 160, height: 160)
                    
                    Circle()
                        .fill(Color(hex: friend.avatarColorHex))
                        .frame(width: 130, height: 130)
                    
                    Image(systemName: friend.avatarSymbol)
                        .font(.system(size: 64))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 8) {
                    Text(friend.displayName)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("AudiText Voice Call • \(callDurationSeconds / 60):\(String(format: "%02d", callDurationSeconds % 60))")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.9))
                }
                
                Spacer()
                
                // Controls
                HStack(spacing: 40) {
                    Button(action: { isMuted.toggle() }) {
                        ZStack {
                            Circle()
                                .fill(isMuted ? Color.red : Color.white.opacity(0.3))
                                .frame(width: 68, height: 68)
                            
                            Image(systemName: isMuted ? "mic.slash.fill" : "mic.fill")
                                .font(.system(size: 26))
                                .foregroundColor(.white)
                        }
                    }
                    
                    Button(action: { engine.endAudioCall() }) {
                        ZStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 76, height: 76)
                            
                            Image(systemName: "phone.down.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.bottom, 60)
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

import SwiftUI

struct ChatListView: View {
    @EnvironmentObject var engine: MockLiveEngine
    @Binding var selectedTab: Int
    @State private var showParentPinModal = false
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header
            HStack(alignment: .center) {
                HStack(spacing: 10) {
                    // Kiwi Bird Mascot Icon
                    ZStack {
                        Circle()
                            .fill(Color(hex: "#48DBFB"))
                            .frame(width: 46, height: 46)
                        
                        Image(systemName: "bird.fill")
                            .font(.system(size: 26))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("KiwiChat")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "#5F27CD"))
                        
                        Text("Good friends. Happy chats!")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(Color(hex: "#546E7A"))
                    }
                }
                
                Spacer()
                
                // Settings Gear (Parent Hub Access)
                Button(action: {
                    showParentPinModal = true
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color(hex: "#546E7A"))
                        .padding(10)
                        .background(Color(hex: "#F1F5F9"))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 14)
            .background(Color.white)
            
            Divider()
                .opacity(0.4)
            
            // MARK: - Friend Chat List
            ScrollView {
                if engine.friends.isEmpty {
                    VStack(spacing: 16) {
                        Spacer(minLength: 60)
                        
                        ZStack {
                            Circle()
                                .fill(Color(hex: "#48DBFB").opacity(0.15))
                                .frame(width: 90, height: 90)
                            
                            Image(systemName: "person.2.badge.key.fill")
                                .font(.system(size: 40))
                                .foregroundColor(Color(hex: "#48DBFB"))
                        }
                        
                        Text("No Friends Added Yet!")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "#1E293B"))
                        
                        Text("Exchange a safe 6-digit code with your friend to start chatting live.")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(Color(hex: "#64748B"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 36)
                        
                        Button(action: {
                            selectedTab = 1 // Switch to Add Friend tab
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "key.fill")
                                Text("Add Friend with Code 🔑")
                            }
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(Color(hex: "#5F27CD"))
                            .cornerRadius(20)
                            .shadow(color: Color(hex: "#5F27CD").opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding(.top, 8)
                        
                        Spacer(minLength: 60)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(engine.friends) { friend in
                            Button(action: {
                                engine.selectedFriendId = friend.id
                            }) {
                                FriendRowCard(
                                    friend: friend,
                                    isSelected: engine.selectedFriendId == friend.id
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Divider()
                                .padding(.leading, 76)
                                .opacity(0.3)
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .background(Color(hex: "#F8FAFC"))
        }
        .sheet(isPresented: $showParentPinModal) {
            ParentControlView()
                .environmentObject(engine)
        }
    }
}

// MARK: - Friend Row Card Component
struct FriendRowCard: View {
    let friend: FriendContact
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            // Avatar with Online Badge
            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    Circle()
                        .fill(Color(hex: friend.avatarColorHex))
                        .frame(width: 54, height: 54)
                    
                    Image(systemName: friend.avatarSymbol)
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                }
                
                if friend.isOnline {
                    Circle()
                        .fill(Color(hex: "#2ED573"))
                        .frame(width: 15, height: 15)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2.5)
                        )
                        .offset(x: 2, y: 2)
                }
            }
            
            // Name & Message Preview
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(friend.displayName)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "#1E293B"))
                    
                    Spacer()
                    
                    Text(friend.lastMessageTimeStr)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(Color(hex: "#94A3B8"))
                }
                
                Text(friend.lastMessagePreview.isEmpty ? "Tap to start chat!" : friend.lastMessagePreview)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Color(hex: "#64748B"))
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(isSelected ? Color(hex: "#E0F2FE") : Color.white)
    }
}

// MARK: - Color Hex Extension Helper
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8 * 17) & 255, (int >> 4 & 15) * 17, (int & 15) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, (int >> 16) & 255, (int >> 8) & 255, int & 255)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = ((int >> 24) & 255, (int >> 16) & 255, (int >> 8) & 255, int & 255)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

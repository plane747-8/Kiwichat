import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var engine: MockLiveEngine
    @State private var selectedTab: Int = 0 // 0 = Chats, 1 = Friends, 2 = Discover / Profile
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Top Profile Switcher & Alert Bar
                TopUserStatusBar()
                
                // MARK: - Main Content Area
                GeometryReader { geo in
                    if geo.size.width > 600 {
                        // Wide Screen Dual Panel (Matches User Screenshot Exactly!)
                        HStack(spacing: 0) {
                            // Left Chat List / Selected Tab Panel
                            VStack(spacing: 0) {
                                switch selectedTab {
                                case 0:
                                    ChatListView(selectedTab: $selectedTab)
                                case 1:
                                    AddFriendView()
                                default:
                                    DiscoverProfileView()
                                }
                            }
                            .frame(width: 380)
                            
                            Divider()
                            
                            // Right Active Chat Thread Panel
                            VStack(spacing: 0) {
                                if let friendId = engine.selectedFriendId,
                                   let friend = engine.friends.first(where: { $0.id == friendId }) {
                                    ChatDetailView(friend: friend)
                                } else {
                                    EmptyChatDetailView()
                                }
                            }
                        }
                    } else {
                        // Phone View (Single Panel Navigation)
                        VStack(spacing: 0) {
                            if let friendId = engine.selectedFriendId,
                               let friend = engine.friends.first(where: { $0.id == friendId }) {
                                ChatDetailView(friend: friend)
                            } else {
                                switch selectedTab {
                                case 0:
                                    ChatListView(selectedTab: $selectedTab)
                                case 1:
                                    AddFriendView()
                                default:
                                    DiscoverProfileView()
                                }
                            }
                        }
                    }
                }
                
                // MARK: - Bottom Custom Tab Bar (Matches Screenshot!)
                CustomBottomTabBar(selectedTab: $selectedTab)
            }
            
            // MARK: - Video Call Fullscreen Modal
            if engine.isVideoCallActive, let friend = engine.activeVideoCallFriend {
                VideoCallOverlayView(friend: friend)
                    .transition(.move(edge: .bottom))
                    .zIndex(100)
            }
            
            // MARK: - Audio Call Fullscreen Modal
            if engine.isAudioCallActive, let friend = engine.activeAudioCallFriend {
                AudioCallOverlayView(friend: friend)
                    .transition(.opacity)
                    .zIndex(99)
            }
        }
    }
}

// MARK: - Top User Status Bar
struct TopUserStatusBar: View {
    @EnvironmentObject var engine: MockLiveEngine
    
    var body: some View {
        HStack {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color(hex: engine.currentUser.avatarColorHex))
                    .frame(width: 24, height: 24)
                    .overlay(
                        Image(systemName: engine.currentUser.avatarSymbol)
                            .font(.system(size: 13))
                            .foregroundColor(.white)
                    )
                
                Text(engine.currentUser.displayName)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#1E293B"))
                
                Text("(@\(engine.currentUser.username))")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(Color(hex: "#64748B"))
            }
            
            Spacer()
            
            // Notification Message (If any)
            if let notif = engine.systemNotificationMessage {
                Text(notif)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.orange)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button(action: {
                engine.logoutUser()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.backward.circle.fill")
                    Text("Log Out")
                }
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "#64748B"))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(hex: "#F1F5F9"))
                .cornerRadius(12)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(Color(hex: "#F8FAFC"))
        .border(Color(hex: "#E2E8F0"), width: 0.5)
    }
}

// MARK: - Custom Bottom Tab Bar Component (Matches User Screenshot!)
struct CustomBottomTabBar: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var engine: MockLiveEngine
    
    var body: some View {
        HStack(spacing: 0) {
            // Tab 1: Chats
            Button(action: {
                selectedTab = 0
                engine.selectedFriendId = engine.friends.first?.id
            }) {
                VStack(spacing: 4) {
                    ZStack {
                        if selectedTab == 0 {
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color(hex: "#E0F2FE"))
                                .frame(width: 64, height: 36)
                        }
                        
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 20))
                            .foregroundColor(selectedTab == 0 ? Color(hex: "#0284C7") : Color(hex: "#64748B"))
                    }
                    
                    Text("Chats")
                        .font(.system(size: 13, weight: selectedTab == 0 ? .bold : .medium, design: .rounded))
                        .foregroundColor(selectedTab == 0 ? Color(hex: "#0284C7") : Color(hex: "#64748B"))
                }
            }
            .frame(maxWidth: .infinity)
            
            // Tab 2: Friends (6-Digit Codes)
            Button(action: {
                selectedTab = 1
                engine.selectedFriendId = nil
            }) {
                VStack(spacing: 4) {
                    ZStack {
                        if selectedTab == 1 {
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color(hex: "#E0F2FE"))
                                .frame(width: 64, height: 36)
                        }
                        
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 20))
                            .foregroundColor(selectedTab == 1 ? Color(hex: "#0284C7") : Color(hex: "#64748B"))
                    }
                    
                    Text("Friends")
                        .font(.system(size: 13, weight: selectedTab == 1 ? .bold : .medium, design: .rounded))
                        .foregroundColor(selectedTab == 1 ? Color(hex: "#0284C7") : Color(hex: "#64748B"))
                }
            }
            .frame(maxWidth: .infinity)
            
            // Tab 3: Discover / Profile
            Button(action: {
                selectedTab = 2
                engine.selectedFriendId = nil
            }) {
                VStack(spacing: 4) {
                    ZStack {
                        if selectedTab == 2 {
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color(hex: "#E0F2FE"))
                                .frame(width: 64, height: 36)
                        }
                        
                        Image(systemName: "face.smiling.fill")
                            .font(.system(size: 20))
                            .foregroundColor(selectedTab == 2 ? Color(hex: "#0284C7") : Color(hex: "#64748B"))
                    }
                    
                    Text("Discover")
                        .font(.system(size: 13, weight: selectedTab == 2 ? .bold : .medium, design: .rounded))
                        .foregroundColor(selectedTab == 2 ? Color(hex: "#0284C7") : Color(hex: "#64748B"))
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 8)
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(Color(hex: "#E2E8F0"))
                .frame(height: 1),
            alignment: .top
        )
    }
}

// MARK: - Discover & Profile View
struct DiscoverProfileView: View {
    @EnvironmentObject var engine: MockLiveEngine
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Discover & Profile 😊")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#5F27CD"))
                
                Text("Customize your kid avatar and view safety stats.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Color(hex: "#64748B"))
            }
            .padding(.top, 24)
            
            // Profile Card
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color(hex: engine.currentUser.avatarColorHex))
                        .frame(width: 90, height: 90)
                    
                    Image(systemName: engine.currentUser.avatarSymbol)
                        .font(.system(size: 48))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 4) {
                    Text(engine.currentUser.displayName)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    
                    Text("@\(engine.currentUser.username)")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(Color(hex: "#64748B"))
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "shield.fill")
                        .foregroundColor(Color(hex: "#2ED573"))
                    Text("100% Protected Account")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "#2ED573"))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color(hex: "#E8FADF"))
                .clipShape(Capsule())
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .background(Color(hex: "#F8FAFC"))
    }
}

// MARK: - Empty Chat Detail View
struct EmptyChatDetailView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 64))
                .foregroundColor(Color(hex: "#CBD5E1"))
            
            Text("Select a friend to start chatting!")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "#64748B"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "#F8FAFC"))
    }
}

import Foundation
import SwiftUI
import Combine

@MainActor
final class MockLiveEngine: ObservableObject {
    // MARK: - Published Properties
    @Published var currentUser: KidUser
    @Published var savedUsers: [KidUser] = []
    @Published var userPasswords: [String: String] = [:] // username -> password
    
    // Clean Empty Lists - ZERO BOTS!
    @Published var friends: [FriendContact] = []
    @Published var pendingFriendInvites: [FriendContact] = []
    @Published var messagesByFriendId: [UUID: [ChatMessage]] = [:]
    @Published var activeInviteCodes: [InviteCode] = []
    @Published var flaggedIncidents: [FlaggedIncident] = []
    
    // Start on Sign Up / Login Screen
    @Published var isAuthenticated: Bool = false
    
    // Active Navigation / Modals
    @Published var selectedFriendId: UUID?
    @Published var isVideoCallActive: Bool = false
    @Published var activeVideoCallFriend: FriendContact? = nil
    @Published var isAudioCallActive: Bool = false
    @Published var activeAudioCallFriend: FriendContact? = nil
    @Published var showParentPINModal: Bool = false
    @Published var isParentModeUnlocked: Bool = false
    @Published var systemNotificationMessage: String? = nil
    
    // MARK: - Initializer
    init() {
        // Default placeholder user before logging in
        let placeholder = KidUser(
            username: "guest",
            displayName: "Guest",
            avatarSymbol: "person.crop.circle.fill",
            avatarColorHex: "#38BDF8"
        )
        self.currentUser = placeholder
        self.friends = []
        self.pendingFriendInvites = []
        self.messagesByFriendId = [:]
        self.flaggedIncidents = []
        self.activeInviteCodes = []
        self.isAuthenticated = false
        
        loadSavedAccounts()
        
        // Configure Custom Live WebSocket client
        KiwiWebSocketClient.shared.configure(with: self)
    }
    
    // MARK: - Local Persistence for Accounts & Chat Data
    private func loadSavedAccounts() {
        if let data = UserDefaults.standard.data(forKey: "kiwi_saved_users"),
           let decoded = try? JSONDecoder().decode([KidUser].self, from: data) {
            self.savedUsers = decoded
        }
        if let passDict = UserDefaults.standard.dictionary(forKey: "kiwi_user_passwords") as? [String: String] {
            self.userPasswords = passDict
        }
        
        // Auto-restore last logged in kid
        if let lastUserId = UserDefaults.standard.string(forKey: "kiwi_last_logged_in_user_id"),
           let uuid = UUID(uuidString: lastUserId),
           let user = savedUsers.first(where: { $0.id == uuid }) {
            self.currentUser = user
            self.isAuthenticated = true
            loadChatData()
            KiwiWebSocketClient.shared.connect()
            KiwiWebSocketClient.shared.registerUser(user)
        }
    }
    
    private func saveAccounts() {
        if let encoded = try? JSONEncoder().encode(savedUsers) {
            UserDefaults.standard.set(encoded, forKey: "kiwi_saved_users")
        }
        UserDefaults.standard.set(userPasswords, forKey: "kiwi_user_passwords")
    }
    
    func saveChatData() {
        guard isAuthenticated else { return }
        let keyFriends = "kiwi_friends_\(currentUser.id.uuidString)"
        let keyMessages = "kiwi_messages_\(currentUser.id.uuidString)"
        if let data = try? JSONEncoder().encode(friends) {
            UserDefaults.standard.set(data, forKey: keyFriends)
        }
        let stringKeyDict = Dictionary(uniqueKeysWithValues: messagesByFriendId.map { ($0.key.uuidString, $0.value) })
        if let data = try? JSONEncoder().encode(stringKeyDict) {
            UserDefaults.standard.set(data, forKey: keyMessages)
        }
    }
    
    func loadChatData() {
        let keyFriends = "kiwi_friends_\(currentUser.id.uuidString)"
        let keyMessages = "kiwi_messages_\(currentUser.id.uuidString)"
        if let data = UserDefaults.standard.data(forKey: keyFriends),
           let decoded = try? JSONDecoder().decode([FriendContact].self, from: data) {
            self.friends = decoded
        } else {
            self.friends = []
        }
        if let data = UserDefaults.standard.data(forKey: keyMessages),
           let decoded = try? JSONDecoder().decode([String: [ChatMessage]].self, from: data) {
            var restored: [UUID: [ChatMessage]] = [:]
            for (k, v) in decoded {
                if let uuid = UUID(uuidString: k) {
                    restored[uuid] = v
                }
            }
            self.messagesByFriendId = restored
        } else {
            self.messagesByFriendId = [:]
        }
    }
    
    // MARK: - Real Authentication (Sign Up & Login)
    func loginKidUser(username: String, password: String) -> (success: Bool, message: String) {
        let cleanUser = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleanUser.isEmpty else {
            return (false, "Please enter your username.")
        }
        guard !password.isEmpty else {
            return (false, "Please enter your password.")
        }
        
        // Check if user exists
        if let matchedUser = savedUsers.first(where: { $0.username.lowercased() == cleanUser }) {
            let correctPassword = userPasswords[cleanUser] ?? ""
            if !correctPassword.isEmpty && correctPassword != password {
                return (false, "Incorrect password. Please try again.")
            }
            self.currentUser = matchedUser
        } else {
            // First time login with this username -> create account
            let newKid = KidUser(
                username: cleanUser,
                displayName: cleanUser.capitalized,
                avatarSymbol: "face.smiling.fill",
                avatarColorHex: "#38BDF8"
            )
            self.currentUser = newKid
            self.savedUsers.append(newKid)
            self.userPasswords[cleanUser] = password
            saveAccounts()
        }
        
        self.isAuthenticated = true
        UserDefaults.standard.set(currentUser.id.uuidString, forKey: "kiwi_last_logged_in_user_id")
        loadChatData()
        self.systemNotificationMessage = "Welcome, \(currentUser.displayName)! 👋"
        
        // Connect & register on live WebSocket server
        KiwiWebSocketClient.shared.connect()
        KiwiWebSocketClient.shared.registerUser(currentUser)
        
        return (true, "Logged in successfully")
    }
    
    func registerNewKidUser(
        username: String,
        password: String,
        displayName: String,
        avatarSymbol: String,
        avatarColorHex: String,
        parentPin: String,
        parentEmail: String
    ) -> (success: Bool, message: String) {
        let cleanUser = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleanName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !cleanUser.isEmpty else { return (false, "Please choose a username.") }
        guard !password.isEmpty, password.count >= 4 else { return (false, "Password must be at least 4 characters.") }
        guard !cleanName.isEmpty else { return (false, "Please enter a display nickname.") }
        guard parentPin.count == 4 else { return (false, "Parent PIN must be 4 digits.") }
        
        // Prevent duplicate usernames
        if savedUsers.contains(where: { $0.username.lowercased() == cleanUser }) {
            return (false, "Username '@\(cleanUser)' is already taken. Please pick another.")
        }
        
        let parentConfig = ParentSafetySettings(
            parentPin: parentPin,
            parentEmail: parentEmail.isEmpty ? "parent@family.com" : parentEmail,
            enableWordFilter: true,
            filterSeverity: .strict,
            requirePinForFriends: false,
            enableVoiceNotes: true,
            enableVideoCalls: true
        )
        
        let newKid = KidUser(
            username: cleanUser,
            displayName: cleanName,
            avatarSymbol: avatarSymbol,
            avatarColorHex: avatarColorHex,
            parentSettings: parentConfig
        )
        
        self.currentUser = newKid
        self.savedUsers.append(newKid)
        self.userPasswords[cleanUser] = password
        saveAccounts()
        
        self.isAuthenticated = true
        UserDefaults.standard.set(newKid.id.uuidString, forKey: "kiwi_last_logged_in_user_id")
        loadChatData()
        self.systemNotificationMessage = "Welcome to KiwiChat, \(cleanName)! 🎉"
        
        // Connect & register on live WebSocket server
        KiwiWebSocketClient.shared.connect()
        KiwiWebSocketClient.shared.registerUser(newKid)
        
        return (true, "Account created")
    }
    
    func logoutUser() {
        self.isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: "kiwi_last_logged_in_user_id")
        self.friends = []
        self.messagesByFriendId = [:]
        self.pendingFriendInvites = []
        KiwiWebSocketClient.shared.disconnect()
        self.systemNotificationMessage = "Logged out"
    }
    
    // MARK: - Contact Management Actions
    func approveFriendInvite(inviteId: UUID) {
        guard let index = pendingFriendInvites.firstIndex(where: { $0.id == inviteId }) else { return }
        var approvedFriend = pendingFriendInvites.remove(at: index)
        approvedFriend.isApprovedByParent = true
        approvedFriend.lastMessagePreview = "Parent approved! Happy chatting 🎉"
        approvedFriend.lastMessageTimeStr = "Just now"
        friends.insert(approvedFriend, at: 0)
        saveChatData()
        
        systemNotificationMessage = "Approved friendship with \(approvedFriend.displayName) 🛡️"
    }
    
    func rejectFriendInvite(inviteId: UUID) {
        guard let index = pendingFriendInvites.firstIndex(where: { $0.id == inviteId }) else { return }
        let friend = pendingFriendInvites.remove(at: index)
        systemNotificationMessage = "Declined invite from \(friend.displayName)"
    }
    
    func togglePauseChat(for friendId: UUID) {
        guard let idx = friends.firstIndex(where: { $0.id == friendId }) else { return }
        friends[idx].isChatPaused.toggle()
        saveChatData()
        let status = friends[idx].isChatPaused ? "Paused" : "Resumed"
        systemNotificationMessage = "\(status) chat for \(friends[idx].displayName)"
    }
    
    func toggleBlockContact(for friendId: UUID) {
        guard let idx = friends.firstIndex(where: { $0.id == friendId }) else { return }
        friends[idx].isBlocked.toggle()
        saveChatData()
        let status = friends[idx].isBlocked ? "Blocked" : "Unblocked"
        systemNotificationMessage = "\(status) \(friends[idx].displayName)"
    }
    
    func removeContact(for friendId: UUID) {
        if let idx = friends.firstIndex(where: { $0.id == friendId }) {
            let removedName = friends[idx].displayName
            friends.remove(at: idx)
            messagesByFriendId.removeValue(forKey: friendId)
            saveChatData()
            if selectedFriendId == friendId {
                selectedFriendId = friends.first?.id
            }
            systemNotificationMessage = "Removed \(removedName) from contacts"
        }
    }
    
    // MARK: - Flagged Incident Log Management
    func dismissFlaggedIncident(id: UUID) {
        flaggedIncidents.removeAll(where: { $0.id == id })
    }
    
    func clearAllFlaggedIncidents() {
        flaggedIncidents.removeAll()
        systemNotificationMessage = "Cleared all safety incident logs"
    }
    
    // MARK: - Sending Messages (Real Network Only - NO BOTS!)
    func sendMessage(to friendId: UUID, text: String, type: MessageType = .text, audioDuration: Double? = nil, stickerName: String? = nil) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || type != .text else { return }
        
        // Check if chat is paused or friend is blocked
        if let friend = friends.first(where: { $0.id == friendId }) {
            if friend.isBlocked {
                systemNotificationMessage = "⚠️ Cannot send message: Contact is blocked by parent."
                return
            }
            if friend.isChatPaused {
                systemNotificationMessage = "⚠️ Cannot send message: Chat is currently paused by parent."
                return
            }
        }
        
        // 1. Run Safety Word Filter
        var cleanText = text
        var flagged = false
        if type == .text && currentUser.parentSettings.enableWordFilter {
            let filterResult = SafetyFilterService.shared.sanitize(
                text,
                severity: currentUser.parentSettings.filterSeverity,
                customBlockedWords: currentUser.parentSettings.customBlockedWords
            )
            cleanText = filterResult.filteredText
            flagged = filterResult.wasFlagged
            if flagged, let reason = filterResult.flagReason {
                systemNotificationMessage = "🛡️ Safety Alert: \(reason)"
                flaggedIncidents.insert(
                    FlaggedIncident(senderName: currentUser.displayName, originalMessage: text, flagReason: reason),
                    at: 0
                )
            }
        }
        
        // Target receiver ID is the remote friend's userId
        let targetFriend = friends.first(where: { $0.id == friendId })
        let remoteReceiverId = targetFriend?.friendUserId ?? friendId
        
        let newMsg = ChatMessage(
            senderId: currentUser.id,
            receiverId: remoteReceiverId,
            type: type,
            textContent: cleanText,
            audioDuration: audioDuration,
            stickerName: stickerName,
            timestamp: Date(),
            isRead: true,
            isFlagged: flagged
        )
        
        if messagesByFriendId[friendId] == nil {
            messagesByFriendId[friendId] = []
        }
        messagesByFriendId[friendId]?.append(newMsg)
        
        // Update friend preview
        if let idx = friends.firstIndex(where: { $0.id == friendId }) {
            friends[idx].lastMessagePreview = type == .audio ? "🎙️ Voice Note" : (type == .sticker ? "🐱 Sticker" : cleanText)
            friends[idx].lastMessageTimeStr = "Just now"
        }
        
        // Save chat data locally
        saveChatData()
        
        // Send across Live WebSocket to the other phone
        KiwiWebSocketClient.shared.sendChatMessage(newMsg)
    }
    
    // MARK: - 6-Digit One-Time Code Generator & Redeemer
    func generateInviteCode() -> InviteCode {
        let digits = String(format: "%06d", Int.random(in: 100000...999999))
        let codeObj = InviteCode(
            code: digits,
            creatorUserId: currentUser.id,
            creatorUsername: currentUser.username,
            creatorDisplayName: currentUser.displayName,
            creatorAvatarSymbol: currentUser.avatarSymbol
        )
        activeInviteCodes.append(codeObj)
        
        // Broadcast to Live Server
        KiwiWebSocketClient.shared.broadcastInviteCode(digits, creator: currentUser)
        
        return codeObj
    }
    
    func redeemInviteCode(_ inputCode: String) -> (success: Bool, message: String) {
        let cleaned = inputCode.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")
        guard cleaned.count == 6 else {
            return (false, "Please enter a valid 6-digit code.")
        }
        
        // Transmit redemption packet to Live Server to match with the real phone!
        KiwiWebSocketClient.shared.redeemInviteCode(cleaned, redeemer: currentUser)
        
        return (true, "Searching for your friend with code \(cleaned)...")
    }
    
    // MARK: - Calls (Video / Audio)
    func startVideoCall(with friend: FriendContact) {
        guard currentUser.parentSettings.enableVideoCalls else {
            systemNotificationMessage = "🔒 Video calling is disabled by Parent Controls."
            return
        }
        if friend.isBlocked || friend.isChatPaused {
            systemNotificationMessage = "⚠️ Video call unavailable for this contact."
            return
        }
        activeVideoCallFriend = friend
        isVideoCallActive = true
        KiwiWebSocketClient.shared.sendCallSignal(action: "call_start", friendId: friend.friendUserId)
    }
    
    func endVideoCall() {
        if let friend = activeVideoCallFriend {
            KiwiWebSocketClient.shared.sendCallSignal(action: "call_end", friendId: friend.friendUserId)
        }
        isVideoCallActive = false
        activeVideoCallFriend = nil
    }
    
    func startAudioCall(with friend: FriendContact) {
        guard currentUser.parentSettings.enableVoiceNotes else {
            systemNotificationMessage = "🔒 Voice calls are disabled by Parent Controls."
            return
        }
        if friend.isBlocked || friend.isChatPaused {
            systemNotificationMessage = "⚠️ Voice call unavailable for this contact."
            return
        }
        activeAudioCallFriend = friend
        isAudioCallActive = true
        KiwiWebSocketClient.shared.sendCallSignal(action: "call_start", friendId: friend.friendUserId)
    }
    
    func endAudioCall() {
        if let friend = activeAudioCallFriend {
            KiwiWebSocketClient.shared.sendCallSignal(action: "call_end", friendId: friend.friendUserId)
        }
        isAudioCallActive = false
        activeAudioCallFriend = nil
    }
}

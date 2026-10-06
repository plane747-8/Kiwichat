import Foundation
import SwiftUI
import Combine

@MainActor
final class MockLiveEngine: ObservableObject {
    // MARK: - Published Properties
    @Published var currentUser: KidUser
    @Published var availableDemoUsers: [KidUser] = []
    @Published var friends: [FriendContact] = []
    @Published var messagesByFriendId: [UUID: [ChatMessage]] = [:]
    @Published var activeInviteCodes: [InviteCode] = []
    @Published var flaggedIncidents: [FlaggedIncident] = []
    @Published var isAuthenticated: Bool = true // Allows toggle between Auth Screen and Main App
    
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
        // Create Demo Users
        let leoSettings = ParentSafetySettings(parentPin: "1234")
        let leo = KidUser(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            username: "leo_star",
            displayName: "Leo",
            avatarSymbol: "face.smiling.fill",
            avatarColorHex: "#FF6B81",
            parentSettings: leoSettings
        )
        
        let emma = KidUser(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            username: "emma_play",
            displayName: "Emma",
            avatarSymbol: "person.crop.circle.fill",
            avatarColorHex: "#FF758C"
        )
        
        let lucas = KidUser(
            id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            username: "lucas_gamer",
            displayName: "Lucas",
            avatarSymbol: "sparkles",
            avatarColorHex: "#2ED573"
        )
        
        let ava = KidUser(
            id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
            username: "ava_sun",
            displayName: "Ava",
            avatarSymbol: "star.fill",
            avatarColorHex: "#FF9F43"
        )
        
        let noah = KidUser(
            id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
            username: "noah_hero",
            displayName: "Noah",
            avatarSymbol: "bolt.fill",
            avatarColorHex: "#54a0ff"
        )
        
        let olivia = KidUser(
            id: UUID(uuidString: "66666666-6666-6666-6666-666666666666")!,
            username: "olivia_art",
            displayName: "Olivia",
            avatarSymbol: "heart.fill",
            avatarColorHex: "#9c88ff"
        )
        
        self.currentUser = leo
        self.availableDemoUsers = [leo, emma, lucas, ava, noah, olivia]
        
        setupInitialFriendsAndMessages(leo: leo, emma: emma, lucas: lucas, ava: ava, noah: noah, olivia: olivia)
    }
    
    // MARK: - Setup Initial Data matching UI screenshot
    private func setupInitialFriendsAndMessages(
        leo: KidUser,
        emma: KidUser,
        lucas: KidUser,
        ava: KidUser,
        noah: KidUser,
        olivia: KidUser
    ) {
        let fEmma = FriendContact(
            friendUserId: emma.id,
            friendUsername: emma.username,
            displayName: "Emma",
            avatarSymbol: "person.fill",
            avatarColorHex: "#FF758C",
            isOnline: true,
            lastMessagePreview: "Let's play later! 🎮",
            lastMessageTimeStr: "10:24 AM",
            unreadCount: 0
        )
        
        let fLucas = FriendContact(
            friendUserId: lucas.id,
            friendUsername: lucas.username,
            displayName: "Lucas",
            avatarSymbol: "person.fill",
            avatarColorHex: "#2ED573",
            isOnline: true,
            lastMessagePreview: "Sounds good! 👍",
            lastMessageTimeStr: "9:12 AM",
            unreadCount: 0
        )
        
        let fAva = FriendContact(
            friendUserId: ava.id,
            friendUsername: ava.username,
            displayName: "Ava",
            avatarSymbol: "person.fill",
            avatarColorHex: "#FF9F43",
            isOnline: false,
            lastMessagePreview: "Check this out! 🐱",
            lastMessageTimeStr: "Yesterday",
            unreadCount: 0
        )
        
        let fNoah = FriendContact(
            friendUserId: noah.id,
            friendUsername: noah.username,
            displayName: "Noah",
            avatarSymbol: "person.fill",
            avatarColorHex: "#54a0ff",
            isOnline: false,
            lastMessagePreview: "See you at recess!",
            lastMessageTimeStr: "Yesterday",
            unreadCount: 0
        )
        
        let fOlivia = FriendContact(
            friendUserId: olivia.id,
            friendUsername: olivia.username,
            displayName: "Olivia",
            avatarSymbol: "person.fill",
            avatarColorHex: "#9c88ff",
            isOnline: false,
            lastMessagePreview: "That's awesome! 🌈",
            lastMessageTimeStr: "Monday",
            unreadCount: 0
        )
        
        self.friends = [fEmma, fLucas, fAva, fNoah, fOlivia]
        self.selectedFriendId = fEmma.id
        
        // Populate Emma Chat Thread (Matches UI screenshot!)
        let emmaMessages: [ChatMessage] = [
            ChatMessage(
                senderId: leo.id,
                receiverId: emma.id,
                type: .text,
                textContent: "Hi Emma! 👋 What do you want to do today?",
                timestamp: Date().addingTimeInterval(-3600)
            ),
            ChatMessage(
                senderId: emma.id,
                receiverId: leo.id,
                type: .text,
                textContent: "Hey! 😊 Maybe we can play a game or watch a funny video?",
                timestamp: Date().addingTimeInterval(-2700)
            ),
            ChatMessage(
                senderId: leo.id,
                receiverId: emma.id,
                type: .text,
                textContent: "Both sound great! 🎮 Let's play after lunch!",
                timestamp: Date().addingTimeInterval(-1800)
            ),
            ChatMessage(
                senderId: emma.id,
                receiverId: leo.id,
                type: .text,
                textContent: "Yay! 🎉 See you then!",
                timestamp: Date().addingTimeInterval(-900)
            ),
            ChatMessage(
                senderId: emma.id,
                receiverId: leo.id,
                type: .sticker,
                textContent: "Sticker",
                stickerName: "cat_waving",
                timestamp: Date().addingTimeInterval(-300)
            )
        ]
        
        let lucasMessages: [ChatMessage] = [
            ChatMessage(
                senderId: lucas.id,
                receiverId: leo.id,
                type: .text,
                textContent: "Sounds good! 👍",
                timestamp: Date().addingTimeInterval(-7200)
            )
        ]
        
        let avaMessages: [ChatMessage] = [
            ChatMessage(
                senderId: ava.id,
                receiverId: leo.id,
                type: .text,
                textContent: "Check this out! 🐱",
                timestamp: Date().addingTimeInterval(-86400)
            )
        ]
        
        let noahMessages: [ChatMessage] = [
            ChatMessage(
                senderId: noah.id,
                receiverId: leo.id,
                type: .text,
                textContent: "See you at recess!",
                timestamp: Date().addingTimeInterval(-86400)
            )
        ]
        
        let oliviaMessages: [ChatMessage] = [
            ChatMessage(
                senderId: olivia.id,
                receiverId: leo.id,
                type: .text,
                textContent: "That's awesome! 🌈",
                timestamp: Date().addingTimeInterval(-172800)
            )
        ]
        
        messagesByFriendId[fEmma.id] = emmaMessages
        messagesByFriendId[fLucas.id] = lucasMessages
        messagesByFriendId[fAva.id] = avaMessages
        messagesByFriendId[fNoah.id] = noahMessages
        messagesByFriendId[fOlivia.id] = oliviaMessages
    }
    
    // MARK: - Auth Actions
    func loginKidUser(username: String, password: String) {
        if let match = availableDemoUsers.first(where: { $0.username.lowercased() == username.lowercased() }) {
            self.currentUser = match
        } else {
            let newKid = KidUser(
                username: username.lowercased(),
                displayName: username.capitalized,
                avatarSymbol: "star.fill",
                avatarColorHex: "#38BDF8"
            )
            self.currentUser = newKid
            self.availableDemoUsers.append(newKid)
        }
        self.isAuthenticated = true
        self.systemNotificationMessage = "Logged in as \(currentUser.displayName) 👋"
    }
    
    func registerNewKidUser(
        username: String,
        displayName: String,
        avatarSymbol: String,
        avatarColorHex: String,
        parentPin: String,
        parentEmail: String
    ) {
        let parentConfig = ParentSafetySettings(parentPin: parentPin, parentEmail: parentEmail)
        let newKid = KidUser(
            username: username.lowercased(),
            displayName: displayName,
            avatarSymbol: avatarSymbol,
            avatarColorHex: avatarColorHex,
            parentSettings: parentConfig
        )
        self.currentUser = newKid
        self.availableDemoUsers.append(newKid)
        self.isAuthenticated = true
        self.systemNotificationMessage = "Created safe account for \(displayName) 🎉"
    }
    
    func logoutUser() {
        self.isAuthenticated = false
        self.systemNotificationMessage = "Logged out"
    }
    
    // MARK: - Actions
    func sendMessage(to friendId: UUID, text: String, type: MessageType = .text, audioDuration: Double? = nil, stickerName: String? = nil) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || type != .text else { return }
        
        // 1. Run Safety Word Filter
        var cleanText = text
        var flagged = false
        if type == .text && currentUser.parentSettings.enableWordFilter {
            let filterResult = SafetyFilterService.shared.sanitize(text, customBlockedWords: currentUser.parentSettings.customBlockedWords)
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
        
        let newMsg = ChatMessage(
            senderId: currentUser.id,
            receiverId: friendId,
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
        
        // Simulate Friend Auto-Reply after 2.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            self?.simulateAutoReply(from: friendId)
        }
    }
    
    private func simulateAutoReply(from friendId: UUID) {
        guard let friend = friends.first(where: { $0.id == friendId }) else { return }
        let replies = [
            "Super cool! 😎",
            "Can't wait to play! 🚀",
            "Awesome! 🌟",
            "Haha that's so funny! 😂",
            "See you later! 👋"
        ]
        let randomReply = replies.randomElement() ?? "Yay!"
        
        let replyMsg = ChatMessage(
            senderId: friend.friendUserId,
            receiverId: currentUser.id,
            type: .text,
            textContent: randomReply,
            timestamp: Date(),
            isRead: true
        )
        
        messagesByFriendId[friendId]?.append(replyMsg)
        if let idx = friends.firstIndex(where: { $0.id == friendId }) {
            friends[idx].lastMessagePreview = randomReply
            friends[idx].lastMessageTimeStr = "Just now"
        }
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
        return codeObj
    }
    
    func redeemInviteCode(_ inputCode: String) -> (success: Bool, message: String) {
        let cleaned = inputCode.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")
        guard cleaned.count == 6 else {
            return (false, "Please enter a valid 6-digit code.")
        }
        
        // Check if code matches a demo user code or dynamically generated code
        let friendNames = ["Chloe", "Zack", "Maya", "Ethan", "Lily"]
        let randomName = friendNames.randomElement() ?? "Friend"
        
        let newFriendUser = KidUser(
            username: "\(randomName.lowercased())_buddy",
            displayName: randomName,
            avatarSymbol: "person.crop.circle.fill",
            avatarColorHex: "#70A1FF"
        )
        
        let newContact = FriendContact(
            friendUserId: newFriendUser.id,
            friendUsername: newFriendUser.username,
            displayName: newFriendUser.displayName,
            avatarSymbol: "person.fill",
            avatarColorHex: "#70A1FF",
            isOnline: true,
            lastMessagePreview: "Connected via 6-digit code! 🎉",
            lastMessageTimeStr: "Just now"
        )
        
        friends.insert(newContact, at: 0)
        messagesByFriendId[newContact.id] = [
            ChatMessage(
                senderId: newFriendUser.id,
                receiverId: currentUser.id,
                type: .text,
                textContent: "Hey \(currentUser.displayName)! We connected using the 6-digit invite code! 🎉",
                timestamp: Date()
            )
        ]
        
        selectedFriendId = newContact.id
        return (true, "Success! Connected with \(randomName) 👋")
    }
    
    // MARK: - Calls (Video / Audio)
    func startVideoCall(with friend: FriendContact) {
        guard currentUser.parentSettings.enableVideoCalls else {
            systemNotificationMessage = "🔒 Video calling is disabled by Parent Controls."
            return
        }
        activeVideoCallFriend = friend
        isVideoCallActive = true
    }
    
    func endVideoCall() {
        isVideoCallActive = false
        activeVideoCallFriend = nil
    }
    
    func startAudioCall(with friend: FriendContact) {
        guard currentUser.parentSettings.enableVoiceNotes else {
            systemNotificationMessage = "🔒 Voice calls are disabled by Parent Controls."
            return
        }
        activeAudioCallFriend = friend
        isAudioCallActive = true
    }
    
    func endAudioCall() {
        isAudioCallActive = false
        activeAudioCallFriend = nil
    }
    
    // MARK: - Switch Demo User Profile
    func switchUser(to user: KidUser) {
        self.currentUser = user
        self.isParentModeUnlocked = false
        systemNotificationMessage = "Switched active profile to \(user.displayName)"
    }
}

import Foundation
import SwiftUI
import Combine

// MARK: - Native WebSocket Client for KiwiChat
@MainActor
final class KiwiWebSocketClient: ObservableObject {
    static let shared = KiwiWebSocketClient()
    
    // Live Cloud Server on Render (Worldwide: Ohio to Japan & Everywhere!)
    static let defaultCloudServer = "kiwichat.onrender.com"
    
    @Published var isConnected: Bool = false
    @Published var serverAddress: String = "kiwichat.onrender.com"
    @Published var connectionStatusText: String = "Disconnected"
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var isIntentionalDisconnect: Bool = false
    private weak var liveEngine: MockLiveEngine?
    
    private init() {
        // Load saved server URL if present and not the old local IP
        if let saved = UserDefaults.standard.string(forKey: "kiwi_server_ip"),
           !saved.isEmpty,
           !saved.contains("192.168.") {
            self.serverAddress = saved
        } else {
            self.serverAddress = Self.defaultCloudServer
            UserDefaults.standard.set(Self.defaultCloudServer, forKey: "kiwi_server_ip")
        }
    }
    
    func configure(with engine: MockLiveEngine) {
        self.liveEngine = engine
    }
    
    // MARK: - Connect & Disconnect
    func connect() {
        disconnect()
        isIntentionalDisconnect = false
        
        var trimmed = serverAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let urlString: String
        if trimmed.hasPrefix("wss://") || trimmed.hasPrefix("ws://") {
            urlString = trimmed
        } else {
            // Remove any stray http:// or https:// prefix
            trimmed = trimmed.replacingOccurrences(of: "https://", with: "")
                             .replacingOccurrences(of: "http://", with: "")
            
            // Cloud hosts like render.com, railway.app, etc. require secure wss://
            let isCloud = trimmed.contains(".com") || trimmed.contains(".app") || trimmed.contains(".io") || trimmed.contains(".dev") || trimmed.contains(".net")
            let isLocal = trimmed.hasPrefix("192.168.") || trimmed.hasPrefix("10.") || trimmed.hasPrefix("172.") || trimmed.hasPrefix("127.0.0.1") || trimmed.hasPrefix("localhost")
            
            if isCloud && !isLocal {
                urlString = "wss://\(trimmed)"
            } else {
                urlString = "ws://\(trimmed)"
            }
        }
        
        guard let url = URL(string: urlString) else {
            connectionStatusText = "Invalid server URL"
            return
        }
        
        connectionStatusText = "Connecting to Cloud Server..."
        let session = URLSession(configuration: .default)
        let task = session.webSocketTask(with: url)
        self.webSocketTask = task
        task.resume()
        
        // Save preferred URL
        UserDefaults.standard.set(serverAddress, forKey: "kiwi_server_ip")
        
        // Start listening
        listenForMessages()
        
        // Send initial registration packet
        if let engine = liveEngine {
            registerUser(engine.currentUser)
        }
    }
    
    func disconnect() {
        isIntentionalDisconnect = true
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        isConnected = false
        connectionStatusText = "Disconnected"
    }
    
    // MARK: - Outgoing Packets
    func registerUser(_ user: KidUser) {
        let payload: [String: Any] = [
            "action": "register_user",
            "user": [
                "id": user.id.uuidString,
                "username": user.username,
                "displayName": user.displayName,
                "avatarSymbol": user.avatarSymbol,
                "avatarColorHex": user.avatarColorHex
            ]
        ]
        send(payload)
    }
    
    func broadcastInviteCode(_ code: String, creator: KidUser) {
        let payload: [String: Any] = [
            "action": "create_invite_code",
            "code": code,
            "creator": [
                "id": creator.id.uuidString,
                "username": creator.username,
                "displayName": creator.displayName,
                "avatarSymbol": creator.avatarSymbol,
                "avatarColorHex": creator.avatarColorHex
            ]
        ]
        send(payload)
    }
    
    func redeemInviteCode(_ code: String, redeemer: KidUser) {
        let payload: [String: Any] = [
            "action": "redeem_invite_code",
            "code": code,
            "redeemer": [
                "id": redeemer.id.uuidString,
                "username": redeemer.username,
                "displayName": redeemer.displayName,
                "avatarSymbol": redeemer.avatarSymbol,
                "avatarColorHex": redeemer.avatarColorHex
            ]
        ]
        send(payload)
    }
    
    func sendChatMessage(_ message: ChatMessage) {
        let payload: [String: Any] = [
            "action": "send_message",
            "message": [
                "id": message.id.uuidString,
                "senderId": message.senderId.uuidString,
                "receiverId": message.receiverId.uuidString,
                "type": message.type.rawValue,
                "textContent": message.textContent,
                "audioDuration": message.audioDuration as Any,
                "stickerName": message.stickerName as Any,
                "timestamp": message.timestamp.timeIntervalSince1970,
                "isFlagged": message.isFlagged
            ]
        ]
        send(payload)
    }
    
    func sendCallSignal(action: String, friendId: UUID) {
        let payload: [String: Any] = [
            "action": action, // "call_start" or "call_end"
            "friendId": friendId.uuidString
        ]
        send(payload)
    }
    
    private func send(_ dictionary: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: dictionary),
              let jsonString = String(data: data, encoding: .utf8) else {
            return
        }
        
        let message = URLSessionWebSocketTask.Message.string(jsonString)
        webSocketTask?.send(message) { error in
            if let error = error {
                print("⚠️ WebSocket send failed: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Incoming Message Listener
    private func listenForMessages() {
        webSocketTask?.receive { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                switch result {
                case .failure(let error):
                    print("⚠️ WebSocket receive error: \(error.localizedDescription)")
                    self.isConnected = false
                    self.connectionStatusText = "Connection lost. Reconnecting..."
                    if !self.isIntentionalDisconnect {
                        try? await Task.sleep(nanoseconds: 3_000_000_000)
                        self.connect()
                    }
                case .success(let message):
                    switch message {
                    case .string(let text):
                        self.handleIncomingJson(text)
                    case .data(let data):
                        if let text = String(data: data, encoding: .utf8) {
                            self.handleIncomingJson(text)
                        }
                    @unknown default:
                        break
                    }
                    
                    // Continue receiving loop
                    self.listenForMessages()
                }
            }
        }
    }
    
    private func handleIncomingJson(_ text: String) {
        guard let data = text.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let action = dict["action"] as? String,
              let engine = self.liveEngine else {
            return
        }
        
        switch action {
        case "registered_success":
            self.isConnected = true
            self.connectionStatusText = "Cloud Connected 🟢"
            
        case "incoming_message":
            if let msgDict = dict["message"] as? [String: Any] {
                self.handleIncomingChatMessage(msgDict, engine: engine)
            }
            
        case "friend_paired_notification":
            // Phone 1 received notification that Phone 2 redeemed its code!
            if let friendDict = dict["friend"] as? [String: Any],
               let friendIdStr = friendDict["id"] as? String,
               let friendUUID = UUID(uuidString: friendIdStr) {
                let displayName = friendDict["displayName"] as? String ?? "Friend"
                let username = friendDict["username"] as? String ?? "user"
                let symbol = friendDict["avatarSymbol"] as? String ?? "person.fill"
                let color = friendDict["avatarColorHex"] as? String ?? "#70A1FF"
                
                let newContact = FriendContact(
                    friendUserId: friendUUID,
                    friendUsername: username,
                    displayName: displayName,
                    avatarSymbol: symbol,
                    avatarColorHex: color,
                    isOnline: true,
                    lastMessagePreview: "Connected live! 🎉",
                    lastMessageTimeStr: "Just now"
                )
                
                if !engine.friends.contains(where: { $0.friendUserId == friendUUID }) {
                    engine.friends.insert(newContact, at: 0)
                    engine.saveChatData()
                }
                engine.systemNotificationMessage = "🎉 \(displayName) paired via your 6-digit code!"
            }
            
        case "call_start":
            if let friendIdStr = dict["friendId"] as? String,
               let fId = UUID(uuidString: friendIdStr),
               let friend = engine.friends.first(where: { $0.friendUserId == fId || $0.id == fId }) {
                engine.startVideoCall(with: friend)
            }
            
        case "call_end":
            engine.endVideoCall()
            engine.endAudioCall()
            
        default:
            break
        }
    }
    
    private func handleIncomingChatMessage(_ dict: [String: Any], engine: MockLiveEngine) {
        guard let idStr = dict["id"] as? String,
              let id = UUID(uuidString: idStr),
              let senderIdStr = dict["senderId"] as? String,
              let senderId = UUID(uuidString: senderIdStr),
              let receiverIdStr = dict["receiverId"] as? String,
              let receiverId = UUID(uuidString: receiverIdStr),
              let typeStr = dict["type"] as? String,
              let type = MessageType(rawValue: typeStr),
              let textContent = dict["textContent"] as? String else {
            return
        }
        
        let audioDuration = dict["audioDuration"] as? Double
        let stickerName = dict["stickerName"] as? String
        let timestampSeconds = dict["timestamp"] as? Double ?? Date().timeIntervalSince1970
        let isFlagged = dict["isFlagged"] as? Bool ?? false
        
        let newMsg = ChatMessage(
            id: id,
            senderId: senderId,
            receiverId: receiverId,
            type: type,
            textContent: textContent,
            audioDuration: audioDuration,
            stickerName: stickerName,
            timestamp: Date(timeIntervalSince1970: timestampSeconds),
            isRead: true,
            isFlagged: isFlagged
        )
        
        // Find existing friend contact or create one
        var targetFriend = engine.friends.first(where: { $0.friendUserId == senderId || $0.id == senderId })
        if targetFriend == nil {
            let autoFriend = FriendContact(
                friendUserId: senderId,
                friendUsername: "friend",
                displayName: "Friend",
                avatarSymbol: "person.fill",
                avatarColorHex: "#70A1FF"
            )
            engine.friends.insert(autoFriend, at: 0)
            targetFriend = autoFriend
        }
        
        guard let friendContact = targetFriend else { return }
        
        if engine.messagesByFriendId[friendContact.id] == nil {
            engine.messagesByFriendId[friendContact.id] = []
        }
        
        // Avoid duplicate message IDs
        if !(engine.messagesByFriendId[friendContact.id]?.contains(where: { $0.id == id }) ?? false) {
            engine.messagesByFriendId[friendContact.id]?.append(newMsg)
            
            if let idx = engine.friends.firstIndex(where: { $0.id == friendContact.id }) {
                engine.friends[idx].lastMessagePreview = type == .audio ? "🎙️ Voice Note" : (type == .sticker ? "🐱 Sticker" : textContent)
                engine.friends[idx].lastMessageTimeStr = "Just now"
            }
            engine.saveChatData()
        }
    }
}

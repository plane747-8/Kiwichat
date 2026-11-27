import Foundation
import SwiftUI
import Combine

// MARK: - Cloud Data Transfer Objects (DTOs) for Firestore & Backend
struct CloudUserDTO: Codable {
    let id: String
    let username: String
    let displayName: String
    let avatarSymbol: String
    let avatarColorHex: String
    let parentEmail: String
    let parentPinHash: String
    let wordFilterSeverity: String
    let enableVoiceNotes: Bool
    let enableVideoCalls: Bool
    let bedtimeLockActive: Bool
    let requirePinForFriends: Bool
    let createdAt: TimeInterval
}

struct CloudInviteCodeDTO: Codable {
    let code: String
    let creatorUserId: String
    let creatorUsername: String
    let creatorDisplayName: String
    let creatorAvatarSymbol: String
    let creatorAvatarColorHex: String
    let createdAt: TimeInterval
    let expiresAt: TimeInterval
    var isUsed: Bool
}

struct CloudMessageDTO: Codable {
    let id: String
    let senderId: String
    let receiverId: String
    let type: String // "text", "audio", "sticker"
    let textContent: String
    let audioDuration: Double?
    let stickerName: String?
    let timestamp: TimeInterval
    let isFlagged: Bool
}

// MARK: - CloudChatManager
// Provides cloud database architecture & Firestore synchronization logic
@MainActor
final class CloudChatManager: ObservableObject {
    static let shared = CloudChatManager()
    
    @Published var isConnectedToCloud: Bool = false
    @Published var cloudSyncStatus: String = "Ready to connect Firebase"
    
    private init() {}
    
    // Firestore Collection Names
    enum Collections {
        static let users = "users"
        static let inviteCodes = "inviteCodes"
        static let chats = "chats"
        static let messages = "messages"
        static let flaggedIncidents = "flaggedIncidents"
    }
    
    // Helper to generate deterministic chat room ID between two users
    static func chatRoomId(userA: String, userB: String) -> String {
        return userA < userB ? "\(userA)_\(userB)" : "\(userB)_\(userA)"
    }
}

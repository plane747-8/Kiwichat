import Foundation
import SwiftUI

// MARK: - Message Type
enum MessageType: String, Codable {
    case text
    case audio
    case sticker
    case reaction
    case callNotice
}

// MARK: - Word Filter Severity
enum WordFilterSeverity: String, CaseIterable, Codable, Identifiable {
    case standard = "Standard"
    case strict = "Strict"
    case maximum = "Maximum"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .standard: return "shield"
        case .strict: return "shield.lefthalf.filled"
        case .maximum: return "shield.fill"
        }
    }
    
    var summary: String {
        switch self {
        case .standard: return "Blocks bad language & personal grooming phrases"
        case .strict: return "Also blocks links, phone numbers & social media apps"
        case .maximum: return "Highest shield: blocks all numbers, addresses & unkind words"
        }
    }
}

// MARK: - Chat Message Model
struct ChatMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let senderId: UUID
    let receiverId: UUID
    let type: MessageType
    var textContent: String
    var audioDuration: Double?
    var stickerName: String?
    let timestamp: Date
    var isRead: Bool
    var isFlagged: Bool
    var reactionEmoji: String?

    init(
        id: UUID = UUID(),
        senderId: UUID,
        receiverId: UUID,
        type: MessageType = .text,
        textContent: String = "",
        audioDuration: Double? = nil,
        stickerName: String? = nil,
        timestamp: Date = Date(),
        isRead: Bool = true,
        isFlagged: Bool = false,
        reactionEmoji: String? = nil
    ) {
        self.id = id
        self.senderId = senderId
        self.receiverId = receiverId
        self.type = type
        self.textContent = textContent
        self.audioDuration = audioDuration
        self.stickerName = stickerName
        self.timestamp = timestamp
        self.isRead = isRead
        self.isFlagged = isFlagged
        self.reactionEmoji = reactionEmoji
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: timestamp)
    }
}

// MARK: - Friend Contact Model
struct FriendContact: Identifiable, Codable, Equatable {
    let id: UUID
    let friendUserId: UUID
    var friendUsername: String
    var displayName: String
    var avatarSymbol: String
    var avatarColorHex: String
    var isOnline: Bool
    var lastMessagePreview: String
    var lastMessageTimeStr: String
    var unreadCount: Int
    var isApprovedByParent: Bool
    var isBlocked: Bool
    var isChatPaused: Bool
    
    init(
        id: UUID = UUID(),
        friendUserId: UUID,
        friendUsername: String,
        displayName: String,
        avatarSymbol: String = "person.crop.circle.fill",
        avatarColorHex: String = "#70A1FF",
        isOnline: Bool = true,
        lastMessagePreview: String = "",
        lastMessageTimeStr: String = "Just now",
        unreadCount: Int = 0,
        isApprovedByParent: Bool = true,
        isBlocked: Bool = false,
        isChatPaused: Bool = false
    ) {
        self.id = id
        self.friendUserId = friendUserId
        self.friendUsername = friendUsername
        self.displayName = displayName
        self.avatarSymbol = avatarSymbol
        self.avatarColorHex = avatarColorHex
        self.isOnline = isOnline
        self.lastMessagePreview = lastMessagePreview
        self.lastMessageTimeStr = lastMessageTimeStr
        self.unreadCount = unreadCount
        self.isApprovedByParent = isApprovedByParent
        self.isBlocked = isBlocked
        self.isChatPaused = isChatPaused
    }
}

// MARK: - 6-Digit One-Time Invite Code Model
struct InviteCode: Identifiable, Codable {
    let id: UUID
    let code: String
    let creatorUserId: UUID
    let creatorUsername: String
    let creatorDisplayName: String
    let creatorAvatarSymbol: String
    let createdAt: Date
    let expiresAt: Date
    var isUsed: Bool
    
    init(
        id: UUID = UUID(),
        code: String,
        creatorUserId: UUID,
        creatorUsername: String,
        creatorDisplayName: String,
        creatorAvatarSymbol: String,
        createdAt: Date = Date(),
        expiresAt: Date = Date().addingTimeInterval(15 * 60),
        isUsed: Bool = false
    ) {
        self.id = id
        self.code = code
        self.creatorUserId = creatorUserId
        self.creatorUsername = creatorUsername
        self.creatorDisplayName = creatorDisplayName
        self.creatorAvatarSymbol = creatorAvatarSymbol
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.isUsed = isUsed
    }
    
    var isExpired: Bool {
        return Date() > expiresAt
    }
}

// MARK: - Parent Safety Settings Model
struct ParentSafetySettings: Codable, Equatable {
    var parentPin: String
    var parentEmail: String
    var enableWordFilter: Bool
    var filterSeverity: WordFilterSeverity
    var requirePinForFriends: Bool
    var enableVoiceNotes: Bool
    var enableVideoCalls: Bool
    var bedtimeLockActive: Bool
    var bedtimeStartHour: Int
    var bedtimeEndHour: Int
    var customBlockedWords: [String]
    
    init(
        parentPin: String = "1234",
        parentEmail: String = "parent@family.com",
        enableWordFilter: Bool = true,
        filterSeverity: WordFilterSeverity = .strict,
        requirePinForFriends: Bool = false,
        enableVoiceNotes: Bool = true,
        enableVideoCalls: Bool = true,
        bedtimeLockActive: Bool = false,
        bedtimeStartHour: Int = 20,
        bedtimeEndHour: Int = 7,
        customBlockedWords: [String] = []
    ) {
        self.parentPin = parentPin
        self.parentEmail = parentEmail
        self.enableWordFilter = enableWordFilter
        self.filterSeverity = filterSeverity
        self.requirePinForFriends = requirePinForFriends
        self.enableVoiceNotes = enableVoiceNotes
        self.enableVideoCalls = enableVideoCalls
        self.bedtimeLockActive = bedtimeLockActive
        self.bedtimeStartHour = bedtimeStartHour
        self.bedtimeEndHour = bedtimeEndHour
        self.customBlockedWords = customBlockedWords
    }
}

// MARK: - Kid User Profile Model
struct KidUser: Identifiable, Codable, Equatable {
    let id: UUID
    var username: String
    var displayName: String
    var avatarSymbol: String
    var avatarColorHex: String
    var parentSettings: ParentSafetySettings
    
    init(
        id: UUID = UUID(),
        username: String,
        displayName: String,
        avatarSymbol: String = "face.smiling.fill",
        avatarColorHex: String = "#FF6B81",
        parentSettings: ParentSafetySettings = ParentSafetySettings()
    ) {
        self.id = id
        self.username = username
        self.displayName = displayName
        self.avatarSymbol = avatarSymbol
        self.avatarColorHex = avatarColorHex
        self.parentSettings = parentSettings
    }
}

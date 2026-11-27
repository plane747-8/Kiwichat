import Foundation
import SwiftUI
import Combine

// MARK: - Backend Service Protocol
// Allows KiwiChat to switch seamlessly between Local Mock Engine and Firebase / Supabase Cloud Backend
protocol LiveChatServiceProtocol: ObservableObject {
    var currentUser: KidUser { get set }
    var friends: [FriendContact] { get set }
    var pendingFriendInvites: [FriendContact] { get set }
    var messagesByFriendId: [UUID: [ChatMessage]] { get set }
    var flaggedIncidents: [FlaggedIncident] { get set }
    var isAuthenticated: Bool { get set }
    var systemNotificationMessage: String? { get set }
    
    func loginKidUser(username: String, password: String) async throws
    func registerNewKidUser(username: String, displayName: String, avatarSymbol: String, avatarColorHex: String, parentPin: String, parentEmail: String) async throws
    func logoutUser()
    
    func generateInviteCode() async throws -> InviteCode
    func redeemInviteCode(_ code: String) async throws -> (success: Bool, message: String)
    func sendMessage(to friendId: UUID, text: String, type: MessageType, audioDuration: Double?, stickerName: String?) async throws
    
    func approveFriendInvite(inviteId: UUID) async throws
    func rejectFriendInvite(inviteId: UUID) async throws
    func togglePauseChat(for friendId: UUID) async throws
    func toggleBlockContact(for friendId: UUID) async throws
    func removeContact(for friendId: UUID) async throws
    
    func dismissFlaggedIncident(id: UUID)
    func clearAllFlaggedIncidents()
}

import SwiftUI

struct ParentControlView: View {
    @EnvironmentObject var engine: MockLiveEngine
    @ObservedObject var socketClient = KiwiWebSocketClient.shared
    @Environment(\.dismiss) var dismiss
    
    // Lock / Unlock State
    @State private var enteredPin: String = ""
    @State private var isUnlocked: Bool = false
    @State private var errorMessage: String? = nil
    
    // Change PIN State
    @State private var showChangePinSheet: Bool = false
    @State private var newPin: String = ""
    @State private var confirmNewPin: String = ""
    @State private var pinChangeError: String? = nil
    @State private var pinChangeSuccess: Bool = false
    
    // Custom Blocked Words
    @State private var newCustomWord: String = ""
    
    // Unfriend / Block Confirmation
    @State private var friendToUnfriend: FriendContact? = nil
    @State private var showUnfriendAlert: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#F8FAFC").ignoresSafeArea()
                
                if !isUnlocked {
                    // MARK: - 1. 4-Digit Parent PIN Lock Overlay
                    pinLockOverlayView
                } else {
                    // MARK: - 2. Unlocked Parental Control Hub
                    unlockedDashboardView
                }
            }
            .navigationTitle(isUnlocked ? "Parental Control Hub 🛡️" : "Parent Verification")
            .navigationBarTitleDisplayMode(isUnlocked ? .inline : .inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isUnlocked ? "Lock & Exit" : "Close") {
                        isUnlocked = false
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                
                if isUnlocked {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                    }
                }
            }
            .sheet(isPresented: $showChangePinSheet) {
                changePinModalView
            }
            .alert(item: $friendToUnfriend) { friend in
                Alert(
                    title: Text("Unfriend \(friend.displayName)?"),
                    message: Text("This will remove \(friend.displayName) from \(engine.currentUser.displayName)'s friends list and delete the chat history."),
                    primaryButton: .destructive(Text("Unfriend")) {
                        engine.removeContact(for: friend.id)
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
    
    // MARK: - 4-Digit PIN Lock Overlay Screen
    private var pinLockOverlayView: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 20)
            
            ZStack {
                Circle()
                    .fill(Color(hex: "#5F27CD").opacity(0.12))
                    .frame(width: 90, height: 90)
                
                Image(systemName: "shield.lock.fill")
                    .font(.system(size: 46))
                    .foregroundColor(Color(hex: "#5F27CD"))
            }
            
            VStack(spacing: 6) {
                Text("Parent Verification 🛡️")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#1E293B"))
                
                Text("Enter your 4-digit Master PIN to manage settings")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Color(hex: "#64748B"))
                    .multilineTextAlignment(.center)
                
                Text("Default PIN: \(engine.currentUser.parentSettings.parentPin)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#5F27CD"))
                    .padding(.top, 2)
            }
            
            // Masked PIN Dots
            HStack(spacing: 18) {
                ForEach(0..<4, id: \.self) { idx in
                    Circle()
                        .fill(idx < enteredPin.count ? Color(hex: "#5F27CD") : Color(hex: "#CBD5E1"))
                        .frame(width: 18, height: 18)
                        .overlay(
                            Circle()
                                .stroke(Color(hex: "#5F27CD").opacity(0.3), lineWidth: idx < enteredPin.count ? 0 : 2)
                        )
                        .scaleEffect(idx < enteredPin.count ? 1.15 : 1.0)
                        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: enteredPin.count)
                }
            }
            .padding(.vertical, 8)
            
            if let err = errorMessage {
                Text(err)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.red)
                    .transition(.opacity)
            }
            
            // Numeric Keypad
            VStack(spacing: 16) {
                let rows = [
                    ["1", "2", "3"],
                    ["4", "5", "6"],
                    ["7", "8", "9"],
                    ["", "0", "⌫"]
                ]
                
                ForEach(rows, id: \.self) { row in
                    HStack(spacing: 24) {
                        ForEach(row, id: \.self) { key in
                            Button(action: {
                                handleKeyTap(key)
                            }) {
                                Text(key)
                                    .font(.system(size: 26, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(hex: "#1E293B"))
                                    .frame(width: 68, height: 68)
                                    .background(key.isEmpty ? Color.clear : Color.white)
                                    .clipShape(Circle())
                                    .shadow(color: key.isEmpty ? Color.clear : Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
                            }
                            .disabled(key.isEmpty)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Unlocked Dashboard Form
    private var unlockedDashboardView: some View {
        Form {
            // Summary Header Card
            Section {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: engine.currentUser.avatarColorHex))
                            .frame(width: 52, height: 52)
                        
                        Image(systemName: engine.currentUser.avatarSymbol)
                            .font(.system(size: 26))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text("\(engine.currentUser.displayName)'s Account")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "#1E293B"))
                        
                        Text("Parent Contact: \(engine.currentUser.parentSettings.parentEmail)")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(Color(hex: "#64748B"))
                    }
                    
                    Spacer()
                    
                    Button("Change PIN") {
                        newPin = ""
                        confirmNewPin = ""
                        pinChangeError = nil
                        pinChangeSuccess = false
                        showChangePinSheet = true
                    }
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#5F27CD"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(hex: "#5F27CD").opacity(0.1))
                    .clipShape(Capsule())
                }
                .padding(.vertical, 4)
            }
            
            // MARK: - Live 2-Phone Server Network Status
            Section(
                header: Label("Live 2-Phone Network 📡", systemImage: "antenna.radiowaves.left.and.right"),
                footer: Text("Run `python3 kiwi_server.py` on your Mac. Both iPhones connect to this IP for real-time messaging.")
            ) {
                HStack {
                    Text("Connection Status")
                        .font(.system(size: 14, design: .rounded))
                    Spacer()
                    Text(socketClient.connectionStatusText)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(socketClient.isConnected ? Color(hex: "#2ED573") : .orange)
                }
                
                HStack {
                    Text("Server IP:Port")
                        .font(.system(size: 14, design: .rounded))
                    Spacer()
                    TextField("192.168.254.90:8080", text: $socketClient.serverAddress)
                        .multilineTextAlignment(.trailing)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color(hex: "#5F27CD"))
                }
                
                Button(action: {
                    socketClient.connect()
                }) {
                    HStack {
                        Spacer()
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text(socketClient.isConnected ? "Reconnect Server" : "Connect to Server")
                        Spacer()
                    }
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#5F27CD"))
                }
            }
            
            // MARK: - Section 1: Contact Management Panel
            Section(header: Label("Pending Friend Invites (\(engine.pendingFriendInvites.count))", systemImage: "person.crop.circle.badge.plus")) {
                if engine.pendingFriendInvites.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(hex: "#2ED573"))
                        Text("No pending friend requests. All caught up!")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(Color(hex: "#64748B"))
                    }
                    .padding(.vertical, 4)
                } else {
                    ForEach(engine.pendingFriendInvites) { invite in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Color(hex: invite.avatarColorHex))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Image(systemName: invite.avatarSymbol)
                                            .font(.system(size: 20))
                                            .foregroundColor(.white)
                                    )
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(invite.displayName)
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                    Text("@\(invite.friendUsername)")
                                        .font(.system(size: 12, design: .rounded))
                                        .foregroundColor(Color(hex: "#64748B"))
                                }
                                
                                Spacer()
                                
                                Text(invite.lastMessageTimeStr)
                                    .font(.system(size: 11, design: .rounded))
                                    .foregroundColor(.gray)
                            }
                            
                            HStack(spacing: 12) {
                                Button(action: {
                                    engine.approveFriendInvite(inviteId: invite.id)
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.shield.fill")
                                        Text("Approve")
                                    }
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Color(hex: "#2ED573"))
                                    .cornerRadius(12)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: {
                                    engine.rejectFriendInvite(inviteId: invite.id)
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "xmark.circle")
                                        Text("Decline")
                                    }
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(hex: "#EF4444"))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Color(hex: "#FEE2E2"))
                                    .cornerRadius(12)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            
            Section(header: Label("Connected Contacts (\(engine.friends.count))", systemImage: "person.2.fill")) {
                if engine.friends.isEmpty {
                    Text("No friends connected yet.")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(.gray)
                } else {
                    ForEach(engine.friends) { friend in
                        VStack(spacing: 10) {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Color(hex: friend.avatarColorHex))
                                    .frame(width: 42, height: 42)
                                    .overlay(
                                        Image(systemName: friend.avatarSymbol)
                                            .font(.system(size: 20))
                                            .foregroundColor(.white)
                                    )
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Text(friend.displayName)
                                            .font(.system(size: 16, weight: .bold, design: .rounded))
                                        
                                        if friend.isBlocked {
                                            Text("BLOCKED")
                                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.red)
                                                .clipShape(Capsule())
                                        } else if friend.isChatPaused {
                                            Text("PAUSED")
                                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.orange)
                                                .clipShape(Capsule())
                                        }
                                    }
                                    
                                    Text("@\(friend.friendUsername)")
                                        .font(.system(size: 12, design: .rounded))
                                        .foregroundColor(Color(hex: "#64748B"))
                                }
                                
                                Spacer()
                            }
                            
                            // Management Controls: Pause Chat, Block/Unblock, Unfriend
                            HStack(spacing: 8) {
                                Button(action: {
                                    engine.togglePauseChat(for: friend.id)
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: friend.isChatPaused ? "play.fill" : "pause.fill")
                                        Text(friend.isChatPaused ? "Resume Chat" : "Pause Chat")
                                    }
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(friend.isChatPaused ? Color(hex: "#0284C7") : Color(hex: "#D97706"))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                    .background(friend.isChatPaused ? Color(hex: "#E0F2FE") : Color(hex: "#FEF3C7"))
                                    .cornerRadius(10)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: {
                                    engine.toggleBlockContact(for: friend.id)
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: friend.isBlocked ? "lock.open.fill" : "nosign")
                                        Text(friend.isBlocked ? "Unblock" : "Block")
                                    }
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(friend.isBlocked ? Color(hex: "#059669") : Color(hex: "#DC2626"))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                    .background(friend.isBlocked ? Color(hex: "#D1FAE5") : Color(hex: "#FEE2E2"))
                                    .cornerRadius(10)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: {
                                    friendToUnfriend = friend
                                    showUnfriendAlert = true
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "trash")
                                        Text("Unfriend")
                                    }
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(hex: "#6B7280"))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                    .background(Color(hex: "#F3F4F6"))
                                    .cornerRadius(10)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            
            // MARK: - Section 2: Safety Controls & Content Filters
            Section(header: Label("Safety Controls & Content Filters", systemImage: "slider.horizontal.3")) {
                Toggle("Active Safety Word Filter", isOn: $engine.currentUser.parentSettings.enableWordFilter)
                
                if engine.currentUser.parentSettings.enableWordFilter {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Filter Severity Level")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(hex: "#1E293B"))
                        
                        Picker("Severity", selection: $engine.currentUser.parentSettings.filterSeverity) {
                            ForEach(WordFilterSeverity.allCases) { tier in
                                Text(tier.rawValue).tag(tier)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        HStack(spacing: 6) {
                            Image(systemName: engine.currentUser.parentSettings.filterSeverity.icon)
                                .foregroundColor(Color(hex: "#5F27CD"))
                            Text(engine.currentUser.parentSettings.filterSeverity.summary)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(Color(hex: "#64748B"))
                        }
                        .padding(.top, 2)
                    }
                    .padding(.vertical, 4)
                }
                
                Toggle("Require Parent Approval for New Friends", isOn: $engine.currentUser.parentSettings.requirePinForFriends)
                
                Toggle("Allow AudiText Voice Notes 🎙️", isOn: $engine.currentUser.parentSettings.enableVoiceNotes)
                
                Toggle("Allow KidTime Video Calls 📹", isOn: $engine.currentUser.parentSettings.enableVideoCalls)
            }
            
            // Bedtime Quiet Hours
            Section(
                header: Label("Bedtime Quiet Hours Lock 🌙", systemImage: "moon.stars.fill"),
                footer: Text("When active, notifications are muted and text inputs are paused so your child gets healthy sleep.")
            ) {
                Toggle("Enable Bedtime Quiet Hours", isOn: $engine.currentUser.parentSettings.bedtimeLockActive)
                
                if engine.currentUser.parentSettings.bedtimeLockActive {
                    HStack {
                        Text("Quiet Hours Period")
                            .font(.system(size: 14, design: .rounded))
                        Spacer()
                        Text("8:00 PM – 7:00 AM")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "#5F27CD"))
                    }
                }
            }
            
            // Custom Blocked Words
            Section(
                header: Label("Custom Family Blocked Words", systemImage: "text.badge.xmark"),
                footer: Text("Add custom words or family rules that should always be censored.")
            ) {
                HStack {
                    TextField("Add custom blocked word...", text: $newCustomWord)
                        .font(.system(size: 14, design: .rounded))
                    
                    Button("Add") {
                        let trimmed = newCustomWord.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                        if !trimmed.isEmpty && !engine.currentUser.parentSettings.customBlockedWords.contains(trimmed) {
                            engine.currentUser.parentSettings.customBlockedWords.append(trimmed)
                            newCustomWord = ""
                        }
                    }
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#5F27CD"))
                    .disabled(newCustomWord.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                
                if !engine.currentUser.parentSettings.customBlockedWords.isEmpty {
                    ForEach(engine.currentUser.parentSettings.customBlockedWords, id: \.self) { word in
                        HStack {
                            Text(word)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                            Spacer()
                            Button(action: {
                                engine.currentUser.parentSettings.customBlockedWords.removeAll(where: { $0 == word })
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            
            // MARK: - Section 3: Flagged Message Log Viewer
            Section(header: Label("Flagged Incident Logs (\(engine.flaggedIncidents.count))", systemImage: "exclamationmark.triangle.fill")) {
                if engine.flaggedIncidents.isEmpty {
                    HStack(spacing: 10) {
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 22))
                            .foregroundColor(Color(hex: "#2ED573"))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("All Clear! 🛡️")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "#2ED573"))
                            Text("No suspicious messages or safety incidents reported.")
                                .font(.system(size: 12, design: .rounded))
                                .foregroundColor(Color(hex: "#64748B"))
                        }
                    }
                    .padding(.vertical, 6)
                } else {
                    ForEach(engine.flaggedIncidents) { incident in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(incident.senderName)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(hex: "#1E293B"))
                                
                                Spacer()
                                
                                Text(incident.timestamp.formatted(date: .abbreviated, time: .shortened))
                                    .font(.system(size: 11, design: .rounded))
                                    .foregroundColor(.gray)
                                
                                Button(action: {
                                    engine.dismissFlaggedIncident(id: incident.id)
                                }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.gray)
                                        .padding(4)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            Text("Reason: \(incident.flagReason)")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "#D97706"))
                            
                            HStack(alignment: .top, spacing: 4) {
                                Text("Original:")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundColor(Color(hex: "#64748B"))
                                Text("\"\(incident.originalMessage)\"")
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundColor(Color(hex: "#EF4444"))
                            }
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(hex: "#FEF2F2"))
                            .cornerRadius(8)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    Button(action: {
                        engine.clearAllFlaggedIncidents()
                    }) {
                        HStack {
                            Spacer()
                            Image(systemName: "trash")
                            Text("Clear All Incident Logs")
                            Spacer()
                        }
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.red)
                    }
                }
            }
            
            // Logout
            Section {
                Button(action: {
                    dismiss()
                    engine.logoutUser()
                }) {
                    HStack {
                        Spacer()
                        Image(systemName: "arrow.backward.circle.fill")
                        Text("Log Out Account")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                        Spacer()
                    }
                    .foregroundColor(.red)
                }
            }
        }
    }
    
    // MARK: - Change Master PIN Modal
    private var changePinModalView: some View {
        NavigationView {
            Form {
                Section(header: Text("Update Parent Master PIN")) {
                    SecureField("Enter New 4-Digit PIN", text: $newPin)
                        .keyboardType(.numberPad)
                    SecureField("Confirm New 4-Digit PIN", text: $confirmNewPin)
                        .keyboardType(.numberPad)
                }
                
                if let err = pinChangeError {
                    Text(err)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.red)
                }
                
                if pinChangeSuccess {
                    Text("Master PIN updated successfully! 🎉")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "#2ED573"))
                }
                
                Button("Save New PIN") {
                    saveNewPin()
                }
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "#5F27CD"))
            }
            .navigationTitle("Change Master PIN")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        showChangePinSheet = false
                    }
                }
            }
        }
    }
    
    // MARK: - Handlers
    private func handleKeyTap(_ key: String) {
        if key == "⌫" {
            if !enteredPin.isEmpty {
                enteredPin.removeLast()
            }
        } else if enteredPin.count < 4 {
            enteredPin.append(key)
            if enteredPin.count == 4 {
                if enteredPin == engine.currentUser.parentSettings.parentPin {
                    withAnimation {
                        isUnlocked = true
                        errorMessage = nil
                    }
                } else {
                    errorMessage = "Incorrect PIN."
                    enteredPin = ""
                }
            }
        }
    }
    
    private func saveNewPin() {
        guard newPin.count == 4, CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: newPin)) else {
            pinChangeError = "PIN must be exactly 4 digits."
            return
        }
        guard newPin == confirmNewPin else {
            pinChangeError = "PINs do not match."
            return
        }
        engine.currentUser.parentSettings.parentPin = newPin
        pinChangeError = nil
        pinChangeSuccess = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            showChangePinSheet = false
        }
    }
}

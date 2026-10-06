import SwiftUI

struct ParentControlView: View {
    @EnvironmentObject var engine: MockLiveEngine
    @Environment(\.dismiss) var dismiss
    
    @State private var enteredPin: String = ""
    @State private var isUnlocked: Bool = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        NavigationView {
            VStack {
                if !isUnlocked {
                    // MARK: - 4-Digit Parent PIN Unlock Screen
                    VStack(spacing: 24) {
                        Image(systemName: "shield.lock.fill")
                            .font(.system(size: 64))
                            .foregroundColor(Color(hex: "#5F27CD"))
                            .padding(.top, 40)
                        
                        VStack(spacing: 6) {
                            Text("Parent Dashboard 🛡️")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "#1E293B"))
                            
                            Text("Enter 4-Digit Parent Master PIN")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(Color(hex: "#64748B"))
                            
                            Text("(Default PIN for testing: 1234)")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(Color(hex: "#5F27CD"))
                        }
                        
                        // Masked PIN Dots
                        HStack(spacing: 16) {
                            ForEach(0..<4, id: \.self) { idx in
                                Circle()
                                    .fill(idx < enteredPin.count ? Color(hex: "#5F27CD") : Color(hex: "#CBD5E1"))
                                    .frame(width: 18, height: 18)
                            }
                        }
                        .padding(.vertical, 12)
                        
                        if let err = errorMessage {
                            Text(err)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.red)
                        }
                        
                        // Custom Keypad
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
                                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                                .foregroundColor(Color(hex: "#1E293B"))
                                                .frame(width: 64, height: 64)
                                                .background(Color(hex: "#F1F5F9"))
                                                .clipShape(Circle())
                                                .opacity(key.isEmpty ? 0 : 1)
                                        }
                                        .disabled(key.isEmpty)
                                    }
                                }
                            }
                        }
                        .padding(.top, 10)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                } else {
                    // MARK: - Unlocked Parent Controls Dashboard
                    Form {
                        Section(header: Text("🛡️ Safety & Content Filters")) {
                            Toggle("Safety Word & Personal Info Filter", isOn: $engine.currentUser.parentSettings.enableWordFilter)
                            Toggle("Require Parent PIN for Friends", isOn: $engine.currentUser.parentSettings.requirePinForFriends)
                            Toggle("Allow AudiText Voice Notes", isOn: $engine.currentUser.parentSettings.enableVoiceNotes)
                            Toggle("Allow KidTime Video Calls", isOn: $engine.currentUser.parentSettings.enableVideoCalls)
                            Toggle("Bedtime Quiet Hours Lock (8 PM - 7 AM)", isOn: $engine.currentUser.parentSettings.bedtimeLockActive)
                        }
                        
                        // Flagged Safety Incident Log Section
                        Section(header: Text("⚠️ Flagged Safety Incident Logs (\(engine.flaggedIncidents.count))")) {
                            if engine.flaggedIncidents.isEmpty {
                                Text("No safety incidents reported. Clean chat thread! 🎉")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundColor(.gray)
                            } else {
                                ForEach(engine.flaggedIncidents) { incident in
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(incident.senderName)
                                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                            Spacer()
                                            Text(incident.timestamp.formatted(date: .omitted, time: .shortened))
                                                .font(.system(size: 11, design: .rounded))
                                                .foregroundColor(.gray)
                                        }
                                        Text(incident.flagReason)
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .foregroundColor(.orange)
                                        Text("Original: \"\(incident.originalMessage)\"")
                                            .font(.system(size: 13, design: .rounded))
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                        
                        Section(header: Text("👥 Connected Friends (\(engine.friends.count))")) {
                            ForEach(engine.friends) { friend in
                                HStack {
                                    Circle()
                                        .fill(Color(hex: friend.avatarColorHex))
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Image(systemName: friend.avatarSymbol)
                                                .foregroundColor(.white)
                                        )
                                    
                                    VStack(alignment: .leading) {
                                        Text(friend.displayName)
                                            .font(.system(size: 16, weight: .bold))
                                        Text("@\(friend.friendUsername)")
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    Button("Block") {
                                        if let idx = engine.friends.firstIndex(where: { $0.id == friend.id }) {
                                            engine.friends.remove(at: idx)
                                        }
                                    }
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(12)
                                }
                            }
                        }
                        
                        Section(header: Text("🔄 Switch Active Kid Profile (For Testing)")) {
                            ForEach(engine.availableDemoUsers) { user in
                                Button(action: {
                                    engine.switchUser(to: user)
                                    dismiss()
                                }) {
                                    HStack {
                                        Circle()
                                            .fill(Color(hex: user.avatarColorHex))
                                            .frame(width: 32, height: 32)
                                            .overlay(
                                                Image(systemName: user.avatarSymbol)
                                                    .foregroundColor(.white)
                                            )
                                        
                                        Text("\(user.displayName) (@\(user.username))")
                                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                                            .foregroundColor(Color(hex: "#1E293B"))
                                        
                                        Spacer()
                                        
                                        if engine.currentUser.id == user.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(Color(hex: "#2ED573"))
                                        }
                                    }
                                }
                            }
                        }
                        
                        Section {
                            Button(action: {
                                dismiss()
                                engine.logoutUser()
                            }) {
                                HStack {
                                    Spacer()
                                    Text("Log Out of Account")
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundColor(.red)
                                    Spacer()
                                }
                            }
                        }
                    }
                    .navigationTitle("Parent Hub 🛡️")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                dismiss()
                            }
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func handleKeyTap(_ key: String) {
        if key == "⌫" {
            if !enteredPin.isEmpty {
                enteredPin.removeLast()
            }
        } else if enteredPin.count < 4 {
            enteredPin.append(key)
            if enteredPin.count == 4 {
                if enteredPin == engine.currentUser.parentSettings.parentPin {
                    isUnlocked = true
                    errorMessage = nil
                } else {
                    errorMessage = "Incorrect PIN. Try 1234."
                    enteredPin = ""
                }
            }
        }
    }
}

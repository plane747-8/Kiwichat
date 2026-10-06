import SwiftUI

struct AuthView: View {
    @EnvironmentObject var engine: MockLiveEngine
    
    @State private var isLoginMode: Bool = true
    
    // Form Inputs
    @State private var usernameInput: String = ""
    @State private var passwordInput: String = ""
    @State private var displayNameInput: String = ""
    @State private var parentEmailInput: String = ""
    @State private var parentPinInput: String = "1234"
    @State private var selectedAvatarSymbol: String = "face.smiling.fill"
    @State private var selectedAvatarColorHex: String = "#FF6B81"
    
    @State private var errorMessage: String? = nil
    
    let avatarSymbols = [
        "face.smiling.fill", "person.crop.circle.fill", "sparkles",
        "star.fill", "bolt.fill", "heart.fill", "crown.fill", "pawprint.fill"
    ]
    
    let avatarColors = [
        "#FF6B81", "#FF758C", "#2ED573", "#FF9F43", "#54a0ff", "#9c88ff", "#38BDF8"
    ]
    
    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                colors: [Color(hex: "#F8FAFC"), Color(hex: "#EEF2FF")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Logo & Mascot Header
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "#48DBFB"))
                                .frame(width: 72, height: 72)
                                .shadow(color: Color(hex: "#48DBFB").opacity(0.4), radius: 10, x: 0, y: 5)
                            
                            Image(systemName: "bird.fill")
                                .font(.system(size: 42))
                                .foregroundColor(.white)
                        }
                        
                        Text("KiwiChat")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "#5F27CD"))
                        
                        Text("Safe Live Messaging for Kids 🛡️")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(hex: "#64748B"))
                    }
                    .padding(.top, 24)
                    
                    // MARK: - Quick Profile Switcher Toolbar (For Testing)
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "hand.tap.fill")
                                .foregroundColor(Color(hex: "#5F27CD"))
                            Text("Quick Demo Logins (1-Tap Test):")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "#475569"))
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(engine.availableDemoUsers) { user in
                                    Button(action: {
                                        usernameInput = user.username
                                        passwordInput = "1234"
                                        engine.loginKidUser(username: user.username, password: "1234")
                                    }) {
                                        HStack(spacing: 6) {
                                            Circle()
                                                .fill(Color(hex: user.avatarColorHex))
                                                .frame(width: 26, height: 26)
                                                .overlay(
                                                    Image(systemName: user.avatarSymbol)
                                                        .font(.system(size: 12))
                                                        .foregroundColor(.white)
                                                )
                                            
                                            Text(user.displayName)
                                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                                .foregroundColor(Color(hex: "#1E293B"))
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.white)
                                        .cornerRadius(20)
                                        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                                    }
                                }
                            }
                        }
                    }
                    .padding(14)
                    .background(Color(hex: "#E0E7FF"))
                    .cornerRadius(18)
                    .padding(.horizontal, 20)
                    
                    // MARK: - Auth Form Card
                    VStack(spacing: 18) {
                        // Segment Picker: Login vs Sign Up
                        Picker("Auth Mode", selection: $isLoginMode) {
                            Text("Kid Login").tag(true)
                            Text("New Kid Account").tag(false)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        if let err = errorMessage {
                            Text(err)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.red)
                        }
                        
                        VStack(spacing: 14) {
                            if !isLoginMode {
                                // Display Nickname Input
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Kid Display Nickname")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundColor(Color(hex: "#64748B"))
                                    
                                    TextField("e.g. Leo", text: $displayNameInput)
                                        .font(.system(size: 16, design: .rounded))
                                        .padding(12)
                                        .background(Color(hex: "#F8FAFC"))
                                        .cornerRadius(12)
                                }
                                
                                // Avatar Picker
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Choose Avatar & Color")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundColor(Color(hex: "#64748B"))
                                    
                                    HStack(spacing: 12) {
                                        ForEach(avatarColors, id: \.self) { hex in
                                            Circle()
                                                .fill(Color(hex: hex))
                                                .frame(width: 32, height: 32)
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.white, lineWidth: selectedAvatarColorHex == hex ? 3 : 0)
                                                )
                                                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                                                .onTapGesture {
                                                    selectedAvatarColorHex = hex
                                                }
                                        }
                                    }
                                }
                            }
                            
                            // Username Input
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Kid Username")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(hex: "#64748B"))
                                
                                TextField("e.g. leo_star", text: $usernameInput)
                                    .font(.system(size: 16, design: .rounded))
                                    .padding(12)
                                    .background(Color(hex: "#F8FAFC"))
                                    .cornerRadius(12)
                            }
                            
                            // Password Input
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Password")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(hex: "#64748B"))
                                
                                SecureField("••••••••", text: $passwordInput)
                                    .font(.system(size: 16, design: .rounded))
                                    .padding(12)
                                    .background(Color(hex: "#F8FAFC"))
                                    .cornerRadius(12)
                            }
                            
                            if !isLoginMode {
                                Divider()
                                    .padding(.vertical, 4)
                                
                                // Initial Parent Setup Fields
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "shield.fill")
                                            .foregroundColor(Color(hex: "#2ED573"))
                                        Text("Parent Setup (Master Verification)")
                                            .font(.system(size: 13, weight: .bold, design: .rounded))
                                            .foregroundColor(Color(hex: "#2ED573"))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Parent Recovery Email")
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .foregroundColor(Color(hex: "#64748B"))
                                        
                                        TextField("parent@family.com", text: $parentEmailInput)
                                            .font(.system(size: 15, design: .rounded))
                                            .padding(12)
                                            .background(Color(hex: "#F8FAFC"))
                                            .cornerRadius(12)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Create 4-Digit Parent Master PIN")
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .foregroundColor(Color(hex: "#64748B"))
                                        
                                        SecureField("1234", text: $parentPinInput)
                                            .font(.system(size: 15, design: .monospaced))
                                            .padding(12)
                                            .background(Color(hex: "#F8FAFC"))
                                            .cornerRadius(12)
                                    }
                                }
                                .padding(12)
                                .background(Color(hex: "#F0FDF4"))
                                .cornerRadius(14)
                            }
                        }
                        
                        // Action Button
                        Button(action: {
                            handleAuthSubmit()
                        }) {
                            HStack {
                                Image(systemName: isLoginMode ? "arrow.right.circle.fill" : "person.badge.shield.checkmark.fill")
                                Text(isLoginMode ? "Kid Login 🚀" : "Create Safe Kid Account 🛡️")
                            }
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(hex: "#5F27CD"))
                            .cornerRadius(20)
                            .shadow(color: Color(hex: "#5F27CD").opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(24)
                    .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 40)
            }
        }
    }
    
    private func handleAuthSubmit() {
        errorMessage = nil
        if isLoginMode {
            guard !usernameInput.isEmpty else {
                errorMessage = "Please enter a username."
                return
            }
            engine.loginKidUser(username: usernameInput, password: passwordInput)
        } else {
            guard !usernameInput.isEmpty, !displayNameInput.isEmpty else {
                errorMessage = "Please enter both display name and username."
                return
            }
            guard parentPinInput.count == 4 else {
                errorMessage = "Parent Master PIN must be 4 digits."
                return
            }
            
            engine.registerNewKidUser(
                username: usernameInput,
                displayName: displayNameInput,
                avatarSymbol: selectedAvatarSymbol,
                avatarColorHex: selectedAvatarColorHex,
                parentPin: parentPinInput,
                parentEmail: parentEmailInput.isEmpty ? "parent@family.com" : parentEmailInput
            )
        }
    }
}

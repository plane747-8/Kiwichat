import SwiftUI

struct AuthView: View {
    @EnvironmentObject var engine: MockLiveEngine
    
    @State private var isLoginMode: Bool = false // Default to Sign Up for new users
    
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
                                .frame(width: 76, height: 76)
                                .shadow(color: Color(hex: "#48DBFB").opacity(0.4), radius: 10, x: 0, y: 5)
                            
                            Image(systemName: "bird.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.white)
                        }
                        
                        Text("KiwiChat")
                            .font(.system(size: 38, weight: .heavy, design: .rounded))
                            .foregroundColor(Color(hex: "#5F27CD"))
                        
                        Text("Good friends. Happy chats! 🛡️")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(hex: "#64748B"))
                    }
                    .padding(.top, 30)
                    
                    // MARK: - Auth Form Card
                    VStack(spacing: 20) {
                        // Mode Switcher: Sign Up vs Login
                        Picker("Account Mode", selection: $isLoginMode) {
                            Text("New Kid Account 🎉").tag(false)
                            Text("Kid Login 🚀").tag(true)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        if let err = errorMessage {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text(err)
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(.red)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.red.opacity(0.08))
                            .cornerRadius(10)
                            .transition(.opacity)
                        }
                        
                        VStack(spacing: 16) {
                            if !isLoginMode {
                                // Display Nickname Input
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Kid Display Nickname")
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundColor(Color(hex: "#64748B"))
                                    
                                    TextField("What should friends call you? (e.g. Leo)", text: $displayNameInput)
                                        .font(.system(size: 16, design: .rounded))
                                        .padding(12)
                                        .background(Color(hex: "#F8FAFC"))
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color(hex: "#E2E8F0"), lineWidth: 1)
                                        )
                                }
                                
                                // Avatar Picker
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Choose Avatar & Color")
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundColor(Color(hex: "#64748B"))
                                    
                                    // Symbol Picker
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 10) {
                                            ForEach(avatarSymbols, id: \.self) { sym in
                                                ZStack {
                                                    Circle()
                                                        .fill(selectedAvatarSymbol == sym ? Color(hex: selectedAvatarColorHex) : Color(hex: "#F1F5F9"))
                                                        .frame(width: 42, height: 42)
                                                    
                                                    Image(systemName: sym)
                                                        .font(.system(size: 20))
                                                        .foregroundColor(selectedAvatarSymbol == sym ? .white : Color(hex: "#64748B"))
                                                }
                                                .onTapGesture {
                                                    selectedAvatarSymbol = sym
                                                }
                                            }
                                        }
                                    }
                                    
                                    // Color Dots
                                    HStack(spacing: 12) {
                                        ForEach(avatarColors, id: \.self) { hex in
                                            Circle()
                                                .fill(Color(hex: hex))
                                                .frame(width: 30, height: 30)
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
                                    .padding(.top, 4)
                                }
                            }
                            
                            // Username Input
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Username")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(hex: "#64748B"))
                                
                                TextField("Choose a username (e.g. leo123)", text: $usernameInput)
                                    .font(.system(size: 16, design: .rounded))
                                    .textInputAutocapitalization(.never)
                                    .disableAutocorrection(true)
                                    .padding(12)
                                    .background(Color(hex: "#F8FAFC"))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color(hex: "#E2E8F0"), lineWidth: 1)
                                    )
                            }
                            
                            // Password Input
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Password")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(hex: "#64748B"))
                                
                                SecureField("Enter your password", text: $passwordInput)
                                    .font(.system(size: 16, design: .rounded))
                                    .padding(12)
                                    .background(Color(hex: "#F8FAFC"))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color(hex: "#E2E8F0"), lineWidth: 1)
                                    )
                            }
                            
                            if !isLoginMode {
                                Divider()
                                    .padding(.vertical, 4)
                                
                                // Initial Parent Setup Fields
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "shield.fill")
                                            .foregroundColor(Color(hex: "#2ED573"))
                                        Text("Parent Setup (Master Security)")
                                            .font(.system(size: 13, weight: .bold, design: .rounded))
                                            .foregroundColor(Color(hex: "#2ED573"))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Parent Recovery Email")
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .foregroundColor(Color(hex: "#64748B"))
                                        
                                        TextField("parent@family.com", text: $parentEmailInput)
                                            .font(.system(size: 15, design: .rounded))
                                            .keyboardType(.emailAddress)
                                            .textInputAutocapitalization(.never)
                                            .padding(12)
                                            .background(Color.white)
                                            .cornerRadius(10)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Create 4-Digit Parent PIN")
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .foregroundColor(Color(hex: "#64748B"))
                                        
                                        SecureField("1234", text: $parentPinInput)
                                            .font(.system(size: 16, design: .monospaced))
                                            .keyboardType(.numberPad)
                                            .padding(12)
                                            .background(Color.white)
                                            .cornerRadius(10)
                                    }
                                }
                                .padding(14)
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
                                Text(isLoginMode ? "Log In 🚀" : "Create Safe Account 🎉")
                            }
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(hex: "#5F27CD"))
                            .cornerRadius(20)
                            .shadow(color: Color(hex: "#5F27CD").opacity(0.35), radius: 8, x: 0, y: 4)
                        }
                    }
                    .padding(22)
                    .background(Color.white)
                    .cornerRadius(26)
                    .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 40)
            }
        }
    }
    
    private func handleAuthSubmit() {
        errorMessage = nil
        if isLoginMode {
            let res = engine.loginKidUser(username: usernameInput, password: passwordInput)
            if !res.success {
                errorMessage = res.message
            }
        } else {
            let res = engine.registerNewKidUser(
                username: usernameInput,
                password: passwordInput,
                displayName: displayNameInput,
                avatarSymbol: selectedAvatarSymbol,
                avatarColorHex: selectedAvatarColorHex,
                parentPin: parentPinInput,
                parentEmail: parentEmailInput
            )
            if !res.success {
                errorMessage = res.message
            }
        }
    }
}

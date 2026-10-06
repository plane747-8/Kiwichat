import SwiftUI

struct AddFriendView: View {
    @EnvironmentObject var engine: MockLiveEngine
    
    @State private var selectedSegment: Int = 0 // 0 = My 6-Digit Code, 1 = Enter Friend Code
    @State private var generatedCodeObj: InviteCode? = nil
    @State private var countdownSeconds: Int = 900 // 15 minutes
    @State private var timer: Timer? = nil
    @State private var isCopied: Bool = false
    
    // Code input digits
    @State private var inputDigits: [String] = Array(repeating: "", count: 6)
    @FocusState private var focusedIndex: Int?
    
    @State private var statusMessage: String? = nil
    @State private var isSuccess: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            // MARK: - Header
            VStack(spacing: 6) {
                Text("Add Friends 🔑")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#5F27CD"))
                
                Text("Zero phone numbers required! Use safe 6-digit codes.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Color(hex: "#64748B"))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 20)
            
            // MARK: - Segmented Picker
            Picker("Mode", selection: $selectedSegment) {
                Text("My 6-Digit Code").tag(0)
                Text("Enter Friend Code").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 24)
            
            if selectedSegment == 0 {
                // MARK: - Panel 0: My 6-Digit Code Generator
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        Text("Share this code in person with your friend:")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(Color(hex: "#475569"))
                        
                        if let invite = generatedCodeObj {
                            // Stylized Code Card
                            VStack(spacing: 14) {
                                HStack(spacing: 10) {
                                    let codeChars = Array(invite.code)
                                    ForEach(0..<codeChars.count, id: \.self) { idx in
                                        if idx == 3 {
                                            Text("-")
                                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                                .foregroundColor(Color(hex: "#94A3B8"))
                                        }
                                        Text(String(codeChars[idx]))
                                            .font(.system(size: 30, weight: .bold, design: .monospaced))
                                            .foregroundColor(Color(hex: "#5F27CD"))
                                            .frame(width: 42, height: 54)
                                            .background(Color(hex: "#F1F5F9"))
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color(hex: "#C084FC"), lineWidth: 2)
                                            )
                                    }
                                }
                                .padding(.vertical, 4)
                                
                                // Copy Button
                                Button(action: {
                                    copyCodeToClipboard(invite.code)
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: isCopied ? "checkmark.circle.fill" : "doc.on.doc.fill")
                                        Text(isCopied ? "Code Copied!" : "Copy Code")
                                    }
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(isCopied ? Color(hex: "#2ED573") : Color(hex: "#5F27CD"))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(isCopied ? Color(hex: "#E8FADF") : Color(hex: "#F3E8FF"))
                                    .clipShape(Capsule())
                                }
                            }
                            
                            // Circular Countdown Timer Ring Progress
                            ZStack {
                                Circle()
                                    .stroke(Color(hex: "#FFE4E6"), lineWidth: 6)
                                    .frame(width: 90, height: 90)
                                
                                Circle()
                                    .trim(from: 0.0, to: CGFloat(countdownSeconds) / 900.0)
                                    .stroke(Color(hex: "#FF6B81"), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                                    .frame(width: 90, height: 90)
                                    .rotationEffect(.degrees(-90))
                                
                                VStack(spacing: 2) {
                                    Text("\(countdownSeconds / 60):\(String(format: "%02d", countdownSeconds % 60))")
                                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                                        .foregroundColor(Color(hex: "#FF6B81"))
                                    
                                    Text("Expires")
                                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                                        .foregroundColor(Color(hex: "#94A3B8"))
                                }
                            }
                            .padding(.top, 8)
                        } else {
                            Button(action: {
                                generateNewCode()
                            }) {
                                HStack {
                                    Image(systemName: "sparkles")
                                    Text("Generate 6-Digit Code")
                                }
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 28)
                                .padding(.vertical, 16)
                                .background(Color(hex: "#5F27CD"))
                                .cornerRadius(24)
                                .shadow(color: Color(hex: "#5F27CD").opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                        }
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(24)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                    .padding(.horizontal, 20)
                    
                    if generatedCodeObj != nil {
                        Button("Generate Different Code") {
                            generateNewCode()
                        }
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "#5F27CD"))
                    }
                }
            } else {
                // MARK: - Panel 1: Enter Friend's 6-Digit Code
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        Text("Enter the 6-digit code your friend gave you:")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(Color(hex: "#475569"))
                        
                        // 6 Digit Text Fields
                        HStack(spacing: 8) {
                            ForEach(0..<6, id: \.self) { idx in
                                TextField("", text: $inputDigits[idx])
                                    #if os(iOS)
                                    .keyboardType(.numberPad)
                                    #endif
                                    .multilineTextAlignment(.center)
                                    .font(.system(size: 26, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color(hex: "#1E293B"))
                                    .frame(width: 44, height: 54)
                                    .background(Color(hex: "#F8FAFC"))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(focusedIndex == idx ? Color(hex: "#38BDF8") : Color(hex: "#CBD5E1"), lineWidth: 2)
                                    )
                                    .focused($focusedIndex, equals: idx)
                                    .onChange(of: inputDigits[idx]) { _, newValue in
                                        if newValue.count > 1 {
                                            inputDigits[idx] = String(newValue.prefix(1))
                                        }
                                        if !newValue.isEmpty && idx < 5 {
                                            focusedIndex = idx + 1
                                        }
                                        // Auto-redeem when 6th digit entered
                                        if inputDigits.joined().count == 6 {
                                            redeemCode()
                                        }
                                    }
                            }
                        }
                        .padding(.vertical, 8)
                        
                        if let msg = statusMessage {
                            Text(msg)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(isSuccess ? Color(hex: "#2ED573") : Color.red)
                        }
                        
                        // Redeem Button
                        Button(action: {
                            redeemCode()
                        }) {
                            HStack {
                                Image(systemName: "person.badge.plus")
                                Text("Connect Friend 🎉")
                            }
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(hex: "#38BDF8"))
                            .cornerRadius(24)
                            .shadow(color: Color(hex: "#38BDF8").opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                    }
                    .padding(24)
                    .background(Color.white)
                    .cornerRadius(24)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                    .padding(.horizontal, 20)
                }
            }
            
            Spacer()
        }
        .background(Color(hex: "#F8FAFC"))
        .onAppear {
            if generatedCodeObj == nil {
                generateNewCode()
            }
        }
    }
    
    private func copyCodeToClipboard(_ code: String) {
        #if os(iOS)
        UIPasteboard.general.string = code
        #endif
        isCopied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isCopied = false
        }
    }
    
    private func generateNewCode() {
        let newCode = engine.generateInviteCode()
        generatedCodeObj = newCode
        countdownSeconds = 900
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if countdownSeconds > 0 {
                countdownSeconds -= 1
            } else {
                timer?.invalidate()
            }
        }
    }
    
    private func redeemCode() {
        let codeStr = inputDigits.joined()
        let result = engine.redeemInviteCode(codeStr)
        statusMessage = result.message
        isSuccess = result.success
        if result.success {
            inputDigits = Array(repeating: "", count: 6)
        }
    }
}

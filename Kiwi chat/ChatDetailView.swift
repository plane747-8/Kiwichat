import SwiftUI

struct ChatDetailView: View {
    @EnvironmentObject var engine: MockLiveEngine
    let friend: FriendContact
    
    @State private var messageText: String = ""
    @State private var isRecordingAudio: Bool = false
    @State private var audioDurationCounter: Double = 0.0
    @State private var timer: Timer? = nil
    @State private var showStickerPicker: Bool = false
    
    var messages: [ChatMessage] {
        engine.messagesByFriendId[friend.id] ?? []
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Navigation Header (Matches Screenshot!)
            HStack(spacing: 12) {
                Button(action: {
                    engine.selectedFriendId = nil
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(hex: "#546E7A"))
                }
                
                // Avatar with Online Badge
                ZStack(alignment: .bottomTrailing) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: friend.avatarColorHex))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: friend.avatarSymbol)
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                    }
                    
                    if friend.isOnline {
                        Circle()
                            .fill(Color(hex: "#2ED573"))
                            .frame(width: 13, height: 13)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .offset(x: 1, y: 1)
                    }
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(friend.displayName)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "#1E293B"))
                    
                    Text(friend.isOnline ? "Online" : "Offline")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(friend.isOnline ? Color(hex: "#2ED573") : Color(hex: "#94A3B8"))
                }
                
                Spacer()
                
                // AudiText Phone Call Button
                Button(action: {
                    engine.startAudioCall(with: friend)
                }) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "#48DBFB"))
                        .padding(8)
                }
                
                // KidTime Video Call Button
                Button(action: {
                    engine.startVideoCall(with: friend)
                }) {
                    Image(systemName: "video.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color(hex: "#48DBFB"))
                        .padding(8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            
            Divider()
                .opacity(0.4)
            
            // MARK: - Message Thread ScrollView
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Safety Notice Shield Banner
                        HStack(spacing: 6) {
                            Image(systemName: "shield.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "#2ED573"))
                            
                            Text("KidChat Protected • Safe Friends Only 🛡️")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(Color(hex: "#2ED573"))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color(hex: "#E8FADF"))
                        .clipShape(Capsule())
                        .padding(.top, 8)
                        
                        ForEach(messages) { msg in
                            ChatMessageBubble(
                                message: msg,
                                isFromCurrentUser: msg.senderId == engine.currentUser.id,
                                friend: friend,
                                onToggleReaction: { emoji in
                                    // Add reaction emoji to message
                                }
                            )
                            .id(msg.id)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 16)
                }
                .background(Color(hex: "#F0F4F8"))
                .modifier(ScrollToBottomOnChange(count: messages.count, lastId: messages.last?.id, proxy: proxy))
            }
            
            // MARK: - Sticker Picker Drawer (If Active)
            if showStickerPicker {
                StickerPickerView(onSelectSticker: { sticker in
                    engine.sendMessage(to: friend.id, text: "Sticker", type: .sticker, stickerName: sticker)
                    showStickerPicker = false
                })
            }
            
            // MARK: - Audio Recording Bar (If Recording)
            if isRecordingAudio {
                HStack(spacing: 12) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.red)
                    
                    Text("Recording Voice Note: \(String(format: "%.1f", audioDurationCounter))s")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.red)
                    
                    Spacer()
                    
                    Button("Cancel") {
                        stopAudioRecording(send: false)
                    }
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.gray)
                    
                    Button("Send 🎙️") {
                        stopAudioRecording(send: true)
                    }
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color(hex: "#48DBFB"))
                    .cornerRadius(16)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(hex: "#FFF1F2"))
            } else {
                // MARK: - Standard Bottom Input Bar (Matches Screenshot!)
                HStack(spacing: 10) {
                    // + Button (Stickers / Mic)
                    Button(action: {
                        showStickerPicker.toggle()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "#38BDF8"))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "plus")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Text Input Bar with Smiley Face Icon
                    HStack(spacing: 8) {
                        TextField("Type a message...", text: $messageText)
                            .font(.system(size: 16, design: .rounded))
                            .foregroundColor(Color(hex: "#1E293B"))
                        
                        Button(action: {
                            messageText += " 😊"
                        }) {
                            Image(systemName: "face.smiling")
                                .font(.system(size: 22))
                                .foregroundColor(Color(hex: "#94A3B8"))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .cornerRadius(24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color(hex: "#E2E8F0"), lineWidth: 1.5)
                    )
                    
                    // Mic / Send Button
                    if messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        // Mic Button for AudiText Voice Notes
                        Button(action: {
                            startAudioRecording()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "#38BDF8"))
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            }
                        }
                    } else {
                        // Blue Send Button with White Airplane Icon
                        Button(action: {
                            let textToSend = messageText
                            messageText = ""
                            engine.sendMessage(to: friend.id, text: textToSend)
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "#38BDF8"))
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 19))
                                    .foregroundColor(.white)
                                    .offset(x: -1, y: 1)
                            }
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white)
            }
        }
    }
    
    // MARK: - Voice Recording Handlers
    private func startAudioRecording() {
        isRecordingAudio = true
        audioDurationCounter = 0.0
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            audioDurationCounter += 0.1
            if audioDurationCounter >= 10.0 {
                stopAudioRecording(send: true)
            }
        }
    }
    
    private func stopAudioRecording(send: Bool) {
        timer?.invalidate()
        timer = nil
        let duration = audioDurationCounter
        isRecordingAudio = false
        audioDurationCounter = 0.0
        
        if send && duration > 0.5 {
            engine.sendMessage(to: friend.id, text: "🎙️ Voice Note (\(String(format: "%.1f", duration))s)", type: .audio, audioDuration: duration)
        }
    }
}

// MARK: - Chat Message Bubble View (Matches Screenshot Styling)
struct ChatMessageBubble: View {
    let message: ChatMessage
    let isFromCurrentUser: Bool
    let friend: FriendContact
    let onToggleReaction: (String) -> Void
    
    @State private var isPlayingAudio: Bool = false
    @State private var reactionEmoji: String? = nil
    @State private var showReactionPicker: Bool = false
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isFromCurrentUser {
                Spacer(minLength: 50)
            } else {
                // Friend Avatar next to received bubble
                ZStack {
                    Circle()
                        .fill(Color(hex: friend.avatarColorHex))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: friend.avatarSymbol)
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
            }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                // Emoji Reaction Badge overlay
                if let emoji = reactionEmoji {
                    Text(emoji)
                        .font(.system(size: 16))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
                        .offset(y: 4)
                }
                
                if message.type == .sticker {
                    // Custom Cat Waving Sticker (Matches Screenshot!)
                    VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 2) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
                            
                            VStack(spacing: 4) {
                                Text("🐱❤️")
                                    .font(.system(size: 64))
                                
                                Text("Yay! 🎉")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(hex: "#FF6B81"))
                            }
                            .padding(14)
                        }
                        .frame(width: 140, height: 130)
                        
                        Text(message.formattedTime)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(Color(hex: "#94A3B8"))
                    }
                } else if message.type == .audio {
                    // Interactive Voice Note Bubble Player
                    Button(action: {
                        isPlayingAudio.toggle()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: isPlayingAudio ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(isFromCurrentUser ? .white : Color(hex: "#38BDF8"))
                            
                            // Animated Waveform lines
                            HStack(spacing: 3) {
                                ForEach(0..<12, id: \.self) { i in
                                    Capsule()
                                        .fill(isFromCurrentUser ? Color.white.opacity(0.8) : Color(hex: "#38BDF8").opacity(0.7))
                                        .frame(width: 3, height: CGFloat([12, 22, 16, 28, 10, 24, 18, 30, 14, 20, 8, 16][i]) * (isPlayingAudio ? 1.2 : 0.8))
                                }
                            }
                            
                            Text("\(String(format: "%.1f", message.audioDuration ?? 2.0))s")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(isFromCurrentUser ? .white : Color(hex: "#1E293B"))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(isFromCurrentUser ? Color(hex: "#60A5FA") : Color.white)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 2)
                    }
                } else {
                    // Standard Text Bubble
                    VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                        Text(message.textContent)
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .foregroundColor(isFromCurrentUser ? Color(hex: "#0F172A") : Color(hex: "#0F172A"))
                            .multilineTextAlignment(.leading)
                        
                        HStack(spacing: 4) {
                            Text(message.formattedTime)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(isFromCurrentUser ? Color(hex: "#334155") : Color(hex: "#64748B"))
                            
                            if isFromCurrentUser {
                                // Double Checkmarks (✓✓)
                                HStack(spacing: -3) {
                                    Image(systemName: "checkmark")
                                    Image(systemName: "checkmark")
                                }
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color(hex: "#0284C7"))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        isFromCurrentUser
                        ? Color(hex: "#93C5FD") // Light blue sent bubble matching screenshot
                        : Color.white // Light grey/white received bubble matching screenshot
                    )
                    .clipShape(RoundedBubbleShape(isFromCurrentUser: isFromCurrentUser))
                    .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 2)
                    .onTapGesture {
                        showReactionPicker.toggle()
                    }
                }
                
                // Emoji Reaction Bar (If Triggered)
                if showReactionPicker {
                    HStack(spacing: 12) {
                        ForEach(["❤️", "👍", "😂", "😮", "🎉", "⭐"], id: \.self) { emoji in
                            Button(emoji) {
                                reactionEmoji = emoji
                                onToggleReaction(emoji)
                                showReactionPicker = false
                            }
                            .font(.system(size: 20))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white)
                    .clipShape(Capsule())
                    .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
                }
                
                if message.isFlagged {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.shield.fill")
                        Text("Safety Word Filtered")
                    }
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.orange)
                }
            }
            
            if !isFromCurrentUser {
                Spacer(minLength: 50)
            }
        }
    }
}

// Custom Rounded Bubble Tail Shape (Pure SwiftUI)
struct RoundedBubbleShape: Shape {
    let isFromCurrentUser: Bool
    
    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 18
        var path = Path()
        let tl: CGFloat = radius
        let tr: CGFloat = radius
        let bl: CGFloat = isFromCurrentUser ? radius : 4
        let br: CGFloat = isFromCurrentUser ? 4 : radius
        
        path.move(to: CGPoint(x: rect.minX + tl, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - tr, y: rect.minY))
        path.addArc(center: CGPoint(x: rect.maxX - tr, y: rect.minY + tr), radius: tr, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - br))
        path.addArc(center: CGPoint(x: rect.maxX - br, y: rect.maxY - br), radius: br, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX + bl, y: rect.maxY))
        path.addArc(center: CGPoint(x: rect.minX + bl, y: rect.maxY - bl), radius: bl, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + tl))
        path.addArc(center: CGPoint(x: rect.minX + tl, y: rect.minY + tl), radius: tl, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        return path
    }
}

// MARK: - Sticker Picker Drawer
struct StickerPickerView: View {
    let onSelectSticker: (String) -> Void
    let stickers = ["cat_waving", "dog_happy", "star_rocket", "unicorn_sparkle"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Fun Stickers 🐱🎨")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "#64748B"))
                .padding(.horizontal, 16)
                .padding(.top, 8)
            
            HStack(spacing: 16) {
                Button(action: { onSelectSticker("cat_waving") }) {
                    VStack {
                        Text("🐱❤️")
                            .font(.system(size: 40))
                        Text("Happy Cat")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                }
                
                Button(action: { onSelectSticker("dog_happy") }) {
                    VStack {
                        Text("🐶✨")
                            .font(.system(size: 40))
                        Text("Playful Pup")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                }
                
                Button(action: { onSelectSticker("star_rocket") }) {
                    VStack {
                        Text("🚀⭐")
                            .font(.system(size: 40))
                        Text("Star Rocket")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                }
                
                Button(action: { onSelectSticker("unicorn_sparkle") }) {
                    VStack {
                        Text("🦄🌈")
                            .font(.system(size: 40))
                        Text("Rainbow")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
        .background(Color(hex: "#F1F5F9"))
    }
}


// MARK: - Backward-compatible Scroll Modifier (iOS 16 & iOS 17+)
private struct ScrollToBottomOnChange: ViewModifier {
    let count: Int
    let lastId: UUID?
    let proxy: ScrollViewProxy
    
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.onChange(of: count) {
                if let lastId = lastId {
                    withAnimation {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
            }
        } else {
            content.onChange(of: count) { _ in
                if let lastId = lastId {
                    withAnimation {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
            }
        }
    }
}

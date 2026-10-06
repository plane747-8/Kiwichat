import Foundation

struct SafetyFilterResult {
    let originalText: String
    let filteredText: String
    let wasFlagged: Bool
    let flagReason: String?
}

struct FlaggedIncident: Identifiable, Codable {
    let id: UUID
    let senderName: String
    let timestamp: Date
    let originalMessage: String
    let flagReason: String
    
    init(id: UUID = UUID(), senderName: String, timestamp: Date = Date(), originalMessage: String, flagReason: String) {
        self.id = id
        self.senderName = senderName
        self.timestamp = timestamp
        self.originalMessage = originalMessage
        self.flagReason = flagReason
    }
}

final class SafetyFilterService {
    static let shared = SafetyFilterService()
    
    private let inappropriateWords: Set<String> = [
        "badword", "hate", "ugly", "stupid", "idiot", "dumb", "fool", "shut up", "jerk", "freak", "loser"
    ]
    
    private let suspiciousPhrases: [String] = [
        "don't tell your parents", "keep this secret", "where do you live",
        "what's your address", "send me a picture", "are you alone", "meet me",
        "don't tell anyone", "secret friend"
    ]
    
    private let socialPlatforms: [String] = [
        "instagram", "insta", "tiktok", "snapchat", "snap", "discord", "roblox", "fortnite", "whatsapp", "telegram"
    ]
    
    private init() {}
    
    func sanitize(_ text: String, customBlockedWords: [String] = []) -> SafetyFilterResult {
        var cleanText = text
        var flagged = false
        var reasons: [String] = []
        
        let lower = text.lowercased()
        
        // 1. Check suspicious grooming phrases
        for phrase in suspiciousPhrases {
            if lower.contains(phrase) {
                flagged = true
                reasons.append("Safety Guard: Detected prohibited phrase")
                let replacement = String(repeating: "★", count: phrase.count)
                cleanText = cleanText.replacingOccurrences(of: phrase, with: replacement, options: .caseInsensitive)
            }
        }
        
        // 2. Check phone numbers (digits sequence >= 7)
        let phoneRegex = #"\b\d{3}[-.\s]?\d{3}[-.\s]?\d{4}\b"#
        if let regex = try? NSRegularExpression(pattern: phoneRegex) {
            let matches = regex.matches(in: cleanText, range: NSRange(cleanText.startIndex..., in: cleanText))
            if !matches.isEmpty {
                flagged = true
                reasons.append("Privacy Guard: Phone number detected & hidden")
                cleanText = regex.stringByReplacingMatches(in: cleanText, options: [], range: NSRange(cleanText.startIndex..., in: cleanText), withTemplate: "[Phone Number Blocked 🛡️]")
            }
        }
        
        // 3. Check URLs or Emails
        let urlRegex = #"(https?://\S+|www\.\S+|\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b)"#
        if let regex = try? NSRegularExpression(pattern: urlRegex) {
            let matches = regex.matches(in: cleanText, range: NSRange(cleanText.startIndex..., in: cleanText))
            if !matches.isEmpty {
                flagged = true
                reasons.append("Privacy Guard: External links/emails blocked")
                cleanText = regex.stringByReplacingMatches(in: cleanText, options: [], range: NSRange(cleanText.startIndex..., in: cleanText), withTemplate: "[Link Blocked 🛡️]")
            }
        }
        
        // 4. Check Street Address keywords (e.g. 123 Main St, Avenue, Rd)
        let streetAddressRegex = #"\b\d{1,5}\s+[A-Za-z0-9\s]{2,20}\s+(Street|St|Avenue|Ave|Road|Rd|Drive|Dr|Boulevard|Blvd|Lane|Ln|Court|Ct)\b"#
        if let regex = try? NSRegularExpression(pattern: streetAddressRegex, options: .caseInsensitive) {
            let matches = regex.matches(in: cleanText, range: NSRange(cleanText.startIndex..., in: cleanText))
            if !matches.isEmpty {
                flagged = true
                reasons.append("Privacy Guard: Street address detected & hidden")
                cleanText = regex.stringByReplacingMatches(in: cleanText, options: [], range: NSRange(cleanText.startIndex..., in: cleanText), withTemplate: "[Address Blocked 🛡️]")
            }
        }
        
        // 5. Social Media Handle detection (@username or platform mentions)
        for platform in socialPlatforms {
            if lower.contains(platform) {
                flagged = true
                reasons.append("Privacy Guard: Social media app handle blocked")
                cleanText = cleanText.replacingOccurrences(of: platform, with: "[Social Media Blocked 🛡️]", options: .caseInsensitive)
            }
        }
        
        // 6. Inappropriate words & custom words
        let wordsToMask = inappropriateWords.union(customBlockedWords.map { $0.lowercased() })
        let components = cleanText.components(separatedBy: .whitespacesAndNewlines)
        var sanitizedWords: [String] = []
        
        for word in components {
            let stripped = word.trimmingCharacters(in: .punctuationCharacters).lowercased()
            if wordsToMask.contains(stripped) {
                flagged = true
                let masked = String(repeating: "*", count: max(3, word.count))
                sanitizedWords.append(masked)
            } else {
                sanitizedWords.append(word)
            }
        }
        
        cleanText = sanitizedWords.joined(separator: " ")
        
        return SafetyFilterResult(
            originalText: text,
            filteredText: cleanText,
            wasFlagged: flagged,
            flagReason: reasons.joined(separator: ", ")
        )
    }
}

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
    
    private let maximumExtraWords: Set<String> = [
        "annoying", "boring", "leave me alone", "go away", "shut it", "gross", "creep", "weirdo"
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
    
    func sanitize(_ text: String, severity: WordFilterSeverity = .strict, customBlockedWords: [String] = []) -> SafetyFilterResult {
        var cleanText = text
        var flagged = false
        var reasons: [String] = []
        
        let lower = text.lowercased()
        
        // 1. Check suspicious grooming phrases (Applies to all tiers)
        for phrase in suspiciousPhrases {
            if lower.contains(phrase) {
                flagged = true
                reasons.append("Prohibited secret/grooming phrase")
                let replacement = String(repeating: "★", count: phrase.count)
                cleanText = cleanText.replacingOccurrences(of: phrase, with: replacement, options: .caseInsensitive)
            }
        }
        
        // 2. Strict & Maximum: Check phone numbers
        if severity == .strict || severity == .maximum {
            let phoneRegex = #"(\b\d{3}[-.\s]?\d{3}[-.\s]?\d{4}\b|\b\d{7,11}\b)"#
            if let regex = try? NSRegularExpression(pattern: phoneRegex) {
                let matches = regex.matches(in: cleanText, range: NSRange(cleanText.startIndex..., in: cleanText))
                if !matches.isEmpty {
                    flagged = true
                    reasons.append("Phone number blocked")
                    cleanText = regex.stringByReplacingMatches(in: cleanText, options: [], range: NSRange(cleanText.startIndex..., in: cleanText), withTemplate: "[Phone Number Blocked 🛡️]")
                }
            }
        }
        
        // 3. Strict & Maximum: Check URLs or Emails
        if severity == .strict || severity == .maximum {
            let urlRegex = #"(https?://\S+|www\.\S+|\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b)"#
            if let regex = try? NSRegularExpression(pattern: urlRegex) {
                let matches = regex.matches(in: cleanText, range: NSRange(cleanText.startIndex..., in: cleanText))
                if !matches.isEmpty {
                    flagged = true
                    reasons.append("External links/emails blocked")
                    cleanText = regex.stringByReplacingMatches(in: cleanText, options: [], range: NSRange(cleanText.startIndex..., in: cleanText), withTemplate: "[Link Blocked 🛡️]")
                }
            }
        }
        
        // 4. Strict & Maximum: Check Street Address keywords
        if severity == .strict || severity == .maximum {
            let streetAddressRegex = #"\b\d{1,5}\s+[A-Za-z0-9\s]{2,20}\s+(Street|St|Avenue|Ave|Road|Rd|Drive|Dr|Boulevard|Blvd|Lane|Ln|Court|Ct)\b"#
            if let regex = try? NSRegularExpression(pattern: streetAddressRegex, options: .caseInsensitive) {
                let matches = regex.matches(in: cleanText, range: NSRange(cleanText.startIndex..., in: cleanText))
                if !matches.isEmpty {
                    flagged = true
                    reasons.append("Street address blocked")
                    cleanText = regex.stringByReplacingMatches(in: cleanText, options: [], range: NSRange(cleanText.startIndex..., in: cleanText), withTemplate: "[Address Blocked 🛡️]")
                }
            }
        }
        
        // 5. Strict & Maximum: Social Media Handle detection
        if severity == .strict || severity == .maximum {
            for platform in socialPlatforms {
                if lower.contains(platform) {
                    flagged = true
                    reasons.append("Social media platform mention blocked")
                    cleanText = cleanText.replacingOccurrences(of: platform, with: "[Social Media Blocked 🛡️]", options: .caseInsensitive)
                }
            }
        }
        
        // 6. Inappropriate words & custom words
        var wordsToMask = inappropriateWords.union(customBlockedWords.map { $0.lowercased() })
        if severity == .maximum {
            wordsToMask = wordsToMask.union(maximumExtraWords)
        }
        
        let components = cleanText.components(separatedBy: .whitespacesAndNewlines)
        var sanitizedWords: [String] = []
        
        for word in components {
            let stripped = word.trimmingCharacters(in: .punctuationCharacters).lowercased()
            if wordsToMask.contains(stripped) {
                flagged = true
                if !reasons.contains("Inappropriate language blocked") {
                    reasons.append("Inappropriate language blocked")
                }
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

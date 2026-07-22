import Foundation

/// The message and answer types shared by Ask DebtShield.
///
/// These outlived the original county chatbot: the personal responder
/// (`PersonalChatEngine`) and its view (`PersonalChatView`) both use them, so
/// they live here on their own rather than inside any one engine.

/// One turn of the conversation.
struct ChatMessage: Identifiable, Sendable {
    enum Role: Sendable {
        case user
        case assistant

        /// Spoken prefix so a screen-reader user always knows who is talking.
        var accessibilityPrefix: String {
            switch self {
            case .user: return "You asked"
            case .assistant: return "DebtShield replied"
            }
        }
    }

    let id: UUID
    let role: Role
    let text: String
    /// Where the numbers came from. Assistant messages only.
    let provenance: String?
    /// Suggested next questions.
    let followUps: [String]

    init(id: UUID = UUID(), role: Role, text: String, provenance: String? = nil, followUps: [String] = []) {
        self.id = id
        self.role = role
        self.text = text
        self.provenance = provenance
        self.followUps = followUps
    }
}

/// What the engine produced for one question.
struct ChatAnswer: Sendable {
    var text: String
    var provenance: String?
    var followUps: [String] = []
    /// True when the engine declined rather than answered. Declines never
    /// contain figures.
    var isDecline: Bool = false
}

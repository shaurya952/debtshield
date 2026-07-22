import SwiftUI

/// Phase 8 Ask DebtShield.
///
/// Answers come from `ChatEngine`, which computes every figure from the dataset
/// rather than generating text. Nothing here is networked and nothing is sent
/// anywhere.
struct ChatbotView: View {
    let dataset: Dataset
    let searchIndex: CountySearchIndex
    let selection: SelectionStore

    @State private var messages: [ChatMessage] = []
    @State private var draft: String = ""
    @FocusState private var isInputFocused: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var county: ScoredCounty? {
        selection.selectedCounty(in: dataset)
    }

    /// True while only the greeting is on screen.
    private var conversationNotStarted: Bool { messages.count <= 1 }

    /// Follow-ups from the newest assistant turn, falling back to the standard
    /// starters so there is always something to tap.
    ///
    /// Before the conversation starts these are recomputed from the *current*
    /// selection rather than read off the greeting, so picking a county on
    /// another tab and coming back offers prompts about that county.
    private var suggestions: [String] {
        if conversationNotStarted {
            return ChatEngine.quickPrompts(for: county)
        }
        if let last = messages.last, last.role == .assistant, !last.followUps.isEmpty {
            return last.followUps
        }
        return ChatEngine.quickPrompts(for: county)
    }

    var body: some View {
        VStack(spacing: 0) {
            transcript
            Divider()
            suggestionBar
            inputBar
        }
        .background(Theme.screenGradient)
        .navigationTitle("Ask DebtShield")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Clear") { clear() }
                    .font(.body)
                    .disabled(messages.isEmpty)
                    .accessibilityHint("Removes every message in this conversation")
            }
        }
        // Refreshes the greeting when the selected county changes, but only
        // while the conversation is untouched — never rewrites history the user
        // has already read.
        .task(id: selection.selectedID) {
            if conversationNotStarted { messages = [openingMessage] }
        }
    }

    private var openingMessage: ChatMessage {
        let subject = county.map { "**\($0.displayName)**" } ?? "any U.S. county"
        return ChatMessage(
            role: .assistant,
            text: "Ask me about \(subject) — its risk level, what drives it, or how the score is worked out.\n\nI only use the data built into this app, and I'll tell you when I don't know something.",
            followUps: ChatEngine.quickPrompts(for: county)
        )
    }

    // MARK: - Transcript

    private var transcript: some View {
        ScrollViewReader { proxy in
            ScrollView {
                // A plain VStack, not Lazy: lazy stacks cache row heights and
                // do not re-measure when the text size changes, which left the
                // disclaimer reported as not supporting Dynamic Type. A chat
                // transcript is short enough that laziness buys nothing.
                VStack(alignment: .leading, spacing: Theme.Spacing.comfortable) {
                    ForEach(messages) { message in
                        ChatBubble(message: message)
                            .id(message.id)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    disclaimer
                        .id(disclaimerID)
                }
                .padding(Theme.Spacing.comfortable)
            }
            .onChange(of: messages.count) {
                guard let last = messages.last else { return }
                // Reduce Motion: jump rather than animate the scroll.
                if reduceMotion {
                    proxy.scrollTo(last.id, anchor: .bottom)
                } else {
                    withAnimation(.easeOut(duration: 0.25)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private let disclaimerID = "disclaimer"

    private var disclaimer: some View {
        Text("Educational information only — not financial, legal, or benefits advice. Answers come from the built-in county data and never leave your device.")
            .font(.footnote)
            .foregroundStyle(Theme.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, Theme.Spacing.tight)
    }

    // MARK: - Suggestions

    private var suggestionBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.tight) {
                ForEach(suggestions, id: \.self) { prompt in
                    Button {
                        send(prompt)
                    } label: {
                        Text(prompt)
                            .font(.subheadline)
                            .fixedSize(horizontal: true, vertical: false)
                            .padding(.horizontal, Theme.Spacing.regular)
                            .frame(minHeight: Theme.minimumTapTarget)
                            .background(Theme.cardBackground, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(prompt)
                    .accessibilityHint("Asks this question")
                }
            }
            .padding(.horizontal, Theme.Spacing.comfortable)
            .padding(.vertical, Theme.Spacing.tight)
        }
        .background(Theme.screenGradient)
        .accessibilityLabel("Suggested questions")
    }

    // MARK: - Input

    private var inputBar: some View {
        HStack(spacing: Theme.Spacing.tight) {
            TextField("Ask a question", text: $draft, axis: .vertical)
                .lineLimit(1...4)
                .textFieldStyle(.plain)
                .padding(.horizontal, Theme.Spacing.regular)
                .padding(.vertical, Theme.Spacing.tight)
                .frame(minHeight: Theme.minimumTapTarget)
                .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .focused($isInputFocused)
                .submitLabel(.send)
                .onSubmit { send(draft) }
                .accessibilityLabel("Your question")

            Button {
                send(draft)
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title)
                    .frame(width: Theme.minimumTapTarget, height: Theme.minimumTapTarget)
            }
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityLabel("Send")
        }
        .padding(Theme.Spacing.comfortable)
        .background(.bar)
    }

    // MARK: - Actions

    private func send(_ text: String) {
        let question = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty else { return }

        draft = ""
        messages.append(ChatMessage(role: .user, text: question))

        let answer = ChatEngine.respond(
            to: question,
            dataset: dataset,
            searchIndex: searchIndex,
            county: county
        )
        messages.append(ChatMessage(
            role: .assistant,
            text: answer.text,
            provenance: answer.provenance,
            followUps: answer.followUps
        ))
    }

    private func clear() {
        messages = [openingMessage]
        draft = ""
    }
}

// MARK: - Bubble

/// One message.
///
/// Role is carried three ways — alignment, background, and a visible "You" /
/// "DebtShield" label — so it never depends on colour or position alone.
struct ChatBubble: View {
    let message: ChatMessage

    private var isUser: Bool { message.role == .user }

    var body: some View {
        VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
            HStack(spacing: 5) {
                if !isUser { BrandMark(size: 15) }
                Text(isUser ? "You" : "DebtShield")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.secondaryText)
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.tight) {
                Text(.init(message.text))
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityHidden(true)
                    .foregroundStyle(isUser ? Color.white : Color.primary)
                    .textSelection(.enabled)

                if let provenance = message.provenance {
                    // Says where the numbers came from, on every answer that
                    // quotes one.
                    Label(provenance, systemImage: "doc.text.magnifyingglass")
                        .font(.caption)
                        .foregroundStyle(isUser ? Color.white.opacity(0.8) : Color.secondary)
                }
            }
            .padding(Theme.Spacing.regular)
            .background(
                isUser ? AnyShapeStyle(Theme.brand) : AnyShapeStyle(Theme.cardBackground),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(message.role.accessibilityPrefix): \(spokenText)")
    }

    /// Markdown emphasis markers would otherwise be read aloud literally.
    private var spokenText: String {
        var text = message.text.replacingOccurrences(of: "**", with: "")
        text = text.replacingOccurrences(of: "· ", with: "")
        if let provenance = message.provenance {
            text += ". Source: \(provenance)"
        }
        return text
    }
}

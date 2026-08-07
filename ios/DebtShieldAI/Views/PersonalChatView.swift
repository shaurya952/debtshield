import SwiftUI

/// Ask DebtShield, pointed at the person's own month.
///
/// Answers come from `PersonalChatEngine`, which computes every figure from the
/// `MoneyPlan` on this device. Nothing is networked; nothing is sent anywhere.
/// The transcript reuses `ChatBubble` so the voice and layout match the rest of
/// the app exactly.
struct PersonalChatView: View {
    let store: MoneyPlanStore
    /// The comparison data, so the AI can answer "how does my rent compare".
    /// Optional-by-nature: the chat works without it, just without comparisons.
    var dataStore: DataStore? = nil
    var benchmarks: Benchmarks? = nil

    @State private var messages: [ChatMessage] = []
    @State private var draft: String = ""
    @FocusState private var isInputFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var plan: MoneyPlan { store.plan }

    private var homeCounty: ScoredCounty? {
        guard let fips = store.homeCountyFIPS, let dataset = dataStore?.dataset else { return nil }
        return dataset.county(fips: fips)
    }

    /// Past months plus this month, oldest first — for the "where is this
    /// heading" early-warning.
    private var months: [MonthRecord] {
        var all = store.history.reversed().map { $0 }
        if store.plan.isComplete, !store.month.isEmpty {
            all.append(MonthRecord(monthKey: store.month, plan: store.plan))
        }
        return all
    }
    private var conversationNotStarted: Bool { messages.count <= 1 }
    private var canSend: Bool { !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    private var suggestions: [String] {
        if let last = messages.last, last.role == .assistant, !last.followUps.isEmpty {
            return last.followUps
        }
        var prompts = PersonalChatEngine.quickPrompts(for: plan)
        // Once there's a couple of months tracked, lead with the differentiator.
        if store.history.count >= 2 {
            prompts.insert("Am I heading toward debt?", at: 0)
        }
        return prompts
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
                    .disabled(messages.isEmpty)
                    .accessibilityHint("Removes every message in this conversation")
            }
        }
        .onAppear {
            if conversationNotStarted { messages = [openingMessage] }
        }
    }

    private var openingMessage: ChatMessage {
        let answer = PersonalChatEngine.opening(for: plan)
        return ChatMessage(role: .assistant, text: answer.text, followUps: answer.followUps)
    }

    // MARK: - Transcript

    private var transcript: some View {
        ScrollViewReader { proxy in
            ScrollView {
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
        Text("This explains your own numbers — it isn't financial or legal advice. Everything stays on your device.")
            .font(Theme.Typography.caption)
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
                            .font(Theme.Typography.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.brand)
                            .fixedSize(horizontal: true, vertical: false)
                            .padding(.horizontal, Theme.Spacing.comfortable)
                            .frame(minHeight: Theme.minimumTapTarget)
                            .background(Theme.iconWell(Theme.brand), in: Capsule())
                            .overlay(Capsule().strokeBorder(Theme.brand.opacity(0.22), lineWidth: 1))
                    }
                    .buttonStyle(PressableCardStyle())
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
            TextField("Ask about your month", text: $draft, axis: .vertical)
                .lineLimit(1...4)
                .textFieldStyle(.plain)
                .padding(.horizontal, Theme.Spacing.regular)
                .padding(.vertical, Theme.Spacing.tight)
                .frame(minHeight: Theme.minimumTapTarget)
                .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
                .focused($isInputFocused)
                .submitLabel(.send)
                .onSubmit { send(draft) }
                .accessibilityLabel("Your question")

            Button {
                send(draft)
            } label: {
                Image(systemName: "arrow.up")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(
                        canSend ? AnyShapeStyle(Theme.brandGradient)
                                : AnyShapeStyle(Color(uiColor: .tertiarySystemFill)),
                        in: Circle()
                    )
                    .shadow(color: canSend ? Theme.brand.opacity(0.35) : .clear, radius: 6, x: 0, y: 3)
            }
            .disabled(!canSend)
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

        let answer = PersonalChatEngine.respond(to: question, plan: plan, county: homeCounty, benchmarks: benchmarks, months: months)
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
                    Label(provenance, systemImage: "doc.text.magnifyingglass")
                        .font(.caption)
                        .foregroundStyle(isUser ? Color.white.opacity(0.85) : Theme.secondaryText)
                }
            }
            .padding(Theme.Spacing.regular)
            .background {
                let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
                if isUser {
                    shape.fill(Theme.brandGradient)
                        .shadow(color: Theme.brand.opacity(0.28), radius: 8, x: 0, y: 4)
                } else {
                    shape.fill(Theme.cardBackground)
                        .overlay(shape.strokeBorder(Theme.separator.opacity(0.6), lineWidth: 1))
                        .shadow(color: Theme.cardShadow, radius: 7, x: 0, y: 3)
                }
            }
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

#if DEBUG
#Preview("With numbers") {
    NavigationStack { PersonalChatView(store: .preview(.sampleOver)) }
}

#Preview("No numbers") {
    NavigationStack { PersonalChatView(store: .preview(.empty)) }
}
#endif

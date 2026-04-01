import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let widget: WidgetConfig?
    let time = Date()
}

struct ChatView: View {
    @State private var messages: [ChatMessage] = []
    @State private var input = ""
    @State private var typing = false
    private let ai = AIService()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "wand.and.stars").font(.title2).foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Widget Creator").font(.headline)
                    Text("Опишите виджет — я создам!").font(.caption2).foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(12)
            .background(.ultraThinMaterial)
            Divider()

            // Messages
            ScrollViewReader { p in
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(messages) { m in
                            VStack(alignment: m.isUser ? .trailing : .leading, spacing: 4) {
                                Text(m.text)
                                    .font(.subheadline)
                                    .padding(10)
                                    .background(m.isUser ? Color.blue : Color(.secondarySystemBackground))
                                    .foregroundStyle(m.isUser ? .white : .primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))

                                if let w = m.widget {
                                    widgetPreview(w).frame(height: 100).clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: m.isUser ? .trailing : .leading)
                            .id(m.id)
                        }
                        if typing {
                            HStack(spacing: 4) {
                                Circle().fill(.gray.opacity(0.5)).frame(width: 6, height: 6)
                                Circle().fill(.gray.opacity(0.5)).frame(width: 6, height: 6)
                                Circle().fill(.gray.opacity(0.5)).frame(width: 6, height: 6)
                            }.padding(12).id("t")
                        }
                    }
                    .padding(12)
                }
                .onChange(of: messages.count) { _ in
                    if let last = messages.last { withAnimation { p.scrollTo(last.id) } }
                }
                .onChange(of: typing) { _ in
                    if typing { withAnimation { p.scrollTo("t") } }
                }
            }

            // Input
            HStack {
                TextField("Опишите виджет...", text: $input, axis: .vertical)
                    .lineLimit(1...3).textFieldStyle(PlainTextFieldStyle())
                Button { send() } label: {
                    Image(systemName: "arrow.up.circle.fill").font(.system(size: 30))
                        .foregroundStyle(input.isEmpty ? .gray : .blue)
                }.disabled(input.isEmpty)
            }
            .padding(12)
        }
        .onAppear { if messages.isEmpty { messages.append(ChatMessage(text: "Привет! 👋 Я создатель виджетов!\n\nНапишите что хотите видеть на виджете.\n\nИли напишите Помощь", isUser: false, widget: nil)) } }
    }

    @ViewBuilder
    func widgetPreview(_ c: WidgetConfig) -> some View {
        ZStack {
            if c.type == .gradient {
                LinearGradient(colors: [c.primary, c.secondary], startPoint: .topLeading, endPoint: .bottomTrailing)
            } else {
                c.primary
            }
            VStack(spacing: 4) {
                if c.type == .emoji {
                    Text(c.emoji).font(.system(size: 30))
                }
                if c.type == .countdown {
                    Text(c.countdownStr ?? "--").font(.system(size: 28, weight: .bold, design: .monospaced)).foregroundStyle(c.textClr)
                }
                Text(c.title).font(.system(size: CGFloat(min(c.fontSize, 20)), weight: .bold, design: .rounded))
                    .foregroundStyle(c.textClr).lineLimit(3)
                if c.type == .quote && !c.subtitle.isEmpty {
                    Text("— \(c.subtitle)").font(.caption).foregroundStyle(c.textClr.opacity(0.7))
                }
            }
            .padding()
        }
    }

    func send() {
        let t = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        input = ""
        messages.append(ChatMessage(text: t, isUser: true, widget: nil))
        typing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            let r = ai.respond(t)
            withAnimation { messages.append(ChatMessage(text: r.text, isUser: false, widget: r.widget)); typing = false }
        }
    }
}

@main
struct App: SwiftUI.App {
    var body: some Scene {
        WindowGroup { ChatView() }
    }
}

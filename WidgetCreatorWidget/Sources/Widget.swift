import WidgetKit
import SwiftUI

struct Entry: TimelineEntry {
    let date: Date
    let config: WidgetConfig?
}

struct Provider: TimelineProvider {
    func placeholder(in c: Context) -> Entry { Entry(date: .now, config: WidgetConfig(title: "Widget Creator")) }
    func getSnapshot(in c: Context, completion: @escaping (Entry) -> Void) {
        completion(Entry(date: .now, config: UserDefaults.latestWidget()))
    }
    func getTimeline(in c: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let cfg = UserDefaults.latestWidget()
        let next = cfg?.type == .countdown
            ? Calendar.current.date(byAdding: .minute, value: 1, to: .now)!
            : Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
        completion(Timeline(entries: [Entry(date: .now, config: cfg)], policy: .after(next)))
    }
}

struct WView: View {
    let entry: Entry
    @Environment(\.widgetFamily) var family
    var body: some View {
        if let c = entry.config { build(c) }
        else {
            ZStack {
                Color(.systemBlue)
                VStack(spacing: 6) {
                    Image(systemName: "wand.and.stars").font(.title2).foregroundStyle(.white)
                    Text("Widget Creator").font(.caption.bold()).foregroundStyle(.white)
                }
            }
        }
    }

    @ViewBuilder
    func build(_ c: WidgetConfig) -> some View {
        ZStack {
            bg(c)
            VStack(spacing: 4) {
                if c.type == .emoji { Text(c.emoji).font(.system(size: sz(30, 50, 72))) }
                if c.type == .countdown { Text(c.countdownStr ?? "--").font(.system(size: sz(18, 32, 44), weight: .bold, design: .monospaced)) }
                if c.type == .quote { Text("\"").font(.system(size: sz(20, 36, 50))).foregroundStyle(c.textClr.opacity(0.3)) }
                Text(c.title).font(.system(size: sz(14, 20, 28), weight: .bold, design: .rounded))
                    .foregroundStyle(c.textClr).lineLimit(4).multilineTextAlignment(.center)
                if c.type == .quote && !c.subtitle.isEmpty {
                    Text("— \(c.subtitle)").font(.system(size: sz(9, 11, 13), weight: .medium))
                        .foregroundStyle(c.textClr.opacity(0.7))
                }
            }
            .padding()
        }
    }

    func bg(_ c: WidgetConfig) -> some View {
        Group {
            if c.type == .gradient {
                LinearGradient(colors: [c.primary, c.secondary], startPoint: .topLeading, endPoint: .bottomTrailing)
            } else {
                c.primary
            }
        }
    }

    func sz(_ s: CGFloat, _ m: CGFloat, _ l: CGFloat) -> CGFloat {
        switch family { case .systemSmall: return s; case .systemLarge: return l; default: return m }
    }
}

struct WidgetC: Widget {
    let kind = "WidgetCreatorWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { e in WView(entry: e) }
            .configurationDisplayName("Widget Creator")
            .description("AI виджеты")
            .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

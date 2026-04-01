import Foundation
import SwiftUI

enum WidgetType: String, Codable {
    case text, countdown, emoji, gradient, quote
    var icon: String {
        switch self {
        case .text: return "textformat"
        case .countdown: return "timer"
        case .emoji: return "face.smiling"
        case .gradient: return "paintpalette"
        case .quote: return "quote.bubble"
        }
    }
    var label: String {
        switch self {
        case .text: return "Текст"
        case .countdown: return "Таймер"
        case .emoji: return "Эмодзи"
        case .gradient: return "Градиент"
        case .quote: return "Цитата"
        }
    }
}

struct WidgetConfig: Identifiable, Codable {
    let id: UUID
    var type: WidgetType
    var title: String
    var subtitle: String
    var primaryHex: String
    var secondaryHex: String
    var textHex: String
    var fontSize: Int
    var emoji: String
    var targetDate: Date?
    var createdAt: Date

    init(type: WidgetType = .text, title: String = "", subtitle: String = "",
         primaryHex: String = "#007AFF", secondaryHex: String = "#5856D6",
         textHex: String = "#FFFFFF", fontSize: Int = 18, emoji: String = "", targetDate: Date? = nil) {
        self.id = UUID(); self.type = type; self.title = title; self.subtitle = subtitle
        self.primaryHex = primaryHex; self.secondaryHex = secondaryHex; self.textHex = textHex
        self.fontSize = fontSize; self.emoji = emoji; self.targetDate = targetDate; self.createdAt = Date()
    }
}

extension Color {
    init(hex: String) {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: h).scanHexInt64(&rgb)
        self.init(red: Double((rgb & 0xFF0000) >> 16) / 255.0,
                  green: Double((rgb & 0x00FF00) >> 8) / 255.0,
                  blue: Double(rgb & 0x0000FF) / 255.0)
    }
}

extension WidgetConfig {
    var primary: Color { Color(hex: primaryHex) }
    var secondary: Color { Color(hex: secondaryHex) }
    var textClr: Color { Color(hex: textHex) }
    var countdownStr: String? {
        guard let t = targetDate else { return nil }
        let c = Calendar.current.dateComponents([.day, .hour, .minute], from: Date(), to: t)
        guard let d = c.day, let h = c.hour, let m = c.minute else { return nil }
        if d > 0 { return "\(d)d \(h)h \(m)m" }
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }
}

extension UserDefaults {
    static let g = UserDefaults(suiteName: "group.com.widgetcreator.app") ?? .standard

    static func saveWidget(_ cfg: WidgetConfig) {
        var all = allWidgets()
        if let i = all.firstIndex(where: { $0.id == cfg.id }) { all[i] = cfg }
        else { all.append(cfg) }
        if let d = try? JSONEncoder().encode(all) { g.set(d, forKey: "widgets") }
    }

    static func allWidgets() -> [WidgetConfig] {
        guard let d = g.data(forKey: "widgets"),
              let c = try? JSONDecoder().decode([WidgetConfig].self, from: d) else { return [] }
        return c
    }

    static func latestWidget() -> WidgetConfig? { allWidgets().last }

    static func deleteWidget(id: UUID) {
        var a = allWidgets(); a.removeAll { $0.id == id }
        if let d = try? JSONEncoder().encode(a) { g.set(d, forKey: "widgets") }
    }
}

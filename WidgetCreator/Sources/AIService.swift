import Foundation

class AIService {
    func respond(_ msg: String) -> (text: String, widget: WidgetConfig?) {
        let low = msg.lowercased()

        if low.contains("привет") || low.contains("хай") || low.contains("здравствуй") {
            return (greeting(), nil)
        }
        if low.contains("помощь") || low.contains("help") {
            return (helpText(), nil)
        }
        if low.contains("мои виджет") || low.contains("список") {
            return (listWidgets(), nil)
        }
        if low.contains("удали") || low.contains("delete") {
            return deleteWidget(low)
        }

        // Detect type
        if low.contains("таймер") || low.contains("countdown") || low.contains("обратн") || low.contains("осталос") {
            return makeCountdown(msg)
        }
        if low.contains("эмодзи") || low.contains("emoji") || low.contains("смайл") {
            return makeEmoji(msg)
        }
        if low.contains("градиент") || low.contains("gradient") || low.contains("перелив") {
            return makeGradient(msg)
        }
        if low.contains("цитат") || low.contains("quote") || low.contains("мотивац") {
            return makeQuote()
        }

        // Default: text widget
        return makeText(msg)
    }

    // MARK: - Creators
    private func makeText(_ msg: String) -> (String, WidgetConfig?) {
        var c = WidgetConfig(type: .text)
        c.title = cleanText(msg)
        applyColor(&c, msg)
        UserDefaults.saveWidget(c)
        return ("✅ Виджет создан!\n\n\"\(c.title)\"\n\n📱 Добавьте:\nДолго нажмите на экран → + → Widget Creator", c)
    }

    private func makeCountdown(_ msg: String) -> (String, WidgetConfig?) {
        var c = WidgetConfig(type: .countdown, fontSize: 24)
        if let d = parseDate(msg) { c.targetDate = d; c.title = eventName(msg) }
        else { c.targetDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()); c.title = cleanText(msg) }
        applyColor(&c, msg)
        UserDefaults.saveWidget(c)
        return ("⏱ Таймер создан!\n\n\"\(c.title)\"\n\n📱 Добавьте:\nДолго нажмите на экран → + → Widget Creator", c)
    }

    private func makeEmoji(_ msg: String) -> (String, WidgetConfig?) {
        var c = WidgetConfig(type: .emoji, fontSize: 40)
        c.emoji = extractEmoji(msg).isEmpty ? "⭐" : extractEmoji(msg)
        c.title = cleanText(msg).isEmpty ? "Виджет" : cleanText(msg)
        applyColor(&c, msg)
        UserDefaults.saveWidget(c)
        return ("😀 Виджет создан!\n\n📱 Добавьте:\nДолго нажмите на экран → + → Widget Creator", c)
    }

    private func makeGradient(_ msg: String) -> (String, WidgetConfig?) {
        var c = WidgetConfig(type: .gradient)
        c.title = cleanText(msg)
        let g = detectGradient(msg)
        c.primaryHex = g.0; c.secondaryHex = g.1
        UserDefaults.saveWidget(c)
        return ("🌈 Градиент создан!\n\n📱 Добавьте:\nДолго нажмите на экран → + → Widget Creator", c)
    }

    private func makeQuote() -> (String, WidgetConfig?) {
        var c = WidgetConfig(type: .quote, fontSize: 16)
        let q = quotes.randomElement()!
        c.title = q.0; c.subtitle = q.1
        UserDefaults.saveWidget(c)
        return ("💡 Цитата создана!\n\n\"\(c.title)\"\n— \(c.subtitle)\n\n📱 Добавьте:\nДолго нажмите на экран → + → Widget Creator", c)
    }

    // MARK: - Helpers
    private func cleanText(_ msg: String) -> String {
        var t = msg
        for kw in ["создай виджет","создать виджет","сделай виджет","создай","создать","сделай","виджет","widget","пожалуйста","плиз","хочу","нужен"] {
            t = t.replacingOccurrences(of: kw, with: "", options: .caseInsensitive)
        }
        t = t.trimmingCharacters(in: .whitespacesAndNewlines)
        if let f = t.first, "-:,".contains(f) { t = String(t.dropFirst()) }
        t = t.trimmingCharacters(in: .whitespacesAndNewlines)
        if !t.isEmpty { t = String(t.prefix(1)).uppercased() + t.dropFirst() }
        return t.isEmpty ? "Мой виджет" : String(t.prefix(80))
    }

    private func applyColor(_ c: inout WidgetConfig, _ msg: String) {
        let low = msg.lowercased()
        let colors: [String: String] = [
            "красн":"#FF3B30","син":"#007AFF","зелен":"#34C759","зелён":"#34C759",
            "фиолет":"#AF52DE","оранж":"#FF9500","розов":"#FF2D55","жёлт":"#FFCC00",
            "желт":"#FFCC00","чёрн":"#1C1C1E","черн":"#1C1C1E","бел":"#F2F2F7",
            "сер":"#8E8E93","голуб":"#32ADE6","бирюзов":"#5AC8FA","мятн":"#00C7BE",
            "red":"#FF3B30","blue":"#007AFF","green":"#34C759","purple":"#AF52DE",
            "orange":"#FF9500","pink":"#FF2D55","yellow":"#FFCC00","black":"#1C1C1E",
        ]
        for (k, v) in colors { if low.contains(k) { c.primaryHex = v; break } }
        c.textHex = "#FFFFFF"
    }

    private func detectGradient(_ msg: String) -> (String, String) {
        let low = msg.lowercased()
        let g: [(k: [String], p: String, s: String)] = [
            (["синий фиолет"], "#007AFF", "#AF52DE"), (["закат","sunset"], "#FF9500", "#FF2D55"),
            (["океан","ocean"], "#007AFF", "#00C7BE"), (["ночь","night"], "#1C1C1E", "#5856D6"),
            (["радуг"], "#FF3B30", "#AF52DE"),
        ]
        for item in g { for k in item.k { if low.contains(k) { return (item.p, item.s) } } }
        let all = ["#007AFF","#5856D6","#FF2D55","#FF9500","#34C759"]
        return (all.randomElement()!, all.randomElement()!)
    }

    private func parseDate(_ msg: String) -> Date? {
        let cal = Calendar.current, now = Date(), yr = cal.component(.year, from: now)
        let events: [(k: String, m: Int, d: Int)] = [
            ("новый год",1,1),("рождество",1,7),("валентин",2,14),("23 февраля",2,23),
            ("8 марта",3,8),("день победы",5,9),("хэллоуин",10,31),("halloween",10,31),
        ]
        for e in events {
            if msg.lowercased().contains(e.k) {
                var c = DateComponents(); c.year = yr; c.month = e.m; c.day = e.d
                if let dt = cal.date(from: c) { return dt < now ? cal.date(from: { c.year = yr+1; return c }()) : dt }
            }
        }
        // N дней
        if let r = msg.range(of: "(\\d+)\\s*д", options: .regularExpression) {
            let s = String(msg[r]).filter { $0.isNumber }
            if let n = Int(s) { return cal.date(byAdding: .day, value: n, to: now) }
        }
        return nil
    }

    private func eventName(_ msg: String) -> String {
        let low = msg.lowercased()
        for e in ["новый год","рождество","валентин","23 февраля","8 марта","день победы","хэллоуин"] {
            if low.contains(e) { return String(e.prefix(1)).uppercased() + e.dropFirst() }
        }
        return cleanText(msg)
    }

    private func extractEmoji(_ msg: String) -> String {
        var result = ""
        for (i, c) in msg.unicodeScalars.enumerated() where c.properties.isEmojiPresentation {
            result.append(Character(c))
            if result.count >= 3 { break }
        }
        return result
    }

    private func deleteWidget(_ low: String) -> (String, WidgetConfig?) {
        let all = UserDefaults.allWidgets()
        if all.isEmpty { return ("У вас пока нет виджетов.\n\nНапишите мне и я создам виджет!", nil) }
        if low.contains("все") || low.contains("всё") {
            UserDefaults.g.removeObject(forKey: "widgets")
            return ("Все виджеты удалены!\n\nСоздайте новый!", nil)
        }
        if let last = all.last { UserDefaults.deleteWidget(id: last.id) }
        return ("Виджет удалён!\n\nСоздайте новый!", nil)
    }

    private func listWidgets() -> String {
        let all = UserDefaults.allWidgets()
        if all.isEmpty { return "У вас пока нет виджетов.\n\nНапишите мне!" }
        var r = "Ваши виджеты (\(all.count)):\n\n"
        for (i, c) in all.enumerated() {
            r += "\(c.type.icon) \(i+1). \(c.title)\n"
        }
        return r
    }

    // MARK: - Texts
    private func greeting() -> String {
        "Привет! Я создатель виджетов!\n\nНапишите что хотите:\n\nТекстовый виджет\nТаймер\nЭмодзи\nГрадиент\nЦитата\n\nИли напишите Помощь"
    }
    private func helpText() -> String {
        "Помощь:\n\nТекст: Создай виджет [текст] [цвет]\nТаймер: Таймер до [событие]\nЭмодзи: Эмодзи [эмодзи]\nГрадиент: Градиентный виджет\nЦитата: Цитата дня\n\nЦвета: красный, синий, зелёный, фиолетовый, оранжевый, розовый, жёлтый\n\nУправление:\nМои виджеты - список\nУдали - удалить\nУдали все - очистить"
    }

    private let quotes: [(String, String)] = [
        ("Будущее принадлежит тем, кто верит в красоту своей мечты.", "Элеонора Рузвельт"),
        ("Единственный способ делать великую работу — любить то, что ты делаешь.", "Стив Джобс"),
        ("Не бойся идти медленно, бойся стоять на месте.", "Китайская пословица"),
        ("Секрет успеха — начать.", "Марк Твен"),
        ("Делай что можешь, с тем что имеешь, там где ты есть.", "Теодор Рузвельт"),
        ("Будь тем изменением, которое ты хочешь видеть в мире.", "Махатма Ганди"),
    ]
}

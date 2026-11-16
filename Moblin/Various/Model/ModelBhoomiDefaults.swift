import Foundation

private let bhoomiChatOffAppliedKey = "bhoomiChatOffApplied"
private let bhoomiStreamNameShownKey = "bhoomiStreamNameShown"

extension Model {
    func applyBhoomiDefaultsOnce() {
        if !UserDefaults.standard.bool(forKey: bhoomiStreamNameShownKey) {
            database.show.stream = true
            UserDefaults.standard.set(true, forKey: bhoomiStreamNameShownKey)
            settings.store()
        }
        guard !UserDefaults.standard.bool(forKey: bhoomiChatOffAppliedKey) else {
            return
        }
        database.chat.enabled = false
        database.show.chat = false
        UserDefaults.standard.set(true, forKey: bhoomiChatOffAppliedKey)
        settings.store()
    }
}

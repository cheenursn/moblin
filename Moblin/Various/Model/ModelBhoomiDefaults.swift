import Foundation

private let bhoomiChatOffAppliedKey = "bhoomiChatOffApplied"

extension Model {
    func applyBhoomiDefaultsOnce() {
        guard !UserDefaults.standard.bool(forKey: bhoomiChatOffAppliedKey) else {
            return
        }
        database.chat.enabled = false
        database.show.chat = false
        UserDefaults.standard.set(true, forKey: bhoomiChatOffAppliedKey)
        settings.store()
    }
}

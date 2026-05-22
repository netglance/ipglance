import WidgetKit
import IPGlanceCore

struct WidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> IPGlanceEntry {
        IPGlanceEntry(date: .now, info: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (IPGlanceEntry) -> Void) {
        completion(IPGlanceEntry(date: .now, info: SharedStore.read()))
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<IPGlanceEntry>) -> Void) {
        let cached = SharedStore.read()
        if let cached {
            let entries = [IPGlanceEntry(date: .now, info: cached)]
            let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now)!
            completion(Timeline(entries: entries, policy: .after(next)))
        } else {
            Task {
                let info = try? await IPGeolocationService().fetchCountryInfo()
                if let info { SharedStore.write(info) }
                let entries = [IPGlanceEntry(date: .now, info: info)]
                let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now)!
                completion(Timeline(entries: entries, policy: .after(next)))
            }
        }
    }
}

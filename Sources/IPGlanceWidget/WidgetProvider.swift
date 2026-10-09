import WidgetKit
import IPGlanceCore

struct WidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> IPGlanceEntry {
        IPGlanceEntry(date: .now, info: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (IPGlanceEntry) -> Void) {
        completion(IPGlanceEntry(date: .now, info: SharedStore.read(), fetchedAt: SharedStore.readFetchedAt()))
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<IPGlanceEntry>) -> Void) {
        Task {
            var info = SharedStore.read()
            var fetchedAt = SharedStore.readFetchedAt()
            if info == nil, let fresh = try? await IPGeolocationService().fetchCountryInfo() {
                SharedStore.write(fresh)
                info = fresh
                fetchedAt = .now
            }
            completion(Timeline(entries: [IPGlanceEntry(date: .now, info: info, fetchedAt: fetchedAt)],
                                policy: .after(.now.addingTimeInterval(30 * 60))))
        }
    }
}

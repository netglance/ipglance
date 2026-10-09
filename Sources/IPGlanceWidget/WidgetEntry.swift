import WidgetKit
import IPGlanceCore

struct IPGlanceEntry: TimelineEntry {
    let date: Date
    let info: CountryInfo?
    /// When the IP was fetched; `nil` for caches that predate the stored date.
    var fetchedAt: Date?
}

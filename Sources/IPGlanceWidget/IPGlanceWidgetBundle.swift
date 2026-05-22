import WidgetKit
import SwiftUI

@main
struct IPGlanceWidgetBundle: WidgetBundle {
    var body: some Widget {
        IPGlanceWidget()
    }
}

struct IPGlanceWidget: Widget {
    let kind = "IPGlanceWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetProvider()) { entry in
            WidgetEntryView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("IPGlance")
        .description("Показывает ваш текущий публичный IP-адрес.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct WidgetEntryView: View {
    let entry: IPGlanceEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemSmall:  SmallWidgetView(entry: entry)
        case .systemMedium: MediumWidgetView(entry: entry)
        case .systemLarge:  LargeWidgetView(entry: entry)
        default:            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Previews

private let previewEntry = IPGlanceEntry(
    date: .now,
    info: .init(
        ip: "188.114.97.42",
        countryCode: "NL",
        countryName: "Netherlands",
        city: "Amsterdam",
        region: "North Holland",
        isp: "Cloudflare WARP",
        asn: "AS13335",
        timezone: "Europe/Amsterdam",
        latitude: 52.37,
        longitude: 4.89
    )
)

#Preview("Small", as: .systemSmall) {
    IPGlanceWidget()
} timeline: {
    previewEntry
}

#Preview("Medium", as: .systemMedium) {
    IPGlanceWidget()
} timeline: {
    previewEntry
}

#Preview("Large", as: .systemLarge) {
    IPGlanceWidget()
} timeline: {
    previewEntry
}

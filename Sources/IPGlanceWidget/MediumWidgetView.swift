import SwiftUI
import IPGlanceCore

struct MediumWidgetView: View {
    let entry: IPGlanceEntry

    var body: some View {
        ZStack {
            ContainerRelativeShape().fill(.background)
            if let info = entry.info {
                HStack(spacing: 0) {
                    // Left: flag + location
                    VStack(alignment: .leading, spacing: 4) {
                        Text(info.flagEmoji).font(.system(size: 36))
                        Text(info.countryName)
                            .font(.system(size: 12, weight: .semibold))
                            .lineLimit(1)
                        Text(info.city.isEmpty ? info.countryCode : info.city)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Spacer()
                        updatedLabel
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Divider().padding(.vertical, 8)

                    // Right: IP + stats
                    VStack(alignment: .leading, spacing: 6) {
                        Text(info.ip)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        statRow(label: "ISP", value: firstWord(info.isp))
                        statRow(label: "ASN", value: info.asn.isEmpty ? "—" : info.asn, mono: true)
                        statRow(label: "TZ", value: info.shortTimezone)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(14)
            } else {
                placeholder
            }
        }
    }

    private func statRow(label: String, value: String, mono: Bool = false) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Text(value)
                .font(.system(size: 11, weight: .medium, design: mono ? .monospaced : .default))
                .lineLimit(1)
        }
    }

    @ViewBuilder private var updatedLabel: some View {
        if let fetchedAt = entry.fetchedAt {
            Text(fetchedAt, style: .relative)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
    }

    private var placeholder: some View {
        HStack {
            Text("🌐").font(.system(size: 36))
            Text("widget_loading").font(.system(size: 13)).foregroundStyle(.secondary)
        }
    }

    private func firstWord(_ s: String) -> String {
        s.split(separator: " ").first.map(String.init) ?? s
    }
}

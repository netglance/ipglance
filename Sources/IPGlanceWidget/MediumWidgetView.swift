import SwiftUI
import IPGlanceCore

struct MediumWidgetView: View {
    let entry: IPGlanceEntry
    @Environment(\.colorScheme) private var colorScheme

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
                        statRow(label: "TZ", value: shortTZ(info.timezone))
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
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Text(value)
                .font(.system(size: 11, weight: .medium, design: mono ? .monospaced : .default))
                .lineLimit(1)
        }
    }

    private var updatedLabel: some View {
        Text(entry.date, style: .relative)
            .font(.system(size: 9))
            .foregroundStyle(.tertiary)
    }

    private var placeholder: some View {
        HStack {
            Text("🌐").font(.system(size: 36))
            Text("Загрузка…").font(.system(size: 13)).foregroundStyle(.secondary)
        }
    }

    private func firstWord(_ s: String) -> String {
        s.split(separator: " ").first.map(String.init) ?? s
    }

    private func shortTZ(_ tz: String) -> String {
        guard !tz.isEmpty else { return "—" }
        return tz.split(separator: "/").last
            .map { $0.replacingOccurrences(of: "_", with: " ") } ?? tz
    }
}

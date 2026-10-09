import SwiftUI
import IPGlanceCore

struct LargeWidgetView: View {
    let entry: IPGlanceEntry

    var body: some View {
        ZStack {
            ContainerRelativeShape().fill(.background)
            if let info = entry.info {
                VStack(alignment: .leading, spacing: 0) {
                    // Hero
                    HStack(spacing: 12) {
                        Text(info.flagEmoji).font(.system(size: 44))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(info.countryName)
                                .font(.system(size: 16, weight: .bold))
                            Text(info.city.isEmpty ? info.region : "\(info.city), \(info.region)")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                    }
                    .padding(.bottom, 10)

                    // IP
                    Text(info.ip)
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .padding(.bottom, 12)

                    Divider().padding(.bottom, 10)

                    // Detail rows
                    VStack(spacing: 8) {
                        detailRow(label: "widget_provider", value: info.isp.isEmpty ? "—" : info.isp)
                        detailRow(label: "ASN", value: info.asn.isEmpty ? "—" : info.asn, mono: true)
                        detailRow(label: "widget_city", value: info.city.isEmpty ? "—" : info.city)
                        detailRow(label: "widget_region", value: info.region.isEmpty ? "—" : info.region)
                        detailRow(label: "widget_timezone", value: info.timezone.isEmpty ? "—" : info.timezone)
                    }

                    Spacer()

                    // Footer
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                        Text(entry.date, style: .relative)
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.top, 8)
                }
                .padding(16)
            } else {
                VStack(spacing: 8) {
                    Text("🌐").font(.system(size: 44))
                    Text("widget_no_data").font(.system(size: 14)).foregroundStyle(.secondary)
                }
            }
        }
    }

    private func detailRow(label: LocalizedStringKey, value: String, mono: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .medium, design: mono ? .monospaced : .default))
                .lineLimit(1)
        }
    }
}

import SwiftUI
import IPGlanceCore

struct SmallWidgetView: View {
    let entry: IPGlanceEntry
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(.background)
            if let info = entry.info {
                VStack(spacing: 6) {
                    Text(info.flagEmoji)
                        .font(.system(size: 44))
                    Text(info.ip)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(info.countryCode)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding(12)
            } else {
                placeholder
            }
        }
    }

    private var placeholder: some View {
        VStack(spacing: 6) {
            Text("🌐").font(.system(size: 44))
            Text("—").font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }
}

import SwiftUI

struct AboutView: View {
    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool { colorScheme == .dark }
    private var bg: Color { isDark ? Color(red: 31/255, green: 32/255, blue: 36/255) : Color(red: 244/255, green: 245/255, blue: 247/255) }
    private var sub: Color { isDark ? .white.opacity(0.55) : .black.opacity(0.5) }
    private var stroke: Color { isDark ? .white.opacity(0.07) : .black.opacity(0.07) }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            VStack(spacing: 20) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(stroke, lineWidth: 0.5))
                        .frame(width: 80, height: 80)
                    Text("🌐").font(.system(size: 50))
                }
                Text("IPGlance")
                    .font(.system(size: 22, weight: .bold))
                Text("v 1.0.0")
                    .font(.system(size: 13))
                    .foregroundStyle(sub)
                Text("about_description", bundle: .module)
                    .font(.system(size: 13))
                    .foregroundStyle(sub)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)
            }
            .padding(36)
        }
        .frame(width: 400)
    }
}

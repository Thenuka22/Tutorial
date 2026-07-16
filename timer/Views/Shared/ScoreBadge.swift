import SwiftUI

struct ScoreBadge: View {
    let title: String
    let value: String
    let symbol: String
    var tint: Color = MiniArcadeTheme.orange

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 5) {
                MiniArcadeSymbolIcon(
                    systemName: symbol,
                    tint: tint,
                    size: 28,
                    symbolSize: 13
                )

                Text(title.uppercased())
                    .font(MiniArcadeGameFont.label(10))
                    .foregroundStyle(MiniArcadeTheme.mutedInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }

            Text(value)
                .font(MiniArcadeGameFont.display(18).monospacedDigit())
                .foregroundStyle(MiniArcadeTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.68)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 68)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(MiniArcadePanelBackground(cornerRadius: 18))
        .accessibilityElement(children: .combine)
    }
}

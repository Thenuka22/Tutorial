import SwiftUI

struct ScoreBadge: View {
    let title: String
    let value: String
    let symbol: String
    var tint: Color = PlayHubTheme.orange

    var body: some View {
        VStack(spacing: 5) {
            Label(title, systemImage: symbol)
                .font(.caption2.bold())
                .foregroundStyle(PlayHubTheme.mutedInk)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(value)
                .font(.headline.monospacedDigit())
                .foregroundStyle(PlayHubTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.90), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(tint.opacity(0.16), lineWidth: 1)
        )
    }
}

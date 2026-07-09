import SwiftUI

struct ScoreBadge: View {
    let title: String
    let value: String
    let symbol: String
    var tint: Color = PlayHubTheme.orange

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(tint, in: Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.55), lineWidth: 2))

            VStack(alignment: .leading, spacing: 0) {
                Text(title.uppercased())
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .foregroundStyle(PlayHubTheme.mutedInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)

                Text(value)
                    .font(.system(size: 17, weight: .black, design: .rounded).monospacedDigit())
                    .foregroundStyle(.white)
                    .gameTextShadow()
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 58)
        .padding(.horizontal, 10)
        .background {
            Image(GameArt.coinBar)
                .resizable(capInsets: EdgeInsets(top: 18, leading: 42, bottom: 18, trailing: 42), resizingMode: .stretch)
        }
    }
}

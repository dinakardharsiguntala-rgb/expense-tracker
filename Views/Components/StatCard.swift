import SwiftUI

public struct StatCard: View {
    let title: String
    let amount: Double
    let iconName: String
    let accentColor: Color
    var subtitle: String? = nil

    public init(
        title: String,
        amount: Double,
        iconName: String,
        accentColor: Color,
        subtitle: String? = nil
    ) {
        self.title = title
        self.amount = amount
        self.iconName = iconName
        self.accentColor = accentColor
        self.subtitle = subtitle
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: iconName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(accentColor)
                    .frame(width: 32, height: 32)
                    .background(accentColor.opacity(0.15))
                    .clipShape(Circle())

                Spacer()

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }

            Text(CurrencyFormatter.format(amount))
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.appSecondaryBackground)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        )
    }
}

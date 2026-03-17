import SwiftUI

#if canImport(ActivityKit)
import ActivityKit
import Shared
import WidgetKit

/// Lock Screen and banner presentation view for HA Live Activities
@available(iOS 16.1, *)
struct LiveActivityView: View {
    let state: HALiveActivityAttributes.ContentState
    let attributes: HALiveActivityAttributes

    private var accentColor: Color {
        if let hex = state.color {
            return Color(hex: hex)
        }
        return .blue
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            if let iconName = state.icon {
                let mdiName = iconName.replacingOccurrences(of: "mdi:", with: "")
                Image(uiImage: MaterialDesignIcons(named: mdiName).image(
                    ofSize: CGSize(width: 28, height: 28),
                    color: UIColor(accentColor)
                ))
                .frame(width: 28, height: 28)
            }

            // Title and subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(attributes.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if let subtitle = state.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Value and optional progress
            VStack(alignment: .trailing, spacing: 4) {
                Text(state.value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(accentColor)
                    .lineLimit(1)

                if let progress = state.progress {
                    ProgressView(value: min(max(progress, 0), 1))
                        .tint(accentColor)
                        .frame(width: 80)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

/// Dynamic Island views for HA Live Activities
@available(iOS 16.1, *)
struct LiveActivityDynamicIslandView {
    let state: HALiveActivityAttributes.ContentState
    let attributes: HALiveActivityAttributes

    private var accentColor: Color {
        if let hex = state.color {
            return Color(hex: hex)
        }
        return .blue
    }

    // MARK: - Compact Leading

    @ViewBuilder
    var compactLeading: some View {
        if let iconName = state.icon {
            let mdiName = iconName.replacingOccurrences(of: "mdi:", with: "")
            Image(uiImage: MaterialDesignIcons(named: mdiName).image(
                ofSize: CGSize(width: 16, height: 16),
                color: UIColor(accentColor)
            ))
            .frame(width: 16, height: 16)
        } else {
            Image(systemName: "house.fill")
                .foregroundStyle(accentColor)
                .font(.caption2)
        }
    }

    // MARK: - Compact Trailing

    @ViewBuilder
    var compactTrailing: some View {
        Text(state.value)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(accentColor)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }

    // MARK: - Expanded

    @ViewBuilder
    var expanded: some View {
        HStack(spacing: 12) {
            if let iconName = state.icon {
                let mdiName = iconName.replacingOccurrences(of: "mdi:", with: "")
                Image(uiImage: MaterialDesignIcons(named: mdiName).image(
                    ofSize: CGSize(width: 40, height: 40),
                    color: UIColor(accentColor)
                ))
                .frame(width: 40, height: 40)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(attributes.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                if let subtitle = state.subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(state.value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(accentColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                if let progress = state.progress {
                    ProgressView(value: min(max(progress, 0), 1))
                        .tint(accentColor)
                        .frame(width: 80)
                }
            }
        }
        .padding()
    }

    // MARK: - Minimal

    @ViewBuilder
    var minimal: some View {
        if let iconName = state.icon {
            let mdiName = iconName.replacingOccurrences(of: "mdi:", with: "")
            Image(uiImage: MaterialDesignIcons(named: mdiName).image(
                ofSize: CGSize(width: 20, height: 20),
                color: UIColor(accentColor)
            ))
            .frame(width: 20, height: 20)
        } else {
            Image(systemName: "house.fill")
                .foregroundStyle(accentColor)
        }
    }
}

// MARK: - Color hex extension

@available(iOS 16.1, *)
private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
#endif

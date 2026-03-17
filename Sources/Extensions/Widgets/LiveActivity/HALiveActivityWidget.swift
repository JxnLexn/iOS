import SwiftUI

#if canImport(ActivityKit)
import ActivityKit
import Shared
import WidgetKit

/// The Widget struct that ties HALiveActivityAttributes to the Live Activity views.
/// This is registered in the widget bundle to enable Live Activities.
@available(iOS 16.1, *)
struct HALiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: HALiveActivityAttributes.self) { context in
            // Lock Screen / banner presentation
            LiveActivityView(
                state: context.state,
                attributes: context.attributes
            )
            .activityBackgroundTint(.black.opacity(0.7))
            .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            let diView = LiveActivityDynamicIslandView(
                state: context.state,
                attributes: context.attributes
            )

            return DynamicIsland {
                // Expanded regions
                DynamicIslandExpandedRegion(.center) {
                    diView.expanded
                }
            } compactLeading: {
                diView.compactLeading
            } compactTrailing: {
                diView.compactTrailing
            } minimal: {
                diView.minimal
            }
        }
    }
}
#endif

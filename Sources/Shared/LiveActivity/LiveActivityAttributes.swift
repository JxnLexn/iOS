import Foundation

#if canImport(ActivityKit)
import ActivityKit

/// Defines the structure for Home Assistant Live Activities.
/// Static attributes are set when the activity starts; ContentState is updated dynamically.
@available(iOS 16.1, *)
public struct HALiveActivityAttributes: ActivityAttributes {
    /// Dynamic state updated via push notifications or local updates
    public struct ContentState: Codable, Hashable {
        /// Primary display value (e.g. "21.5°C", "On", "Running")
        public var value: String
        /// Optional Material Design icon name (e.g. "mdi:thermometer")
        public var icon: String?
        /// Optional secondary text / subtitle
        public var subtitle: String?
        /// Accent color as hex string (e.g. "#FF9500")
        public var color: String?
        /// Optional progress value 0.0–1.0 for gauge-style display
        public var progress: Double?
        /// Timestamp of the last update
        public var updatedAt: Date

        public init(
            value: String,
            icon: String? = nil,
            subtitle: String? = nil,
            color: String? = nil,
            progress: Double? = nil,
            updatedAt: Date = Date()
        ) {
            self.value = value
            self.icon = icon
            self.subtitle = subtitle
            self.color = color
            self.progress = progress
            self.updatedAt = updatedAt
        }
    }

    /// Entity ID being tracked (e.g. "sensor.temperature")
    public var entityId: String
    /// Friendly display name for the activity
    public var title: String
    /// Server identifier for multi-server setups
    public var serverId: String

    public init(entityId: String, title: String, serverId: String) {
        self.entityId = entityId
        self.title = title
        self.serverId = serverId
    }
}
#endif

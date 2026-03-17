import Foundation
import PromiseKit

#if canImport(ActivityKit)
import ActivityKit

/// Manages the lifecycle of Home Assistant Live Activities.
/// Handles starting, updating, ending activities, and push token registration.
@available(iOS 16.1, *)
public class LiveActivityManager {
    public static let shared = LiveActivityManager()

    private init() {}

    // MARK: - Start

    /// Starts a new Live Activity with the given parameters.
    /// - Returns: The activity ID string for future reference.
    @discardableResult
    public func start(
        entityId: String,
        title: String,
        serverId: String,
        initialState: HALiveActivityAttributes.ContentState
    ) throws -> String {
        let attributes = HALiveActivityAttributes(
            entityId: entityId,
            title: title,
            serverId: serverId
        )

        let content = ActivityContent(
            state: initialState,
            staleDate: nil
        )

        let activity = try Activity.request(
            attributes: attributes,
            content: content,
            pushType: .token
        )

        Current.Log.info("Started Live Activity: \(activity.id) for entity: \(entityId)")

        // Observe push token updates for this activity
        observePushTokenUpdates(for: activity)

        return activity.id
    }

    // MARK: - Update

    /// Updates the content state of an existing Live Activity.
    public func update(activityId: String, state: HALiveActivityAttributes.ContentState) {
        guard let activity = findActivity(byId: activityId) else {
            Current.Log.warning("Live Activity not found for update: \(activityId)")
            return
        }

        let content = ActivityContent(
            state: state,
            staleDate: nil
        )

        Task {
            await activity.update(content)
            Current.Log.info("Updated Live Activity: \(activityId)")
        }
    }

    // MARK: - End

    /// Ends an existing Live Activity.
    public func end(
        activityId: String,
        finalState: HALiveActivityAttributes.ContentState? = nil,
        dismissTimeInterval: TimeInterval? = nil
    ) {
        guard let activity = findActivity(byId: activityId) else {
            Current.Log.warning("Live Activity not found for end: \(activityId)")
            return
        }

        let dismissalPolicy: ActivityUIDismissalPolicy
        if let interval = dismissTimeInterval {
            dismissalPolicy = .after(Date().addingTimeInterval(interval))
        } else {
            dismissalPolicy = .default
        }

        Task {
            let content: ActivityContent<HALiveActivityAttributes.ContentState>?
            if let finalState {
                content = ActivityContent(state: finalState, staleDate: nil)
            } else {
                content = nil
            }

            await activity.end(content, dismissalPolicy: dismissalPolicy)
            Current.Log.info("Ended Live Activity: \(activityId)")
        }
    }

    // MARK: - End All

    /// Ends all active HA Live Activities.
    public func endAll() {
        for activity in Activity<HALiveActivityAttributes>.activities {
            Task {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
        Current.Log.info("Ended all Live Activities")
    }

    // MARK: - Query

    /// Returns all currently active HA Live Activities.
    public var activeActivities: [Activity<HALiveActivityAttributes>] {
        Activity<HALiveActivityAttributes>.activities.filter { $0.activityState == .active }
    }

    // MARK: - Push Token

    /// Observes push token updates for a specific activity and registers with HA server.
    private func observePushTokenUpdates(for activity: Activity<HALiveActivityAttributes>) {
        Task {
            for await tokenData in activity.pushTokenUpdates {
                let tokenString = tokenData.map { String(format: "%02x", $0) }.joined()
                Current.Log.info("Live Activity push token for \(activity.id): \(tokenString)")

                // Register the push token with all configured HA servers
                await registerPushToken(
                    tokenString,
                    activityId: activity.id,
                    entityId: activity.attributes.entityId,
                    serverId: activity.attributes.serverId
                )
            }
        }
    }

    /// Registers a Live Activity push token with the Home Assistant server.
    private func registerPushToken(
        _ token: String,
        activityId: String,
        entityId: String,
        serverId: String
    ) async {
        guard let server = Current.servers.all.first(where: { $0.identifier.rawValue == serverId }),
              let api = Current.api(for: server) else {
            Current.Log.error("Could not find server \(serverId) to register Live Activity push token")
            return
        }

        let payload: [String: Any] = [
            "push_token": token,
            "activity_id": activityId,
            "entity_id": entityId,
        ]

        do {
            _ = try await api.CreateEvent(
                eventType: "ios.live_activity_token",
                eventData: payload
            ).async()
        } catch {
            Current.Log.error("Failed to register Live Activity push token: \(error)")
        }
    }

    // MARK: - Private Helpers

    private func findActivity(byId activityId: String) -> Activity<HALiveActivityAttributes>? {
        Activity<HALiveActivityAttributes>.activities.first { $0.id == activityId }
    }

    /// Parses a ContentState from a notification payload dictionary.
    public static func contentState(from payload: [String: Any]) -> HALiveActivityAttributes.ContentState? {
        guard let value = payload["value"] as? String else {
            Current.Log.error("Live Activity payload missing required 'value' field")
            return nil
        }

        return HALiveActivityAttributes.ContentState(
            value: value,
            icon: payload["icon"] as? String,
            subtitle: payload["subtitle"] as? String,
            color: payload["color"] as? String,
            progress: payload["progress"] as? Double,
            updatedAt: Date()
        )
    }
}
#endif

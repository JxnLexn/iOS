import Foundation
import PromiseKit

#if canImport(ActivityKit)
import ActivityKit
#endif

// MARK: - Start Live Activity

#if os(iOS)
@available(iOS 16.1, *)
struct HandlerStartLiveActivity: NotificationCommandHandler {
    func handle(_ payload: [String: Any]) -> Promise<Void> {
        Current.Log.verbose("Starting Live Activity from notification command: \(payload)")

        guard let entityId = payload["entity_id"] as? String else {
            Current.Log.error("start_live_activity: missing required 'entity_id'")
            return .init(error: LiveActivityCommandError.missingEntityId)
        }

        guard let state = LiveActivityManager.contentState(from: payload) else {
            Current.Log.error("start_live_activity: missing required 'value'")
            return .init(error: LiveActivityCommandError.missingValue)
        }

        let title = payload["title"] as? String ?? entityId
        let serverId = payload["server_id"] as? String ?? ""

        do {
            let activityId = try LiveActivityManager.shared.start(
                entityId: entityId,
                title: title,
                serverId: serverId,
                initialState: state
            )
            Current.Log.info("Started Live Activity with ID: \(activityId)")

            Current.clientEventStore.addEvent(ClientEvent(
                text: "Started Live Activity for \(entityId) (id: \(activityId))",
                type: .notification
            ))

            return .value(())
        } catch {
            Current.Log.error("Failed to start Live Activity: \(error)")
            return .init(error: error)
        }
    }
}

// MARK: - Update Live Activity

@available(iOS 16.1, *)
struct HandlerUpdateLiveActivity: NotificationCommandHandler {
    func handle(_ payload: [String: Any]) -> Promise<Void> {
        Current.Log.verbose("Updating Live Activity from notification command: \(payload)")

        guard let activityId = payload["activity_id"] as? String else {
            Current.Log.error("update_live_activity: missing required 'activity_id'")
            return .init(error: LiveActivityCommandError.missingActivityId)
        }

        guard let state = LiveActivityManager.contentState(from: payload) else {
            Current.Log.error("update_live_activity: missing required 'value'")
            return .init(error: LiveActivityCommandError.missingValue)
        }

        LiveActivityManager.shared.update(activityId: activityId, state: state)

        Current.clientEventStore.addEvent(ClientEvent(
            text: "Updated Live Activity \(activityId)",
            type: .notification
        ))

        return .value(())
    }
}

// MARK: - End Live Activity

@available(iOS 16.1, *)
struct HandlerEndLiveActivity: NotificationCommandHandler {
    func handle(_ payload: [String: Any]) -> Promise<Void> {
        Current.Log.verbose("Ending Live Activity from notification command: \(payload)")

        guard let activityId = payload["activity_id"] as? String else {
            Current.Log.error("end_live_activity: missing required 'activity_id'")
            return .init(error: LiveActivityCommandError.missingActivityId)
        }

        let dismissAfter = payload["dismiss_after"] as? TimeInterval

        // Parse optional final state
        let finalState = LiveActivityManager.contentState(from: payload)

        LiveActivityManager.shared.end(
            activityId: activityId,
            finalState: finalState,
            dismissTimeInterval: dismissAfter
        )

        Current.clientEventStore.addEvent(ClientEvent(
            text: "Ended Live Activity \(activityId)",
            type: .notification
        ))

        return .value(())
    }
}

// MARK: - Errors

enum LiveActivityCommandError: LocalizedError {
    case missingEntityId
    case missingActivityId
    case missingValue

    var errorDescription: String? {
        switch self {
        case .missingEntityId:
            return "Live Activity command missing required 'entity_id' field"
        case .missingActivityId:
            return "Live Activity command missing required 'activity_id' field"
        case .missingValue:
            return "Live Activity command missing required 'value' field"
        }
    }
}
#endif

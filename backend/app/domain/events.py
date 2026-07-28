from enum import Enum
from app.domain.exceptions import InvalidPayloadError

class RideEventType(str, Enum):
    RIDE_REQUESTED = 'RIDE_REQUESTED'
    OWNER_REVIEWED = 'OWNER_REVIEWED'
    FARE_SENT = 'FARE_SENT'
    FARE_ACCEPTED = 'FARE_ACCEPTED'
    RIDER_ASSIGNED = 'RIDER_ASSIGNED'
    RIDER_ACCEPTED = 'RIDER_ACCEPTED'
    RIDER_REJECTED = 'RIDER_REJECTED'
    RIDE_STARTED = 'RIDE_STARTED'
    ARRIVED = 'ARRIVED'
    NO_SHOW = 'NO_SHOW'
    ROUTE_DEVIATION = 'ROUTE_DEVIATION'
    RIDE_COMPLETED = 'RIDE_COMPLETED'
    RIDE_CANCELLED = 'RIDE_CANCELLED'
    BREAKDOWN = 'BREAKDOWN'
    ACCIDENT = 'ACCIDENT'
    SOS_TRIGGERED = 'SOS_TRIGGERED'
    SOS_RESOLVED = 'SOS_RESOLVED'
    SHARE_RIDE_CREATED = 'SHARE_RIDE_CREATED'
    OWNER_NOTE = 'OWNER_NOTE'
    TELEMETRY_UPDATE = 'TELEMETRY_UPDATE'

# Mapping API action strings to DB ENUM strings
API_ACTION_TO_EVENT_TYPE = {
    'request_ride': RideEventType.RIDE_REQUESTED,
    'owner_review': RideEventType.OWNER_REVIEWED,
    'send_fare': RideEventType.FARE_SENT,
    'accept_fare': RideEventType.FARE_ACCEPTED,
    'assign_rider': RideEventType.RIDER_ASSIGNED,
    'accept_assignment': RideEventType.RIDER_ACCEPTED,
    'reject_assignment': RideEventType.RIDER_REJECTED,
    'start_ride': RideEventType.RIDE_STARTED,
    'arrive': RideEventType.ARRIVED,
    'report_no_show': RideEventType.NO_SHOW,
    'report_deviation': RideEventType.ROUTE_DEVIATION,
    'complete_ride': RideEventType.RIDE_COMPLETED,
    'cancel_ride': RideEventType.RIDE_CANCELLED,
    'report_breakdown': RideEventType.BREAKDOWN,
    'report_accident': RideEventType.ACCIDENT,
    'trigger_sos': RideEventType.SOS_TRIGGERED,
    'resolve_sos': RideEventType.SOS_RESOLVED,
    'create_share_link': RideEventType.SHARE_RIDE_CREATED,
    'add_owner_note': RideEventType.OWNER_NOTE,
    'update_location': RideEventType.TELEMETRY_UPDATE
}

def map_action_to_event(action: str) -> RideEventType:
    event_type = API_ACTION_TO_EVENT_TYPE.get(action)
    if not event_type:
        raise InvalidPayloadError(f"Unknown action: {action}")
    return event_type

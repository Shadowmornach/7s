from enum import Enum
from app.domain.events import RideEventType
from app.domain.exceptions import RuleViolationError

class RideStatus(str, Enum):
    REQUESTED = "REQUESTED"
    OWNER_REVIEWING = "OWNER_REVIEWING"
    FARE_SENT = "FARE_SENT"
    FARE_ACCEPTED = "FARE_ACCEPTED"
    RIDER_ASSIGNED = "RIDER_ASSIGNED"
    RIDER_EN_ROUTE = "RIDER_EN_ROUTE"
    ARRIVED = "ARRIVED"
    IN_PROGRESS = "IN_PROGRESS"
    COMPLETED = "COMPLETED"
    CANCELLED = "CANCELLED"

# Event → resulting status (same mapping as DB trigger 011_triggers.sql)
EVENT_TO_STATUS: dict[RideEventType, RideStatus | None] = {
    RideEventType.RIDE_REQUESTED:     RideStatus.REQUESTED,
    RideEventType.OWNER_REVIEWED:     RideStatus.OWNER_REVIEWING,
    RideEventType.FARE_SENT:          RideStatus.FARE_SENT,
    RideEventType.FARE_ACCEPTED:      RideStatus.FARE_ACCEPTED,
    RideEventType.RIDER_ASSIGNED:     RideStatus.RIDER_ASSIGNED,
    RideEventType.RIDER_ACCEPTED:     RideStatus.RIDER_EN_ROUTE,
    RideEventType.ARRIVED:            RideStatus.ARRIVED,
    RideEventType.RIDE_STARTED:       RideStatus.IN_PROGRESS,
    RideEventType.RIDE_COMPLETED:     RideStatus.COMPLETED,
    RideEventType.RIDE_CANCELLED:     RideStatus.CANCELLED,
    # Non-status-changing events:
    RideEventType.RIDER_REJECTED:     None,
    RideEventType.NO_SHOW:            None,
    RideEventType.ROUTE_DEVIATION:    None,
    RideEventType.BREAKDOWN:          None,
    RideEventType.ACCIDENT:           None,
    RideEventType.SOS_TRIGGERED:      None,
    RideEventType.SOS_RESOLVED:       None,
    RideEventType.SHARE_RIDE_CREATED: None,
    RideEventType.OWNER_NOTE:         None,
    RideEventType.TELEMETRY_UPDATE:   None,
}

# Allowed transitions: current_status → set of allowed new statuses
# Mirrors 011_triggers.sql lines 60-80 exactly
ALLOWED_TRANSITIONS: dict[RideStatus, set[RideStatus]] = {
    RideStatus.REQUESTED:        {RideStatus.REQUESTED, RideStatus.OWNER_REVIEWING, RideStatus.RIDER_ASSIGNED, RideStatus.CANCELLED},
    RideStatus.OWNER_REVIEWING:  {RideStatus.FARE_SENT, RideStatus.CANCELLED},
    RideStatus.FARE_SENT:        {RideStatus.FARE_ACCEPTED, RideStatus.CANCELLED},
    RideStatus.FARE_ACCEPTED:    {RideStatus.RIDER_ASSIGNED, RideStatus.CANCELLED},
    RideStatus.RIDER_ASSIGNED:   {RideStatus.RIDER_EN_ROUTE, RideStatus.CANCELLED},
    RideStatus.RIDER_EN_ROUTE:   {RideStatus.ARRIVED, RideStatus.CANCELLED},
    RideStatus.ARRIVED:          {RideStatus.IN_PROGRESS, RideStatus.CANCELLED},
    RideStatus.IN_PROGRESS:      {RideStatus.COMPLETED, RideStatus.CANCELLED},
    RideStatus.COMPLETED:        set(),  # Terminal
    RideStatus.CANCELLED:        set(),  # Terminal
}

def validate_transition(current_status: str, event_type: RideEventType) -> None:
    """Fast-fail Python-side guard. DB trigger is the final authority.
    
    RACE CONDITION NOTE: Between this check and the DB INSERT, another
    request could change the ride's status. This is acceptable because
    the DB trigger (011_triggers.sql) performs the authoritative check
    under a FOR UPDATE row lock. This Python check is an optimization
    to avoid unnecessary round-trips, not a guarantee.
    """
    new_status = EVENT_TO_STATUS.get(event_type)
    if new_status is None:
        return  # Non-status-changing event — always allowed
    
    current = RideStatus(current_status)
    if current in (RideStatus.COMPLETED, RideStatus.CANCELLED):
        if event_type not in (RideEventType.OWNER_NOTE, RideEventType.SOS_TRIGGERED, RideEventType.SOS_RESOLVED):
            raise RuleViolationError(f"Ride is in terminal state {current.value}. No further transitions allowed.")
        return
    
    allowed = ALLOWED_TRANSITIONS.get(current, set())
    if new_status not in allowed:
        raise RuleViolationError(
            f"Invalid transition: {current.value} → {new_status.value} via {event_type.name}"
        )

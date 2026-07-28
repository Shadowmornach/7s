from prometheus_client import Counter, Histogram, Gauge

http_requests_total = Counter("http_requests_total", "Total HTTP requests", ["method", "path", "status"])
http_request_duration = Histogram("http_request_duration_seconds", "HTTP request duration", ["method", "path"])
ride_events_total = Counter("ride_events_total", "Total ride events processed", ["event_type"])
active_websockets = Gauge("active_websocket_connections", "Active WebSocket connections")
db_query_duration = Histogram("db_query_duration_seconds", "Database query duration", ["operation"])
auth_failures_total = Counter("auth_failures_total", "Authentication failures", ["reason"])
ride_timeouts_total = Counter("ride_timeouts_total", "Rides auto-cancelled by timeout sweep")

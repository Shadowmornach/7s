class MetricsCollector:
    def __init__(self):
        self.error_count_5xx = 0
        self.sos_triggers_count = 0
        self.sos_acks_count = 0
        self.sos_total_response_time_seconds = 0.0
        self.stk_attempts_count = 0
        self.stk_success_count = 0

    def record_5xx_error(self):
        self.error_count_5xx += 1

    def record_sos_trigger(self):
        self.sos_triggers_count += 1

    def record_sos_ack(self, response_time_seconds: float):
        self.sos_acks_count += 1
        self.sos_total_response_time_seconds += max(0.0, response_time_seconds)

    def record_stk_attempt(self):
        self.stk_attempts_count += 1

    def record_stk_success(self):
        self.stk_success_count += 1

    def get_summary(self) -> dict:
        avg_sos_response_time = (
            self.sos_total_response_time_seconds / self.sos_acks_count
            if self.sos_acks_count > 0
            else 0.0
        )
        payment_success_rate = (
            self.stk_success_count / self.stk_attempts_count
            if self.stk_attempts_count > 0
            else 1.0
        )
        return {
            "error_count_5xx": self.error_count_5xx,
            "sos_triggers_count": self.sos_triggers_count,
            "sos_acks_count": self.sos_acks_count,
            "avg_sos_response_time_seconds": round(avg_sos_response_time, 2),
            "stk_attempts_count": self.stk_attempts_count,
            "stk_success_count": self.stk_success_count,
            "payment_success_rate": round(payment_success_rate, 4),
        }

metrics_collector = MetricsCollector()

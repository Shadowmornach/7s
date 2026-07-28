import json
import logging
from app.middleware.request_context import request_id_var

class JSONFormatter(logging.Formatter):
    def format(self, record):
        log_data = {
            "timestamp": self.formatTime(record),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "request_id": request_id_var.get(""),
        }
        
        # Include any extra kwargs passed to logger
        for k, v in record.__dict__.items():
            if k not in ["args", "asctime", "created", "exc_info", "exc_text", "filename", "funcName", "id", "levelname", "levelno", "lineno", "module", "msecs", "message", "msg", "name", "pathname", "process", "processName", "relativeCreated", "stack_info", "thread", "threadName", "taskName"]:
                log_data[k] = v

        if record.exc_info:
            log_data["exception"] = self.formatException(record.exc_info)
        return json.dumps(log_data)

def setup_logging(log_level: str):
    logger = logging.getLogger("7s")
    logger.setLevel(log_level)
    
    # Don't propagate to root logger
    logger.propagate = False
    
    handler = logging.StreamHandler()
    handler.setFormatter(JSONFormatter())
    logger.addHandler(handler)
    
    # Set uvicorn loggers to use the same format
    for logger_name in ["uvicorn", "uvicorn.error", "uvicorn.access"]:
        u_logger = logging.getLogger(logger_name)
        u_logger.handlers = [handler]
        u_logger.propagate = False

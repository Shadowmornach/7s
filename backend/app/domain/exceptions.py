class DomainException(Exception):
    """Base class for all domain exceptions."""
    def __init__(self, message: str, code: str):
        super().__init__(message)
        self.code = code
        self.message = message

class ConcurrencyException(DomainException):
    def __init__(self, message="Version mismatch: ride has been updated since last read."):
        super().__init__(message, code="CONCURRENCY_ERROR")

class RuleViolationError(DomainException):
    def __init__(self, message: str, code: str = "RULE_VIOLATION"):
        super().__init__(message, code)

class InvalidPayloadError(DomainException):
    def __init__(self, message: str):
        super().__init__(message, code="INVALID_PAYLOAD")

class ResourceNotFoundError(DomainException):
    def __init__(self, message: str):
        super().__init__(message, code="NOT_FOUND")

class UnauthorizedError(DomainException):
    def __init__(self, message: str):
        super().__init__(message, code="UNAUTHORIZED")

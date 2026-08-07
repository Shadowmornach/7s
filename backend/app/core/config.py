from typing import Optional
from pydantic import SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    # Existing
    DATABASE_URL: SecretStr
    DEBUG: bool = False

    # Auth
    JWT_SECRET: SecretStr
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    PROVISIONING_SECRET: SecretStr = SecretStr("dev-provisioning-secret-change-in-production")
    PROVISIONING_ALLOWED_IPS: str = "127.0.0.1,::1,testclient"

    # Logging & Observability
    LOG_LEVEL: str = "INFO"
    ENVIRONMENT: str = "development"
    # External Services
    SUPABASE_URL: Optional[str] = None
    ORS_API_KEY: Optional[SecretStr] = None
    AT_USERNAME: Optional[str] = None
    AT_API_KEY: Optional[SecretStr] = None
    AT_SENDER_ID: Optional[str] = None

    # Payments (BambaStack M-Pesa Gateway) — Optional until payment flows are invoked
    BAMBASTACK_API_KEY: Optional[SecretStr] = None
    BAMBASTACK_BASE_URL: str = "https://majengo-backend-593721555291.us-central1.run.app"
    BAMBASTACK_TIMEOUT_SECONDS: int = 15

    # Security & CORS
    CORS_ORIGINS: str = "http://localhost:3000,http://localhost:8000"
    LOGIN_RATE_LIMIT_CALLS: int = 5
    LOGIN_RATE_LIMIT_PERIOD_SECONDS: int = 60
    RATE_LIMIT_MAX_KEYS: int = 10000
    MAX_REQUEST_SIZE_BYTES: int = 2097152 # 2MB default

    # Database
    DATABASE_TIMEOUT: float = 5.0
    DATABASE_POOL_MIN: int = 2
    DATABASE_POOL_MAX: int = 10

    # Ride Operations
    RIDE_TIMEOUT_SECONDS: int = 300
    TIMEOUT_SWEEP_INTERVAL_SECONDS: float = 60.0

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

settings = Settings()

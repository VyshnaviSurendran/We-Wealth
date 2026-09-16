from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    ENVIRONMENT: str = "local"
    DEBUG: bool = True

    DATABASE_URL: str = "postgresql+psycopg://we_wealth:we_wealth@localhost:5432/we_wealth"

    JWT_SECRET_KEY: str = "change-me-to-a-long-random-secret"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60

    BACKEND_CORS_ORIGINS: list[str] = ["http://localhost:3000"]

    API_V1_PREFIX: str = "/api/v1"
    PROJECT_NAME: str = "We Wealth"


settings = Settings()

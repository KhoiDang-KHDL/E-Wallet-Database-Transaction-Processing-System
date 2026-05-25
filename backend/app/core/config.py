from functools import lru_cache
from pathlib import Path

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict

BACKEND_DIR = Path(__file__).resolve().parents[2]


class Settings(BaseSettings):
    app_name: str = "IS210 E-Wallet API"
    app_env: str = "development"
    app_debug: bool = True

    jwt_secret_key: str = Field(min_length=16)
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 120

    oracle_user: str
    oracle_password: str
    oracle_dsn: str
    oracle_pool_min: int = 1
    oracle_pool_max: int = 5
    oracle_pool_increment: int = 1

    model_config = SettingsConfigDict(
        env_file=BACKEND_DIR / ".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )


@lru_cache
def get_settings() -> Settings:
    return Settings()

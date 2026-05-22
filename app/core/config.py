from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "E-Wallet Backend"
    app_env: str = "development"
    debug: bool = True
    database_url: str = "oracle+oracledb://EWALLET_PROJECT:123456@localhost:1521/?service_name=orclpdb4.mshome.net"
    jwt_secret_key: str = "change-this-secret-key"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 1440
    admin_user_ids: str = "1"

    @property
    def admin_ids(self) -> set[int]:
        return {int(value.strip()) for value in self.admin_user_ids.split(",") if value.strip().isdigit()}

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")


settings = Settings()
print("DATABASE_URL =", settings.database_url)
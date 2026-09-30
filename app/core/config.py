from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # Values to be loaded from environmnet variables.

    app_name: str = "Actiphibian Gateway"

    # Match the key used by the C# auth serv. The token are verified here
    secret_key: str = "your-secret-key"
    jwt_algorithm: str = "HS256"

    # For the actual flutter origins
    cors_origins: list[str] = ["*"]

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


settings = Settings()

# app/config/settings.py

class MockSettings:
    APP_NAME: str = "Organism Analysis Backend"
    CORS_ORIGINS: list = ["*"]
    SECRET_KEY: str = "your_secret_key"
    DATABASE_URL: str = "sqlite:///./test.db"

# Load the mock settings object to use in the app
settings = MockSettings()

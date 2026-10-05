from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from models.base import Base
import threading

class DatabaseManager:
    _instance = None
    _lock = threading.Lock()

    def __new__(cls):
        with cls._lock:
            if cls._instance is None:
                cls._instance = super().__new__(cls)
            return cls._instance

    def __init__(self):
        if getattr(self, "_initialized", False):
            return 

        self.DATABASE_URL = "sqlite+aiosqlite:///temp.db"
        # Cloud database URL (pending connection details from Manie/Daniel)
        # self.CLOUD_DATABASE_URL = "postgresql+asyncpg://user:password@cloud-server-ip:5432/dbname"

        self.local_engine = create_async_engine(self.DATABASE_URL)
        # self.cloud_engine = create_async_engine(self.CLOUD_DATABASE_URL)
        self.local_session = async_sessionmaker(bind=self.local_engine)
        # self.cloud_Session = async_sessionmaker(bind=self.cloud_engine)
        self._initialized = True

    async def init_db(self):
        async with self.engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)

    def create_session(self):
        return self.local_session()
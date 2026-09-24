from sqlalchemy.ext.asyncio import AsyncSession
from typing import AsyncGenerator
from db.config import DatabaseManager

db_manager = DatabaseManager()

async def get_session() -> AsyncGenerator[AsyncSession, None]:
    async with db_manager.create_session() as session:
        yield session
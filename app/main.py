from fastapi import FastAPI, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from db.config import DatabaseManager
from dependencies import get_session

app = FastAPI()

@app.get("/")
async def home():
    return {"message": "API is functioning"}

@app.get("/test-db")
async def test_db_session(session: AsyncSession = Depends(get_session)):
    return {"message": "Database session creation successfull"}

db1 = DatabaseManager()
db2 = DatabaseManager()

print("Database connection is a singleton:", db1 is db2)


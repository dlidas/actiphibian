from fastapi import APIRouter, Depends, status
from pydantic import BaseModel, Field

from core.security import get_current_user
from services.dummy_service import create_item_in_db

# Need a prefix and tags for the router so that all endpoints in this router will have the same prefix and tag
router = APIRouter(
    prefix="/api/v1/items",
    tags=["items"]
)

class ItemCreate(BaseModel):
    title: str = Field(..., min_length=1, max_length=100)
    description: str | None = Field(None, max_length=300)
    
class ItemResponse(BaseModel):
    id: int
    title: str
    description: str | None

#Check if gateway is reachable and healthy
@router.get("/health")
async def health_check():
    return {"status": "healthy"}

@router.post("/", response_model=ItemResponse, status_code=status.HTTP_201_CREATED)
def create_item(item: ItemCreate, user: str = Depends(get_current_user)):
    """
    So basically: FastAPI and Pydanitc will validate payload before it runs the function.
    Any bad input will be caught by the exception handler in main.py and return a consistent error response format.
    The db-layer receives only trusted data
    201 defined by a response model, so that the client knows what to expect in the response
    """
    saved_item = create_item_in_db(item)
    return saved_item

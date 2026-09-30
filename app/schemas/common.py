from typing import Generic, Optional, TypeVar
from pydantic import BaseModel

T = TypeVar("T")

#Response wrapper for all endpoints to ensure consistent response format
class APIResponse(BaseModel, Generic[T]):
    data: Optional[T] = None
    message: Optional[str] = None
    success: bool 
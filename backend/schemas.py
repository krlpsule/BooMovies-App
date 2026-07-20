from pydantic import BaseModel
from typing import Optional

class UserLogin(BaseModel):
    Username: str
    Password_: str
    
class MovieCreate(BaseModel):
    Title: str
    Director: str
    Genre: str
    Plot: str
    PosterUrl: Optional[str] = None

class BookCreate(BaseModel):
    Title: str
    Author: str
    Genre: str
    Summary: str
    CoverUrl: Optional[str] = None

class UserCreate(BaseModel):
    NameSurname: str
    Username: str
    Email: str
    Password_: str

class BookReviewCreate(BaseModel):
    UserID: int
    BookID: int
    Rating: int 
    ReviewText: str

class MovieReviewCreate(BaseModel):
    UserID: int
    MovieID: int
    Rating: int 
    ReviewText: str


class UserLibraryCreate(BaseModel):
    UserID: int
    BookID: int

class UserWatchlistCreate(BaseModel):
    UserID: int
    MovieID: int
from pydantic import BaseModel

class UserLogin(BaseModel):
    Username: str
    Password_: str
    
class MovieCreate(BaseModel):
    Title: str
    Director: str
    Genre: str
    Plot: str

class BookCreate(BaseModel):
    Title: str
    Author: str
    Genre: str
    Summary: str

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
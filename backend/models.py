from sqlalchemy import Column, Integer, String, Text, ForeignKey
from database import Base

class Book(Base):
    __tablename__ = "Books"
    BookID = Column(Integer, primary_key=True, index=True)
    Title = Column(String(255), nullable=False)
    Author = Column(String(255))
    Genre = Column(String(100))
    Summary = Column(Text)

class Movie(Base):
    __tablename__ = "Movies"
    MovieID = Column(Integer, primary_key=True, index=True)
    Title = Column(String(255), nullable=False)
    Director = Column(String(255))
    Genre = Column(String(100))
    Plot = Column(Text)

class User(Base):
    __tablename__ = "Users"
    UserID = Column(Integer, primary_key=True, index=True)
    NameSurname = Column(String(100), nullable=False)
    Username = Column(String(50), nullable=False, unique=True)
    Email = Column(String(100), nullable=False, unique=True)
    Password_ = Column(String(250), nullable=False)  


class BookReview(Base):
    __tablename__ = "BookReviews"
    ReviewID = Column(Integer, primary_key=True, index=True)
    UserID = Column(Integer, ForeignKey("Users.UserID"), nullable=False)
    BookID = Column(Integer, ForeignKey("Books.BookID"), nullable=False)
    Rating = Column(Integer, nullable=False) 
    ReviewText = Column(Text) 


class MovieReview(Base):
    __tablename__ = "MovieReviews"
    ReviewID = Column(Integer, primary_key=True, index=True)
    UserID = Column(Integer, ForeignKey("Users.UserID"), nullable=False)
    MovieID = Column(Integer, ForeignKey("Movies.MovieID"), nullable=False)
    Rating = Column(Integer, nullable=False)
    ReviewText = Column(Text)  
    
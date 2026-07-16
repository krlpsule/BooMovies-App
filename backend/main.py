from http.client import HTTPException

from fastapi import FastAPI, Depends
from sqlalchemy.orm import Session
from database import SessionLocal, engine
import models
from schemas import UserCreate, MovieCreate, BookCreate, BookReviewCreate, MovieReviewCreate, UserLogin


models.Base.metadata.create_all(bind=engine)

app = FastAPI()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
# main.py en tepeye ekle
@app.middleware("http")
async def log_requests(request, call_next):
    print(f"Gelen istek: {request.method} {request.url}")
    response = await call_next(request)
    return response        

@app.get("/books")
def get_books(db: Session = Depends(get_db)):
    books = db.query(models.Book).all()
    return books

@app.get("/movies")
def get_movies(db: Session = Depends(get_db)):
    movies = db.query(models.Movie).all()
    return movies

@app.get("/users")
def get_users(db: Session = Depends(get_db)):
    users = db.query(models.User).all()
    return users

@app.get("/book_reviews")
def get_book_reviews(db: Session = Depends(get_db)):
    reviews = db.query(models.BookReview).all()
    return reviews

@app.get("/movie_reviews")
def get_movie_reviews(db: Session = Depends(get_db)):
    reviews = db.query(models.MovieReview).all()
    return reviews

@app.post("/login")
def login(user: UserLogin, db: Session = Depends(get_db)):
    # Kullanıcıyı veritabanında ara
    db_user = db.query(models.User).filter(
        models.User.Username == user.Username, 
        models.User.Password_ == user.Password_
    ).first()
    
    if not db_user:
        raise HTTPException(status_code=400, detail="Hatalı kullanıcı adı veya şifre")
    
    return {"message": "Giriş başarılı", "UserID": db_user.UserID}


@app.post("/add_user")
def add_user(user: UserCreate, db: Session = Depends(get_db)):
    new_user = models.User( 
        NameSurname=user.NameSurname,
        Username=user.Username,
        Email=user.Email,
        Password_=user.Password_
    ) 
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user

@app.post("/add_movie_if_not_exists")
def add_movie_if_not_exists(movie: MovieCreate, db: Session = Depends(get_db)):   
    existing_movie = db.query(models.Movie).filter(models.Movie.Title == movie.Title).first()
    
    if existing_movie:
        return existing_movie 
    new_movie = models.Movie(
        Title=movie.Title,
        Director=movie.Director,
        Genre=movie.Genre,
        Plot=movie.Plot
    )
    db.add(new_movie)
    db.commit()
    db.refresh(new_movie)
    return new_movie


@app.post("/add_book_if_not_exists")
def add_book_if_not_exists(book: BookCreate, db: Session = Depends(get_db)):
   
    existing_book = db.query(models.Book).filter(models.Book.Title == book.Title).first()
    
    if existing_book:
        return existing_book 

    new_book = models.Book(
        Title=book.Title,
        Author=book.Author,
        Genre=book.Genre,
        Summary=book.Summary
    )
    db.add(new_book)
    db.commit()
    db.refresh(new_book)
    return new_book

@app.post("/add_book_review")
def add_book_review(review: BookReviewCreate, db: Session = Depends(get_db)):
    new_review = models.BookReview(
        UserID=review.UserID,
        BookID=review.BookID,
        Rating=review.Rating,
        ReviewText=review.ReviewText
    )
    db.add(new_review)
    db.commit()
    db.refresh(new_review)
    return new_review

@app.post("/add_movie_review")
def add_movie_review(review: MovieReviewCreate, db: Session = Depends(get_db)):
    new_review = models.MovieReview(
        UserID=review.UserID,
        MovieID=review.MovieID,
        Rating=review.Rating,
        ReviewText=review.ReviewText
    )
    db.add(new_review)
    db.commit()
    db.refresh(new_review)
    return new_review

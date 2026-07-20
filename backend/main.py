from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from database import SessionLocal, engine
import models
from schemas import UserCreate, MovieCreate, BookCreate, BookReviewCreate, MovieReviewCreate, UserLibraryCreate, UserLogin, UserWatchlistCreate

# Veritabanı tablolarını oluştur
models.Base.metadata.create_all(bind=engine)

app = FastAPI()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# --- Middleware (İstekleri loglama) ---
@app.middleware("http")
async def log_requests(request, call_next):
    print(f"Gelen istek: {request.method} {request.url}")
    response = await call_next(request)
    return response

# --- GET ENDPOINTLERİ ---
@app.get("/books")
def get_books(db: Session = Depends(get_db)):
    return db.query(models.Book).all()

@app.get("/movies")
def get_movies(db: Session = Depends(get_db)):
    return db.query(models.Movie).all()

@app.get("/users")
def get_users(db: Session = Depends(get_db)):
    return db.query(models.User).all()

@app.get("/book_reviews")
def get_book_reviews(db: Session = Depends(get_db)):
    return db.query(models.BookReview).all()

@app.get("/movie_reviews")
def get_movie_reviews(db: Session = Depends(get_db)):
    return db.query(models.MovieReview).all()

# --- AUTH & USER ---
@app.post("/login")
def login(user: UserLogin, db: Session = Depends(get_db)):
    db_user = db.query(models.User).filter(
        models.User.Username == user.Username, 
        models.User.Password_ == user.Password_
    ).first()
    if not db_user:
        raise HTTPException(status_code=400, detail="Hatalı kullanıcı adı veya şifre")
    return {"message": "Giriş başarılı", "UserID": db_user.UserID, "Username": db_user.Username}

@app.post("/add_user")
def add_user(user: UserCreate, db: Session = Depends(get_db)):
    new_user = models.User(NameSurname=user.NameSurname, Username=user.Username, Email=user.Email, Password_=user.Password_) 
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user

# --- CONTENT MANAGEMENT ---
@app.post("/add_movie_if_not_exists")
def add_movie_if_not_exists(movie: MovieCreate, db: Session = Depends(get_db)):   
    existing = db.query(models.Movie).filter(models.Movie.Title == movie.Title).first()
    if existing: return existing 
    # YENİ: PosterUrl eklendi
    new_movie = models.Movie(Title=movie.Title, Director=movie.Director, Genre=movie.Genre, Plot=movie.Plot, PosterUrl=movie.PosterUrl)
    db.add(new_movie)
    db.commit()
    db.refresh(new_movie)
    return new_movie

@app.post("/add_book_if_not_exists")
def add_book_if_not_exists(book: BookCreate, db: Session = Depends(get_db)):
    existing = db.query(models.Book).filter(models.Book.Title == book.Title).first()
    if existing: return existing 
    # YENİ: CoverUrl eklendi
    new_book = models.Book(Title=book.Title, Author=book.Author, Genre=book.Genre, Summary=book.Summary, CoverUrl=book.CoverUrl)
    db.add(new_book)
    db.commit()
    db.refresh(new_book)
    return new_book

# --- REVIEW ENDPOINTLERİ ---
@app.post("/add_book_review")
def add_book_review(review: BookReviewCreate, db: Session = Depends(get_db)):
    new_review = models.BookReview(UserID=review.UserID, BookID=review.BookID, Rating=review.Rating, ReviewText=review.ReviewText)
    db.add(new_review)
    db.commit()
    db.refresh(new_review)
    return new_review

@app.post("/add_movie_review")
def add_movie_review(review: MovieReviewCreate, db: Session = Depends(get_db)):
    new_review = models.MovieReview(UserID=review.UserID, MovieID=review.MovieID, Rating=review.Rating, ReviewText=review.ReviewText)
    db.add(new_review)
    db.commit()
    db.refresh(new_review)
    return new_review

# --- LIBRARY & WATCHLIST ---
@app.post("/add_to_library")
def add_to_library(entry: UserLibraryCreate, db: Session = Depends(get_db)):
    if db.query(models.UserLibrary).filter(models.UserLibrary.UserID == entry.UserID, models.UserLibrary.BookID == entry.BookID).first():
        return {"message": "Kitap zaten kütüphanenizde var."}
    new_entry = models.UserLibrary(UserID=entry.UserID, BookID=entry.BookID)
    db.add(new_entry)
    db.commit()
    return {"message": "Kitap kütüphaneye eklendi."}

@app.post("/add_to_watchlist")
def add_to_watchlist(entry: UserWatchlistCreate, db: Session = Depends(get_db)):
    if db.query(models.UserWatchlist).filter(models.UserWatchlist.UserID == entry.UserID, models.UserWatchlist.MovieID == entry.MovieID).first():
        return {"message": "Film zaten listenizde var."}
    new_entry = models.UserWatchlist(UserID=entry.UserID, MovieID=entry.MovieID)
    db.add(new_entry)
    db.commit()
    return {"message": "Film listeye eklendi."}

@app.get("/book/{book_id}/details")
def get_book_details(book_id: int, db: Session = Depends(get_db)):
    book = db.query(models.Book).filter(models.Book.BookID == book_id).first()
    if not book:
        raise HTTPException(status_code=404, detail="Kitap bulunamadı")

    reviews = db.query(models.BookReview).filter(models.BookReview.BookID == book_id).all()
    review_list = []
    for r in reviews:
        user = db.query(models.User).filter(models.User.UserID == r.UserID).first()
        review_list.append({
            "ReviewID": r.ReviewID,
            "UserID": r.UserID,
            "Username": user.Username if user else "Bilinmeyen Kullanıcı",
            "Rating": r.Rating,
            "ReviewText": r.ReviewText,
        })

    return {
        "BookID": book.BookID,
        "Title": book.Title,
        "Author": book.Author,
        "Genre": book.Genre,
        "Summary": book.Summary,
        "CoverUrl": book.CoverUrl,
        "Reviews": review_list,
    }

@app.get("/movie/{movie_id}/details")
def get_movie_details(movie_id: int, db: Session = Depends(get_db)):
    movie = db.query(models.Movie).filter(models.Movie.MovieID == movie_id).first()
    if not movie:
        raise HTTPException(status_code=404, detail="Film bulunamadı")

    reviews = db.query(models.MovieReview).filter(models.MovieReview.MovieID == movie_id).all()
    review_list = []
    for r in reviews:
        user = db.query(models.User).filter(models.User.UserID == r.UserID).first()
        review_list.append({
            "ReviewID": r.ReviewID,
            "UserID": r.UserID,
            "Username": user.Username if user else "Bilinmeyen Kullanıcı",
            "Rating": r.Rating,
            "ReviewText": r.ReviewText,
        })

    return {
        "MovieID": movie.MovieID,
        "Title": movie.Title,
        "Director": movie.Director,
        "Genre": movie.Genre,
        "Plot": movie.Plot,
        "PosterUrl": movie.PosterUrl, 
        "Reviews": review_list,
    }

@app.get("/user/{user_id}/library")
def get_user_library(user_id: int, db: Session = Depends(get_db)):
    library = db.query(models.UserLibrary).filter(models.UserLibrary.UserID == user_id).all()
    result = []
    for entry in library:
        book = db.query(models.Book).filter(models.Book.BookID == entry.BookID).first()
        if book:
            review = db.query(models.BookReview).filter(models.BookReview.UserID == user_id, models.BookReview.BookID == entry.BookID).first()
           
            result.append({
                "BookID": book.BookID, 
                "Title": book.Title, 
                "Author": book.Author, 
                "Rating": review.Rating if review else "Yok",
                "CoverUrl": book.CoverUrl 
            })
    return result

@app.get("/user/{user_id}/watchlist")
def get_user_watchlist(user_id: int, db: Session = Depends(get_db)):
    watchlist = db.query(models.UserWatchlist).filter(models.UserWatchlist.UserID == user_id).all()
    result = []
    for entry in watchlist:
        movie = db.query(models.Movie).filter(models.Movie.MovieID == entry.MovieID).first()
        if movie:
            review = db.query(models.MovieReview).filter(models.MovieReview.UserID == user_id, models.MovieReview.MovieID == entry.MovieID).first()
            
            result.append({
                "MovieID": movie.MovieID, 
                "Title": movie.Title, 
                "Director": movie.Director, 
                "Rating": review.Rating if review else "Yok",
                "PosterUrl": movie.PosterUrl
            })
    return result
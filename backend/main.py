from fastapi import FastAPI, Depends, HTTPException, BackgroundTasks
from sqlalchemy.orm import Session
from sqlalchemy import func
from database import SessionLocal, engine
import models
from schemas import UserCreate, MovieCreate, BookCreate, BookReviewCreate, MovieReviewCreate, UserLibraryCreate, UserLogin, UserWatchlistCreate
from gemini_service import enrich_book_info, enrich_movie_info

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

# --- ARKA PLAN GÖREVLERİ (Gemini zenginleştirme, isteği yavaşlatmaması için) ---
def _enrich_movie_in_background(movie_id: int, title: str, director: str, genre: str, plot: str):
    enriched = enrich_movie_info(title, director, genre, plot)
    db = SessionLocal()
    try:
        movie_row = db.query(models.Movie).filter(models.Movie.MovieID == movie_id).first()
        if movie_row:
            movie_row.Director = enriched["Director"]
            movie_row.Genre = enriched["Genre"]
            movie_row.Plot = enriched["Plot"]
            db.commit()
            print(f"Gemini zenginleştirme tamamlandı: MovieID={movie_id}")
    finally:
        db.close()

def _enrich_book_in_background(book_id: int, title: str, author: str, genre: str, summary: str):
    enriched = enrich_book_info(title, author, genre, summary)
    db = SessionLocal()
    try:
        book_row = db.query(models.Book).filter(models.Book.BookID == book_id).first()
        if book_row:
            book_row.Author = enriched["Author"]
            book_row.Genre = enriched["Genre"]
            book_row.Summary = enriched["Summary"]
            db.commit()
            print(f"Gemini zenginleştirme tamamlandı: BookID={book_id}")
    finally:
        db.close()

# --- CONTENT MANAGEMENT ---
@app.post("/add_movie_if_not_exists")
def add_movie_if_not_exists(movie: MovieCreate, background_tasks: BackgroundTasks, db: Session = Depends(get_db)):
    existing = db.query(models.Movie).filter(models.Movie.Title == movie.Title).first()
    if existing: return existing 

    # Eldeki bilgilerle hemen kaydet, kullanıcı beklemesin
    new_movie = models.Movie(
        Title=movie.Title,
        Director=movie.Director,
        Genre=movie.Genre,
        Plot=movie.Plot,
        PosterUrl=movie.PosterUrl,
    )
    db.add(new_movie)
    db.commit()
    db.refresh(new_movie)

    # Eksik alanlar varsa (Director/Genre/Plot), Gemini zenginleştirmesini arka planda çalıştır
    background_tasks.add_task(
        _enrich_movie_in_background,
        new_movie.MovieID, movie.Title, movie.Director, movie.Genre, movie.Plot,
    )

    return new_movie

@app.post("/add_book_if_not_exists")
def add_book_if_not_exists(book: BookCreate, background_tasks: BackgroundTasks, db: Session = Depends(get_db)):
    existing = db.query(models.Book).filter(models.Book.Title == book.Title).first()
    if existing: return existing 

    # Eldeki bilgilerle hemen kaydet, kullanıcı beklemesin
    new_book = models.Book(
        Title=book.Title,
        Author=book.Author,
        Genre=book.Genre,
        Summary=book.Summary,
        CoverUrl=book.CoverUrl,
    )
    db.add(new_book)
    db.commit()
    db.refresh(new_book)

    # Eksik alanlar varsa (Author/Genre/Summary), Gemini zenginleştirmesini arka planda çalıştır
    background_tasks.add_task(
        _enrich_book_in_background,
        new_book.BookID, book.Title, book.Author, book.Genre, book.Summary,
    )

    return new_book

# --- REVIEW ENDPOINTLERİ ---
@app.post("/add_book_review")
def add_book_review(review: BookReviewCreate, db: Session = Depends(get_db)):
    existing = db.query(models.BookReview).filter(
        models.BookReview.UserID == review.UserID,
        models.BookReview.BookID == review.BookID,
    ).first()
    if existing:
        existing.Rating = review.Rating
        existing.ReviewText = review.ReviewText
        db.commit()
        db.refresh(existing)
        return existing

    new_review = models.BookReview(UserID=review.UserID, BookID=review.BookID, Rating=review.Rating, ReviewText=review.ReviewText)
    db.add(new_review)
    db.commit()
    db.refresh(new_review)
    return new_review

@app.post("/add_movie_review")
def add_movie_review(review: MovieReviewCreate, db: Session = Depends(get_db)):
    existing = db.query(models.MovieReview).filter(
        models.MovieReview.UserID == review.UserID,
        models.MovieReview.MovieID == review.MovieID,
    ).first()
    if existing:
        existing.Rating = review.Rating
        existing.ReviewText = review.ReviewText
        db.commit()
        db.refresh(existing)
        return existing

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

@app.delete("/remove_from_library/{user_id}/{book_id}")
def remove_from_library(user_id: int, book_id: int, db: Session = Depends(get_db)):
    entry = db.query(models.UserLibrary).filter(
        models.UserLibrary.UserID == user_id,
        models.UserLibrary.BookID == book_id,
    ).first()
    if not entry:
        raise HTTPException(status_code=404, detail="Kitap kütüphanenizde bulunamadı.")

    # Kullanıcının bu kitaba yaptığı yorumları da temizle, bu sonradan değişebilir emin değilim
    db.query(models.BookReview).filter(
        models.BookReview.UserID == user_id,
        models.BookReview.BookID == book_id,
    ).delete()

    db.delete(entry)
    db.commit()
    return {"message": "Kitap kütüphaneden kaldırıldı."}

@app.delete("/remove_from_watchlist/{user_id}/{movie_id}")
def remove_from_watchlist(user_id: int, movie_id: int, db: Session = Depends(get_db)):
    entry = db.query(models.UserWatchlist).filter(
        models.UserWatchlist.UserID == user_id,
        models.UserWatchlist.MovieID == movie_id,
    ).first()
    if not entry:
        raise HTTPException(status_code=404, detail="Film listenizde bulunamadı.")

    # Kullanıcının bu filme yaptığı yorumları da temizle, bu sonradan değişebilir emin değilim

    db.query(models.MovieReview).filter(
        models.MovieReview.UserID == user_id,
        models.MovieReview.MovieID == movie_id,
    ).delete()

    db.delete(entry)
    db.commit()
    return {"message": "Film listeden kaldırıldı."}

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
            avg_rating = db.query(func.avg(models.BookReview.Rating)).filter(
                models.BookReview.BookID == book.BookID
            ).scalar()
            own_review = db.query(models.BookReview).filter(
                models.BookReview.UserID == user_id,
                models.BookReview.BookID == book.BookID,
            ).first()

            result.append({
                "BookID": book.BookID,
                "Title": book.Title,
                "Author": book.Author,
                "AverageRating": round(avg_rating, 1) if avg_rating is not None else None,
                "UserRating": own_review.Rating if own_review else None,
                "UserReviewText": own_review.ReviewText if own_review else None,
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
            avg_rating = db.query(func.avg(models.MovieReview.Rating)).filter(
                models.MovieReview.MovieID == movie.MovieID
            ).scalar()
            own_review = db.query(models.MovieReview).filter(
                models.MovieReview.UserID == user_id,
                models.MovieReview.MovieID == movie.MovieID,
            ).first()

            result.append({
                "MovieID": movie.MovieID,
                "Title": movie.Title,
                "Director": movie.Director,
                "AverageRating": round(avg_rating, 1) if avg_rating is not None else None,
                "UserRating": own_review.Rating if own_review else None,
                "UserReviewText": own_review.ReviewText if own_review else None,
                "PosterUrl": movie.PosterUrl
            })
    return result
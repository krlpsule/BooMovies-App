import os
import json
import time
import requests
from dotenv import load_dotenv

load_dotenv()

GROQ_API_KEY = os.getenv("GROQ_API_KEY")
GROQ_MODEL = "openai/gpt-oss-20b"  
GROQ_URL = "https://api.groq.com/openai/v1/chat/completions"

RETRYABLE_STATUS_CODES = {429, 503}
MAX_RETRIES = 3
RETRY_BACKOFF_SECONDS = 3


def _is_empty(value: str | None) -> bool:
    return value is None or not value.strip()


def _call_groq(prompt: str, schema_name: str, schema: dict) -> dict | None:
    """Groq API'sine strict JSON schema modunda istek atar, ayrıştırılmış dict döner (hata varsa None).
    429/503 gibi geçici hatalarda otomatik olarak tekrar dener."""
    if not GROQ_API_KEY:
        print("UYARI: GROQ_API_KEY tanımlı değil. Yapay zeka zenginleştirme atlanıyor.")
        return None

    payload = {
        "model": GROQ_MODEL,
        "messages": [{"role": "user", "content": prompt}],
        "response_format": {
            "type": "json_schema",
            "json_schema": {
                "name": schema_name,
                "strict": True,
                "schema": schema,
            },
        },
    }
    headers = {
        "Authorization": f"Bearer {GROQ_API_KEY}",
        "Content-Type": "application/json",
    }

    for attempt in range(1, MAX_RETRIES + 1):
        try:
            response = requests.post(GROQ_URL, headers=headers, json=payload, timeout=30)

            if response.status_code == 200:
                data = response.json()
                text = data["choices"][0]["message"]["content"]
                return json.loads(text)

            if response.status_code in RETRYABLE_STATUS_CODES and attempt < MAX_RETRIES:
                wait = RETRY_BACKOFF_SECONDS * attempt
                print(
                    f"Groq API geçici hata ({response.status_code}), "
                    f"{wait}s sonra tekrar denenecek (deneme {attempt}/{MAX_RETRIES})..."
                )
                time.sleep(wait)
                continue

            print(f"Groq API hatası: {response.status_code} - {response.text[:300]}")
            return None

        except Exception as e:
            if attempt < MAX_RETRIES:
                wait = RETRY_BACKOFF_SECONDS * attempt
                print(
                    f"Groq API çağrısı sırasında hata: {e} — "
                    f"{wait}s sonra tekrar denenecek (deneme {attempt}/{MAX_RETRIES})..."
                )
                time.sleep(wait)
                continue
            print(f"Groq API çağrısı sırasında hata: {e}")
            return None

    return None


def enrich_book_info(title: str, author: str = "", genre: str = "", summary: str = "") -> dict:
    """Author/Genre/Summary alanlarından boş olanları Groq ile doldurur.
    Dolu olan alanlara dokunmaz, sadece eksikleri tamamlar."""
    missing = []
    if _is_empty(author):
        missing.append("author")
    if _is_empty(genre):
        missing.append("genre")
    if _is_empty(summary):
        missing.append("summary")

    if not missing:
        return {"Author": author, "Genre": genre, "Summary": summary}

    known_info = []
    if not _is_empty(author):
        known_info.append(f"yazar zaten biliniyor: {author}")
    if not _is_empty(genre):
        known_info.append(f"tür zaten biliniyor: {genre}")
    if not _is_empty(summary):
        known_info.append(f"özet zaten biliniyor: {summary}")

    prompt = (
        f"'{title}' isimli kitap hakkında bilgi araştır. "
        + (f"Bilinen bilgiler: {'; '.join(known_info)}. " if known_info else "")
        + f"Eksik olan şu alanları doldurman gerekiyor: {', '.join(missing)}. "
        "author: kitabın gerçek yazarının adı. "
        "genre: kısa bir tür ifadesi (örn. 'Bilim Kurgu', 'Roman', 'Fantastik', 'Klasik'). "
        "summary: kitabın konusunu özetleyen, spoiler içermeyen 2-3 cümlelik Türkçe bir özet. "
        "Kitabı tanımıyorsan veya emin değilsen ilgili alana 'Bilinmiyor' yaz, bilgi uydurma. "
        "Bilinen alanlar için, sana verilen bilgiyi aynen geri döndür. "
        "Sadece JSON formatında cevap ver."
    )

    schema = {
        "type": "object",
        "properties": {
            "author": {"type": "string"},
            "genre": {"type": "string"},
            "summary": {"type": "string"},
        },
        "required": ["author", "genre", "summary"],
        "additionalProperties": False,
    }

    result = _call_groq(prompt, "book_enrichment", schema) or {}

    return {
        "Author": author if not _is_empty(author) else result.get("author", "Bilinmiyor"),
        "Genre": genre if not _is_empty(genre) else result.get("genre", "Genel"),
        "Summary": summary if not _is_empty(summary) else result.get("summary", "Özet yok."),
    }


def enrich_movie_info(title: str, director: str = "", genre: str = "", plot: str = "") -> dict:
    """Director/Genre/Plot alanlarından boş olanları Groq ile doldurur."""
    missing = []
    if _is_empty(director):
        missing.append("director")
    if _is_empty(genre):
        missing.append("genre")
    if _is_empty(plot):
        missing.append("plot")

    if not missing:
        return {"Director": director, "Genre": genre, "Plot": plot}

    known_info = []
    if not _is_empty(director):
        known_info.append(f"yönetmen zaten biliniyor: {director}")
    if not _is_empty(genre):
        known_info.append(f"tür zaten biliniyor: {genre}")
    if not _is_empty(plot):
        known_info.append(f"konu zaten biliniyor: {plot}")

    prompt = (
        f"'{title}' isimli film hakkında bilgi araştır. "
        + (f"Bilinen bilgiler: {'; '.join(known_info)}. " if known_info else "")
        + f"Eksik olan şu alanları doldurman gerekiyor: {', '.join(missing)}. "
        "director: filmin gerçek yönetmeninin adı. "
        "genre: kısa bir tür ifadesi (örn. 'Bilim Kurgu', 'Dram', 'Komedi', 'Aksiyon'). "
        "plot: filmin konusunu özetleyen, spoiler içermeyen 2-3 cümlelik Türkçe bir özet. "
        "Filmi tanımıyorsan veya emin değilsen ilgili alana 'Bilinmiyor' yaz, bilgi uydurma. "
        "Bilinen alanlar için, sana verilen bilgiyi aynen geri döndür. "
        "Sadece JSON formatında cevap ver."
    )

    schema = {
        "type": "object",
        "properties": {
            "director": {"type": "string"},
            "genre": {"type": "string"},
            "plot": {"type": "string"},
        },
        "required": ["director", "genre", "plot"],
        "additionalProperties": False,
    }

    result = _call_groq(prompt, "movie_enrichment", schema) or {}

    return {
        "Director": director if not _is_empty(director) else result.get("director", "Bilinmiyor"),
        "Genre": genre if not _is_empty(genre) else result.get("genre", "Genel"),
        "Plot": plot if not _is_empty(plot) else result.get("plot", "Özet yok."),
    }


def recommend_books(user_books: list, custom_prompt: str = "") -> list:
    """Kullanıcının kütüphanesine göre kitap önerisi üretir."""
    if not GROQ_API_KEY:
        print("UYARI: GROQ_API_KEY tanımlı değil. Öneri üretilemiyor.")
        return []

    if user_books:
        books_text = "\n".join(
            f"- {b['title']} ({b.get('author') or 'yazar bilinmiyor'}), tür: {b.get('genre') or 'bilinmiyor'}"
            + (f", kullanıcının puanı: {b['rating']}/5" if b.get("rating") else "")
            for b in user_books
        )
    else:
        books_text = "Kullanıcının kütüphanesinde henüz hiç kitap yok."

    prompt = (
        "Aşağıda bir kullanıcının kütüphanesindeki kitaplar ve varsa kullanıcının verdiği puanlar listeleniyor:\n"
        f"{books_text}\n\n"
        + (f"Kullanıcının özel isteği: '{custom_prompt}'\n\n" if custom_prompt.strip() else "")
        + "Bu bilgilere dayanarak kullanıcının zevkine uygun, listesinde OLMAYAN 5 kitap öner. "
        "Yüksek puan verdiği kitaplara benzer tarz ve türdeki kitaplara öncelik ver. "
        "Her öneri için 'neden bu kitabı önerdiğini' açıklayan kısa (1-2 cümle) bir Türkçe gerekçe yaz. "
        "Gerçekten var olan kitaplar öner, uydurma. Sadece JSON formatında cevap ver."
    )

    schema = {
        "type": "object",
        "properties": {
            "recommendations": {
                "type": "array",
                "items": {
                    "type": "object",
                    "properties": {
                        "title": {"type": "string"},
                        "author": {"type": "string"},
                        "reason": {"type": "string"},
                    },
                    "required": ["title", "author", "reason"],
                    "additionalProperties": False,
                },
            }
        },
        "required": ["recommendations"],
        "additionalProperties": False,
    }

    result = _call_groq(prompt, "book_recommendations", schema)
    if not result:
        return []
    return result.get("recommendations", [])


def recommend_movies(user_movies: list, custom_prompt: str = "") -> list:
    """Kullanıcının izleme listesine göre film önerisi üretir."""
    if not GROQ_API_KEY:
        print("UYARI: GROQ_API_KEY tanımlı değil. Öneri üretilemiyor.")
        return []

    if user_movies:
        movies_text = "\n".join(
            f"- {m['title']} ({m.get('director') or 'yönetmen bilinmiyor'}), tür: {m.get('genre') or 'bilinmiyor'}"
            + (f", kullanıcının puanı: {m['rating']}/5" if m.get("rating") else "")
            for m in user_movies
        )
    else:
        movies_text = "Kullanıcının izleme listesinde henüz hiç film yok."

    prompt = (
        "Aşağıda bir kullanıcının izleme listesindeki filmler ve varsa kullanıcının verdiği puanlar listeleniyor:\n"
        f"{movies_text}\n\n"
        + (f"Kullanıcının özel isteği: '{custom_prompt}'\n\n" if custom_prompt.strip() else "")
        + "Bu bilgilere dayanarak kullanıcının zevkine uygun, listesinde OLMAYAN 5 film öner. "
        "Yüksek puan verdiği filmlere benzer tarz ve türdeki filmlere öncelik ver. "
        "Her öneri için 'neden bu filmi önerdiğini' açıklayan kısa (1-2 cümle) bir Türkçe gerekçe yaz. "
        "Gerçekten var olan filmler öner, uydurma. Sadece JSON formatında cevap ver."
    )

    schema = {
        "type": "object",
        "properties": {
            "recommendations": {
                "type": "array",
                "items": {
                    "type": "object",
                    "properties": {
                        "title": {"type": "string"},
                        "director": {"type": "string"},
                        "reason": {"type": "string"},
                    },
                    "required": ["title", "director", "reason"],
                    "additionalProperties": False,
                },
            }
        },
        "required": ["recommendations"],
        "additionalProperties": False,
    }

    result = _call_groq(prompt, "movie_recommendations", schema)
    if not result:
        return []
    return result.get("recommendations", [])
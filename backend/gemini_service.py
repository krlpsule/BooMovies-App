import os
import json
import requests
from dotenv import load_dotenv

load_dotenv()

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
GEMINI_MODEL = "gemini-3.5-flash"
GEMINI_URL = (
    f"https://generativelanguage.googleapis.com/v1beta/models/{GEMINI_MODEL}:generateContent"
)


def _is_empty(value: str | None) -> bool:
    return value is None or not value.strip()


def _call_gemini(prompt: str, schema: dict) -> dict | None:
    """Gemini API'sine JSON-modda istek atar, ayrıştırılmış dict döner (hata varsa None)."""
    if not GEMINI_API_KEY:
        print("UYARI: GEMINI_API_KEY tanımlı değil. Yapay zeka zenginleştirme atlanıyor.")
        return None

    payload = {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {
            "responseMimeType": "application/json",
            "responseSchema": schema,
            "thinkingConfig": {"thinkingLevel": "low"},
        },
    }

    try:
        response = requests.post(
            GEMINI_URL,
            params={"key": GEMINI_API_KEY},
            json=payload,
            timeout=60,
        )
        if response.status_code != 200:
            print(f"Gemini API hatası: {response.status_code} - {response.text[:300]}")
            return None

        data = response.json()
        text = data["candidates"][0]["content"]["parts"][0]["text"]
        return json.loads(text)
    except Exception as e:
        print(f"Gemini API çağrısı sırasında hata: {e}")
        return None


def enrich_book_info(title: str, author: str = "", genre: str = "", summary: str = "") -> dict:
    """Author/Genre/Summary alanlarından boş olanları Gemini ile doldurur.
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

    prompt = (
        f"'{title}' isimli kitap hakkında bilgi araştır. "
        f"Sadece şu alanları doldur: {', '.join(missing)}. "
        "author: kitabın gerçek yazarının adı. "
        "genre: kısa bir tür ifadesi (örn. 'Bilim Kurgu', 'Roman', 'Fantastik', 'Klasik'). "
        "summary: kitabın konusunu özetleyen, spoiler içermeyen 2-3 cümlelik Türkçe bir özet. "
        "Kitabı tanımıyorsan veya emin değilsen ilgili alana 'Bilinmiyor' yaz, bilgi uydurma."
    )

    schema = {
        "type": "OBJECT",
        "properties": {
            "author": {"type": "STRING"},
            "genre": {"type": "STRING"},
            "summary": {"type": "STRING"},
        },
        "required": missing,
    }

    result = _call_gemini(prompt, schema) or {}

    return {
        "Author": author if not _is_empty(author) else result.get("author", "Bilinmiyor"),
        "Genre": genre if not _is_empty(genre) else result.get("genre", "Genel"),
        "Summary": summary if not _is_empty(summary) else result.get("summary", "Özet yok."),
    }



def recommend_books(user_books: list, custom_prompt: str = "") -> list:
    """Kullanıcının kütüphanesine göre kitap önerisi üretir."""
    if not GEMINI_API_KEY:
        print("UYARI: GEMINI_API_KEY tanımlı değil. Öneri üretilemiyor.")
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
        "Her öneri için 'neden bu kitabı önerdiğini' açıklayan kısa (1-2 cümle) bir gerekçe yaz. "
        "Gerçekten var olan kitaplar öner, uydurma."
    )

    schema = {
        "type": "OBJECT",
        "properties": {
            "recommendations": {
                "type": "ARRAY",
                "items": {
                    "type": "OBJECT",
                    "properties": {
                        "title": {"type": "STRING"},
                        "author": {"type": "STRING"},
                        "reason": {"type": "STRING"},
                    },
                    "required": ["title", "author", "reason"],
                },
            }
        },
        "required": ["recommendations"],
    }

    result = _call_gemini(prompt, schema)
    if not result:
        return []
    return result.get("recommendations", [])


def recommend_movies(user_movies: list, custom_prompt: str = "") -> list:
    """Kullanıcının izleme listesine göre film önerisi üretir."""
    if not GEMINI_API_KEY:
        print("UYARI: GEMINI_API_KEY tanımlı değil. Öneri üretilemiyor.")
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
        "Her öneri için 'neden bu filmi önerdiğini' açıklayan kısa (1-2 cümle) bir gerekçe yaz. "
        "Gerçekten var olan filmler öner, uydurma."
    )

    schema = {
        "type": "OBJECT",
        "properties": {
            "recommendations": {
                "type": "ARRAY",
                "items": {
                    "type": "OBJECT",
                    "properties": {
                        "title": {"type": "STRING"},
                        "director": {"type": "STRING"},
                        "reason": {"type": "STRING"},
                    },
                    "required": ["title", "director", "reason"],
                },
            }
        },
        "required": ["recommendations"],
    }

    result = _call_gemini(prompt, schema)
    if not result:
        return []
    return result.get("recommendations", [])


def enrich_movie_info(title: str, director: str = "", genre: str = "", plot: str = "") -> dict:
    """Director/Genre/Plot alanlarından boş olanları Gemini ile doldurur."""
    missing = []
    if _is_empty(director):
        missing.append("director")
    if _is_empty(genre):
        missing.append("genre")
    if _is_empty(plot):
        missing.append("plot")

    if not missing:
        return {"Director": director, "Genre": genre, "Plot": plot}

    prompt = (
        f"'{title}' isimli film hakkında bilgi araştır. "
        f"Sadece şu alanları doldur: {', '.join(missing)}. "
        "director: filmin gerçek yönetmeninin adı. "
        "genre: kısa bir tür ifadesi (örn. 'Bilim Kurgu', 'Dram', 'Komedi', 'Aksiyon'). "
        "plot: filmin konusunu özetleyen, spoiler içermeyen 2-3 cümlelik Türkçe bir özet. "
        "Filmi tanımıyorsan veya emin değilsen ilgili alana 'Bilinmiyor' yaz, bilgi uydurma."
    )

    schema = {
        "type": "OBJECT",
        "properties": {
            "director": {"type": "STRING"},
            "genre": {"type": "STRING"},
            "plot": {"type": "STRING"},
        },
        "required": missing,
    }

    result = _call_gemini(prompt, schema) or {}

    return {
        "Director": director if not _is_empty(director) else result.get("director", "Bilinmiyor"),
        "Genre": genre if not _is_empty(genre) else result.get("genre", "Genel"),
        "Plot": plot if not _is_empty(plot) else result.get("plot", "Özet yok."),
    }
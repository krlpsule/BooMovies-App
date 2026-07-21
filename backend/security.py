import bcrypt


def hash_password(plain_password: str) -> str:
    """Şifreyi bcrypt ile hash'ler, DB'ye kaydedilecek string'i döner."""
    hashed = bcrypt.hashpw(plain_password.encode("utf-8"), bcrypt.gensalt())
    return hashed.decode("utf-8")


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Girilen şifrenin, DB'deki bcrypt hash'iyle eşleşip eşleşmediğini kontrol eder."""
    try:
        return bcrypt.checkpw(
            plain_password.encode("utf-8"), hashed_password.encode("utf-8")
        )
    except ValueError:
        # hashed_password bcrypt formatında değilse (örn. eski düz metin şifre) buraya düşer
        return False


def is_bcrypt_hash(value: str) -> bool:
    """Verilen string'in bcrypt hash formatında olup olmadığını kontrol eder.
    Eski (hash'lenmemiş) kullanıcı şifrelerini ayırt etmek için kullanılır."""
    return value.startswith(("$2a$", "$2b$", "$2y$"))
"""
HTTP-klient til NextSip-backend (NestJS + Redis).

"""

import requests

# Backend koerer paa samme Pi som dette script
API_URL = "http://127.0.0.1:3000"
TIMEOUT = 3


def init_db():
    """Tjekker om backend er naaeligt og skriver besked til konsollen."""
    try:
        response = requests.get(f"{API_URL}/health", timeout=TIMEOUT)
        response.raise_for_status()
        print("Backend OK:", API_URL)
    except requests.RequestException as e:
        print(f"ADVARSEL: kan ikke naa backend paa {API_URL} ({e})")


def uid_to_str(uid_bytes):
    return "".join(f"{b:02x}" for b in uid_bytes)


def ensure_card(uid_str):
    """Henter saldo for kortet. Backend opretter automatisk nye kort
    med saldo 0, hvis UID'en ikke er set foer."""
    response = requests.get(f"{API_URL}/cards/{uid_str}", timeout=TIMEOUT)
    response.raise_for_status()
    return response.json()["balance"]


def get_balance(uid_str):
    return ensure_card(uid_str)


def add_to_balance(uid_str, item, price):
    """Bogfoerer et koeb (vare + pris) og returnerer det nye saldo."""
    response = requests.post(
        f"{API_URL}/cards/{uid_str}/transactions",
        json={"item": item, "price": price},
        timeout=TIMEOUT,
    )
    response.raise_for_status()
    return response.json()["balance"]

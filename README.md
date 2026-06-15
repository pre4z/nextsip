Backend er lavet som et NestJS-API og bruger Redis som database.

Systemet holder styr på saldo pr. kort-UID, gemmer transaktionshistorik og har et simpelt admin-område med login via JWT.

Krav på Raspberry Pi

Før projektet kan køres, skal Node.js være installeret på Raspberry Pi’en.

Tjek først Node-versionen:

node -v

Versionen bør være 18 eller nyere.

Hvis Node.js mangler eller versionen er for gammel, kan det installeres med:

sudo apt update
sudo apt install -y nodejs npm

Redis skal også installeres og startes:

sudo apt install -y redis-server
sudo systemctl enable --now redis-server
redis-cli ping

Hvis Redis kører korrekt, bør kommandoen svare med:

PONG
Installation og setup

Gå ind i backend-mappen og installer dependencies:

cd nextsip-backend
npm install

Derefter kopieres miljøfilen:

cp .env.example .env

I .env-filen skal følgende værdier sættes:

JWT_SECRET=
ADMIN_USERNAME=
ADMIN_PASSWORD=

Disse bruges til admin-login og JWT-authentication.

Start af backend

Under udvikling kan backend startes med auto-reload:

npm run start:dev

Til produktion bygges og startes projektet sådan:

npm run build
npm run start:prod

Når serveren kører, er API’et tilgængeligt på:

http://<pi-ip>:3000

Pi’ens IP-adresse kan findes med:

hostname -I

dispenser.py kan kalde backend lokalt via 127.0.0.1, mens Flutter-appen kalder backend via Pi’ens IP-adresse på netværket.

API-overblik
Offentlige endpoints

Disse endpoints bruges af Raspberry Pi’en og Flutter-kundedelen.

Hent kort og saldo
GET /cards/:uid

Returnerer:

{ "uid": "...", "balance": 0 }

Hvis kortet ikke findes endnu, bliver det oprettet med saldo 0.

Opret transaktion
POST /cards/:uid/transactions

Body:

{
  "item": "...",
  "price": 0
}

Dette trækker beløbet fra kortets saldo og returnerer den nye saldo.

Betaling / nulstilling af saldo
POST /cards/:uid/pay

Dette sætter saldoen til 0.

I projektet bruges dette som Proof-of-Concept for betaling.

Admin endpoints

Admin-endpoints kræver JWT-token.

Login
POST /auth/login

Body:

{
  "username": "...",
  "password": "..."
}

Returnerer:

{
  "access_token": "..."
}
Hent alle kort
GET /admin/cards

Returnerer en liste over alle kendte kort og deres saldo.

Hent alle transaktioner
GET /admin/transactions

Returnerer en samlet historik over alle bookinger/transaktioner.

Ret saldo manuelt
PATCH /admin/cards/:uid

Body:

{
  "balance": 0
}

Dette bruges til manuelt at ændre saldoen på et kort.

Ved kald til admin-endpoints skal JWT-token sendes med i headeren:

Authorization: Bearer <token>
Redis-datamodel

Backend gemmer data i Redis med følgende struktur:

cards

Set med alle kendte kort-UIDs.

card:<uid>

Hash med kortets saldo:

{ "balance": 0 }
transactions

Liste med alle transaktioner gemt som JSON:

{
  "uid": "...",
  "item": "...",
  "price": 0,
  "timestamp": "..."
}

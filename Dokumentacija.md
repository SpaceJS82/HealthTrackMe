# Dokumentacija: Yoa Health Tracker & Coach

## 1. Opis funkcionalnosti rešitve

Aplikacija omogoča uporabnikom sledenje telesni aktivnosti, meritvam zdravja (kot so spanec in stres) ter deljenje rezultatov s prijatelji. Ključne funkcionalnosti vključujejo:

* **Merjenje zdravja:** aplikacija uporablja Apple HealthKit za sledenje spancu, stresu, vadbi ipd.
* **Dnevnik dogodkov:** uporabniki lahko nalagajo dogodke, kot so vadbe, z metapodatki (trajanje, aktivnost itd.).
* **Prijateljski sistem:** uporabniki lahko pošiljajo in prejemajo prošnje za prijateljstvo, sprejemajo ali zavračajo prošnje in odstranjujejo prijatelje.
* **Deljenje zdravja in spanca:** z izrecnim soglasjem lahko prijatelji med seboj delijo podatke, kot so točkovanje spanca ali dnevna vadba.
* **Reakcije na dogodke:** uporabniki lahko reagirajo na dogodke drugih uporabnikov z emojiji.
* **Analitika uporabe:** administratorji imajo dostop do statističnega pregleda uporabe aplikacije prek ločene upravljalske plošče.

---

## 2. Arhitektura in komponente rešitve

### Backend:

* **Tehnologije:** Express.js z MySQL preko Knex.js kot ORM.
* **JWT avtentikacija:** vključen je zaščiten sistem za preverjanje uporabnikov z žetoni.
* **Modularna struktura:** ločeni moduli za upravljanje s prijatelji, dogodki, meritvami zdravja, profilom, obvestili in analitiko.
* **API endpointi so zavarovani z `verifyToken` middleware-om.**

### Frontend (mobilna aplikacija):

* **Swift / SwiftUI:** aplikacija je izključno za iOS in uporablja HealthKit za zbiranje podatkov o uporabniku.
* **Integracija z Apple Watch:** dodatna aplikacija za sledenje spancu in vadbi v realnem času.

### Admin Panel:

* **Tehnologije:** React.js
* **Namen:** omogoča vpogled v agregirane podatke analitike, kot so št. prijateljstev, stopnja konverzije povabil, uporaba aplikacije skozi čas itd.
* **URL:** `https://api.getyoa.app/yoaapi/analytics/*`

---

## 3. Simuliran zaledni sistem in operaterska platforma

Simulacija strežnika za razvoj poteka lokalno ali na produkcijskem naslovu `https://api.getyoa.app/yoaapi`. Admin panel (operaterska platforma) omogoča naslednje funkcionalnosti:

* **Statistika uporabe aplikacije:** kot so dnevne nove prijateljske povezave, stopnja sprejemanja povabil in aktivnost uporabnikov.
* **Dostop preko varovanih API klicev:** vsak zahtevek vsebuje JWT v `Authorization` glavi.
* **Primer zahteve:**

```js
fetch('https://api.getyoa.app/yoaapi/analytics/friendship/per-day', {
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`
  }
})
```

---

## 4. REST vmesnik

Aplikacija temelji na RESTful vmesniku. Vsi klici API potekajo preko poti `/yoaapi` na strežniku in zahtevajo avtentikacijo z JWT. Ključni endpointi vključujejo:

### 🔐 Avtentikacija

* **POST** `/login`: vrača JWT in podatke o uporabniku.
* **POST** `/register`: registracija novega uporabnika.
* **GET** `/check-auth`: preverjanje veljavnosti žetona.

### 👥 Prijateljski sistem

* **GET** `/friends`: seznam prijateljev.
* **POST** `/friends/send-request`: pošiljanje prošnje.
* **POST** `/friends/answer-request`: odobritev/zavrnitev prošnje.
* **DELETE** `/friends/remove`: odstranitev prijatelja.
* **GET** `/friends/get-requests`: prejete prošnje.

### 🏋️‍♀️ Dogodki (vadba ipd.)

* **GET** `/events/get-events`: vsi dogodki uporabnika in prijateljev.
* **POST** `/events/upload-event`: dodaj nov dogodek.
* **POST** `/events/react`: dodaj reakcijo na dogodek.
* **GET** `/events/get-event-reactions?eventId=123`: pridobi reakcije za dogodek.

### 💓 Meritve zdravja

* **GET** `/health/health-metrics`: podatki uporabnika (npr. spanec, vadba).
* **POST** `/health/upload-health-metric`: dodaj novo meritev.
* **GET** `/health/friend-sleep-scores`: vpogled v spanec prijateljev (z dovoljenjem).
* **DELETE** `/health/delete/health-metric/:date`: odstrani meritev.

### ⚙️ Profil

* **PATCH** `/profile/username`: posodobi uporabniško ime.
* **PATCH** `/profile/password`: posodobi geslo.

---


## 5. Yoa Health Tracker & Coach – pregled rešitve

**Yoa Health Tracker & Coach** je iOS aplikacija, namenjena uporabnikom, ki želijo poglobljeno razumeti in izboljšati svoje zdravje s pomočjo Apple Watcha oziroma drugih naprav, ki sinhronizirajo podatke z Apple Health. Aplikacija ponuja celovit vpogled v zdravstvene navade posameznika preko metrik, kot so *sleep score*, *fitness score*, *stress score*, in druge vitalne vrednosti. Na podlagi teh podatkov aplikacija podaja tudi praktične, prilagojene nasvete za izboljšanje življenjskega sloga.

Uporabniki lahko spremljajo:
- **Odstopanja** vrednosti od običajnega stanja (npr. HRV, spanje, aktivnost),
- **Trende skozi čas** za posamezne metrike (npr. akumulacija vadb),
- **Vsakodnevni dnevnik** navad, kjer aplikacija analizira vpliv dnevnih dejavnosti na spanje in srčni utrip,
- **Socialne funkcionalnosti**, kjer lahko uporabniki delijo svoje rezultate (npr. sleep score, workouts) s prijatelji in reagirajo na njihove objave.

Rešitev vključuje tudi aplikacijo za Apple Watch, ki služi kot pasivni senzor in omogoča sinhronizacijo z iOS aplikacijo. Backend infrastruktura podpira socialne funkcionalnosti prek ExpressJS API-ja na NGINX strežniku ter uporablja MySQL podatkovno bazo za shranjevanje in upravljanje podatkov.

### 5.1 Struktura uporabniških vmesnikov

Aplikacija je razdeljena v več ključnih uporabniških sklopov:
- **Dashboard (Pregledna plošča)**: prikazuje glavne metrike (sleep, fitness, stress scores), dnevne cilje in ključna odstopanja.
- **Journal (Dnevnik)**: uporabnik vsak dan vnese aktivnosti/navade, sistem pa analizira njihov vpliv na zdravje (npr. HRV, spanje).
- **Workouts**: prikaz vadb skozi čas, vključno z metrikami napora in okrevanja.
- **Social Feed**: funkcionalnost za povezovanje s prijatelji, pregled deljenih statistik in interakcije (reakcije, komentarji).
- **Profil**: osebne nastavitve, cilji, sinhronizacija z Apple Health in podatki o napravi.
- **Notifications & Suggestions**: obvestila z nasveti in opozorili glede odstopanj ali doseženih ciljev.

iOS aplikacija je razvita v **Swift z UIKit**, Apple Watch aplikacija v **SwiftUI**, kar omogoča moderno, odzivno in intuitivno uporabniško izkušnjo.

## 6. Struktura rešitve

Aplikacija je sestavljena iz iOS in Apple Watch aplikacije ter backend strežnika.

### 6.1 iOS aplikacija

- **Jezik in ogrodje**: Swift + UIKit
- **Organizacija kode**: ViewController struktura in backend data layer
- **HealthKit** integracija za zbiranje podatkov
- **Na napravi poteka analiza dnevnika in generiranje priporočil**

### 6.2 Apple Watch aplikacija

- Razvita v **SwiftUI**
- Sinhronizacija z Apple Health za zajem podatkov

### 6.3 Backend

- REST API na **ExpressJS** s **MySQL** bazo
- Hosted preko **NGINX**
- Funkcionalnosti: deljenje rezultatov, povezovanje uporabnikov, push obvestila
- Knjižnice: `express`, `knex`, `apn`

## 7. Zunanje odvisnosti aplikacije

### 7.1 iOS/WatchOS aplikacija

- **Ni zunanjih knjižnic**
- Uporabljene le Apple-ove: UIKit, SwiftUI, HealthKit itd.

### 7.2 Backend

- Knjižnice: `knex`, `apn`
- Ostalo: ExpressJS, MySQL, NGINX

### 7.3 Distribucija

- Uporablja se **TestFlight** za testiranje in **AppStore** za distribucijo

## 8. Navodila za zagon

### 8.1 iOS aplikacija

Repozitorij:  
[https://github.com/SpaceJS82/HealthTrackMe](https://github.com/SpaceJS82/HealthTrackMe)

Namestitev:
```
git clone https://github.com/SpaceJS82/HealthTrackMe
```
Nato odpri projekt v Xcode in prilagodi nastavitve (Team, Bundle ID).
Datoteke testiraj na basic Xcode projectu saj je repozitorij aplikacije drugje.

### 8.2 Backend

Namestitev:
```
git clone https://github.com/SpaceJS82/HealthTrackMe
cd HealthTrackMe/backend
npm install
node index.js
```
Potrebna je konfiguracija `.env` datoteke z dostopom do baze in APN ključa.

## 9. Navodila za nadaljnji razvoj

### Upravljanje nalog

Razvojna ekipa uporablja **kanban board v Notionu** z naslednjimi fazami:
- `Not started`
- `In progress`
- `Waiting for review`
- `Complete` (npr. `Analytics done`, `Watch app done`)

### Proces

- Delo poteka na `main` veji
- Naloge in testiranje potekajo prek Notiona
- Distribucija in testiranje funkcionalnosti poteka prek **TestFlight**

## 10. Odprte pomanjkljivosti, nedoslednosti in napake ob predaji rešitve

Trenutno **ni znanih napak ali manjkajočih funkcij**. Vsa funkcionalnost deluje stabilno in je testirana.

## 11. Prevzem rešitve

Za prevzem ali sodelovanje:

- Kloniraj repozitorij
- Vzpostavi lokalno okolje (Xcode, Node.js, MySQL)
- Po potrebi pridobi dostop do Notion kanban sistema

📧 Kontakt: **contact@getyoa.app**
# Dokumentacija: Yoa Health Tracker & Coach

## 1. Yoa Health Tracker & Coach – pregled rešitve

**Yoa Health Tracker & Coach** je iOS aplikacija, namenjena uporabnikom, ki želijo poglobljeno razumeti in izboljšati svoje zdravje s pomočjo Apple Watcha oziroma drugih naprav, ki sinhronizirajo podatke z Apple Health. Aplikacija ponuja celovit vpogled v zdravstvene navade posameznika preko metrik, kot so *sleep score*, *fitness score*, *stress score*, in druge vitalne vrednosti. Na podlagi teh podatkov aplikacija podaja tudi praktične, prilagojene nasvete za izboljšanje življenjskega sloga.

Uporabniki lahko spremljajo:
- **Odstopanja** vrednosti od običajnega stanja (npr. HRV, spanje, aktivnost),
- **Trende skozi čas** za posamezne metrike (npr. akumulacija vadb),
- **Vsakodnevni dnevnik** navad, kjer aplikacija analizira vpliv dnevnih dejavnosti na spanje in srčni utrip,
- **Socialne funkcionalnosti**, kjer lahko uporabniki delijo svoje rezultate (npr. sleep score, workouts) s prijatelji in reagirajo na njihove objave.

Rešitev vključuje tudi aplikacijo za Apple Watch, ki služi kot pasivni senzor in omogoča sinhronizacijo z iOS aplikacijo. Backend infrastruktura podpira socialne funkcionalnosti prek ExpressJS API-ja na NGINX strežniku ter uporablja MySQL podatkovno bazo za shranjevanje in upravljanje podatkov.

### 1.1 Struktura uporabniških vmesnikov

Aplikacija je razdeljena v več ključnih uporabniških sklopov:
- **Dashboard (Pregledna plošča)**: prikazuje glavne metrike (sleep, fitness, stress scores), dnevne cilje in ključna odstopanja.
- **Journal (Dnevnik)**: uporabnik vsak dan vnese aktivnosti/navade, sistem pa analizira njihov vpliv na zdravje (npr. HRV, spanje).
- **Workouts**: prikaz vadb skozi čas, vključno z metrikami napora in okrevanja.
- **Social Feed**: funkcionalnost za povezovanje s prijatelji, pregled deljenih statistik in interakcije (reakcije, komentarji).
- **Profil**: osebne nastavitve, cilji, sinhronizacija z Apple Health in podatki o napravi.
- **Notifications & Suggestions**: obvestila z nasveti in opozorili glede odstopanj ali doseženih ciljev.

iOS aplikacija je razvita v **Swift z UIKit**, Apple Watch aplikacija v **SwiftUI**, kar omogoča moderno, odzivno in intuitivno uporabniško izkušnjo.

## 2. Struktura rešitve

Aplikacija je sestavljena iz iOS in Apple Watch aplikacije ter backend strežnika.

### 2.1 iOS aplikacija

- **Jezik in ogrodje**: Swift + UIKit
- **Organizacija kode**: ViewController struktura in backend data layer
- **HealthKit** integracija za zbiranje podatkov
- **Na napravi poteka analiza dnevnika in generiranje priporočil**

### 2.2 Apple Watch aplikacija

- Razvita v **SwiftUI**
- Sinhronizacija z Apple Health za zajem podatkov

### 2.3 Backend

- REST API na **ExpressJS** s **MySQL** bazo
- Hosted preko **NGINX**
- Funkcionalnosti: deljenje rezultatov, povezovanje uporabnikov, push obvestila
- Knjižnice: `express`, `knex`, `apn`

## 3. Zunanje odvisnosti aplikacije

### 3.1 iOS/WatchOS aplikacija

- **Ni zunanjih knjižnic**
- Uporabljene le Apple-ove: UIKit, SwiftUI, HealthKit itd.

### 3.2 Backend

- Knjižnice: `knex`, `apn`
- Ostalo: ExpressJS, MySQL, NGINX

### 3.3 Distribucija

- Uporablja se **TestFlight** za testiranje in **AppStore** za distribucijo

## 4. Navodila za zagon

### 4.1 iOS aplikacija

Repozitorij:  
[https://github.com/SpaceJS82/HealthTrackMe](https://github.com/SpaceJS82/HealthTrackMe)

Namestitev:
```
git clone https://github.com/SpaceJS82/HealthTrackMe
```
Nato odpri projekt v Xcode in prilagodi nastavitve (Team, Bundle ID).
Datoteke testiraj na basic Xcode projectu saj je repozitorij aplikacije drugje.

### 4.2 Backend

Namestitev:
```
git clone https://github.com/SpaceJS82/HealthTrackMe
cd HealthTrackMe/backend
npm install
node index.js
```
Potrebna je konfiguracija `.env` datoteke z dostopom do baze in APN ključa.

## 5. Navodila za nadaljnji razvoj

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

## 6. Odprte pomanjkljivosti, nedoslednosti in napake ob predaji rešitve

Trenutno **ni znanih napak ali manjkajočih funkcij**. Vsa funkcionalnost deluje stabilno in je testirana.

## 7. Prevzem rešitve

Za prevzem ali sodelovanje:

- Kloniraj repozitorij
- Vzpostavi lokalno okolje (Xcode, Node.js, MySQL)
- Po potrebi pridobi dostop do Notion kanban sistema

📧 Kontakt: **contact@getyoa.app**
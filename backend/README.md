# Litha API

Spring Boot 3 / PostgreSQL REST API for the Flutter app.

## Prerequisites

- Java 17
- PostgreSQL 14+ with a database named `litha`

Create the database once. From the project root, set the password you chose
during PostgreSQL installation for this PowerShell session, then run the setup
script:

```powershell
$env:PGPASSWORD = 'the-password-you-set-for-postgres'
.\backend\scripts\setup-postgres.ps1
Remove-Item Env:PGPASSWORD
```

The script automatically finds the PostgreSQL 18 client installed in its
default Windows location. It is safe to run again: it only creates the `litha`
database if it does not already exist.

Set credentials (optional if using the defaults in `application.yml`):

```powershell
$env:DATABASE_URL = 'jdbc:postgresql://localhost:5432/litha'
$env:DATABASE_USERNAME = 'postgres'
$env:DATABASE_PASSWORD = 'the-password-you-set-for-postgres'
```

Run the API:

```powershell
cd backend
mvn spring-boot:run
```

On the first successful start, Hibernate creates the tables for stones, stone
photos, memories, memory photos, locations, stone identifications, and hunt
items. The API is intentionally single-owner at present, so it does not create
a `users` table or expose authentication endpoints. Add that only when the app
needs multiple accounts.

It starts at `http://localhost:9090`. For the Android emulator, Flutter must call `http://10.0.2.2:9090`; a real phone needs your computer's LAN IP.

This is deliberately a private, single-person app: it has no sign-in and no users table. Keep the API private (for example, run it only on your home network) if you deploy it.

## API

Every resource supports `GET`, `GET /{id}`, `POST`, `PUT /{id}`, and `DELETE /{id}`:

- `/api/stones`, `/api/stone-photos?stoneId=1`, `/api/memories?stoneId=1`
- `/api/memory-photos?memoryId=1`, `/api/stone-identifications?stoneId=1`
- `/api/hunt-items`, `/api/locations`

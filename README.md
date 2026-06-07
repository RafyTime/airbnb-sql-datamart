# Airbnb SQL Datamart

Airbnb-style PostgreSQL datamart for the IU **Build a Data Mart in SQL** portfolio project.

## 📦 Requirements

- 🐳 Docker Desktop with Docker Compose

## ⚙️ Setup

1. Copy `.env.example` to `.env`. Adjust values if needed.
2. Start the database and pgAdmin:

```bash
docker compose up -d
```

PostgreSQL runs on `localhost:5432` and pgAdmin runs on `http://localhost:5050`.
On first startup Docker automatically loads:

- `database/01_schema.sql`
- `database/02_seeds.sql`
- `database/03_functions.sql`

To reset and reload everything from scratch:

```bash
docker compose down -v
docker compose up -d
```

## 🔗 pgAdmin Connection

Log in to pgAdmin with the `DB_USER` and `DB_PASSWORD` from `.env`, then register a server:

- Host: `postgres`
- Port: `5432`
- Database: `DB_NAME`
- Username: `DB_USER`
- Password: `DB_PASSWORD`

## 🧪 Test Query Functions

The showcase queries from `docs/phase_2/TEST_QUERIES.md` are loaded as functions in `database/03_functions.sql`.

Example:

```sql
SELECT * FROM listing_test_query();
SELECT * FROM booking_test_query();
```

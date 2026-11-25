# Airbnb SQL Datamart

Airbnb-style PostgreSQL datamart for the IU **Build a Data Mart in SQL** portfolio project. It models listings, bookings, payments, and reviews, with sample data and SQL queries that validate the design.

- [Entity relationship diagram](docs/phase_1/ENTITY_RELATIONSHIP_DIAGRAM.svg)
- [Final project abstract](docs/phase_3/FINALIZATION_PHASE.md)
- [SQL test query catalog](docs/phase_2/TEST_QUERIES.md)

## Requirements

- Docker with Docker Compose

## Setup

1. From the repository root, copy [`.env.example`](.env.example) to `.env`. Adjust values if needed.
2. Start the database and pgAdmin:

```bash
docker compose up -d
```

With the example port settings, PostgreSQL listens on `localhost:5432` and pgAdmin is available at <http://localhost:5050>.
When PostgreSQL initializes an empty data directory, it loads these files in order.

- [Schema](database/01_schema.sql)
- [Sample data](database/02_seeds.sql)
- [Test query functions](database/03_functions.sql)

## Connect with pgAdmin

Log in to pgAdmin with the `DB_USER` and `DB_PASSWORD` from `.env`, then register a server:

- Host: `postgres`
- Port: `5432`
- Database: `DB_NAME`
- Username: `DB_USER`
- Password: `DB_PASSWORD`

## Run a test query

Open the Query Tool for the database named in `DB_NAME` and run the listing query. It should return rows with a `result` column containing JSON objects for active listings. Run the booking query to explore the sample bookings.

```sql
SELECT * FROM listing_test_query();
SELECT * FROM booking_test_query();
```

## Reset local data

If you previously started the project with the volume mounted at `/var/lib/postgresql/data`, export any data you want to keep before recreating the PostgreSQL container. The corrected mount does not migrate data from the previous container.

`docker compose down -v` deletes the local database and pgAdmin settings. Use it when you want to reload the original schema and sample data.

```bash
docker compose down -v
docker compose up -d
```

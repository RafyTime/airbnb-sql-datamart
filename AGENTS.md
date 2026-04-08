## Learned User Preferences

- Prefer simple, academic tone for course README and similar project documentation.
- For brief factual questions (e.g. Docker image tags), prefer short, direct answers.
- Prefer a simple root-level `uv` Python project for this repo’s seeder, with `pyproject.toml` and `main.py` at the root and the seeding logic in `scripts/seed.py`.
- Prefer a small seeding stack centered on `Faker`, `psycopg`, and `python-dotenv`; avoid heavier ORM layers unless there is a clear need.
- Prefer exporting a static SQL snapshot of seeded data with `pg_dump` (data-only, insert-style flags) after the Python seeder runs, rather than building large SQL dump logic inside the seeder.

## Learned Workspace Facts

- IU “Build a Data Mart in SQL” portfolio project: Airbnb-style normalized PostgreSQL datamart covering users, listings, bookings, payments, reviews, messaging, and related entities per phase 1 design docs.
- Course requirements expect seeded data to meet minimum row counts per table (on the order of at least 20 rows each across the full schema); the Python seeder should populate every table accordingly.
- Phase 1 design lives under `docs/phase_1/` (conception, data dictionary, ERD); high-level requirements are in `docs/REQUIREMENTS.md`.
- Phase 2 artifacts, including the validated PostgreSQL test query catalog, live under `docs/phase_2/` (for example `docs/phase_2/test_queries.md`).
- Database implementation DDL is intended under `database/schema/` (often grouped by domain); Docker Compose mounts `./database/schema` to the Postgres container’s `/docker-entrypoint-initdb.d` for first-time initialization.
- PostgreSQL and pgAdmin are started via Docker Compose; from pgAdmin on that network, connect to PostgreSQL using host `postgres`, port `5432`, and the credentials configured in `.env` (see README).
- Docker runs the SQL init scripts from `database/schema/` in lexicographic order, so schema filenames should preserve dependency order.
- To refresh `database/seeds/seeds.sql` after seeding, run `pg_dump` against the running Postgres container using the same database user and database name as in `.env` (not a guessed role); failed dumps often produce a file containing only the error message.

# Airbnb SQL Datamart

The repository models an Airbnb-style booking system with a relational database design using PostgreSQL, focused on clarity, normalization, and practical use cases.

Part of the IU **Build a Data Mart in SQL** Prortfolio Project.

## 📦 Requirements

- 🐳Docker (Docker Desktop & Compose)

## ⚙️ Setup

1. Create a local `.env` file in the project root.
2. Copy the values from `.env.example`.
3. Adjust the credentials if needed.

Example:

```env
DB_NAME=airbnb_datamart
DB_USER=admin@email.com # ⚠️must be an email!
DB_PASSWORD=Admin_123
```

## ▶️ Usage

Start the services with Docker Compose:

```bash
docker compose up -d
```

This starts:

- `postgres` on port `5432`
- `pgadmin` on port `5050`

If you need to stop and remove the containers, use:

```bash
docker compose down
```

If you also want to remove the database volume and reset the data:

```bash
docker compose down -v
```

## 🔗 Connect pgAdmin to PostgreSQL

Open pgAdmin in your browser:

```text
http://localhost:5050
```

Log in with the credentials from your `.env` file:

- Email: `DB_USER`
- Password: `DB_PASSWORD`

Then register a new server with these values:

- Name: any label you want, for example `airbnb_datamart`
- Host name/address: `postgres`
- Port: `5432`
- Maintenance database: `DB_NAME`
- Username: `DB_USER`
- Password: `DB_PASSWORD`

Use `postgres` as the host because pgAdmin runs inside Docker and connects to the database service through the internal Docker network.

## 🗒️ Notes

- The schema scripts are expected to be placed in `database/schema/` and will be executed automatically when the PostgreSQL container initializes.
- The project documentation in `docs/phase_1/` should be used as the conceptual reference for the database implementation.

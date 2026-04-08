"""Seed the Airbnb datamart with deterministic dummy data.

The script truncates the existing tables, then inserts a coherent dataset in
dependency order so foreign keys stay valid. It uses a mix of German and
Colombian Spanish Faker locales to keep the generated content varied.
"""

from __future__ import annotations

import hashlib
import logging
import os
import random
import re
import secrets
import unicodedata
from dataclasses import dataclass
from datetime import UTC, date, datetime, time, timedelta
from decimal import Decimal, ROUND_HALF_UP
from typing import Any
from uuid import UUID

import psycopg
from dotenv import load_dotenv
from faker import Faker
from psycopg.types.json import Jsonb

LOGGER = logging.getLogger(__name__)

SEED = 42
LOCALES = ("de_DE", "es_CO")
PRICE_Q = Decimal("0.01")
COORD_Q = Decimal("0.000001")
MONEY_FEE = Decimal("0.10")
HOST_PAYOUT_RATE = Decimal("0.85")

ROLE_NAMES = [
    "Admin",
    "Host",
    "Guest",
    "Support",
    "Moderator",
    "Finance",
    "Compliance",
    "Superhost",
    "Traveler",
    "Verified",
    "Ambassador",
    "Curator",
    "Analyst",
    "Reviewer",
    "Manager",
    "Supervisor",
    "Editor",
    "Operator",
    "Partner",
    "Auditor",
]

AMENITIES = [
    ("wifi", "WLAN", "connectivity"),
    ("kitchen", "Küche", "home"),
    ("washer", "Waschmaschine", "laundry"),
    ("dryer", "Trockner", "laundry"),
    ("parking", "Parkplatz", "transport"),
    ("ac", "Aire acondicionado", "comfort"),
    ("heating", "Heizung", "comfort"),
    ("pool", "Piscina", "leisure"),
    ("balcony", "Balkon", "outdoor"),
    ("elevator", "Aufzug", "access"),
    ("workspace", "Escritorio", "work"),
    ("tv", "Televisor", "entertainment"),
    ("coffee", "Cafetera", "kitchen"),
    ("iron", "Plancha", "utility"),
    ("hairdryer", "Secador de pelo", "bathroom"),
    ("self_checkin", "Check-in automático", "access"),
    ("family_friendly", "Familienfreundlich", "family"),
    ("pet_friendly", "Pet friendly", "family"),
    ("sea_view", "Vista al mar", "view"),
    ("garden", "Garten", "outdoor"),
]

HOUSE_RULES = [
    ("no_smoking", "No smoking"),
    ("no_pets", "No pets"),
    ("no_parties", "No parties"),
    ("quiet_hours", "Quiet hours after 22:00"),
    ("check_in_after_3pm", "Check-in after 15:00"),
    ("check_out_before_11am", "Check-out before 11:00"),
    ("respect_neighbors", "Respect the neighbors"),
    ("clean_common_areas", "Leave common areas clean"),
    ("report_damage", "Report damages immediately"),
    ("lock_doors", "Lock doors and windows"),
    ("no_loud_music", "No loud music"),
    ("no_unregistered_guests", "No unregistered guests"),
    ("turn_off_lights", "Turn off lights when leaving"),
    ("take_out_trash", "Take out the trash before checkout"),
    ("use_kitchen_respectfully", "Use the kitchen respectfully"),
    ("no_shoes_inside", "No shoes inside"),
    ("keep_noise_down", "Keep noise down in stairwells"),
    ("close_windows", "Close windows when leaving"),
    ("pool_hours", "Pool hours must be respected"),
    ("save_energy", "Save energy and water"),
]

FEE_TYPES = [
    ("cleaning", "Cleaning fee"),
    ("service", "Service fee"),
    ("city_tax", "City tax"),
    ("linen", "Linen fee"),
    ("parking", "Parking fee"),
    ("pet", "Pet fee"),
    ("extra_guest", "Extra guest fee"),
    ("late_checkin", "Late check-in fee"),
    ("early_checkin", "Early check-in fee"),
    ("security_deposit", "Security deposit"),
    ("resort", "Resort fee"),
    ("towel", "Towel fee"),
    ("breakfast", "Breakfast fee"),
    ("heating", "Heating surcharge"),
    ("aircon", "Air conditioning surcharge"),
    ("laundry", "Laundry fee"),
    ("key_exchange", "Key exchange fee"),
    ("maintenance", "Maintenance fee"),
    ("wifi_plus", "Premium Wi-Fi fee"),
    ("convenience", "Convenience fee"),
]

GERMAN_LOCATION_SUFFIXES = ["Mitte", "Nord", "Süd", "Ost", "West"]
SPANISH_LOCATION_SUFFIXES = ["Centro", "Norte", "Sur", "Este", "Oeste"]

GERMAN_LISTING_TITLES = [
    "Helle Wohnung in {place}",
    "Gemütliches Apartment in {place}",
    "Ruhiges Studio nahe {place}",
    "Modernes Loft in {place}",
]

SPANISH_LISTING_TITLES = [
    "Apartamento acogedor en {place}",
    "Estudio tranquilo cerca de {place}",
    "Loft moderno en {place}",
    "Casa luminosa en {place}",
]

GERMAN_REVIEW_TITLES = [
    "Sehr angenehmer Aufenthalt",
    "Tolle Kommunikation",
    "Sauber und komfortabel",
    "Empfehlenswert",
]

SPANISH_REVIEW_TITLES = [
    "Estadía muy agradable",
    "Comunicación excelente",
    "Limpio y cómodo",
    "Muy recomendable",
]

GERMAN_MESSAGES = [
    "Hallo, ist die Unterkunft für die genannten Daten verfügbar?",
    "Vielen Dank, ich freue mich auf den Aufenthalt.",
    "Können wir den Check-in kurz abstimmen?",
    "Perfekt, ich habe alle Informationen erhalten.",
]

SPANISH_MESSAGES = [
    "Hola, ¿la vivienda está disponible para esas fechas?",
    "Muchas gracias, quedo atento a la confirmación.",
    "¿Podemos coordinar el check-in por favor?",
    "Perfecto, ya tengo toda la información.",
]


@dataclass(slots=True)
class UserSeed:
    user_id: UUID
    role_name: str
    locale: str
    first_name: str
    last_name: str
    email: str


@dataclass(slots=True)
class LocationSeed:
    location_id: UUID
    name: str
    type: str
    parent_location_id: UUID | None
    locale: str


@dataclass(slots=True)
class ListingSeed:
    listing_id: UUID
    host: UserSeed
    location: LocationSeed
    policy_id: UUID
    base_price: Decimal
    currency: str
    title: str


@dataclass(slots=True)
class BookingSeed:
    booking_id: UUID
    guest: UserSeed
    listing: ListingSeed
    checkin_date: date
    checkout_date: date
    guests_count: int
    status: str
    total_price: Decimal


def configure_logging() -> None:
    level_name = os.getenv("LOG_LEVEL", "INFO").upper()
    logging.basicConfig(
        level=getattr(logging, level_name, logging.INFO),
        format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
    )


def slugify(value: str) -> str:
    normalized = unicodedata.normalize("NFKD", value)
    ascii_text = normalized.encode("ascii", "ignore").decode("ascii")
    slug = re.sub(r"[^a-zA-Z0-9]+", "-", ascii_text).strip("-").lower()
    return slug or "value"


def money(value: float | int | str | Decimal) -> Decimal:
    return Decimal(str(value)).quantize(PRICE_Q, rounding=ROUND_HALF_UP)


def coordinate(value: float | int | str | Decimal) -> Decimal:
    return Decimal(str(value)).quantize(COORD_Q, rounding=ROUND_HALF_UP)


def money_from_range(low: int, high: int) -> Decimal:
    return money(random.uniform(low, high))


def dt_at(day: date, hour: int, minute: int = 0) -> datetime:
    return datetime.combine(day, time(hour=hour, minute=minute), tzinfo=UTC)


def now_utc() -> datetime:
    return datetime.now(UTC)


def get_fakers() -> dict[str, Faker]:
    fakers = {locale: Faker(locale) for locale in LOCALES}
    for faker in fakers.values():
        faker.seed_instance(SEED)
    return fakers


def connect() -> psycopg.Connection[Any]:
    database_url = os.getenv("DATABASE_URL")
    if database_url:
        return psycopg.connect(database_url)

    return psycopg.connect(
        host=os.getenv("DB_HOST", "localhost"),
        port=os.getenv("DB_PORT", "5432"),
        dbname=os.getenv("DB_NAME", "airbnb_datamart"),
        user=os.getenv("DB_USER", "postgres"),
        password=os.getenv("DB_PASSWORD", "postgres"),
    )


def fetch_id(cursor: psycopg.Cursor[Any], sql: str, params: tuple[Any, ...]) -> UUID:
    cursor.execute(sql, params)
    row = cursor.fetchone()
    if row is None:
        raise RuntimeError("Expected an inserted row with RETURNING id.")
    return row[0]


def reset_tables(cursor: psycopg.Cursor[Any]) -> None:
    LOGGER.info("Truncating existing data")
    cursor.execute(
        """
        TRUNCATE TABLE
            booking_fee,
            payment_transaction,
            payout,
            review,
            message,
            message_thread,
            notification,
            wishlist_item,
            wishlist,
            referral,
            booking,
            listing_blocked_date,
            listing_house_rule,
            listing_amenity,
            listing_photo,
            listing,
            user_role,
            user_profile,
            session,
            account,
            verification,
            role,
            fee_type,
            cancellation_policy,
            amenity,
            house_rule,
            location,
            "user"
        RESTART IDENTITY CASCADE;
        """
    )


def seed_roles(cursor: psycopg.Cursor[Any]) -> dict[str, UUID]:
    LOGGER.info("Seeding role catalog")
    role_ids: dict[str, UUID] = {}
    for role_name in ROLE_NAMES:
        role_id = fetch_id(
            cursor,
            "INSERT INTO role (name) VALUES (%s) RETURNING role_id;",
            (role_name,),
        )
        role_ids[role_name] = role_id
    LOGGER.info("Inserted %s roles", len(role_ids))
    return role_ids


def seed_locations(
    cursor: psycopg.Cursor[Any], fakers: dict[str, Faker]
) -> list[LocationSeed]:
    LOGGER.info("Seeding location hierarchy")
    locations: list[LocationSeed] = []

    country_specs = [
        ("Deutschland", "de_DE", 2),
        ("Colombia", "es_CO", 2),
    ]

    for country_name, locale, city_count in country_specs:
        country_id = fetch_id(
            cursor,
            """
            INSERT INTO location (name, type, parent_location_id)
            VALUES (%s, %s, %s)
            RETURNING location_id;
            """,
            (country_name, "country", None),
        )
        country = LocationSeed(country_id, country_name, "country", None, locale)
        locations.append(country)

        city_faker = fakers[locale]
        for city_index in range(city_count):
            city_name = f"{city_faker.city()} {city_index + 1}"
            city_id = fetch_id(
                cursor,
                """
                INSERT INTO location (name, type, parent_location_id)
                VALUES (%s, %s, %s)
                RETURNING location_id;
                """,
                (city_name, "city", country_id),
            )
            city = LocationSeed(city_id, city_name, "city", country_id, locale)
            locations.append(city)

            suffixes = (
                GERMAN_LOCATION_SUFFIXES
                if locale == "de_DE"
                else SPANISH_LOCATION_SUFFIXES
            )
            for suffix in suffixes:
                neighborhood_name = f"{city_name} {suffix}"
                neighborhood_id = fetch_id(
                    cursor,
                    """
                    INSERT INTO location (name, type, parent_location_id)
                    VALUES (%s, %s, %s)
                    RETURNING location_id;
                    """,
                    (neighborhood_name, "neighborhood", city_id),
                )
                locations.append(
                    LocationSeed(
                        neighborhood_id,
                        neighborhood_name,
                        "neighborhood",
                        city_id,
                        locale,
                    )
                )

    LOGGER.info("Inserted %s locations", len(locations))
    return locations


def seed_reference_catalogs(
    cursor: psycopg.Cursor[Any],
) -> tuple[dict[str, UUID], dict[str, UUID], dict[str, UUID], dict[str, UUID]]:
    LOGGER.info("Seeding reference catalogs")

    amenity_ids: dict[str, UUID] = {}
    for code, name, category in AMENITIES:
        amenity_ids[code] = fetch_id(
            cursor,
            """
            INSERT INTO amenity (code, name, category)
            VALUES (%s, %s, %s)
            RETURNING amenity_id;
            """,
            (code, name, category),
        )

    house_rule_ids: dict[str, UUID] = {}
    for code, name in HOUSE_RULES:
        house_rule_ids[code] = fetch_id(
            cursor,
            """
            INSERT INTO house_rule (code, name)
            VALUES (%s, %s)
            RETURNING rule_id;
            """,
            (code, name),
        )

    fee_type_ids: dict[str, UUID] = {}
    for code, name in FEE_TYPES:
        fee_type_ids[code] = fetch_id(
            cursor,
            """
            INSERT INTO fee_type (code, name)
            VALUES (%s, %s)
            RETURNING fee_type_id;
            """,
            (code, name),
        )

    cancellation_policy_ids: dict[str, UUID] = {}
    for index, (code, name, refund_days) in enumerate(
        (
            ("flex_24h", "Flexible 24 hours", 1),
            ("flex_3d", "Flexible 3 days", 3),
            ("moderate_5d", "Moderate 5 days", 5),
            ("moderate_7d", "Moderate 7 days", 7),
            ("strict_7d", "Strict 7 days", 7),
            ("strict_14d", "Strict 14 days", 14),
            ("super_strict", "Super strict", 14),
            ("long_stay", "Long stay", 30),
            ("weekend_friendly", "Weekend friendly", 2),
            ("family_friendly", "Family friendly", 5),
            ("business", "Business travel", 3),
            ("seasonal", "Seasonal", 7),
            ("flex_budget", "Flexible budget", 1),
            ("premium", "Premium", 14),
            ("last_minute", "Last minute", 0),
            ("holiday", "Holiday special", 10),
            ("city_break", "City break", 4),
            ("extended", "Extended stay", 21),
            ("medical", "Medical travel", 7),
            ("custom", "Custom contract", 14),
        ),
        start=1,
    ):
        rules_json = {
            "policy_rank": index,
            "refund_before_days": refund_days,
            "guest_fee_percentage": float(MONEY_FEE),
            "host_payout_delay_hours": 24,
            "description": name,
        }
        cancellation_policy_ids[code] = fetch_id(
            cursor,
            """
            INSERT INTO cancellation_policy (code, name, rules_json)
            VALUES (%s, %s, %s)
            RETURNING policy_id;
            """,
            (code, name, Jsonb(rules_json)),
        )

    LOGGER.info(
        "Inserted catalogs: %s amenities, %s house rules, %s fee types, %s policies",
        len(amenity_ids),
        len(house_rule_ids),
        len(fee_type_ids),
        len(cancellation_policy_ids),
    )
    return amenity_ids, house_rule_ids, fee_type_ids, cancellation_policy_ids


def build_users(fakers: dict[str, Faker]) -> list[dict[str, Any]]:
    LOGGER.info("Building user records in memory")
    user_plan = [("Host", 8)] + [("Guest", 10)] + [("Admin", 2)]

    users: list[dict[str, Any]] = []
    sequence = 1
    for role_name, count in user_plan:
        for _ in range(count):
            locale = random.choice(LOCALES)
            faker = fakers[locale]
            first_name = faker.first_name()
            last_name = faker.last_name()
            slug = slugify(f"{first_name}.{last_name}")
            email = f"{slug}.{sequence:02d}@example.com"
            phone = faker.phone_number()
            if role_name == "Guest" and sequence % 3 == 0:
                phone = None

            users.append(
                {
                    "role_name": role_name,
                    "locale": locale,
                    "first_name": first_name,
                    "last_name": last_name,
                    "email": email,
                    "phone": phone,
                }
            )
            sequence += 1

    random.shuffle(users)
    return users


def seed_users(
    cursor: psycopg.Cursor[Any],
    user_rows: list[dict[str, Any]],
    role_ids: dict[str, UUID],
    fakers: dict[str, Faker],
) -> list[UserSeed]:
    LOGGER.info("Seeding users and identity tables")
    users: list[UserSeed] = []
    now = now_utc()
    session_devices = [
        (
            "web-chrome",
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
            "(KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36",
        ),
        (
            "ios-app",
            "Airbnb/24.15.1 (iPhone; iOS 17.4; Scale/3.00)",
        ),
        (
            "android-app",
            "Airbnb/24.15.1 (Linux; Android 14; Pixel 8)",
        ),
        (
            "web-safari",
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_4) AppleWebKit/605.1.15 "
            "(KHTML, like Gecko) Version/17.4 Safari/605.1.15",
        ),
    ]

    for index, row in enumerate(user_rows, start=1):
        status = "active"
        verified_at = now - timedelta(days=index * 2)
        user_id = fetch_id(
            cursor,
            """
            INSERT INTO "user" (
                email, first_name, last_name, phone, status, verified_at
            )
            VALUES (%s, %s, %s, %s, %s, %s)
            RETURNING user_id;
            """,
            (
                row["email"],
                row["first_name"],
                row["last_name"],
                row["phone"],
                status,
                verified_at,
            ),
        )
        user = UserSeed(
            user_id=user_id,
            role_name=row["role_name"],
            locale=row["locale"],
            first_name=row["first_name"],
            last_name=row["last_name"],
            email=row["email"],
        )
        users.append(user)

        role_id = role_ids[row["role_name"]]
        fetch_id(
            cursor,
            """
            INSERT INTO user_role (user_id, role_id, assigned_at, revoked_at)
            VALUES (%s, %s, %s, %s)
            RETURNING user_id;
            """,
            (user_id, role_id, now - timedelta(days=index * 3), None),
        )

        profile_faker = fakers[row["locale"]]
        name_slug = slugify(f"{row['first_name']}.{row['last_name']}")
        website_slug = slugify(f"{row['first_name']}-{row['last_name']}")
        profile_payload = {
            "preferred_locale": row["locale"],
            "theme": "dark" if index % 2 else "light",
            "marketing_emails": index % 3 != 0,
            "currency_hint": "EUR" if row["locale"] == "de_DE" else "COP",
        }
        social_payload = {
            "instagram": f"@{name_slug}",
            "website": f"https://example.com/{website_slug}",
        }
        bio = (
            profile_faker.sentence(nb_words=12)
            + " "
            + profile_faker.sentence(nb_words=8)
        )
        avatar_url = f"https://picsum.photos/seed/{slugify(row['email'])}/640/640"
        fetch_id(
            cursor,
            """
            INSERT INTO user_profile (user_id, avatar_url, bio, languages, socials, settings)
            VALUES (%s, %s, %s, %s, %s, %s)
            RETURNING user_id;
            """,
            (
                user_id,
                avatar_url,
                bio,
                ["de", "es", "en"] if row["locale"] == "de_DE" else ["es", "de", "en"],
                Jsonb(social_payload),
                Jsonb(profile_payload),
            ),
        )

        provider = "password"
        if index % 4 == 0:
            provider = "google"
        elif index % 5 == 0:
            provider = "facebook"
        expires_at = now + timedelta(days=365) if provider != "password" else None
        fetch_id(
            cursor,
            """
            INSERT INTO account (
                user_id,
                provider,
                provider_account_id,
                access_token,
                refresh_token,
                scope,
                expires_at,
                password_hash
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING auth_id;
            """,
            (
                user_id,
                provider,
                f"{provider}-{slugify(row['email'])}",
                secrets.token_urlsafe(24) if provider != "password" else None,
                secrets.token_urlsafe(24) if provider != "password" else None,
                "email profile" if provider != "password" else "local-login",
                expires_at,
                f"$2b$12${secrets.token_hex(16)}",
            ),
        )

        session_tag, session_user_agent = session_devices[
            (index - 1) % len(session_devices)
        ]
        session_seed = f"{slugify(row['email'])}:{index}:{session_tag}"
        revoked_at = now - timedelta(days=index) if index % 5 == 0 else None
        fetch_id(
            cursor,
            """
            INSERT INTO session (
                user_id,
                token,
                refresh_token,
                user_agent,
                ip_hash,
                tag,
                revoked_at
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            RETURNING session_id;
            """,
            (
                user_id,
                hashlib.sha256(f"session-token:{session_seed}".encode()).hexdigest(),
                hashlib.sha256(
                    f"session-refresh:{session_seed}".encode()
                ).hexdigest(),
                session_user_agent,
                hashlib.sha256(f"ip:{session_seed}".encode()).hexdigest(),
                session_tag,
                revoked_at,
            ),
        )

        consumed_at = verified_at + timedelta(hours=1) if index % 4 != 0 else None
        purpose = "email" if index % 2 else "phone"
        fetch_id(
            cursor,
            """
            INSERT INTO verification (
                user_id, purpose, value, consumed_at, expires_at, created_at
            )
            VALUES (%s, %s, %s, %s, %s, %s)
            RETURNING verif_id;
            """,
            (
                user_id,
                purpose,
                secrets.token_urlsafe(12),
                consumed_at,
                verified_at + timedelta(days=7),
                verified_at - timedelta(hours=2),
            ),
        )

    LOGGER.info("Inserted %s users and related identity rows", len(users))
    return users


def seed_listings(
    cursor: psycopg.Cursor[Any],
    users: list[UserSeed],
    locations: list[LocationSeed],
    cancellation_policy_ids: dict[str, UUID],
    fakers: dict[str, Faker],
) -> list[ListingSeed]:
    LOGGER.info("Seeding listings and property assets")

    hosts = [user for user in users if user.role_name == "Host"]
    neighborhoods = [
        location for location in locations if location.type == "neighborhood"
    ]
    policies = list(cancellation_policy_ids.values())
    listings: list[ListingSeed] = []

    property_types = ["apartment", "house", "studio", "loft", "private room"]
    room_types = ["entire place", "private room", "shared room", "hotel room"]

    for index, neighborhood in enumerate(neighborhoods, start=1):
        host = hosts[(index - 1) % len(hosts)]
        locale = neighborhood.locale
        faker = fakers[locale]
        currency = "EUR" if locale == "de_DE" else "COP"
        base_price = (
            money_from_range(65, 220)
            if currency == "EUR"
            else money_from_range(180000, 650000)
        )
        title_template = random.choice(
            GERMAN_LISTING_TITLES if locale == "de_DE" else SPANISH_LISTING_TITLES
        )
        title = title_template.format(place=neighborhood.name)
        description = " ".join(
            [
                faker.sentence(nb_words=10),
                faker.sentence(nb_words=12),
                faker.sentence(nb_words=8),
            ]
        )
        property_type = property_types[(index - 1) % len(property_types)]
        room_type = room_types[(index - 1) % len(room_types)]
        accommodates = 2 + (index % 5)
        bedrooms = 1 + (index % 3)
        beds = max(1, bedrooms + (1 if index % 4 == 0 else 0))
        bathrooms = Decimal(str(1 + (index % 3) * 0.5)).quantize(Decimal("0.1"))
        created_at = now_utc() - timedelta(days=60 + index)
        address_line2 = (
            f"Apt. {index:02d}"
            if locale == "es_CO"
            else f"Wohnung {index:02d}"
        )

        listing_id = fetch_id(
            cursor,
            """
            INSERT INTO listing (
                host_id,
                location_id,
                policy_id,
                title,
                description,
                property_type,
                room_type,
                accommodates,
                bedrooms,
                beds,
                bathrooms,
                address_line1,
                address_line2,
                postal_code,
                lat,
                lng,
                base_price,
                currency,
                status,
                created_at,
                updated_at
            )
            VALUES (
                %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s
            )
            RETURNING listing_id;
            """,
            (
                host.user_id,
                neighborhood.location_id,
                policies[(index - 1) % len(policies)],
                title,
                description,
                property_type,
                room_type,
                accommodates,
                bedrooms,
                beds,
                bathrooms,
                faker.street_address(),
                address_line2 if index % 2 else None,
                faker.postcode(),
                coordinate(faker.latitude()),
                coordinate(faker.longitude()),
                base_price,
                currency,
                "active",
                created_at,
                created_at + timedelta(days=1),
            ),
        )

        listing = ListingSeed(
            listing_id=listing_id,
            host=host,
            location=neighborhood,
            policy_id=policies[(index - 1) % len(policies)],
            base_price=base_price,
            currency=currency,
            title=title,
        )
        listings.append(listing)

        photo_seed = slugify(title)
        for photo_index, is_cover in enumerate((True, False), start=1):
            fetch_id(
                cursor,
                """
                INSERT INTO listing_photo (
                    listing_id, url, caption, is_cover, sort_order, uploaded_at
                )
                VALUES (%s, %s, %s, %s, %s, %s)
                RETURNING photo_id;
                """,
                (
                    listing_id,
                    f"https://picsum.photos/seed/{photo_seed}-{photo_index}/1280/960",
                    f"{title} photo {photo_index}",
                    is_cover,
                    photo_index,
                    created_at + timedelta(hours=photo_index),
                ),
            )

    LOGGER.info(
        "Inserted %s listings and %s listing photos", len(listings), len(listings) * 2
    )
    return listings


def seed_listing_details(
    cursor: psycopg.Cursor[Any],
    listings: list[ListingSeed],
    amenity_ids: dict[str, UUID],
    house_rule_ids: dict[str, UUID],
) -> None:
    amenity_values = list(amenity_ids.values())
    house_rule_values = list(house_rule_ids.values())

    for index, listing in enumerate(listings, start=1):
        start_amenity = (index - 1) % len(amenity_values)
        for offset in range(3):
            amenity_id = amenity_values[(start_amenity + offset) % len(amenity_values)]
            fetch_id(
                cursor,
                """
                INSERT INTO listing_amenity (listing_id, amenity_id)
                VALUES (%s, %s)
                RETURNING listing_id;
                """,
                (listing.listing_id, amenity_id),
            )

        start_rule = (index - 1) % len(house_rule_values)
        for offset in range(2):
            rule_id = house_rule_values[(start_rule + offset) % len(house_rule_values)]
            note = (
                "Please keep the property tidy."
                if offset == 0
                else "Respect quiet hours after 22:00."
            )
            fetch_id(
                cursor,
                """
                INSERT INTO listing_house_rule (listing_id, rule_id, note)
                VALUES (%s, %s, %s)
                RETURNING listing_id;
                """,
                (listing.listing_id, rule_id, note),
            )

        blocked_start = date.today() + timedelta(days=30 + index)
        for offset in range(2):
            fetch_id(
                cursor,
                """
                INSERT INTO listing_blocked_date (listing_id, day, reason)
                VALUES (%s, %s, %s)
                RETURNING listing_id;
                """,
                (
                    listing.listing_id,
                    blocked_start + timedelta(days=offset * 3),
                    "Maintenance window" if offset == 0 else "Owner hold",
                ),
            )

    LOGGER.info("Inserted listing amenities, house rules, and blocked dates")


def seed_bookings(
    cursor: psycopg.Cursor[Any],
    users: list[UserSeed],
    listings: list[ListingSeed],
    fee_type_ids: dict[str, UUID],
) -> list[BookingSeed]:
    LOGGER.info("Seeding bookings and booking fees")

    guests = [user for user in users if user.role_name == "Guest"]
    bookings: list[BookingSeed] = []
    today = date.today()

    for index, listing in enumerate(listings, start=1):
        guest = guests[(index - 1) % len(guests)]
        nights = 2 + (index % 4)
        checkin = today - timedelta(days=90 - index * 3)
        checkout = checkin + timedelta(days=nights)
        subtotal = (listing.base_price * Decimal(nights)).quantize(
            PRICE_Q, rounding=ROUND_HALF_UP
        )
        cleaning_fee = (
            money_from_range(18, 42)
            if listing.currency == "EUR"
            else money_from_range(60000, 120000)
        )
        service_fee = (subtotal * MONEY_FEE).quantize(PRICE_Q, rounding=ROUND_HALF_UP)
        total_price = (subtotal + cleaning_fee + service_fee).quantize(
            PRICE_Q, rounding=ROUND_HALF_UP
        )
        booking_created_at = dt_at(checkin - timedelta(days=2), 9, 15)
        booking_updated_at = dt_at(checkout + timedelta(days=1), 11, 45)

        booking_id = fetch_id(
            cursor,
            """
            INSERT INTO booking (
                guest_id,
                listing_id,
                policy_id,
                checkin_date,
                checkout_date,
                guests_count,
                status,
                total_price,
                currency,
                created_at,
                updated_at
            )
            VALUES (
                %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s
            )
            RETURNING booking_id;
            """,
            (
                guest.user_id,
                listing.listing_id,
                listing.policy_id,
                checkin,
                checkout,
                1 + (index % 4),
                "completed",
                total_price,
                listing.currency,
                booking_created_at,
                booking_updated_at,
            ),
        )

        booking = BookingSeed(
            booking_id=booking_id,
            guest=guest,
            listing=listing,
            checkin_date=checkin,
            checkout_date=checkout,
            guests_count=1 + (index % 4),
            status="completed",
            total_price=total_price,
        )
        bookings.append(booking)

        for fee_code, amount in (
            ("cleaning", cleaning_fee),
            ("service", service_fee),
        ):
            fetch_id(
                cursor,
                """
                INSERT INTO booking_fee (booking_id, fee_type_id, amount)
                VALUES (%s, %s, %s)
                RETURNING booking_id;
                """,
                (booking_id, fee_type_ids[fee_code], amount),
            )

        payment_occurred_at = booking_created_at + timedelta(hours=2)
        fetch_id(
            cursor,
            """
            INSERT INTO payment_transaction (
                booking_id, txn_type, amount, currency, method, status, occurred_at, updated_at
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING payment_id;
            """,
            (
                booking_id,
                "payment",
                total_price,
                listing.currency,
                "card" if index % 2 else "wallet",
                "succeeded",
                payment_occurred_at,
                payment_occurred_at + timedelta(minutes=5),
            ),
        )

        payout_amount = (total_price * HOST_PAYOUT_RATE).quantize(
            PRICE_Q, rounding=ROUND_HALF_UP
        )
        payout_sent_at = dt_at(checkout + timedelta(days=1), 14, 0)
        fetch_id(
            cursor,
            """
            INSERT INTO payout (
                booking_id, host_id, amount, currency, status, sent_at
            )
            VALUES (%s, %s, %s, %s, %s, %s)
            RETURNING payout_id;
            """,
            (
                booking_id,
                listing.host.user_id,
                payout_amount,
                listing.currency,
                "sent",
                payout_sent_at,
            ),
        )

    LOGGER.info("Inserted %s bookings, payments, and payouts", len(bookings))
    return bookings


def seed_engagement(
    cursor: psycopg.Cursor[Any],
    users: list[UserSeed],
    listings: list[ListingSeed],
    bookings: list[BookingSeed],
    fakers: dict[str, Faker],
) -> None:
    LOGGER.info(
        "Seeding wishlists, referrals, reviews, threads, messages, and notifications"
    )

    wishlist_ids: list[UUID] = []
    for index, user in enumerate(users, start=1):
        name = f"{'Favoriten' if user.locale == 'de_DE' else 'Favoritos'} {index}"
        wishlist_id = fetch_id(
            cursor,
            """
            INSERT INTO wishlist (user_id, name, created_at, updated_at)
            VALUES (%s, %s, %s, %s)
            RETURNING wishlist_id;
            """,
            (
                user.user_id,
                name,
                now_utc() - timedelta(days=index * 2),
                now_utc() - timedelta(days=index),
            ),
        )
        wishlist_ids.append(wishlist_id)

        chosen_listings = [
            listings[(index - 1 + offset) % len(listings)] for offset in range(3)
        ]
        for chosen in chosen_listings:
            fetch_id(
                cursor,
                """
                INSERT INTO wishlist_item (wishlist_id, listing_id, added_at)
                VALUES (%s, %s, %s)
                RETURNING wishlist_id;
                """,
                (wishlist_id, chosen.listing_id, now_utc() - timedelta(days=index + 3)),
            )

    LOGGER.info(
        "Inserted %s wishlists and %s wishlist items",
        len(wishlist_ids),
        len(wishlist_ids) * 3,
    )

    referee_pool = users[10:]
    referrer_pool = users[:10]
    for index, referrer in enumerate(referrer_pool):
        for offset in range(2):
            referee = referee_pool[(index + offset) % len(referee_pool)]
            if referrer.user_id == referee.user_id:
                referee = referee_pool[(index + offset + 1) % len(referee_pool)]
            fetch_id(
                cursor,
                """
                INSERT INTO referral (referrer_user_id, referee_user_id, created_at)
                VALUES (%s, %s, %s)
                RETURNING referral_id;
                """,
                (
                    referrer.user_id,
                    referee.user_id,
                    now_utc() - timedelta(days=index + offset + 1),
                ),
            )

    LOGGER.info("Inserted referral rows")

    for index, booking in enumerate(bookings, start=1):
        host = booking.listing.host
        guest = booking.guest
        listing = booking.listing
        booking_day = booking.checkin_date
        thread_id = fetch_id(
            cursor,
            """
            INSERT INTO message_thread (listing_id, booking_id)
            VALUES (%s, %s)
            RETURNING thread_id;
            """,
            (listing.listing_id, booking.booking_id),
        )

        guest_locale = fakers[guest.locale]
        host_locale = fakers[host.locale]
        guest_body = random.choice(
            GERMAN_MESSAGES if guest.locale == "de_DE" else SPANISH_MESSAGES
        )
        host_body = random.choice(
            GERMAN_MESSAGES if host.locale == "de_DE" else SPANISH_MESSAGES
        )

        fetch_id(
            cursor,
            """
            INSERT INTO message (thread_id, sender_user_id, body, sent_at)
            VALUES (%s, %s, %s, %s)
            RETURNING message_id;
            """,
            (
                thread_id,
                guest.user_id,
                guest_body,
                dt_at(booking_day - timedelta(days=2), 18, 30),
            ),
        )
        fetch_id(
            cursor,
            """
            INSERT INTO message (thread_id, sender_user_id, body, sent_at)
            VALUES (%s, %s, %s, %s)
            RETURNING message_id;
            """,
            (
                thread_id,
                host.user_id,
                host_body,
                dt_at(booking_day - timedelta(days=1), 9, 15),
            ),
        )

        guest_review_title = random.choice(
            GERMAN_REVIEW_TITLES if guest.locale == "de_DE" else SPANISH_REVIEW_TITLES
        )
        host_review_title = random.choice(
            GERMAN_REVIEW_TITLES if host.locale == "de_DE" else SPANISH_REVIEW_TITLES
        )
        guest_review_body = guest_locale.sentence(nb_words=14)
        host_review_body = host_locale.sentence(nb_words=14)

        fetch_id(
            cursor,
            """
            INSERT INTO review (
                booking_id, reviewer_user_id, reviewee_user_id, rating, title, body, created_at
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            RETURNING review_id;
            """,
            (
                booking.booking_id,
                guest.user_id,
                host.user_id,
                5 if index % 3 else 4,
                guest_review_title,
                guest_review_body,
                dt_at(booking.checkout_date, 13, 0),
            ),
        )
        fetch_id(
            cursor,
            """
            INSERT INTO review (
                booking_id, reviewer_user_id, reviewee_user_id, rating, title, body, created_at
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            RETURNING review_id;
            """,
            (
                booking.booking_id,
                host.user_id,
                guest.user_id,
                5 if index % 4 else 4,
                host_review_title,
                host_review_body,
                dt_at(booking.checkout_date, 13, 30),
            ),
        )

        notification_type = "booking_completed" if index % 2 else "message_received"
        payload = {
            "booking_id": str(booking.booking_id),
            "listing_id": str(listing.listing_id),
            "role": guest.role_name,
            "summary": "Completed stay" if index % 2 else "New message",
        }
        fetch_id(
            cursor,
            """
            INSERT INTO notification (user_id, type, payload, created_at, read_at)
            VALUES (%s, %s, %s, %s, %s)
            RETURNING notification_id;
            """,
            (
                guest.user_id,
                notification_type,
                Jsonb(payload),
                now_utc() - timedelta(days=index),
                now_utc() - timedelta(days=index - 1),
            ),
        )

    LOGGER.info("Inserted message threads, messages, reviews, and notifications")


def seed_database() -> None:
    random.seed(SEED)
    load_dotenv()
    configure_logging()
    fakers = get_fakers()

    LOGGER.info("Opening database connection")
    with connect() as connection:
        try:
            with connection.cursor() as cursor:
                reset_tables(cursor)
                role_ids = seed_roles(cursor)
                locations = seed_locations(cursor, fakers)
                amenity_ids, house_rule_ids, fee_type_ids, cancellation_policy_ids = (
                    seed_reference_catalogs(cursor)
                )
                user_rows = build_users(fakers)
                users = seed_users(cursor, user_rows, role_ids, fakers)
                listings = seed_listings(
                    cursor, users, locations, cancellation_policy_ids, fakers
                )
                seed_listing_details(cursor, listings, amenity_ids, house_rule_ids)
                bookings = seed_bookings(cursor, users, listings, fee_type_ids)
                seed_engagement(cursor, users, listings, bookings, fakers)

            connection.commit()
            LOGGER.info("Database seed completed successfully")
        except Exception:
            connection.rollback()
            LOGGER.exception("Database seed failed and was rolled back")
            raise


def main() -> int:
    seed_database()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

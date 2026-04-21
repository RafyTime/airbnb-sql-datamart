# Phase 2 - Table Schemas

This document presents the PostgreSQL schema implemented for the phase 2 datamart.
It serves as a reference for the tables, relationships, constraints, and indexes that
suport the app model designed in phase 1.

The entities are grouped by related features/use case and organized in the order they should be implemented.

## Identity And Access

### 1. `user`

**Description:** Stores the core user account record for guests, hosts, and other platform participants. It is the primary identity table that the rest of the application references for authentication, profile ownership, messaging, bookings, and access control.

```sql
CREATE TABLE "user" (
    user_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email       VARCHAR(255) NOT NULL,
    first_name  VARCHAR(100) NOT NULL,
    last_name   VARCHAR(100) NOT NULL,
    phone       VARCHAR(50),
    status      VARCHAR(32) NOT NULL,
    verified_at TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT user_email_unique UNIQUE (email)
);
```

### 2. `session`

**Description:** Stores active and revoked login sessions for users. This table supports device tracking and session lifecycle management without mixing session state into the main user record.

```sql
CREATE TABLE session (
    session_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID NOT NULL REFERENCES "user" (user_id) ON DELETE CASCADE,
    token         TEXT NOT NULL,
    refresh_token TEXT NOT NULL,
    user_agent    TEXT,
    ip_hash       VARCHAR(128),
    tag           VARCHAR(255),
    revoked_at    TIMESTAMPTZ,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

### 3. `account`

**Description:** Stores external authentication accounts and credential material for each user. It lets one user connect multiple sign-in providers while keeping authentication details separate from profile data.

```sql
CREATE TABLE account (
    auth_id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES "user" (user_id) ON DELETE CASCADE,
    provider            VARCHAR(64) NOT NULL,
    provider_account_id VARCHAR(255),
    access_token        TEXT,
    refresh_token       TEXT,
    scope               TEXT,
    expires_at          TIMESTAMPTZ,
    password_hash       TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

### 4. `verification`

**Description:** Stores verification codes, links, and other one-time identity checks. It keeps verification events separate from the user record so account confirmation, recovery, and similar workflows can be managed independently.

```sql
CREATE TABLE verification (
    verif_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES "user" (user_id) ON DELETE CASCADE,
    purpose     VARCHAR(64) NOT NULL,
    value       TEXT NOT NULL,
    consumed_at TIMESTAMPTZ,
    expires_at  TIMESTAMPTZ NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

### 5. `role`

**Description:** Stores the reusable authorization roles available in the platform. It provides the catalog that access rules and admin tooling use to grant permissions consistently.

```sql
CREATE TABLE role (
    role_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name       VARCHAR(64) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT role_name_unique UNIQUE (name)
);
```

### 6. `user_role`

**Description:** Stores the many-to-many relationship between users and roles. It records which users have which permissions and when those assignments were granted or revoked.

```sql
CREATE TABLE user_role (
    user_id     UUID NOT NULL REFERENCES "user" (user_id) ON DELETE CASCADE,
    role_id     UUID NOT NULL REFERENCES role (role_id) ON DELETE CASCADE,
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    revoked_at  TIMESTAMPTZ,
    PRIMARY KEY (user_id, role_id)
);
```

### 7. `user_profile`

**Description:** Stores optional presentation and preference data for a user. It keeps bios, languages, social links, and settings separate from the core account record so profile details can evolve independently.

```sql
CREATE TABLE user_profile (
    user_id    UUID PRIMARY KEY REFERENCES "user" (user_id) ON DELETE CASCADE,
    avatar_url TEXT NOT NULL,
    bio        TEXT NOT NULL,
    languages  TEXT[] NOT NULL DEFAULT '{}',
    socials    JSONB NOT NULL DEFAULT '{}',
    settings   JSONB NOT NULL DEFAULT '{}'
);
```

## Geography And Reference Data

### 8. `location`

**Description:** Stores the hierarchical geography tree used by listings and reporting. This table supports nested locations such as country, city, and neighborhood without duplicating location text in downstream entities.

```sql
CREATE TABLE location (
    location_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name                VARCHAR(255) NOT NULL,
    type                VARCHAR(64) NOT NULL,
    parent_location_id  UUID REFERENCES location (location_id) ON DELETE SET NULL
);
```

### 9. `amenity`

**Description:** Stores the reusable amenity catalog for listings. It standardizes amenity definitions so listings can share the same feature vocabulary.

```sql
CREATE TABLE amenity (
    amenity_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code       VARCHAR(64) NOT NULL,
    name       VARCHAR(255) NOT NULL,
    category   VARCHAR(128) NOT NULL,
    CONSTRAINT amenity_code_unique UNIQUE (code)
);
```

### 10. `house_rule`

**Description:** Stores the reusable house-rule catalog that hosts can apply to listings. It centralizes rule definitions so the same rule can be reused across many properties.

```sql
CREATE TABLE house_rule (
    rule_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code    VARCHAR(64) NOT NULL,
    name    VARCHAR(255) NOT NULL,
    CONSTRAINT house_rule_code_unique UNIQUE (code)
);
```

### 11. `fee_type`

**Description:** Stores the catalog of fee categories used in booking pricing. It allows each fee component to be tracked consistently across bookings and receipts.

```sql
CREATE TABLE fee_type (
    fee_type_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code        VARCHAR(64) NOT NULL,
    name        VARCHAR(255) NOT NULL,
    CONSTRAINT fee_type_code_unique UNIQUE (code)
);
```

### 12. `cancellation_policy`

**Description:** Stores the booking and listing cancellation policy definitions. It keeps policy rules in one place so listings and bookings can reference the same policy behavior.

```sql
CREATE TABLE cancellation_policy (
    policy_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code        VARCHAR(64) NOT NULL,
    name        VARCHAR(255) NOT NULL,
    rules_json  JSONB NOT NULL,
    CONSTRAINT cancellation_policy_code_unique UNIQUE (code)
);
```

## Listings And Availability

### 13. `listing`

**Description:** Stores the main property listing record for the marketplace. It ties a host, a location, and a cancellation policy together with the property details shown to guests.

```sql
CREATE TABLE listing (
    listing_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    host_id       UUID NOT NULL REFERENCES "user" (user_id) ON DELETE RESTRICT,
    location_id   UUID NOT NULL REFERENCES location (location_id) ON DELETE RESTRICT,
    policy_id     UUID NOT NULL REFERENCES cancellation_policy (policy_id) ON DELETE RESTRICT,
    title         VARCHAR(500) NOT NULL,
    description   TEXT NOT NULL,
    property_type VARCHAR(64) NOT NULL,
    room_type     VARCHAR(64) NOT NULL,
    accommodates  INTEGER NOT NULL,
    bedrooms      INTEGER NOT NULL,
    beds          INTEGER NOT NULL,
    bathrooms     NUMERIC(4, 1) NOT NULL,
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    postal_code   VARCHAR(32),
    lat           NUMERIC(9, 6),
    lng           NUMERIC(9, 6),
    base_price    NUMERIC(12, 2) NOT NULL,
    currency      CHAR(3) NOT NULL,
    status        VARCHAR(32) NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

### 14. `listing_photo`

**Description:** Stores listing images and their display order. It keeps media assets separate from the listing record so photos can be managed independently.

```sql
CREATE TABLE listing_photo (
    photo_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    listing_id  UUID NOT NULL REFERENCES listing (listing_id) ON DELETE CASCADE,
    url         TEXT NOT NULL,
    caption     TEXT,
    is_cover    BOOLEAN NOT NULL DEFAULT false,
    sort_order  INTEGER NOT NULL DEFAULT 0,
    uploaded_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

### 15. `listing_amenity`

**Description:** Stores the many-to-many relationship between listings and amenities. It records which reusable amenities belong to each listing.

```sql
CREATE TABLE listing_amenity (
    listing_id UUID NOT NULL REFERENCES listing (listing_id) ON DELETE CASCADE,
    amenity_id UUID NOT NULL REFERENCES amenity (amenity_id) ON DELETE CASCADE,
    PRIMARY KEY (listing_id, amenity_id)
);
```

### 16. `listing_house_rule`

**Description:** Stores the relationship between listings and house rules, including optional host-specific notes. It supports applying shared rules while still allowing listing-level detail.

```sql
CREATE TABLE listing_house_rule (
    listing_id UUID NOT NULL REFERENCES listing (listing_id) ON DELETE CASCADE,
    rule_id    UUID NOT NULL REFERENCES house_rule (rule_id) ON DELETE CASCADE,
    note       TEXT,
    PRIMARY KEY (listing_id, rule_id)
);
```

### 17. `listing_blocked_date`

**Description:** Stores individual blocked calendar dates for a listing. It is used to mark unavailable days without changing the listing itself.

```sql
CREATE TABLE listing_blocked_date (
    listing_id UUID NOT NULL REFERENCES listing (listing_id) ON DELETE CASCADE,
    day        DATE NOT NULL,
    reason     TEXT,
    PRIMARY KEY (listing_id, day)
);
```

## Bookings And Payments

### 18. `booking`

**Description:** Stores confirmed and pending reservations between guests and listings. It is the central transactional record for stays, pricing, and booking status.

```sql
CREATE TABLE booking (
    booking_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    guest_id      UUID NOT NULL REFERENCES "user" (user_id) ON DELETE RESTRICT,
    listing_id    UUID NOT NULL REFERENCES listing (listing_id) ON DELETE RESTRICT,
    policy_id     UUID NOT NULL REFERENCES cancellation_policy (policy_id) ON DELETE RESTRICT,
    checkin_date  DATE NOT NULL,
    checkout_date DATE NOT NULL,
    guests_count  INTEGER NOT NULL,
    status        VARCHAR(32) NOT NULL,
    total_price   NUMERIC(12, 2) NOT NULL,
    currency      CHAR(3) NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT booking_checkin_before_checkout CHECK (checkin_date < checkout_date),
    CONSTRAINT booking_guests_positive CHECK (guests_count > 0)
);
```

### 19. `booking_fee`

**Description:** Stores the itemized fees attached to a booking. It breaks total booking price into reusable fee categories for receipts and reporting.

```sql
CREATE TABLE booking_fee (
    booking_id   UUID NOT NULL REFERENCES booking (booking_id) ON DELETE CASCADE,
    fee_type_id  UUID NOT NULL REFERENCES fee_type (fee_type_id) ON DELETE RESTRICT,
    amount       NUMERIC(12, 2) NOT NULL,
    PRIMARY KEY (booking_id, fee_type_id),
    CONSTRAINT booking_fee_amount_non_negative CHECK (amount >= 0)
);
```

### 20. `payment_transaction`

**Description:** Stores payment events tied to a booking. It captures the lifecycle of charges, refunds, and other money movements independently from the booking header.

```sql
CREATE TABLE payment_transaction (
    payment_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id  UUID NOT NULL REFERENCES booking (booking_id) ON DELETE RESTRICT,
    txn_type    VARCHAR(32) NOT NULL,
    amount      NUMERIC(12, 2) NOT NULL,
    currency    CHAR(3) NOT NULL,
    method      VARCHAR(64) NOT NULL,
    status      VARCHAR(32) NOT NULL,
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT payment_transaction_amount_positive CHECK (amount > 0)
);
```

### 21. `payout`

**Description:** Stores host payout records generated from bookings. It tracks how much money was sent to the host and when that transfer occurred.

```sql
CREATE TABLE payout (
    payout_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID NOT NULL REFERENCES booking (booking_id) ON DELETE RESTRICT,
    host_id    UUID NOT NULL REFERENCES "user" (user_id) ON DELETE RESTRICT,
    amount     NUMERIC(12, 2) NOT NULL,
    currency   CHAR(3) NOT NULL,
    status     VARCHAR(32) NOT NULL,
    sent_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT payout_one_per_booking UNIQUE (booking_id)
);
```

## Messaging And Engagement

### 22. `message_thread`

**Description:** Stores the conversation thread header for guest-host communication. It links a thread to a listing and optionally to a booking so the chat can be tied to a specific reservation.

```sql
CREATE TABLE message_thread (
    thread_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    listing_id  UUID NOT NULL REFERENCES listing (listing_id) ON DELETE CASCADE,
    booking_id  UUID REFERENCES booking (booking_id) ON DELETE SET NULL
);
```

### 23. `message`

**Description:** Stores the individual messages exchanged inside a conversation thread. It holds the actual message content and sender identity separately from the thread metadata.

```sql
CREATE TABLE message (
    message_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    thread_id       UUID NOT NULL REFERENCES message_thread (thread_id) ON DELETE CASCADE,
    sender_user_id  UUID NOT NULL REFERENCES "user" (user_id) ON DELETE RESTRICT,
    body            TEXT NOT NULL,
    sent_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

### 24. `wishlist`

**Description:** Stores a user's saved trip collections. It lets guests organize listings into named lists without duplicating listing data.

```sql
CREATE TABLE wishlist (
    wishlist_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES "user" (user_id) ON DELETE CASCADE,
    name        VARCHAR(255) NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

### 25. `wishlist_item`

**Description:** Stores the many-to-many relationship between wishlists and listings. It records which properties a user saved into each collection.

```sql
CREATE TABLE wishlist_item (
    wishlist_id UUID NOT NULL REFERENCES wishlist (wishlist_id) ON DELETE CASCADE,
    listing_id  UUID NOT NULL REFERENCES listing (listing_id) ON DELETE CASCADE,
    added_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (wishlist_id, listing_id)
);
```

### 26. `referral`

**Description:** Stores referral relationships between two users. It captures who invited whom so referral programs can be tracked independently from core account data.

```sql
CREATE TABLE referral (
    referral_id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    referrer_user_id  UUID NOT NULL REFERENCES "user" (user_id) ON DELETE CASCADE,
    referee_user_id   UUID NOT NULL REFERENCES "user" (user_id) ON DELETE CASCADE,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT referral_distinct_users CHECK (referrer_user_id <> referee_user_id),
    CONSTRAINT referral_pair_unique UNIQUE (referrer_user_id, referee_user_id)
);
```

### 27. `review`

**Description:** Stores guest reviews tied to completed bookings. It supports verified feedback by linking the reviewer, the reviewed host, and the reservation that qualifies the review.

```sql
CREATE TABLE review (
    review_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id        UUID NOT NULL REFERENCES booking (booking_id) ON DELETE RESTRICT,
    reviewer_user_id  UUID NOT NULL REFERENCES "user" (user_id) ON DELETE RESTRICT,
    reviewee_user_id  UUID NOT NULL REFERENCES "user" (user_id) ON DELETE RESTRICT,
    rating            SMALLINT NOT NULL,
    title             VARCHAR(255) NOT NULL,
    body              TEXT NOT NULL,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT review_one_per_reviewer_per_booking UNIQUE (booking_id, reviewer_user_id),
    CONSTRAINT review_rating_range CHECK (rating >= 1 AND rating <= 5)
);
```

### 28. `notification`

**Description:** Stores user-facing notifications generated by application events. It supports the activity center by holding the message payload, read state, and recipient user.

```sql
CREATE TABLE notification (
    notification_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES "user" (user_id) ON DELETE CASCADE,
    type            VARCHAR(64) NOT NULL,
    payload         JSONB NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    read_at         TIMESTAMPTZ
);
```

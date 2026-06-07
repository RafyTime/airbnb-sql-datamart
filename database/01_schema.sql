-- Airbnb SQL Datamart schema
-- Loaded first by Docker Compose from /docker-entrypoint-initdb.d/01_schema.sql

-- ============================================================
-- Identity And Access
-- ============================================================

-- Identity: users, auth, roles, profile (Phase 1 data dictionary)

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

CREATE TABLE verification (
    verif_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES "user" (user_id) ON DELETE CASCADE,
    purpose     VARCHAR(64) NOT NULL,
    value       TEXT NOT NULL,
    consumed_at TIMESTAMPTZ,
    expires_at  TIMESTAMPTZ NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE role (
    role_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name       VARCHAR(64) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT role_name_unique UNIQUE (name)
);

CREATE TABLE user_role (
    user_id     UUID NOT NULL REFERENCES "user" (user_id) ON DELETE CASCADE,
    role_id     UUID NOT NULL REFERENCES role (role_id) ON DELETE CASCADE,
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    revoked_at  TIMESTAMPTZ,
    PRIMARY KEY (user_id, role_id)
);

CREATE TABLE user_profile (
    user_id    UUID PRIMARY KEY REFERENCES "user" (user_id) ON DELETE CASCADE,
    avatar_url TEXT NOT NULL,
    bio        TEXT NOT NULL,
    languages  TEXT[] NOT NULL DEFAULT '{}',
    socials    JSONB NOT NULL DEFAULT '{}',
    settings   JSONB NOT NULL DEFAULT '{}'
);

CREATE INDEX idx_session_user_id ON session (user_id);
CREATE INDEX idx_account_user_id ON account (user_id);
CREATE INDEX idx_verification_user_id ON verification (user_id);
CREATE INDEX idx_user_role_role_id ON user_role (role_id);

-- ============================================================
-- Geography And Reference Data
-- ============================================================

-- Location hierarchy (Phase 1 data dictionary)

CREATE TABLE location (
    location_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name                VARCHAR(255) NOT NULL,
    type                VARCHAR(64) NOT NULL,
    parent_location_id  UUID REFERENCES location (location_id) ON DELETE SET NULL
);

CREATE INDEX idx_location_parent ON location (parent_location_id);

-- Reference catalogs: amenities, rules, fees, cancellation policies

CREATE TABLE amenity (
    amenity_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code       VARCHAR(64) NOT NULL,
    name       VARCHAR(255) NOT NULL,
    category   VARCHAR(128) NOT NULL,
    CONSTRAINT amenity_code_unique UNIQUE (code)
);

CREATE TABLE house_rule (
    rule_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code    VARCHAR(64) NOT NULL,
    name    VARCHAR(255) NOT NULL,
    CONSTRAINT house_rule_code_unique UNIQUE (code)
);

CREATE TABLE fee_type (
    fee_type_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code        VARCHAR(64) NOT NULL,
    name        VARCHAR(255) NOT NULL,
    CONSTRAINT fee_type_code_unique UNIQUE (code)
);

CREATE TABLE cancellation_policy (
    policy_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code        VARCHAR(64) NOT NULL,
    name        VARCHAR(255) NOT NULL,
    rules_json  JSONB NOT NULL,
    CONSTRAINT cancellation_policy_code_unique UNIQUE (code)
);

-- ============================================================
-- Listings And Availability
-- ============================================================

-- Listings and related photos, amenities, rules, blocked dates

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

CREATE TABLE listing_photo (
    photo_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    listing_id  UUID NOT NULL REFERENCES listing (listing_id) ON DELETE CASCADE,
    url         TEXT NOT NULL,
    caption     TEXT,
    is_cover    BOOLEAN NOT NULL DEFAULT false,
    sort_order  INTEGER NOT NULL DEFAULT 0,
    uploaded_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE listing_amenity (
    listing_id UUID NOT NULL REFERENCES listing (listing_id) ON DELETE CASCADE,
    amenity_id UUID NOT NULL REFERENCES amenity (amenity_id) ON DELETE CASCADE,
    PRIMARY KEY (listing_id, amenity_id)
);

CREATE TABLE listing_house_rule (
    listing_id UUID NOT NULL REFERENCES listing (listing_id) ON DELETE CASCADE,
    rule_id    UUID NOT NULL REFERENCES house_rule (rule_id) ON DELETE CASCADE,
    note       TEXT,
    PRIMARY KEY (listing_id, rule_id)
);

CREATE TABLE listing_blocked_date (
    listing_id UUID NOT NULL REFERENCES listing (listing_id) ON DELETE CASCADE,
    day        DATE NOT NULL,
    reason     TEXT,
    PRIMARY KEY (listing_id, day)
);

CREATE INDEX idx_listing_host_id ON listing (host_id);
CREATE INDEX idx_listing_location_id ON listing (location_id);
CREATE INDEX idx_listing_policy_id ON listing (policy_id);
CREATE INDEX idx_listing_photo_listing_id ON listing_photo (listing_id);
CREATE INDEX idx_listing_amenity_amenity_id ON listing_amenity (amenity_id);
CREATE INDEX idx_listing_house_rule_rule_id ON listing_house_rule (rule_id);

-- ============================================================
-- Bookings And Payments
-- ============================================================

-- Bookings and per-booking fees

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

CREATE TABLE booking_fee (
    booking_id   UUID NOT NULL REFERENCES booking (booking_id) ON DELETE CASCADE,
    fee_type_id  UUID NOT NULL REFERENCES fee_type (fee_type_id) ON DELETE RESTRICT,
    amount       NUMERIC(12, 2) NOT NULL,
    PRIMARY KEY (booking_id, fee_type_id),
    CONSTRAINT booking_fee_amount_non_negative CHECK (amount >= 0)
);

CREATE INDEX idx_booking_guest_id ON booking (guest_id);
CREATE INDEX idx_booking_listing_id ON booking (listing_id);
CREATE INDEX idx_booking_policy_id ON booking (policy_id);
CREATE INDEX idx_booking_fee_fee_type_id ON booking_fee (fee_type_id);

-- Payment events and host payouts

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

CREATE INDEX idx_payment_transaction_booking_id ON payment_transaction (booking_id);
CREATE INDEX idx_payout_host_id ON payout (host_id);

-- ============================================================
-- Messaging And Engagement
-- ============================================================

-- Message threads and messages

CREATE TABLE message_thread (
    thread_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    listing_id  UUID NOT NULL REFERENCES listing (listing_id) ON DELETE CASCADE,
    booking_id  UUID REFERENCES booking (booking_id) ON DELETE SET NULL
);

CREATE TABLE message (
    message_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    thread_id       UUID NOT NULL REFERENCES message_thread (thread_id) ON DELETE CASCADE,
    sender_user_id  UUID NOT NULL REFERENCES "user" (user_id) ON DELETE RESTRICT,
    body            TEXT NOT NULL,
    sent_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_message_thread_listing_id ON message_thread (listing_id);
CREATE INDEX idx_message_thread_booking_id ON message_thread (booking_id);
CREATE INDEX idx_message_thread_id ON message (thread_id);
CREATE INDEX idx_message_sender_user_id ON message (sender_user_id);

-- Wishlists, referrals, reviews, notifications

CREATE TABLE wishlist (
    wishlist_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES "user" (user_id) ON DELETE CASCADE,
    name        VARCHAR(255) NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE wishlist_item (
    wishlist_id UUID NOT NULL REFERENCES wishlist (wishlist_id) ON DELETE CASCADE,
    listing_id  UUID NOT NULL REFERENCES listing (listing_id) ON DELETE CASCADE,
    added_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (wishlist_id, listing_id)
);

CREATE TABLE referral (
    referral_id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    referrer_user_id  UUID NOT NULL REFERENCES "user" (user_id) ON DELETE CASCADE,
    referee_user_id   UUID NOT NULL REFERENCES "user" (user_id) ON DELETE CASCADE,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT referral_distinct_users CHECK (referrer_user_id <> referee_user_id),
    CONSTRAINT referral_pair_unique UNIQUE (referrer_user_id, referee_user_id)
);

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

CREATE TABLE notification (
    notification_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES "user" (user_id) ON DELETE CASCADE,
    type            VARCHAR(64) NOT NULL,
    payload         JSONB NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    read_at         TIMESTAMPTZ
);

CREATE INDEX idx_wishlist_user_id ON wishlist (user_id);
CREATE INDEX idx_wishlist_item_listing_id ON wishlist_item (listing_id);
CREATE INDEX idx_referral_referee ON referral (referee_user_id);
CREATE INDEX idx_review_booking_id ON review (booking_id);
CREATE INDEX idx_review_reviewee ON review (reviewee_user_id);
CREATE INDEX idx_notification_user_id ON notification (user_id);

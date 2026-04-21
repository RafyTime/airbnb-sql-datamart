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

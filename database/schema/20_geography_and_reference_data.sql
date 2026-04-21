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

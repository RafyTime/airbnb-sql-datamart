-- Location hierarchy (Phase 1 data dictionary)

CREATE TABLE location (
    location_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name                VARCHAR(255) NOT NULL,
    type                VARCHAR(64) NOT NULL,
    parent_location_id  UUID REFERENCES location (location_id) ON DELETE SET NULL
);

CREATE INDEX idx_location_parent ON location (parent_location_id);

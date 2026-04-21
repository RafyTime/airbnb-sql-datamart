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

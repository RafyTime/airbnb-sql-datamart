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

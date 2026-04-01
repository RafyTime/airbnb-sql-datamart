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

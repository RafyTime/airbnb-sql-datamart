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


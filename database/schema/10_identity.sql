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

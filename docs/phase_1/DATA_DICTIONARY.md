# **Data Dictionary**

## user

| Name       | Type        | Description                                       |
|:-----------|:------------|:--------------------------------------------------|
| user_id    | uuid        | Surrogate primary key for the user.               |
| email      | string      | Unique email used for login/identification.       |
| first_name | string      | User’s given name.                                |
| last_name  | string      | User’s family name.                               |
| phone      | string?     | Optional phone number for contact/verification.   |
| status     | string      | Account state (e.g., active, disabled).           |
| verified_at| timestamp?  | When the user verified email/identity.            |
| created_at | timestamp   | Row creation timestamp (UTC).                     |
| updated_at | timestamp   | Last update timestamp (UTC).                      |

## session

| Name          | Type        | Description                                    |
|:--------------|:------------|:---------------------------------------------  |
| session_id    | uuid        | Surrogate primary key for a login session.     |
| user_id       | uuid        | FK to user owning the session.                 |
| token         | string      | Session token identifier (hashed if persisted).|
| refresh_token | string      | Token used to renew the session.               |
| user_agent    | string?     | Client user agent string (browser/app).        |
| ip_hash       | string?     | Hashed IP for security/auditing.               |
| tag           | string?     | Optional label (e.g., device name).            |
| revoked_at    | timestamp   | When the session was revoked (if any).         |
| created_at    | timestamp   | Session creation time.                         |
| updated_at    | timestamp   | Last session update time.                      |

## account

| Name                | Type        | Description                               |
|:--------------------|:------------|:------------------------------------------|
| auth_id             | uuid        | Surrogate primary key for auth account.   |
| user_id             | uuid        | FK to user.                               |
| provider            | string      | Auth provider (password, google, etc.).   |
| provider_account_id | string?     | Provider-side user/account id.            |
| access_token        | string?     | Provider access token (if stored).        |
| refresh_token       | string?     | Provider refresh token (if stored).       |
| scope               | string?     | OAuth scopes granted.                     |
| expires_at          | timestamp?  | Token expiration timestamp.               |
| password_hash       | string?     | Password hash for local login.            |
| created_at          | timestamp   | Account record creation time.             |
| updated_at          | timestamp   | Last update time.                         |

## verification

| Name         | Type        | Description                                  |
|:-------------|:------------|:-------------------------------------------- |
| verif_id     | uuid        | Surrogate primary key for verification event.|
| user_id      | uuid        | FK to user being verified.                   |
| purpose      | string      | Purpose (email, phone, reset, etc.).         |
| value        | string      | Token/code or value to verify.               |
| consumed_at  | timestamp?  | When the token/value was consumed.           |
| expires_at   | timestamp   | When the token/value expires.                |
| created_at   | timestamp   | Creation timestamp.                          |

## role

| Name      | Type      | Description                                   |
|:----------|:----------|:----------------------------------------------|
| role_id   | uuid      | Surrogate primary key for role.               |
| name      | string    | Unique role name (e.g., admin, host, guest).  |
| created_at| timestamp | Creation timestamp.                           |

## user_role

| Name       | Type      | Description                 |
|:-----------|:----------|:----------------------------|
| user_id    | uuid      | FK to user.                 |
| role_id    | uuid      | FK to role.                 |
| assigned_at| timestamp | When the role was assigned. |
| revoked_at | timestamp?| When the role was revoked.  |

## user_profile

| Name       | Type      | Description                          |
|:-----------|:----------|:-------------------------------------|
| user_id    | uuid      | PK and FK to user (1:1).             |
| avatar_url | string    | Profile image URL.                   |
| bio        | text      | Short user biography.                |
| languages  | text[]    | Languages the user speaks.           |
| socials    | json      | Social links/handles.                |
| settings   | json      | User preferences/settings.           |

## location

| Name                | Type      | Description                                       |
|:--------------------|:----------|:--------------------------------------------------|
| location_id         | uuid      | Surrogate primary key for location node.          |
| name                | string    | Location name (e.g., “Paris”, “Île‑de‑France”).   |
| type                | string    | Granularity/type (country, region, city, area).   |
| parent_location_id  | uuid      | Parent location id (null for root).               |

## listing

| Name            | Type          | Description                                      |
|:----------------|:--------------|:-------------------------------------------------|
| listing_id      | uuid          | Surrogate primary key for listing.               |
| host_id         | uuid          | FK to user who hosts the listing.                |
| location_id     | uuid          | FK to location of the listing.                   |
| policy_id       | uuid          | FK to cancellation_policy in force.              |
| title           | string        | Public title of the listing.                     |
| description     | text          | Detailed description of the property.            |
| property_type   | string        | Property type (apartment, house, etc.).          |
| room_type       | string        | Room type (entire place, private room, etc.).    |
| accommodates    | int           | Max number of guests.                            |
| bedrooms        | int           | Number of bedrooms.                              |
| beds            | int           | Number of beds.                                  |
| bathrooms       | numeric       | Number of bathrooms (supports decimals).         |
| address_line1   | string?       | Address line 1.                                  |
| address_line2   | string?       | Address line 2.                                  |
| postal_code     | string?       | Postal/ZIP code.                                 |
| lat             | decimal(6,9)  | Latitude coordinate.                             |
| lng             | decimal(6,9)  | Longitude coordinate.                            |
| base_price      | decimal       | Base nightly price.                              |
| currency        | char(3)       | ISO‑4217 currency code.                          |
| status          | string        | Listing status (draft, active, suspended).       |
| created_at      | timestamp     | Creation timestamp.                              |
| updated_at      | timestamp     | Last update timestamp.                           |

## listing_photo

| Name        | Type      | Description                           |
|:------------|:----------|:--------------------------------------|
| photo_id    | uuid      | Surrogate primary key for photo.      |
| listing_id  | uuid      | FK to listing.                        |
| url         | string    | Public URL of the image.              |
| caption     | string    | Optional caption/alt text.            |
| is_cover    | bool      | Whether this is the cover image.      |
| sort_order  | int       | Display order among photos.           |
| uploaded_at | timestamp | When the photo was uploaded.          |

## amenity

| Name        | Type      | Description                               |
|:------------|:----------|:------------------------------------------|
| amenity_id  | uuid      | Surrogate primary key for amenity.        |
| code        | string    | Unique amenity code.                      |
| name        | string    | Human‑readable amenity name.              |
| category    | string    | Group/category (e.g., kitchen, safety).   |

## listing_amenity

| Name        | Type      | Description                   |
|:------------|:----------|:------------------------------|
| listing_id  | uuid      | FK to listing.                |
| amenity_id  | uuid      | FK to amenity.                |

## house_rule

| Name       | Type      | Description                          |
|:-----------|:----------|:-------------------------------------|
| rule_id    | uuid      | Surrogate primary key for house rule.|
| code       | string    | Unique rule code.                    |
| name       | string    | Human‑readable rule name.            |

## listing_house_rule

| Name       | Type    | Description                            |
|:-----------|:--------|:---------------------------------------|
| listing_id | uuid    | FK to listing.                         |
| rule_id    | uuid    | FK to house_rule.                      |
| note       | text?   | Optional rule note/clarification.      |

## listing_blocked_date

| Name        | Type    | Description                                  |
|:------------|:--------|:---------------------------------------------|
| listing_id  | uuid    | FK to listing.                               |
| day         | date    | Date blocked (unavailable).                  |
| reason      | text?   | Reason for block (maintenance, hold, etc.).  |

## cancellation_policy

| Name      | Type    | Description                                      |
|:----------|:--------|:-------------------------------------------------|
| policy_id | uuid    | Surrogate primary key for policy.                |
| code      | string  | Unique policy code (e.g., FLEX, STRICT).         |
| name      | string  | Human‑readable policy name.                      |
| rules_json| json    | JSON describing refund rules/tiers.              |

## booking

| Name         | Type      | Description                                                        |
|:-------------|:----------|:-------------------------------------------------------------------|
| booking_id   | uuid      | Surrogate primary key for booking.                                 |
| guest_id     | uuid      | FK to user who books (guest).                                      |
| listing_id   | uuid      | FK to listing booked.                                              |
| policy_id    | uuid      | FK to cancellation policy at booking time.                         |
| checkin_date | date      | Check‑in date.                                                     |
| checkout_date| date      | Check‑out date.                                                    |
| guests_count | int       | Number of guests in the booking.                                   |
| status       | string    | Booking state (pending, accepted, cancelled, completed).           |
| total_price  | decimal   | Computed total price for the stay.                                 |
| currency     | char(3)   | ISO‑4217 currency of the booking.                                  |
| created_at   | timestamp | Creation timestamp.                                                |
| updated_at   | timestamp | Last update timestamp.                                             |

## fee_type

| Name         | Type      | Description                          |
|:-------------|:----------|:-------------------------------------|
| fee_type_id  | uuid      | Surrogate primary key for fee type.  |
| code         | string    | Unique fee code.                     |
| name         | string    | Fee name (e.g., cleaning, service).  |

## booking_fee

| Name         | Type    | Description                           |
|:-------------|:--------|:--------------------------------------|
| booking_id   | uuid    | FK to booking.                        |
| fee_type_id  | uuid    | FK to fee_type.                       |
| amount       | decimal | Fee amount applied to the booking.    |

## payment_transaction

| Name        | Type        | Description                                        |
|:------------|:------------|:---------------------------------------------------|
| payment_id  | uuid        | Surrogate primary key for payment event.           |
| booking_id  | uuid        | FK to related booking.                             |
| txn_type    | string      | Type (payment, refund, chargeback).                |
| amount      | decimal     | Transaction amount (positive).                     |
| currency    | char(3)     | ISO‑4217 currency code.                            |
| method      | string      | Payment method (card, wallet, etc.).               |
| status      | string      | Processing status (pending, succeeded, failed).    |
| occurred_at | timestamp   | When the transaction occurred.                     |
| updated_at  | timestamp   | Last update timestamp.                             |

## payout

| Name       | Type      | Description                                           |
|:-----------|:----------|:------------------------------------------------------|
| payout_id  | uuid      | Surrogate primary key for payout.                     |
| booking_id | uuid      | FK to booking (unique per booking).                   |
| host_id    | uuid      | FK to host user receiving payout.                     |
| amount     | decimal   | Payout amount to host.                                |
| currency   | char(3)   | Currency of the payout.                               |
| status     | string    | Payout status (scheduled, sent, failed).              |
| sent_at    | timestamp | When the payout was sent.                             |

## wishlist

| Name         | Type      | Description                            |
|:-------------|:----------|:---------------------------------------|
| wishlist_id  | uuid      | Surrogate primary key for wishlist.    |
| user_id      | uuid      | FK to user owning the wishlist.        |
| name         | string    | Wishlist name.                         |
| created_at   | timestamp | Creation timestamp.                    |
| updated_at   | timestamp | Last update timestamp.                 |

## wishlist_item

| Name         | Type      | Description                  |
|:-------------|:----------|:-----------------------------|
| wishlist_id  | uuid      | FK to wishlist.              |
| listing_id   | uuid      | FK to listing.               |
| added_at     | timestamp | When the listing was added.  |

## message_thread

| Name        | Type     | Description                                |
|:------------|:---------|:-------------------------------------------|
| thread_id   | uuid     | Surrogate primary key for thread.          |
| listing_id  | uuid     | FK to listing context.                     |
| booking_id  | uuid?    | Optional FK to booking (if post‑booking).  |

## message

| Name            | Type     | Description                            |
|:----------------|:-------- |:-------------------------------------- |
| message_id      | uuid     | Surrogate primary key for message.     |
| thread_id       | uuid     | FK to message_thread.                  |
| sender_user_id  | uuid     | FK to user who sent the message.       |
| body            | text     | Message content.                       |
| sent_at         | timestamp| When the message was sent.             |

## referral

| Name             | Type      | Description                        |
|:-----------------|:----------|:---------------------------------  |
| referral_id      | uuid      | Surrogate primary key for referral.|
| referrer_user_id | uuid      | FK to user who invited.            |
| referee_user_id  | uuid      | FK to invited user.                |
| created_at       | timestamp | When the referral was created.     |

## review

| Name              | Type      | Description                                      |
|:------------------|:----------|:-------------------------------------------------|
| review_id         | uuid      | Surrogate primary key for review.                |
| booking_id        | uuid      | FK to booking being reviewed.                    |
| reviewer_user_id  | uuid      | FK to user authoring the review.                 |
| reviewee_user_id  | uuid      | FK to user receiving the review.                 |
| rating            | smallint  | Integer rating score.                            |
| title             | string    | Short review title.                              |
| body              | text      | Review text body.                                |
| created_at        | timestamp | When the review was created.                     |

## notification

| Name             | Type        | Description                                     |
|:-----------------|:------------|:------------------------------------------------|
| notification_id  | uuid        | Surrogate primary key for notification.         |
| user_id          | uuid        | FK to user to notify.                           |
| type             | string      | Notification type/category.                     |
| payload          | json        | Payload with event‑specific details.            |
| created_at       | timestamp   | Creation time of the notification.              |
| read_at          | timestamp?  | When the notification was read.                 |

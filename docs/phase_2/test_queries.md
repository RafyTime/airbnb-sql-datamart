# Phase 2 Test Query Catalog

This catalog groups validated PostgreSQL test queries by domain so a tutor can quickly confirm that the seeded Airbnb datamart contains working, app-like data across the full schema.

Each query below is designed as an individual test case for one table, while still joining nearby tables when that makes the result more realistic to review.

## Identity And Access

### 1. `user`: recent user directory

```sql
SELECT
    user_id,
    email,
    first_name,
    last_name,
    status,
    verified_at,
    created_at
FROM "user"
ORDER BY created_at DESC
LIMIT 10;
```

This simulates an admin or trust-and-safety directory view of recently created users.

### 2. `session`: active sessions by device

```sql
SELECT
    s.session_id,
    u.email,
    s.tag,
    s.user_agent,
    s.created_at,
    s.updated_at
FROM session s
JOIN "user" u ON u.user_id = s.user_id
WHERE s.revoked_at IS NULL
ORDER BY s.updated_at DESC, s.created_at DESC
LIMIT 10;
```

This simulates a security view of currently active user sessions.

### 3. `account`: linked login providers

```sql
SELECT
    u.email,
    a.provider,
    a.provider_account_id,
    a.expires_at,
    a.created_at
FROM account a
JOIN "user" u ON u.user_id = a.user_id
ORDER BY a.created_at DESC
LIMIT 10;
```

This simulates an account-management screen that shows how users sign in.

### 4. `verification`: pending and consumed verifications

```sql
SELECT
    u.email,
    v.purpose,
    v.expires_at,
    v.consumed_at,
    (v.consumed_at IS NULL) AS is_pending
FROM verification v
JOIN "user" u ON u.user_id = v.user_id
ORDER BY v.created_at DESC
LIMIT 10;
```

This simulates support staff checking whether user verification flows are still pending or already used.

### 5. `role`: role catalog

```sql
SELECT
    role_id,
    name,
    created_at
FROM role
ORDER BY name;
```

This simulates a simple authorization-role catalog used by the platform.

### 6. `user_role`: current role assignments

```sql
SELECT
    u.email,
    r.name AS role_name,
    ur.assigned_at,
    ur.revoked_at
FROM user_role ur
JOIN "user" u ON u.user_id = ur.user_id
JOIN role r ON r.role_id = ur.role_id
ORDER BY ur.assigned_at DESC
LIMIT 10;
```

This simulates an admin screen for reviewing which users currently hold which roles.

### 7. `user_profile`: profile completeness and localization

```sql
SELECT
    u.email,
    CARDINALITY(up.languages) AS language_count,
    up.settings ->> 'locale' AS locale,
    up.settings ->> 'timezone' AS timezone,
    LENGTH(up.bio) AS bio_length
FROM user_profile up
JOIN "user" u ON u.user_id = up.user_id
ORDER BY language_count DESC, bio_length DESC
LIMIT 10;
```

This simulates a profile-quality review that checks localization and profile completeness.

## Geography And Reference Data

### 8. `location`: listing locations in the hierarchy

```sql
SELECT
    child.name AS place_name,
    child.type AS place_type,
    parent.name AS parent_place,
    COUNT(l.listing_id) AS listing_count
FROM location child
LEFT JOIN location parent ON parent.location_id = child.parent_location_id
LEFT JOIN listing l ON l.location_id = child.location_id
GROUP BY child.location_id, child.name, child.type, parent.name
ORDER BY listing_count DESC, child.name
LIMIT 10;
```

This simulates a catalog of places and shows which nodes in the hierarchy currently have listings attached.

### 9. `amenity`: amenity adoption across listings

```sql
SELECT
    a.code,
    a.name,
    a.category,
    COUNT(la.listing_id) AS listings_using_amenity
FROM amenity a
LEFT JOIN listing_amenity la ON la.amenity_id = a.amenity_id
GROUP BY a.amenity_id, a.code, a.name, a.category
ORDER BY listings_using_amenity DESC, a.name
LIMIT 10;
```

This simulates a reference-data report showing which amenities are most common.

### 10. `house_rule`: house-rule usage

```sql
SELECT
    hr.code,
    hr.name,
    COUNT(lhr.listing_id) AS listings_using_rule
FROM house_rule hr
LEFT JOIN listing_house_rule lhr ON lhr.rule_id = hr.rule_id
GROUP BY hr.rule_id, hr.code, hr.name
ORDER BY listings_using_rule DESC, hr.name
LIMIT 10;
```

This simulates a rule-catalog report showing which house rules hosts apply most often.

### 11. `fee_type`: booking fee catalog in use

```sql
SELECT
    ft.code,
    ft.name,
    COUNT(bf.booking_id) AS bookings_with_fee,
    COALESCE(SUM(bf.amount), 0) AS total_fee_amount
FROM fee_type ft
LEFT JOIN booking_fee bf ON bf.fee_type_id = ft.fee_type_id
GROUP BY ft.fee_type_id, ft.code, ft.name
ORDER BY total_fee_amount DESC, ft.name
LIMIT 10;
```

This simulates a finance check on which fee types appear in booking charges.

### 12. `cancellation_policy`: policy adoption by listings

```sql
SELECT
    cp.code,
    cp.name,
    COUNT(l.listing_id) AS active_listing_count
FROM cancellation_policy cp
LEFT JOIN listing l ON l.policy_id = cp.policy_id
GROUP BY cp.policy_id, cp.code, cp.name
ORDER BY active_listing_count DESC, cp.name
LIMIT 10;
```

This simulates a host-policy overview showing which cancellation policies are actually used.

## Listings And Availability

### 13. `listing`: active listing directory

```sql
SELECT
    l.listing_id,
    l.title,
    host.email AS host_email,
    loc.name AS place_name,
    l.property_type,
    l.room_type,
    l.base_price,
    l.currency,
    l.status
FROM listing l
JOIN "user" host ON host.user_id = l.host_id
JOIN location loc ON loc.location_id = l.location_id
ORDER BY l.created_at DESC
LIMIT 10;
```

This simulates an operations view of the latest listings with host and place context.

### 14. `listing_photo`: cover photos for listing cards

```sql
SELECT
    l.title AS listing_title,
    lp.url,
    lp.caption,
    lp.is_cover,
    lp.sort_order
FROM listing_photo lp
JOIN listing l ON l.listing_id = lp.listing_id
WHERE lp.is_cover = TRUE
ORDER BY lp.uploaded_at DESC
LIMIT 10;
```

This simulates the photo selected for listing search results and detail pages.

### 15. `listing_amenity`: amenity checklist per listing

```sql
SELECT
    l.title AS listing_title,
    a.name AS amenity_name,
    a.category
FROM listing_amenity la
JOIN listing l ON l.listing_id = la.listing_id
JOIN amenity a ON a.amenity_id = la.amenity_id
ORDER BY l.title, a.name
LIMIT 15;
```

This simulates the checklist that a guest sees on a listing details page.

### 16. `listing_house_rule`: rule notes per listing

```sql
SELECT
    l.title AS listing_title,
    hr.name AS rule_name,
    COALESCE(lhr.note, 'no extra note') AS host_note
FROM listing_house_rule lhr
JOIN listing l ON l.listing_id = lhr.listing_id
JOIN house_rule hr ON hr.rule_id = lhr.rule_id
ORDER BY l.title, hr.name
LIMIT 15;
```

This simulates the house-rules section shown to guests before booking.

### 17. `listing_blocked_date`: blocked availability calendar

```sql
SELECT
    l.title AS listing_title,
    lbd.day,
    COALESCE(lbd.reason, 'unspecified') AS reason
FROM listing_blocked_date lbd
JOIN listing l ON l.listing_id = lbd.listing_id
ORDER BY lbd.day, l.title
LIMIT 10;
```

This simulates the host calendar view of blocked dates and their reasons.

## Bookings And Money

### 18. `booking`: recent booking history

```sql
SELECT
    b.booking_id,
    guest.email AS guest_email,
    l.title AS listing_title,
    b.checkin_date,
    b.checkout_date,
    b.guests_count,
    b.status,
    b.total_price,
    b.currency
FROM booking b
JOIN "user" guest ON guest.user_id = b.guest_id
JOIN listing l ON l.listing_id = b.listing_id
ORDER BY b.created_at DESC
LIMIT 10;
```

This simulates a booking-management view for recent reservations.

### 19. `booking_fee`: fee breakdown per reservation

```sql
SELECT
    b.booking_id,
    ft.name AS fee_name,
    bf.amount,
    b.currency
FROM booking_fee bf
JOIN booking b ON b.booking_id = bf.booking_id
JOIN fee_type ft ON ft.fee_type_id = bf.fee_type_id
ORDER BY b.created_at DESC, ft.name
LIMIT 15;
```

This simulates the fee lines a guest sees during checkout and in receipts.

### 20. `payment_transaction`: recent payment activity

```sql
SELECT
    pt.payment_id,
    b.booking_id,
    pt.txn_type,
    pt.method,
    pt.status,
    pt.amount,
    pt.currency,
    pt.occurred_at
FROM payment_transaction pt
JOIN booking b ON b.booking_id = pt.booking_id
ORDER BY pt.occurred_at DESC
LIMIT 10;
```

This simulates a payment-operations feed for booking transactions.

### 21. `payout`: host payouts sent for bookings

```sql
SELECT
    p.payout_id,
    host.email AS host_email,
    b.booking_id,
    p.amount,
    p.currency,
    p.status,
    p.sent_at
FROM payout p
JOIN "user" host ON host.user_id = p.host_id
JOIN booking b ON b.booking_id = p.booking_id
ORDER BY p.sent_at DESC
LIMIT 10;
```

This simulates the payout queue or payout history reviewed by finance staff.

## Messaging And Engagement

### 22. `message_thread`: conversation threads tied to listings

```sql
SELECT
    mt.thread_id,
    l.title AS listing_title,
    mt.booking_id,
    COUNT(m.message_id) AS message_count
FROM message_thread mt
JOIN listing l ON l.listing_id = mt.listing_id
LEFT JOIN message m ON m.thread_id = mt.thread_id
GROUP BY mt.thread_id, l.title, mt.booking_id
ORDER BY message_count DESC, mt.thread_id
LIMIT 10;
```

This simulates an inbox view of listing conversations and their activity levels.

### 23. `message`: recent messages with sender context

```sql
SELECT
    m.message_id,
    sender.email AS sender_email,
    m.thread_id,
    LEFT(m.body, 80) AS message_preview,
    m.sent_at
FROM message m
JOIN "user" sender ON sender.user_id = m.sender_user_id
ORDER BY m.sent_at DESC
LIMIT 10;
```

This simulates the latest message feed shown inside a host or guest inbox.

### 24. `wishlist`: wishlists owned by users

```sql
SELECT
    w.wishlist_id,
    u.email,
    w.name,
    w.created_at,
    COUNT(wi.listing_id) AS saved_listing_count
FROM wishlist w
JOIN "user" u ON u.user_id = w.user_id
LEFT JOIN wishlist_item wi ON wi.wishlist_id = w.wishlist_id
GROUP BY w.wishlist_id, u.email, w.name, w.created_at
ORDER BY saved_listing_count DESC, w.created_at DESC
LIMIT 10;
```

This simulates the wishlists a guest has created and how full they are.

### 25. `wishlist_item`: saved listings inside wishlists

```sql
SELECT
    u.email,
    w.name AS wishlist_name,
    l.title AS listing_title,
    wi.added_at
FROM wishlist_item wi
JOIN wishlist w ON w.wishlist_id = wi.wishlist_id
JOIN "user" u ON u.user_id = w.user_id
JOIN listing l ON l.listing_id = wi.listing_id
ORDER BY wi.added_at DESC
LIMIT 10;
```

This simulates the individual properties a guest has saved to a wishlist.

### 26. `referral`: referral relationships between users

```sql
SELECT
    referrer.email AS referrer_email,
    referee.email AS referee_email,
    r.created_at
FROM referral r
JOIN "user" referrer ON referrer.user_id = r.referrer_user_id
JOIN "user" referee ON referee.user_id = r.referee_user_id
ORDER BY r.created_at DESC
LIMIT 10;
```

This simulates referral-program activity between existing users.

### 27. `review`: recent review feed for completed stays

```sql
SELECT
    l.title AS listing_title,
    reviewer.email AS reviewer_email,
    reviewee.email AS reviewee_email,
    r.rating,
    r.title,
    LEFT(r.body, 100) AS review_preview,
    r.created_at
FROM review r
JOIN booking b ON b.booking_id = r.booking_id
JOIN listing l ON l.listing_id = b.listing_id
JOIN "user" reviewer ON reviewer.user_id = r.reviewer_user_id
JOIN "user" reviewee ON reviewee.user_id = r.reviewee_user_id
ORDER BY r.created_at DESC
LIMIT 10;
```

This simulates the review feed shown on listing and user profile pages.

### 28. `notification`: recent notification feed

```sql
SELECT
    u.email,
    n.type,
    n.payload,
    n.created_at,
    (n.read_at IS NOT NULL) AS is_read
FROM notification n
JOIN "user" u ON u.user_id = n.user_id
ORDER BY n.created_at DESC
LIMIT 10;
```

This simulates the latest notifications shown to users in the app.

## Coverage Map

| Query | Primary Table |
| --- | --- |
| 1 | `user` |
| 2 | `session` |
| 3 | `account` |
| 4 | `verification` |
| 5 | `role` |
| 6 | `user_role` |
| 7 | `user_profile` |
| 8 | `location` |
| 9 | `amenity` |
| 10 | `house_rule` |
| 11 | `fee_type` |
| 12 | `cancellation_policy` |
| 13 | `listing` |
| 14 | `listing_photo` |
| 15 | `listing_amenity` |
| 16 | `listing_house_rule` |
| 17 | `listing_blocked_date` |
| 18 | `booking` |
| 19 | `booking_fee` |
| 20 | `payment_transaction` |
| 21 | `payout` |
| 22 | `message_thread` |
| 23 | `message` |
| 24 | `wishlist` |
| 25 | `wishlist_item` |
| 26 | `referral` |
| 27 | `review` |
| 28 | `notification` |

Every table in the schema now has its own individual, practical query: `user`, `session`, `account`, `verification`, `role`, `user_role`, `user_profile`, `location`, `amenity`, `house_rule`, `fee_type`, `cancellation_policy`, `listing`, `listing_photo`, `listing_amenity`, `listing_house_rule`, `listing_blocked_date`, `booking`, `booking_fee`, `payment_transaction`, `payout`, `message_thread`, `message`, `wishlist`, `wishlist_item`, `referral`, `review`, and `notification`.

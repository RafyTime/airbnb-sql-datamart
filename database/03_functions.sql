-- Airbnb SQL Datamart test query functions
-- Loaded third by Docker Compose from /docker-entrypoint-initdb.d/03_functions.sql
-- Each function returns JSONB rows so different query shapes can share one simple interface.

-- ============================================================
-- Identity And Access
-- ============================================================

-- Query 1: user
-- Use case: Trust And Safety User Directory
CREATE OR REPLACE FUNCTION user_test_query()
RETURNS TABLE (result JSONB)
LANGUAGE sql
STABLE
AS $$
    SELECT to_jsonb(query_result)
    FROM (
        SELECT
            user_id,
            email,
            first_name,
            last_name,
            status,
            (verified_at IS NOT NULL) AS is_verified,
            created_at
        FROM "user"
        ORDER BY created_at DESC
        LIMIT 10
    ) AS query_result;
$$;

-- Query 2: session
-- Use case: Active Device Sessions Dashboard
CREATE OR REPLACE FUNCTION session_test_query()
RETURNS TABLE (result JSONB)
LANGUAGE sql
STABLE
AS $$
    SELECT to_jsonb(query_result)
    FROM (
        SELECT
            s.session_id,
            u.email,
            COALESCE(s.tag, 'unlabeled device') AS device_label,
            s.user_agent,
            s.created_at,
            s.updated_at AS last_seen_at
        FROM session s
        JOIN "user" u ON u.user_id = s.user_id
        WHERE s.revoked_at IS NULL
        ORDER BY s.updated_at DESC, s.created_at DESC
        LIMIT 10
    ) AS query_result;
$$;

-- Query 3: account
-- Use case: Linked Sign-In Methods
CREATE OR REPLACE FUNCTION account_test_query()
RETURNS TABLE (result JSONB)
LANGUAGE sql
STABLE
AS $$
    SELECT to_jsonb(query_result)
    FROM (
        SELECT
            u.email,
            a.provider,
            a.provider_account_id,
            a.expires_at,
            a.created_at
        FROM account a
        JOIN "user" u ON u.user_id = a.user_id
        ORDER BY u.email, a.created_at DESC
        LIMIT 10
    ) AS query_result;
$$;

-- Query 4: verification
-- Use case: Verification Queue Monitoring
CREATE OR REPLACE FUNCTION verification_test_query()
RETURNS TABLE (result JSONB)
LANGUAGE sql
STABLE
AS $$
    SELECT to_jsonb(query_result)
    FROM (
        SELECT
            u.email,
            v.purpose,
            v.expires_at,
            v.consumed_at,
            CASE
                WHEN v.consumed_at IS NOT NULL THEN 'completed'
                WHEN v.expires_at < now() THEN 'expired'
                ELSE 'pending'
            END AS verification_state
        FROM verification v
        JOIN "user" u ON u.user_id = v.user_id
        ORDER BY v.created_at DESC
        LIMIT 10
    ) AS query_result;
$$;

-- Query 5: role
-- Use case: Authorization Role Coverage
CREATE OR REPLACE FUNCTION role_test_query()
RETURNS TABLE (result JSONB)
LANGUAGE sql
STABLE
AS $$
    SELECT to_jsonb(query_result)
    FROM (
        SELECT
            r.name AS role_name,
            COUNT(ur.user_id) FILTER (WHERE ur.revoked_at IS NULL) AS active_user_count,
            COUNT(ur.user_id) FILTER (WHERE ur.revoked_at IS NOT NULL) AS historical_assignment_count
        FROM role r
        LEFT JOIN user_role ur ON ur.role_id = r.role_id
        GROUP BY r.role_id, r.name
        ORDER BY active_user_count DESC, r.name
    ) AS query_result;
$$;

-- Query 6: user_role
-- Use case: Current Access Assignments
CREATE OR REPLACE FUNCTION user_role_test_query()
RETURNS TABLE (result JSONB)
LANGUAGE sql
STABLE
AS $$
    SELECT to_jsonb(query_result)
    FROM (
        SELECT
            u.email,
            r.name AS role_name,
            ur.assigned_at,
            ur.revoked_at,
            (ur.revoked_at IS NULL) AS is_active
        FROM user_role ur
        JOIN "user" u ON u.user_id = ur.user_id
        JOIN role r ON r.role_id = ur.role_id
        ORDER BY ur.assigned_at DESC
        LIMIT 10
    ) AS query_result;
$$;

-- Query 7: user_profile
-- Use case: Profile Readiness Review
CREATE OR REPLACE FUNCTION user_profile_test_query()
RETURNS TABLE (result JSONB)
LANGUAGE sql
STABLE
AS $$
    SELECT to_jsonb(query_result)
    FROM (
        SELECT
            u.email,
            CARDINALITY(up.languages) AS language_count,
            up.settings ->> 'locale' AS locale,
            up.settings ->> 'timezone' AS timezone,
            LENGTH(up.bio) AS bio_length
        FROM user_profile up
        JOIN "user" u ON u.user_id = up.user_id
        ORDER BY language_count DESC, bio_length DESC
        LIMIT 10
    ) AS query_result;
$$;

-- ============================================================
-- Geography And Reference Data
-- ============================================================

-- Query 8: location
-- Use case: Destination Breadcrumb Builder
CREATE OR REPLACE FUNCTION location_test_query()
RETURNS TABLE (result JSONB)
LANGUAGE sql
STABLE
AS $$
    SELECT to_jsonb(query_result)
    FROM (
        WITH RECURSIVE location_path AS (
            SELECT
                l.location_id AS leaf_location_id,
                l.location_id,
                l.name,
                l.type,
                l.parent_location_id,
                0 AS depth
            FROM location l
            WHERE l.type = 'neighborhood'

            UNION ALL

            SELECT
                lp.leaf_location_id,
                parent.location_id,
                parent.name,
                parent.type,
                parent.parent_location_id,
                lp.depth + 1
            FROM location_path lp
            JOIN location parent ON parent.location_id = lp.parent_location_id
        ),
        listing_counts AS (
            SELECT
                location_id,
                COUNT(*) AS listing_count
            FROM listing
            GROUP BY location_id
        )
        SELECT
            lp.leaf_location_id AS location_id,
            STRING_AGG(lp.name, ' -> ' ORDER BY lp.depth DESC) AS full_location_path,
            COALESCE(MAX(lc.listing_count), 0) AS listing_count
        FROM location_path lp
        LEFT JOIN listing_counts lc ON lc.location_id = lp.leaf_location_id
        GROUP BY lp.leaf_location_id
        ORDER BY listing_count DESC, full_location_path
        LIMIT 10
    ) AS query_result;
$$;

-- Query 9: amenity
-- Use case: Guest Filter Popularity Report
CREATE OR REPLACE FUNCTION amenity_test_query()
RETURNS TABLE (result JSONB)
LANGUAGE sql
STABLE
AS $$
    SELECT to_jsonb(query_result)
    FROM (
        SELECT
            a.code,
            a.name,
            a.category,
            COUNT(la.listing_id) AS listings_using_amenity
        FROM amenity a
        LEFT JOIN listing_amenity la ON la.amenity_id = a.amenity_id
        GROUP BY a.amenity_id, a.code, a.name, a.category
        ORDER BY listings_using_amenity DESC, a.name
        LIMIT 10
    ) AS query_result;
$$;

-- Query 10: house_rule
-- Use case: Pre-Booking Rule Adoption
CREATE OR REPLACE FUNCTION house_rule_test_query()
RETURNS TABLE (result JSONB)
LANGUAGE sql
STABLE
AS $$
    SELECT to_jsonb(query_result)
    FROM (
        SELECT
            hr.code,
            hr.name,
            COUNT(lhr.listing_id) AS listings_using_rule,
            COUNT(lhr.note) AS rules_with_custom_note
        FROM house_rule hr
        LEFT JOIN listing_house_rule lhr ON lhr.rule_id = hr.rule_id
        GROUP BY hr.rule_id, hr.code, hr.name
        ORDER BY listings_using_rule DESC, hr.name
        LIMIT 10
    ) AS query_result;
$$;

-- Query 11: fee_type
-- Use case: Checkout Fee Mix Analysis
CREATE OR REPLACE FUNCTION fee_type_test_query()
RETURNS TABLE (result JSONB)
LANGUAGE sql
STABLE
AS $$
    SELECT to_jsonb(query_result)
    FROM (
        SELECT
            ft.code,
            ft.name,
            COUNT(bf.booking_id) AS bookings_with_fee,
            ROUND(COALESCE(AVG(bf.amount), 0), 2) AS average_fee_amount,
            COALESCE(SUM(bf.amount), 0) AS total_fee_amount
        FROM fee_type ft
        LEFT JOIN booking_fee bf ON bf.fee_type_id = ft.fee_type_id
        GROUP BY ft.fee_type_id, ft.code, ft.name
        ORDER BY total_fee_amount DESC, ft.name
        LIMIT 10
    ) AS query_result;
$$;

-- Query 12: cancellation_policy
-- Use case: Policy Adoption And Booking Impact
CREATE OR REPLACE FUNCTION cancellation_policy_test_query()
RETURNS TABLE (result JSONB)
LANGUAGE sql
STABLE
AS $$
    SELECT to_jsonb(query_result)
    FROM (
        SELECT
            cp.code,
            cp.name,
            COUNT(DISTINCT l.listing_id) AS listing_count,
            COUNT(DISTINCT b.booking_id) AS booking_count
        FROM cancellation_policy cp
        LEFT JOIN listing l ON l.policy_id = cp.policy_id
        LEFT JOIN booking b ON b.policy_id = cp.policy_id
        GROUP BY cp.policy_id, cp.code, cp.name
        ORDER BY booking_count DESC, listing_count DESC, cp.name
        LIMIT 10
    ) AS query_result;
$$;

-- ============================================================
-- Listings And Availability
-- ============================================================

-- Query 13: listing
-- Use case: Guest Search Results
CREATE OR REPLACE FUNCTION listing_test_query()
RETURNS TABLE (result JSONB)
LANGUAGE sql
STABLE
AS $$
    SELECT to_jsonb(query_result)
    FROM (
        SELECT
            l.listing_id,
            l.title,
            CONCAT_WS(' -> ', country.name, city.name, neighborhood.name) AS location_path,
            l.property_type,
            l.room_type,
            l.accommodates,
            l.base_price,
            l.currency,
            cover_photo.url AS cover_image_url
        FROM listing l
        JOIN location neighborhood ON neighborhood.location_id = l.location_id
        LEFT JOIN location city ON city.location_id = neighborhood.parent_location_id
        LEFT JOIN location country ON country.location_id = city.parent_location_id
        LEFT JOIN LATERAL (
            SELECT lp.url
            FROM listing_photo lp
            WHERE lp.listing_id = l.listing_id
            ORDER BY lp.is_cover DESC, lp.sort_order ASC, lp.uploaded_at ASC
            LIMIT 1
        ) AS cover_photo ON TRUE
        WHERE l.status = 'active'
        ORDER BY l.base_price ASC, l.created_at DESC
        LIMIT 10
    ) AS query_result;
$$;

-- Query 14: listing_photo
-- Use case: Listing Card Cover Image Audit
CREATE OR REPLACE FUNCTION listing_photo_test_query()
RETURNS TABLE (result JSONB)
LANGUAGE sql
STABLE
AS $$
    SELECT to_jsonb(query_result)
    FROM (
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
        LIMIT 10
    ) AS query_result;
$$;

-- Query 15: listing_amenity
-- Use case: Listing Amenities Checklist
CREATE OR REPLACE FUNCTION listing_amenity_test_query()
RETURNS TABLE (result JSONB)
LANGUAGE sql
STABLE
AS $$
    SELECT to_jsonb(query_result)
    FROM (
        SELECT
            l.title AS listing_title,
            a.name AS amenity_name,
            a.category
        FROM listing_amenity la
        JOIN listing l ON l.listing_id = la.listing_id
        JOIN amenity a ON a.amenity_id = la.amenity_id
        ORDER BY l.title, a.name
        LIMIT 15
    ) AS query_result;
$$;

-- Query 16: listing_house_rule
-- Use case: Pre-Booking Rule Disclosure
CREATE OR REPLACE FUNCTION listing_house_rule_test_query()
RETURNS TABLE (result JSONB)
LANGUAGE sql
STABLE
AS $$
    SELECT to_jsonb(query_result)
    FROM (
        SELECT
            l.title AS listing_title,
            hr.name AS rule_name,
            COALESCE(lhr.note, 'no extra note') AS host_note
        FROM listing_house_rule lhr
        JOIN listing l ON l.listing_id = lhr.listing_id
        JOIN house_rule hr ON hr.rule_id = lhr.rule_id
        ORDER BY l.title, hr.name
        LIMIT 15
    ) AS query_result;
$$;

-- Query 17: listing_blocked_date
-- Use case: Host Calendar Availability Control
CREATE OR REPLACE FUNCTION listing_blocked_date_test_query()
RETURNS TABLE (result JSONB)
LANGUAGE sql
STABLE
AS $$
    SELECT to_jsonb(query_result)
    FROM (
        SELECT
            l.title AS listing_title,
            lbd.day,
            COALESCE(lbd.reason, 'unspecified') AS reason
        FROM listing_blocked_date lbd
        JOIN listing l ON l.listing_id = lbd.listing_id
        ORDER BY lbd.day, l.title
        LIMIT 10
    ) AS query_result;
$$;

-- ============================================================
-- Bookings And Payments
-- ============================================================

-- Query 18: booking
-- Use case: Guest Trip Summary
CREATE OR REPLACE FUNCTION booking_test_query()
RETURNS TABLE (result JSONB)
LANGUAGE sql
STABLE
AS $$
    SELECT to_jsonb(query_result)
    FROM (
        WITH payment_rollup AS (
            SELECT
                booking_id,
                SUM(CASE WHEN txn_type = 'payment' AND status = 'succeeded' THEN amount ELSE 0 END) AS paid_amount,
                MAX(CASE WHEN txn_type = 'payment' THEN status END) AS latest_payment_status,
                MAX(occurred_at) AS last_payment_at
            FROM payment_transaction
            GROUP BY booking_id
        )
        SELECT
            b.booking_id,
            guest.email AS guest_email,
            l.title AS listing_title,
            b.checkin_date,
            b.checkout_date,
            (b.checkout_date - b.checkin_date) AS nights,
            b.guests_count,
            b.status,
            b.total_price,
            COALESCE(pr.paid_amount, 0) AS paid_amount,
            COALESCE(pr.latest_payment_status, 'no payment yet') AS payment_status,
            pr.last_payment_at
        FROM booking b
        JOIN "user" guest ON guest.user_id = b.guest_id
        JOIN listing l ON l.listing_id = b.listing_id
        LEFT JOIN payment_rollup pr ON pr.booking_id = b.booking_id
        ORDER BY b.checkin_date DESC, b.created_at DESC
        LIMIT 10
    ) AS query_result;
$$;

-- Query 19: booking_fee
-- Use case: Booking Receipt Fee Breakdown
CREATE OR REPLACE FUNCTION booking_fee_test_query()
RETURNS TABLE (result JSONB)
LANGUAGE sql
STABLE
AS $$
    SELECT to_jsonb(query_result)
    FROM (
        SELECT
            b.booking_id,
            ft.name AS fee_name,
            bf.amount,
            b.currency
        FROM booking_fee bf
        JOIN booking b ON b.booking_id = bf.booking_id
        JOIN fee_type ft ON ft.fee_type_id = bf.fee_type_id
        ORDER BY b.created_at DESC, ft.name
        LIMIT 15
    ) AS query_result;
$$;

-- Query 20: payment_transaction
-- Use case: Reservation Payment Timeline
CREATE OR REPLACE FUNCTION payment_transaction_test_query()
RETURNS TABLE (result JSONB)
LANGUAGE sql
STABLE
AS $$
    SELECT to_jsonb(query_result)
    FROM (
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
        LIMIT 10
    ) AS query_result;
$$;

-- Query 21: payout
-- Use case: Host Financial Ledger
CREATE OR REPLACE FUNCTION payout_test_query()
RETURNS TABLE (result JSONB)
LANGUAGE sql
STABLE
AS $$
    SELECT to_jsonb(query_result)
    FROM (
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
        LIMIT 10
    ) AS query_result;
$$;

-- ============================================================
-- Messaging And Engagement
-- ============================================================

-- Query 22: message_thread
-- Use case: Reservation Conversation Inbox
CREATE OR REPLACE FUNCTION message_thread_test_query()
RETURNS TABLE (result JSONB)
LANGUAGE sql
STABLE
AS $$
    SELECT to_jsonb(query_result)
    FROM (
        SELECT
            mt.thread_id,
            l.title AS listing_title,
            mt.booking_id,
            COUNT(m.message_id) AS message_count,
            MAX(m.sent_at) AS last_message_at
        FROM message_thread mt
        JOIN listing l ON l.listing_id = mt.listing_id
        LEFT JOIN message m ON m.thread_id = mt.thread_id
        GROUP BY mt.thread_id, l.title, mt.booking_id
        ORDER BY last_message_at DESC NULLS LAST, message_count DESC
        LIMIT 10
    ) AS query_result;
$$;

-- Query 23: message
-- Use case: Conversation Activity Feed
CREATE OR REPLACE FUNCTION message_test_query()
RETURNS TABLE (result JSONB)
LANGUAGE sql
STABLE
AS $$
    SELECT to_jsonb(query_result)
    FROM (
        SELECT
            m.message_id,
            sender.email AS sender_email,
            m.thread_id,
            LEFT(m.body, 80) AS message_preview,
            m.sent_at
        FROM message m
        JOIN "user" sender ON sender.user_id = m.sender_user_id
        ORDER BY m.sent_at DESC
        LIMIT 10
    ) AS query_result;
$$;

-- Query 24: wishlist
-- Use case: Saved Trip Collections
CREATE OR REPLACE FUNCTION wishlist_test_query()
RETURNS TABLE (result JSONB)
LANGUAGE sql
STABLE
AS $$
    SELECT to_jsonb(query_result)
    FROM (
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
        LIMIT 10
    ) AS query_result;
$$;

-- Query 25: wishlist_item
-- Use case: Wishlist Property Lineup
CREATE OR REPLACE FUNCTION wishlist_item_test_query()
RETURNS TABLE (result JSONB)
LANGUAGE sql
STABLE
AS $$
    SELECT to_jsonb(query_result)
    FROM (
        SELECT
            u.email,
            w.name AS wishlist_name,
            l.title AS listing_title,
            l.base_price,
            l.currency,
            wi.added_at
        FROM wishlist_item wi
        JOIN wishlist w ON w.wishlist_id = wi.wishlist_id
        JOIN "user" u ON u.user_id = w.user_id
        JOIN listing l ON l.listing_id = wi.listing_id
        ORDER BY wi.added_at DESC
        LIMIT 10
    ) AS query_result;
$$;

-- Query 26: referral
-- Use case: Referral Attribution Chain
CREATE OR REPLACE FUNCTION referral_test_query()
RETURNS TABLE (result JSONB)
LANGUAGE sql
STABLE
AS $$
    SELECT to_jsonb(query_result)
    FROM (
        SELECT
            referrer.email AS referrer_email,
            referee.email AS referee_email,
            r.created_at
        FROM referral r
        JOIN "user" referrer ON referrer.user_id = r.referrer_user_id
        JOIN "user" referee ON referee.user_id = r.referee_user_id
        ORDER BY r.created_at DESC
        LIMIT 10
    ) AS query_result;
$$;

-- Query 27: review
-- Use case: Verified Review Feed
CREATE OR REPLACE FUNCTION review_test_query()
RETURNS TABLE (result JSONB)
LANGUAGE sql
STABLE
AS $$
    SELECT to_jsonb(query_result)
    FROM (
        SELECT
            r.review_id,
            reviewer.email AS reviewer_email,
            b.booking_id,
            b.checkin_date,
            b.checkout_date,
            r.rating,
            r.title,
            LEFT(r.body, 100) AS review_preview,
            r.created_at AS reviewed_at
        FROM review r
        JOIN booking b ON b.booking_id = r.booking_id
        JOIN "user" reviewer ON reviewer.user_id = r.reviewer_user_id
        ORDER BY r.created_at DESC
        LIMIT 10
    ) AS query_result;
$$;

-- Query 28: notification
-- Use case: User Activity Center
CREATE OR REPLACE FUNCTION notification_test_query()
RETURNS TABLE (result JSONB)
LANGUAGE sql
STABLE
AS $$
    SELECT to_jsonb(query_result)
    FROM (
        SELECT
            u.email,
            n.type,
            n.payload,
            n.created_at,
            (n.read_at IS NOT NULL) AS is_read
        FROM notification n
        JOIN "user" u ON u.user_id = n.user_id
        ORDER BY n.created_at DESC
        LIMIT 10
    ) AS query_result;
$$;

-- ============================================================
-- Supplementary Analytical Queries
-- ============================================================

-- Query 29: Global Revenue Analytics
-- Use case: Country-Level Revenue Performance
CREATE OR REPLACE FUNCTION global_revenue_test_query()
RETURNS TABLE (result JSONB)
LANGUAGE sql
STABLE
AS $$
    SELECT to_jsonb(query_result)
    FROM (
        WITH booking_financials AS (
            SELECT
                b.booking_id,
                COALESCE(country.name, city.name, neighborhood.name) AS country_name,
                SUM(
                    CASE
                        WHEN pt.txn_type = 'payment' AND pt.status = 'succeeded' THEN pt.amount
                        ELSE 0
                    END
                ) AS total_income,
                MAX(
                    CASE
                        WHEN p.status IN ('sent', 'scheduled') THEN p.amount
                        ELSE 0
                    END
                ) AS host_payout
            FROM booking b
            JOIN listing l ON l.listing_id = b.listing_id
            JOIN location neighborhood ON neighborhood.location_id = l.location_id
            LEFT JOIN location city ON city.location_id = neighborhood.parent_location_id
            LEFT JOIN location country ON country.location_id = city.parent_location_id
            LEFT JOIN payment_transaction pt ON pt.booking_id = b.booking_id
            LEFT JOIN payout p ON p.booking_id = b.booking_id
            GROUP BY
                b.booking_id,
                COALESCE(country.name, city.name, neighborhood.name)
        )
        SELECT
            country_name AS country,
            ROUND(SUM(total_income), 2) AS total_income,
            ROUND(SUM(host_payout), 2) AS total_host_payouts,
            ROUND(SUM(total_income) - SUM(host_payout), 2) AS platform_fees_retained
        FROM booking_financials
        GROUP BY country_name
        ORDER BY total_income DESC, country
    ) AS query_result;
$$;

-- Query 30: Host Leaderboard
-- Use case: Top Host Performance Ranking
CREATE OR REPLACE FUNCTION host_leaderboard_test_query()
RETURNS TABLE (result JSONB)
LANGUAGE sql
STABLE
AS $$
    SELECT to_jsonb(query_result)
    FROM (
        WITH host_payouts AS (
            SELECT
                p.host_id,
                SUM(p.amount) AS total_payout_amount,
                COUNT(*) AS paid_booking_count
            FROM payout p
            WHERE p.status IN ('sent', 'scheduled')
            GROUP BY p.host_id
        ),
        host_ratings AS (
            SELECT
                r.reviewee_user_id AS host_id,
                AVG(r.rating)::NUMERIC(10, 2) AS average_rating,
                COUNT(*) AS review_count
            FROM review r
            JOIN booking b ON b.booking_id = r.booking_id
            JOIN listing l ON l.listing_id = b.listing_id
            WHERE r.reviewee_user_id = l.host_id
            GROUP BY r.reviewee_user_id
        )
        SELECT
            RANK() OVER (
                ORDER BY hp.total_payout_amount DESC, COALESCE(hr.average_rating, 0) DESC
            ) AS host_rank,
            u.email AS host_email,
            hp.paid_booking_count,
            ROUND(hp.total_payout_amount, 2) AS total_payout_amount,
            COALESCE(hr.average_rating, 0) AS average_rating,
            COALESCE(hr.review_count, 0) AS review_count
        FROM host_payouts hp
        JOIN "user" u ON u.user_id = hp.host_id
        LEFT JOIN host_ratings hr ON hr.host_id = hp.host_id
        ORDER BY host_rank, host_email
        LIMIT 10
    ) AS query_result;
$$;

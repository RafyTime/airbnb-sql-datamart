# **Data Dictionary**

|Name|Type|Description|
|:----|:----|:----|
|**user**|||
|user\_id|uuid|Surrogate primary key for the user.|
|email|string|Unique email used for login/identification.|
|first\_name|string|User’s given name.|
|last\_name|string|User’s family name.|
|phone|string?|Optional phone number for contact/verification.|
|status|string|Account state (e.g., active, disabled).|
|verified\_at|timestamp?|When the user verified email/identity.|
|created\_at|timestamp|Row creation timestamp (UTC).|
|updated\_at|timestamp|Last update timestamp (UTC).|
|**session**|||
|session\_id|uuid|Surrogate primary key for a login session.|
|user\_id|uuid|FK to user owning the session.|
|token|string|Session token identifier (hashed if persisted).|
|refresh\_token|string|Token used to renew the session.|
|user\_agent|string?|Client user agent string (browser/app).|
|ip\_hash|string?|Hashed IP for security/auditing.|
|tag|string?|Optional label (e.g., device name).|
|revoked\_at|timestamp|When the session was revoked (if any).|
|created\_at|timestamp|Session creation time.|
|updated\_at|timestamp|Last session update time.|
|**account**|||
|auth\_id|uuid|Surrogate primary key for auth account.|
|user\_id|uuid|FK to user.|
|provider|string|Auth provider (password, google, etc.).|
|provider\_account\_id|string?|Provider-side user/account id.|
|access\_token|string?|Provider access token (if stored).|
|refresh\_token|string?|Provider refresh token (if stored).|
|scope|string?|OAuth scopes granted.|
|expires\_at|timestamp?|Token expiration timestamp.|
|password\_hash|string?|Password hash for local login.|
|created\_at|timestamp|Account record creation time.|
|updated\_at|timestamp|Last update time.|
|**verification**|||
|verif\_id|uuid|Surrogate primary key for verification event.|
|user\_id|uuid|FK to user being verified.|
|purpose|string|Purpose (email, phone, reset, etc.).|
|value|string|Token/code or value to verify.|
|consumed\_at|timestamp?|When the token/value was consumed.|
|expires\_at|timestamp|When the token/value expires.|
|created\_at|timestamp|Creation timestamp.|
|**role**|||
|role\_id|uuid|Surrogate primary key for role.|
|name|string|Unique role name (e.g., admin, host, guest).|
|created\_at|timestamp|Creation timestamp.|
|**user\_role**|||
|user\_id|uuid|FK to user.|
|role\_id|uuid|FK to role.|
|assigned\_at|timestamp|When the role was assigned.|
|revoked\_at|timestamp?|When the role was revoked.|
|**user\_profile**|||
|user\_id|uuid|PK and FK to user (1:1).|
|avatar\_url|string|Profile image URL.|
|bio|text|Short user biography.|
|languages|text\[\]|Languages the user speaks.|
|socials|json|Social links/handles.|
|settings|json|User preferences/settings.|
|**location**|||
|location\_id|uuid|Surrogate primary key for location node.|
|name|string|Location name (e.g., “Paris”, “Île‑de‑France”).|
|type|string|Granularity/type (country, region, city, area).|
|parent\_location\_id|uuid|Parent location id (null for root).|
|**listing**|||
|listing\_id|uuid|Surrogate primary key for listing.|
|host\_id|uuid|FK to user who hosts the listing.|
|location\_id|uuid|FK to location of the listing.|
|policy\_id|uuid|FK to cancellation\_policy in force.|
|title|string|Public title of the listing.|
|description|text|Detailed description of the property.|
|property\_type|string|Property type (apartment, house, etc.).|
|room\_type|string|Room type (entire place, private room, etc.).|
|accommodates|int|Max number of guests.|
|bedrooms|int|Number of bedrooms.|
|beds|int|Number of beds.|
|bathrooms|numeric|Number of bathrooms (supports decimals).|
|address\_line1|string?|Address line 1\.|
|address\_line2|string?|Address line 2\.|
|postal\_code|string?|Postal/ZIP code.|
|lat|decimal(6,9)|Latitude coordinate.|
|lng|decimal(6,9)|Longitude coordinate.|
|base\_price|decimal|Base nightly price.|
|currency|char(3)|ISO‑4217 currency code.|
|status|string|Listing status (draft, active, suspended).|
|created\_at|timestamp|Creation timestamp.|
|updated\_at|timestamp|Last update timestamp.|
|**listing\_photo**|||
|photo\_id|uuid|Surrogate primary key for photo.|
|listing\_id|uuid|FK to listing.|
|url|string|Public URL of the image.|
|caption|string|Optional caption/alt text.|
|is\_cover|bool|Whether this is the cover image.|
|sort\_order|int|Display order among photos.|
|uploaded\_at|timestamp|When the photo was uploaded.|
|**amenity**|||
|amenity\_id|uuid|Surrogate primary key for amenity.|
|code|string|Unique amenity code.|
|name|string|Human‑readable amenity name.|
|category|string|Group/category (e.g., kitchen, safety).|
|**listing\_amenity**|||
|listing\_id|uuid|FK to listing.|
|amenity\_id|uuid|FK to amenity.|
|**house\_rule**|||
|rule\_id|uuid|Surrogate primary key for house rule.|
|code|string|Unique rule code.|
|name|string|Human‑readable rule name.|
|**listing\_house\_rule**|||
|listing\_id|uuid|FK to listing.|
|rule\_id|uuid|FK to house\_rule.|
|note|text?|Optional rule note/clarification.|
|**listing\_blocked\_date**|||
|listing\_id|uuid|FK to listing.|
|day|date|Date blocked (unavailable).|
|reason|text?|Reason for block (maintenance, hold, etc.).|
|**cancellation\_policy**|||
|policy\_id|uuid|Surrogate primary key for policy.|
|code|string|Unique policy code (e.g., FLEX, STRICT).|
|name|string|Human‑readable policy name.|
|rules\_json|json|JSON describing refund rules/tiers.|
|**booking**|||
|booking\_id|uuid|Surrogate primary key for booking.|
|guest\_id|uuid|FK to user who books (guest).|
|listing\_id|uuid|FK to listing booked.|
|policy\_id|uuid|FK to cancellation policy at booking time.|
|checkin\_date|date|Check‑in date.|
|checkout\_date|date|Check‑out date.|
|guests\_count|int|Number of guests in the booking.|
|status|string|Booking state (pending, accepted, cancelled, completed).|
|total\_price|decimal|Computed total price for the stay.|
|currency|char(3)|ISO‑4217 currency of the booking.|
|created\_at|timestamp|Creation timestamp.|
|updated\_at|timestamp|Last update timestamp.|
|**fee\_type**|||
|fee\_type\_id|uuid|Surrogate primary key for fee type.|
|code|string|Unique fee code.|
|name|string|Fee name (e.g., cleaning, service).|
|**booking\_fee**|||
|booking\_id|uuid|FK to booking.|
|fee\_type\_id|uuid|FK to fee\_type.|
|amount|decimal|Fee amount applied to the booking.|
|**payment\_transaction**|||
|payment\_id|uuid|Surrogate primary key for payment event.|
|booking\_id|uuid|FK to related booking.|
|txn\_type|string|Type (payment, refund, chargeback).|
|amount|decimal|Transaction amount (positive).|
|currency|char(3)|ISO‑4217 currency code.|
|method|string|Payment method (card, wallet, etc.).|
|status|string|Processing status (pending, succeeded, failed).|
|occurred\_at|timestamp|When the transaction occurred.|
|updated\_at|timestamp|Last update timestamp.|
|**payout**|||
|payout\_id|uuid|Surrogate primary key for payout.|
|booking\_id|uuid|FK to booking (unique per booking).|
|host\_id|uuid|FK to host user receiving payout.|
|amount|decimal|Payout amount to host.|
|currency|char(3)|Currency of the payout.|
|status|string|Payout status (scheduled, sent, failed).|
|sent\_at|timestamp|When the payout was sent.|
|**wishlist**|||
|wishlist\_id|uuid|Surrogate primary key for wishlist.|
|user\_id|uuid|FK to user owning the wishlist.|
|name|string|Wishlist name.|
|created\_at|timestamp|Creation timestamp.|
|updated\_at|timestamp|Last update timestamp.|
|**wishlist\_item**|||
|wishlist\_id|uuid|FK to wishlist.|
|listing\_id|uuid|FK to listing.|
|added\_at|timestamp|When the listing was added.|
|**message\_thread**|||
|thread\_id|uuid|Surrogate primary key for thread.|
|listing\_id|uuid|FK to listing context.|
|booking\_id|uuid?|Optional FK to booking (if post‑booking).|
|**message**|||
|message\_id|uuid|Surrogate primary key for message.|
|thread\_id|uuid|FK to message\_thread.|
|sender\_user\_id|uuid|FK to user who sent the message.|
|body|text|Message content.|
|sent\_at|timestamp|When the message was sent.|
|**referral**|||
|referral\_id|uuid|Surrogate primary key for referral.|
|referrer\_user\_id|uuid|FK to user who invited.|
|referee\_user\_id|uuid|FK to invited user.|
|created\_at|timestamp|When the referral was created.|
|**review**|||
|review\_id|uuid|Surrogate primary key for review.|
|booking\_id|uuid|FK to booking being reviewed.|
|reviewer\_user\_id|uuid|FK to user authoring the review.|
|reviewee\_user\_id|uuid|FK to user receiving the review.|
|rating|smallint|Integer rating score.|
|title|string|Short review title.|
|body|text|Review text body.|
|created\_at|timestamp|When the review was created.|
|**notification**|||
|notification\_id|uuid|Surrogate primary key for notification.|
|user\_id|uuid|FK to user to notify.|
|type|string|Notification type/category.|
|payload|json|Payload with event‑specific details.|
|created\_at|timestamp|Creation time of the notification.|
|read\_at|timestamp?|When the notification was read.|

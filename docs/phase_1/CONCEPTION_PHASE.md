# **Portfolio Project — Phase 1**

## **Abstract**

**Problem.** The task is to design and implement a relational database that supports Airbnb's accommodation booking use case. The database should enable core features such as user accounts, listings, bookings, and payments while remaining normalized, consistent, and practical for demonstration.

**Solution Approach.** The database design will focus on guest, host, and admin roles and their interactions: creating and searching listings, managing availability, handling bookings, processing payments and payouts, and enabling communication and reviews. The design prioritizes essential MVP functionality to keep the scope realistic while allowing for future enhancements. The ER model includes over 20 entities with normalized relationships and constraints, providing a robust base for SQL implementation and testing.

## **Requirements Specification**

### **Purpose & Scope**

This project delivers the database backbone for a lean Airbnb-style platform. In this platform guests should be able to discover and book places to stay, hosts publish and manage their properties, and admins should oversee system operations, keeping everything healthy and fair. The scope targets a realistic, working MVP database that demonstrates all core flows and use cases: solid identity and roles, listings with clean location modeling, a simple but safe availability model, bookings, itemized pricing, payments and payouts, basic cancellation policies, lightweight messaging and reviews, and a couple of value-add features (wishlists, referrals). Advanced pricing, disputes, and KYC are out-of-scope for this MVP.

### **Roles & Responsibilities**

* **Guest:** Travelers seeking accommodation reliably and conveniently. They register accounts, search for available listings, make bookings, submit payments, and leave reviews. Their benefit is convenient, transparent, and secure access to short-term stays.  
* **Host:** The accommodation provider or manager. They create and manage listings with photos, amenities, and rules, handle availability, accept bookings and receive payouts. The value to a host is visibility and exposure, streamlined property management and simplified monetization.  
* **Admin:** The platform steward who ensures smooth platform operations. Beyond read access, admins manage disputes, enforce cancellation policies, monitor fraudulent activity, and adjust fees or platform rules. Their task is ensuring trust, fairness, and compliance for all participants.

### **Requirements (Use Cases)**

1. **Authentication & Accounts.** Users register via password or OAuth, maintain sessions, and verify contact details.  
2. **Listings.** Hosts publish and manage listings with property details, photos, amenities, and rules. Under Admin supervision & approval.  
3. **Location & Search.** Guests browse listings by location, and filter by price, dates, and amenities.  
4. **Availability.** Hosts manage availability dates; guests see booked or blocked dates.  
5. **Bookings.** Guests request/confirm bookings; hosts accept/decline; states flow from pending → accepted/declined → cancelled/completed. Overlaps are prevented.  
6. **Payments & Payouts.** Guests pay, with optional service/cleaning fees; hosts receive payouts post-check-in; refunds can be modeled on the payment transaction type.  
7. **Pricing.** Listings define base price and optional fees (cleaning, service) with a currency; the booking stores the computed total  
8. **Cancellation Policies.** Standardized policies define refund rules for guest/host-initiated cancellations, monitored by admins.  
9. **Wishlists.** Guests can save listings to personal collections.  
10. **Reviews.** Guests and hosts leave one review each per booking, covering rating and text.  
11. **Messaging.** Guests and hosts communicate via message threads tied to listings or bookings; enough for pre-booking questions and coordination.  
12. **Notifications.** Users receive alerts about bookings, cancellations, or messages.  
13. **Profiles.** Users enrich profiles with a photo, a bio, languages, and optional social links.  
14. **Referrals.** Users invite others and track referrals. The relationship is recorded for credits/recognition.

### **Data & Functions Required**

The system must support identity management, role assignments, listings, and related metadata, booking transactions, payments and payouts, cancellation policies, wishlists, reviews, messaging, notifications, and referrals. Core functions include enforcing booking availability, preventing duplicate reviews, maintaining referential integrity, enabling queries such as searching by city, calculating booking totals, and hosting payout reporting.

### **Assumptions, Constraints & Technical Considerations**

* **Users** can be both **Guests** and **Hosts**; A single **User** table stores all individuals, with roles managed via a **Role/UserRole** mapping.  
* **Locations** are normalized hierarchically to reduce duplication.  
* **Bookings** enforce date rules (checkin \< checkout) to avoid overlaps.  
* **Payments** and **payouts** are separate entities; One table for all payment events: payment\_transaction with txn\_type (payment, refund, chargeback) and positive amounts;  
* **Reviews** are limited to one per party per booking, and **Ratings** are integers.  
* **Auth** tokens and other sensitive values (passwords, refresh\_tokens) are stored encrypted.  
* **Naming conventions:** snake\_case for identifiers; singular table names; surrogate UUIDs (or serial IDs where practical); composite PKs for bridge tables. created\_at/updated\_at on mutable tables.  
* **Data types:** Monetary as DECIMAL(12,2); timestamps in UTC; currencies in ISO-4217 CHAR(3).  
* **Normalization.** Aim for 3NF. Keep computed booking.total\_price for performance, with itemized booking\_fee rows for transparency.

### **Entity Relationship Model Diagram**

![Entity Relationship Model Diagram](/docs/phase_1/ENTITY_RELATIONSHIP_DIAGRAM.svg)

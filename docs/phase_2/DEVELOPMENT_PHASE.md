# **Portfolio Project — Phase 2**

## **Overview**

This phase focused on turning the conceptual database design from phase 1 into a working PostgreSQL implementation for an Airbnb-style platform. The main objective was to preserve the original use cases, assumptions, and normalization decisions while translating them into SQL tables, relationships, constraints, and testable data. The result is a structured database implementation that supports realistic platform workflows such as account management, listing publication, booking, payments, messaging, reviews, and reporting.

## Implementation

### **Backbone & Infrastructure**

The database was implemented in PostgreSQL 18.3. To keep the setup simple, portable, and reproducible, Docker and Docker Compose were used to run both the PostgreSQL instance and a pgAdmin instance. This made the environment easier to manage across different machines without depending on local installations or conflicting configurations. These decisions supported the development process, but remained secondary to the SQL implementation itself.

### **Schema Implementation**

The schema implementation stayed closely aligned with the conception from phase 1. Since the ER model and the data dictionary had already been developed in a clear and consistent way, the translation into SQL did not require major structural changes. The tables were grouped by functionality and created in dependency order, which made it easier to preserve relationships and keep the implementation organized. In this way, the structure defined in the conception phase was carried over directly into development instead of being redesigned during implementation.

The realistic use cases defined in phase 1 were also reflected in the final schema. Identity and access management were implemented through a central `user` table together with `role`, `user_role`, `session`, `account`, and `verification`. Listing publication and search were represented through listing, photo, amenity, house-rule, and location tables. Availability, bookings, pricing, payments, payouts, messaging, reviews, notifications, wishlists, and referrals were implemented as separate but connected parts of the same system. This preserved the original idea of a realistic MVP database that supports the most important Airbnb-style workflows without expanding into less essential features.

The assumptions, constraints, and technical considerations from phase 1 were also carried into the final SQL implementation. A single `user` entity was used for all persons in the system, reflecting the idea that one individual can hold multiple platform roles. Locations were normalized hierarchically to reduce repetition and support cleaner location-based queries. Bookings enforce date rules such as `checkin_date < checkout_date`, payment transactions store only positive amounts, and reviews are constrained by rating ranges and uniqueness rules. The planned separation between guest payments and host payouts was maintained, and the pricing model combines a stored `booking.total_price` with itemized `booking_fee` rows for transparency. PostgreSQL-specific decisions such as UUID primary keys, JSONB columns, array types, snake_case naming, timestamps, ISO currency codes, `UNIQUE` constraints, `CHECK` constraints, and supporting indexes helped turn the conceptual model into a robust relational implementation.

### **Seeding & Data Decisions**

To populate the schema with test data, a Python seeding script was used. The script was managed with Astral's UV for lightweight project and package management and used Faker together with psycopg to insert data directly into the running PostgreSQL database. A fixed seed was used so that the generated data remained consistent across executions. After seeding the live database, a SQL snapshot was also exported into `database/seeds/seeds.sql` through `pg_dump`, which made it easier to preserve and reuse the populated state of the system.

The seeded data was designed to balance realism with the formal project requirements. Each entity received at least 20 rows, even when some entries were not equally relevant for the minimal version of the platform. This was especially visible in areas such as roles, where some generated values exist mainly to satisfy the required 20 entries per table rule. Even so, the overall aim was still to make the dataset feel plausible and usable. For that reason, the seeding strategy included variation inspired by both Germany and Colombia, with corresponding differences in names, locations, and currencies.

### **Test Query Implementation**

The implementation of the test queries required more iteration than the schema itself. The goal was not simply to prove that rows existed or that foreign keys worked, but to create queries that demonstrated recognizable and practical use cases for an Airbnb-style platform. Because of this, the final query set focuses on workflows such as user and role management, listing discovery, availability control, booking and payment handling, messaging, reviews, wishlists, and analytical reporting.

This part of the work involved some trial and error, because useful queries had to be both technically correct and meaningful in context. In the end, the test cases became an important part of the implementation, since they showed that the database was not only structurally valid but also capable of supporting the kind of operations and reporting that such a platform would realistically require.

## **Reflection**

Looking back, the actual implementation of the schema was less difficult than expected because the design work in phase 1 had already created a strong foundation. The more demanding part of this phase was deciding how to seed the database in a realistic way and how to design test queries that demonstrated functionality rather than only database connectivity. That balance between academic requirements and practical realism required the most revision and thought during development.

Overall, this phase confirmed that the conceptual choices made in phase 1 were sound. A well-structured and normalized design made the transition into SQL implementation much more straightforward, while still leaving room for realistic data generation and practical validation. For that reason, the development phase was not only an execution of the original design, but also a useful reflection on how conceptual database decisions hold up when they are implemented, populated, and tested in a real system.

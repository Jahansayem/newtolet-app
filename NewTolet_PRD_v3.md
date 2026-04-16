# New Tolet

**www.newtolet.com**

## Product Requirements Document

**House Rental Platform + MLM Employee Management**
**Bangladesh Nationwide | Cross-Platform Mobile App (Flutter)**
**Version 2.0 | March 2026 | Draft**

---

## 1. What is New Tolet?

New Tolet is a house rental app for Bangladesh. It helps tenants find homes and helps landlords find tenants — without any broker.

The app covers all types of rental: family homes, bachelor rooms, sublets, hostels, mess, office spaces, and shops. It works across all 8 divisions of Bangladesh.

What makes New Tolet different is its employee system. Employees (agents) go out, collect rental listings, and bring new members into the platform. They earn points for this work, and those points turn into real money (USD), which can be withdrawn in BDT.

The employee system follows an MLM (multi-level marketing) structure. When you bring someone in, and they bring someone in, you earn from their work too. This is modeled after the Tiens VShare app.

---

## 2. User Roles & Permissions

| Role | Can Do | Registration |
|------|--------|--------------|
| Tenant | Browse, search, save favorites, contact landlords, pay advance, rate & review | Phone OTP |
| Landlord | View listing status, respond to tenant inquiries, receive advance payments | Phone OTP + NID verification |
| Agent/Employee | All Tenant abilities + Add listings, invite members, earn points, access MLM dashboard | Referral link + Phone OTP |
| Admin | Approve/reject listings, process payouts, manage disputes, view analytics, set exchange rates | Backend panel login |

- A user can be both a Tenant and an Agent simultaneously.
- Landlords cannot post listings directly — all listings are submitted by agents after field verification.
- Agents must complete their first listing before accessing withdrawal features.

---

## 3. How Employees Earn Points

There are two main ways to earn points:

| Action | Points | When |
|--------|--------|------|
| Add a rental listing | 100 | Each time a listing is verified and goes live |
| Invite a new member | 150 | When the invited person registers and does their first action |

There are also bonus points:

| Bonus | Points | When |
|-------|--------|------|
| First listing bonus | 50 | One time — when you add your very first listing |
| Weekly active bonus | 25 | Every week you complete at least **7 listings AND 1 invite** |
| Listing quality bonus | 30 | When your listing has 5+ photos and full details |
| Team milestone (10 members) | 200 | One time — when your team hits 10 people |
| Team milestone (25 members) | 500 | One time |
| Team milestone (50 members) | 1,000 | One time |
| Team milestone (100 members) | 2,500 | One time |

### 3.1 Point Volume Types

The system tracks different types of point volumes. These are used to decide bonuses and rank:

| Short Name | Full Name | What It Means |
|------------|-----------|---------------|
| PPV | Personal Point Volume | Points you earned yourself |
| GPV | Group Point Volume | Points your whole team earned |
| TNPV | Total Network Point Volume | Your PPV + your team's GPV combined |
| ATNPV | Accumulated TNPV | Your total TNPV across all time |
| PBV | Personal Business Volume | USD business value from your own listings (1 listing = $1.00 PBV) |
| TNBV | Total Network Business Volume | USD business value from your full network |

### 3.2 Currency & Points System

All points, bonuses, and internal balances are denominated in **USD ($)**.

| Item | Detail |
|------|--------|
| Internal currency | USD ($) |
| Points to USD conversion | **1 point = $0.01 USD** (100 points = $1.00) |
| Withdrawal currency | BDT (৳) — converted at time of withdrawal |
| Exchange rate source | Admin-set rate, updated weekly (e.g., 1 USD = 120 BDT) |
| Rate lock | Locked at the moment the agent confirms the withdrawal request |
| In-app display | Balance shown in both USD and BDT equivalent |

### 3.3 How to Use Points

- Cash out to bKash, Nagad, or Rocket (paid in BDT)
- Get mobile recharge or data packs
- Use as platform credits for premium listing features
- Minimum **$5.00 USD** (500 points) to cash out
- Bank transfer available for amounts above $50.00 USD

### 3.4 Point Expiration

- Points expire after **12 months** of account inactivity (no listings, no invites, no logins).
- Active agents never lose points.
- 30-day warning notification before expiration.

---

## 4. Team Structure (MLM)

Every employee has a team tree. When you invite someone, they sit under you. When they invite someone, that person sits under them. This creates a tree-like structure.

### 4.1 Two Types of Network

- **Sponsor Network:** Shows who invited whom. This is the referral chain. You see PPV, GPV, TNPV for each person.
- **Placement Network:** Shows the organizational structure. Used for bonus calculations. You see PBV, TNBV, APBV for each person.

**Placement rules:**
- By default, placement follows the sponsor tree (new member is placed directly under their inviter).
- Sponsors can manually place a new member under any existing member in their downline within 7 days of registration.
- After 7 days, placement is locked and cannot be changed.
- Tree width: **Unlimited** — no cap on direct placements.

### 4.2 Star Levels

As you earn more points and grow your team, you move up in star level. Higher star = higher bonus percentages.

| Level | PPV Needed | Team Size | Direct Bonus | Indirect Bonus |
|-------|-----------|-----------|--------------|----------------|
| None (New) | 0 | 0 | 0% | 0% |
| Star 1 | 200 | 2+ | 5% | 0% |
| Star 2 | 500 | 5+ | 7% | 2% |
| Star 3 | 1,000 | 10+ | 10% | 3% |
| Star 4 | 2,500 | 25+ | 12% | 5% |
| Star 5 | 5,000 | 50+ | 15% | 7% |
| Star 6 | 10,000 | 100+ | 18% | 10% |
| Star 7 | 25,000 | 250+ | 20% | 12% |
| Star 8 | 50,000 | 500+ | 25% | 15% |

**Bonus base:** Percentages are applied to the **USD value of points earned** within the calculation period.
- Direct Bonus = Your star level % × your own PPV (in USD)
- Indirect Bonus = Your star level % × your direct downline's GPV (in USD)

Star 4 and above also get a **Leadership Bonus** from deep team performance (see Section 5.1).

### 4.3 Honorary Levels

After Star 8, top performers unlock special titles with extra rewards:

| Level | Extra Requirement | Special Perk |
|-------|-------------------|--------------|
| Bronze Lion | 100K ATNPV | 2% global pool share |
| Silver Lion | 250K ATNPV | 3% pool + mentorship |
| Golden Lion | 500K ATNPV | 5% pool + VIP status |
| 1–5 Star Golden Lion | 1M–25M ATNPV | 6–10% pool + travel/vehicle/housing rewards |
| Director | 50M ATNPV | 12% pool + board advisory |
| Honorary Director | 100M ATNPV | Maximum benefits |

---

## 5. Bonus System

### 5.1 Types of Bonuses

- **Direct Bonus:** You earn this from your own work (listings and invites). Percentage based on your star level × your PPV in USD.
- **Indirect Bonus:** You earn this when your direct team members do work. Percentage based on your star level × their GPV in USD.
- **Leadership Bonus:** For Star 4 and above. Earned from deep team activity up to **5 levels deep**:
  - Level 1 (direct): Included in Indirect Bonus
  - Level 2: 3% of their GPV
  - Level 3: 2% of their GPV
  - Level 4: 1% of their GPV
  - Level 5: 0.5% of their GPV
- **Honor Bonus:** Quarterly reward for honorary-level members from a shared pool. Pool = **5% of total platform commission revenue** for the quarter.

### 5.2 When Bonuses Are Paid

| Type | Period | Paid On | Currency |
|------|--------|---------|----------|
| Monthly Bonus | Calendar month | 5th of next month | BDT via bKash/Nagad/Rocket |
| Weekly Bonus | Saturday to Friday | Next Tuesday | BDT via bKash/Nagad/Rocket |
| Honor Bonus | Every 3 months | 15th of quarter-end month | BDT via bank transfer |

All bonuses are calculated in USD and paid in BDT at the admin-set exchange rate on the payout date.

### 5.3 Staying Active

To keep earning bonuses, employees must stay active. The system checks activity each month.

| Status | Requirement | Bonus Impact |
|--------|------------|--------------|
| **Active (Green)** | 20+ listings AND 4+ invites per month | Full bonuses (100%) |
| **Common (Blue)** | 10–19 listings OR 2–3 invites per month | Reduced bonuses (50%) |
| **Low Active (Red)** | Fewer than 10 listings AND fewer than 2 invites | Bonuses paused until active again |

- Status is evaluated on the 1st of each month based on previous month's activity.
- New agents get a **30-day grace period** — counted as Active regardless of output.
- Agents receive a push notification on the 20th if they're trending toward Low Active.

---

## 6. Referral Tree in Profile

Every agent can view their **full referral tree** from the **My Center** tab under **"My Referral Tree"**.

### 6.1 Referral Tree View

The tree shows the agent's complete downline hierarchy with real-time activity status.

**Tree node for each member displays:**
- Profile photo and name
- Star level badge (Star 1–8 or Honorary icon)
- Activity status indicator:
  - 🟢 Green dot = Active (working this month)
  - 🔵 Blue dot = Common (partially active)
  - 🔴 Red dot = Low Active / Inactive
- Listings this month (count)
- Invites this month (count)
- Join date

**Tree interaction:**
- Tap any node to expand and see their downline
- Tap a member's name to view their mini-profile:
  - Total listings contributed
  - Total invites
  - Current star level
  - PPV this month
  - Days since last activity
- Search by name within the tree
- Filter tree by: All | Active only | Inactive only | By star level
- Collapse/expand branches

### 6.2 Tree Tabs

| Tab | What It Shows |
|-----|---------------|
| **Sponsor Tree** | Who invited whom — the referral chain. Shows PPV, GPV, TNPV per member. |
| **Placement Tree** | Organizational structure used for bonus calculations. Shows PBV, TNBV, APBV per member. |

### 6.3 Tree Summary Header

At the top of the referral tree screen, a summary bar shows:

| Metric | Description |
|--------|-------------|
| Total Team Size | Number of people in your full downline |
| Active Members | Count and % of members who are Green status |
| This Month's Team GPV | Combined points earned by your whole team this month |
| New Joins This Month | Members who registered this month through your network |

---

## 7. Rental Marketplace

### 7.1 What Can Be Listed

| Category | Example |
|----------|---------|
| Family Home | 2-bedroom flat for a family in Dhanmondi |
| Bachelor | Single room or seat for a student in Mirpur |
| Sublet | Shared flat, one room available in Uttara |
| Hostel / Mess | Hostel seat near a university |
| Office Space | Commercial office room in Motijheel |
| Shop | Retail shop space in a local market |

### 7.2 Adding a Listing

When an employee adds a listing, they fill in:

- Category (family, bachelor, sublet, etc.)
- Title and description (Bangla or English)
- Photos (up to 10)
- Monthly rent in BDT (৳)
- Location: Division > District > Thana > Area
- Property details: rooms, bathrooms, floor, size
- Amenities: gas, water, lift, parking, generator, etc.
- Availability date and advance amount
- Landlord contact info (hidden until user registers)

### 7.3 Listing Moderation Workflow

| Step | Action | Timeline |
|------|--------|----------|
| 1. Submit | Agent submits listing via app | Instant |
| 2. Auto-check | System checks for duplicates (address + photos), required fields, image quality | Instant |
| 3. Queue | Listing enters admin review queue | — |
| 4. Review | Admin verifies photos, description accuracy, GPS location match | Within 24 hours |
| 5a. Approve | Listing goes live, agent gets 100 points | Notification sent |
| 5b. Reject | Agent gets rejection reason, can edit and resubmit | Notification sent |

**Duplicate detection:** If a listing's GPS coordinates are within 50m of an existing active listing AND the category matches, it's flagged for manual review.

### 7.4 Listing Lifecycle

| State | Description | Duration |
|-------|-------------|----------|
| Draft | Agent started but didn't submit (offline drafts included) | Until submitted |
| Pending Review | Submitted, awaiting admin approval | Max 24 hours |
| Active | Live and visible to tenants | 60 days or until rented |
| Rented | Marked as rented by agent or landlord | Archived after 7 days |
| Expired | 60 days passed without renewal | Auto-archived |
| Rejected | Admin rejected, editable by agent | 14 days to resubmit |

- Agents receive a notification 7 days before a listing expires.
- Agents can renew an active listing for another 60 days (earns no additional points).
- If an agent leaves the platform, their active listings are transferred to their sponsor (upline).

### 7.5 Finding a Rental

- Browse by division, district, thana, and area
- Filter by price, category, bedrooms, and date
- Search in Bangla or English
- See listings on a map (clustered pins by category, radius search)
- Save favorites and get alerts for new matches

### 7.6 Contacting & Booking

- See full details, photos, and map location
- Contact landlord through in-app chat or phone (registered users only)
- Share listing via WhatsApp, Messenger, or SMS
- Pay advance through bKash, Nagad, or Rocket
- Rate and review after renting

**Advance Payment Flow:**
1. Tenant initiates advance payment through the app
2. Payment goes to **NewTolet escrow wallet** (not directly to landlord)
3. Landlord confirms tenant visit/agreement within 48 hours
4. On confirmation, funds are released to landlord (minus platform commission)
5. If landlord doesn't confirm within 48 hours, tenant can request a full refund
6. Disputes are handled by admin within 72 hours

---

## 8. App Screens Overview

### 8.1 Bottom Navigation (5 Tabs)

| Tab | What It Does |
|-----|--------------|
| Home | Browse and search rental listings |
| Training | Learn: courses, tips, live sessions |
| Message | Chat and notifications |
| Member | MLM dashboard and all business tools |
| My Center | Profile, my listings, **my referral tree**, orders, settings |

### 8.2 My Center Tab (Profile Hub)

| Section | What It Shows |
|---------|---------------|
| Profile Header | Photo, name, star level badge, referral code, USD balance + BDT equivalent |
| My Referral Tree | Full tree view with activity status (see Section 6) |
| My Listings | All listings with status (Active/Pending/Expired/Rented) |
| My Earnings | Points history, bonus breakdown, withdrawal history |
| My Invites | Pending invites, registered invites, conversion rate |
| Withdrawal | Cash out to bKash/Nagad/Rocket in BDT |
| Settings | Language, notifications, data saver, account |

### 8.3 Member Tab (MLM Hub)

This is the main screen for the MLM side. It has two sections:

- **Quick Tools:** Team, Leg (Real-Time), My Performance, Active Status, Distributor Analysis, Level Analysis, Performance Analysis
- **All Tools:** Everything above plus My Bonus, Honor Bonus, Renewal, Upgrade Assistant

### 8.4 Key MLM Screens

| Screen | What It Shows |
|--------|---------------|
| My Team | Tree view of your network (Sponsor tab + Placement tab) with activity indicators |
| Performance Analysis | Bar chart of TNPV over 6 months with comparison table (in USD) |
| Level Analysis | Funnel chart showing team distribution by star level |
| Distributor Analysis | How many of your team are active vs inactive (pie chart + list) |
| Upgrade Assistant | What you need to do to reach the next star level (progress bars) |
| Leg (Real-Time) | Live TNBV breakdown by each leg of your tree (in USD) |
| Bonus Center | Monthly and weekly bonus amounts in USD with BDT equivalent, history |
| Active Qualification | Your qualification status for each bonus type |
| Renewal | Which team members need to re-verify or have been inactive 30+ days |

### 8.5 Invite Screen

- Get your unique referral link and QR code
- Share through WhatsApp, Messenger, SMS, Facebook
- Track: who registered, who is still pending, who completed first action
- Get 150 points when they complete registration and first action

### 8.6 Training Center

- Video courses and tips for agents
- Business tools and sales techniques
- Live training sessions (schedule + notifications)
- Content in Bangla and English
- Completion tracking per agent (admin-visible)

### 8.7 Chat System

| Feature | Detail |
|---------|--------|
| Type | 1:1 messaging between tenant and landlord (agent-facilitated) |
| Media | Photo and location sharing supported |
| Persistence | Messages stored for 90 days |
| Notifications | Push notification for new messages |
| Moderation | Report/block functionality |

---

## 9. Bangladesh-Specific Details

### 9.1 Location System

The app uses Bangladesh's full address structure: 8 Divisions > 64 Districts > 495+ Thanas > Local Areas. Users can also search by landmark (like "near Bashundhara R/A").

### 9.2 Payments

- **bKash** — main payment method for withdrawals and transactions
- **Nagad** and **Rocket** as alternatives
- **Bank transfer** for large amounts (above $50 USD equivalent)
- All prices displayed in BDT (৳) for listings
- Agent balances displayed in USD ($) with BDT equivalent

### 9.3 Language

- Full Bangla and English support
- User can switch language in settings
- SMS OTP in Bangla

### 9.4 Works on Low Internet

- Offline draft mode — create listings without internet, sync later
- Small app size (under 30 MB)
- Compressed images for slow connections
- Data saver mode

---

## 10. Revenue Model

NewTolet earns revenue through the following channels:

| Revenue Stream | Detail |
|----------------|--------|
| Advance payment commission | 5% platform fee on advance payments processed through escrow |
| Premium listings | Landlords/agents pay to feature listings at the top of search results ($1–$3 USD per week) |
| Boost listings | Pay to increase visibility in specific areas ($0.50–$2 USD per boost) |
| Agent membership renewal | Optional premium agent tier with higher bonus multipliers (future v1.1) |

Revenue funds the MLM payout pool, platform operations, and growth.

---

## 11. Technical Overview

### 11.1 Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Frontend** | Flutter (Dart) | Cross-platform mobile app (Android + iOS from single codebase) |
| **Backend** | Supabase | Backend-as-a-Service — database, auth, storage, realtime, edge functions |
| **Database** | Supabase PostgreSQL | Primary database with Row Level Security (RLS) for data isolation |
| **Auth** | Supabase Auth | Phone OTP login, JWT tokens, session management |
| **Realtime** | Supabase Realtime | Live updates for chat, referral tree activity, TNBV leg data |
| **Storage** | Supabase Storage | Listing photos, profile images, training videos (with CDN) |
| **Edge Functions** | Supabase Edge Functions (Deno) | Bonus calculations, point awarding, payout processing, exchange rate logic |
| **Local Storage** | Hive / Isar | Offline draft caching, local preferences |
| **State Management** | Riverpod | App-wide state management in Flutter |
| **Maps** | Google Maps Flutter plugin | Listing map view, GPS verification, radius search |
| **Charts** | fl_chart | MLM performance charts, TNPV graphs, level analysis |
| **Notifications** | Firebase Cloud Messaging (FCM) | Push notifications for both Android and iOS |
| **Payments** | bKash, Nagad, Rocket APIs | Withdrawal payouts and advance payment processing |
| **Deep Links** | Firebase Dynamic Links | Referral invite links that open the app directly |

### 11.2 Platform Requirements

| Item | Detail |
|------|--------|
| Android minimum | 6.0 (API 23) |
| iOS minimum | 12.0 |
| Flutter version | 3.x (latest stable) |
| App size | Under 30 MB (Android), under 40 MB (iOS) |
| Architecture | Clean Architecture + Feature-first folder structure |
| Exchange rate | Admin-managed via Supabase table, updated weekly |

### 11.3 Supabase Schema (High-Level)

| Table | Key Fields | Notes |
|-------|-----------|-------|
| `users` | id, phone, role, star_level, sponsor_id, placement_parent_id, status | RLS by user role |
| `listings` | id, agent_id, category, title, rent_bdt, location_geo, status, expires_at | PostGIS for geo queries |
| `points_ledger` | id, user_id, action, points, usd_value, created_at | Append-only audit log |
| `bonuses` | id, user_id, type, amount_usd, period, paid_at, payout_method | Weekly + monthly + honor |
| `team_tree` | id, user_id, sponsor_id, placement_parent_id, depth, path | Materialized path for fast tree queries |
| `withdrawals` | id, user_id, amount_usd, amount_bdt, exchange_rate, status, method | Rate locked at request time |
| `messages` | id, sender_id, receiver_id, listing_id, content, created_at | Supabase Realtime subscriptions |
| `training_content` | id, title, type, url, language, order | Video/article content management |

### 11.4 Security

| Area | Implementation |
|------|---------------|
| Data in transit | TLS 1.3 for all Supabase API communication |
| Data at rest | Supabase encrypts all data at rest (AES-256) |
| Row Level Security | RLS policies on every table — users only access their own data |
| Authentication | Supabase Auth with Phone OTP + JWT (1h access token, 30d refresh) |
| Rate limiting | Max 10 OTP requests per hour per number (Supabase + Edge Function) |
| Fraud detection | GPS verification for listings, duplicate phone checks, activity pattern monitoring via Edge Functions |
| Privacy | Landlord contact hidden until tenant registered; agent cannot see tenant payment details |
| API security | Supabase anon key + RLS (no direct DB access from client without policies) |

---

## 12. Launch Plan

| Phase | When | What | Go/No-Go Criteria |
|-------|------|------|-------------------|
| Alpha | Month 1–2 | Login, listings, basic MLM tree, points — test in Dhaka (Android APK) | 50+ test agents, <2% crash rate |
| Beta | Month 3–4 | Full team views, bonuses, bKash payout — expand to 4 divisions (Android + iOS TestFlight) | 200+ agents, payout system verified |
| v1.0 Launch | Month 5–6 | All main features, nationwide — public release on Play Store + App Store | All 8 divisions, 500+ listings live |
| v1.1 | Month 7–8 | Training center, upgrade assistant, rewards shop | 70%+ agent retention from beta |
| v2.0 | Month 9–12 | Web dashboard (admin panel), AI listing recommendations, advanced analytics | Revenue positive or clear path |

> **Note:** Since Flutter builds for both Android and iOS from a single codebase, iOS is included from Beta onwards instead of being deferred to v2.0. The v2.0 web dashboard can use Flutter Web or a separate admin panel (React/Next.js on Supabase).

---

## 13. Success Metrics

| What We Measure | 6 Months | 12 Months |
|-----------------|----------|-----------|
| Registered agents | 1,000 | 10,000 |
| Active agents (monthly) | 60% | 70% |
| Total listings | 10,000 | 100,000 |
| Divisions covered | 4 out of 8 | All 8 |
| Districts covered | 20 out of 64 | 50 out of 64 |
| Tenant signups | 5,000 | 50,000 |
| Agent retention (3 months) | 65% | 80% |
| Monthly revenue (USD) | — | TBD after beta |

---

## 14. Risks and How We Handle Them

| Risk | How We Handle It |
|------|-----------------|
| Agents don't join outside Dhaka | District-specific bonuses, local team leaders, regional campaigns |
| Fake or duplicate listings | Photo verification, GPS check (50m radius), manual review before approval |
| People create fake invites for points | Phone OTP required, activity check before awarding points, 1 account per phone number |
| Competition from THE TOLET, Bikroy | Better agent incentives, faster coverage, simpler app |
| Slow internet in rural areas | Offline mode, image compression, small app size |
| Payment gateway issues | Multiple options (bKash + Nagad + Rocket), manual backup |
| USD-BDT rate fluctuation | Weekly admin-set rate with lock at withdrawal time; reserve buffer fund |
| Agent churn mid-tree | Downline remains intact under sponsor's upline; orphaned listings transfer to sponsor |
| Points liability growth | 12-month expiration on inactive accounts; monthly accrual reporting |

---

## 15. Competitors

| Competitor | Their Strength | Our Advantage |
|------------|---------------|---------------|
| THE TOLET | Established brand, affiliate program | MLM agent network gives deeper listing coverage |
| Basha Vara | Good SEO, division-wise listings | Employee incentives drive faster growth |
| ToletBD | Subarea-level search | Agent-verified listings + team quality control |
| Bikroy Rentals | Huge user base | Dedicated rental focus + reward system |
| BDHousing | Large inventory | Broker-free model + MLM growth engine |

---

*End of Document — NewTolet PRD v3*

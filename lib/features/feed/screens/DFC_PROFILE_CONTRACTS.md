# 🥋 DFC PROFILE SCREEN CONTRACTS

**VERTICAL:** Profiles & Identity (Fighter, Gym, Promoter, Fan)
**INFRASTRUCTURE:** Firebase Auth + Firestore
**STATUS:** ARCHITECTURE LOCKED

This document defines the strict data contracts for the Profile vertical. No UI is built without adhering to these exact read, write, and routing rules.

---

## 1. PUBLIC FIGHTER PROFILE (`/public-profile/:fighterId`)
**INTENT:** The showcase. How fans, promoters, and opponents view a fighter's legacy, stats, and media.

### 📖 READS (Firestore)
- `users/{fighterId}`: Gets `displayName`, `photoUrl`.
- `fighters/{fighterId}`: Gets `record`, `weightClass`, `stance`, `bio`, `gymId`.
- `gyms/{gymId}`: Gets the fighter's affiliated gym name/logo.
- `fights` (Query): `where('fighterAId' == fighterId OR 'fighterBId' == fighterId)` for fight history.
- `feedPosts` (Query): `where('authorId' == fighterId)` for the fighter's timeline/clips.
- `suspensions` (Query): Checks if the fighter is currently medically suspended (shows a red flag if true).

### ✍️ WRITES & FUNCTIONS
- **No direct profile writes.** This is a read-only public view.
- **Write:** `follows/{userId}_{fighterId}` (If fan clicks "Follow").

### 🔘 BUTTONS & ACTIONS
- **[Follow Fighter]** → Writes to `follows` collection.
- **[Message]** → Routes to Chat/DM screen.
- **[View Full Fight]** (on history card) → Routes to `/replay` with `fightId`.

### 🧭 NAVIGATION
- `Tap Gym Name` → Routes to `/gym-hub/:gymId`.
- `Tap Replay Clip` → Routes to `/replay/:eventId`.

---

## 2. PRIVATE PROFILE & SETTINGS (`/profile`)
**INTENT:** The Control Center. How a user manages their own data, hardware, and permissions.

### 📖 READS (Firestore)
- `users/{uid}`: Current user base data.
- `fighters/{uid}` (if role==fighter): Own stats, bio, weight.
- `payouts` (Query): `where('fighterUserId' == uid)`.
- `ppvPurchases` (Query): `where('userId' == uid)`.

### ✍️ WRITES & FUNCTIONS
- **Write:** `users/{uid}` (Update avatar, display name).
- **Write:** `fighters/{uid}` (Update weight class, stance, bio).
- **Function:** `updateUserProfile` (Handles secure image uploads to Firebase Storage).
- **Function:** `linkStripeAccount` (For payouts).

### 🔘 BUTTONS & ACTIONS
- **[Edit Bio/Stats]** → Opens edit modal → Writes to `fighters`.
- **[View Wallet/Payouts]** → Routes to `/finance`.
- **[Manage Devices]** → Routes to `/devices` (BLE setup).
- **[Sign Out]** → Calls `FirebaseAuth.instance.signOut()`.

### 🧭 NAVIGATION
- `Hardware Status` → Routes to `/devices`.
- `Wallet/Money` → Routes to `/finance`.
- `Medical Records` → Routes to `/medical`.

---

## 3. GYM & TEAM HUB (`/gym-hub/:gymId`)
**INTENT:** The Roster. Showcases a gym's active fighters, coaches, and overall readiness (if owner).

### 📖 READS (Firestore)
- `gyms/{gymId}`: Gets `name`, `location`, `logoUrl`, `ownerUserId`.
- `fighters` (Query): `where('gymId' == gymId)`. Returns the active roster.
- `users` (Query): Fetch coach profiles linked to the gym.
- **(If Owner/Coach) `aiInsights`:** Fetch aggregated team readiness and fatigue scores.

### ✍️ WRITES & FUNCTIONS
- **Write:** `gyms/{gymId}` (Update logo/location if owner).
- **Write:** `feedPosts` (Post gym news/promos).

### 🔘 BUTTONS & ACTIONS
- **[Join Gym]** → Triggers request to gym owner.
- **[Post Update]** (if owner) → Opens composer → Writes to `feedPosts`.
- **[Team Analytics]** (if coach) → Opens team biometrics.

### 🧭 NAVIGATION
- `Tap Fighter Tile` → Routes to `/public-profile/:fighterId`.
- `Tap Team Analytics` → Routes to `/coach-hub`.

---

## 4. PROMOTER PUBLIC PROFILE (`/promoter-profile/:promoterId`)
**INTENT:** The Brand. How fans see a promotion and find their upcoming events and ticket links.

### 📖 READS (Firestore)
- `users/{promoterId}`: Promoter branding, name, logo.
- `events` (Query): `where('promoterUserId' == promoterId)`. Sorted by `date`.
- `ppvEvents` (Query): Join on event IDs to show what streams are active.
- `feedPosts` (Query): `where('authorId' == promoterId)` for official announcements.

### ✍️ WRITES & FUNCTIONS
- Read-only for public.

### 🔘 BUTTONS & ACTIONS
- **[Buy Tickets / PPV]** → Hits `validatePpvAccess` or routes to Stripe.
- **[View Fight Card]** → Opens event details.

### 🧭 NAVIGATION
- `Tap Event` → Routes to `/event-center/:eventId`.
- `Tap Buy PPV` → Routes to `/ppv/:eventId`.

---

**STATUS:** CONTRACTS LOCKED. 
**NEXT PHASE:** UI IMPLEMENTATION AGAINST CONTRACTS.
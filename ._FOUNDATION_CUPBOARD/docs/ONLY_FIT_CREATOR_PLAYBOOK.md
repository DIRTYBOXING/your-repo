# OnlyFit — Premium DFC Creator Playbook

OnlyFit is the high-prestige, combat-fitness creator vertical integrated directly into the Data Fight Central (DFC) ecosystem. It provides elite athletes, personal trainers, and combat champions with a high-fidelity visual showroom to distribute training content, monetize pay-per-view (PPV) streams, and drive direct ticketing sales under unified brand tokens.

---

## 🎨 1. Vogue/Apple-Grade Design Standards

OnlyFit completely rejects traditional low-contrast social media grids. All screens enforce an elegant, editorial aesthetic:

*   **Deep Obsidian Showrooms:** All backgrounds must remain static deep pitch black (`#000000`, `AppColors.bg`) to let high-end photography shine.
*   **Minimalist Serif displays:** Elegant display serifs (e.g. Playfair Display, Didot) govern major brand headlines, with neutral sans-serifs handling standard microcopy.
*   **Custom Brand Tokens:** Creators configure their profile with a signature highlight accent (`themeColor`, e.g. `#E86A8A` Soft Rose) to dynamically customize UI borders and `DfcGlassPanel` glow states on client devices.

---

## 💳 2. Direct-Commerce Over Chat

OnlyFit completely bypasses typical social messaging/chat modules. Instead, the interaction is strictly focused on prestige, operations, and transaction conversion loops:

*   **Direct-Buy Buttons:** Profile views exhibit two prominent direct call-to-actions: "Buy PPV Access" and "Buy Event Tickets" mapped straight to Stripe Connect express APIs.
*   **No Chat Noise:** Users buy tickets or streams directly from the timeline without engaging in conversational friction. Transactions are immediate and fully auditable.

---

## ⚡ 3. Unified Ingestion and Distribution

All OnlyFit creator feeds undergo standard platform normalization before reaching customer devices:

*   **Ingestion Pipeline:** Posts, highlights, and reels follow the platform's core ingestion loop: `Source Intake -> Normalize -> Rank -> Publish`.
*   **Prioritized Feed Bumps:** Promotions and featured booster packages automatically update scores on the Firestore `feed` collection, instantly floating prioritized creator items to the top of home streams.

---

## 🔒 4. Compliance & KYC Onboarding

Before a creator is permitted to list event tickets or PPV streams, Stripe Express requirements must be fully validated:
- **Verified KYC:** Address, bank details, and identity clearance must report `verified` status on Stripe.
- **Background Checks:** Any creator delivering children-facing mentorship programs must have a signed safeguarding agreement and report active back-office profile approval.

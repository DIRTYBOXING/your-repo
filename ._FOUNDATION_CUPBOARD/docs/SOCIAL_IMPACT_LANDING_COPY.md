# DFC Premium Landing Pages and Donation UX Copy

## Design and brand direction

### Tone
Cinematic, empathetic, authoritative, hopeful.

### Visual language
- Editorial portrait style with generous negative space
- Warm cinematic lighting for human stories
- High-contrast hero with restrained luxury textures for donation and product modules
- Real community scenes over decorative stock imagery

### Typography
- Display: Playfair Display or Didot for hero headlines
- Body: Inter or Helvetica Neue for readability

### Color system
- Soft Rose `#E86A8A` for Pink Shields
- Warm Gold `#C89B3A` for Gold Coin Gym
- Deep Charcoal `#111217` for primary text
- Warm Sand `#F6EDE6` and Muted Teal `#2E8B8A` as supporting accents

### Motion
- Subtle parallax in hero only
- Fade-up section reveals
- Light CTA hover scale
- Respect `prefers-reduced-motion`

## Pink Shields page copy

### Hero
Headline: Pink Shields Protect. Rebuild. Empower.

Subhead: Small acts. Real shelter. Lasting safety for women and children affected by violence.

Primary CTA: Donate Now - Rebuild a Safe Room

Secondary CTA: Sponsor a Mentor

Hero microcopy: Every $25 funds emergency supplies. Every $500 rebuilds a safe room.

### Why it matters
Section title: Why Pink Shields

Body: Violence leaves physical scars and shattered safety. Pink Shields funds emergency relief, rebuilds safe spaces, and connects survivors with trained mentors and legal support. We partner with local shelters and certified trainers to deliver immediate help and long-term recovery.

### Impact snapshot
- Safe Rooms Rebuilt: 124 this year
- Survivors Supported: 3,482 emergency grants
- Mentor Hours Delivered: 5,200

### How it works
- Step 1: Create a safe fund for emergency grants.
- Step 2: Partner NGOs verify needs and match survivors.
- Step 3: Trainers and mentors provide recovery programs and skills.

### Donation module copy
Preset CTA row: Donate $5, Donate $25, Donate $100, Other

Microcopy: One-click donations, secure payments, and transparent quarterly reporting.

### Story block
Title: Survivor voices

Quote: They rebuilt our room and gave us a place to sleep without fear.

Attribution: Anonymized testimonial

### Footer CTA
Headline: Join the Shield Network

CTA: Volunteer or Partner

## Buy a Coffee Not a Coffin page copy

### Hero
Headline: Buy a Coffee Not a Coffin

Subhead: Micro-donations that fund emergency response and trauma care.

Primary CTA: Donate $1 Now

Secondary CTA: Round Up My Purchases

Hero microcopy: Small daily acts save lives.

### How it works
- Round Up: round purchases to the nearest dollar
- Micro-donations: one-click $1 to $5 donations
- Impact: immediate medical, legal, and crisis support pathways

### Social proof module
- Daily donors: 12,400
- Average donation: $2.30

### CTA module
- Donate $1
- Subscribe $5 per month
- Gift a Coffee

### Footer CTA
Headline: Start Rounding Up Today

CTA: Enable Round Up

## Gold Coin Gym page copy

### Hero
Headline: Gold Coin Gym Train Mentor Transform

Subhead: Pay-what-you-can classes, youth mentorship, and scholarships powered by DFC trainers.

Primary CTA: Book a Class

Secondary CTA: Sponsor a Seat

Hero microcopy: Every class funds a scholarship for an at-risk child.

### Program overview
- Gold Coin classes: pay-what-you-can community sessions
- Sponsor a Seat: donors fund access for youth
- Mentor program: certified trainers deliver life skills and vocational coaching

### Donation and sponsorship options
- Sponsor a Month: $500 funds 20 classes
- Corporate Match: contact team for matching program setup

### Footer CTA
Headline: Become a Certified Mentor

CTA: Apply Now

## Donation modal microcopy

### Header
Support this program in one click

### Fields
- Donation amount
- Recurring toggle
- Payment method
- Tax receipt email

### Privacy and legal note
We process donations securely. Personal data is used for receipts and reporting only.

### Confirmation message
Thank you. Your donation of $X has been received. A receipt has been sent to your email.

## Accessibility and performance checklist
- Body text contrast at least 4.5:1
- Full keyboard navigation for donation and form flows
- ARIA labels for all donation controls and live confirmation status
- Alt text for all images with no survivor-identifying details
- Responsive hero images with `srcset`
- Lazy-load below-the-fold media
- Inline critical CSS for first paint

## Analytics event hooks
- `page_view` with `page_name`
- `cta_click` with `cta_name` and optional `amount`
- `donation_submitted` with `amount`, `currency`, `recurring`, `method`
- `sponsor_seat` with `program` and `seats`
- `trainer_signup` with `trainer_id` and `city`
- `share` with `channel`
- `ab_experiment` with `experiment_id` and `variant`

## A/B test ideas
- Hero CTA copy: Donate Now vs Rebuild a Safe Room
- Donation presets: 5-25-100 vs 1-10-50
- Hero image type: portrait vs community rebuild
- Recurring toggle default: off vs on

## Ready snippets

Meta title: Pink Shields - Rebuild Safe Spaces for Women and Children | DFC

Meta description: Join Pink Shields by Data Fight Central. Donate to fund emergency support, rebuild safe rooms, and mentor survivors.

Footer short: Data Fight Central. All donations processed securely. Privacy Policy and Terms.

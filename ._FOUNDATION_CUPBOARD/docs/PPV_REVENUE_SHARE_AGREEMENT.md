# DATA FIGHT CENTRAL — PAY-PER-VIEW REVENUE SHARE AGREEMENT

## CONTRACT OF SALE & PLATFORM SERVICES

**Document Version:** 1.0  
**Effective Date:** **\*\***\_\_\_**\*\***  
**Last Updated:** 24 March 2026  
**Governing Entities:**

- Dirty Boxing Pty Ltd (ABN pending) — Australia
- DataFightCentral LLC (EIN pending) — United States

All entities operate under the brand **"Data Fight Central"** ("DFC", "Platform", "we", "us", "our")  
**Contact:** legal@datafightcentral.com  
**Primary Jurisdiction:** Queensland, Australia / California, USA

---

## RECITALS

**WHEREAS** DataFightCentral operates a digital pay-per-view platform for combat sports content distribution, event livestreaming, and related e-commerce services;

**WHEREAS** the Platform provides worldwide advertising, promotion, and e-commerce infrastructure that drives viewership, sales volume, and audience reach on behalf of content creators, promoters, and event organisers;

**WHEREAS** the parties wish to establish a transparent, formulaic revenue-sharing arrangement that compensates the Platform proportionally for the exposure, distribution, and commercial infrastructure it provides;

**NOW, THEREFORE**, in consideration of the mutual covenants and agreements set forth herein, the parties agree as follows:

---

## 1. DEFINITIONS

1.1. **"Buy"** or **"Purchase"** means a single completed pay-per-view transaction by an end consumer for access to a PPV Event, at the applicable Event Price.

1.2. **"Event Price"** means the retail price per Buy as set by the Promoter and approved by DFC, denominated in the applicable Supported Currency. The standard base Event Price is **$20.00 AUD** unless otherwise agreed in writing.

1.3. **"Gross Revenue"** means the total amount collected from all Buys for a given PPV Event, calculated as: `Buys × Event Price`.

1.4. **"Payment Processing Fees"** means the fees charged by the third-party payment processor (Stripe) at the prevailing rate of **2.9% of the transaction amount plus $0.30 AUD per transaction**, or such other rate as may apply. Calculated as: `Buys × (Event Price × 0.029 + 0.30)`.

1.5. **"Net Revenue"** means Gross Revenue less Payment Processing Fees: `Net Revenue = Gross Revenue − Payment Processing Fees`.

1.6. **"DFC Platform Percentage"** means the percentage of Net Revenue payable to DFC, determined by the Sliding Scale Formula defined in Section 3.

1.7. **"DFC Cut"** means the dollar amount payable to DFC: `DFC Cut = Net Revenue × DFC Platform Percentage`.

1.8. **"Promoter Cut"** means the dollar amount attributable to the Promoter: `Promoter Cut = Net Revenue − DFC Cut`.

1.9. **"Dispute & Chargeback Reserve"** means an amount equal to **two percent (2%)** of Net Revenue withheld as a reserve against chargebacks, refund claims, and payment disputes: `Reserve = Net Revenue × 0.02`.

1.10. **"Payable to Promoter"** means the final amount disbursed to the Promoter after all deductions: `Payable = Promoter Cut − Reserve`.

1.11. **"Exposure Threshold"** means the cumulative number of Buys for a single PPV Event, used to determine the applicable DFC Platform Percentage under the Sliding Scale.

1.12. **"Supported Currencies"** means AUD, USD, GBP, EUR, NZD, SGD, CAD, ZAR, NGN, BRL, MXN, INR, PHP, and JPY, or such other currencies as DFC may support from time to time.

---

## 2. PARTIES

2.1. **PLATFORM PROVIDER:** DataFightCentral, operated by Dirty Boxing Pty Ltd and/or DataFightCentral LLC (collectively, "DFC").

2.2. **CONTENT PROVIDER / PROMOTER:** ******\*\*\*\*******\_******\*\*\*\******* ("Promoter"), an individual or entity duly authorised to promote, produce, and distribute combat sports events.

2.3. Each party represents and warrants that it has the legal authority and capacity to enter into this Agreement and to perform its obligations hereunder.

---

## 3. SLIDING SCALE REVENUE SHARE — CORE CLAUSE

### 3.1. Sliding Scale Formula

The DFC Platform Percentage shall be calculated dynamically based on the cumulative number of Buys for each PPV Event, according to the following formula:

> **DFC Platform Percentage = 30% + (min(Buys, 10,000) ÷ 10,000) × 20%**

This formula produces a **linear interpolation** from a **floor of thirty percent (30%)** to a **ceiling of fifty percent (50%)** as the number of Buys increases from zero (0) to ten thousand (10,000).

### 3.2. Boundary Conditions

| Condition                             | DFC Platform %  | Promoter Share % |
| ------------------------------------- | --------------- | ---------------- |
| 0 Buys                                | 30.00%          | 70.00%           |
| At any point between 1 and 9,999 Buys | 30.00% – 49.98% | 70.00% – 50.02%  |
| 10,000 or more Buys                   | 50.00% (cap)    | 50.00% (floor)   |

### 3.3. Rationale & Commercial Justification

(a) **At low volume (0–500 Buys):** The Promoter retains approximately **70%** of Net Revenue, recognising that early-stage events carry higher risk for the Promoter and lower infrastructure costs for DFC. DFC's 30% floor covers base platform hosting, payment processing overhead, content delivery network (CDN) costs, and basic promotional placement.

(b) **At medium volume (501–5,000 Buys):** As Buys increase, DFC's worldwide advertising, e-commerce infrastructure, search engine visibility, social media amplification, and algorithmic promotion contribute materially to driving additional sales. The Platform Percentage increases proportionally to reflect DFC's growing contribution to commercial success.

(c) **At high volume (5,001–10,000+ Buys):** Events achieving significant viewership benefit substantially from DFC's global distribution network, cross-promotion across concurrent events, featured placement in browse/discovery feeds, push notification campaigns, and international payment processing in multiple currencies. The Platform Percentage approaches and caps at **50%**, reflecting the equal value exchange between content and distribution.

(d) **Cap at 50%:** The DFC Platform Percentage shall not exceed **fifty percent (50%)** regardless of the number of Buys, ensuring the Promoter always retains at least half of Net Revenue.

### 3.4. Illustrative Schedule

The following table illustrates the revenue split at selected thresholds for a standard **$20.00 Event Price**:

| Buys   | Gross ($)  | Stripe Fees ($) | Net ($)    | DFC %  | DFC Cut ($) | Promoter Cut ($) | Reserve ($) | Payable ($) |
| ------ | ---------- | --------------- | ---------- | ------ | ----------- | ---------------- | ----------- | ----------- |
| 50     | 1,000.00   | 44.00           | 956.00     | 30.10% | 287.76      | 668.24           | 19.12       | 649.12      |
| 100    | 2,000.00   | 88.00           | 1,912.00   | 30.20% | 577.42      | 1,334.58         | 38.24       | 1,296.34    |
| 250    | 5,000.00   | 220.00          | 4,780.00   | 30.50% | 1,457.90    | 3,322.10         | 95.60       | 3,226.50    |
| 500    | 10,000.00  | 440.00          | 9,560.00   | 31.00% | 2,963.60    | 6,596.40         | 191.20      | 6,405.20    |
| 1,000  | 20,000.00  | 880.00          | 19,120.00  | 32.00% | 6,118.40    | 13,001.60        | 382.40      | 12,619.20   |
| 2,500  | 50,000.00  | 2,200.00        | 47,800.00  | 35.00% | 16,730.00   | 31,070.00        | 956.00      | 30,114.00   |
| 5,000  | 100,000.00 | 4,400.00        | 95,600.00  | 40.00% | 38,240.00   | 57,360.00        | 1,912.00    | 55,448.00   |
| 7,500  | 150,000.00 | 6,600.00        | 143,400.00 | 45.00% | 64,530.00   | 78,870.00        | 2,868.00    | 76,002.00   |
| 10,000 | 200,000.00 | 8,800.00        | 191,200.00 | 50.00% | 95,600.00   | 95,600.00        | 3,824.00    | 91,776.00   |
| 15,000 | 300,000.00 | 13,200.00       | 286,800.00 | 50.00% | 143,400.00  | 143,400.00       | 5,736.00    | 137,664.00  |

### 3.5. Per-Event Calculation

The Sliding Scale is applied **independently per PPV Event**. Buy counts from one Event do not carry over or aggregate with other Events for the purpose of calculating the DFC Platform Percentage, unless the parties agree otherwise in a separate Multi-Event Package addendum.

---

## 4. PAYMENT PROCESSING & DEDUCTIONS

### 4.1. Payment Processor

All transactions are processed through **Stripe** (or such successor processor as DFC may designate). Stripe fees are deducted from Gross Revenue **before** the revenue split is applied.

### 4.2. Stripe Fee Schedule

The current Stripe fee structure applied to each Buy is:

> **Stripe Fee per Buy = (Event Price × 2.9%) + $0.30 AUD**

Example at $20.00 Event Price: `($20.00 × 0.029) + $0.30 = $0.88 per Buy`

### 4.3. Dispute & Chargeback Reserve

(a) DFC shall withhold **two percent (2%)** of the Net Revenue from each Event as a Reserve against chargebacks, payment disputes, and refund obligations.

(b) The Reserve shall be held for a period of **ninety (90) days** following the Event date.

(c) Any portion of the Reserve not applied to settled chargebacks or refunds within the 90-day period shall be released and paid to the Promoter in the next scheduled payout cycle.

(d) If chargeback or refund claims exceed the Reserve amount, the excess shall be deducted from the Promoter's future payouts or invoiced to the Promoter directly, at DFC's sole election.

### 4.4. Currency Conversion

Where Buys are made in currencies other than the Promoter's nominated settlement currency, conversion shall be performed at Stripe's prevailing exchange rate at the time of settlement. Currency conversion fees, if any, are borne by the Promoter.

---

## 5. PAYOUT TERMS

### 5.1. Standard Payout Schedule

Payouts are processed **weekly**, on each Monday, for all settled funds from the previous seven (7) day period, subject to a minimum payout threshold of **$50.00 AUD** (or equivalent in the Promoter's settlement currency).

### 5.2. Payout Method

Funds are disbursed via Stripe Connect to the Promoter's verified bank account. The Promoter is responsible for providing and maintaining accurate banking details.

### 5.3. Payout Holds

DFC may place a temporary hold on payouts if:

(a) The Event is subject to an active dispute, investigation, or complaint;  
(b) DFC suspects fraudulent activity, artificially inflated Buy counts, or Terms of Service violations;  
(c) Required by law, regulation, or court order;  
(d) The Promoter's account information is incomplete or unverified.

### 5.4. Tax Obligations

Each party is solely responsible for its own tax obligations. DFC may issue tax reporting documents (e.g., 1099 forms for US-based Promoters, Payment Summaries for Australian Promoters) as required by applicable law. The Promoter acknowledges that all amounts stated in this Agreement are exclusive of applicable taxes unless stated otherwise.

---

## 6. PLATFORM SERVICES PROVIDED BY DFC

In consideration of the DFC Platform Percentage, DFC provides the following services:

### 6.1. Core Distribution Infrastructure

(a) Secure, scalable hosting and content delivery network (CDN) for livestream and on-demand PPV content;  
(b) Multi-currency payment processing in all Supported Currencies;  
(c) Consumer-facing purchase flow, account management, and access control;  
(d) Mobile (iOS, Android) and web application distribution;  
(e) Customer support for purchase-related enquiries.

### 6.2. Promotion & Advertising (Proportional to Exposure)

(a) Algorithmic placement in browse and discover feeds;  
(b) Push notification campaigns to registered users;  
(c) Social media cross-promotion through DFC's official channels;  
(d) Email marketing campaigns to DFC's subscriber base;  
(e) Search engine optimisation (SEO) for Event pages;  
(f) Cross-event promotional banners and recommendations.

### 6.3. Analytics & Reporting

(a) Real-time sales dashboard with live Buy counts, revenue, and split visualisation;  
(b) Post-event reconciliation reports;  
(c) Geographic and demographic audience insights;  
(d) Revenue projection tools.

### 6.4. Proportionality

The intensity and scope of DFC's promotional and advertising efforts scale proportionally with the number of Buys and revenue generated by an Event, reflecting the sliding nature of the revenue share. Higher-performing Events receive greater platform investment in promotion, placement, and distribution resources.

---

## 7. PROMOTER OBLIGATIONS

7.1. The Promoter shall provide all necessary content, metadata, fighter information, and event details required to list and promote the PPV Event on the Platform.

7.2. The Promoter represents and warrants that:

(a) It holds all necessary rights, licences, and permissions to distribute the Event content;  
(b) It holds valid promoter licences where required by the applicable athletic commission or governing body;  
(c) All fighters appearing on the Event card have signed appropriate bout agreements and media release authorisations;  
(d) The Event content does not infringe any third-party intellectual property rights.

7.3. The Promoter shall comply with all applicable laws, regulations, and DFC Community Guidelines.

7.4. The Promoter shall not simultaneously sell identical content on competing platforms during the live broadcast window unless a separate co-distribution agreement is in effect.

---

## 8. OTHER REVENUE STREAMS

The following revenue types are governed by separate, fixed fee schedules (not subject to the PPV Sliding Scale):

| Revenue Type        | DFC Platform Fee                      | Creator/Promoter Share |
| ------------------- | ------------------------------------- | ---------------------- |
| PPV Events          | 30–50% (Sliding Scale, per Section 3) | 70–50%                 |
| Event Tickets       | 15%                                   | 85%                    |
| Marketplace Sales   | 25%                                   | 75%                    |
| Sponsorship Revenue | 25%                                   | 75%                    |
| Donations / Tips    | 0%                                    | 100%                   |

These fixed splits are subject to change upon thirty (30) days' written notice to the affected party.

---

## 9. TERM & TERMINATION

### 9.1. Term

This Agreement commences on the Effective Date and continues for an initial term of **twelve (12) months**, automatically renewing for successive 12-month periods unless terminated by either party.

### 9.2. Termination Without Cause

Either party may terminate this Agreement by providing **thirty (30) days'** written notice to the other party.

### 9.3. Termination for Cause

Either party may terminate immediately upon written notice if:

(a) The other party commits a material breach and fails to cure within fourteen (14) days of receiving written notice;  
(b) The other party becomes insolvent, enters administration, or commences bankruptcy proceedings;  
(c) The other party engages in fraudulent, illegal, or grossly negligent conduct.

### 9.4. Effect of Termination

Upon termination:

(a) All outstanding payouts shall be processed within thirty (30) days, subject to the Reserve hold period;  
(b) The Promoter's Events shall be removed from active sale on the Platform;  
(c) Existing purchasers retain access to previously purchased content for a minimum of twelve (12) months;  
(d) Sections 10 (Limitation of Liability), 11 (Indemnification), 12 (Confidentiality), and 13 (Dispute Resolution) survive termination.

---

## 10. LIMITATION OF LIABILITY

10.1. TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, DFC's TOTAL AGGREGATE LIABILITY UNDER THIS AGREEMENT SHALL NOT EXCEED THE TOTAL DFC CUT RETAINED BY DFC FROM THE PROMOTER'S EVENTS DURING THE TWELVE (12) MONTH PERIOD PRECEDING THE CLAIM.

10.2. IN NO EVENT SHALL EITHER PARTY BE LIABLE FOR INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, INCLUDING BUT NOT LIMITED TO LOSS OF PROFITS, REVENUE, DATA, GOODWILL, OR BUSINESS OPPORTUNITY.

10.3. The limitations in this Section do not apply to: (a) breaches of confidentiality obligations; (b) indemnification obligations; (c) wilful misconduct or fraud.

---

## 11. INDEMNIFICATION

11.1. The Promoter shall indemnify, defend, and hold harmless DFC, its officers, directors, employees, and agents from and against all claims, liabilities, damages, losses, and expenses (including reasonable legal fees) arising from:

(a) The Promoter's breach of this Agreement;  
(b) Any claim that the Event content infringes third-party rights;  
(c) Injuries, damages, or claims arising from the Event itself;  
(d) The Promoter's violation of applicable laws or regulations.

11.2. DFC shall indemnify, defend, and hold harmless the Promoter from claims arising directly from DFC's platform infrastructure failures that result in loss of revenue, provided the Promoter notifies DFC promptly and cooperates in the defence.

---

## 12. CONFIDENTIALITY

12.1. Each party agrees to keep confidential the other party's proprietary business information, financial data, and the specific terms of any custom revenue-sharing arrangements.

12.2. This obligation does not apply to information that: (a) is publicly available; (b) was known to the receiving party prior to disclosure; (c) is independently developed; or (d) must be disclosed by law or court order.

12.3. Confidentiality obligations survive termination for a period of **three (3) years**.

---

## 13. DISPUTE RESOLUTION

13.1. **Negotiation:** The parties shall first attempt to resolve disputes through good-faith negotiation for a period of thirty (30) days.

13.2. **Mediation:** If negotiation fails, disputes shall be submitted to mediation under the rules of the Australian Disputes Centre (ADC) or, for US-based Promoters, the American Arbitration Association (AAA).

13.3. **Arbitration:** If mediation fails, disputes shall be resolved by binding arbitration in Brisbane, Queensland, Australia (or Los Angeles, California, USA for US-based Promoters), under the applicable arbitration rules.

13.4. **Governing Law:** This Agreement is governed by the laws of Queensland, Australia. For US-based Promoters, the laws of the State of California shall apply as an alternative governing law.

13.5. **Injunctive Relief:** Nothing in this section prevents either party from seeking urgent injunctive or equitable relief from a court of competent jurisdiction where necessary to prevent irreparable harm.

---

## 14. MODIFICATIONS TO REVENUE SPLIT

14.1. **Standard Sliding Scale:** The Sliding Scale formula in Section 3 represents the **default revenue share** for all Promoters unless modified in writing.

14.2. **Custom Arrangements:** Variations to the Sliding Scale (e.g., volume discounts, founding partner rates, exclusivity bonuses) must be documented in a separate **Promoter Partnership Amendment** (see DFC_PROMOTER_CONTRACT_EXTENSION_TEMPLATE) executed by both parties.

14.3. **Formula Changes:** DFC reserves the right to modify the Sliding Scale formula upon **sixty (60) days'** written notice. Any modification applies prospectively to Events listed after the effective date and does not affect Events already scheduled or in progress.

14.4. **Grandfathering:** Promoters with active Events at the time of a formula change retain the existing formula for those Events until completion.

---

## 15. GENERAL PROVISIONS

15.1. **Entire Agreement:** This Agreement, together with any executed Amendments, constitutes the entire agreement between the parties regarding the subject matter hereof and supersedes all prior negotiations, representations, and agreements.

15.2. **Severability:** If any provision is held invalid or unenforceable, the remaining provisions shall continue in full force and effect.

15.3. **Assignment:** Neither party may assign this Agreement without the prior written consent of the other party, except in connection with a merger, acquisition, or sale of substantially all assets.

15.4. **Force Majeure:** Neither party shall be liable for failure to perform due to events beyond its reasonable control, including natural disasters, war, pandemic, government action, or infrastructure failure.

15.5. **Notices:** All notices shall be in writing and delivered to:

**DFC:** legal@datafightcentral.com  
**Promoter:** ******\*\*\*\*******\_******\*\*\*\******* (email provided at registration)

15.6. **Waiver:** Failure to enforce any provision shall not constitute a waiver of the right to enforce it subsequently.

15.7. **Independent Contractors:** The parties are independent contractors. Nothing herein creates an employment, agency, joint venture, or partnership relationship.

---

## 16. EXECUTION

By signing below, the parties acknowledge that they have read, understood, and agree to be bound by the terms of this PPV Revenue Share Agreement.

---

**DATA FIGHT CENTRAL**

|                                |                                            |
| ------------------------------ | ------------------------------------------ |
| **Authorised Representative:** | ******\*\*\*\*******\_******\*\*\*\******* |
| **Title:**                     | Founder / Director                         |
| **Date:**                      | ******\*\*\*\*******\_******\*\*\*\******* |
| **Signature:**                 | ******\*\*\*\*******\_******\*\*\*\******* |

---

**PROMOTER**

|                                |                                            |
| ------------------------------ | ------------------------------------------ |
| **Legal Name / Entity:**       | ******\*\*\*\*******\_******\*\*\*\******* |
| **ABN / EIN (if applicable):** | ******\*\*\*\*******\_******\*\*\*\******* |
| **Authorised Representative:** | ******\*\*\*\*******\_******\*\*\*\******* |
| **Title:**                     | ******\*\*\*\*******\_******\*\*\*\******* |
| **Date:**                      | ******\*\*\*\*******\_******\*\*\*\******* |
| **Signature:**                 | ******\*\*\*\*******\_******\*\*\*\******* |

---

## SCHEDULE A — SLIDING SCALE REFERENCE TABLE

The following table provides the DFC Platform Percentage at each 1,000-Buy increment for quick reference:

| Buys    | DFC %  | Promoter % |
| ------- | ------ | ---------- |
| 0       | 30.00% | 70.00%     |
| 1,000   | 32.00% | 68.00%     |
| 2,000   | 34.00% | 66.00%     |
| 3,000   | 36.00% | 64.00%     |
| 4,000   | 38.00% | 62.00%     |
| 5,000   | 40.00% | 60.00%     |
| 6,000   | 42.00% | 58.00%     |
| 7,000   | 44.00% | 56.00%     |
| 8,000   | 46.00% | 54.00%     |
| 9,000   | 48.00% | 52.00%     |
| 10,000+ | 50.00% | 50.00%     |

---

## SCHEDULE B — FEE DEDUCTION WATERFALL

For each PPV Event, revenue flows through the following deduction waterfall:

```
1. GROSS REVENUE          = Buys × Event Price
2. STRIPE FEES            = Buys × (Event Price × 0.029 + 0.30)
3. NET REVENUE            = Gross Revenue − Stripe Fees
4. DFC CUT                = Net Revenue × DFC Platform Percentage
5. PROMOTER CUT           = Net Revenue − DFC Cut
6. RESERVE (2%)           = Net Revenue × 0.02
7. PAYABLE TO PROMOTER    = Promoter Cut − Reserve
```

The Reserve is released after 90 days, less any settled chargebacks or refunds.

---

## SCHEDULE C — TECHNICAL IMPLEMENTATION REFERENCE

The Sliding Scale formula is implemented in the DFC platform codebase as follows (reference only, not part of the contractual terms):

- **`stripe_payment_engine.dart`** — `ppvPlatformFee = 0.30` (floor constant)
- **`creator_payout_engine.dart`** — `ppvCreatorShareFloor = 0.70`, `ppvCreatorShareCeiling = 0.50`, `ppvCreatorShareForExposure(exposure)` (sliding interpolation)
- **`promoter_reconciliation_screen.dart`** — `_dfcPct(buys) = 0.30 + (min(buys, 10000) / 10000) * 0.20` (display formula)

---

_END OF AGREEMENT_

**Document ID:** DFC-PPV-RSA-v1.0  
**Classification:** Confidential — Commercial in Confidence

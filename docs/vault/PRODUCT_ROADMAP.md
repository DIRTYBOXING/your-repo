# 🔒 DFC PRODUCT ROADMAP — VAULT DOCUMENT

> **STATUS: FUTURE TECH — DO NOT BUILD**  
> This is a conceptual engineering spec, not an active development target.

---

# 🚀 PRODUCT ROADMAP v1.0

## PHASE 1 — MVP (Months 1-3)

### Hardware

- [ ] Glove-clip prototype (3D printed)
- [ ] Basic IMU (MPU-6050 for dev)
- [ ] nRF52840 dev board
- [ ] USB charging

### Firmware

- [ ] IMU sampling @ 100 Hz
- [ ] Basic punch detection (threshold)
- [ ] BLE streaming
- [ ] Battery monitoring

### App

- [ ] BLE pairing
- [ ] Real-time punch count
- [ ] Session recording
- [ ] Basic stats display

### AI

- [ ] Rule-based punch detection
- [ ] Simple speed estimation

### Deliverable

**Working prototype that counts punches and estimates speed**

---

## PHASE 2 — V1 (Months 4-6)

### Hardware

- [ ] Injection-molded glove-clip
- [ ] ICM-42688-P IMU upgrade
- [ ] Piezo impact sensor
- [ ] Magnetic charging dock
- [ ] Headgear sensor prototype

### Firmware

- [ ] Madgwick sensor fusion
- [ ] Punch classification
- [ ] Impact event detection
- [ ] Power optimization
- [ ] OTA updates

### App

- [ ] Punch type breakdown
- [ ] Round timer
- [ ] Session history
- [ ] Cloud sync
- [ ] Basic ATLAS coaching tips

### AI

- [ ] CNN punch classifier
- [ ] Speed regression model
- [ ] Basic force estimation

### Deliverable

**Production-ready glove-clip with punch classification**

---

## PHASE 3 — V2 (Months 7-9)

### Hardware

- [ ] UWB module integration
- [ ] DW3000 ranging
- [ ] Refined headgear sensor
- [ ] Smart pad prototype

### Firmware

- [ ] UWB two-way ranging
- [ ] Multi-device sync
- [ ] Distance classification
- [ ] Hit/miss detection

### App

- [ ] Sparring mode
- [ ] Two-fighter pairing
- [ ] Live distance display
- [ ] Near-miss tracking
- [ ] Head impact alerts

### AI

- [ ] Distance scoring model
- [ ] Impact classification
- [ ] Fight IQ v1
- [ ] Fatigue detection

### Deliverable

**Full sparring system with distance tracking and head impact monitoring**

---

## PHASE 4 — V3 (Months 10-18)

### Hardware

- [ ] Smart heavy bag sensor
- [ ] Smart pads (coach mitt)
- [ ] Ring boundary sensors
- [ ] Broadcast integration kit

### Firmware

- [ ] Multi-node mesh
- [ ] Ring positioning
- [ ] Event scoring mode

### App

- [ ] Gym dashboard
- [ ] Coach tools
- [ ] Fighter comparison
- [ ] Leaderboards
- [ ] Training programs

### AI

- [ ] Advanced Fight IQ
- [ ] Technique scoring
- [ ] Matchmaking predictions
- [ ] Injury risk model

### Deliverable

**Gym ecosystem with smart equipment and coaching tools**

---

## PHASE 5 — V4 (Months 18-24)

### Hardware

- [ ] Referee wearable
- [ ] Ring sensors (8-point)
- [ ] Broadcast overlay system
- [ ] Arena installation kit

### Platform

- [ ] Event scoring mode
- [ ] Live TV integration
- [ ] Streaming overlay
- [ ] Commission dashboard

### AI

- [ ] AI judge scoring
- [ ] Real-time analytics
- [ ] Fighter digital twin
- [ ] Predictive commentary

### Deliverable

**Event-ready AI scoring system for sanctioned competitions**

---

## PHASE 6 — GLOBAL (Year 2+)

### Scale

- [ ] 1,000+ gyms
- [ ] 50+ promotions
- [ ] 500,000+ fighters
- [ ] Global leaderboard

### Products

- [ ] DFC Combat OS (gym management)
- [ ] DFC Event Suite (promotion tools)
- [ ] DFC Broadcast (TV integration)
- [ ] DFC Academy (certification)

### AI

- [ ] ATLAS 3.0 (autonomous coaching)
- [ ] Virtual sparring partner
- [ ] Career trajectory prediction
- [ ] Global ranking algorithm

---

## MILESTONES SUMMARY

| Phase  | Timeline | Key Deliverable          |
| ------ | -------- | ------------------------ |
| MVP    | Month 3  | Punch counting prototype |
| V1     | Month 6  | Production glove-clip    |
| V2     | Month 9  | Sparring + UWB system    |
| V3     | Month 18 | Smart gym ecosystem      |
| V4     | Month 24 | Event scoring system     |
| Global | Year 2+  | Platform dominance       |

---

## RISK FACTORS

### Technical

- UWB accuracy in sweaty/metal environments
- Battery life vs. sensor rate tradeoff
- Edge ML performance on nRF52840

### Business

- Manufacturing cost control
- Gym adoption friction
- Event sanctioning approval

### Mitigation

- Prototype early, test often
- Partner with gyms for beta
- Work with commissions from Phase 3

---

_Vault Document — March 2026_

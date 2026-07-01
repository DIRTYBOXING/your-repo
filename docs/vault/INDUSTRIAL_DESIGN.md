# 🔒 DFC INDUSTRIAL DESIGN BRIEF — VAULT DOCUMENT

> **STATUS: FUTURE TECH — DO NOT BUILD**  
> This is a conceptual engineering spec, not an active development target.

---

# 🧱 INDUSTRIAL DESIGN BRIEF v1.0

## 1. GLOVE-CLIP

### Dimensions

- **Length:** 30 mm
- **Width:** 20 mm
- **Height:** 10 mm
- **Weight:** < 18 grams (with battery)

### Materials

| Component         | Material            | Reason                              |
| ----------------- | ------------------- | ----------------------------------- |
| Shell (top)       | PC-ABS              | Impact resistance, lightweight      |
| Shell (bottom)    | TPU overmold        | Grip, shock absorption              |
| Clip              | 301 Stainless Steel | Spring memory, corrosion resistance |
| Gasket            | Silicone            | Water/sweat sealing                 |
| Charging contacts | Gold-plated copper  | Corrosion resistance                |

### Clip Mechanism

```
- Spring steel clip (3mm width)
- Clamping force: 2-3N
- Opening angle: 45°
- Fits glove seams 3-8mm thick
- Quick-release tab
```

### Environmental Requirements

- **IP Rating:** IP54 (sweat-sealed)
- **Temperature:** -10°C to +50°C operation
- **Shock:** Survive 10G lateral (500 cycles)
- **Drop:** Survive 1.5m drop onto rubber (100 cycles)

### Mounting Positions

- Wrist strap (primary)
- Glove cuff (secondary)
- Hook-and-loop patch (optional)

### Color Options

- Stealth Black (matte)
- Fire Red (accent)
- White (neutral)

---

## 2. HEADGEAR SENSOR

### Dimensions

- **Length:** 40 mm
- **Width:** 30 mm
- **Height:** 12 mm
- **Weight:** < 25 grams

### Materials

| Component    | Material         | Reason              |
| ------------ | ---------------- | ------------------- |
| Outer shell  | TPU (Shore 80A)  | Impact absorption   |
| Inner frame  | PC-ABS           | Structural rigidity |
| Foam liner   | EVA closed-cell  | Dampening, comfort  |
| Mounting pad | Medical silicone | Skin contact, grip  |

### Impact Protection

```
- TPU shell absorbs initial impact
- EVA foam dampens vibration
- PCB isolated on rubber mounts
- High-G sensor rated to 400G
```

### Mounting System

- Hook-and-loop base pad
- Adhesive for permanent mount
- Elastic strap option
- Fits inside headgear padding

### Environmental Requirements

- **IP Rating:** IP54
- **Temperature:** -10°C to +50°C
- **Shock:** Survive 400G impact (1000 cycles)

---

## 3. CHARGING DOCK

### Design

- Magnetic alignment
- Dual slots (L + R glove-clips)
- Single slot (headgear)
- USB-C input
- LED indicators

### Materials

- ABS base
- Silicone contact pads
- Neodymium magnets (N52)

---

## 4. PCB LAYOUT CONSTRAINTS

### Glove-Clip PCB

- **Size:** 25 × 15 mm
- **Layers:** 4-layer
- **Components:**
  - nRF52840 (center)
  - ICM-42688-P (edge, oriented)
  - Piezo connector (bottom edge)
  - Battery connector (side)
  - Charging pads (bottom)
  - Antenna (top edge, keep-out zone)

### Headgear PCB

- **Size:** 35 × 25 mm
- **Layers:** 4-layer
- **Components:**
  - nRF52840 (center)
  - ADXL372 high-G (isolated mount)
  - ICM-42688-P (secondary)
  - Larger battery connector

---

## 5. ANTENNA DESIGN

### BLE Antenna

- PCB trace antenna
- 2.4 GHz tuned
- Keep-out zone: 5mm radius
- Ground plane cutout

### UWB Antenna

- Chip antenna (DW3000 companion)
- 6.5 GHz tuned
- Clearance from metal surfaces

---

## 6. MANUFACTURING CONSTRAINTS

### Injection Molding

- Draft angles: 2° minimum
- Wall thickness: 1.5-2.5mm uniform
- Undercuts: avoid or use side actions
- Gate placement: hidden surfaces

### Assembly

- Snap-fit shell (no screws)
- Ultrasonic welding for seal
- Battery tab-welded
- Conformal coating on PCB

### Testing Points

- Programming header (pogo pins)
- Battery test point
- BLE/UWB test point

---

## 7. REGULATORY

### Certifications Required

- FCC (USA) — BLE + UWB emissions
- CE (EU) — EMC compliance
- RoHS — hazardous materials
- UN38.3 — lithium battery transport

### Safety

- No sharp edges
- Rounded corners (2mm radius)
- Battery protection circuit
- Thermal cutoff

---

## 8. PACKAGING

### Retail Box

- Glove-clip pair
- Charging dock
- USB-C cable
- Quick start guide
- Carrying pouch

### Dimensions

- 150 × 100 × 50 mm
- Weight: < 200g total

---

_Vault Document — March 2026_

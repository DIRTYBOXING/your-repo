# 🔒 DFC ATLAS MODEL TRAINING PLAN — VAULT DOCUMENT

> **STATUS: FUTURE TECH — DO NOT BUILD**  
> This is a conceptual engineering spec, not an active development target.

---

# 🧬 ATLAS AI MODEL TRAINING PLAN v1.0

## 1. MODELS REQUIRED

### Model 1: Punch Classification

- **Architecture:** CNN + LSTM
- **Input:** IMU sequences (200 samples = 1 second)
- **Output:** Punch type (6 classes)
  - Jab
  - Cross
  - Lead Hook
  - Rear Hook
  - Lead Uppercut
  - Rear Uppercut
  - Overhand
- **Confidence threshold:** 85%

### Model 2: Punch Speed Estimation

- **Architecture:** Regression (MLP or XGBoost)
- **Input:** Acceleration curve features
  - Peak acceleration
  - Time to peak
  - Integral (impulse)
  - Gyroscope rotation
- **Output:** Peak velocity (m/s)
- **Target accuracy:** ±0.5 m/s

### Model 3: Punch Force Estimation

- **Architecture:** Regression ensemble
- **Input:**
  - Piezo sensor peak
  - Piezo impulse
  - IMU velocity estimate
  - Punch type
- **Output:** Estimated force (N)
- **Target accuracy:** ±15%

### Model 4: Impact Classification

- **Architecture:** CNN (1D convolution)
- **Input:** Headgear IMU burst (100ms window)
- **Output:** Impact class
  - Clean hit (full scoring)
  - Graze (partial)
  - Near miss (no score)
  - Blocked (no score)
- **Confidence threshold:** 80%

### Model 5: Distance Scoring

- **Architecture:** Rule-based + ML refinement
- **Input:** UWB distance + velocity
- **Output:**
  - Distance class
  - Score multiplier
  - Contact confidence

### Model 6: Fight IQ Score

- **Architecture:** Gradient boosting (XGBoost)
- **Input:** Session aggregates
  - Punch variety
  - Combination frequency
  - Defense rate
  - Counter-punch ratio
  - Distance management
  - Output efficiency
- **Output:** IQ score (0-100)

### Model 7: Fatigue Detection

- **Architecture:** Time-series regression
- **Input:** Round-by-round metrics
  - Punch speed decay
  - Volume decline
  - Recovery time increase
- **Output:** Fatigue index (0-100)

---

## 2. DATASET REQUIREMENTS

### Minimum Dataset Size

| Data Type       | Minimum | Target  |
| --------------- | ------- | ------- |
| Fighters        | 50      | 200     |
| Total punches   | 10,000  | 100,000 |
| Labeled punches | 5,000   | 50,000  |
| Sparring rounds | 500     | 5,000   |
| Head impacts    | 1,000   | 10,000  |
| Distance events | 5,000   | 50,000  |

### Fighter Diversity

- Weight classes: 8+ (flyweight to heavyweight)
- Styles: Orthodox, Southpaw, Switch
- Skill levels: Beginner, Intermediate, Pro
- Disciplines: Boxing, Muay Thai, MMA, Kickboxing

### Collection Protocol

```
1. Equip fighter with calibrated sensors
2. Record 3-minute rounds (pad work + sparring)
3. Video sync for ground truth
4. Coach labels punch types
5. Force plate validation (subset)
```

---

## 3. LABELING PROTOCOL

### Punch Labels

| Field   | Values                                                             |
| ------- | ------------------------------------------------------------------ |
| Type    | jab, cross, hook_lead, hook_rear, upper_lead, upper_rear, overhand |
| Hand    | left, right                                                        |
| Power   | light, medium, full                                                |
| Target  | head, body                                                         |
| Landed  | true, false                                                        |
| Quality | clean, partial, blocked                                            |

### Impact Labels

| Field    | Values                          |
| -------- | ------------------------------- |
| Location | front, side, back, top          |
| Type     | punch, kick, elbow, knee, clash |
| Severity | light, medium, heavy            |
| Clean    | true, false                     |

### Labeling Tools

- CVAT for video annotation
- Custom IMU labeling interface
- Coach review dashboard

---

## 4. TRAINING PIPELINE

### Step 1 — Data Preprocessing

```
- Resample to uniform 200 Hz
- Apply Madgwick orientation filter
- Segment punch windows (500ms)
- Extract features
- Normalize per-fighter
```

### Step 2 — Train/Val/Test Split

```
- Train: 70%
- Validation: 15%
- Test: 15%
- Split by fighter (no leakage)
```

### Step 3 — Model Training

```
- Hyperparameter search (Optuna)
- Cross-validation (5-fold)
- Early stopping on val loss
- Ensemble for production
```

### Step 4 — Calibration

```
- Temperature scaling
- Platt calibration
- Confidence thresholding
```

### Step 5 — Edge Deployment

```
- Quantize to INT8 (TFLite)
- Optimize for nRF52840
- On-device inference
- Cloud fallback
```

---

## 5. VALIDATION PROTOCOL

### Lab Validation

- Force plate ground truth
- High-speed camera (1000 fps)
- Motion capture correlation
- N=20 fighters minimum

### Field Validation

- Gym deployment (5 gyms)
- Coach feedback loop
- A/B testing vs. legacy
- User satisfaction survey

### Metrics

| Model                 | Metric      | Target   |
| --------------------- | ----------- | -------- |
| Punch Classification  | Accuracy    | >90%     |
| Speed Estimation      | MAE         | <0.5 m/s |
| Force Estimation      | MAPE        | <15%     |
| Impact Classification | F1          | >0.85    |
| Fight IQ              | Correlation | >0.8     |

---

## 6. CONTINUOUS LEARNING

### Data Flywheel

```
1. Deploy model
2. Collect new data
3. Flag uncertain predictions
4. Coach review queue
5. Add to training set
6. Retrain monthly
```

### Model Versioning

- Semantic versioning (v1.0.0)
- A/B testing new versions
- Rollback capability
- Performance monitoring

---

## 7. COMPUTE REQUIREMENTS

### Training

- GPU: NVIDIA A100 or equivalent
- Time: ~4 hours per model
- Storage: 500GB dataset

### Inference (Edge)

- CPU: ARM Cortex-M4 (nRF52840)
- RAM: 256 KB
- Latency: <50ms per prediction

### Inference (Cloud)

- Serverless (Cloud Functions)
- Batch processing
- Real-time API fallback

---

_Vault Document — March 2026_

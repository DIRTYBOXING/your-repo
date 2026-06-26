# 🔒 DFC GLOVE-CLIP FIRMWARE SPECIFICATION — VAULT DOCUMENT

> **STATUS: FUTURE TECH — DO NOT BUILD**  
> This is a conceptual engineering spec, not an active development target.

---

# 📋 FIRMWARE SPECIFICATION v1.0

## 1. TARGET HARDWARE

### Microcontroller

- **Primary:** Nordic nRF52840
- **Alternative:** ESP32-C3
- Clock: 64 MHz
- RAM: 256 KB
- Flash: 1 MB
- BLE 5.0 + Thread

### IMU

- **Primary:** TDK ICM-42688-P
- **Alternative:** ICM-20948 / MPU-9250
- 6-axis (accel + gyro)
- Sampling: 100-200 Hz
- Shock tolerance: 10,000g

### Impact Sensor

- Piezoelectric film sensor
- Sampling: 500-1000 Hz
- Sensitivity: 0.1N resolution

### Battery

- 150-200 mAh LiPo
- 3.7V nominal
- Runtime: 6-10 hours
- Charge time: 1.5 hours

---

## 2. FIRMWARE ARCHITECTURE

### Language

- C/C++ (bare metal)
- Nordic nRF5 SDK / Zephyr RTOS

### Core Modules

#### A. Sensor Fusion Module

```
- Madgwick or Mahony filter
- Quaternion orientation
- 100-200 Hz update rate
- Gravity compensation
- Drift correction
```

#### B. Punch Detection Module

```
- Acceleration threshold detection
- Angular velocity validation
- Peak extraction
- Punch classification (jab/cross/hook/uppercut)
- Debounce logic (150ms minimum)
```

#### C. Impact Analysis Module

```
- Peak force extraction
- Impulse calculation
- Contact time measurement
- Force curve analysis
```

#### D. BLE Communication Module

```
- GATT server implementation
- Custom characteristics
- 20-50 Hz data streaming
- Packet batching
- Connection management
```

#### E. Power Management Module

```
- Deep sleep mode
- Dynamic sampling rate
- Battery telemetry
- Low battery alerts
- Charge detection
```

#### F. OTA Update Module

```
- DFU bootloader
- Secure firmware updates
- Version management
- Rollback capability
```

---

## 3. DEVICE STATE MACHINE

```
STATES:
- IDLE (deep sleep)
- PAIRING (BLE advertising)
- CONNECTED (streaming)
- RECORDING (local storage)
- CHARGING
- OTA_UPDATE
- ERROR

TRANSITIONS:
- IDLE → PAIRING (button press / motion detect)
- PAIRING → CONNECTED (BLE connection)
- CONNECTED → RECORDING (session start)
- RECORDING → CONNECTED (session end)
- ANY → CHARGING (charger connected)
- CONNECTED → OTA_UPDATE (update request)
- ANY → ERROR (fault detected)
- ERROR → IDLE (reset)
```

---

## 4. SAMPLING CONFIGURATION

| Sensor        | Sampling Rate | Buffer Size |
| ------------- | ------------- | ----------- |
| Accelerometer | 200 Hz        | 50 samples  |
| Gyroscope     | 200 Hz        | 50 samples  |
| Impact Sensor | 1000 Hz       | 100 samples |
| Battery       | 1 Hz          | 1 sample    |
| Temperature   | 0.1 Hz        | 1 sample    |

---

## 5. PUNCH DETECTION ALGORITHM

```
1. Read IMU at 200 Hz
2. Apply Madgwick filter
3. Extract forward acceleration vector
4. Detect acceleration spike > 3g
5. Validate angular velocity pattern
6. Check forward vector alignment
7. Start punch window (100ms)
8. Capture peak velocity
9. Wait for impact spike
10. Extract impact force
11. Calculate power estimate
12. Classify punch type
13. Send BLE packet
14. Apply 150ms debounce
```

---

## 6. POWER BUDGET

| Mode             | Current | Duration |
| ---------------- | ------- | -------- |
| Deep Sleep       | 5 µA    | 90%      |
| Active Streaming | 15 mA   | 8%       |
| BLE Transmit     | 25 mA   | 2%       |
| Peak (impact)    | 40 mA   | <0.1%    |

**Estimated battery life:** 8-10 hours active use

---

## 7. ERROR HANDLING

```
- IMU failure: Fallback to reduced mode
- Impact sensor failure: Continue with IMU only
- BLE disconnect: Buffer 60s of data
- Low battery: Reduce sampling rate
- Memory overflow: Circular buffer
- Watchdog timeout: Auto-reset
```

---

## 8. TESTING REQUIREMENTS

- Drop test: 1.5m onto rubber mat (100 cycles)
- Impact test: 500N repeated force (1000 cycles)
- Temperature: -10°C to +50°C operation
- Humidity: 95% RH (non-condensing)
- BLE range: 10m minimum
- Battery cycles: 500+ charge cycles

---

_Vault Document — March 2026_

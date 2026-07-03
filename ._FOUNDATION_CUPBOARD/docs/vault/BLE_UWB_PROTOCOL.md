# 🔒 DFC BLE + UWB PROTOCOL SPECIFICATION — VAULT DOCUMENT

> **STATUS: FUTURE TECH — DO NOT BUILD**  
> This is a conceptual engineering spec, not an active development target.

---

# 📡 BLE + UWB PROTOCOL SPECIFICATION v1.0

## 1. BLE GATT STRUCTURE

### Service: DFC Combat Sensor

**UUID:** `0x1800-DFC0-XXXX-XXXX-XXXXXXXXXXXX`

### Characteristics

| ID     | Name               | Type   | Properties   |
| ------ | ------------------ | ------ | ------------ |
| `0x01` | Punch Event Packet | Notify | Read, Notify |
| `0x02` | IMU Stream         | Notify | Read, Notify |
| `0x03` | Impact Event       | Notify | Read, Notify |
| `0x04` | Distance Event     | Notify | Read, Notify |
| `0x05` | Battery Level      | Read   | Read         |
| `0x06` | Device Info        | Read   | Read         |
| `0x07` | Firmware Version   | Read   | Read         |
| `0x08` | Session Control    | Write  | Write        |
| `0x09` | Calibration        | Write  | Read, Write  |

---

## 2. PACKET STRUCTURES

### Punch Event Packet (20 bytes)

```
[0-3]   Timestamp (uint32, ms)
[4]     HandID (uint8: 0=left, 1=right)
[5]     PunchType (uint8: 0=jab, 1=cross, 2=hook, 3=uppercut, 4=overhand)
[6-7]   Speed (uint16, cm/s)
[8-9]   Force (uint16, N)
[10-11] Angle (int16, degrees × 10)
[12]    Confidence (uint8, 0-100)
[13-19] Reserved
```

### IMU Stream Packet (20 bytes)

```
[0-3]   Timestamp (uint32, ms)
[4-5]   AccelX (int16, mg)
[6-7]   AccelY (int16, mg)
[8-9]   AccelZ (int16, mg)
[10-11] GyroX (int16, deg/s × 10)
[12-13] GyroY (int16, deg/s × 10)
[14-15] GyroZ (int16, deg/s × 10)
[16-19] Reserved
```

### Impact Event Packet (20 bytes)

```
[0-3]   Timestamp (uint32, ms)
[4-5]   ImpactForce (uint16, N)
[6-7]   RotAccelX (int16, rad/s² × 10)
[8-9]   RotAccelY (int16, rad/s² × 10)
[10-11] RotAccelZ (int16, rad/s² × 10)
[12]    Direction (uint8: 0-7 octant)
[13]    Confidence (uint8, 0-100)
[14-19] Reserved
```

### Distance Event Packet (16 bytes)

```
[0-3]   Timestamp (uint32, ms)
[4-5]   DistanceCM (uint16, centimeters)
[6]     Classification (uint8: 0=hit, 1=graze, 2=near, 3=miss)
[7]     Confidence (uint8, 0-100)
[8-9]   VelocityApproach (int16, cm/s)
[10-15] Reserved
```

---

## 3. UWB PROTOCOL

### Hardware

- **Chip:** Decawave DW3000
- **Mode:** Two-Way Ranging (TWR)
- **Frequency:** 6.5 GHz (Channel 5)
- **Data Rate:** 6.8 Mbps

### Ranging Cycle

1. Initiator sends POLL message
2. Responder receives, records RX timestamp
3. Responder sends RESPONSE message
4. Initiator receives, records RX timestamp
5. Distance calculated from time-of-flight

### Sync Protocol

```
1. BLE timestamp sync every 10s
2. UWB ranging at 100 Hz
3. Punch event triggers distance snapshot
4. Distance tagged to punch timestamp
```

### Distance Classification Thresholds

| Distance | Classification | Score       |
| -------- | -------------- | ----------- |
| 0-1 cm   | Clean Hit      | Full points |
| 1-3 cm   | Graze          | Half points |
| 3-10 cm  | Near Miss      | No points   |
| >10 cm   | Miss           | No points   |

---

## 4. MULTI-DEVICE PAIRING

### Device Roles

- **Phone:** Central (coordinator)
- **Left Glove-Clip:** Peripheral
- **Right Glove-Clip:** Peripheral
- **Headgear:** Peripheral

### Pairing Sequence

```
1. Phone scans for DFC devices
2. User pairs left glove (button press)
3. User pairs right glove (button press)
4. User pairs headgear (button press)
5. Phone assigns device IDs
6. Devices store pairing info
7. Auto-reconnect on power-on
```

### Multi-Device Stream

```
Phone receives:
- L glove IMU @ 50 Hz
- R glove IMU @ 50 Hz
- L glove punches (event-driven)
- R glove punches (event-driven)
- Headgear impacts (event-driven)
- UWB distance (event-driven)
```

---

## 5. ERROR HANDLING

### Connection Loss

- Buffer 60s of data locally
- Attempt reconnect every 5s
- Resume streaming on reconnect
- Flag data with connection gaps

### Timestamp Drift

- Re-sync every 10s
- Drift correction algorithm
- Maximum acceptable drift: 10ms

### Packet Loss

- Sequence numbers in packets
- Gap detection on phone
- Request retransmit (critical events only)

---

## 6. POWER OPTIMIZATION

### Adaptive Streaming

| Activity | IMU Rate | UWB Rate |
| -------- | -------- | -------- |
| Idle     | 10 Hz    | Off      |
| Warm-up  | 50 Hz    | Off      |
| Sparring | 200 Hz   | 100 Hz   |
| Event    | 200 Hz   | 100 Hz   |

### Sleep Modes

- No activity 30s → reduce sampling
- No activity 5m → deep sleep
- Motion detect → wake up

---

## 7. SECURITY

### Pairing

- BLE Secure Connections (LE Secure)
- 128-bit AES encryption
- Device whitelist

### Data Protection

- Encrypted BLE link
- No PII in packets
- Session IDs only

---

_Vault Document — March 2026_

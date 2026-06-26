# DFC Safety Device Onboarding Checklist

## Pre-Event Setup

- [ ] Register device serial numbers in safety system
- [ ] Assign devices to participant roster
- [ ] Verify HMAC_SECRET is configured on Cloud Run
- [ ] Verify ONCALL_SMS numbers are correct
- [ ] Test device → webhook → SMS alert chain end-to-end
- [ ] Print and distribute device consent forms

## Event Day

- [ ] Charge all devices to 100%
- [ ] Issue devices to registered participants
- [ ] Collect signed consent forms (docs/legal/device_consent.txt)
- [ ] Activate geofence zones in Radar dashboard
- [ ] Confirm safety webhook is live (GET /health returns ok)
- [ ] Verify on-call team receives test alert SMS
- [ ] Brief medical personnel on alert escalation procedure

## During Event

- [ ] Monitor safety dashboard for alerts
- [ ] Respond to CRITICAL alerts within 60 seconds
- [ ] Log all incidents manually in addition to auto-logs
- [ ] Replace low-battery devices as alerts come in

## Post-Event

- [ ] Collect all devices from participants
- [ ] Download safety logs from docs/legal/safety_logs/
- [ ] Review all CRITICAL and HIGH alerts
- [ ] File incident reports for any SOS or fall detections
- [ ] Deactivate geofence zones in Radar dashboard
- [ ] Archive signed consent forms in docs/legal/consents/

#ifndef EVENTS_H
#define EVENTS_H

typedef struct {
  char deviceId[32];
  char ts[32];       /* ISO8601 UTC timestamp */
  char nid[40];      /* nonce UUID v4 */
  float d;           /* distance in metres */
  int dir;           /* direction in degrees 0-359 */
  char sig[16];      /* signal type: panic, auto_proximity, heartbeat, tamper */
  int bat;           /* battery percent 0-100 */
} event_t;

#endif /* EVENTS_H */

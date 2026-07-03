#ifndef CBOR_ENCODER_H
#define CBOR_ENCODER_H

#include <stddef.h>
#include <stdint.h>
#include "events.h"

/**
 * Encode an event_t into CBOR using integer keys per CHUCKYA schema:
 *   1:id, 2:ts, 3:nid, 4:d, 5:dir, 6:sig, 7:bat
 *
 * Returns number of bytes written to out buffer.
 */
size_t cbor_encode_event(const event_t *ev, uint8_t *out, size_t out_len);

#endif /* CBOR_ENCODER_H */

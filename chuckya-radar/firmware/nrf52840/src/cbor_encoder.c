/*
 * CHUCKYA Bracelet — CBOR Encoder
 * Encodes event_t into CBOR using integer keys per schema:
 *   1:id, 2:ts, 3:nid, 4:d, 5:dir, 6:sig, 7:bat
 */

#include "cbor_encoder.h"
#include <tinycbor/cbor.h>
#include <string.h>

size_t cbor_encode_event(const event_t *ev, uint8_t *out, size_t out_len) {
    CborEncoder encoder, map;
    cbor_encoder_init(&encoder, out, out_len, 0);

    /* Count fields: 6 required + bat if > 0 */
    int field_count = 6;
    if (ev->bat > 0) field_count = 7;

    cbor_encoder_create_map(&encoder, &map, field_count);

    /* 1: deviceId */
    cbor_encode_int(&map, 1);
    cbor_encode_text_stringz(&map, ev->deviceId);

    /* 2: timestamp */
    cbor_encode_int(&map, 2);
    cbor_encode_text_stringz(&map, ev->ts);

    /* 3: nonce */
    cbor_encode_int(&map, 3);
    cbor_encode_text_stringz(&map, ev->nid);

    /* 4: distance (float) */
    cbor_encode_int(&map, 4);
    cbor_encode_float(&map, ev->d);

    /* 5: direction (int) */
    cbor_encode_int(&map, 5);
    cbor_encode_int(&map, ev->dir);

    /* 6: signal type */
    cbor_encode_int(&map, 6);
    cbor_encode_text_stringz(&map, ev->sig);

    /* 7: battery (optional) */
    if (ev->bat > 0) {
        cbor_encode_int(&map, 7);
        cbor_encode_int(&map, ev->bat);
    }

    cbor_encoder_close_container(&encoder, &map);
    return cbor_encoder_get_buffer_size(&encoder, out);
}

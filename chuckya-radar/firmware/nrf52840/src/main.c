/*
 * CHUCKYA Bracelet Firmware — Main
 * Target: nRF52840 with Zephyr RTOS
 * Handles button press, periodic UWB scan, BLE event dispatch
 */

#include <zephyr/kernel.h>
#include <zephyr/sys/printk.h>
#include <zephyr/drivers/gpio.h>
#include <string.h>

#include "ble_service.h"
#include "uwb.h"
#include "cbor_encoder.h"
#include "config.h"
#include "events.h"

/* ─── Event buffer (circular) ─── */
static event_t buffer[BUFFER_SIZE];
static int buf_head = 0;

/* ─── Stubs for timestamp and UUID generation ─── */
static void get_iso_ts(char *buf, size_t len) {
    /* In production: read RTC and format ISO8601 */
    strncpy(buf, "2026-03-28T00:00:00Z", len);
}

static void generate_uuid(char *buf, size_t len) {
    /* In production: use hardware RNG for UUID v4 */
    strncpy(buf, "00000000-0000-4000-8000-000000000000", len);
}

static void indicate_local_alert(void) {
    /* Vibrate motor, blink LED, short beep */
    printk("!! LOCAL ALERT: vibrate + LED + beep\n");
}

/* ─── Button init (GPIO interrupt) ─── */
static const struct gpio_dt_spec button = GPIO_DT_SPEC_GET(DT_ALIAS(sw0), gpios);
static struct gpio_callback button_cb_data;
static int64_t last_press_time = 0;

/* ─── Send raw event to phone or buffer ─── */
static void send_raw_event(event_t *ev) {
    uint8_t cbor_buf[128];
    size_t len = cbor_encode_event(ev, cbor_buf, sizeof(cbor_buf));
    if (ble_is_connected()) {
        ble_notify_raw(cbor_buf, len);
    } else {
        buffer[buf_head] = *ev;
        buf_head = (buf_head + 1) % BUFFER_SIZE;
    }
}

/* ─── Button press handler (panic) ─── */
static void button_handler(const struct device *port, struct gpio_callback *cb, uint32_t pins) {
    int64_t now = k_uptime_get();
    if ((now - last_press_time) < PANIC_DEBOUNCE_MS) {
        return; /* debounce */
    }
    last_press_time = now;

    event_t ev = {0};
    strncpy(ev.deviceId, DEVICE_ID, sizeof(ev.deviceId));
    get_iso_ts(ev.ts, sizeof(ev.ts));
    generate_uuid(ev.nid, sizeof(ev.nid));
    ev.d = uwb_measure_distance();
    ev.dir = uwb_estimate_direction();
    strncpy(ev.sig, "panic", sizeof(ev.sig));

    send_raw_event(&ev);
    indicate_local_alert();

    printk("PANIC event sent: d=%.1f dir=%d\n", (double)ev.d, ev.dir);
}

static void button_init(void) {
    if (!gpio_is_ready_dt(&button)) {
        printk("Button GPIO not ready\n");
        return;
    }
    gpio_pin_configure_dt(&button, GPIO_INPUT);
    gpio_pin_interrupt_configure_dt(&button, GPIO_INT_EDGE_TO_ACTIVE);
    gpio_init_callback(&button_cb_data, button_handler, BIT(button.pin));
    gpio_add_callback(button.port, &button_cb_data);
}

/* ─── Periodic proximity scan ─── */
static void periodic_scan(void) {
    float distance = uwb_measure_distance();
    if (distance < AUTO_THRESHOLD_M && distance > 0.0f) {
        event_t ev = {0};
        strncpy(ev.deviceId, DEVICE_ID, sizeof(ev.deviceId));
        get_iso_ts(ev.ts, sizeof(ev.ts));
        generate_uuid(ev.nid, sizeof(ev.nid));
        ev.d = distance;
        ev.dir = uwb_estimate_direction();
        strncpy(ev.sig, "auto_proximity", sizeof(ev.sig));

        send_raw_event(&ev);
        printk("AUTO_PROXIMITY event: d=%.1f dir=%d\n", (double)ev.d, ev.dir);
    }
}

/* ─── Main ─── */
int main(void) {
    printk("╔══════════════════════════════════════╗\n");
    printk("║  CHUCKYA Bracelet v0.1.0             ║\n");
    printk("║  DataFightCentral — Safety Wearable  ║\n");
    printk("╚══════════════════════════════════════╝\n");

    ble_init();
    uwb_init();
    button_init();

    printk("Bracelet ready. Advertising as CHUCKYA-%s\n", DEVICE_ID);

    int scan_counter = 0;
    while (1) {
        k_sleep(K_MSEC(1000));
        scan_counter += 1000;

        if (scan_counter >= SCAN_INTERVAL_MS) {
            periodic_scan();
            scan_counter = 0;
        }
    }
    return 0;
}

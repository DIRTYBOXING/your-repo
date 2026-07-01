/*
 * CHUCKYA Bracelet — BLE GATT Service
 * Registers CHUCKYA service with Raw Proximity and Pairing Code characteristics.
 */

#include "ble_service.h"
#include "config.h"

#include <zephyr/bluetooth/bluetooth.h>
#include <zephyr/bluetooth/gatt.h>
#include <zephyr/sys/printk.h>
#include <string.h>

static struct bt_conn *current_conn;

/* ─── Pairing Code characteristic ─── */
static ssize_t read_pair(struct bt_conn *conn, const struct bt_gatt_attr *attr,
                         void *buf, uint16_t len, uint16_t offset) {
    /* In production: generate random 6-digit code and display on device */
    const char *pair_code = "123456";
    return bt_gatt_attr_read(conn, attr, buf, len, offset, pair_code, strlen(pair_code));
}

static ssize_t write_pair(struct bt_conn *conn, const struct bt_gatt_attr *attr,
                          const void *buf, uint16_t len, uint16_t offset, uint8_t flags) {
    /* Accept confirmation token from phone to finalize pairing */
    printk("Pairing confirmation received (%d bytes)\n", len);
    return len;
}

/* ─── GATT Service Definition ─── */
BT_GATT_SERVICE_DEFINE(chuckya_svc,
    BT_GATT_PRIMARY_SERVICE(BT_UUID_DECLARE_128(CHUCKYA_SERVICE_UUID)),

    /* Raw Proximity — Notify only (phone subscribes) */
    BT_GATT_CHARACTERISTIC(BT_UUID_DECLARE_128(CHAR_RAW_UUID),
                           BT_GATT_CHRC_NOTIFY,
                           BT_GATT_PERM_NONE,
                           NULL, NULL, NULL),
    BT_GATT_CCC(NULL, BT_GATT_PERM_READ | BT_GATT_PERM_WRITE),

    /* Pairing Code — Read (display code) + Write (confirm from phone) */
    BT_GATT_CHARACTERISTIC(BT_UUID_DECLARE_128(CHAR_PAIR_UUID),
                           BT_GATT_CHRC_READ | BT_GATT_CHRC_WRITE,
                           BT_GATT_PERM_READ | BT_GATT_PERM_WRITE,
                           read_pair, write_pair, NULL),
);

/* ─── Connection callbacks ─── */
static void connected(struct bt_conn *conn, uint8_t err) {
    if (err) {
        printk("BLE connection failed (err %u)\n", err);
        return;
    }
    current_conn = bt_conn_ref(conn);
    printk("BLE connected\n");
}

static void disconnected(struct bt_conn *conn, uint8_t reason) {
    printk("BLE disconnected (reason %u)\n", reason);
    if (current_conn) {
        bt_conn_unref(current_conn);
        current_conn = NULL;
    }
}

BT_CONN_CB_DEFINE(conn_callbacks) = {
    .connected = connected,
    .disconnected = disconnected,
};

/* ─── Advertising data ─── */
static const struct bt_data ad[] = {
    BT_DATA_BYTES(BT_DATA_FLAGS, (BT_LE_AD_GENERAL | BT_LE_AD_NO_BREDR)),
    BT_DATA_BYTES(BT_DATA_UUID128_ALL, CHUCKYA_SERVICE_UUID),
};

static const struct bt_data sd[] = {
    BT_DATA(BT_DATA_NAME_COMPLETE, "CHUCKYA-" DEVICE_ID, sizeof("CHUCKYA-" DEVICE_ID) - 1),
};

void start_advertising(void) {
    int err = bt_le_adv_start(BT_LE_ADV_CONN, ad, ARRAY_SIZE(ad), sd, ARRAY_SIZE(sd));
    if (err) {
        printk("Advertising start failed (err %d)\n", err);
    }
}

/* ─── Init ─── */
void ble_init(void) {
    int err = bt_enable(NULL);
    if (err) {
        printk("Bluetooth init failed (err %d)\n", err);
        return;
    }
    printk("Bluetooth initialized\n");
    start_advertising();
}

void ble_notify_raw(uint8_t *data, size_t len) {
    if (!current_conn) return;
    bt_gatt_notify(NULL, &chuckya_svc.attrs[2], data, len);
}

bool ble_is_connected(void) {
    return current_conn != NULL;
}

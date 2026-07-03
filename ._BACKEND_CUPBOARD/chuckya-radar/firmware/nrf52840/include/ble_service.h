#ifndef BLE_SERVICE_H
#define BLE_SERVICE_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

void ble_init(void);
void ble_notify_raw(uint8_t *data, size_t len);
bool ble_is_connected(void);
void start_advertising(void);

#endif /* BLE_SERVICE_H */

/*
 * CHUCKYA Bracelet — UWB Module
 * Stub implementation for testing without hardware.
 * Replace with Qorvo DW3000 or Decawave DWM3000 driver in production.
 */

#include "uwb.h"
#include <zephyr/sys/printk.h>

void uwb_init(void) {
    printk("UWB module initialized (stub)\n");
    /* In production:
     * - Initialize SPI to DW3000
     * - Configure ranging mode (TWR or TDoA)
     * - Set channel and preamble
     */
}

float uwb_measure_distance(void) {
    /* In production: perform two-way ranging and return distance in metres */
    return 6.2f; /* synthetic value for testing */
}

int uwb_estimate_direction(void) {
    /* In production: use PDoA (Phase Difference of Arrival) for angle */
    return 270; /* synthetic bearing for testing */
}

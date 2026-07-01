package com.dfc.chuckya

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.content.Context
import com.upokecenter.cbor.CBORObject
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.util.*

class BleManager(private val ctx: Context, private val onStatus: (String)->Unit = {}) {
  private val adapter = BluetoothAdapter.getDefaultAdapter()
  private var gatt: BluetoothGatt? = null
  private val scope = CoroutineScope(Dispatchers.IO)

  companion object {
    val SERVICE_UUID = UUID.fromString("0000CCHK-0000-1000-8000-00805F9B34FB")
    val CHAR_RAW = UUID.fromString("0000C001-0000-1000-8000-00805F9B34FB")
    val CHAR_PAIR = UUID.fromString("0000C002-0000-1000-8000-00805F9B34FB")
  }

  fun scanAndConnect() {
    val scanner = adapter.bluetoothLeScanner
    scanner.startScan(object : ScanCallback() {
      override fun onScanResult(callbackType: Int, result: ScanResult) {
        val name = result.device.name ?: ""
        if (name.startsWith("CHUCKYA-")) {
          scanner.stopScan(this)
          onStatus("Found ${name}, connecting")
          result.device.connectGatt(ctx, false, object : BluetoothGattCallback() {
            override fun onConnectionStateChange(g: BluetoothGatt, status: Int, newState: Int) {
              if (newState == android.bluetooth.BluetoothProfile.STATE_CONNECTED) {
                g.discoverServices()
              } else if (newState == android.bluetooth.BluetoothProfile.STATE_DISCONNECTED) {
                onStatus("Disconnected")
              }
            }
            override fun onServicesDiscovered(g: BluetoothGatt, status: Int) {
              gatt = g
              subscribeRaw(g)
              onStatus("Paired and subscribed")
            }
            override fun onCharacteristicChanged(g: BluetoothGatt, characteristic: BluetoothGattCharacteristic) {
              if (characteristic.uuid == CHAR_RAW) {
                val data = characteristic.value
                scope.launch { handleRawNotification(data) }
              }
            }
          })
        }
      }
    })
  }

  private fun subscribeRaw(g: BluetoothGatt) {
    val svc = g.getService(SERVICE_UUID) ?: return
    val char = svc.getCharacteristic(CHAR_RAW) ?: return
    g.setCharacteristicNotification(char, true)
    // CCC descriptor write omitted for brevity — required in production
  }

  private suspend fun handleRawNotification(data: ByteArray) {
    try {
      val obj = CBORObject.DecodeFromBytes(data)
      val event = mapOf(
        "id" to obj.get(1).AsString(),
        "ts" to obj.get(2).AsString(),
        "nid" to obj.get(3).AsString(),
        "d" to obj.get(4).AsDouble(),
        "dir" to obj.get(5).AsInt32(),
        "sig" to obj.get(6).AsString()
      )
      SigningService.signAndUpload(ctx, event)
    } catch (e: Exception) {
      onStatus("CBOR decode error: ${e.message}")
    }
  }

  fun close() { gatt?.disconnect(); gatt?.close() }
}

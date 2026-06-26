package com.dfc.chuckya

import android.os.Bundle
import android.widget.Button
import android.widget.ListView
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import kotlinx.coroutines.MainScope

class MainActivity : AppCompatActivity() {
  private val scope = MainScope()
  private lateinit var bleManager: BleManager
  private lateinit var statusView: TextView
  private lateinit var deviceList: ListView

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    setContentView(R.layout.activity_main)
    statusView = findViewById(R.id.status)
    deviceList = findViewById(R.id.deviceList)
    bleManager = BleManager(this) { updateStatus(it) }

    findViewById<Button>(R.id.btnPair).setOnClickListener {
      updateStatus("Scanning for bracelets...")
      bleManager.scanAndConnect()
    }
  }

  private fun updateStatus(text: String) {
    runOnUiThread { statusView.text = "Status: $text" }
  }

  override fun onDestroy() {
    super.onDestroy()
    bleManager.close()
  }
}

// TelemetryConsentActivity.kt
// CHUCKYA Safety Radar — Android companion app
// Collects explicit consent, signs telemetry with Android Keystore, sends to staging backend.
package com.datafightcentral.chuckya

import android.os.Bundle
import android.util.Base64
import android.util.Log
import android.widget.Button
import android.widget.CheckBox
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import org.json.JSONObject
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.Signature
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import java.util.concurrent.TimeUnit

class TelemetryConsentActivity : AppCompatActivity() {
    companion object {
        private const val TAG = "ChuckyaTelemetry"
        private const val KEY_ALIAS = "chuckya_demo_key"
    }

    // Replace with your Cloud Run staging URL or ngrok URL
    private val backendUrl: String
        get() = BuildConfig.CHUCKYA_BACKEND_URL.ifEmpty { "https://REPLACE_WITH_STAGING_URL" }

    private val httpClient = OkHttpClient.Builder()
        .connectTimeout(15, TimeUnit.SECONDS)
        .readTimeout(15, TimeUnit.SECONDS)
        .build()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_consent)

        val cbAppId = findViewById<CheckBox>(R.id.consent_appid)
        val cbImei = findViewById<CheckBox>(R.id.consent_imei)
        val cbLoc = findViewById<CheckBox>(R.id.consent_location)
        val btn = findViewById<Button>(R.id.agreeButton)

        // App Instance ID consent is required and always checked
        cbAppId.isChecked = true
        cbAppId.isEnabled = false

        ensureKeyPairExists()

        btn.setOnClickListener {
            Thread {
                try {
                    // 1. Build and store consent record
                    val consent = JSONObject().apply {
                        put("appInstanceId", getAppInstanceId())
                        put("appInstanceIdConsent", true)
                        put("imeiConsent", cbImei.isChecked)
                        put("locationConsent", cbLoc.isChecked)
                        put("timestamp", java.time.Instant.now().toString())
                    }
                    uploadConsent(consent)

                    // 2. Build telemetry payload
                    val payload = JSONObject().apply {
                        put("source", "device_app")
                        put("appInstanceId", getAppInstanceId())
                        put("timestamp", java.time.Instant.now().toString())
                        put("type", "manual_scan")
                        put("riskScore", 95)
                        put("topSignals", org.json.JSONArray().put("manual_ping"))
                        put("notes", "demo ping from Android device")
                    }

                    if (cbImei.isChecked) {
                        val imei = getDeviceImeiOrNull()
                        if (imei != null) payload.put("imei", imei)
                    }

                    if (cbLoc.isChecked) {
                        val loc = getLastKnownLocationOrNull()
                        if (loc != null) payload.put("location", loc)
                    }

                    // 3. Sign payload with device key
                    val signature = signPayload(payload.toString())
                    payload.put("signatureJwt", signature)

                    // 4. Send to backend
                    val success = postTelemetry(payload.toString())

                    runOnUiThread {
                        if (success) {
                            Toast.makeText(this, "Ping sent successfully!", Toast.LENGTH_LONG).show()
                        } else {
                            Toast.makeText(this, "Failed to send ping. Check logs.", Toast.LENGTH_LONG).show()
                        }
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error sending telemetry", e)
                    runOnUiThread {
                        Toast.makeText(this, "Error: ${e.message}", Toast.LENGTH_LONG).show()
                    }
                }
            }.start()
        }
    }

    private fun ensureKeyPairExists() {
        val ks = KeyStore.getInstance("AndroidKeyStore")
        ks.load(null)
        if (!ks.containsAlias(KEY_ALIAS)) {
            val kpg = KeyPairGenerator.getInstance("RSA", "AndroidKeyStore")
            val spec = android.security.keystore.KeyGenParameterSpec.Builder(
                KEY_ALIAS,
                android.security.keystore.KeyProperties.PURPOSE_SIGN or
                    android.security.keystore.KeyProperties.PURPOSE_VERIFY
            )
                .setDigests(android.security.keystore.KeyProperties.DIGEST_SHA256)
                .setSignaturePaddings(android.security.keystore.KeyProperties.SIGNATURE_PADDING_RSA_PKCS1)
                .setKeySize(2048)
                .build()
            kpg.initialize(spec)
            kpg.generateKeyPair()
            Log.i(TAG, "Generated new RSA keypair in AndroidKeyStore")
            // Register public key with backend
            uploadPublicKey()
        }
    }

    private fun uploadPublicKey() {
        try {
            val ks = KeyStore.getInstance("AndroidKeyStore")
            ks.load(null)
            val entry = ks.getEntry(KEY_ALIAS, null) as KeyStore.PrivateKeyEntry
            val pubBytes = entry.certificate.publicKey.encoded
            val pubB64 = Base64.encodeToString(pubBytes, Base64.NO_WRAP)

            val json = JSONObject().apply {
                put("appInstanceId", getAppInstanceId())
                put("publicKey", pubB64)
            }

            val req = Request.Builder()
                .url("$backendUrl/v1/device/registerPublicKey")
                .post(json.toString().toRequestBody("application/json".toMediaType()))
                .build()

            httpClient.newCall(req).execute().use { resp ->
                if (resp.isSuccessful) {
                    Log.i(TAG, "Public key registered with backend")
                } else {
                    Log.w(TAG, "Public key registration failed: ${resp.code}")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to upload public key", e)
        }
    }

    private fun uploadConsent(consent: JSONObject) {
        try {
            val req = Request.Builder()
                .url("$backendUrl/v1/device/consent")
                .post(consent.toString().toRequestBody("application/json".toMediaType()))
                .build()

            httpClient.newCall(req).execute().use { resp ->
                Log.i(TAG, "Consent upload: ${resp.code}")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to upload consent", e)
        }
    }

    private fun signPayload(payload: String): String {
        val ks = KeyStore.getInstance("AndroidKeyStore")
        ks.load(null)
        val entry = ks.getEntry(KEY_ALIAS, null) as KeyStore.PrivateKeyEntry
        val sig = Signature.getInstance("SHA256withRSA")
        sig.initSign(entry.privateKey)
        sig.update(payload.toByteArray(Charsets.UTF_8))
        return Base64.encodeToString(sig.sign(), Base64.NO_WRAP)
    }

    private fun postTelemetry(jsonPayload: String): Boolean {
        val req = Request.Builder()
            .url("$backendUrl/v1/radar/event")
            .post(jsonPayload.toRequestBody("application/json".toMediaType()))
            .build()

        return httpClient.newCall(req).execute().use { resp ->
            Log.i(TAG, "Telemetry POST response: ${resp.code}")
            resp.isSuccessful
        }
    }

    // --- Helper stubs ---

    private fun getAppInstanceId(): String {
        return android.provider.Settings.Secure.getString(
            contentResolver,
            android.provider.Settings.Secure.ANDROID_ID
        )
    }

    // Requires READ_PHONE_STATE permission + runtime grant. Returns null if not available.
    private fun getDeviceImeiOrNull(): String? {
        // Implementation requires TelephonyManager and runtime permission check.
        // Only collect if user explicitly consented via the checkbox.
        return null
    }

    // Requires ACCESS_FINE_LOCATION permission + runtime grant. Returns null if not available.
    private fun getLastKnownLocationOrNull(): JSONObject? {
        // Implementation requires FusedLocationProviderClient and runtime permission check.
        // Only collect if user explicitly consented via the checkbox.
        return null
    }
}

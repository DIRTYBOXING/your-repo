package com.dfc.chuckya

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.Signature
import java.util.*
import kotlinx.coroutines.*
import org.json.JSONObject

object SigningService {
  private const val KEY_ALIAS = "chuckya_key"

  private fun ensureKey() {
    val ks = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
    if (!ks.containsAlias(KEY_ALIAS)) {
      val kpg = KeyPairGenerator.getInstance(KeyProperties.KEY_ALGORITHM_RSA, "AndroidKeyStore")
      val spec = KeyGenParameterSpec.Builder(KEY_ALIAS, KeyProperties.PURPOSE_SIGN)
        .setDigests(KeyProperties.DIGEST_SHA256)
        .setSignaturePaddings(KeyProperties.SIGNATURE_PADDING_RSA_PKCS1)
        .setUserAuthenticationRequired(false)
        .build()
      kpg.initialize(spec)
      kpg.generateKeyPair()
    }
  }

  fun signAndUpload(ctx: Context, event: Map<String,Any>) {
    ensureKey()
    CoroutineScope(Dispatchers.IO).launch {
      val payload = mutableMapOf<String,Any>(
        "appInstanceId" to BuildConfig.APPLICATION_ID,
        "timestamp" to event["ts"]!!,
        "nonce" to event["nid"]!!,
        "mode" to if (event["sig"]=="panic") "code_black" else "amber",
        "proximity" to mapOf("distance_m" to event["d"], "direction_deg" to event["dir"]),
        "signals" to listOf(event["sig"]),
        "consent" to mapOf("location" to false, "imei" to false)
      )
      val canonical = Canonical.canonicalize(payload)
      val signature = sign(canonical.toByteArray(Charsets.UTF_8))
      payload["signatureBase64"] = android.util.Base64.encodeToString(signature, android.util.Base64.NO_WRAP)
      UploadService.upload(ctx, payload)
    }
  }

  private fun sign(data: ByteArray): ByteArray {
    val ks = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
    val priv = ks.getKey(KEY_ALIAS, null)
    val sig = Signature.getInstance("SHA256withRSA")
    sig.initSign(priv as java.security.PrivateKey)
    sig.update(data)
    return sig.sign()
  }
}

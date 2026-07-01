package com.dfc.chuckya

import android.content.Context
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject

object UploadService {
  private val client = OkHttpClient()
  private const val BACKEND = "https://staging.example.com" // set to staging/production in config

  suspend fun upload(ctx: Context, payload: Map<String,Any>) = withContext(Dispatchers.IO) {
    val body = JSONObject(payload).toString().toRequestBody("application/json".toMediaType())
    val req = Request.Builder().url("$BACKEND/v1/radar/event").post(body).build()
    client.newCall(req).execute().use { resp ->
      // handle response, implement retry/queue on failure
    }
  }
}

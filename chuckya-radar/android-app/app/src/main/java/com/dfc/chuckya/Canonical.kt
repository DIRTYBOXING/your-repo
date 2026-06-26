package com.dfc.chuckya

import org.json.JSONObject
import java.util.*

object Canonical {
  fun canonicalize(map: Map<String,Any>): String {
    val sorted = TreeMap<String,Any>(map)
    val json = JSONObject(sorted as Map<*, *>)
    return json.toString()
  }
}

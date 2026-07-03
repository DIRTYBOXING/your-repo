# ─── Uptime Checks ───────────────────────────────────────────────────────────

resource "google_monitoring_uptime_check_config" "entitlements_health" {
  display_name = "DFC Entitlements Health"
  timeout      = "10s"
  period       = "300s"

  http_check {
    path         = "/health"
    port         = 443
    use_ssl      = true
    validate_ssl = true
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = trimprefix(google_cloud_run_v2_service.entitlements.uri, "https://")
    }
  }
}

resource "google_monitoring_uptime_check_config" "web_app_health" {
  display_name = "DFC Web App"
  timeout      = "10s"
  period       = "300s"

  http_check {
    path         = "/"
    port         = 443
    use_ssl      = true
    validate_ssl = true
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = "datafightcentral.web.app"
    }
  }
}

# ─── Alert Policy: Service Down ──────────────────────────────────────────────

resource "google_monitoring_notification_channel" "email_ops" {
  display_name = "DFC Ops Email"
  type         = "email"

  labels = {
    email_address = var.ops_email
  }
}

resource "google_monitoring_alert_policy" "service_uptime" {
  display_name = "DFC Service Down Alert"
  combiner     = "OR"

  conditions {
    display_name = "Entitlements service uptime failure"

    condition_threshold {
      filter          = "metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\" AND resource.type=\"uptime_url\" AND metric.labels.check_id=\"${google_monitoring_uptime_check_config.entitlements_health.uptime_check_id}\""
      comparison      = "COMPARISON_GT"
      threshold_value = 1
      duration        = "300s"

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_NEXT_OLDER"
        cross_series_reducer = "REDUCE_COUNT_FALSE"
        group_by_fields    = ["resource.label.project_id"]
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email_ops.name]

  alert_strategy {
    auto_close = "1800s"
  }
}

# ─── Alert Policy: High Error Rate on Cloud Run ─────────────────────────────

resource "google_monitoring_alert_policy" "cloud_run_errors" {
  display_name = "DFC Cloud Run High Error Rate"
  combiner     = "OR"

  conditions {
    display_name = "Cloud Run 5xx error rate > 5%"

    condition_threshold {
      filter          = "metric.type=\"run.googleapis.com/request_count\" AND resource.type=\"cloud_run_revision\" AND metric.labels.response_code_class=\"5xx\""
      comparison      = "COMPARISON_GT"
      threshold_value = 5
      duration        = "300s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email_ops.name]
}

# ─── Billing Budget Alert ────────────────────────────────────────────────────
# Fires email alerts at 50%, 80%, and 100% of monthly budget.
# Requires billing_account_id to be set in terraform.tfvars.

resource "google_billing_budget" "monthly_cap" {
  count = var.billing_account_id != "" ? 1 : 0

  billing_account = var.billing_account_id
  display_name    = "DFC Monthly Budget Cap"

  budget_filter {
    projects = ["projects/${var.project_id}"]
  }

  amount {
    specified_amount {
      currency_code = "USD"
      units         = tostring(var.monthly_budget_usd)
    }
  }

  threshold_rules {
    threshold_percent = 0.5
    spend_basis       = "CURRENT_SPEND"
  }
  threshold_rules {
    threshold_percent = 0.8
    spend_basis       = "CURRENT_SPEND"
  }
  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "CURRENT_SPEND"
  }

  all_updates_rule {
    monitoring_notification_channels = [google_monitoring_notification_channel.email_ops.name]
    disable_default_iam_recipients   = false
  }
}

# ─── Cloud Run Request Spike Alert ───────────────────────────────────────────
# Detects abnormal request volume that could signal abuse or runaway costs.

resource "google_monitoring_alert_policy" "cloud_run_request_spike" {
  display_name = "DFC Cloud Run Request Spike"
  combiner     = "OR"

  conditions {
    display_name = "Request count > 10k/min across all Cloud Run services"

    condition_threshold {
      filter          = "metric.type=\"run.googleapis.com/request_count\" AND resource.type=\"cloud_run_revision\""
      comparison      = "COMPARISON_GT"
      threshold_value = 10000
      duration        = "60s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email_ops.name]
}

# ─── Firestore Read Spike Alert ──────────────────────────────────────────────
# Detects abnormal Firestore read activity (scraping, runaway queries).

resource "google_monitoring_alert_policy" "firestore_read_spike" {
  display_name = "DFC Firestore Read Spike"
  combiner     = "OR"

  conditions {
    display_name = "Firestore document reads > 50k in 5min"

    condition_threshold {
      filter          = "metric.type=\"firestore.googleapis.com/document/read_count\" AND resource.type=\"firestore_database\""
      comparison      = "COMPARISON_GT"
      threshold_value = 50000
      duration        = "300s"

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_SUM"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email_ops.name]
}

# ─── Storage Growth Alert ────────────────────────────────────────────────────

resource "google_monitoring_alert_policy" "storage_growth" {
  display_name = "DFC Storage Growth Alert"
  combiner     = "OR"

  conditions {
    display_name = "GCS bucket storage > 10GB"

    condition_threshold {
      filter          = "metric.type=\"storage.googleapis.com/storage/total_bytes\" AND resource.type=\"gcs_bucket\""
      comparison      = "COMPARISON_GT"
      threshold_value = 10737418240 # 10 GB
      duration        = "0s"

      aggregations {
        alignment_period   = "3600s"
        per_series_aligner = "ALIGN_MAX"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email_ops.name]
}

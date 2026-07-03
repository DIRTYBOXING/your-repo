terraform {
  required_version = ">= 1.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# ─── Pub/Sub Topics ──────────────────────────────────────────────────────────

resource "google_pubsub_topic" "poster_generation" {
  name = "poster_generation"
}

resource "google_pubsub_topic" "promotion_jobs" {
  name = "promotion_jobs"
}

resource "google_pubsub_topic" "promotion_dlq" {
  name    = "promotion_dlq"
  # Messages retained for 7 days for inspection and requeue
  message_retention_duration = "604800s"
}

# ─── Pub/Sub Push Subscriptions → Cloud Run Workers ─────────────────────────

# Delivers poster_generation messages to poster-worker Cloud Run service
resource "google_pubsub_subscription" "poster_generation_push" {
  name  = "poster-generation-push-to-worker"
  topic = google_pubsub_topic.poster_generation.name

  push_config {
    push_endpoint = "${google_cloud_run_v2_service.poster_worker.uri}/pubsub"

    oidc_token {
      service_account_email = google_service_account.worker_sa.email
    }
  }

  ack_deadline_seconds       = 300
  message_retention_duration = "86400s" # 24h retry window

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.promotion_dlq.id
    max_delivery_attempts = 5
  }
}

# Delivers promotion_jobs messages to promotion-worker Cloud Run service
resource "google_pubsub_subscription" "promotion_jobs_push" {
  name  = "promotion-jobs-push-to-worker"
  topic = google_pubsub_topic.promotion_jobs.name

  push_config {
    push_endpoint = "${google_cloud_run_v2_service.promotion_worker.uri}/pubsub"

    oidc_token {
      service_account_email = google_service_account.worker_sa.email
    }
  }

  ack_deadline_seconds       = 300
  message_retention_duration = "86400s"

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.promotion_dlq.id
    max_delivery_attempts = 5
  }
}

# Allow Pub/Sub to invoke Cloud Run services
resource "google_cloud_run_service_iam_member" "poster_worker_pubsub_invoker" {
  service  = "poster-worker"
  location = var.region
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.worker_sa.email}"
}

resource "google_cloud_run_service_iam_member" "promotion_worker_pubsub_invoker" {
  service  = "promotion-worker"
  location = var.region
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.worker_sa.email}"
}

# ─── GCS Assets Bucket ───────────────────────────────────────────────────────

resource "google_storage_bucket" "assets" {
  name                        = var.assets_bucket
  location                    = var.region
  uniform_bucket_level_access = true

  lifecycle_rule {
    action { type = "Delete" }
    condition { age = 365 }
  }

  cors {
    origin          = ["https://datafightcentral.com"]
    method          = ["GET", "HEAD"]
    response_header = ["Content-Type"]
    max_age_seconds = 3600
  }
}

# ─── Service Account for workers ─────────────────────────────────────────────

resource "google_service_account" "worker_sa" {
  account_id   = "dfc-promotion-worker"
  display_name = "DFC Promotion Worker Service Account"
}

resource "google_project_iam_member" "worker_firestore" {
  project = var.project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.worker_sa.email}"
}

resource "google_project_iam_member" "worker_pubsub" {
  project = var.project_id
  role    = "roles/pubsub.editor"
  member  = "serviceAccount:${google_service_account.worker_sa.email}"
}

resource "google_storage_bucket_iam_member" "worker_gcs" {
  bucket = google_storage_bucket.assets.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.worker_sa.email}"
}

# ─── Outputs ─────────────────────────────────────────────────────────────────

output "worker_service_account_email" {
  value = google_service_account.worker_sa.email
}

output "assets_bucket_name" {
  value = google_storage_bucket.assets.name
}

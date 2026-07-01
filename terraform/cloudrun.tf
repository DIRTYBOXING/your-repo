# ─── Cloud Run Services ──────────────────────────────────────────────────────
# COST CONTROL: All services scale to zero, have max instance caps, CPU/memory
# limits, and request timeouts. Monitor via billing budget + alert policies in
# monitoring.tf. Review max_instance_count quarterly to match actual traffic.

resource "google_cloud_run_v2_service" "entitlements" {
  name     = "entitlements-service"
  location = var.region

  template {
    service_account = google_service_account.entitlements_sa.email

    containers {
      image = "gcr.io/${var.project_id}/entitlements-service:latest"

      env {
        name  = "NODE_ENV"
        value = "production"
      }
      env {
        name  = "TOKEN_TTL"
        value = "120"
      }
      env {
        name  = "FRONTEND_URL"
        value = "https://datafightcentral.com"
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 5  # Launch cap — raise after validating traffic
    }

    max_instance_request_concurrency = 80
    timeout = "60s"
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
}

resource "google_cloud_run_v2_service" "poster_worker" {
  name     = "poster-worker"
  location = var.region

  template {
    service_account = google_service_account.worker_sa.email

    containers {
      image = "gcr.io/${var.project_id}/poster-worker:latest"

      resources {
        limits = {
          cpu    = "1"
          memory = "1Gi"
        }
      }
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 3  # Launch cap — raise after validating traffic
    }

    timeout = "300s"
  }
}

resource "google_cloud_run_v2_service" "promotion_worker" {
  name     = "promotion-worker"
  location = var.region

  template {
    service_account = google_service_account.worker_sa.email

    containers {
      image = "gcr.io/${var.project_id}/promotion-worker:latest"

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 3  # Launch cap — raise after validating traffic
    }

    timeout = "300s"
  }
}

resource "google_cloud_run_v2_service" "genkit" {
  name     = "genkit"
  location = var.region

  template {
    service_account = google_service_account.worker_sa.email

    containers {
      image = "gcr.io/${var.project_id}/genkit:latest"

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 2  # Launch cap — raise after validating traffic
    }

    timeout = "300s"
  }
}

# ─── Entitlements Service Account ────────────────────────────────────────────

resource "google_service_account" "entitlements_sa" {
  account_id   = "dfc-entitlements-sa"
  display_name = "DFC Entitlements Service Account"
}

resource "google_project_iam_member" "entitlements_firestore" {
  project = var.project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.entitlements_sa.email}"
}

resource "google_project_iam_member" "entitlements_secretmanager" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.entitlements_sa.email}"
}

# ─── Outputs ─────────────────────────────────────────────────────────────────

output "entitlements_url" {
  value = google_cloud_run_v2_service.entitlements.uri
}

output "poster_worker_url" {
  value = google_cloud_run_v2_service.poster_worker.uri
}

output "promotion_worker_url" {
  value = google_cloud_run_v2_service.promotion_worker.uri
}

output "genkit_url" {
  value = google_cloud_run_v2_service.genkit.uri
}

# ═══════════════════════════════════════════════════════════════════════════
# Cloud CDN — Cache media assets served from the GCS bucket
# ═══════════════════════════════════════════════════════════════════════════
#
# Sits in front of the Firebase Storage / GCS bucket that holds transcoded
# video, thumbnails, OG images, and poster assets.  Delivers them via
# Google's edge network so users worldwide get fast loads.
#
# The backend bucket points at var.assets_bucket (same bucket the upload-
# service and video-worker already write to).
# ═══════════════════════════════════════════════════════════════════════════

# ─── Backend Bucket (CDN-enabled) ────────────────────────────────────────

resource "google_compute_backend_bucket" "media_cdn" {
  name        = "dfc-media-cdn"
  bucket_name = var.assets_bucket
  enable_cdn  = true

  cdn_policy {
    cache_mode                   = "CACHE_ALL_STATIC"
    default_ttl                  = 3600   # 1 hour default
    max_ttl                      = 86400  # 24 hours max
    client_ttl                   = 3600
    signed_url_cache_max_age_sec = 3600
    serve_while_stale            = 86400  # serve stale up to 24h while revalidating

    cache_key_policy {
      include_http_headers = []
    }
  }
}

# ─── URL Map ─────────────────────────────────────────────────────────────

resource "google_compute_url_map" "media_cdn" {
  name            = "dfc-media-cdn-url-map"
  default_service = google_compute_backend_bucket.media_cdn.id
}

# ─── HTTPS Proxy + Forwarding (requires managed SSL cert) ────────────────
# Uncomment and supply your domain once DNS is pointed at the load-balancer IP.

# resource "google_compute_managed_ssl_certificate" "media_cdn" {
#   name = "dfc-media-cdn-cert"
#   managed {
#     domains = ["media.datafightcentral.com"]
#   }
# }

# resource "google_compute_target_https_proxy" "media_cdn" {
#   name             = "dfc-media-cdn-https-proxy"
#   url_map          = google_compute_url_map.media_cdn.id
#   ssl_certificates = [google_compute_managed_ssl_certificate.media_cdn.id]
# }

# resource "google_compute_global_forwarding_rule" "media_cdn" {
#   name       = "dfc-media-cdn-fwd"
#   target     = google_compute_target_https_proxy.media_cdn.id
#   port_range = "443"
#   ip_protocol = "TCP"
# }

# ─── HTTP-only proxy (works immediately for testing) ─────────────────────

resource "google_compute_target_http_proxy" "media_cdn" {
  name    = "dfc-media-cdn-http-proxy"
  url_map = google_compute_url_map.media_cdn.id
}

resource "google_compute_global_forwarding_rule" "media_cdn_http" {
  name        = "dfc-media-cdn-http-fwd"
  target      = google_compute_target_http_proxy.media_cdn.id
  port_range  = "80"
  ip_protocol = "TCP"
}

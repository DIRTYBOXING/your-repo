param(
    [string]$BaseUrl = $(
        if ($env:SUPERBEAST_API_BASE_URL) {
            $env:SUPERBEAST_API_BASE_URL
        }
        elseif ($env:SUPERBEAST_API_PORT) {
            "http://127.0.0.1:$($env:SUPERBEAST_API_PORT)"
        }
        else {
            'http://127.0.0.1:8001'
        }
    ),
    [string]$PpvId = 'ppv-superbeast-smoke',
    [string]$UserId = 'user-superbeast-smoke',
    [int]$PriceCents = 1999
)

$ErrorActionPreference = 'Stop'

$runtime = Invoke-RestMethod -Uri "$BaseUrl/ops/runtime"
$before = Invoke-RestMethod -Uri "$BaseUrl/ops/outbox"
$purchase = Invoke-RestMethod -Method Post -Uri "$BaseUrl/ppv/purchase" -ContentType 'application/json' -Body (@{
        ppv_id      = $PpvId
        user_id     = $UserId
        price_cents = $PriceCents
    } | ConvertTo-Json)
$after = Invoke-RestMethod -Uri "$BaseUrl/ops/outbox"

[pscustomobject]@{
    runtime  = $runtime
    before   = $before
    purchase = $purchase
    after    = $after
} | ConvertTo-Json -Depth 8

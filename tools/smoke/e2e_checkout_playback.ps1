param(
    [Parameter(Mandatory = $true)]
    [string]$BaseUrl,

    [Parameter(Mandatory = $true)]
    [string]$EventId,

    [Parameter(Mandatory = $true)]
    [string]$UserId,

    [Parameter(Mandatory = $true)]
    [string]$Email
)

$ErrorActionPreference = 'Stop'
$RuntimeName = 'legacy live-publisher'

function Write-Step {
    param([string]$Message)
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Invoke-JsonGet {
    param([string]$Url)
    return Invoke-RestMethod -Method Get -Uri $Url -ContentType 'application/json'
}

function Invoke-JsonPost {
    param(
        [string]$Url,
        [hashtable]$Body
    )

    $jsonBody = $Body | ConvertTo-Json -Depth 5
    return Invoke-RestMethod -Method Post -Uri $Url -ContentType 'application/json' -Body $jsonBody
}

Write-Host "PPV smoke lane: $RuntimeName" -ForegroundColor Yellow
Write-Host 'This script exercises /api/events/... endpoints in dfc-content-pipeline/live-publisher, not the canonical Firebase PPV callable flow.' -ForegroundColor Yellow
Write-Host ''

Write-Step 'Creating checkout session'
$checkout = Invoke-JsonPost -Url "$BaseUrl/api/events/$EventId/ppv/checkout" -Body @{
    userId = $UserId
    email = $Email
}
$checkout | ConvertTo-Json -Depth 10

if ($checkout.status -eq 'already_purchased') {
    Write-Host 'User already has access.' -ForegroundColor Yellow
} elseif ($checkout.checkoutUrl) {
    Write-Host 'Open this URL and complete payment with Stripe test credentials:' -ForegroundColor Yellow
    Write-Host $checkout.checkoutUrl
} else {
    Write-Warning 'Checkout creation did not return a checkoutUrl.'
}

Write-Host ''
Write-Step 'Checking PPV access'
$access = Invoke-JsonGet -Url "$BaseUrl/api/events/$EventId/ppv/access?userId=$UserId"
$access | ConvertTo-Json -Depth 10

if (-not $access.hasAccess) {
    if ($checkout.sessionId) {
        Write-Host ''
        Write-Step 'Completing local smoke purchase'
        $smokeComplete = Invoke-JsonPost -Url "$BaseUrl/api/events/$EventId/ppv/smoke-complete" -Body @{
            userId = $UserId
            sessionId = $checkout.sessionId
        }
        $smokeComplete | ConvertTo-Json -Depth 10

        Write-Host ''
        Write-Step 'Re-checking PPV access'
        $access = Invoke-JsonGet -Url "$BaseUrl/api/events/$EventId/ppv/access?userId=$UserId"
        $access | ConvertTo-Json -Depth 10
    }
}

if (-not $access.hasAccess) {
    Write-Host ''
    Write-Warning 'Access not yet granted.'
    Write-Host 'If payment was just completed, verify Stripe webhook delivery or Stripe CLI forwarding before retrying.' -ForegroundColor Yellow
    exit 2
}

Write-Host ''
Write-Step 'Attempting replay URL retrieval'
$replay = Invoke-JsonGet -Url "$BaseUrl/api/events/$EventId/replay?userId=$UserId"
$replay | ConvertTo-Json -Depth 10

if ($replay.replayUrl) {
    Write-Host ''
    Write-Step 'Validating replay URL'
    try {
        $response = Invoke-WebRequest -Method Head -Uri $replay.replayUrl -MaximumRedirection 0 -ErrorAction Stop
        $statusCode = [int]$response.StatusCode
    } catch {
        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode
        } else {
            throw
        }
    }

    Write-Host "Replay URL HTTP status: $statusCode"
    if ($statusCode -notin 200, 302) {
        Write-Error 'Replay URL validation failed.'
    }
}

Write-Host ''
Write-Host 'Smoke test completed.' -ForegroundColor Green
Write-Host 'For true end-to-end validation, confirm this run used real Stripe test webhook delivery and the intended canonical staging runtime.' -ForegroundColor Yellow

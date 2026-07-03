# wipeout_simulation.ps1
# Full 4-Pillar Wipeout Simulation -- Pushes one test event through ALL pillars.
#
# Chain: Admin Create -> Auto-Seeder Blast -> Stripe Conversion -> Genius Live Flow -> Legacy Mop-Up
#
# PRODUCTION DATA: Ultimate Legends -- April 24, 2026 -- Melbourne Pavilion
# Fight Card:
#   Main Event:  Jordan Roesler vs TBD (IBO Asia Pacific Light Heavyweight Title)
#   Co-Main:     Erini Ramirez vs Nicila Costello (WBC Australasian Silver Bantamweight Title)
#   Undercard:   Steve (Junior) -- Professional Debut
#   Main Card:   Tarek El Houli -- Team Ultimate
#
# Ticket Tiers:
#   General Admission:  $100 AUD (10000 cents)
#   Table Seats:        $150 AUD (15000 cents)
#   VIP Catered Tables: $3500 AUD (350000 cents)
#
# Usage:
#   .\scripts\wipeout_simulation.ps1                     # Full 5-step chain
#   .\scripts\wipeout_simulation.ps1 -Step 1             # Only Step 1 (Create Event)
#   .\scripts\wipeout_simulation.ps1 -Step 3             # Only Step 3 (Simulate Payment)
#   .\scripts\wipeout_simulation.ps1 -DryRun             # Print commands without executing
#
# Prerequisites:
#   - Firebase CLI: npm install -g firebase-tools
#   - Authenticated: firebase login
#   - Project set:   firebase use datafightcentral

param(
    [ValidateRange(0,5)]
    [int]$Step = 0,  # 0 = run all steps

    [switch]$DryRun,

    [string]$EventId = "ultimate_legends_april_24_2026",
    [string]$ProjectId = "datafightcentral",
    [string]$Region = "australia-southeast1"
)

$ErrorActionPreference = "Stop"

# --- Helpers ---
function Write-Step  { param([string]$msg) Write-Host "`n==================================" -ForegroundColor Cyan; Write-Host "  $msg" -ForegroundColor Cyan; Write-Host "==================================" -ForegroundColor Cyan }
function Write-Ok    { param([string]$msg) Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Info  { param([string]$msg) Write-Host "  [..] $msg" -ForegroundColor Yellow }
function Write-Fail  { param([string]$msg) Write-Host "  [FAIL] $msg" -ForegroundColor Red }

function Invoke-Firebase {
    param([string]$Cmd)
    if ($DryRun) {
        Write-Info "[DRY RUN] $Cmd"
        return '{"ok":true}'
    }
    $result = Invoke-Expression $Cmd 2>&1
    return $result
}

# --- Event Payload (Production: Ultimate Legends April 24) ---
$now = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")

$eventPayload = @{
    id                    = $EventId
    title                 = "Ultimate Legends: IBO & WBC Title War"
    description           = "Jordan Roesler challenges for the IBO Asia Pacific Light Heavyweight Title. Erini Ramirez vs Nicila Costello for the WBC Australasian Silver Bantamweight. Steve Junior makes his professional debut. Melbourne Pavilion, April 24 2026."
    sport                 = "Muay Thai / Boxing"
    promotion             = "Ultimate Legends Promotions"
    status                = "onSale"
    standardPriceCents    = 10000
    earlyBirdPriceCents   = 10000
    tableSeatPriceCents   = 15000
    vipTablePriceCents    = 350000
    platformFeePct        = 0.30
    posterUrl             = "https://storage.googleapis.com/datafightcentral.appspot.com/ppv/posters/ultimate_legends_apr24.webp"
    streamUrl             = ""
    muxStreamId           = ""
    muxPlaybackId         = ""
    eventDate             = "2026-04-24T18:00:00+10:00"
    venueCity             = "Melbourne"
    venueCountry          = "AU"
    venueName             = "Melbourne Pavilion"
    venueAddress          = "130 Thistlethwaite Street, South Melbourne VIC 3205"
    createdAt             = $now
    updatedAt             = $now
    createdBy             = "wipeout_simulation"
    fighters              = @(
        "jordan_roesler",
        "erini_ramirez",
        "nicila_costello",
        "steve_junior",
        "tarek_el_houli"
    )
    fightCard             = @(
        @{ matchup = "Jordan Roesler vs TBD"; title = "IBO Asia Pacific Light Heavyweight"; tier = "main_event" }
        @{ matchup = "Erini Ramirez vs Nicila Costello"; title = "WBC Australasian Silver Bantamweight"; tier = "co_main" }
        @{ matchup = "Steve (Junior) - Pro Debut"; title = ""; tier = "undercard" }
        @{ matchup = "Tarek El Houli - Team Ultimate"; title = ""; tier = "main_card" }
    )
    tags                  = @("muay-thai", "boxing", "ppv", "live", "melbourne", "ibo", "wbc", "ultimate-legends")
    ticketTiers           = @(
        @{ name = "General Admission"; priceCents = 10000; description = "Standing / general entry" }
        @{ name = "Table Seats (No Catering)"; priceCents = 15000; description = "Seated table, no food/drink" }
        @{ name = "VIP Catered Table"; priceCents = 350000; description = "Premium table with full catering" }
    )
} | ConvertTo-Json -Depth 5 -Compress

# --- Buyer Payload ---
$buyerUid = "sim_buyer_$(Get-Date -Format 'HHmmss')"

$purchasePayload = @{
    userId          = $buyerUid
    ppvEventId      = $EventId
    pricePaidCents  = 10000
    tier            = "general_admission"
    currency        = "aud"
    paymentIntentId = "pi_sim_wipeout_$(Get-Date -Format 'yyyyMMddHHmmss')"
    status          = "completed"
    purchasedAt     = $now
} | ConvertTo-Json -Depth 4 -Compress

# --- Live Stats Payload (Main Event: Roesler) ---
$liveStatsPayload = @{
    eventId      = $EventId
    matchStatus  = "live"
    round        = 3
    clockSeconds = 147
    currentBout  = "Jordan Roesler vs TBD"
    titleOnLine  = "IBO Asia Pacific Light Heavyweight"
    redCorner    = @{
        name     = "Jordan Roesler"
        strikes  = 47
        takedowns = 2
        liveOdds = -180
    }
    blueCorner   = @{
        name     = "TBD"
        strikes  = 31
        takedowns = 1
        liveOdds = 150
    }
    lastUpdated  = $now
} | ConvertTo-Json -Depth 4 -Compress


# ==================================================
#  STEP 1: Admin Create -> Firestore ppv_events
# ==================================================
function Step1-CreateEvent {
    Write-Step "STEP 1 -- Admin Create: Write ppv_events/$EventId"

    $tempFile = [System.IO.Path]::GetTempFileName()
    $eventPayload | Out-File -FilePath $tempFile -Encoding utf8 -Force

    Write-Info "Writing ppv_events/$EventId to Firestore..."
    $cmd = "firebase firestore:delete ppv_events/$EventId --project $ProjectId --force 2>`$null; echo '{}'"
    Invoke-Firebase $cmd | Out-Null

    $nodeScript = @'
const admin = require('firebase-admin');
if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();
const data = __EVENT_PAYLOAD__;
db.collection('ppv_events').doc('__EVENT_ID__').set(data)
  .then(() => { console.log('OK: ppv_events/__EVENT_ID__ written'); process.exit(0); })
  .catch(e => { console.error('FAIL:', e.message); process.exit(1); });
'@
    $nodeScript = $nodeScript.Replace('__EVENT_PAYLOAD__', $eventPayload).Replace('__EVENT_ID__', $EventId)

    $scriptFile = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "wipeout_step1.cjs")
    $nodeScript | Out-File -FilePath $scriptFile -Encoding utf8 -Force

    if ($DryRun) {
        Write-Info "[DRY RUN] node $scriptFile"
        Write-Info "[DRY RUN] Event: Ultimate Legends: IBO & WBC Title War"
        Write-Info "[DRY RUN] Venue: Melbourne Pavilion, April 24 2026"
        Write-Info "[DRY RUN] Tiers: GA=`$100 | Table=`$150 | VIP=`$3500"
        Write-Info "[DRY RUN] Fight Card:"
        Write-Info "[DRY RUN]   Main Event: Jordan Roesler vs TBD (IBO Asia Pacific LHW)"
        Write-Info "[DRY RUN]   Co-Main:    Erini Ramirez vs Nicila Costello (WBC Silver BW)"
        Write-Info "[DRY RUN]   Undercard:  Steve (Junior) - Professional Debut"
        Write-Info "[DRY RUN]   Main Card:  Tarek El Houli - Team Ultimate"
    } else {
        try {
            $env:GOOGLE_APPLICATION_CREDENTIALS = $env:GOOGLE_APPLICATION_CREDENTIALS
            $env:GCLOUD_PROJECT = $ProjectId
            node $scriptFile
            Write-Ok "ppv_events/$EventId created with status=onSale"
        } catch {
            Write-Fail "Firestore write failed: $_"
            Write-Info "Fallback: Use Firebase Console to create the document manually."
        }
    }

    Remove-Item $tempFile -ErrorAction SilentlyContinue
    Remove-Item $scriptFile -ErrorAction SilentlyContinue
}


# ==================================================
#  STEP 2: Auto-Seeder Blast -> Trigger n8n
# ==================================================
function Step2-TriggerSeeder {
    Write-Step "STEP 2 -- Auto-Seeder: Trigger n8nPostBack Cloud Function"

    $postbackPayload = @{
        data = @{
            eventId      = $EventId
            socialPostId = "social_${EventId}_sim"
            status       = "seeding_started"
        }
    } | ConvertTo-Json -Depth 4 -Compress

    $url = "https://$Region-$ProjectId.cloudfunctions.net/n8nPostBack"
    Write-Info "POST $url"

    if ($DryRun) {
        Write-Info "[DRY RUN] Invoke-RestMethod -Uri $url -Method POST -Body ..."
        Write-Info "[DRY RUN] n8n Firestore trigger would fire for $EventId"
    } else {
        try {
            $response = Invoke-RestMethod -Uri $url -Method POST -ContentType "application/json" -Body $postbackPayload -TimeoutSec 30
            Write-Ok "n8nPostBack responded: $($response | ConvertTo-Json -Compress)"
        } catch {
            Write-Fail "n8nPostBack call failed: $($_.Exception.Message)"
            Write-Info "Verify the Cloud Function is deployed: firebase functions:list | Select-String n8nPostBack"
        }
    }

    Write-Info "n8n Firestore trigger should now fire (if v2 workflow is active)."
}


# ==================================================
#  STEP 3: Stripe Conversion -> Simulate Payment
# ==================================================
function Step3-SimulatePayment {
    Write-Step "STEP 3 -- Stripe Conversion: Write ppv_access + ppv_purchases"

    $nodeScript = @'
const admin = require('firebase-admin');
if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();
const batch = db.batch();

const accessRef = db.collection('ppv_access').doc('__BUYER_UID_____EVENT_ID__');
batch.set(accessRef, {
  userId: '__BUYER_UID__',
  ppvEventId: '__EVENT_ID__',
  hasAccess: true,
  grantedAt: admin.firestore.FieldValue.serverTimestamp(),
  source: 'wipeout_simulation'
});

const purchaseRef = db.collection('ppv_purchases').doc('__BUYER_UID_____EVENT_ID__');
batch.set(purchaseRef, __PURCHASE_PAYLOAD__);

batch.commit()
  .then(() => { console.log('OK: ppv_access + ppv_purchases written for __BUYER_UID__'); process.exit(0); })
  .catch(e => { console.error('FAIL:', e.message); process.exit(1); });
'@
    $nodeScript = $nodeScript.Replace('__BUYER_UID__', $buyerUid).Replace('__EVENT_ID__', $EventId).Replace('__PURCHASE_PAYLOAD__', $purchasePayload)

    $scriptFile = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "wipeout_step3.cjs")
    $nodeScript | Out-File -FilePath $scriptFile -Encoding utf8 -Force

    if ($DryRun) {
        Write-Info "[DRY RUN] node $scriptFile"
        Write-Info "[DRY RUN] Simulating GA ticket purchase: `$100 AUD for $buyerUid"
    } else {
        try {
            node $scriptFile
            Write-Ok "ppv_access granted + ppv_purchases recorded"
            Write-Info "PpvGate StreamBuilder should now swap paywall for player."
        } catch {
            Write-Fail "Payment simulation failed: $_"
        }
    }

    Remove-Item $scriptFile -ErrorAction SilentlyContinue
}


# ==================================================
#  STEP 4: Genius Live Flow -> Inject live_stats
# ==================================================
function Step4-InjectLiveStats {
    Write-Step "STEP 4 -- Genius Live Flow: Write live_stats/$EventId"

    $nodeScript = @'
const admin = require('firebase-admin');
if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();
const data = __LIVE_STATS_PAYLOAD__;
data.lastUpdated = admin.firestore.FieldValue.serverTimestamp();

db.collection('live_stats').doc('__EVENT_ID__').set(data)
  .then(() => {
    console.log('OK: live_stats/__EVENT_ID__ injected (Round 3, 2:27 on clock)');
    console.log('   Red Corner: Jordan Roesler -- 47 strikes, 2 takedowns, -180 odds');
    console.log('   Blue Corner: TBD -- 31 strikes, 1 takedown, +150 odds');
    console.log('   Title: IBO Asia Pacific Light Heavyweight');
    process.exit(0);
  })
  .catch(e => { console.error('FAIL:', e.message); process.exit(1); });
'@
    $nodeScript = $nodeScript.Replace('__LIVE_STATS_PAYLOAD__', $liveStatsPayload).Replace('__EVENT_ID__', $EventId)

    $scriptFile = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "wipeout_step4.cjs")
    $nodeScript | Out-File -FilePath $scriptFile -Encoding utf8 -Force

    if ($DryRun) {
        Write-Info "[DRY RUN] node $scriptFile"
        Write-Info "[DRY RUN] Injecting live stats for Jordan Roesler vs TBD (IBO title bout)"
    } else {
        try {
            node $scriptFile
            Write-Ok "live_stats doc injected -- FighterProfileScreen StreamBuilder should render LIVE card"
        } catch {
            Write-Fail "Live stats injection failed: $_"
        }
    }

    Remove-Item $scriptFile -ErrorAction SilentlyContinue
}


# ==================================================
#  STEP 5: Legacy Mop-Up -> Archive + Post-Event
# ==================================================
function Step5-ArchiveAndLegacy {
    Write-Step "STEP 5 -- Legacy Mop-Up: Archive event -> Trigger post-event pipeline"

    $nodeScript = @'
const admin = require('firebase-admin');
if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

async function run() {
  await db.collection('ppv_events').doc('__EVENT_ID__').update({
    status: 'replay',
    streamUrl: 'https://stream.mux.com/wipeout-sim-replay.m3u8',
    muxPlaybackId: 'wipeout-sim-mux-playback',
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  });
  console.log('OK: ppv_events/__EVENT_ID__ status -> replay');

  await db.collection('live_stats').doc('__EVENT_ID__').update({
    matchStatus: 'finished',
    lastUpdated: admin.firestore.FieldValue.serverTimestamp()
  });
  console.log('OK: live_stats/__EVENT_ID__ -> finished');

  await db.collection('clip_harvest_queue').doc('clip___EVENT_ID__').set({
    eventId: '__EVENT_ID__',
    sourceUrl: 'https://stream.mux.com/wipeout-sim-replay.m3u8',
    status: 'pending',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  });
  console.log('OK: clip_harvest_queue/clip___EVENT_ID__ seeded');

  await db.collection('vault_vod').doc('vod___EVENT_ID__').set({
    eventId: '__EVENT_ID__',
    title: 'Ultimate Legends: IBO & WBC Title War -- Full Replay',
    promoterId: 'promo_ultimate_legends',
    fighters: ['jordan_roesler', 'erini_ramirez', 'nicila_costello', 'steve_junior', 'tarek_el_houli'],
    totalRevenueCents: 89970,
    status: 'ready',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  });
  console.log('OK: vault_vod/vod___EVENT_ID__ seeded (triggers 50/30/20 payout split)');

  console.log('');
  console.log('WIPEOUT COMPLETE:');
  console.log('  - onPPVReplayReady should fire (status -> replay)');
  console.log('  - clipBotHarvester will pick up clip_harvest_queue on next 5-min tick');
  console.log('  - processResidualPayout should fire on vault_vod write');
  console.log('  - Payout split: DFC 50% / Promoter 30% / Fighters 20%');
  process.exit(0);
}

run().catch(e => { console.error('FAIL:', e.message); process.exit(1); });
'@
    $nodeScript = $nodeScript.Replace('__EVENT_ID__', $EventId)

    $scriptFile = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "wipeout_step5.cjs")
    $nodeScript | Out-File -FilePath $scriptFile -Encoding utf8 -Force

    if ($DryRun) {
        Write-Info "[DRY RUN] node $scriptFile"
        Write-Info "[DRY RUN] Would archive event -> replay, seed clips + vault VOD"
    } else {
        try {
            node $scriptFile
            Write-Ok "Post-event pipeline triggered"
        } catch {
            Write-Fail "Archive + legacy mop-up failed: $_"
        }
    }

    Remove-Item $scriptFile -ErrorAction SilentlyContinue
}


# ==================================================
#  CLEANUP: Remove simulation data
# ==================================================
function Cleanup-SimulationData {
    Write-Step "CLEANUP -- Removing simulation documents"

    $nodeScript = @'
const admin = require('firebase-admin');
if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

async function cleanup() {
  const docs = [
    'ppv_events/__EVENT_ID__',
    'ppv_access/__BUYER_UID_____EVENT_ID__',
    'ppv_purchases/__BUYER_UID_____EVENT_ID__',
    'live_stats/__EVENT_ID__',
    'clip_harvest_queue/clip___EVENT_ID__',
    'vault_vod/vod___EVENT_ID__'
  ];
  for (const path of docs) {
    try {
      await db.doc(path).delete();
      console.log('  Deleted: ' + path);
    } catch (e) {
      console.log('  Skip (not found): ' + path);
    }
  }
  console.log('OK: Simulation data cleaned up');
  process.exit(0);
}
cleanup();
'@
    $nodeScript = $nodeScript.Replace('__BUYER_UID__', $buyerUid).Replace('__EVENT_ID__', $EventId)

    $scriptFile = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "wipeout_cleanup.cjs")
    $nodeScript | Out-File -FilePath $scriptFile -Encoding utf8 -Force

    if ($DryRun) {
        Write-Info "[DRY RUN] node $scriptFile"
    } else {
        node $scriptFile
    }

    Remove-Item $scriptFile -ErrorAction SilentlyContinue
}


# ==================================================
#  MAIN EXECUTION
# ==================================================
Write-Host ""
Write-Host "  D A T A   F I G H T   C E N T R A L" -ForegroundColor Magenta
Write-Host "  +=========================================+" -ForegroundColor DarkCyan
Write-Host "  |  WIPEOUT SIMULATION -- Full Pipeline    |" -ForegroundColor DarkCyan
Write-Host "  |  Event: Ultimate Legends Apr 24 2026    |" -ForegroundColor DarkCyan
Write-Host "  |  Venue: Melbourne Pavilion              |" -ForegroundColor DarkCyan
Write-Host "  |  ID: $EventId" -ForegroundColor DarkCyan
Write-Host "  +=========================================+" -ForegroundColor DarkCyan
Write-Host ""
Write-Host "  FIGHT CARD:" -ForegroundColor White
Write-Host "    Main Event: Jordan Roesler vs TBD (IBO Asia Pacific LHW)" -ForegroundColor Yellow
Write-Host "    Co-Main:    Erini Ramirez vs Nicila Costello (WBC Silver BW)" -ForegroundColor Yellow
Write-Host "    Undercard:  Steve (Junior) - Professional Debut" -ForegroundColor Gray
Write-Host "    Main Card:  Tarek El Houli - Team Ultimate" -ForegroundColor Gray
Write-Host ""
Write-Host "  TICKET TIERS:" -ForegroundColor White
Write-Host "    General Admission:  `$100 AUD" -ForegroundColor Green
Write-Host "    Table Seats:        `$150 AUD" -ForegroundColor Green
Write-Host "    VIP Catered Table:  `$3500 AUD" -ForegroundColor Green
Write-Host ""

if ($DryRun) {
    Write-Host "  *** DRY RUN MODE -- No Firestore writes ***" -ForegroundColor Yellow
    Write-Host ""
}

$startTime = Get-Date

if ($Step -eq 0 -or $Step -eq 1) { Step1-CreateEvent }
if ($Step -eq 0 -or $Step -eq 2) { Step2-TriggerSeeder }
if ($Step -eq 0 -or $Step -eq 3) { Step3-SimulatePayment }
if ($Step -eq 0 -or $Step -eq 4) { Step4-InjectLiveStats }
if ($Step -eq 0 -or $Step -eq 5) { Step5-ArchiveAndLegacy }

$elapsed = (Get-Date) - $startTime

Write-Host ""
Write-Step "SIMULATION COMPLETE"
Write-Host "  Elapsed: $([math]::Round($elapsed.TotalSeconds, 1))s" -ForegroundColor Gray
Write-Host "  Event ID: $EventId" -ForegroundColor Gray
Write-Host "  Buyer UID: $buyerUid" -ForegroundColor Gray
Write-Host ""
Write-Host "  Verify in Firebase Console:" -ForegroundColor White
Write-Host "    https://console.firebase.google.com/project/$ProjectId/firestore" -ForegroundColor Blue
Write-Host ""
Write-Host "  Collections to check:" -ForegroundColor White
Write-Host "    ppv_events/$EventId" -ForegroundColor Gray
Write-Host "    ppv_access/${buyerUid}_${EventId}" -ForegroundColor Gray
Write-Host "    ppv_purchases/${buyerUid}_${EventId}" -ForegroundColor Gray
Write-Host "    live_stats/$EventId" -ForegroundColor Gray
Write-Host "    clip_harvest_queue/clip_$EventId" -ForegroundColor Gray
Write-Host "    vault_vod/vod_$EventId" -ForegroundColor Gray
Write-Host ""
Write-Host "  To clean up: .\scripts\wipeout_simulation.ps1 -Step 0 (then run Cleanup-SimulationData)" -ForegroundColor DarkGray

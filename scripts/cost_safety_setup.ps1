#!/usr/bin/env pwsh
# ═══════════════════════════════════════════════════════════════════
# DFC — COST SAFETY SETUP SCRIPT
# Run this ONCE after deploying to set up Firebase budget alerts
# ═══════════════════════════════════════════════════════════════════

Write-Host "⭐ DFC COST SAFETY SETUP" -ForegroundColor Cyan
Write-Host "Project: datafightcentral (Blaze Plan)" -ForegroundColor Yellow
Write-Host ""

# ── STEP 1: Verify firebase is logged in ──
Write-Host "✅ Step 1 — Checking Firebase login..." -ForegroundColor Green
firebase projects:list | Select-String "datafightcentral"

# ── STEP 2: Deploy updated Firestore + Storage rules with limits ──
Write-Host ""
Write-Host "✅ Step 2 — Deploying security rules with cost limits..." -ForegroundColor Green
firebase deploy --only firestore:rules,storage:rules

# ── STEP 3: Remind about Google Cloud Budget Alert ──
Write-Host ""
Write-Host "════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "⚠️  MANUAL STEP REQUIRED — Budget Alert" -ForegroundColor Yellow
Write-Host "════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Go to this URL to set a spending limit:" -ForegroundColor White
Write-Host "https://console.cloud.google.com/billing/budgets?project=datafightcentral" -ForegroundColor Cyan
Write-Host ""
Write-Host "Set up these 3 alerts:" -ForegroundColor White
Write-Host "  1. Alert at $50/month  → Email notification" -ForegroundColor Green
Write-Host "  2. Alert at $100/month → Email + SMS notification" -ForegroundColor Yellow
Write-Host "  3. Alert at $200/month → Email + disable non-critical functions" -ForegroundColor Red
Write-Host ""
Write-Host "Blaze plan FREE TIER (per month):" -ForegroundColor White
Write-Host "  • Firestore: 50K reads, 20K writes, 20K deletes FREE" -ForegroundColor Green
Write-Host "  • Storage:   10 GB storage, 10 GB transfer FREE" -ForegroundColor Green
Write-Host "  • Functions: 2M invocations, 400K GB-seconds FREE" -ForegroundColor Green
Write-Host "  • Hosting:   10 GB storage, 10 GB transfer FREE" -ForegroundColor Green
Write-Host ""
Write-Host "✅ Cost Safety Setup Complete!" -ForegroundColor Cyan

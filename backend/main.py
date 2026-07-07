"""
DFC Backend — FastAPI production server
Deployed to Google Cloud Run (australia-southeast1)
Routes: /stripe/webhook, /fighters, /events, /gyms, /auth, /economy
"""
from __future__ import annotations

import hashlib
import hmac
import json
import os
import time
from typing import Any

import stripe
from fastapi import FastAPI, HTTPException, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

# ── Firebase Admin ────────────────────────────────────────────────────────────
import firebase_admin
from firebase_admin import credentials, firestore

if not firebase_admin._apps:
    # Cloud Run uses Application Default Credentials automatically
    firebase_admin.initialize_app()

db = firestore.client()

# ── Stripe ────────────────────────────────────────────────────────────────────
stripe.api_key = os.environ.get("STRIPE_SECRET_KEY", "")
STRIPE_WEBHOOK_SECRET = os.environ.get("STRIPE_WEBHOOK_SECRET", "")

# ── App ───────────────────────────────────────────────────────────────────────
app = FastAPI(title="DFC Backend", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://datafightcentral.com", "https://datafightcentral-9d036.web.app"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ── Health ────────────────────────────────────────────────────────────────────
@app.get("/")
def health():
    return {"status": "DFC backend running", "version": "1.0.0", "ts": int(time.time())}


# ── Stripe Webhook ────────────────────────────────────────────────────────────
@app.post("/stripe/webhook")
async def stripe_webhook(request: Request):
    payload = await request.body()
    sig_header = request.headers.get("stripe-signature", "")

    try:
        event = stripe.Webhook.construct_event(payload, sig_header, STRIPE_WEBHOOK_SECRET)
    except stripe.errors.SignatureVerificationError:
        raise HTTPException(status_code=400, detail="Invalid Stripe signature")
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

    event_type = event["type"]
    data = event["data"]["object"]

    if event_type == "checkout.session.completed":
        _handle_checkout_completed(data)
    elif event_type == "payment_intent.succeeded":
        _handle_payment_succeeded(data)
    elif event_type == "customer.subscription.updated":
        _handle_subscription_updated(data)
    elif event_type == "invoice.payment_failed":
        _handle_payment_failed(data)

    return JSONResponse({"received": True})


def _handle_checkout_completed(session: dict[str, Any]):
    metadata = session.get("metadata", {})
    event_id = metadata.get("eventId")
    user_id = metadata.get("userId")
    if event_id and user_id:
        db.collection("ppv_purchases").add({
            "eventId": event_id,
            "userId": user_id,
            "sessionId": session.get("id"),
            "amount": session.get("amount_total", 0) / 100,
            "currency": session.get("currency", "aud").upper(),
            "status": "completed",
            "completedAt": firestore.SERVER_TIMESTAMP,
        })


def _handle_payment_succeeded(intent: dict[str, Any]):
    db.collection("payment_logs").add({
        "intentId": intent.get("id"),
        "amount": intent.get("amount", 0) / 100,
        "status": "succeeded",
        "ts": firestore.SERVER_TIMESTAMP,
    })


def _handle_subscription_updated(subscription: dict[str, Any]):
    customer_id = subscription.get("customer")
    if customer_id:
        db.collection("subscriptions").document(customer_id).set({
            "status": subscription.get("status"),
            "planId": subscription.get("plan", {}).get("id"),
            "updatedAt": firestore.SERVER_TIMESTAMP,
        }, merge=True)


def _handle_payment_failed(invoice: dict[str, Any]):
    db.collection("payment_failures").add({
        "invoiceId": invoice.get("id"),
        "customer": invoice.get("customer"),
        "amount": invoice.get("amount_due", 0) / 100,
        "ts": firestore.SERVER_TIMESTAMP,
    })


# ── Fighters ──────────────────────────────────────────────────────────────────
@app.get("/fighters")
def get_fighters(limit: int = 50, weight_class: str | None = None):
    query = db.collection("fighters").limit(limit)
    if weight_class:
        query = query.where("weightClass", "==", weight_class)
    docs = query.stream()
    return [{"id": d.id, **d.to_dict()} for d in docs]


@app.get("/fighters/{fighter_id}")
def get_fighter(fighter_id: str):
    doc = db.collection("fighters").document(fighter_id).get()
    if not doc.exists:
        raise HTTPException(status_code=404, detail="Fighter not found")
    return {"id": doc.id, **doc.to_dict()}


# ── Events ────────────────────────────────────────────────────────────────────
@app.get("/events")
def get_events(limit: int = 20, status: str = "upcoming"):
    docs = (
        db.collection("events")
        .where("status", "==", status)
        .order_by("eventDate")
        .limit(limit)
        .stream()
    )
    return [{"id": d.id, **d.to_dict()} for d in docs]


@app.get("/events/{event_id}")
def get_event(event_id: str):
    doc = db.collection("events").document(event_id).get()
    if not doc.exists:
        raise HTTPException(status_code=404, detail="Event not found")
    return {"id": doc.id, **doc.to_dict()}


# ── PPV ───────────────────────────────────────────────────────────────────────
@app.get("/ppv")
def get_ppv_events(limit: int = 20):
    docs = db.collection("ppv_events").limit(limit).stream()
    return [{"id": d.id, **d.to_dict()} for d in docs]


@app.post("/ppv/{event_id}/purchase")
async def purchase_ppv(event_id: str, request: Request):
    body = await request.json()
    user_id = body.get("userId")
    if not user_id:
        raise HTTPException(status_code=400, detail="userId required")

    # Create Stripe checkout session
    event_doc = db.collection("ppv_events").document(event_id).get()
    if not event_doc.exists:
        raise HTTPException(status_code=404, detail="PPV event not found")

    event_data = event_doc.to_dict()
    price_aud = int((event_data.get("priceAUD", 49.99)) * 100)

    session = stripe.checkout.Session.create(
        payment_method_types=["card"],
        line_items=[{
            "price_data": {
                "currency": "aud",
                "product_data": {"name": event_data.get("title", "DFC PPV Event")},
                "unit_amount": price_aud,
            },
            "quantity": 1,
        }],
        mode="payment",
        success_url="https://datafightcentral.com/ppv-stream/" + event_id,
        cancel_url="https://datafightcentral.com/ppv",
        metadata={"eventId": event_id, "userId": user_id},
    )

    return {"checkoutUrl": session.url, "sessionId": session.id}


# ── Gyms ──────────────────────────────────────────────────────────────────────
@app.get("/gyms")
def get_gyms(limit: int = 50, city: str | None = None):
    query = db.collection("gyms").limit(limit)
    if city:
        query = query.where("city", "==", city)
    docs = query.stream()
    return [{"id": d.id, **d.to_dict()} for d in docs]


# ── Economy ───────────────────────────────────────────────────────────────────
@app.get("/economy/promoter/{promoter_id}")
def get_promoter_economy(promoter_id: str):
    doc = db.collection("promoter_economy").document(promoter_id).get()
    return {"id": promoter_id, **(doc.to_dict() if doc.exists else {})}


@app.get("/economy/fighter/{fighter_id}")
def get_fighter_economy(fighter_id: str):
    doc = db.collection("fighter_economy").document(fighter_id).get()
    return {"id": fighter_id, **(doc.to_dict() if doc.exists else {})}


# ── Feed ──────────────────────────────────────────────────────────────────────
@app.get("/feed")
def get_feed(limit: int = 30, source: str | None = None):
    query = db.collection("posts").order_by("createdAt", direction=firestore.Query.DESCENDING).limit(limit)
    if source:
        query = query.where("source", "==", source)
    docs = query.stream()
    return [{"id": d.id, **d.to_dict()} for d in docs]

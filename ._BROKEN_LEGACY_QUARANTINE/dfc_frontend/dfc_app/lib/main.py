import logging
from fastapi import FastAPI, HTTPException
from google.cloud import firestore
from datetime import datetime
from models import EventCreate, EventUpdate, FightCreate

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)

app = FastAPI(title="DFC Event Service", version="1.0.0")

def db():
  return firestore.Client()

@app.get("/events")
def list_events():
  docs = db().collection("events").stream()
  return [d.to_dict() | {"id": d.id} for d in docs]

@app.post("/events")
def create_event(payload: EventCreate):
  ref = db().collection("events").document()
  data = payload.dict()
  data["created_at"] = datetime.utcnow().isoformat()
  ref.set(data)
  return {"id": ref.id, **data}

@app.get("/events/{event_id}")
def get_event(event_id: str):
  doc = db().collection("events").document(event_id).get()
  if not doc.exists:
    raise HTTPException(status_code=404, detail="Event not found")
  return {"id": doc.id, **doc.to_dict()}

@app.put("/events/{event_id}")
def update_event(event_id: str, payload: EventUpdate):
  ref = db().collection("events").document(event_id)
  if not ref.get().exists:
    raise HTTPException(status_code=404, detail="Event not found")
  update = {k: v for k, v in payload.dict().items() if v is not None}
  ref.update(update)
  return {"status": "updated"}

@app.post("/events/{event_id}/fights")
def add_fight(event_id: str, payload: FightCreate):
  event_ref = db().collection("events").document(event_id)
  if not event_ref.get().exists:
    raise HTTPException(status_code=404, detail="Event not found")
  fight_ref = event_ref.collection("fights").document()
  fight_ref.set(payload.dict())
  return {"id": fight_ref.id, **payload.dict()}
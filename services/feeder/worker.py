import os
import time

import psycopg2
import requests

DATABASE_URL = os.environ.get(
    "DATABASE_URL",
    "postgresql://dfc_admin:dfc-local-postgres-change-me@db:5432/dfc",
)
POSTER_SERVICE = os.environ.get("POSTER_SERVICE", "http://poster-service:8081/generate")
FEED_SERVICE = os.environ.get("FEED_SERVICE", "")
POLL_SECONDS = int(os.environ.get("FEEDER_POLL_SECONDS", "30"))


def process_events():
    conn = psycopg2.connect(DATABASE_URL)
    cur = conn.cursor()
    try:
        cur.execute(
            """
            SELECT id, name
            FROM events
            WHERE status = 'scheduled' AND COALESCE(processed, FALSE) = FALSE
            ORDER BY start_at ASC NULLS LAST
            LIMIT 10
            """
        )
        rows = cur.fetchall()
        if not rows:
            return 0

        for event_id, name in rows:
            try:
                poster_resp = requests.post(
                    POSTER_SERVICE,
                    json={"event_id": event_id, "title": name},
                    timeout=20,
                )
                poster_resp.raise_for_status()
                poster_data = poster_resp.json()

                cur.execute(
                    "INSERT INTO posters (event_id, storage_path, template) VALUES (%s, %s, %s)",
                    (event_id, poster_data.get("storage_path"), "stub"),
                )

                if FEED_SERVICE:
                    requests.post(
                        FEED_SERVICE,
                        json={
                            "event_id": event_id,
                            "title": name,
                            "body": "Tickets and PPV available",
                        },
                        timeout=10,
                    )
                else:
                    cur.execute(
                        "INSERT INTO feed_items (event_id, title, body) VALUES (%s, %s, %s)",
                        (event_id, name, "Tickets and PPV available"),
                    )

                cur.execute("UPDATE events SET processed = TRUE WHERE id = %s", (event_id,))
                conn.commit()
                print(f"Processed event {event_id}")
            except Exception as exc:
                conn.rollback()
                print(f"Failed processing event {event_id}: {exc}")

        return len(rows)
    finally:
        cur.close()
        conn.close()


if __name__ == "__main__":
    while True:
        try:
            process_events()
        except Exception as exc:
            print(f"Worker loop error: {exc}")
        time.sleep(POLL_SECONDS)

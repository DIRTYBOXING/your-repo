import datetime
import os

import psycopg2
from psycopg2.extras import execute_values

DATABASE_URL = os.environ.get(
    "DATABASE_URL",
    "postgresql://dfc_admin:dfc-local-postgres-change-me@localhost:5432/dfc",
)


def ensure_schema(cur):
    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS events (
          id SERIAL PRIMARY KEY,
          external_id TEXT UNIQUE,
          name TEXT,
          start_at TIMESTAMP,
          venue TEXT,
          status TEXT,
          processed BOOLEAN DEFAULT FALSE,
          created_at TIMESTAMP DEFAULT now()
        );

        CREATE TABLE IF NOT EXISTS matchups (
          id SERIAL PRIMARY KEY,
          event_id INT REFERENCES events(id),
          fighter_a TEXT,
          fighter_b TEXT,
          weight_class TEXT,
          scheduled_rounds INT,
          is_title BOOLEAN DEFAULT FALSE,
          result JSONB,
          created_at TIMESTAMP DEFAULT now()
        );

        CREATE TABLE IF NOT EXISTS posters (
          id SERIAL PRIMARY KEY,
          event_id INT REFERENCES events(id),
          storage_path TEXT,
          template TEXT,
          generated_at TIMESTAMP DEFAULT now()
        );

        CREATE TABLE IF NOT EXISTS ppv_products (
          id SERIAL PRIMARY KEY,
          event_id INT REFERENCES events(id),
          sku TEXT UNIQUE,
          price_cents INT,
          currency TEXT,
          available BOOLEAN DEFAULT TRUE,
          created_at TIMESTAMP DEFAULT now()
        );

        CREATE TABLE IF NOT EXISTS feed_items (
          id SERIAL PRIMARY KEY,
          event_id INT REFERENCES events(id),
          title TEXT,
          body TEXT,
          created_at TIMESTAMP DEFAULT now()
        );
        """
    )


def seed():
    conn = psycopg2.connect(DATABASE_URL)
    cur = conn.cursor()
    try:
        ensure_schema(cur)

        cur.execute(
            """
            INSERT INTO events (external_id, name, start_at, venue, status)
            VALUES (%s, %s, %s, %s, %s)
            ON CONFLICT (external_id)
            DO UPDATE SET name = EXCLUDED.name, start_at = EXCLUDED.start_at, venue = EXCLUDED.venue, status = EXCLUDED.status
            RETURNING id
            """,
            ("UFC999", "UFC 999", datetime.datetime.utcnow(), "T-Mobile Arena", "scheduled"),
        )
        event_id = cur.fetchone()[0]

        matchups = [
            ("Alex Pereira", "Jiri Prochazka", "light heavyweight", 5, True),
            ("Leon Edwards", "Belal Muhammad", "welterweight", 5, True),
        ]
        execute_values(
            cur,
            """
            INSERT INTO matchups (event_id, fighter_a, fighter_b, weight_class, scheduled_rounds, is_title)
            VALUES %s
            ON CONFLICT DO NOTHING
            """,
            [(event_id, *m) for m in matchups],
        )

        cur.execute(
            """
            INSERT INTO ppv_products (event_id, sku, price_cents, currency, available)
            VALUES (%s, %s, %s, %s, %s)
            ON CONFLICT (sku)
            DO UPDATE SET price_cents = EXCLUDED.price_cents, currency = EXCLUDED.currency, available = EXCLUDED.available
            """,
            (event_id, "PPV-UFC999", 4999, "USD", True),
        )

        conn.commit()
        print(f"Seeded UFC999 event id={event_id}")
    finally:
        cur.close()
        conn.close()


if __name__ == "__main__":
    seed()

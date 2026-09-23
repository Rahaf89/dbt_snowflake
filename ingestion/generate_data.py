"""Generate deterministic synthetic marketing data for the Northwind dbt project.

Usage:
    python generate_data.py --out ../raw_data
"""

from __future__ import annotations

import argparse
import csv
import random
import uuid
from datetime import date, datetime, timedelta
from pathlib import Path

from faker import Faker

SEED = 42
fake = Faker()
Faker.seed(SEED)
random.seed(SEED)

CHANNELS = ["organic", "google_ads", "meta_ads", "email", "direct"]
EVENT_TYPES = ["page_view", "product_view", "add_to_cart", "checkout", "purchase"]
CURRENCIES = ["USD", "EUR", "GBP"]


def write_csv(path: Path, fieldnames: list[str], rows: list[dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def generate_customers(n: int) -> list[dict]:
    start = date.today() - timedelta(days=730)
    rows = []
    for customer_id in range(1, n + 1):
        signup_date = start + timedelta(days=random.randint(0, 650))
        rows.append(
            {
                "customer_id": customer_id,
                "email": fake.email(),
                "signup_date": signup_date.isoformat(),
                "acquisition_channel": random.choice(CHANNELS),
            }
        )
    return rows


def generate_orders(customers: list[dict], n: int) -> list[dict]:
    rows = []
    now = datetime.now().replace(microsecond=0)
    customer_ids = [c["customer_id"] for c in customers]
    for order_id in range(1, n + 1):
        ts = now - timedelta(
            days=random.randint(0, 365),
            hours=random.randint(0, 23),
            minutes=random.randint(0, 59),
        )
        rows.append(
            {
                "order_id": order_id,
                "customer_id": random.choice(customer_ids),
                "order_timestamp": ts.isoformat(sep=" "),
                "amount": round(random.uniform(15, 450), 2),
                "currency": random.choice(CURRENCIES),
                "is_refunded": random.random() < 0.08,
            }
        )
    return rows


def generate_web_events(customers: list[dict], n: int) -> list[dict]:
    rows = []
    now = datetime.now().replace(microsecond=0)
    customer_ids = [c["customer_id"] for c in customers]

    for _ in range(n):
        customer_id = random.choice(customer_ids)
        session_id = str(uuid.uuid4())
        event_timestamp = now - timedelta(
            days=random.randint(0, 365),
            hours=random.randint(0, 23),
            minutes=random.randint(0, 59),
        )
        rows.append(
            {
                "event_id": str(uuid.uuid4()),
                "session_id": session_id,
                "customer_id": customer_id,
                "event_timestamp": event_timestamp.isoformat(sep=" "),
                "channel": random.choice(CHANNELS),
                "event_type": random.choice(EVENT_TYPES),
                "is_bot": random.random() < 0.03,
            }
        )
    return rows


def generate_ad_spend(platform: str, days: int = 180, campaigns: int = 4) -> list[dict]:
    rows = []
    today = date.today()
    for day_offset in range(days):
        spend_date = today - timedelta(days=day_offset)
        for campaign_num in range(1, campaigns + 1):
            impressions = random.randint(2_000, 60_000)
            ctr = random.uniform(0.008, 0.055)
            clicks = max(1, round(impressions * ctr))
            cpc = random.uniform(0.35, 2.80)
            rows.append(
                {
                    "date": spend_date.isoformat(),
                    "platform": platform,
                    "campaign_id": f"{platform[:2].upper()}-{campaign_num:03d}",
                    "campaign_name": f"{platform} campaign {campaign_num}",
                    "impressions": impressions,
                    "clicks": clicks,
                    "spend": round(clicks * cpc, 2),
                }
            )
    return rows


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", default="../raw_data", help="Output directory")
    parser.add_argument("--customers", type=int, default=2000)
    parser.add_argument("--orders", type=int, default=5000)
    parser.add_argument("--events", type=int, default=20000)
    args = parser.parse_args()

    out = Path(args.out).resolve()

    customers = generate_customers(args.customers)
    orders = generate_orders(customers, args.orders)
    events = generate_web_events(customers, args.events)
    google = generate_ad_spend("google_ads")
    meta = generate_ad_spend("meta_ads")

    write_csv(
        out / "customers.csv",
        ["customer_id", "email", "signup_date", "acquisition_channel"],
        customers,
    )
    write_csv(
        out / "orders.csv",
        ["order_id", "customer_id", "order_timestamp", "amount", "currency", "is_refunded"],
        orders,
    )
    write_csv(
        out / "web_events.csv",
        [
            "event_id",
            "session_id",
            "customer_id",
            "event_timestamp",
            "channel",
            "event_type",
            "is_bot",
        ],
        events,
    )
    ad_fields = [
        "date",
        "platform",
        "campaign_id",
        "campaign_name",
        "impressions",
        "clicks",
        "spend",
    ]
    write_csv(out / "google_ads_spend.csv", ad_fields, google)
    write_csv(out / "meta_ads_spend.csv", ad_fields, meta)

    print(f"Generated source data in: {out}")
    for path in sorted(out.glob("*.csv")):
        print(f"  - {path.name}")


if __name__ == "__main__":
    main()

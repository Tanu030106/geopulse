"""
Day 3 — Generate 5,000 mock store point locations for GeoPulse.

Produces a CSV that Day 3/4 SQL loads into RAW.raw_store_locations.
Coordinates are scattered around a chosen city's bounding box so they
look like a real metro area (adjust CITY_BOUNDS for your demo city).

Usage:
    pip install pandas numpy
    python generate_mock_stores.py --out stores.csv --n 5000 --city bengaluru
"""
import argparse
import csv
import random

# Rough lat/long bounding boxes for a few demo cities — pick one, or add your own
CITY_BOUNDS = {
    "bengaluru": {"lat": (12.85, 13.10), "lon": (77.45, 77.75)},
    "nyc":       {"lat": (40.55, 40.90), "lon": (-74.05, -73.75)},
    "delhi_ncr": {"lat": (28.40, 28.90), "lon": (76.90, 77.35)},
}


def generate_stores(n: int, city: str, seed: int = 42):
    bounds = CITY_BOUNDS[city]
    rng = random.Random(seed)
    rows = []
    for i in range(1, n + 1):
        lat = rng.uniform(*bounds["lat"])
        lon = rng.uniform(*bounds["lon"])
        rows.append({
            "store_id": f"STORE_{i:05d}",
            "store_name": f"Coffee Chain #{i:05d}",
            "latitude": round(lat, 6),
            "longitude": round(lon, 6),
        })
    return rows


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="stores.csv")
    ap.add_argument("--n", type=int, default=5000)
    ap.add_argument("--city", default="bengaluru", choices=CITY_BOUNDS.keys())
    ap.add_argument("--seed", type=int, default=42)
    args = ap.parse_args()

    rows = generate_stores(args.n, args.city, args.seed)
    with open(args.out, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=["store_id", "store_name", "latitude", "longitude"])
        writer.writeheader()
        writer.writerows(rows)

    print(f"Wrote {len(rows)} mock stores to {args.out} (city={args.city})")


if __name__ == "__main__":
    main()

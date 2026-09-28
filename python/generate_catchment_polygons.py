"""
Day 7 — Generate a 500-meter catchment polygon (circle, approximated as
a 32-sided polygon) around every store location.

Two ways to use this:
1. Standalone (this script): reads stores.csv, writes catchments.csv
   with a WKT polygon per store, which Day 8 SQL loads as GEOGRAPHY.
2. Snowflake-native alternative: Snowflake can also do this in pure SQL
   with ST_BUFFER (see day07_catchment_sql_alternative.sql) — use
   whichever your team prefers; this Python version is handy if you
   want to hand the same polygons to Member 2's Sedona job too.

Usage:
    pip install pandas
    python generate_catchment_polygons.py --stores stores.csv --out catchments.csv --radius_m 500
"""
import argparse
import csv
import math

EARTH_RADIUS_M = 6371000


def buffer_circle_wkt(lat: float, lon: float, radius_m: float, sides: int = 32) -> str:
    """Return a WKT POLYGON approximating a `radius_m` circle around (lat, lon)."""
    points = []
    for i in range(sides + 1):  # +1 to close the ring
        angle = 2 * math.pi * i / sides
        d_lat = (radius_m * math.cos(angle)) / EARTH_RADIUS_M
        d_lon = (radius_m * math.sin(angle)) / (EARTH_RADIUS_M * math.cos(math.radians(lat)))
        pt_lat = lat + math.degrees(d_lat)
        pt_lon = lon + math.degrees(d_lon)
        points.append(f"{pt_lon:.7f} {pt_lat:.7f}")  # WKT is (lon lat)
    ring = ", ".join(points)
    return f"POLYGON(({ring}))"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--stores", default="stores.csv")
    ap.add_argument("--out", default="catchments.csv")
    ap.add_argument("--radius_m", type=float, default=500)
    args = ap.parse_args()

    with open(args.stores, newline="") as f_in, open(args.out, "w", newline="") as f_out:
        reader = csv.DictReader(f_in)
        writer = csv.DictWriter(f_out, fieldnames=["store_id", "catchment_wkt", "radius_m"])
        writer.writeheader()
        n = 0
        for row in reader:
            wkt = buffer_circle_wkt(float(row["latitude"]), float(row["longitude"]), args.radius_m)
            writer.writerow({"store_id": row["store_id"], "catchment_wkt": wkt, "radius_m": args.radius_m})
            n += 1

    print(f"Wrote {n} catchment polygons ({args.radius_m}m radius) to {args.out}")


if __name__ == "__main__":
    main()

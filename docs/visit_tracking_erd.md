# Visit Tracking — Table Relationships (Day 15)

## Entity relationship (text ERD)

```
raw_store_locations (1) ───────< (many) store_catchment_polygons
        │  store_id                        │ store_id
        │                                  │
        │                                  ▼
        │                         (used by Sedona ST_Intersects join)
        │
        └───────< (many) device_visit_log >──────── raw_device_pings
                store_id, device_id              device_id (loosely — pings
                                                   are consumed by Sedona,
                                                   not directly FK'd here)
```

## Relationships

- **`raw_store_locations` → `store_catchment_polygons`**: 1-to-1. Every
  store gets exactly one 500m catchment polygon (`store_id` is the join key).
- **`store_catchment_polygons` + `raw_device_pings` → `device_visit_log`**:
  many-to-many, resolved by Member 2's Sedona `ST_Intersects` spatial join.
  A device's pings can fall inside multiple stores' catchments at once
  (`is_multi_store = TRUE`), which is exactly the signal Member 3's
  cannibalization model (`fct_cannibalization.sql`) needs.
- **`device_visit_log`**: the single table that bridges the spatial layer
  (this track) and the modeling layer (dbt, Member 3). One row = one
  continuous visit by one device to one store.

## Why this shape
- Keeping `device_visit_log` at visit-grain (not raw-ping-grain) keeps
  the table orders of magnitude smaller than `raw_device_pings`, which
  is what makes the multi-store lookups in Day 13 fast.
- `is_multi_store` is pre-computed here (by Sedona) rather than
  recomputed in dbt, since it requires the full spatial join Snowflake
  alone can't do efficiently at this scale.

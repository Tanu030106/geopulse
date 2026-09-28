# GeoPulse — Snowflake Schema Design (Member 1)
*Written Day 10 — mid-project review checkpoint*

## Database / schema layout

```
GEOPULSE_DB
├── RAW          -- landing zone, unmodified loaded data
│   ├── raw_device_pings
│   └── raw_store_locations
├── STAGING      -- cleaned/derived spatial data (this track) + dbt staging (Member 3)
│   ├── store_catchment_polygons
│   └── device_visit_log        (added Day 11-12)
└── ANALYTICS    -- dbt marts (footfall, cannibalization) — owned by Member 3
```

## Table reference

| Table | Schema | Grain | Notes |
|---|---|---|---|
| `raw_device_pings` | RAW | 1 row per GPS ping | Loaded via COPY INTO from CSV/Parquet, `ping_geo` is `GEOGRAPHY` |
| `raw_store_locations` | RAW | 1 row per store | 5,000 mock stores, `store_geo` is `GEOGRAPHY` (Point) |
| `store_catchment_polygons` | STAGING | 1 row per store | 500m buffer polygon around each store, `catchment_geo` is `GEOGRAPHY` (Polygon) |
| `device_visit_log` | STAGING | 1 row per device × store × visit | Populated from Member 2's Sedona spatial-join output |

## Naming conventions
- Databases: `GEOPULSE_DB`
- Schemas: `RAW`, `STAGING`, `ANALYTICS`
- Tables: `snake_case`, domain noun + purpose (e.g. `raw_device_pings`)
- Geography columns always suffixed `_geo`
- Warehouse: `GEOPULSE_WH` (XSMALL by default, scaled up only for big spatial jobs)

## Catchment pipeline (Day 7-8)
1. `generate_mock_stores.py` → `stores.csv` (5,000 stores)
2. Load into `RAW.raw_store_locations` (Day 3)
3. Either:
   - `generate_catchment_polygons.py` → WKT CSV → `COPY INTO STAGING.store_catchment_polygons`, **or**
   - Pure-SQL `ST_BUFFER(store_geo, 500)` (Day 7 alternative script)
4. Validate every catchment `ST_CONTAINS` its own store point (Day 8)

## Access / roles
- Single shared role `GEOPULSE_DEV` for the 4-person team, granted `ALL` on `GEOPULSE_DB`
- Each teammate has their own Snowflake user, granted the shared role

from etl.extract import extract
from etl.transform import transform
from etl.load import load
import time

# ------------------------------------------------------------------
# pipeline.py — orchestrates the full ETL run in sequence
#
# Why have a pipeline file at all?
# In production, pipelines are triggered automatically (by Airflow,
# cron jobs, or cloud schedulers). Having a single entry point means
# you can trigger the whole pipeline with one command, one schedule,
# or one CI/CD step — without manually running each phase.
# ------------------------------------------------------------------

# File paths — defined once here so you never hardcode them in each module
RAW_FILE     = "data/raw/chicago_Food_Inspections.csv"
PARQUET_FILE = "data/parquet/chicago_food_inspections_clean.parquet"

def run_pipeline():
    print("=" * 60)
    print("ETL PIPELINE — Chicago Food Inspections")
    print("=" * 60)

    # --- Phase 2: Extract ---
    print("\n[PIPELINE] Starting EXTRACT phase...")
    start = time.time()
    df_raw = extract(RAW_FILE)
    print(f"[PIPELINE] EXTRACT complete in {time.time() - start:.2f}s")

    # --- Phase 3: Transform ---
    print("\n[PIPELINE] Starting TRANSFORM phase...")
    start = time.time()
    df_clean = transform(df_raw, PARQUET_FILE)
    print(f"[PIPELINE] TRANSFORM complete in {time.time() - start:.2f}s")

    # --- Phase 4: Load ---
    print("\n[PIPELINE] Starting LOAD phase...")
    start = time.time()
    load(PARQUET_FILE)
    print(f"[PIPELINE] LOAD complete in {time.time() - start:.2f}s")

    print("\n" + "=" * 60)
    print("[PIPELINE] ✅ Full pipeline run complete")
    print("=" * 60)

if __name__ == "__main__":
    run_pipeline()
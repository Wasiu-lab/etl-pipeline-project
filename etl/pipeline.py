import os
import time
from etl.extract import extract
from etl.transform import transform
from etl.load import load

# ------------------------------------------------------------------
# Paths are read from environment variables.
# Locally:  .env sets these to local file paths
# Lambda:   Terraform sets these to S3 URIs via Lambda env vars
# This means the same pipeline.py runs in both environments —
# only the environment variables change.
# ------------------------------------------------------------------

RAW_FILE     = os.getenv("RAW_FILE_PATH",     "data/raw/chicago_Food_Inspections.csv")
PARQUET_FILE = os.getenv("PARQUET_FILE_PATH", "data/parquet/chicago_food_inspections_clean.parquet")

def run_pipeline():
    print("=" * 60)
    print("ETL PIPELINE - Chicago Food Inspections")
    print("=" * 60)

    print("\n[PIPELINE] Starting EXTRACT phase...")
    start = time.time()
    df_raw = extract(RAW_FILE)
    print(f"[PIPELINE] EXTRACT complete in {time.time() - start:.2f}s")

    print("\n[PIPELINE] Starting TRANSFORM phase...")
    start = time.time()
    df_clean = transform(df_raw, PARQUET_FILE)
    print(f"[PIPELINE] TRANSFORM complete in {time.time() - start:.2f}s")

    print("\n[PIPELINE] Starting LOAD phase...")
    start = time.time()
    load(PARQUET_FILE)
    print(f"[PIPELINE] LOAD complete in {time.time() - start:.2f}s")

    print("\n" + "=" * 60)
    print("[PIPELINE] Full pipeline run complete")
    print("=" * 60)

if __name__ == "__main__":
    run_pipeline()
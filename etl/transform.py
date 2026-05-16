import pandas as pd
import pyarrow as pa
import pyarrow.parquet as pq
import boto3
import os
import io

def transform(df: pd.DataFrame, output_path: str) -> pd.DataFrame:
    """
    Transform phase — cleans the Chicago Food Inspections DataFrame
    and writes the result to Parquet.

    Supports both local output paths and S3 URIs:
      Local:  'data/parquet/chicago_food_inspections_clean.parquet'
      S3:     's3://your-bucket/parquet/chicago_food_inspections_clean.parquet'

    Args:
        df:           raw DataFrame from extract phase
        output_path:  local path or S3 URI for the Parquet output

    Returns:
        A cleaned, typed pandas DataFrame
    """

    print(f"[TRANSFORM] Starting transform on {len(df):,} rows...")

    # ------------------------------------------------------------------
    # Step 1: Standardise column names
    # ------------------------------------------------------------------
    df.columns = (
        df.columns
        .str.strip()
        .str.lower()
        .str.replace(" ", "_", regex=False)
        .str.replace(r"[^a-z0-9_]", "", regex=True)
    )
    print(f"[TRANSFORM] Columns renamed: {df.columns.tolist()}")

    # ------------------------------------------------------------------
    # Step 2: Select columns
    # ------------------------------------------------------------------
    columns_to_keep = [
        "inspection_id", "dba_name", "aka_name", "license_",
        "facility_type", "risk", "address", "city", "state",
        "zip", "inspection_date", "inspection_type", "results",
        "violations", "latitude", "longitude",
    ]
    columns_to_keep = [c for c in columns_to_keep if c in df.columns]
    df = df[columns_to_keep]
    print(f"[TRANSFORM] Kept {len(columns_to_keep)} columns")

    # ------------------------------------------------------------------
    # Step 3: Rename awkward columns
    # ------------------------------------------------------------------
    df = df.rename(columns={
        "license_":  "license_number",
        "dba_name":  "business_name",
    })

    # ------------------------------------------------------------------
    # Step 4: Fix data types
    # ------------------------------------------------------------------
    df["inspection_date"] = pd.to_datetime(df["inspection_date"], errors="coerce")
    df["license_number"]  = pd.to_numeric(df["license_number"],   errors="coerce")
    df["inspection_id"]   = pd.to_numeric(df["inspection_id"],    errors="coerce")
    df["zip"]             = pd.to_numeric(df["zip"],              errors="coerce")
    df["latitude"]        = pd.to_numeric(df["latitude"],         errors="coerce")
    df["longitude"]       = pd.to_numeric(df["longitude"],        errors="coerce")
    print("[TRANSFORM] Data types cast")

    # ------------------------------------------------------------------
    # Step 5: Handle nulls
    # ------------------------------------------------------------------
    df["violations"]    = df["violations"].fillna("No Violations Recorded")
    df["aka_name"]      = df["aka_name"].fillna(df["business_name"])
    df["facility_type"] = df["facility_type"].fillna("Unknown")
    df["risk"]          = df["risk"].fillna("Unknown")
    df = df[df["business_name"].notna()]
    df = df[df["results"].notna()]
    df = df[df["inspection_date"].notna()]
    print(f"[TRANSFORM] After null handling: {len(df):,} rows remain")

    # ------------------------------------------------------------------
    # Step 6: Clean risk column
    # ------------------------------------------------------------------
    df["risk_level"] = (
        df["risk"]
        .str.extract(r"\((.*?)\)")
        .squeeze()
        .fillna("Unknown")
    )

    # ------------------------------------------------------------------
    # Step 7: Standardise results
    # ------------------------------------------------------------------
    df["results"] = df["results"].str.strip().str.title()

    # ------------------------------------------------------------------
    # Step 8: Add derived columns
    # ------------------------------------------------------------------
    df["inspection_year"]        = df["inspection_date"].dt.year
    df["inspection_month"]       = df["inspection_date"].dt.month
    df["inspection_day_of_week"] = df["inspection_date"].dt.dayofweek
    df["is_pass"]                = df["results"].str.contains("Pass", case=False, na=False)
    df["is_fail"]                = df["results"].str.contains("Fail", case=False, na=False)
    df["is_high_risk"]           = df["risk_level"].str.upper() == "HIGH"
    df["violation_count"]        = df["violations"].apply(
        lambda x: len(x.split("|")) if x != "No Violations Recorded" else 0
    )
    print("[TRANSFORM] Derived columns added")

    # ------------------------------------------------------------------
    # Step 9: Write Parquet — local or S3
    # ------------------------------------------------------------------
    table = pa.Table.from_pandas(df)

    if output_path.startswith("s3://"):
        print(f"[TRANSFORM] Writing Parquet to S3: {output_path}")

        # Parse S3 URI
        path_parts  = output_path.replace("s3://", "").split("/", 1)
        bucket_name = path_parts[0]
        s3_key      = path_parts[1]

        # Write Parquet to an in-memory buffer then upload to S3
        # Lambda has no persistent disk — everything must go through memory or S3
        buffer = io.BytesIO()
        pq.write_table(table, buffer)
        buffer.seek(0)   # rewind buffer to start before uploading

        s3_client = boto3.client("s3")
        s3_client.put_object(
            Bucket=bucket_name,
            Key=s3_key,
            Body=buffer.getvalue()
        )

    else:
        print(f"[TRANSFORM] Writing Parquet locally: {output_path}")
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        pq.write_table(table, output_path)

    print(f"[TRANSFORM] Parquet written to: {output_path}")
    print(f"[TRANSFORM] Final shape: {df.shape[0]:,} rows x {df.shape[1]} columns")
    return df
import pandas as pd
import pyarrow as pa
import pyarrow.parquet as pq
import os

def transform(df: pd.DataFrame, output_path: str) -> pd.DataFrame:
    """
    Transform phase — cleans and reshapes the raw DataFrame, then writes to Parquet.

    Why this is its own function:
    Transformation logic is the most complex part of any pipeline.
    Isolating it means you can test, modify, or replace it without
    touching extract or load logic.

    Args:
        df:           raw DataFrame from extract phase
        output_path:  where to write the Parquet file

    Returns:
        A cleaned, typed pandas DataFrame
    """

    print(f"[TRANSFORM] Starting transform on {len(df):,} rows...")

    # ------------------------------------------------------------------
    # Step 1: Standardise column names
    # Strip whitespace, lowercase everything, replace spaces with underscores
    # This gives you consistent, Pythonic column names to work with
    # ------------------------------------------------------------------
    df.columns = (
        df.columns
        .str.strip()
        .str.lower()
        .str.replace(" ", "_", regex=False)
        .str.replace(r"[^a-z0-9_]", "", regex=True)  # remove special chars
    )

    print(f"[TRANSFORM] Columns renamed: {df.columns.tolist()}")

    # ------------------------------------------------------------------
    # Step 2: Select only the columns you actually need
    # Dropping irrelevant columns keeps your warehouse lean
    # ------------------------------------------------------------------
    columns_to_keep = [
        "inspection id",           
        "dba name",               
        "aka name",              
        "license",     
        "facility type",          
        "risk",          
        "address",
        "city",    
        "state",          
        "zip",    
        "inspection date", 
        "inspection type",      
        "results"            
    ]

    # Only keep columns that actually exist in the dataset
    # (protects against schema changes in the source data)
    columns_to_keep = [c for c in columns_to_keep if c in df.columns]
    df = df[columns_to_keep]

    print(f"[TRANSFORM] Kept {len(columns_to_keep)} columns")

    # ------------------------------------------------------------------
    # Step 3: Fix data types
    # CSVs store everything as strings — you need to cast to proper types
    # errors='coerce' means invalid dates become NaT instead of crashing
    # ------------------------------------------------------------------
    df["inspection_date"] = pd.to_datetime(df["inspection_date"], errors="coerce")
    df["grade_date"]      = pd.to_datetime(df["grade_date"],      errors="coerce")
    df["zipcode"]         = pd.to_numeric(df["zipcode"],          errors="coerce")
    df["score"]           = pd.to_numeric(df["score"],            errors="coerce")
    df["camis"]           = pd.to_numeric(df["camis"],            errors="coerce")

    print("[TRANSFORM] Data types cast")

    # ------------------------------------------------------------------
    # Step 4: Handle nulls
    # Strategy depends on the column — there's no one-size-fits-all rule
    # ------------------------------------------------------------------

    # Score: null means no inspection was scored — treat as 0
    df["score"] = df["score"].fillna(0)

    # Grade: null means no grade assigned — label it clearly
    df["grade"] = df["grade"].fillna("N/A")

    # Critical flag: unknown = not flagged
    df["critical_flag"] = df["critical_flag"].fillna("Not Applicable")

    # Boro: drop rows where borough is completely unknown
    df = df[df["boro"].notna()]
    df = df[df["boro"] != "Missing"]

    # Drop rows with no restaurant name — unusable records
    df = df[df["dba"].notna()]

    print(f"[TRANSFORM] After null handling: {len(df):,} rows remain")

    # ------------------------------------------------------------------
    # Step 5: Add derived columns
    # These are columns that don't exist in the source but are useful
    # for analysis — calculated from existing data
    # ------------------------------------------------------------------

    # Inspection year — useful for year-over-year analysis
    df["inspection_year"] = df["inspection_date"].dt.year

    # Inspection month — useful for seasonal trend analysis
    df["inspection_month"] = df["inspection_date"].dt.month

    # Grade flag — binary column: did this restaurant get an A?
    df["is_grade_a"] = df["grade"].str.upper() == "A"

    print("[TRANSFORM] Derived columns added: inspection_year, inspection_month, is_grade_a")

    # ------------------------------------------------------------------
    # Step 6: Write to Parquet
    # pyarrow converts the pandas DataFrame to columnar Parquet format
    # This is your "data lake" layer — a clean, compressed copy of the data
    # ------------------------------------------------------------------
    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    table = pa.Table.from_pandas(df)
    pq.write_table(table, output_path)

    print(f"[TRANSFORM] Parquet written to: {output_path}")
    print(f"[TRANSFORM] Final shape: {df.shape[0]:,} rows x {df.shape[1]} columns")

    return df
import pandas as pd
import pyarrow as pa
import pyarrow.parquet as pq
import os

def transform(df: pd.DataFrame, output_path: str) -> pd.DataFrame:
    """
    Transform phase — cleans and reshapes the Chicago Food Inspections
    raw DataFrame, then writes the result to Parquet.

    Why this is its own function:
    Transformation logic is the most complex part of any pipeline.
    Isolating it means you can test, modify, or replace it without
    touching extract or load logic.

    Args:
        df:           raw DataFrame from extract phase
        output_path:  where to write the cleaned Parquet file

    Returns:
        A cleaned, typed pandas DataFrame
    """

    print(f"[TRANSFORM] Starting transform on {len(df):,} rows...")

    # ------------------------------------------------------------------
    # Step 1: Standardise column names
    # The raw dataset has mixed case, spaces, and special characters.
    # We strip whitespace, lowercase everything, replace spaces with
    # underscores, and remove any characters that aren't alphanumeric.
    # This gives you clean, consistent, Pythonic column names.
    # ------------------------------------------------------------------
    df.columns = (
        df.columns
        .str.strip()
        .str.lower()
        .str.replace(" ", "_", regex=False)
        .str.replace(r"[^a-z0-9_]", "", regex=True)
    )

    print(f"[TRANSFORM] Columns after rename: {df.columns.tolist()}")

    # ------------------------------------------------------------------
    # Step 2: Select only the columns you need
    # The dataset has 17 columns — some (like Location which duplicates
    # lat/lon) are redundant. We keep what's analytically useful.
    # Dropping noise keeps your warehouse lean and queries faster.
    # ------------------------------------------------------------------
    columns_to_keep = [
        "inspection_id",       # unique ID for each inspection
        "dba_name",            # business name (doing business as)
        "aka_name",            # alternative name if different
        "license_",            # business license number (note: raw name has trailing underscore)
        "facility_type",       # restaurant, school, grocery, etc.
        "risk",                # risk level: Risk 1 (High), Risk 2 (Medium), Risk 3 (Low)
        "address",             # street address
        "city",                # city
        "state",               # state
        "zip",                 # zip code
        "inspection_date",     # date the inspection took place
        "inspection_type",     # type: License, Canvass, Complaint, etc.
        "results",             # outcome: Pass, Fail, Pass w/ Conditions, etc.
        "violations",          # free-text list of violations found
        "latitude",            # geographic coordinate
        "longitude",           # geographic coordinate
    ]

    # Safety check: only keep columns that actually exist after renaming
    # This protects you if the source schema ever changes
    columns_to_keep = [c for c in columns_to_keep if c in df.columns]
    df = df[columns_to_keep]

    print(f"[TRANSFORM] Kept {len(columns_to_keep)} columns")

    # ------------------------------------------------------------------
    # Step 3: Rename awkward columns to cleaner names
    # The license column comes in as 'license_' (trailing underscore).
    # We rename it to something clean here.
    # ------------------------------------------------------------------
    df = df.rename(columns={
        "license_": "license_number",
        "dba_name": "business_name",
        "aka_name": "aka_name",
    })

    print("[TRANSFORM] Columns renamed to clean names")

    # ------------------------------------------------------------------
    # Step 4: Fix data types
    # CSVs store everything as strings — you need to explicitly cast
    # to the correct types so your database receives proper typed data.
    # errors='coerce' means bad values become NaT/NaN instead of crashing.
    # ------------------------------------------------------------------
    df["inspection_date"]  = pd.to_datetime(df["inspection_date"], errors="coerce")
    df["license_number"]   = pd.to_numeric(df["license_number"],   errors="coerce")
    df["inspection_id"]    = pd.to_numeric(df["inspection_id"],    errors="coerce")
    df["zip"]              = pd.to_numeric(df["zip"],              errors="coerce")
    df["latitude"]         = pd.to_numeric(df["latitude"],         errors="coerce")
    df["longitude"]        = pd.to_numeric(df["longitude"],        errors="coerce")

    print("[TRANSFORM] Data types cast")

    # ------------------------------------------------------------------
    # Step 5: Handle nulls
    # There is no single rule for nulls — strategy depends on what
    # each column represents. Document your decisions clearly.
    # ------------------------------------------------------------------

    # Violations: null means no violations were recorded during inspection therefore we can fill with no violations recorded
    df["violations"] = df["violations"].fillna("No Violations Recorded")

    # AKA name: not every business has another bname that it is called, so we fill with the business name
    df["aka_name"] = df["aka_name"].fillna(df["business_name"])

    # Facility type: unknown type — label it explicitly
    df["facility_type"] = df["facility_type"].fillna("Unknown")

    # Risk: unknown risk — label it explicitly
    df["risk"] = df["risk"].fillna("Unknown")

    # Drop rows with no business name — these records are unusable
    df = df[df["business_name"].notna()]

    # Drop rows with no inspection result — we can't analyse them
    df = df[df["results"].notna()]

    # Drop rows with no inspection date — no date = no timeline value
    df = df[df["inspection_date"].notna()]

    print(f"[TRANSFORM] After null handling: {len(df):,} rows remain")

    # ------------------------------------------------------------------
    # Step 6: Clean the 'risk' column
    # Raw values look like: 'Risk 1 (High)', 'Risk 2 (Medium)', 'Risk 3 (Low)'
    # We extract just the label: 'High', 'Medium', 'Low'
    # This makes it much easier to filter and group in SQL later
    # ------------------------------------------------------------------
    df["risk_level"] = (
        df["risk"]
        .str.extract(r"\((.*?)\)")   # extract text inside parentheses
        .squeeze()                    # convert single-column DataFrame to Series
        .fillna("Unknown")  # if no match, label as 'Unknown'
    )

    print("[TRANSFORM] risk_level column extracted from risk column")

    # ------------------------------------------------------------------
    # Step 7: Clean the 'results' column
    # Standardise casing so 'pass', 'Pass', 'PASS' all become 'Pass'
    # Also strip any leading/trailing whitespace
    # ------------------------------------------------------------------
    df["results"] = df["results"].str.strip().str.title()

    # ------------------------------------------------------------------
    # Step 8: Add derived columns
    # These don't exist in the source — you're engineering new features
    # that will make your SQL queries and analysis much more powerful.
    # ------------------------------------------------------------------

    # Inspection year — for year-over-year trend analysis
    df["inspection_year"] = df["inspection_date"].dt.year

    # Inspection month — for seasonal pattern analysis
    df["inspection_month"] = df["inspection_date"].dt.month

    # Inspection day of week — 0=Monday, 6=Sunday
    df["inspection_day_of_week"] = df["inspection_date"].dt.dayofweek

    # Pass flag — binary: did this inspection result in a pass?
    # Covers both 'Pass' and 'Pass W/ Conditions'
    df["is_pass"] = df["results"].str.contains("Pass", case=False, na=False)

    # Fail flag — binary: did this inspection result in a failure?
    df["is_fail"] = df["results"].str.contains("Fail", case=False, na=False)

    # High risk flag — binary: is this a high-risk facility?
    df["is_high_risk"] = df["risk_level"].str.upper() == "HIGH"

    # Violation count — how many violations were recorded?
    # Violations are pipe-separated in the raw data e.g. "1. ... | 2. ..."
    df["violation_count"] = df["violations"].apply(
        lambda x: len(x.split("|")) if x != "No Violations Recorded" else 0
    )

    print("[TRANSFORM] Derived columns added: inspection_year, inspection_month, "
          "inspection_day_of_week, is_pass, is_fail, is_high_risk, violation_count")

    # ------------------------------------------------------------------
    # Step 9: Write to Parquet
    # pyarrow serialises the cleaned DataFrame into columnar Parquet format.
    # This is your data lake layer — compressed, typed, and fast to query.
    # os.makedirs ensures the output folder exists before writing.
    # ------------------------------------------------------------------
    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    table = pa.Table.from_pandas(df)
    pq.write_table(table, output_path)

    print(f"[TRANSFORM] Parquet written to: {output_path}")
    print(f"[TRANSFORM] Final shape: {df.shape[0]:,} rows x {df.shape[1]} columns")

    return df
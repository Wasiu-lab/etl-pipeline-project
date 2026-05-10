import pandas as pd
from sqlalchemy import create_engine, text
from dotenv import load_dotenv
import os

def load(parquet_path: str) -> None:
    """
    Load phase — reads the cleaned Parquet file and loads it into MySQL.

    Why this is its own function:
    Keeping load logic separate means you can swap databases (MySQL → PostgreSQL
    → cloud) by only changing this file. The extract and transform phases
    don't need to know or care where the data ends up.

    Why we read from Parquet and not directly from the DataFrame:
    In a real pipeline, each phase runs independently — sometimes on different
    machines or at different times. Parquet is the handoff format between
    the transform layer and the load layer. Reading from Parquet here simulates
    that real-world separation.

    Args:
        parquet_path: path to the cleaned Parquet file from Phase 3
    """

    # ------------------------------------------------------------------
    # Step 1: Load environment variables from .env
    # load_dotenv() reads your .env file and makes values available via os.getenv()
    # ------------------------------------------------------------------
    load_dotenv()

    DB_HOST     = os.getenv("DB_HOST")
    DB_PORT     = os.getenv("DB_PORT")
    DB_NAME     = os.getenv("DB_NAME")
    DB_USER     = os.getenv("DB_USER")
    DB_PASSWORD = os.getenv("DB_PASSWORD")

    # ------------------------------------------------------------------
    # Step 2: Read the Parquet file back into a DataFrame
    # This is the handoff from the data lake layer (Parquet files on disk)
    # to the warehouse layer (MySQL database).
    # ------------------------------------------------------------------
    print(f"[LOAD] Reading Parquet file: {parquet_path}")
    df = pd.read_parquet(parquet_path)
    print(f"[LOAD] Loaded {len(df):,} rows from Parquet")

    # ------------------------------------------------------------------
    # Step 3: Fix data types before loading into MySQL
    # MySQL does not have a native boolean type — it uses TINYINT(1).
    # pandas boolean columns need to be cast to int (True → 1, False → 0)
    # MySQL also doesn't support pandas NA types for integers — cast those too.
    # ------------------------------------------------------------------
    bool_columns = ["is_pass", "is_fail", "is_high_risk"]
    for col in bool_columns:
        if col in df.columns:
            df[col] = df[col].astype(int)

    # Cast nullable integer columns to standard int where possible
    int_columns = ["inspection_id", "license_number", "violation_count",
                   "inspection_year", "inspection_month", "inspection_day_of_week"]
    for col in int_columns:
        if col in df.columns:
            # Int64 (capital I) is pandas nullable integer — convert to float first
            # to handle NaN, then to standard int-compatible nullable type
            df[col] = pd.to_numeric(df[col], errors="coerce")

    print("[LOAD] Data types prepared for MySQL")

    # ------------------------------------------------------------------
    # Step 4: Build the SQLAlchemy connection engine
    # SQLAlchemy is an abstraction layer — it lets you write the same
    # Python code regardless of which database you're connecting to.
    # The connection string format is: dialect+driver://user:pass@host:port/db
    # ------------------------------------------------------------------
    connection_string = (
        f"mysql+mysqlconnector://{DB_USER}:{DB_PASSWORD}"
        f"@{DB_HOST}:{DB_PORT}/{DB_NAME}"
    )

    engine = create_engine(connection_string)
    print(f"[LOAD] Connected to MySQL: {DB_NAME} on {DB_HOST}")

    # ------------------------------------------------------------------
    # Step 5: Load the DataFrame into MySQL
    # pandas .to_sql() does the heavy lifting here.
    #
    # Key parameters explained:
    #   name='food_inspections'  → the target table name
    #   con=engine               → your SQLAlchemy connection
    #   if_exists='replace'      → drop and recreate the table on each run
    #                              (use 'append' if you want incremental loads)
    #   index=False              → don't write the pandas row index as a column
    #   chunksize=1000           → insert 1000 rows at a time instead of all at once
    #                              this prevents memory issues on large datasets
    #   method='multi'           → batch INSERT statements — much faster than row-by-row
    # ------------------------------------------------------------------
    print(f"[LOAD] Loading {len(df):,} rows into MySQL table: food_inspections")

    df.to_sql(
        name="food_inspections",
        con=engine,
        if_exists="replace",
        index=False,
        chunksize=1000,
        method="multi"
    )

    print("[LOAD] Data loaded successfully")

    # ------------------------------------------------------------------
    # Step 6: Verify the row count in MySQL matches what we loaded
    # Always verify after loading — never assume it worked.
    # We query the table directly and compare the count to our DataFrame.
    # ------------------------------------------------------------------
    with engine.connect() as conn:
        result = conn.execute(text("SELECT COUNT(*) FROM food_inspections"))
        db_count = result.fetchone()[0]

    print(f"[LOAD] Verification — rows in DataFrame : {len(df):,}")
    print(f"[LOAD] Verification — rows in MySQL     : {db_count:,}")

    if len(df) == db_count:
        print("[LOAD] ✅ Row counts match — load successful")
    else:
        print("[LOAD] ⚠️  Row count mismatch — investigate before proceeding")
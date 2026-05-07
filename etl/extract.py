import pandas as pd
import os

def extract(filepath: str) -> pd.DataFrame:
    """
    Extract phase — reads raw CSV from disk into a pandas DataFrame.
    
    Why this exists as its own function:
    Separating extract from transform means if your data source changes
    (e.g. an API instead of a CSV), you only change this file — nothing else.

    Args:
        filepath: path to the raw CSV file

    Returns:
        A raw, unmodified pandas DataFrame
    """

    # Guard: check the file actually exists before trying to read it
    if not os.path.exists(filepath):
        raise FileNotFoundError(f"Raw file not found at: {filepath}")

    print(f"[EXTRACT] Reading file: {filepath}")

    # low_memory=False tells pandas to read the whole file before
    # inferring data types — prevents mixed-type warnings on large files
    df = pd.read_csv(filepath, low_memory=False)

    print(f"[EXTRACT] Loaded {len(df):,} rows and {len(df.columns)} columns")

    return df  


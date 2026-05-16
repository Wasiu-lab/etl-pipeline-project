import pandas as pd
import boto3
import os

def extract(filepath: str) -> pd.DataFrame:
    """
    Extract phase — reads raw CSV into a pandas DataFrame.
    Supports both local file paths and S3 URIs.

    Local path:  'data/raw/chicago_Food_Inspections.csv'
    S3 path:     's3://your-bucket/raw/chicago_Food_Inspections.csv'

    Args:
        filepath: local path or S3 URI to the raw CSV

    Returns:
        A raw, unmodified pandas DataFrame
    """

    # Detect whether the path is an S3 URI or a local file
    if filepath.startswith("s3://"):
        print(f"[EXTRACT] Reading from S3: {filepath}")

        # Parse bucket name and key from the S3 URI
        # s3://my-bucket/raw/file.csv → bucket=my-bucket, key=raw/file.csv
        path_parts  = filepath.replace("s3://", "").split("/", 1)
        bucket_name = path_parts[0]
        s3_key      = path_parts[1]

        # Download the file from S3 into memory using boto3
        # boto3 is the AWS SDK for Python — pre-installed in Lambda runtime
        s3_client = boto3.client("s3")
        response  = s3_client.get_object(Bucket=bucket_name, Key=s3_key)

        # Read the streaming body directly into pandas
        df = pd.read_csv(response["Body"], low_memory=False)

    else:
        # Local file path — same behaviour as before
        if not os.path.exists(filepath):
            raise FileNotFoundError(f"Raw file not found at: {filepath}")

        print(f"[EXTRACT] Reading local file: {filepath}")
        df = pd.read_csv(filepath, low_memory=False)

    print(f"[EXTRACT] Loaded {len(df):,} rows and {len(df.columns)} columns")
    return df
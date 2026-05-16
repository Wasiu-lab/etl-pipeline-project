import sys
import os

# ------------------------------------------------------------------
# Lambda entry point — AWS calls lambda_handler(event, context)
# on every trigger (manual invoke or EventBridge schedule).
#
# Why a separate handler file?
# Lambda needs a specific entry point function. Keeping it here
# means pipeline.py stays clean and testable locally — the handler
# is just a thin wrapper that calls run_pipeline().
# ------------------------------------------------------------------

# Add the project root to Python path so Lambda can find the etl/ module
# Lambda extracts your zip into /var/task/ — this ensures imports work
sys.path.insert(0, "/var/task")

from etl.pipeline import run_pipeline

def lambda_handler(event, context):
    """
    AWS Lambda entry point.

    Called by:
      - EventBridge on a schedule (event contains schedule metadata)
      - Manual invocation from AWS Console or CLI (event is empty {})

    Args:
        event:   dict passed by the trigger — we don't use it here
        context: Lambda runtime info (memory, timeout remaining, etc.)

    Returns:
        A dict with statusCode and body — standard Lambda response format
    """

    print("[LAMBDA] Handler invoked")
    print(f"[LAMBDA] Event received: {event}")

    try:
        run_pipeline()
        return {
            "statusCode": 200,
            "body": "ETL pipeline completed successfully"
        }

    except Exception as e:
        print(f"[LAMBDA] Pipeline failed: {str(e)}")
        # Re-raising causes Lambda to mark the invocation as failed
        # EventBridge can then retry based on your retry policy
        raise
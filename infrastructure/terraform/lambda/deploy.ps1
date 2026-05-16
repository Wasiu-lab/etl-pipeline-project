# deploy.ps1
# Packages the ETL pipeline code and dependencies into a Lambda
# deployment zip, then uploads it to S3.
#
# Run this BEFORE terraform apply whenever you change pipeline code.
# Terraform reads the zip from S3 when creating the Lambda function.
#
# Usage: from your project root run:
#   .\lambda\deploy.ps1 -BucketName "your-bucket-name"

param(
    [Parameter(Mandatory=$true)]
    [string]$BucketName
)

Write-Host "[DEPLOY] Starting Lambda packaging..." -ForegroundColor Cyan

# --- Step 1: Create a clean build folder ---
$buildDir = "lambda\build"
if (Test-Path $buildDir) {
    Remove-Item -Recurse -Force $buildDir
}
New-Item -ItemType Directory -Path $buildDir | Out-Null
Write-Host "[DEPLOY] Clean build directory created"

# --- Step 2: Install dependencies into the build folder ---
# Lambda has no pip — all dependencies must be included in the zip
Write-Host "[DEPLOY] Installing dependencies into build folder..."
pip install -r lambda\requirements.txt --target $buildDir --quiet
Write-Host "[DEPLOY] Dependencies installed"

# --- Step 3: Copy your pipeline code into the build folder ---
# Lambda needs to find etl/ and lambda_handler.py at the root of the zip
Copy-Item -Recurse -Path "etl"                         -Destination $buildDir
Copy-Item -Path "lambda\lambda_handler.py"             -Destination $buildDir
Write-Host "[DEPLOY] Pipeline code copied"

# --- Step 4: Create the zip file ---
$zipPath = "lambda\deployment_package.zip"
if (Test-Path $zipPath) {
    Remove-Item $zipPath
}

Compress-Archive -Path "$buildDir\*" -DestinationPath $zipPath
Write-Host "[DEPLOY] Deployment package zipped: $zipPath"

# --- Step 5: Upload the zip to S3 ---
Write-Host "[DEPLOY] Uploading to S3..."
aws s3 cp $zipPath "s3://$BucketName/lambda/deployment_package.zip"
Write-Host "[DEPLOY] Uploaded to s3://$BucketName/lambda/deployment_package.zip"

# --- Step 6: Clean up build folder ---
Remove-Item -Recurse -Force $buildDir
Write-Host "[DEPLOY] Build folder cleaned up"

Write-Host "[DEPLOY] Done. Run terraform apply to update the Lambda function." -ForegroundColor Green
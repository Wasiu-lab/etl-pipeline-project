# ETL Pipeline — Python · MySQL · AWS

A production-style ETL pipeline for learning and portfolio purposes. Ingests Chicago food inspection data, transforms with Python, stores as Parquet (data lake), and loads into MySQL (data warehouse). Deployed on AWS with Lambda, EventBridge, S3, and RDS.

## 🎯 Project Purpose

Build a **real-world ETL system** that demonstrates:
- End-to-end data pipeline architecture (Extract → Transform → Load)
- Separation of concerns: raw data layer (S3), transformed layer (Parquet), and queryable warehouse (MySQL)
- Cloud deployment with automated scheduling (Lambda + EventBridge)
- Professional project structure and credential management

---

## 📁 Project Structure

```
etl-pipeline-project/
│
├── data/                          # Local data storage
│   ├── raw/                       # Raw CSV files (source)
│   └── parquet/                   # Parquet files (data lake)
│
├── etl/                           # Core pipeline logic
│   ├── extract.py                 # Step 1: Load CSV → pandas
│   ├── transform.py               # Step 2: Clean & reshape
│   ├── load.py                    # Step 3: Write Parquet + MySQL
│   └── pipeline.py                # Orchestrate ETL flow
│
├── infrastructure/                # AWS cloud setup
│   ├── terraform/                 # IaC for AWS resources
│   │   ├── iam.tf                 # Lambda execution roles
│   │   ├── lambda.tf              # Lambda function config
│   │   ├── s3.tf                  # S3 bucket definitions
│   │   ├── rds.tf                 # RDS MySQL instance
│   │   ├── vpc.tf                 # VPC networking
│   │   └── eventbridge.tf          # EventBridge scheduling
│   └── lambda/                    # Lambda deployment package
│
├── sql/                           # Database schema
│   └── create_tables.sql          # MySQL table definitions
│
├── notebooks/                     # EDA & analysis
│   └── explore.ipynb              # Query results & visualizations
│
├── requirements.txt               # Python dependencies
├── .env                           # Credentials (gitignored)
├── test_connection.py             # MySQL connection test
└── README.md                      # This file
```

---

## 🧱 Tech Stack

| Category | Technology |
|----------|------------|
| **Language** | Python 3.11+ |
| **Data Processing** | pandas, pyarrow |
| **Database** | MySQL 8.0 |
| **ORM** | SQLAlchemy |
| **Cloud Provider** | AWS |
| **Compute** | Lambda |
| **Orchestration** | EventBridge |
| **Storage** | S3, RDS |
| **IaC** | Terraform |
| **Secrets** | python-dotenv |

---

## ⚙️ How It Works

**Local Pipeline:**
```
CSV → extract.py → pandas DataFrame → transform.py → Parquet → load.py → MySQL
```

**Cloud Pipeline:**
```
EventBridge (6am UTC) → Lambda → S3 (CSV read/Parquet write) → RDS MySQL
```

**Architecture:**
```
┌─── AWS Cloud ───────────────────────────────────┐
│                                                 │
│  EventBridge (trigger) → Lambda (VPC) → S3    │
│                            ↓                    │
│                         RDS MySQL              │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## 🚀 Quick Start (Local)


### 1. Clone & setup
```bash
git clone <repo> && cd etl-pipeline-project
python -m venv venv
# Windows: venv\Scripts\activate
# Mac/Linux: source venv/bin/activate
pip install -r requirements.txt
```

### 2. Configure `.env`
```
DB_HOST=localhost
DB_PORT=3306
DB_NAME=etl_pipeline
DB_USER=root
DB_PASSWORD=your_password
```

### 3. Create database & verify
```bash
# In MySQL: CREATE DATABASE IF NOT EXISTS etl_pipeline;
python test_connection.py
```

### 4. Run pipeline
```bash
python etl/pipeline.py
```

---

## 📊 Dataset

[Chicago Open Data Portal — Food Inspections](https://data.cityofchicago.org/Health-Human-Services/Food-Inspections/4ijn-s7e5/about_data)

---

## ☁️ Cloud Deployment

Pipeline runs on **AWS** with:
- **Lambda**: Executes `pipeline.py` on schedule (in VPC)
- **EventBridge**: Triggers daily at 6 AM UTC
- **S3**: Stores raw CSVs and Parquet files
- **RDS MySQL**: Data warehouse (eu-west-2, db.t3.micro free tier)

**Setup**: Same code, different `.env` credentials for cloud endpoints.

---

## 📌 Project Status

- ✅ Project structure & local setup
- ✅ ETL pipeline (extract, transform, load)
- ✅ MySQL integration
- ✅ AWS infrastructure (Terraform)
- ✅ Lambda deployment
- 🔄 Production testing & monitoring

---

## 📚 Key Concepts

- Data pipeline orchestration (ETL)
- Data layer separation: raw (S3) → curated (Parquet) → warehouse (MySQL)
- Columnar storage (Parquet) for analytics
- Relational databases for querying
- Infrastructure-as-Code (Terraform)
- Scheduled cloud jobs (EventBridge + Lambda)

---

## 👤 Author

**Abdul** — Data Engineer  
[GitHub](https://github.com/YOUR_USERNAME) · [LinkedIn](https://linkedin.com/in/YOUR_PROFILE)
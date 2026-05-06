# 🛠️ Local ETL Pipeline — Python · MySQL · Parquet

A production-style ETL pipeline built for learning and portfolio purposes.  
Ingests open CSV data, transforms it with Python, writes Parquet files as a data lake layer, and loads into MySQL as a data warehouse layer — with cloud deployment via Railway.app.

---

## 📌 Project Status

| Phase | Description | Status |
|-------|-------------|--------|
| Phase 1 | Project setup & environment configuration | ✅ Complete |
| Phase 2 | Extract — ingest open CSV data | 🔜 Up next |
| Phase 3 | Transform — clean & reshape with pandas | ⏳ Pending |
| Phase 4 | Load — write Parquet + load to MySQL | ⏳ Pending |
| Phase 5 | Query & validate | ⏳ Pending |
| Phase 6 | Cloud deployment (Railway.app) | ⏳ Pending |

---

## 🧱 Tech Stack

| Layer | Tool |
|-------|------|
| Language | Python 3.11+ |
| Data transformation | pandas |
| File format | Parquet (via pyarrow) |
| Database | MySQL |
| DB connector | SQLAlchemy + mysql-connector-python |
| Credentials management | python-dotenv |
| Cloud DB (Phase 6) | Railway.app (free tier) |
| Version control | Git + GitHub |
| Editor | VS Code |

---

## 📁 Project Structure

```
etl-pipeline-project/
│
├── data/
│   ├── raw/               ← Downloaded CSVs (source data)
│   └── parquet/           ← Transformed Parquet files (data lake layer)
│
├── etl/
│   ├── extract.py         ← Step 1: Load CSV into pandas DataFrame
│   ├── transform.py       ← Step 2: Clean, reshape, and enrich data
│   ├── load.py            ← Step 3: Write Parquet + load into MySQL
│   └── pipeline.py        ← Orchestrates all 3 ETL steps
│
├── sql/
│   └── create_tables.sql  ← MySQL schema definitions
│
├── notebooks/
│   └── explore.ipynb      ← EDA and query result visualisations
│
├── test_connection.py     ← Verifies MySQL connection on setup
├── requirements.txt       ← Python dependencies
├── .env                   ← DB credentials (gitignored)
├── .gitignore
└── README.md
```

---

## ⚙️ Local Setup

### 1. Clone the repository

```bash
git clone https://github.com/YOUR_USERNAME/etl-pipeline-project.git
cd etl-pipeline-project
```

### 2. Create and activate a virtual environment

```bash
python -m venv venv

# Windows
venv\Scripts\activate

# Mac/Linux
source venv/bin/activate
```

### 3. Install dependencies

```bash
pip install -r requirements.txt
```

### 4. Configure environment variables

Create a `.env` file in the project root:

```
DB_HOST=localhost
DB_PORT=3306
DB_NAME=etl_pipeline
DB_USER=your_mysql_username
DB_PASSWORD=your_mysql_password
```

### 5. Create the MySQL database

```sql
CREATE DATABASE IF NOT EXISTS etl_pipeline;
```

### 6. Verify the connection

```bash
python test_connection.py
```

Expected output:
```
✅ Connected to: etl_pipeline
```

---

## 📦 Dependencies

```
pandas
pyarrow
sqlalchemy
mysql-connector-python
python-dotenv
```

Install all with:

```bash
pip install -r requirements.txt
```

---

## 📊 Dataset

> _To be added in Phase 2_

Source: [Chicago Open Data Portal — Food Inspections](https://data.cityofchicago.org/Health-Human-Services/Food-Inspections/4ijn-s7e5/about_data)

---

## 🔄 Pipeline Overview

> _To be expanded as each phase is completed_

```
[CSV Source]
     ↓
  extract.py       ← reads raw CSV into pandas
     ↓
  transform.py     ← cleans, reshapes, adds derived columns
     ↓
  data/parquet/    ← saves as Parquet (data lake)
     ↓
  load.py          ← reads Parquet, loads into MySQL
     ↓
[MySQL Database]   ← queryable data warehouse layer
```

---

## ☁️ Cloud Deployment

> _To be documented in Phase 6_

The pipeline will be repointed to a cloud-hosted MySQL instance on **Railway.app** (free tier) to simulate a real-world production environment. No code changes required — only the `.env` credentials will be updated.

---

## 🧠 Key Concepts Covered

- ETL pipeline design (Extract → Transform → Load)
- Separation of raw vs. curated data layers
- Parquet as a columnar storage format
- MySQL as a relational data warehouse
- Managing credentials securely with `.env`
- Structuring Python projects for readability and reuse

---

## 📝 Changelog

### v0.1.0 — Phase 1 Complete
- Initialised project repository and folder structure
- Configured virtual environment and installed dependencies
- Set up `.env` credential management
- Created local MySQL database (`etl_pipeline`)
- Verified database connection via `test_connection.py`
- Configured `.gitignore` to protect credentials and exclude generated files

---

## 👤 Author

**Abdul**  
Data Engineer | Building production-style data pipelines  
[GitHub](https://github.com/YOUR_USERNAME) · [LinkedIn](https://linkedin.com/in/YOUR_PROFILE)
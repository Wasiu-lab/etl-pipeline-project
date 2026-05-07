# The below code is for exploring the raw CSV file to understand its structure, data types, and potential issues before cleaning and processing it.

import pandas as pd

# Load the raw CSV
df = pd.read_csv("data/raw/chicago_Food_Inspections.csv", low_memory=False)

# --- Understand the shape ---
print("Shape:", df.shape)           # rows x columns
print("\nColumns:\n", df.columns.tolist())

# --- Understand data types ---
print("\nData types:\n", df.dtypes)

# --- Check for nulls ---
print("\nNull counts:\n", df.isnull().sum())

# --- Preview first few rows ---
print("\nFirst 3 rows:\n", df.head(3))
-- Always target the right database first
USE etl_pipeline;

-- Drop the table if it already exists to avoid conflicts
DROP TABLE IF EXISTS food_inspections;

-- Defibning the schema for the food_inspections table
CREATE TABLE food_inspections (
    -- Identifiers
    inspection_id       BIGINT,
    license_number      BIGINT,

    -- Business info
    business_name       VARCHAR(255),
    aka_name            VARCHAR(255),
    facility_type       VARCHAR(100),

    -- Location
    address             VARCHAR(255),
    city                VARCHAR(100),
    state               VARCHAR(10),
    zip                 FLOAT,
    latitude            DECIMAL(15, 8),
    longitude           DECIMAL(15, 8),

    -- Risk
    risk                VARCHAR(50),
    risk_level          VARCHAR(20),
    is_high_risk        TINYINT(1),

    -- Inspection details
    inspection_date     DATE,
    inspection_type     VARCHAR(100),
    results             VARCHAR(100),
    violations          TEXT,
    violation_count     INT,

    -- Outcome flags
    is_pass             TINYINT(1),
    is_fail             TINYINT(1),

    -- Derived date columns
    inspection_year     SMALLINT,
    inspection_month    SMALLINT,
    inspection_day_of_week SMALLINT
);

-- Get-Content sql/create_tables.sql | mysql -u root -p etl_pipeline
-- Run the above in piower shell to execute the SQL script and create the table in the MySQL database.
-- Thus the above will request for myseql password and then execute.
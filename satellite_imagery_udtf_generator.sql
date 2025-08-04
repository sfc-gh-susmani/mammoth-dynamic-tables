-- ============================================================================
-- SNOWFLAKE UDTF: Satellite Imagery Synthetic Data Generator
-- ============================================================================
-- This script creates a User-Defined Table Function (UDTF) to generate
-- synthetic satellite imagery metadata at massive scale (1 billion records)
-- for demonstrating large-scale geospatial data processing capabilities
-- ============================================================================

-- Set context
USE DATABASE MAMMOTH;
USE SCHEMA PUBLIC;

-- ============================================================================
-- REFERENCE DATA SETUP FOR GLOBAL SATELLITE IMAGERY
-- ============================================================================

-- Create reference tables for realistic satellite data
CREATE OR REPLACE TABLE REF_SENSOR_TYPES AS
SELECT * FROM VALUES
    ('Planet Dove Satellite'),
    ('Landsat Government'),
    ('Sentinel ESA'),
    ('WorldView-3'),
    ('WorldView-4'),
    ('GeoEye-1'),
    ('QuickBird'),
    ('IKONOS'),
    ('RapidEye Commercial'),
    ('SPOT-6'),
    ('SPOT-7'),
    ('Pleiades-1A'),
    ('Pleiades-1B'),
    ('TerraSAR-X'),
    ('COSMO-SkyMed')
AS t(sensor_type);

CREATE OR REPLACE TABLE REF_GLOBAL_REGIONS AS
SELECT * FROM VALUES
    ('North America'),
    ('South America'),
    ('Europe'),
    ('Asia'),
    ('Africa'),
    ('Oceania'),
    ('Middle East'),
    ('Arctic'),
    ('Antarctica'),
    ('Central America'),
    ('Caribbean'),
    ('Southeast Asia'),
    ('Eastern Europe'),
    ('Western Europe'),
    ('Northern Africa'),
    ('Southern Africa'),
    ('East Asia'),
    ('South Asia'),
    ('Central Asia'),
    ('Pacific Islands')
AS t(region_name);

CREATE OR REPLACE TABLE REF_RESOLUTION_CATEGORIES AS
SELECT * FROM VALUES
    ('Ultra High-Resolution'),
    ('High-Resolution Commercial'),
    ('Medium-Resolution'),
    ('Standard Resolution'),
    ('Low Resolution')
AS t(resolution_category);

CREATE OR REPLACE TABLE REF_PROCESSING_STATUS AS
SELECT * FROM VALUES
    ('Processed'),
    ('Processing'),
    ('Pending'),
    ('Failed'),
    ('Archived')
AS t(status);

-- ============================================================================
-- MAIN UDTF: SATELLITE IMAGERY GENERATOR
-- ============================================================================

CREATE OR REPLACE FUNCTION GENERATE_SATELLITE_IMAGERY_SCALE(NUM_RECORDS NUMBER)
RETURNS TABLE (
    IMAGE_ID VARCHAR(50),
    CAPTURE_TIMESTAMP TIMESTAMP,
    UPLOAD_TIMESTAMP TIMESTAMP,
    CAPTURE_DATE DATE,
    LATITUDE NUMBER(10,6),
    LONGITUDE NUMBER(10,6),
    SENSOR_TYPE VARCHAR(50),
    RESOLUTION_METERS NUMBER(8,2),
    FILE_SIZE_BYTES NUMBER(15,0),
    FILE_URL VARCHAR(500),
    FILE_HASH VARCHAR(64),
    S3_BUCKET VARCHAR(100),
    S3_KEY VARCHAR(500),
    BANDS_AVAILABLE NUMBER(3,0),
    IMAGE_FORMAT VARCHAR(10),
    DATA_QUALITY_SCORE NUMBER(5,2),
    CLOUD_COVERAGE_PERCENT NUMBER(5,2),
    BATCH_ID VARCHAR(50),
    PROCESSING_STATUS VARCHAR(20),
    UPLOAD_METHOD VARCHAR(20),
    GEOMETRY_WKT VARCHAR(100),
    H3_RES6_COUNTRY VARCHAR(20),
    H3_RES7_METRO VARCHAR(20),
    H3_RES8_CITY VARCHAR(20),
    H3_RES9_NEIGHBORHOOD VARCHAR(20),
    H3_RES10_BLOCK VARCHAR(20),
    DISTANCE_TO_NEAREST_CITY_M NUMBER(12,2),
    SENSOR_CATEGORY VARCHAR(50),
    REGION VARCHAR(50),
    RESOLUTION_CATEGORY VARCHAR(50),
    ESTIMATED_COVERAGE_HECTARES NUMBER(12,4),
    COMBINED_QUALITY_SCORE NUMBER(5,2)
)
LANGUAGE SQL
AS
$$
    WITH SEQUENCE_CTE AS (
        SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS RN
        FROM TABLE(GENERATOR(ROWCOUNT => NUM_RECORDS))
    ),
    BASE_TIMESTAMPS AS (
        SELECT 
            RN,
            DATEADD(SECOND, -UNIFORM(1, 31536000, RANDOM()), CURRENT_TIMESTAMP())::TIMESTAMP_NTZ AS BASE_CAPTURE_TIME
        FROM SEQUENCE_CTE
    ),
    SATELLITE_DATA AS (
        SELECT 
            -- Primary identifiers
            'IMG_' || LPAD(RN, 12, '0') || '_' || RANDSTR(8, RANDOM()) AS IMAGE_ID,
            
            -- Temporal data
            BASE_CAPTURE_TIME AS CAPTURE_TIMESTAMP,
            DATEADD(HOUR, UNIFORM(1, 168, RANDOM()), BASE_CAPTURE_TIME)::TIMESTAMP_NTZ AS UPLOAD_TIMESTAMP,
            DATE(BASE_CAPTURE_TIME) AS CAPTURE_DATE,
            
            -- Global coordinates (realistic distribution)
            CASE 
                WHEN UNIFORM(1, 10, RANDOM()) <= 3 THEN
                    -- 30% concentrated in populated areas
                    ROUND(UNIFORM(25.0, 49.0, RANDOM()) + NORMAL(0, 5, RANDOM()), 6)::NUMBER(10,6)
                WHEN UNIFORM(1, 10, RANDOM()) <= 6 THEN
                    -- 30% in Europe/Asia populated zones
                    ROUND(UNIFORM(35.0, 65.0, RANDOM()) + NORMAL(0, 8, RANDOM()), 6)::NUMBER(10,6)
                ELSE
                    -- 40% globally distributed
                    ROUND(UNIFORM(-85.0, 85.0, RANDOM()), 6)::NUMBER(10,6)
            END AS LATITUDE,
            
            CASE 
                WHEN UNIFORM(1, 10, RANDOM()) <= 3 THEN
                    -- 30% concentrated in Americas
                    ROUND(UNIFORM(-125.0, -65.0, RANDOM()) + NORMAL(0, 10, RANDOM()), 6)::NUMBER(10,6)
                WHEN UNIFORM(1, 10, RANDOM()) <= 6 THEN
                    -- 30% in Europe/Asia/Africa
                    ROUND(UNIFORM(-10.0, 140.0, RANDOM()) + NORMAL(0, 15, RANDOM()), 6)::NUMBER(10,6)
                ELSE
                    -- 40% globally distributed
                    ROUND(UNIFORM(-180.0, 180.0, RANDOM()), 6)::NUMBER(10,6)
            END AS LONGITUDE,
            
            -- Sensor and technical specifications
            (SELECT sensor_type FROM REF_SENSOR_TYPES ORDER BY RANDOM() LIMIT 1) AS SENSOR_TYPE,
            
            -- Resolution based on sensor type (realistic ranges)
            CASE 
                WHEN SENSOR_TYPE LIKE '%WorldView%' THEN ROUND(UNIFORM(0.3, 0.6, RANDOM()), 2)::NUMBER(8,2)
                WHEN SENSOR_TYPE LIKE '%GeoEye%' THEN ROUND(UNIFORM(0.4, 0.8, RANDOM()), 2)::NUMBER(8,2)
                WHEN SENSOR_TYPE LIKE '%Planet%' THEN ROUND(UNIFORM(3.0, 4.0, RANDOM()), 2)::NUMBER(8,2)
                WHEN SENSOR_TYPE LIKE '%Landsat%' THEN ROUND(UNIFORM(15.0, 30.0, RANDOM()), 2)::NUMBER(8,2)
                WHEN SENSOR_TYPE LIKE '%Sentinel%' THEN ROUND(UNIFORM(10.0, 20.0, RANDOM()), 2)::NUMBER(8,2)
                ELSE ROUND(UNIFORM(1.0, 10.0, RANDOM()), 2)::NUMBER(8,2)
            END AS RESOLUTION_METERS,
            
            -- File characteristics
            ROUND(UNIFORM(50000000, 2000000000, RANDOM())) AS FILE_SIZE_BYTES, -- 50MB to 2GB
            
            -- File paths and storage
            'https://satellite-data-' || RANDSTR(6, RANDOM()) || '.amazonaws.com/imagery/' || 
            YEAR(BASE_CAPTURE_TIME) || '/' || LPAD(MONTH(BASE_CAPTURE_TIME), 2, '0') || '/' ||
            'IMG_' || LPAD(RN, 12, '0') || '_' || RANDSTR(8, RANDOM()) || '.tiff' AS FILE_URL,
            
            UPPER(MD5(CONCAT('IMG_', RN, RANDSTR(16, RANDOM())))) AS FILE_HASH,
            
            'satellite-imagery-bucket-' || RANDSTR(4, RANDOM()) AS S3_BUCKET,
            
            'satellite_data/' || YEAR(BASE_CAPTURE_TIME) || '/' || 
            LPAD(MONTH(BASE_CAPTURE_TIME), 2, '0') || '/' ||
            'IMG_' || LPAD(RN, 12, '0') || '_' || RANDSTR(8, RANDOM()) || '.tiff' AS S3_KEY,
            
            -- Image characteristics
            CASE 
                WHEN SENSOR_TYPE LIKE '%Landsat%' THEN UNIFORM(8, 11, RANDOM())
                WHEN SENSOR_TYPE LIKE '%Sentinel%' THEN UNIFORM(12, 13, RANDOM())
                WHEN SENSOR_TYPE LIKE '%WorldView%' THEN UNIFORM(4, 8, RANDOM())
                ELSE UNIFORM(3, 11, RANDOM())
            END AS BANDS_AVAILABLE,
            
            CASE UNIFORM(1, 5, RANDOM())
                WHEN 1 THEN 'TIFF'
                WHEN 2 THEN 'GeoTIFF'
                WHEN 3 THEN 'JP2'
                WHEN 4 THEN 'HDF'
                ELSE 'NITF'
            END AS IMAGE_FORMAT,
            
            -- Quality metrics
            ROUND(UNIFORM(65.0, 98.5, RANDOM()), 2)::NUMBER(5,2) AS DATA_QUALITY_SCORE,
            ROUND(UNIFORM(0.0, 85.0, RANDOM()), 2)::NUMBER(5,2) AS CLOUD_COVERAGE_PERCENT,
            
            -- Processing metadata
            'BATCH_' || YEAR(BASE_CAPTURE_TIME) || '_' || 
            LPAD(DAYOFYEAR(BASE_CAPTURE_TIME), 3, '0') || '_' || 
            LPAD(UNIFORM(1, 9999, RANDOM()), 4, '0') AS BATCH_ID,
            
            (SELECT status FROM REF_PROCESSING_STATUS ORDER BY RANDOM() LIMIT 1) AS PROCESSING_STATUS,
            
            CASE UNIFORM(1, 4, RANDOM())
                WHEN 1 THEN 'API'
                WHEN 2 THEN 'Batch'
                WHEN 3 THEN 'Streaming'
                ELSE 'Manual'
            END AS UPLOAD_METHOD,
            
            -- Random city distance (0-500km from nearest major city)
            ROUND(UNIFORM(0, 500000, RANDOM()), 2)::NUMBER(12,2) AS DISTANCE_TO_NEAREST_CITY_M
            
        FROM BASE_TIMESTAMPS
    ),
    ENHANCED_SATELLITE_DATA AS (
        SELECT 
            IMAGE_ID,
            CAPTURE_TIMESTAMP,
            UPLOAD_TIMESTAMP,
            CAPTURE_DATE,
            LATITUDE,
            LONGITUDE,
            SENSOR_TYPE,
            RESOLUTION_METERS,
            FILE_SIZE_BYTES,
            FILE_URL,
            FILE_HASH,
            S3_BUCKET,
            S3_KEY,
            BANDS_AVAILABLE,
            IMAGE_FORMAT,
            DATA_QUALITY_SCORE,
            CLOUD_COVERAGE_PERCENT,
            BATCH_ID,
            PROCESSING_STATUS,
            UPLOAD_METHOD,
            -- Geometry representation
            CONCAT('POINT(', LONGITUDE, ' ', LATITUDE, ')') AS GEOMETRY_WKT,
            
            -- H3 spatial indexing
            H3_LATLNG_TO_CELL_STRING(LATITUDE, LONGITUDE, 6) AS H3_RES6_COUNTRY,
            H3_LATLNG_TO_CELL_STRING(LATITUDE, LONGITUDE, 7) AS H3_RES7_METRO,
            H3_LATLNG_TO_CELL_STRING(LATITUDE, LONGITUDE, 8) AS H3_RES8_CITY,
            H3_LATLNG_TO_CELL_STRING(LATITUDE, LONGITUDE, 9) AS H3_RES9_NEIGHBORHOOD,
            H3_LATLNG_TO_CELL_STRING(LATITUDE, LONGITUDE, 10) AS H3_RES10_BLOCK,
            
            DISTANCE_TO_NEAREST_CITY_M,
            
            -- Enhanced sensor categorization
            CASE
                WHEN SENSOR_TYPE LIKE '%Planet%' THEN 'Planet Dove Satellite'
                WHEN SENSOR_TYPE LIKE '%Landsat%' THEN 'Landsat Government'
                WHEN SENSOR_TYPE LIKE '%Sentinel%' THEN 'Sentinel ESA'
                WHEN SENSOR_TYPE LIKE '%WorldView%' THEN 'WorldView Commercial'
                WHEN SENSOR_TYPE LIKE '%GeoEye%' THEN 'GeoEye Commercial'
                ELSE 'Other Satellite Platform'
            END AS SENSOR_CATEGORY,
            
            -- Global region classification
            CASE
                WHEN LATITUDE BETWEEN 25 AND 49 AND LONGITUDE BETWEEN -125 AND -65 THEN 'North America'
                WHEN LATITUDE BETWEEN -60 AND 15 AND LONGITUDE BETWEEN -85 AND -35 THEN 'South America'
                WHEN LATITUDE BETWEEN 35 AND 71 AND LONGITUDE BETWEEN -10 AND 40 THEN 'Europe'
                WHEN LATITUDE BETWEEN 10 AND 55 AND LONGITUDE BETWEEN 25 AND 145 THEN 'Asia'
                WHEN LATITUDE BETWEEN -35 AND 38 AND LONGITUDE BETWEEN -20 AND 55 THEN 'Africa'
                WHEN LATITUDE BETWEEN -50 AND -10 AND LONGITUDE BETWEEN 110 AND 180 THEN 'Oceania'
                WHEN LATITUDE BETWEEN 12 AND 42 AND LONGITUDE BETWEEN 25 AND 75 THEN 'Middle East'
                WHEN LATITUDE > 66.5 THEN 'Arctic'
                WHEN LATITUDE < -66.5 THEN 'Antarctica'
                ELSE 'Other Region'
            END AS REGION,
            
            -- Resolution categorization
            CASE 
                WHEN RESOLUTION_METERS <= 1.0 THEN 'Ultra High-Resolution'
                WHEN RESOLUTION_METERS <= 3.0 THEN 'High-Resolution Commercial'
                WHEN RESOLUTION_METERS <= 10.0 THEN 'Medium-Resolution'
                WHEN RESOLUTION_METERS <= 30.0 THEN 'Standard Resolution'
                ELSE 'Low Resolution'
            END AS RESOLUTION_CATEGORY,
            
            -- Coverage calculation
            ROUND((RESOLUTION_METERS * RESOLUTION_METERS) / 10000, 4)::NUMBER(12,4) AS ESTIMATED_COVERAGE_HECTARES,
            
            -- Combined quality score
            ROUND(DATA_QUALITY_SCORE * 0.9 + (100 - COALESCE(CLOUD_COVERAGE_PERCENT, 0)) * 0.1, 2)::NUMBER(5,2) AS COMBINED_QUALITY_SCORE
            
        FROM SATELLITE_DATA
    )
    SELECT * FROM ENHANCED_SATELLITE_DATA
$$;

-- ============================================================================
-- CREATE FINAL ICEBERG TABLE FOR 1 BILLION RECORDS
-- ============================================================================

-- Create the target iceberg table
CREATE OR REPLACE ICEBERG TABLE MAMMOTH.PUBLIC.SILVER_IMAGERY_METADATA_SCALE_ICEBERG (
    IMAGE_ID STRING,
    CAPTURE_TIMESTAMP TIMESTAMP,
    UPLOAD_TIMESTAMP TIMESTAMP,
    CAPTURE_DATE DATE,
    LATITUDE NUMBER(10,6),
    LONGITUDE NUMBER(10,6),
    SENSOR_TYPE STRING,
    RESOLUTION_METERS NUMBER(8,2),
    FILE_SIZE_BYTES NUMBER(15,0),
    FILE_URL STRING,
    FILE_HASH STRING,
    S3_BUCKET STRING,
    S3_KEY STRING,
    BANDS_AVAILABLE NUMBER(3,0),
    IMAGE_FORMAT STRING,
    DATA_QUALITY_SCORE NUMBER(5,2),
    CLOUD_COVERAGE_PERCENT NUMBER(5,2),
    BATCH_ID STRING,
    PROCESSING_STATUS STRING,
    UPLOAD_METHOD STRING,
    GEOMETRY_WKT STRING,
    H3_RES6_COUNTRY STRING,
    H3_RES7_METRO STRING,
    H3_RES8_CITY STRING,
    H3_RES9_NEIGHBORHOOD STRING,
    H3_RES10_BLOCK STRING,
    DISTANCE_TO_NEAREST_CITY_M NUMBER(12,2),
    SENSOR_CATEGORY STRING,
    REGION STRING,
    RESOLUTION_CATEGORY STRING,
    ESTIMATED_COVERAGE_HECTARES NUMBER(12,4),
    COMBINED_QUALITY_SCORE NUMBER(5,2)
)
EXTERNAL_VOLUME = 'mammoth_iceberg_external_volume'
CATALOG = 'SNOWFLAKE'
BASE_LOCATION = 'mammoth_dodicse/silver_imagery_metadata_scale/';

-- ============================================================================
-- STORED PROCEDURE: GENERATE 1 BILLION RECORDS IN BATCHES
-- ============================================================================

CREATE OR REPLACE PROCEDURE GENERATE_BILLION_SATELLITE_RECORDS()
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
    start_time TIMESTAMP := CURRENT_TIMESTAMP();
    batch_size NUMBER := 50000000; -- 50 million per batch
    total_batches NUMBER := 20;     -- 20 batches = 1 billion total
    current_batch NUMBER := 1;
    result STRING := '';
BEGIN
    
    result := 'Starting generation of 1 billion satellite imagery records...\n';
    
    -- Clear existing data
    TRUNCATE TABLE SILVER_IMAGERY_METADATA_SCALE_ICEBERG;
    result := result || 'Cleared existing table data.\n';
    
    -- Generate data in batches
    WHILE (current_batch <= total_batches) DO
        result := result || 'Generating batch ' || current_batch || ' of ' || total_batches || 
                  ' (' || batch_size || ' records)...\n';
        
        INSERT INTO SILVER_IMAGERY_METADATA_SCALE_ICEBERG
        SELECT * FROM TABLE(GENERATE_SATELLITE_IMAGERY_SCALE(:batch_size));
        
        result := result || 'Completed batch ' || current_batch || '. ';
        result := result || 'Total records so far: ' || (current_batch * batch_size) || '\n';
        
        current_batch := current_batch + 1;
    END WHILE;
    
    -- Final statistics
    LET record_count NUMBER := (SELECT COUNT(*) FROM SILVER_IMAGERY_METADATA_SCALE_ICEBERG);
    
    result := result || '\n=== GENERATION COMPLETE ===\n';
    result := result || 'Total records generated: ' || record_count || '\n';
    result := result || 'Target records: 1,000,000,000\n';
    result := result || 'Generation time: ' || 
              DATEDIFF(MINUTE, start_time, CURRENT_TIMESTAMP()) || ' minutes\n';
    result := result || 'Table: SILVER_IMAGERY_METADATA_SCALE_ICEBERG\n';
    result := result || 'Ready for large-scale geospatial analytics!\n';
    
    RETURN result;
END;
$$;

-- ============================================================================
-- USAGE INSTRUCTIONS
-- ============================================================================

/*
-- To generate exactly 1 billion records:
CALL GENERATE_BILLION_SATELLITE_RECORDS();

-- To test with smaller batches first (recommended):
INSERT INTO SILVER_IMAGERY_METADATA_SCALE_ICEBERG
SELECT * FROM TABLE(GENERATE_SATELLITE_IMAGERY_SCALE(1000000)); -- 1 million test

-- To check progress:
SELECT COUNT(*) as current_record_count, 
       COUNT(*) / 1000000000.0 * 100 as percent_complete
FROM SILVER_IMAGERY_METADATA_SCALE_ICEBERG;

-- To verify data quality:
SELECT 
    REGION,
    SENSOR_CATEGORY,
    RESOLUTION_CATEGORY,
    COUNT(*) as record_count,
    AVG(COMBINED_QUALITY_SCORE) as avg_quality,
    MIN(CAPTURE_DATE) as earliest_date,
    MAX(CAPTURE_DATE) as latest_date
FROM SILVER_IMAGERY_METADATA_SCALE_ICEBERG
GROUP BY REGION, SENSOR_CATEGORY, RESOLUTION_CATEGORY
ORDER BY record_count DESC;
*/ 
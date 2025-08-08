-- ============================================================================
-- SNOWFLAKE DATA ENGINEERING SHOWCASE: 5-MINUTE DEMO
-- ============================================================================
-- Demonstrating enterprise-scale capabilities with 1 BILLION satellite records
-- Total Demo Time: ~5 minutes
-- ============================================================================

USE DATABASE MAMMOTH;
USE SCHEMA PUBLIC;
USE WAREHOUSE DEMO_WH;

ALTER WAREHOUSE DEMO_WH SET WAREHOUSE_SIZE = 'X-SMALL';
-- ============================================================================
-- SECTION 1: DATA SCALE OVERVIEW (30 seconds)
-- ============================================================================
-- Show the massive scale we're working with

SELECT 
    'TABLE OVERVIEW' AS demo_section,
    COUNT(*) AS total_records,
    COUNT(DISTINCT SENSOR_TYPE) AS sensor_types,
    MIN(CAPTURE_DATE) AS earliest_capture,
    MAX(CAPTURE_DATE) AS latest_capture,
    ROUND(SUM(FILE_SIZE_BYTES) / 1024/1024/1024/1024, 2) AS total_data_tb
FROM SILVER_IMAGERY_METADATA_ICEBERG;

-- ============================================================================
-- SECTION 2: ZERO COPY CLONING (1 minute)
-- ============================================================================
-- Demonstrate instant cloning of billion-record table with NO data movement
-- 🚀 SNOWFLAKE DIFFERENTIATOR: Zero Copy Cloning
-- Create instant clone of 1 billion records (seconds, not hours!)
CREATE OR REPLACE ICEBERG TABLE SILVER_IMAGERY_CLONE 
CLONE SILVER_IMAGERY_METADATA_ICEBERG_v2;

-- Verify clone is identical but independent
SELECT 
    'ZERO COPY CLONE VERIFICATION' AS demo_section,
    'Original Table' AS table_type,
    COUNT(*) AS record_count
FROM SILVER_IMAGERY_METADATA_ICEBERG
UNION ALL
SELECT 
    'ZERO COPY CLONE VERIFICATION' AS demo_section,
    'Cloned Table' AS table_type,
    COUNT(*) AS record_count
FROM SILVER_IMAGERY_CLONE;


-- ============================================================================
-- SECTION 3: TIME TRAVEL (1 minute)
-- ============================================================================
-- Demonstrate querying historical data states

-- 🚀 SNOWFLAKE DIFFERENTIATOR: Time Travel
-- Make a change to demonstrate time travel
select * from silver_imagery_clone;
DELETE FROM SILVER_IMAGERY_CLONE WHERE BAY_REGION = 'North Bay';

-- Show current state vs historical state
SELECT 
    'TIME TRAVEL DEMO' AS demo_section,
    'Current State' AS data_state,
    COUNT(*) AS record_count,
FROM SILVER_IMAGERY_CLONE
UNION ALL
SELECT 
    'TIME TRAVEL DEMO' AS demo_section,
    'Historical State (5 min ago)' AS data_state,
    COUNT(*) AS record_count,
FROM SILVER_IMAGERY_CLONE AT(OFFSET => -60); -- 1 minute ago


SET query_id = (
  SELECT query_id
  FROM TABLE(information_schema.query_history_by_session(result_limit=>5))
  WHERE query_text LIKE 'DELETE%'
  ORDER BY start_time DESC
  LIMIT 1
);

select $query_id;

-- Instantly restore deleted data using time travel
CREATE OR REPLACE ICEBERG TABLE SILVER_IMAGERY_CLONE 
external_volume = 'MAMMOTH_ICEBERG_EXTERNAL_VOLUME'  catalog = 'SNOWFLAKE'  base_location = 'mammoth_dodicse/silver_imagery_metadata_enhanced/' 
AS
SELECT * FROM SILVER_IMAGERY_CLONE BEFORE (STATEMENT => $query_id)
;

select count(*) from silver_imagery_clone;

SELECT 'Data restored instantly using time travel!' AS time_travel_power;

-- ============================================================================
-- SECTION 4: COMPLEX ANALYTICS AT SCALE (2 minutes)
-- ============================================================================
-- Run sophisticated geospatial analytics on 1 billion records
select count(*) from silver_imagery_metadata_scale_iceberg;
alter warehouse demo_wh set WAREHOUSE_SIZE = '2X-LARGE'; 
-- 🚀 SNOWFLAKE DIFFERENTIATOR: Massive Scale Performance
-- Complex multi-dimensional analysis across 1 billion records
WITH regional_analytics AS (
    SELECT 
        REGION,
        SENSOR_CATEGORY,
        RESOLUTION_CATEGORY,
        COUNT(*) AS image_count,
        AVG(COMBINED_QUALITY_SCORE) AS avg_quality,
        SUM(FILE_SIZE_BYTES) AS total_storage_bytes,
        AVG(CLOUD_COVERAGE_PERCENT) AS avg_cloud_coverage,
        COUNT(DISTINCT H3_RES6_COUNTRY) AS h3_cells_covered
    FROM SILVER_IMAGERY_METADATA_SCALE_ICEBERG
    GROUP BY REGION, SENSOR_CATEGORY, RESOLUTION_CATEGORY
),
quality_rankings AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY REGION ORDER BY avg_quality DESC) AS quality_rank,
        RANK() OVER (PARTITION BY SENSOR_CATEGORY ORDER BY image_count DESC) AS volume_rank
    FROM regional_analytics
),
geospatial_hotspots AS (
    SELECT 
        H3_RES8_CITY,
        COUNT(*) AS density_score,
        AVG(LATITUDE) AS center_lat,
        AVG(LONGITUDE) AS center_lon,
        LISTAGG(DISTINCT SENSOR_TYPE, ', ') AS sensor_mix,
        AVG(COMBINED_QUALITY_SCORE) AS hotspot_quality
    FROM SILVER_IMAGERY_METADATA_SCALE_ICEBERG
    GROUP BY H3_RES8_CITY
    HAVING COUNT(*) > 1000  -- High density areas only
)
SELECT 
    'COMPLEX BILLION-RECORD ANALYTICS' AS demo_section,
    qr.REGION,
    qr.SENSOR_CATEGORY,
    qr.image_count,
    ROUND(qr.avg_quality, 2) AS avg_quality,
    ROUND(qr.total_storage_bytes / 1024/1024/1024, 2) AS storage_gb,
    qr.quality_rank,
    COUNT(gh.H3_RES8_CITY) AS high_density_zones
FROM quality_rankings qr
LEFT JOIN geospatial_hotspots gh ON qr.avg_quality > gh.hotspot_quality
WHERE qr.quality_rank <= 3  -- Top 3 quality regions per category
GROUP BY qr.REGION, qr.SENSOR_CATEGORY, qr.image_count, qr.avg_quality, 
         qr.total_storage_bytes, qr.quality_rank
ORDER BY qr.image_count DESC;

-- ============================================================================
-- SECTION 5: ADVANCED GEOSPATIAL INTELLIGENCE (1 minute)
-- ============================================================================
-- Showcase H3 spatial indexing and advanced analytics

-- 🚀 SNOWFLAKE DIFFERENTIATOR: Built-in Geospatial Functions
-- Advanced spatial analytics using H3 indexing on massive dataset
SELECT 
    'GEOSPATIAL INTELLIGENCE AT SCALE' AS demo_section,
    REGION,
    -- Spatial concentration analysis
    COUNT(DISTINCT H3_RES6_COUNTRY) AS country_level_coverage,
    COUNT(DISTINCT H3_RES8_CITY) AS city_level_coverage,
    ROUND(COUNT(*) / COUNT(DISTINCT H3_RES8_CITY), 2) AS avg_images_per_city,
    
    -- Quality metrics analysis
    ROUND(AVG(COMBINED_QUALITY_SCORE), 3) AS avg_quality_score,
    ROUND(STDDEV(COMBINED_QUALITY_SCORE), 3) AS quality_variation,
    
    -- Temporal patterns
    COUNT(DISTINCT DATE_TRUNC('MONTH', CAPTURE_DATE)) AS months_of_coverage,
    
    -- Sensor diversity
    COUNT(DISTINCT SENSOR_TYPE) AS sensor_diversity
    
FROM SILVER_IMAGERY_METADATA_SCALE_ICEBERG
GROUP BY REGION
ORDER BY country_level_coverage DESC;

alter warehouse demo_wh set warehouse_size = 'x-small';

--show caching by rerunning


-- ============================================================================
-- SECTION 6: PERFORMANCE & SCALE SUMMARY (30 seconds)
-- ============================================================================
-- Demonstrate query performance on billion-record dataset

SELECT 
    'SNOWFLAKE PERFORMANCE SUMMARY' AS demo_section,
    '1,000,000,000 records processed' AS scale,
    'Sub-second response times' AS performance,
    'Zero data movement for cloning' AS efficiency,
    'Time travel for instant recovery' AS reliability,
    'Built-in geospatial functions' AS advanced_analytics,
    'Auto-scaling compute' AS elasticity;

<<<<<<< HEAD:snowflake_5min_demo.sql
-- ============================================================================
-- BONUS: REAL-TIME INSIGHTS GENERATION
-- ============================================================================
-- Quick insights that would traditionally take hours

-- Generate business intelligence in seconds from billion records
SELECT 
    'INSTANT BUSINESS INTELLIGENCE' AS insight_type,
    CASE 
        WHEN COMBINED_QUALITY_SCORE >= 90 THEN 'Premium Grade'
        WHEN COMBINED_QUALITY_SCORE >= 80 THEN 'Commercial Grade' 
        WHEN COMBINED_QUALITY_SCORE >= 70 THEN 'Standard Grade'
        ELSE 'Processing Grade'
    END AS quality_tier,
    COUNT(*) AS image_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS market_share_pct,
    ROUND(AVG(FILE_SIZE_BYTES) / 1024/1024, 2) AS avg_size_mb,
    LISTAGG(DISTINCT REGION, ', ') AS global_coverage
FROM SILVER_IMAGERY_METADATA_SCALE_ICEBERG
GROUP BY quality_tier
ORDER BY image_count DESC;
=======
>>>>>>> 5e37399a07fbd8d8b024ae6ef4caea4ee15352ea:mammoth_data_engineering_timetravel.sql

-- ============================================================================
-- CLEANUP (Optional - for demo reset)
-- ============================================================================
DROP TABLE SILVER_IMAGERY_CLONE;

/*
=============================================================================
🎯 DEMO SCRIPT SUMMARY (5-minute timing):

1. [30s] Scale Overview: Show 1B records, global coverage
2. [60s] Zero Copy Cloning: Instant clone creation, no data duplication  
3. [60s] Time Travel: Historical queries, instant data recovery
4. [120s] Complex Analytics: Multi-dimensional analysis at scale
5. [60s] Geospatial Intelligence: H3 indexing, spatial correlations
6. [30s] Performance Summary: Key differentiators recap

🚀 KEY SNOWFLAKE DIFFERENTIATORS DEMONSTRATED:
✅ Massive scale performance (1B records)
✅ Zero copy cloning (instant, no storage cost)
✅ Time travel (data recovery, historical analysis)
✅ Built-in geospatial functions
✅ Auto-scaling compute
✅ Complex analytics without data movement

💡 BUSINESS VALUE:
- Instant data environments for dev/test
- Point-in-time recovery without backups
- Real-time insights from massive datasets
- No infrastructure management required
=============================================================================
*/ 


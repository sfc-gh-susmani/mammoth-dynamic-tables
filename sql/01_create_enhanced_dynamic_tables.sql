-- =====================================================================================
-- MAMMOTH Enhanced Geospatial Dynamic Tables Pipeline
-- Version: 2.0 with Comprehensive Spatial Analytics
-- Compatible with: Apache Iceberg Tables
-- =====================================================================================

-- Set context
USE DATABASE MAMMOTH;
USE SCHEMA PUBLIC;
USE WAREHOUSE DEMO_WH;
--Comment 


-- =====================================================================================
-- BRONZE LAYER: Source Data (Already exists as imagery_metadata_iceberg)
-- =====================================================================================
-- Note: Bronze layer table imagery_metadata_iceberg should already exist
-- This serves as the source for our enhanced geospatial pipeline

-- =====================================================================================
-- SILVER LAYER 1: Enhanced Metadata with Geospatial Functions
-- =====================================================================================

DROP DYNAMIC TABLE IF EXISTS silver_imagery_metadata_iceberg;

CREATE OR REPLACE DYNAMIC ICEBERG TABLE silver_imagery_metadata_iceberg 
TARGET_LAG = 'downstream'
WAREHOUSE = DEMO_WH
EXTERNAL_VOLUME = 'mammoth_iceberg_external_volume'
CATALOG = 'SNOWFLAKE'
BASE_LOCATION = 'mammoth_dodicse/silver_imagery_metadata_enhanced/'
AS
SELECT
    -- Original metadata
    image_id,
    timestamp as capture_timestamp,
    created_at as upload_timestamp,
    capture_date,
    latitude,
    longitude,
    sensor_type,
    resolution_meters,
    file_size_bytes,
    file_url,
    file_hash,
    s3_bucket,
    s3_key,
    bands_available,
    image_format,
    data_quality_score,
    cloud_coverage_percent,
    batch_id,
    processing_status,
    upload_method,
    
    -- ENHANCED GEOSPATIAL FEATURES (Iceberg Compatible) --
    
    -- 1. WKT Geometry Representation
    CONCAT('POINT(', longitude, ' ', latitude, ')') as geometry_wkt,
    
    -- 2. H3 Hexagonal Indexing (Multiple Resolutions)
    H3_LATLNG_TO_CELL_STRING(latitude, longitude, 6) as h3_res6_country,
    H3_LATLNG_TO_CELL_STRING(latitude, longitude, 7) as h3_res7_metro,
    H3_LATLNG_TO_CELL_STRING(latitude, longitude, 8) as h3_res8_city,
    H3_LATLNG_TO_CELL_STRING(latitude, longitude, 9) as h3_res9_neighborhood,
    H3_LATLNG_TO_CELL_STRING(latitude, longitude, 10) as h3_res10_block,
    
    -- 3. Distance Calculations to SF Bay Area Landmarks (in meters)
    ROUND(ST_DISTANCE(
        ST_MAKEPOINT(longitude, latitude), 
        ST_MAKEPOINT(-122.4194, 37.7749)
    ), 2) as distance_to_sf_downtown_m,
    
    ROUND(ST_DISTANCE(
        ST_MAKEPOINT(longitude, latitude), 
        ST_MAKEPOINT(-122.4786, 37.8199)
    ), 2) as distance_to_golden_gate_m,
    
    ROUND(ST_DISTANCE(
        ST_MAKEPOINT(longitude, latitude), 
        ST_MAKEPOINT(-122.3635, 37.7983)
    ), 2) as distance_to_bay_bridge_m,
    
    ROUND(ST_DISTANCE(
        ST_MAKEPOINT(longitude, latitude), 
        ST_MAKEPOINT(-122.2711, 37.8044)
    ), 2) as distance_to_oakland_m,
    
    -- 4. Proximity Classifications 
    CASE WHEN ST_DISTANCE(ST_MAKEPOINT(longitude, latitude), ST_MAKEPOINT(-122.4194, 37.7749)) <= 5000 
         THEN 'Yes' ELSE 'No' END as within_5km_sf_downtown,
         
    CASE WHEN ST_DISTANCE(ST_MAKEPOINT(longitude, latitude), ST_MAKEPOINT(-122.4786, 37.8199)) <= 3000 
         THEN 'Yes' ELSE 'No' END as within_3km_golden_gate,
    
    -- 5. Closest Landmark
    CASE 
        WHEN ST_DISTANCE(ST_MAKEPOINT(longitude, latitude), ST_MAKEPOINT(-122.4194, 37.7749)) <= 
             ST_DISTANCE(ST_MAKEPOINT(longitude, latitude), ST_MAKEPOINT(-122.4786, 37.8199)) AND
             ST_DISTANCE(ST_MAKEPOINT(longitude, latitude), ST_MAKEPOINT(-122.4194, 37.7749)) <= 
             ST_DISTANCE(ST_MAKEPOINT(longitude, latitude), ST_MAKEPOINT(-122.3635, 37.7983))
        THEN 'SF Downtown'
        WHEN ST_DISTANCE(ST_MAKEPOINT(longitude, latitude), ST_MAKEPOINT(-122.4786, 37.8199)) <= 
             ST_DISTANCE(ST_MAKEPOINT(longitude, latitude), ST_MAKEPOINT(-122.3635, 37.7983))
        THEN 'Golden Gate Bridge'
        ELSE 'Bay Bridge'
    END as closest_landmark,
    
    -- 6. Enhanced Sensor Classification
    CASE
        WHEN sensor_type LIKE '%dove%' THEN 'Planet Dove Satellite'
        WHEN sensor_type LIKE '%landsat%' THEN 'Landsat Government'
        WHEN sensor_type LIKE '%sentinel%' THEN 'Sentinel ESA'
        WHEN sensor_type LIKE '%rapideye%' THEN 'RapidEye Commercial'
        ELSE 'Other Satellite Platform'
    END as sensor_category,
    
    -- 7. Bay Region Classification
    CASE
        WHEN latitude > 37.8 AND longitude > -122.3 THEN 'North Bay'
        WHEN latitude BETWEEN 37.7 AND 37.8 AND longitude BETWEEN -122.5 AND -122.3 THEN 'Central Bay'
        WHEN latitude < 37.7 AND longitude < -122.4 THEN 'South Bay'
        WHEN longitude < -118.0 THEN 'Southern California'
        ELSE 'Other Region'
    END as bay_region,
    
    -- 8. Resolution Classification
    CASE 
        WHEN resolution_meters <= 1.0 THEN 'Ultra High-Resolution'
        WHEN resolution_meters <= 3.0 THEN 'High-Resolution Commercial'
        WHEN resolution_meters <= 10.0 THEN 'Medium-Resolution'
        WHEN resolution_meters <= 30.0 THEN 'Standard Resolution'
        ELSE 'Low Resolution'
    END as resolution_category,
    
    -- 9. Coverage and Quality Metrics
    ROUND((resolution_meters * resolution_meters) / 10000, 4) as estimated_coverage_hectares,
    ROUND(data_quality_score * 0.9 + (100 - COALESCE(cloud_coverage_percent, 0)) * 0.1, 1) as combined_quality_score
    
FROM imagery_metadata_iceberg 
WHERE image_id IS NOT NULL;

-- =====================================================================================
-- SILVER LAYER 2: Enhanced Spatial Metrics and Analytics
-- =====================================================================================

DROP DYNAMIC TABLE IF EXISTS silver_imagery_spatial_metrics_iceberg;

CREATE OR REPLACE DYNAMIC ICEBERG TABLE silver_imagery_spatial_metrics_iceberg 
TARGET_LAG = 'downstream'
WAREHOUSE = DEMO_WH
EXTERNAL_VOLUME = 'mammoth_iceberg_external_volume'
CATALOG = 'SNOWFLAKE'
BASE_LOCATION = 'mammoth_dodicse/silver_spatial_metrics_enhanced/'
AS
SELECT
    -- Core identifiers
    image_id,
    capture_timestamp,
    capture_date,
    latitude,
    longitude,
    geometry_wkt,
    sensor_category,
    bay_region,
    resolution_category,
    
    -- H3 Spatial Indexing Analysis
    h3_res6_country,
    h3_res7_metro,
    h3_res8_city,
    h3_res9_neighborhood,
    h3_res10_block,
    
    -- Enhanced Distance Analysis
    distance_to_sf_downtown_m,
    distance_to_golden_gate_m,
    distance_to_bay_bridge_m,
    distance_to_oakland_m,
    closest_landmark,
    within_5km_sf_downtown,
    within_3km_golden_gate,
    
    -- Spatial Quality Metrics
    combined_quality_score,
    estimated_coverage_hectares,
    
    -- NEW: Advanced Spatial Analytics
    
    -- 1. Urban vs Rural Classification based on distance to landmarks
    CASE 
        WHEN distance_to_sf_downtown_m <= 10000 OR 
             distance_to_golden_gate_m <= 10000 OR 
             distance_to_bay_bridge_m <= 10000 OR 
             distance_to_oakland_m <= 10000 
        THEN 'Urban'
        WHEN distance_to_sf_downtown_m <= 25000 
        THEN 'Suburban'
        ELSE 'Rural/Remote'
    END as urban_classification,
    
    -- 2. Average distance to all landmarks
    ROUND((distance_to_sf_downtown_m + distance_to_golden_gate_m + 
           distance_to_bay_bridge_m + distance_to_oakland_m) / 4, 2) as avg_distance_to_landmarks_m,
    
    -- 3. Coordinate precision analysis
    ROUND(latitude, 6) as latitude_precise,
    ROUND(longitude, 6) as longitude_precise,
    LENGTH(CAST(ABS(latitude - FLOOR(ABS(latitude))) AS STRING)) - 2 as latitude_decimal_places,
    LENGTH(CAST(ABS(longitude - FLOOR(ABS(longitude))) AS STRING)) - 2 as longitude_decimal_places,
    
    -- 4. Spatial coverage efficiency
    CASE 
        WHEN estimated_coverage_hectares > 0 AND combined_quality_score > 0 
        THEN ROUND(combined_quality_score / estimated_coverage_hectares, 2)
        ELSE 0 
    END as quality_per_hectare_ratio,
    
    -- 5. H3 Cell Area Analysis  
    -- H3 res 8 cells are approximately 0.74 km² = 74 hectares
    CASE 
        WHEN estimated_coverage_hectares <= 74 THEN 'Sub-Cell Coverage'
        WHEN estimated_coverage_hectares <= 148 THEN 'Single Cell Coverage'  
        WHEN estimated_coverage_hectares <= 370 THEN 'Multi-Cell Coverage'
        ELSE 'Wide Area Coverage'
    END as h3_coverage_category,
    
    -- 6. Processing metadata
    batch_id,
    upload_method,
    data_quality_score,
    file_size_bytes
    
FROM silver_imagery_metadata_iceberg 
WHERE image_id IS NOT NULL;

-- =====================================================================================
-- GOLD LAYER: Business Intelligence and Comprehensive Analytics
-- =====================================================================================

DROP DYNAMIC TABLE IF EXISTS gold_daily_summary_iceberg;

CREATE OR REPLACE DYNAMIC ICEBERG TABLE gold_daily_summary_iceberg 
TARGET_LAG = '15 minutes'
WAREHOUSE = DEMO_WH
EXTERNAL_VOLUME = 'mammoth_iceberg_external_volume'
CATALOG = 'SNOWFLAKE'
BASE_LOCATION = 'mammoth_dodicse/gold_daily_summary_enhanced/'
AS
SELECT
    -- Time-based grouping
    capture_date,
    
    -- Geographic grouping
    bay_region,
    sensor_category,
    urban_classification,
    closest_landmark,
    
    -- CORE METRICS
    COUNT(*) as total_images,
    COUNT(DISTINCT h3_res8_city) as unique_h3_cells,
    COUNT(DISTINCT sensor_category) as unique_sensor_types,
    COUNT(DISTINCT batch_id) as unique_batches,
    
    -- QUALITY METRICS  
    ROUND(AVG(combined_quality_score), 1) as avg_quality_score,
    ROUND(MAX(combined_quality_score), 1) as max_quality_score,
    ROUND(MIN(combined_quality_score), 1) as min_quality_score,
    COUNT(CASE WHEN combined_quality_score >= 90 THEN 1 END) as high_quality_count,
    
    -- SPATIAL COVERAGE METRICS
    ROUND(SUM(estimated_coverage_hectares), 2) as total_coverage_hectares,
    ROUND(AVG(estimated_coverage_hectares), 2) as avg_coverage_per_image_hectares,
    ROUND(MAX(estimated_coverage_hectares), 2) as max_coverage_hectares,
    
    -- DISTANCE & PROXIMITY ANALYTICS
    ROUND(AVG(distance_to_sf_downtown_m), 0) as avg_distance_to_sf_m,
    ROUND(MIN(distance_to_sf_downtown_m), 0) as closest_to_sf_m,
    ROUND(MAX(distance_to_sf_downtown_m), 0) as farthest_from_sf_m,
    ROUND(AVG(avg_distance_to_landmarks_m), 0) as avg_distance_to_all_landmarks_m,
    
    -- PROXIMITY COUNTS
    COUNT(CASE WHEN within_5km_sf_downtown = 'Yes' THEN 1 END) as images_within_5km_sf,
    COUNT(CASE WHEN within_3km_golden_gate = 'Yes' THEN 1 END) as images_within_3km_gg,
    
    -- H3 SPATIAL ANALYTICS
    COUNT(DISTINCT h3_res6_country) as h3_country_cells,
    COUNT(DISTINCT h3_res7_metro) as h3_metro_cells,
    COUNT(DISTINCT h3_res8_city) as h3_city_cells,
    COUNT(DISTINCT h3_res9_neighborhood) as h3_neighborhood_cells,
    COUNT(DISTINCT h3_res10_block) as h3_block_cells,
    
    -- RESOLUTION & COVERAGE ANALYSIS
    COUNT(CASE WHEN resolution_category = 'Ultra High-Resolution' THEN 1 END) as ultra_high_res_count,
    COUNT(CASE WHEN resolution_category = 'High-Resolution Commercial' THEN 1 END) as high_res_count,
    COUNT(CASE WHEN h3_coverage_category = 'Wide Area Coverage' THEN 1 END) as wide_coverage_count,
    
    -- DATA QUALITY & EFFICIENCY
    ROUND(AVG(quality_per_hectare_ratio), 2) as avg_quality_per_hectare,
    ROUND(MAX(quality_per_hectare_ratio), 2) as max_quality_per_hectare,
    
    -- FILE & PROCESSING METRICS
    ROUND(AVG(file_size_bytes) / 1024, 0) as avg_file_size_kb,
    ROUND(SUM(file_size_bytes) / (1024 * 1024), 2) as total_data_size_mb,
    
    -- SPATIAL DIVERSITY INDEX (based on H3 cells vs images)
    ROUND(
        CASE WHEN COUNT(*) > 0 
        THEN (COUNT(DISTINCT h3_res8_city) * 100.0) / COUNT(*) 
        ELSE 0 END, 1
    ) as spatial_diversity_index_pct,
    
    -- OPERATIONAL EFFECTIVENESS SCORE
    ROUND(
        (AVG(combined_quality_score) * 0.4) +
        (CASE WHEN COUNT(DISTINCT h3_res8_city) > 0 
         THEN (COUNT(DISTINCT h3_res8_city) * 100.0) / COUNT(*) * 0.3 
         ELSE 0 END) +
        (CASE WHEN SUM(estimated_coverage_hectares) > 0 
         THEN LEAST(SUM(estimated_coverage_hectares) / 1000, 30) 
         ELSE 0 END),
        1
    ) as operational_effectiveness_score
    
FROM silver_imagery_spatial_metrics_iceberg 
WHERE capture_date IS NOT NULL
GROUP BY capture_date, bay_region, sensor_category, urban_classification, closest_landmark
HAVING COUNT(*) > 0
ORDER BY capture_date DESC, total_images DESC;

-- =====================================================================================
-- DEPLOYMENT SCRIPT: Refresh All Dynamic Tables
-- =====================================================================================

-- Refresh all tables in correct dependency order
ALTER DYNAMIC TABLE silver_imagery_metadata_iceberg REFRESH;
ALTER DYNAMIC TABLE silver_imagery_spatial_metrics_iceberg REFRESH;  
ALTER DYNAMIC TABLE gold_daily_summary_iceberg REFRESH;

-- =====================================================================================
-- VERIFICATION: Pipeline Status Check
-- =====================================================================================

SELECT 
    'ENHANCED GEOSPATIAL PIPELINE STATUS' as summary_type,
    'DEPLOYMENT COMPLETE' as status
UNION ALL
SELECT 'Bronze Records', CAST(COUNT(*) as STRING) FROM imagery_metadata_iceberg
UNION ALL  
SELECT 'Silver Metadata', CAST(COUNT(*) as STRING) FROM silver_imagery_metadata_iceberg
UNION ALL
SELECT 'Silver Spatial', CAST(COUNT(*) as STRING) FROM silver_imagery_spatial_metrics_iceberg
UNION ALL
SELECT 'Gold Summary', CAST(COUNT(*) as STRING) FROM gold_daily_summary_iceberg;

-- =====================================================================================
-- END OF SCRIPT
-- ===================================================================================== 
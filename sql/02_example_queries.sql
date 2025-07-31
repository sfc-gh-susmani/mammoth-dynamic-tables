-- =====================================================================================
-- MAMMOTH Enhanced Geospatial Dynamic Tables - Example Queries
-- Demonstrates comprehensive spatial analytics capabilities
-- =====================================================================================

-- Set context
USE DATABASE MAMMOTH;
USE SCHEMA PUBLIC;

-- =====================================================================================
-- EXAMPLE 1: H3 Spatial Clustering Analysis
-- =====================================================================================

-- Find H3 cells with the highest image density and spatial diversity
WITH h3_spatial_summary AS (
    SELECT 
        h3_res8_city,
        COUNT(*) as images_in_h3_cell,
        COUNT(DISTINCT sensor_category) as sensor_types_in_cell,
        ROUND(AVG(distance_to_sf_downtown_m), 0) as avg_distance_to_sf,
        ROUND(AVG(combined_quality_score), 1) as avg_quality,
        ROUND(SUM(estimated_coverage_hectares), 2) as total_coverage_hectares,
        LISTAGG(DISTINCT bay_region, ', ') as regions_covered,
        LISTAGG(DISTINCT urban_classification, ', ') as urban_types,
        MIN(capture_date) as earliest_capture,
        MAX(capture_date) as latest_capture
    FROM silver_imagery_spatial_metrics_iceberg
    GROUP BY h3_res8_city
    HAVING COUNT(*) >= 3
)
SELECT 
    SUBSTR(h3_res8_city, 1, 12) as h3_cell_short,
    images_in_h3_cell,
    sensor_types_in_cell,
    avg_distance_to_sf,
    avg_quality,
    total_coverage_hectares,
    regions_covered,
    urban_types,
    earliest_capture,
    latest_capture,
    
    -- Calculate H3 cell density (H3 res 8 cells are ~0.74 km²)
    ROUND(images_in_h3_cell / 0.74, 1) as images_per_km2,
    
    -- Temporal span
    DATEDIFF('day', earliest_capture, latest_capture) as capture_span_days
    
FROM h3_spatial_summary
ORDER BY images_in_h3_cell DESC, avg_quality DESC
LIMIT 10;

-- =====================================================================================
-- EXAMPLE 2: Proximity Analysis to San Francisco Landmarks
-- =====================================================================================

-- Analyze imagery closest to major SF landmarks with enhanced geospatial features
SELECT 
    SUBSTR(image_id, 1, 25) as short_id,
    ROUND(latitude, 4) as lat,
    ROUND(longitude, 4) as lng,
    
    -- H3 Spatial Indexing
    h3_res8_city,
    h3_res9_neighborhood,
    
    -- Distance Analysis  
    distance_to_sf_downtown_m,
    distance_to_golden_gate_m,
    closest_landmark,
    
    -- Classifications
    sensor_category,
    bay_region,
    resolution_category,
    
    -- Proximity flags
    within_5km_sf_downtown,
    within_3km_golden_gate,
    
    -- Quality metrics
    ROUND(combined_quality_score, 1) as quality
    
FROM silver_imagery_metadata_iceberg 
WHERE bay_region IN ('Central Bay', 'South Bay')
ORDER BY distance_to_sf_downtown_m ASC
LIMIT 8;

-- =====================================================================================
-- EXAMPLE 3: Urban Classification and Spatial Metrics Analysis
-- =====================================================================================

-- Advanced spatial metrics with urban classification
SELECT 
    SUBSTR(image_id, 1, 20) as short_id,
    bay_region,
    sensor_category,
    closest_landmark,
    
    -- Urban classification
    urban_classification,
    
    -- Advanced spatial metrics
    ROUND(avg_distance_to_landmarks_m, 0) as avg_landmark_dist_m,
    quality_per_hectare_ratio,
    h3_coverage_category,
    
    -- Coordinate precision
    latitude_decimal_places,
    longitude_decimal_places,
    
    -- Coverage analysis
    ROUND(estimated_coverage_hectares, 2) as coverage_ha
    
FROM silver_imagery_spatial_metrics_iceberg 
WHERE urban_classification IN ('Urban', 'Suburban')
ORDER BY avg_distance_to_landmarks_m ASC
LIMIT 6;

-- =====================================================================================
-- EXAMPLE 4: Gold Layer Business Intelligence Analytics
-- =====================================================================================

-- Comprehensive Gold layer analytics with operational effectiveness
SELECT 
    capture_date,
    bay_region,
    sensor_category,
    urban_classification,
    
    -- Core metrics
    total_images,
    unique_h3_cells,
    unique_sensor_types,
    
    -- H3 Spatial Diversity Analysis
    h3_city_cells,
    h3_neighborhood_cells,
    h3_block_cells,
    spatial_diversity_index_pct,
    
    -- Distance & Proximity Analytics
    avg_distance_to_sf_m,
    images_within_5km_sf,
    images_within_3km_gg,
    
    -- Quality & Coverage
    avg_quality_score,
    total_coverage_hectares,
    avg_quality_per_hectare,
    
    -- Resolution analysis
    ultra_high_res_count,
    high_res_count,
    
    -- Operational effectiveness
    operational_effectiveness_score
    
FROM gold_daily_summary_iceberg 
WHERE total_images >= 5
ORDER BY operational_effectiveness_score DESC, total_images DESC
LIMIT 8;

-- =====================================================================================
-- EXAMPLE 5: Regional Coverage Analysis
-- =====================================================================================

-- Analyze coverage patterns across Bay Area regions
SELECT 
    bay_region,
    urban_classification,
    
    -- Image counts and diversity
    COUNT(*) as total_images,
    COUNT(DISTINCT h3_res8_city) as unique_h3_cells,
    COUNT(DISTINCT sensor_category) as unique_sensors,
    
    -- Quality metrics
    ROUND(AVG(combined_quality_score), 1) as avg_quality,
    COUNT(CASE WHEN combined_quality_score >= 90 THEN 1 END) as high_quality_images,
    
    -- Distance statistics
    ROUND(AVG(distance_to_sf_downtown_m), 0) as avg_distance_to_sf_m,
    ROUND(MIN(distance_to_sf_downtown_m), 0) as min_distance_to_sf_m,
    ROUND(MAX(distance_to_sf_downtown_m), 0) as max_distance_to_sf_m,
    
    -- Coverage analysis
    ROUND(SUM(estimated_coverage_hectares), 2) as total_coverage_hectares,
    ROUND(AVG(estimated_coverage_hectares), 4) as avg_coverage_per_image,
    
    -- Temporal analysis
    MIN(capture_date) as earliest_capture,
    MAX(capture_date) as latest_capture,
    DATEDIFF('day', MIN(capture_date), MAX(capture_date)) as capture_span_days
    
FROM silver_imagery_spatial_metrics_iceberg
GROUP BY bay_region, urban_classification
HAVING COUNT(*) >= 3
ORDER BY total_images DESC, avg_quality DESC;

-- =====================================================================================
-- EXAMPLE 6: Sensor Performance by Geographic Region
-- =====================================================================================

-- Compare sensor performance across different geographic contexts
SELECT 
    sensor_category,
    bay_region,
    
    -- Performance metrics
    COUNT(*) as image_count,
    ROUND(AVG(combined_quality_score), 1) as avg_quality_score,
    ROUND(AVG(resolution_meters), 2) as avg_resolution_meters,
    
    -- Spatial coverage
    COUNT(DISTINCT h3_res8_city) as unique_h3_cells,
    ROUND(SUM(estimated_coverage_hectares), 2) as total_coverage_hectares,
    
    -- Distance patterns
    ROUND(AVG(distance_to_sf_downtown_m), 0) as avg_dist_to_sf,
    COUNT(CASE WHEN within_5km_sf_downtown = 'Yes' THEN 1 END) as images_near_sf,
    
    -- Operational efficiency
    ROUND(AVG(quality_per_hectare_ratio), 1) as avg_quality_per_hectare,
    
    -- File size patterns
    ROUND(AVG(file_size_bytes) / 1024, 1) as avg_file_size_kb
    
FROM silver_imagery_spatial_metrics_iceberg
GROUP BY sensor_category, bay_region
HAVING COUNT(*) >= 5
ORDER BY sensor_category, image_count DESC;

-- =====================================================================================
-- EXAMPLE 7: Time Series Analysis with Spatial Context
-- =====================================================================================

-- Analyze temporal patterns in spatial coverage
SELECT 
    capture_date,
    
    -- Daily totals
    COUNT(*) as daily_images,
    COUNT(DISTINCT h3_res8_city) as daily_h3_cells,
    COUNT(DISTINCT bay_region) as regions_covered,
    
    -- Quality trends
    ROUND(AVG(combined_quality_score), 1) as daily_avg_quality,
    
    -- Spatial distribution
    ROUND(AVG(distance_to_sf_downtown_m), 0) as avg_distance_to_sf,
    COUNT(CASE WHEN urban_classification = 'Urban' THEN 1 END) as urban_images,
    COUNT(CASE WHEN urban_classification = 'Suburban' THEN 1 END) as suburban_images,
    COUNT(CASE WHEN urban_classification = 'Rural/Remote' THEN 1 END) as rural_images,
    
    -- Coverage metrics
    ROUND(SUM(estimated_coverage_hectares), 2) as daily_coverage_hectares,
    
    -- Operational effectiveness
    ROUND(AVG(quality_per_hectare_ratio), 1) as avg_efficiency
    
FROM silver_imagery_spatial_metrics_iceberg
GROUP BY capture_date
HAVING COUNT(*) >= 3
ORDER BY capture_date DESC
LIMIT 15;

-- =====================================================================================
-- END OF EXAMPLE QUERIES
-- ===================================================================================== 
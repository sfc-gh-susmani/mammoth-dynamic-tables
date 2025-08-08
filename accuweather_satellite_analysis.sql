-- ============================================================================
-- ACCUWEATHER + SATELLITE IMAGERY INTELLIGENCE ANALYSIS
-- ============================================================================
-- Description: Comprehensive analysis combining 1 billion satellite imagery 
--              records with AccuWeather historical weather data
-- Use Case: Weather pattern validation, anomaly detection, climate analysis
-- Data Sources: MAMMOTH.PUBLIC.SILVER_IMAGERY_METADATA_SCALE_ICEBERG + 
--               SAMPLE_OF_ACCUWEATHERS_HISTORICAL_WEATHER_DATA.HISTORICAL.TOP_CITY_DAILY_METRIC
-- ============================================================================

-- ============================================================================
-- SECTION 1: DATA EXPLORATION AND SETUP
-- ============================================================================

-- Check available data ranges and coverage
SELECT 'SATELLITE_DATA' as DATASET,
       COUNT(*) as RECORD_COUNT,
       MIN(CAPTURE_DATE) as MIN_DATE,
       MAX(CAPTURE_DATE) as MAX_DATE,
       MIN(LATITUDE) as MIN_LAT,
       MAX(LATITUDE) as MAX_LAT,
       MIN(LONGITUDE) as MIN_LON,
       MAX(LONGITUDE) as MAX_LON
FROM MAMMOTH.PUBLIC.SILVER_IMAGERY_METADATA_SCALE_ICEBERG
WHERE LATITUDE BETWEEN 25 AND 50 AND LONGITUDE BETWEEN -125 AND -65
UNION ALL
SELECT 'WEATHER_DATA' as DATASET,
       COUNT(*) as RECORD_COUNT,
       MIN(DATE) as MIN_DATE,
       MAX(DATE) as MAX_DATE,
       MIN(LATITUDE) as MIN_LAT,
       MAX(LATITUDE) as MAX_LAT,
       MIN(LONGITUDE) as MIN_LON,
       MAX(LONGITUDE) as MAX_LON
FROM SAMPLE_OF_ACCUWEATHERS_HISTORICAL_WEATHER_DATA.HISTORICAL.TOP_CITY_DAILY_METRIC
WHERE COUNTRY_CODE = 'US';

-- ============================================================================
-- SECTION 2: BASIC SPATIAL JOIN - SATELLITE + WEATHER
-- ============================================================================

-- Simple spatial join to find nearest weather station for each satellite image
WITH satellite_sample AS (
    SELECT 
        IMAGE_ID,
        LATITUDE,
        LONGITUDE,
        CAPTURE_DATE,
        SENSOR_TYPE,
        COMBINED_QUALITY_SCORE,
        CLOUD_COVERAGE_PERCENT,
        REGION
    FROM MAMMOTH.PUBLIC.SILVER_IMAGERY_METADATA_SCALE_ICEBERG
    WHERE LATITUDE BETWEEN 25 AND 50 
    AND LONGITUDE BETWEEN -125 AND -65  -- North America focus
    AND CAPTURE_DATE >= '2024-01-01'
    LIMIT 20  -- Adjust sample size as needed
),
weather_cities AS (
    SELECT 
        CITY_NAME,
        COUNTRY_CODE,
        LATITUDE as WEATHER_LAT,
        LONGITUDE as WEATHER_LON,
        AVG(CLOUD_COVER_AVG) as AVG_CLOUD_COVER,
        AVG(TEMPERATURE_AVG) as AVG_TEMPERATURE,
        AVG(PRECIPITATION_LWE_TOTAL) as AVG_PRECIPITATION,
        COUNT(*) as WEATHER_OBSERVATIONS
    FROM SAMPLE_OF_ACCUWEATHERS_HISTORICAL_WEATHER_DATA.HISTORICAL.TOP_CITY_DAILY_METRIC
    WHERE COUNTRY_CODE = 'US'
    GROUP BY CITY_NAME, COUNTRY_CODE, LATITUDE, LONGITUDE
),
satellite_weather_pairs AS (
    SELECT 
        s.*,
        w.CITY_NAME,
        w.WEATHER_LAT,
        w.WEATHER_LON,
        w.AVG_CLOUD_COVER,
        w.AVG_TEMPERATURE,
        w.AVG_PRECIPITATION,
        w.WEATHER_OBSERVATIONS,
        ST_DISTANCE(
            ST_MAKEPOINT(s.LONGITUDE, s.LATITUDE),
            ST_MAKEPOINT(w.WEATHER_LON, w.WEATHER_LAT)
        ) as DISTANCE_METERS,
        ROW_NUMBER() OVER (
            PARTITION BY s.IMAGE_ID 
            ORDER BY ST_DISTANCE(
                ST_MAKEPOINT(s.LONGITUDE, s.LATITUDE),
                ST_MAKEPOINT(w.WEATHER_LON, w.WEATHER_LAT)
            )
        ) as distance_rank
    FROM satellite_sample s
    CROSS JOIN weather_cities w
)
SELECT 
    IMAGE_ID,
    LATITUDE as SAT_LAT,
    LONGITUDE as SAT_LON,
    CAPTURE_DATE,
    SENSOR_TYPE,
    COMBINED_QUALITY_SCORE,
    CLOUD_COVERAGE_PERCENT as SAT_CLOUD_PERCENT,
    REGION,
    
    -- Nearest weather station
    CITY_NAME as NEAREST_CITY,
    WEATHER_LAT,
    WEATHER_LON,
    ROUND(AVG_CLOUD_COVER, 2) as HISTORICAL_CLOUD_AVG,
    ROUND(AVG_TEMPERATURE, 2) as HISTORICAL_TEMP_AVG,
    ROUND(AVG_PRECIPITATION, 4) as HISTORICAL_PRECIP_AVG,
    WEATHER_OBSERVATIONS,
    
    -- Distance and analysis
    ROUND(DISTANCE_METERS / 1000, 2) as DISTANCE_TO_WEATHER_STATION_KM,
    ROUND(CLOUD_COVERAGE_PERCENT - AVG_CLOUD_COVER, 2) as CLOUD_DEVIATION_FROM_HISTORICAL,
    
    CASE 
        WHEN CLOUD_COVERAGE_PERCENT > AVG_CLOUD_COVER + 20 THEN 'MUCH_CLOUDIER'
        WHEN CLOUD_COVERAGE_PERCENT > AVG_CLOUD_COVER + 10 THEN 'CLOUDIER'
        WHEN CLOUD_COVERAGE_PERCENT < AVG_CLOUD_COVER - 20 THEN 'MUCH_CLEARER'
        WHEN CLOUD_COVERAGE_PERCENT < AVG_CLOUD_COVER - 10 THEN 'CLEARER'
        ELSE 'SIMILAR'
    END as CLOUD_CONDITION_VS_HISTORICAL

FROM satellite_weather_pairs
WHERE distance_rank = 1  -- Only the nearest weather station
ORDER BY DISTANCE_TO_WEATHER_STATION_KM
LIMIT 10;

-- ============================================================================
-- SECTION 3: COMPREHENSIVE WEATHER INTELLIGENCE ANALYSIS
-- ============================================================================

-- Advanced analysis with anomaly detection and intelligence insights
WITH satellite_analysis AS (
    SELECT 
        IMAGE_ID,
        LATITUDE,
        LONGITUDE,
        CAPTURE_DATE,
        SENSOR_TYPE,
        COMBINED_QUALITY_SCORE,
        CLOUD_COVERAGE_PERCENT,
        REGION,
        RESOLUTION_METERS,
        H3_RES8_CITY,
        -- Categorize image quality
        CASE 
            WHEN COMBINED_QUALITY_SCORE >= 90 THEN 'EXCELLENT'
            WHEN COMBINED_QUALITY_SCORE >= 80 THEN 'GOOD'
            WHEN COMBINED_QUALITY_SCORE >= 70 THEN 'FAIR'
            ELSE 'POOR'
        END as IMAGE_QUALITY_CATEGORY
    FROM MAMMOTH.PUBLIC.SILVER_IMAGERY_METADATA_SCALE_ICEBERG
    WHERE LATITUDE BETWEEN 30 AND 45 
    AND LONGITUDE BETWEEN -125 AND -70  -- Focus on continental US
    AND CAPTURE_DATE >= '2024-06-01'
    AND COMBINED_QUALITY_SCORE >= 75  -- High quality images only
    LIMIT 50
),
weather_stations AS (
    SELECT 
        CITY_NAME,
        COUNTRY_CODE,
        LATITUDE as WEATHER_LAT,
        LONGITUDE as WEATHER_LON,
        -- Calculate comprehensive weather statistics
        AVG(CLOUD_COVER_AVG) as AVG_CLOUD_COVER,
        STDDEV(CLOUD_COVER_AVG) as CLOUD_VARIABILITY,
        AVG(TEMPERATURE_AVG) as AVG_TEMPERATURE,
        AVG(PRECIPITATION_LWE_TOTAL) as AVG_PRECIPITATION,
        AVG(HUMIDITY_RELATIVE_AVG) as AVG_HUMIDITY,
        AVG(WIND_SPEED_AVG) as AVG_WIND_SPEED,
        COUNT(*) as WEATHER_OBSERVATIONS,
        -- Climate classification
        CASE 
            WHEN AVG(TEMPERATURE_AVG) > 20 THEN 'WARM'
            WHEN AVG(TEMPERATURE_AVG) > 10 THEN 'TEMPERATE'
            ELSE 'COOL'
        END as CLIMATE_ZONE
    FROM SAMPLE_OF_ACCUWEATHERS_HISTORICAL_WEATHER_DATA.HISTORICAL.TOP_CITY_DAILY_METRIC
    WHERE COUNTRY_CODE = 'US'
    GROUP BY CITY_NAME, COUNTRY_CODE, LATITUDE, LONGITUDE
    HAVING COUNT(*) >= 1  -- Ensure we have weather data
),
satellite_weather_analysis AS (
    SELECT 
        s.*,
        w.CITY_NAME as NEAREST_WEATHER_STATION,
        w.WEATHER_LAT,
        w.WEATHER_LON,
        w.AVG_CLOUD_COVER,
        w.CLOUD_VARIABILITY,
        w.AVG_TEMPERATURE,
        w.AVG_PRECIPITATION,
        w.AVG_HUMIDITY,
        w.WEATHER_OBSERVATIONS,
        w.CLIMATE_ZONE,
        
        -- Distance calculations
        ST_DISTANCE(
            ST_MAKEPOINT(s.LONGITUDE, s.LATITUDE),
            ST_MAKEPOINT(w.WEATHER_LON, w.WEATHER_LAT)
        ) / 1000 as DISTANCE_KM,
        
        -- Weather comparison metrics
        s.CLOUD_COVERAGE_PERCENT - w.AVG_CLOUD_COVER as CLOUD_DEVIATION,
        ABS(s.CLOUD_COVERAGE_PERCENT - w.AVG_CLOUD_COVER) as ABS_CLOUD_DEVIATION,
        
        -- Advanced analysis
        CASE 
            WHEN ABS(s.CLOUD_COVERAGE_PERCENT - w.AVG_CLOUD_COVER) > (2 * w.CLOUD_VARIABILITY) 
            THEN 'ANOMALOUS'
            WHEN ABS(s.CLOUD_COVERAGE_PERCENT - w.AVG_CLOUD_COVER) > w.CLOUD_VARIABILITY 
            THEN 'UNUSUAL'
            ELSE 'NORMAL'
        END as WEATHER_ANOMALY_STATUS,
        
        ROW_NUMBER() OVER (
            PARTITION BY s.IMAGE_ID 
            ORDER BY ST_DISTANCE(
                ST_MAKEPOINT(s.LONGITUDE, s.LATITUDE),
                ST_MAKEPOINT(w.WEATHER_LON, w.WEATHER_LAT)
            )
        ) as weather_station_rank
    FROM satellite_analysis s
    CROSS JOIN weather_stations w
)
-- FINAL RESULTS WITH INSIGHTS
SELECT 
    '=== SATELLITE IMAGERY + WEATHER INTELLIGENCE ===' as ANALYSIS_TYPE,
    IMAGE_ID,
    ROUND(LATITUDE, 4) as SAT_LAT,
    ROUND(LONGITUDE, 4) as SAT_LON,
    CAPTURE_DATE,
    SENSOR_TYPE,
    IMAGE_QUALITY_CATEGORY,
    ROUND(COMBINED_QUALITY_SCORE, 1) as QUALITY_SCORE,
    ROUND(CLOUD_COVERAGE_PERCENT, 1) as SAT_CLOUD_PERCENT,
    
    '---NEAREST WEATHER STATION---' as DIVIDER_1,
    NEAREST_WEATHER_STATION,
    ROUND(DISTANCE_KM, 1) as DISTANCE_KM,
    CLIMATE_ZONE,
    ROUND(AVG_CLOUD_COVER, 1) as HISTORICAL_CLOUD_AVG,
    ROUND(AVG_TEMPERATURE, 1) as HISTORICAL_TEMP_C,
    
    '---WEATHER ANALYSIS---' as DIVIDER_2,
    ROUND(CLOUD_DEVIATION, 1) as CLOUD_DEVIATION_FROM_NORM,
    WEATHER_ANOMALY_STATUS,
    
    '---INTELLIGENCE INSIGHTS---' as DIVIDER_3,
    CASE 
        WHEN WEATHER_ANOMALY_STATUS = 'ANOMALOUS' AND CLOUD_DEVIATION > 0 
        THEN 'UNUSUAL STORM ACTIVITY DETECTED'
        WHEN WEATHER_ANOMALY_STATUS = 'ANOMALOUS' AND CLOUD_DEVIATION < 0 
        THEN 'EXCEPTIONAL CLEAR CONDITIONS'
        WHEN IMAGE_QUALITY_CATEGORY = 'EXCELLENT' AND CLOUD_COVERAGE_PERCENT < 10 
        THEN 'OPTIMAL IMAGING CONDITIONS'
        WHEN CLOUD_COVERAGE_PERCENT > 80 AND RESOLUTION_METERS < 1.0 
        THEN 'HIGH-RES WEATHER MONITORING'
        ELSE 'STANDARD CONDITIONS'
    END as INTELLIGENCE_ASSESSMENT

FROM satellite_weather_analysis
WHERE weather_station_rank = 1  -- Only closest weather station
ORDER BY 
    CASE WHEN WEATHER_ANOMALY_STATUS = 'ANOMALOUS' THEN 1
         WHEN WEATHER_ANOMALY_STATUS = 'UNUSUAL' THEN 2
         ELSE 3 END,
    ABS_CLOUD_DEVIATION DESC
LIMIT 12;

-- ============================================================================
-- SECTION 4: WEATHER STATION ANALYSIS
-- ============================================================================

-- Analyze available weather stations and their coverage
SELECT 
    CITY_NAME,
    COUNTRY_CODE,
    ROUND(LATITUDE, 3) as LAT,
    ROUND(LONGITUDE, 3) as LON,
    COUNT(*) as HISTORICAL_RECORDS,
    ROUND(AVG(CLOUD_COVER_AVG), 2) as AVG_CLOUD_COVER,
    ROUND(AVG(TEMPERATURE_AVG), 2) as AVG_TEMP_C,
    ROUND(AVG(PRECIPITATION_LWE_TOTAL), 4) as AVG_PRECIPITATION,
    ROUND(AVG(HUMIDITY_RELATIVE_AVG), 2) as AVG_HUMIDITY,
    CASE 
        WHEN AVG(TEMPERATURE_AVG) > 20 THEN 'WARM'
        WHEN AVG(TEMPERATURE_AVG) > 10 THEN 'TEMPERATE'
        ELSE 'COOL'
    END as CLIMATE_ZONE
FROM SAMPLE_OF_ACCUWEATHERS_HISTORICAL_WEATHER_DATA.HISTORICAL.TOP_CITY_DAILY_METRIC
WHERE COUNTRY_CODE = 'US'
GROUP BY CITY_NAME, COUNTRY_CODE, LATITUDE, LONGITUDE
ORDER BY HISTORICAL_RECORDS DESC;

-- ============================================================================
-- SECTION 5: SATELLITE IMAGERY QUALITY vs WEATHER CONDITIONS
-- ============================================================================

-- Analyze relationship between image quality and weather conditions
WITH quality_weather_analysis AS (
    SELECT 
        s.IMAGE_ID,
        s.COMBINED_QUALITY_SCORE,
        s.CLOUD_COVERAGE_PERCENT,
        s.SENSOR_TYPE,
        w.CITY_NAME as NEAREST_CITY,
        w.AVG_CLOUD_COVER as HISTORICAL_CLOUD_AVG,
        w.AVG_TEMPERATURE as HISTORICAL_TEMP,
        -- Calculate nearest weather station
        ROW_NUMBER() OVER (
            PARTITION BY s.IMAGE_ID 
            ORDER BY ST_DISTANCE(
                ST_MAKEPOINT(s.LONGITUDE, s.LATITUDE),
                ST_MAKEPOINT(w.WEATHER_LON, w.WEATHER_LAT)
            )
        ) as weather_rank
    FROM (
        SELECT IMAGE_ID, LATITUDE, LONGITUDE, COMBINED_QUALITY_SCORE, 
               CLOUD_COVERAGE_PERCENT, SENSOR_TYPE
        FROM MAMMOTH.PUBLIC.SILVER_IMAGERY_METADATA_SCALE_ICEBERG
        WHERE LATITUDE BETWEEN 30 AND 45 AND LONGITUDE BETWEEN -125 AND -70
        LIMIT 100
    ) s
    CROSS JOIN (
        SELECT CITY_NAME, LATITUDE as WEATHER_LAT, LONGITUDE as WEATHER_LON,
               AVG(CLOUD_COVER_AVG) as AVG_CLOUD_COVER,
               AVG(TEMPERATURE_AVG) as AVG_TEMPERATURE
        FROM SAMPLE_OF_ACCUWEATHERS_HISTORICAL_WEATHER_DATA.HISTORICAL.TOP_CITY_DAILY_METRIC
        WHERE COUNTRY_CODE = 'US'
        GROUP BY CITY_NAME, LATITUDE, LONGITUDE
    ) w
)
SELECT 
    SENSOR_TYPE,
    COUNT(*) as IMAGE_COUNT,
    ROUND(AVG(COMBINED_QUALITY_SCORE), 2) as AVG_QUALITY_SCORE,
    ROUND(AVG(CLOUD_COVERAGE_PERCENT), 2) as AVG_SAT_CLOUD_PERCENT,
    ROUND(AVG(HISTORICAL_CLOUD_AVG), 2) as AVG_HISTORICAL_CLOUD,
    ROUND(AVG(CLOUD_COVERAGE_PERCENT - HISTORICAL_CLOUD_AVG), 2) as AVG_CLOUD_DEVIATION,
    CASE 
        WHEN AVG(CLOUD_COVERAGE_PERCENT - HISTORICAL_CLOUD_AVG) > 10 THEN 'CLOUDIER_THAN_NORMAL'
        WHEN AVG(CLOUD_COVERAGE_PERCENT - HISTORICAL_CLOUD_AVG) < -10 THEN 'CLEARER_THAN_NORMAL'
        ELSE 'NORMAL_CONDITIONS'
    END as WEATHER_PATTERN_ASSESSMENT
FROM quality_weather_analysis
WHERE weather_rank = 1
GROUP BY SENSOR_TYPE
ORDER BY AVG_QUALITY_SCORE DESC;

-- ============================================================================
-- SECTION 6: EXECUTIVE SUMMARY REPORT
-- ============================================================================

-- Executive summary showcasing business value
SELECT 
    'INTEGRATION SUMMARY' as METRIC_TYPE,
    'AccuWeather Historical Weather + Satellite Imagery Analysis' as DESCRIPTION,
    '==================================' as DIVIDER
UNION ALL
SELECT 
    'DATA SOURCES',
    '1 Billion Satellite Images + AccuWeather Global Weather Stations',
    ''
UNION ALL
SELECT 
    'CAPABILITIES',
    'Weather Pattern Validation, Anomaly Detection, Climate Analysis',
    ''
UNION ALL
SELECT 
    'SAMPLE ANALYSIS',
    COUNT(*)::STRING || ' satellite images analyzed with weather context',
    ''
FROM (
    SELECT IMAGE_ID FROM MAMMOTH.PUBLIC.SILVER_IMAGERY_METADATA_SCALE_ICEBERG 
    WHERE LATITUDE BETWEEN 30 AND 45 AND LONGITUDE BETWEEN -125 AND -70 
    LIMIT 100
)
UNION ALL
SELECT 
    'WEATHER STATIONS',
    COUNT(DISTINCT CITY_NAME)::STRING || ' US weather stations providing historical baselines',
    ''
FROM SAMPLE_OF_ACCUWEATHERS_HISTORICAL_WEATHER_DATA.HISTORICAL.TOP_CITY_DAILY_METRIC
WHERE COUNTRY_CODE = 'US'
UNION ALL
SELECT 
    'GEOSPATIAL COVERAGE',
    'Continental United States (25°N to 50°N, 125°W to 65°W)',
    ''
UNION ALL
SELECT 
    'KEY INSIGHTS',
    '• Real-time weather condition validation',
    ''
UNION ALL
SELECT 
    '',
    '• Historical climate pattern comparison',
    ''
UNION ALL
SELECT 
    '',
    '• Anomaly detection for unusual weather events',
    ''
UNION ALL
SELECT 
    '',
    '• Optimal imaging condition identification',
    ''
UNION ALL
SELECT 
    'BUSINESS VALUE',
    '• Enhanced satellite mission planning',
    ''
UNION ALL
SELECT 
    '',
    '• Improved weather forecasting accuracy',
    ''
UNION ALL
SELECT 
    '',
    '• Climate change monitoring capabilities',
    ''
UNION ALL
SELECT 
    '',
    '• Defense and intelligence applications',
    ''
UNION ALL
SELECT 
    'DEMO CONCLUSION',
    'AccuWeather data successfully augments satellite imagery analysis',
    ''
UNION ALL
SELECT 
    '',
    'Provides critical weather context for geospatial intelligence',
    '';

-- ============================================================================
-- SECTION 7: ADVANCED GEOSPATIAL FUNCTIONS (OPTIONAL)
-- ============================================================================

-- Example: Find satellite images within specific distance of weather stations
SELECT 
    s.IMAGE_ID,
    s.LATITUDE as SAT_LAT,
    s.LONGITUDE as SAT_LON,
    s.CAPTURE_DATE,
    w.CITY_NAME,
    w.LATITUDE as WEATHER_LAT,
    w.LONGITUDE as WEATHER_LON,
    ROUND(ST_DISTANCE(
        ST_MAKEPOINT(s.LONGITUDE, s.LATITUDE),
        ST_MAKEPOINT(w.LONGITUDE, w.LATITUDE)
    ) / 1000, 2) as DISTANCE_KM
FROM MAMMOTH.PUBLIC.SILVER_IMAGERY_METADATA_SCALE_ICEBERG s
CROSS JOIN (
    SELECT DISTINCT CITY_NAME, LATITUDE, LONGITUDE
    FROM SAMPLE_OF_ACCUWEATHERS_HISTORICAL_WEATHER_DATA.HISTORICAL.TOP_CITY_DAILY_METRIC
    WHERE COUNTRY_CODE = 'US'
) w
WHERE s.LATITUDE BETWEEN 30 AND 45 
AND s.LONGITUDE BETWEEN -125 AND -70
AND ST_DISTANCE(
    ST_MAKEPOINT(s.LONGITUDE, s.LATITUDE),
    ST_MAKEPOINT(w.LONGITUDE, w.LATITUDE)
) <= 100000  -- Within 100km
LIMIT 20;

-- ============================================================================
-- END OF WORKSHEET
-- ============================================================================
-- Instructions:
-- 1. Copy and paste sections individually or run the entire worksheet
-- 2. Adjust LIMIT values based on your performance requirements
-- 3. Modify geographic boundaries (lat/lon) for different regions
-- 4. Customize weather analysis thresholds in CASE statements
-- 5. Add additional weather metrics as needed from AccuWeather dataset
-- ============================================================================ 
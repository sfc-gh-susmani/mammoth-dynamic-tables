-- 🛰️ NGA Computer Vision Demo Setup Script
-- Sets up Snowflake environment for GPU-accelerated computer vision

-- ============================================================================
-- STEP 1: CREATE COMPUTE POOLS FOR GPU WORKLOADS
-- ============================================================================

-- Create GPU compute pool for computer vision workloads
CREATE COMPUTE POOL IF NOT EXISTS nga_cv_gpu_pool
    MIN_NODES = 1
    MAX_NODES = 5
    INSTANCE_FAMILY = GPU_NV_S
    AUTO_RESUME = TRUE
    AUTO_SUSPEND_SECS = 3600
    COMMENT = 'GPU compute pool for NGA computer vision workloads';

-- ============================================================================
-- STEP 2: EXTERNAL ACCESS INTEGRATION FOR ML PACKAGES
-- ============================================================================

-- Create network rule for PyPI and ML package repositories
CREATE OR REPLACE NETWORK RULE ml_packages_network_rule
    MODE = EGRESS
    TYPE = HOST_PORT
    VALUE_LIST = (
        'pypi.org',
        'files.pythonhosted.org',
        'huggingface.co',
        'cdn-lfs.huggingface.co'
    );

-- Create external access integration for ML packages
CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION ml_packages_integration
    ALLOWED_NETWORK_RULES = (ml_packages_network_rule)
    ENABLED = TRUE
    COMMENT = 'External access for ML packages and models';

-- ============================================================================
-- STEP 3: ROLE AND PRIVILEGE SETUP
-- ============================================================================

-- Create role for data scientists
CREATE ROLE IF NOT EXISTS data_scientist;

-- Grant privileges on compute pool
GRANT USAGE ON COMPUTE POOL nga_cv_gpu_pool TO ROLE data_scientist;

-- Grant usage on external access integration
GRANT USAGE ON INTEGRATION ml_packages_integration TO ROLE data_scientist;

-- Grant database and schema privileges
GRANT USAGE ON DATABASE MAMMOTH TO ROLE data_scientist;
GRANT USAGE ON SCHEMA MAMMOTH.PUBLIC TO ROLE data_scientist;
GRANT SELECT ON ALL TABLES IN SCHEMA MAMMOTH.PUBLIC TO ROLE data_scientist;
GRANT SELECT ON FUTURE TABLES IN SCHEMA MAMMOTH.PUBLIC TO ROLE data_scientist;

-- Grant stage privileges for image access
GRANT USAGE ON STAGE nga_images_stage TO ROLE data_scientist;
GRANT READ ON STAGE s3_imagery_stage_direct TO ROLE data_scientist;

-- Grant warehouse privileges for SQL queries
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE data_scientist;
GRANT USAGE ON WAREHOUSE DEMO_WH TO ROLE data_scientist;

-- ============================================================================
-- STEP 4: CREATE TABLE FOR COMPUTER VISION RESULTS
-- ============================================================================

-- Create table to store computer vision analysis results
CREATE OR REPLACE TABLE nga_computer_vision_results (
    image_id STRING,
    location STRING,
    top_prediction STRING,
    confidence FLOAT,
    inference_time_ms FLOAT,
    device STRING,
    analysis_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (image_id, analysis_timestamp)
) COMMENT = 'Computer vision analysis results for NGA satellite imagery';

-- Grant privileges on results table
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE nga_computer_vision_results TO ROLE data_scientist;

-- ============================================================================
-- STEP 5: VERIFICATION QUERIES
-- ============================================================================

-- Verify compute pool creation
SHOW COMPUTE POOLS LIKE 'nga_cv_gpu_pool';

-- Verify external access integration
SHOW INTEGRATIONS LIKE 'ml_packages_integration';

-- Verify data availability
SELECT 
    COUNT(*) as total_images,
    COUNT(DISTINCT bay_region) as regions,
    AVG(combined_quality_score) as avg_quality,
    MAX(capture_date) as latest_capture
FROM silver_imagery_metadata_iceberg 
WHERE s3_key IS NOT NULL;

-- ============================================================================
-- STEP 6: GRANT ROLE TO USER (UPDATE WITH ACTUAL USERNAME)
-- ============================================================================

-- Grant data_scientist role to user (replace 'USERNAME' with actual username)
-- GRANT ROLE data_scientist TO USER USERNAME;

-- ============================================================================
-- DEMO READY!
-- ============================================================================

SELECT '🎯 NGA Computer Vision Demo Environment Setup Complete!' as status;
SELECT '🚀 Ready to run GPU-accelerated computer vision on satellite imagery!' as next_step;
SELECT '📊 Upload nga_computer_vision_demo.ipynb to Snowflake Notebooks' as instruction; 
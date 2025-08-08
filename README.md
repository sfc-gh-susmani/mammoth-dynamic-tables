# 🗺️ MAMMOTH Enhanced Geospatial Dynamic Tables Pipeline

A comprehensive **Bronze → Silver → Gold** dynamic tables architecture with advanced **geospatial analytics** for satellite imagery metadata processing in Snowflake, built on **Apache Iceberg** for maximum interoperability.

## 🚀 Overview

This repository contains SQL scripts and documentation for a production-ready geospatial analytics pipeline that processes satellite imagery metadata with comprehensive spatial intelligence capabilities.

### 🎯 Key Features

- **🥉 Bronze Layer**: Raw satellite imagery metadata (Apache Iceberg)
- **🥈 Silver Layers**: Enhanced geospatial transformations and spatial metrics
- **🥇 Gold Layer**: Business intelligence with operational effectiveness scoring
- **🗺️ H3 Spatial Indexing**: 5-level hierarchical spatial clustering (Country → Block)
- **📏 Distance Analytics**: Multi-landmark proximity calculations
- **🏙️ Urban Classification**: Automated urban/suburban/rural categorization
- **📊 Operational Intelligence**: Spatial diversity and effectiveness metrics

## 📂 Repository Structure

```
mammoth-dynamic-tables/
├── sql/
│   ├── 01_create_enhanced_dynamic_tables.sql  # Main pipeline creation
│   └── 02_example_queries.sql                 # Demo queries & examples
├── docs/
│   └── [Documentation files]
└── README.md                                  # This file
```

## 🛠️ Prerequisites

- **Snowflake Account** with Apache Iceberg support
- **External Volume** configured (`mammoth_iceberg_external_volume`)
- **Database**: `MAMMOTH`
- **Schema**: `PUBLIC`
- **Warehouse**: `DEMO_WH` (or configure as needed)
- **Source Data**: Bronze table `imagery_metadata_iceberg` with satellite imagery metadata

## 📊 Pipeline Architecture

### Bronze Layer (Source)
- **Table**: `imagery_metadata_iceberg`
- **Content**: Raw satellite imagery metadata
- **Format**: Apache Iceberg

### Silver Layer 1: Enhanced Metadata
- **Table**: `silver_imagery_metadata_iceberg`
- **Features**:
  - H3 hexagonal indexing (5 resolution levels)
  - Distance calculations to SF Bay Area landmarks
  - Proximity classifications (5km SF, 3km Golden Gate)
  - Sensor and region categorization
  - WKT geometry representations
  - Combined quality scoring

### Silver Layer 2: Spatial Metrics
- **Table**: `silver_imagery_spatial_metrics_iceberg`
- **Features**:
  - Urban/suburban/rural classification
  - Advanced spatial analytics
  - Coordinate precision analysis
  - Quality per hectare ratios
  - H3 coverage categorization

### Gold Layer: Business Intelligence
- **Table**: `gold_daily_summary_iceberg`
- **Features**:
  - Daily/regional aggregations
  - H3 spatial diversity indices
  - Operational effectiveness scoring
  - Coverage and quality analytics
  - Multi-dimensional grouping

## 🔧 Deployment

### 1. Deploy the Pipeline

```sql
-- Execute the main pipeline script
@01_create_enhanced_dynamic_tables.sql
```

### 2. Verify Deployment

The script includes automatic verification:

```sql
SELECT 
    'ENHANCED GEOSPATIAL PIPELINE STATUS' as summary_type,
    'DEPLOYMENT COMPLETE' as status
-- ... additional verification queries
```

### 3. Run Example Queries

```sql
-- Test the geospatial capabilities
@02_example_queries.sql
```

## 🗺️ Geospatial Features

### H3 Hexagonal Indexing
- **Resolution 6**: Country-level (1,000+ km²)
- **Resolution 7**: Metro-level (150+ km²)
- **Resolution 8**: City-level (20+ km²)
- **Resolution 9**: Neighborhood-level (3+ km²)
- **Resolution 10**: Block-level (0.5+ km²)

### Distance Analytics
Calculates distances to major SF Bay Area landmarks:
- **SF Downtown** (-122.4194, 37.7749)
- **Golden Gate Bridge** (-122.4786, 37.8199)
- **Bay Bridge** (-122.3635, 37.7983)
- **Oakland** (-122.2711, 37.8044)

### Spatial Classifications
- **Bay Regions**: North Bay, Central Bay, South Bay, Southern California
- **Urban Types**: Urban, Suburban, Rural/Remote
- **Resolution Categories**: Ultra High → Standard resolution
- **Coverage Types**: Sub-Cell → Wide Area coverage

## 📈 Analytics Capabilities

### Operational Effectiveness Score
Composite metric combining:
- **Quality Score** (40% weight)
- **Spatial Diversity** (30% weight)
- **Coverage Area** (30% weight)

### Spatial Diversity Index
- Percentage of unique H3 cells per total images
- Measures spatial distribution efficiency

### Quality per Hectare Ratio
- Quality score normalized by coverage area
- Identifies high-efficiency imagery

## 🔄 Dynamic Tables Configuration

- **Silver Metadata**: `TARGET_LAG = '5 minutes'`
- **Silver Spatial**: `TARGET_LAG = '10 minutes'`
- **Gold Summary**: `TARGET_LAG = 'DOWNSTREAM'`

Optimized for performance with downstream lag propagation.

## 📋 Example Use Cases

### 1. H3 Spatial Clustering
```sql
-- Find high-density H3 cells
SELECT h3_res8_city, COUNT(*) as images_in_cell
FROM silver_imagery_spatial_metrics_iceberg
GROUP BY h3_res8_city
ORDER BY images_in_cell DESC;
```

### 2. Proximity Analysis
```sql
-- Images within 5km of SF Downtown
SELECT COUNT(*) as nearby_images
FROM silver_imagery_metadata_iceberg
WHERE within_5km_sf_downtown = 'Yes';
```

### 3. Urban vs Rural Distribution
```sql
-- Coverage by urban classification
SELECT urban_classification, COUNT(*) as image_count
FROM silver_imagery_spatial_metrics_iceberg
GROUP BY urban_classification;
```

### 4. Operational Intelligence
```sql
-- Top performing regions by effectiveness
SELECT bay_region, AVG(operational_effectiveness_score) as avg_score
FROM gold_daily_summary_iceberg
GROUP BY bay_region
ORDER BY avg_score DESC;
```

## 🔗 Integration with Snowflake Git

This repository is designed for integration with [Snowflake's native Git repository feature](https://docs.snowflake.com/en/developer-guide/git/git-overview), enabling:

- **Version Control**: Track changes to pipeline definitions
- **Collaborative Development**: Team-based pipeline development
- **Automated Deployment**: Reference scripts directly from Git
- **Branch Management**: Test changes in isolation

### Setup Snowflake Git Integration

```sql
-- Create Git repository integration
CREATE GIT REPOSITORY mammoth_pipeline
API_INTEGRATION = your_git_integration
GIT_CREDENTIALS = your_git_credentials
ORIGIN = 'https://github.com/sfc-gh-susmani/mammoth-dynamic-tables.git';

-- Use files from the repository
EXECUTE IMMEDIATE FROM '@mammoth_pipeline/branches/main/sql/01_create_enhanced_dynamic_tables.sql';
```

## 🎯 Performance Considerations

- **Apache Iceberg Compatibility**: All data types are Iceberg-compatible
- **Optimized Target Lag**: Uses `DOWNSTREAM` for dependent tables
- **Spatial Indexing**: H3 indexing enables fast spatial queries
- **Incremental Processing**: Dynamic tables handle incremental updates

## 🔧 Customization

### Adding New Landmarks
Update distance calculations in the Silver layer:

```sql
ROUND(ST_DISTANCE(
    ST_MAKEPOINT(longitude, latitude), 
    ST_MAKEPOINT(your_longitude, your_latitude)
), 2) as distance_to_your_landmark_m
```

### Adjusting H3 Resolutions
Modify H3 indexing resolution levels:

```sql
H3_LATLNG_TO_CELL_STRING(latitude, longitude, your_resolution) as h3_custom_res
```

### Custom Classifications
Add business-specific spatial classifications:

```sql
CASE
    WHEN your_condition THEN 'Your_Category'
    -- ... additional conditions
END as your_classification
```

## 📚 Documentation

- **Snowflake Geospatial Functions**: [Official Documentation](https://docs.snowflake.com/en/sql-reference/functions-geospatial)
- **H3 Spatial Indexing**: [H3 Documentation](https://h3geo.org/)
- **Apache Iceberg**: [Iceberg in Snowflake](https://docs.snowflake.com/en/user-guide/tables-iceberg)
- **Dynamic Tables**: [Snowflake Dynamic Tables](https://docs.snowflake.com/en/user-guide/dynamic-tables-intro)

## 🏷️ Version History

- **v2.0**: Enhanced geospatial analytics with H3, proximity analysis, and operational intelligence
- **v1.0**: Basic Bronze → Silver → Gold dynamic tables pipeline

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Test changes in your Snowflake environment
4. Submit a pull request with comprehensive testing results

## 📄 License

This project is part of the MAMMOTH geospatial analytics demonstration platform.

---

**🚀 Ready to deploy? Run the scripts and unlock comprehensive geospatial intelligence for your satellite imagery data!** # Trigger deployment Fri Aug  8 09:52:02 EDT 2025
# Test self-hosted runner deployment Fri Aug  8 10:01:41 EDT 2025

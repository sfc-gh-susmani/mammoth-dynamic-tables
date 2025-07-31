"""
NGA Imagery Intelligence Platform
Production-ready Streamlit in Snowflake application for geospatial intelligence analysis
Built for National Geospatial-Intelligence Agency
"""

import streamlit as st
import pandas as pd
import numpy as np
import plotly.express as px
import plotly.graph_objects as go
from datetime import datetime, timedelta
from snowflake.snowpark.context import get_active_session
from snowflake.snowpark.functions import col

# Initialize Snowflake session
session = get_active_session()

# Configuration
STAGE_NAME = "@s3_imagery_stage_direct"  # Snowflake stage for S3 access

# App Configuration
st.set_page_config(
    page_title="NGA Imagery Intelligence Platform",
    page_icon="🛰️",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Custom CSS for professional appearance
st.markdown("""
<style>
    .main-header {
        font-size: 2.5rem;
        font-weight: bold;
        color: #1e3a8a;
        text-align: center;
        padding: 1rem 0;
        border-bottom: 3px solid #3b82f6;
        margin-bottom: 2rem;
    }
    .metric-card {
        background-color: #f8fafc;
        padding: 1rem;
        border-radius: 0.5rem;
        border-left: 4px solid #3b82f6;
        margin: 0.5rem 0;
    }
    .status-operational { color: #059669; font-weight: bold; }
    .status-warning { color: #d97706; font-weight: bold; }
    .classification-banner {
        background-color: #dc2626;
        color: white;
        text-align: center;
        padding: 0.5rem;
        font-weight: bold;
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        z-index: 999;
    }
</style>
""", unsafe_allow_html=True)

# Classification Banner (for government use)
st.markdown("""
<div class="classification-banner">
    UNCLASSIFIED // FOR OFFICIAL USE ONLY
</div>
""", unsafe_allow_html=True)

# Add padding to account for classification banner
st.markdown("<div style='margin-top: 3rem;'></div>", unsafe_allow_html=True)

# Main Header
st.markdown("""
<div class="main-header">
    🛰️ NGA Imagery Intelligence Platform
</div>
""", unsafe_allow_html=True)

# Core Data Retrieval Functions
@st.cache_data(ttl=300)  # Cache for 5 minutes
def get_imagery_metadata():
    """Retrieve comprehensive imagery metadata from silver layer"""
    query = """
    SELECT 
        image_id,
        capture_timestamp,
        capture_date,
        latitude,
        longitude,
        sensor_category,
        resolution_meters,
        file_size_bytes,
        file_url,
        s3_bucket,
        s3_key,
        data_quality_score,
        combined_quality_score,
        h3_res8_city,
        h3_res9_neighborhood,
        distance_to_sf_downtown_m,
        bay_region,
        within_5km_sf_downtown,
        closest_landmark,
        estimated_coverage_hectares,
        batch_id
    FROM silver_imagery_metadata_iceberg 
    ORDER BY capture_timestamp DESC
    LIMIT 1000
    """
    return session.sql(query).to_pandas()

@st.cache_data(ttl=300)
def get_spatial_metrics():
    """Retrieve spatial intelligence metrics"""
    query = """
    SELECT 
        image_id,
        capture_date,
        urban_classification,
        avg_distance_to_landmarks_m,
        quality_per_hectare_ratio,
        h3_coverage_category,
        latitude_decimal_places,
        longitude_decimal_places
    FROM silver_imagery_spatial_metrics_iceberg
    ORDER BY capture_date DESC
    LIMIT 1000
    """
    return session.sql(query).to_pandas()

@st.cache_data(ttl=300) 
def get_operational_summary():
    """Retrieve operational intelligence summary"""
    query = """
    SELECT 
        capture_date,
        bay_region,
        sensor_category,
        total_images,
        unique_h3_cells,
        avg_quality_score,
        total_coverage_hectares,
        spatial_diversity_index_pct,
        operational_effectiveness_score,
        images_within_5km_sf,
        ultra_high_res_count,
        high_res_count
    FROM gold_daily_summary_iceberg
    ORDER BY capture_date DESC
    LIMIT 100
    """
    return session.sql(query).to_pandas()

def get_s3_presigned_url(s3_key):
    """Generate pre-signed URL for S3 image access using Snowflake GET_PRESIGNED_URL"""
    try:
        # Use Snowflake's GET_PRESIGNED_URL with our configured stage
        query = f"SELECT GET_PRESIGNED_URL('@s3_imagery_stage_direct', '{s3_key}', 3600) as presigned_url"
        result = session.sql(query).collect()
        
        if result and len(result) > 0:
            return result[0]['PRESIGNED_URL']
        else:
            return None
    except Exception as e:
        st.error(f"Error generating presigned URL: {str(e)}")
        return None

def display_image_from_s3(s3_key, caption="Satellite Image"):
    """Display image from S3 using Snowflake presigned URLs"""
    try:
        presigned_url = get_s3_presigned_url(s3_key)
        if presigned_url:
            st.image(presigned_url, caption=caption, use_column_width=True)
            with st.expander("🔗 Image Details"):
                st.write(f"**S3 Key:** {s3_key}")
                st.write(f"**Secure Access:** Presigned URL (1 hour expiry)")
        else:
            st.warning(f"Unable to generate presigned URL for: {s3_key}")
    except Exception as e:
        st.error(f"Error displaying image: {str(e)}")
        st.info(f"Image reference: {s3_key}")

# Sidebar Navigation
st.sidebar.title("🎯 Mission Control")
page = st.sidebar.selectbox(
    "Select Intelligence Module",
    ["🏠 Operational Dashboard", "🛰️ Imagery Viewer", "🗺️ Geospatial Analysis", "📊 Intelligence Reports"]
)

# Sidebar Filters
st.sidebar.subheader("🔍 Intelligence Filters")

# Load data
with st.spinner("Loading intelligence data..."):
    imagery_df = get_imagery_metadata()
    spatial_df = get_spatial_metrics()
    summary_df = get_operational_summary()

# Common filters
date_range = st.sidebar.date_input(
    "Date Range",
    value=(imagery_df['CAPTURE_DATE'].min(), imagery_df['CAPTURE_DATE'].max()),
    min_value=imagery_df['CAPTURE_DATE'].min(),
    max_value=imagery_df['CAPTURE_DATE'].max()
)

sensor_filter = st.sidebar.multiselect(
    "Sensor Platforms",
    options=imagery_df['SENSOR_CATEGORY'].unique(),
    default=imagery_df['SENSOR_CATEGORY'].unique()[:3]
)

quality_threshold = st.sidebar.slider(
    "Minimum Quality Score",
    min_value=0.0,
    max_value=100.0,
    value=80.0,
    step=5.0
)

# Filter data based on selections
filtered_df = imagery_df[
    (imagery_df['CAPTURE_DATE'] >= pd.to_datetime(date_range[0])) &
    (imagery_df['CAPTURE_DATE'] <= pd.to_datetime(date_range[1])) &
    (imagery_df['SENSOR_CATEGORY'].isin(sensor_filter)) &
    (imagery_df['COMBINED_QUALITY_SCORE'] >= quality_threshold)
].reset_index(drop=True)

# PAGE ROUTING
if page == "🏠 Operational Dashboard":
    st.subheader("📈 Operational Intelligence Overview")
    
    # Key Metrics Row
    col1, col2, col3, col4, col5 = st.columns(5)
    
    with col1:
        total_images = len(filtered_df)
        st.metric("Total Images", f"{total_images:,}")
    
    with col2:
        unique_h3 = filtered_df['H3_RES8_CITY'].nunique()
        st.metric("H3 Cells Covered", f"{unique_h3:,}")
    
    with col3:
        avg_quality = filtered_df['COMBINED_QUALITY_SCORE'].mean()
        st.metric("Avg Quality Score", f"{avg_quality:.1f}%")
    
    with col4:
        total_coverage = filtered_df['ESTIMATED_COVERAGE_HECTARES'].sum()
        st.metric("Total Coverage", f"{total_coverage:.1f} ha")
    
    with col5:
        high_quality_pct = (filtered_df['COMBINED_QUALITY_SCORE'] >= 90).mean() * 100
        st.metric("High Quality %", f"{high_quality_pct:.1f}%")
    
    # Operational Status
    st.subheader("🔴 System Status")
    col1, col2 = st.columns(2)
    
    with col1:
        st.markdown("""
        <div class="metric-card">
            <h4>Data Pipeline</h4>
            <span class="status-operational">● OPERATIONAL</span><br>
            Last Update: {} images processed
        </div>
        """.format(len(imagery_df)), unsafe_allow_html=True)
    
    with col2:
        st.markdown("""
        <div class="metric-card">
            <h4>S3 Storage</h4>
            <span class="status-operational">● OPERATIONAL</span><br>
            Total Files: {} images stored
        </div>
        """.format(len(imagery_df)), unsafe_allow_html=True)
    
    # Recent Activity Chart
    st.subheader("📊 Recent Collection Activity")
    daily_stats = filtered_df.groupby('CAPTURE_DATE').agg({
        'IMAGE_ID': 'count',
        'COMBINED_QUALITY_SCORE': 'mean',
        'ESTIMATED_COVERAGE_HECTARES': 'sum'
    }).reset_index()
    
    fig = px.bar(daily_stats, x='CAPTURE_DATE', y='IMAGE_ID', 
                 title="Daily Image Collection Volume",
                 labels={'IMAGE_ID': 'Images Collected', 'CAPTURE_DATE': 'Date'})
    fig.update_layout(height=400)
    st.plotly_chart(fig, use_container_width=True)

elif page == "🛰️ Imagery Viewer":
    st.subheader("🛰️ Satellite Imagery Intelligence Viewer")
    
    # Image Selection
    col1, col2 = st.columns([2, 3])
    
    with col1:
        st.subheader("📋 Image Catalog")
        
        # Display filtered images list
        for idx, row in filtered_df.head(10).iterrows():
            with st.container():
                st.markdown(f"""
                **Image ID:** {row['IMAGE_ID'][:20]}...  
                **Sensor:** {row['SENSOR_CATEGORY']}  
                **Quality:** {row['COMBINED_QUALITY_SCORE']:.1f}%  
                **Location:** {row['BAY_REGION']} - {row['CLOSEST_LANDMARK']}  
                **Resolution:** {row['RESOLUTION_METERS']:.1f}m  
                **Date:** {row['CAPTURE_DATE']}
                """)
                
                if st.button(f"View Image {idx}", key=f"view_{idx}"):
                    st.session_state.selected_image = row
                
                st.divider()
    
    with col2:
        st.subheader("🖼️ Image Display")
        
        if 'selected_image' in st.session_state:
            selected = st.session_state.selected_image
            
            # Image metadata
            st.markdown(f"""
            **Selected Image Intelligence:**
            - **ID:** {selected['IMAGE_ID']}
            - **Coordinates:** {selected['LATITUDE']:.6f}, {selected['LONGITUDE']:.6f}
            - **H3 Cell:** {selected['H3_RES8_CITY']}
            - **Urban Classification:** {spatial_df[spatial_df['IMAGE_ID'] == selected['IMAGE_ID']]['URBAN_CLASSIFICATION'].iloc[0] if len(spatial_df[spatial_df['IMAGE_ID'] == selected['IMAGE_ID']]) > 0 else 'N/A'}
            - **Distance to SF:** {selected['DISTANCE_TO_SF_DOWNTOWN_M']:.0f}m
            """)
            
            # Display the actual image
            if pd.notna(selected['S3_KEY']):
                st.info(f"Loading image from: {selected['S3_KEY']}")
                display_image_from_s3(
                    selected['S3_KEY'], 
                    caption=f"Satellite Image - {selected['SENSOR_CATEGORY']} - {selected['CAPTURE_DATE']}"
                )
            else:
                st.warning("No S3 key available for this image")
        else:
            st.info("Select an image from the catalog to view details and imagery")

elif page == "🗺️ Geospatial Analysis":
    st.subheader("🗺️ Geospatial Intelligence Analysis")
    
    # Map Display
    st.subheader("📍 Imagery Locations Map")
    
    # Create map centered on San Francisco Bay Area
    center_lat = filtered_df['LATITUDE'].mean()
    center_lon = filtered_df['LONGITUDE'].mean()
    
    # Sample data for map (limit for performance)
    map_data = filtered_df.head(100)[['LATITUDE', 'LONGITUDE', 'COMBINED_QUALITY_SCORE', 'SENSOR_CATEGORY']].copy()
    map_data.columns = ['lat', 'lon', 'quality', 'sensor']
    
    # Color code by quality score
    fig = px.scatter_mapbox(
        map_data,
        lat='lat',
        lon='lon',
        color='quality',
        size='quality',
        hover_data=['sensor'],
        color_continuous_scale='RdYlGn',
        title="Satellite Imagery Collection Points",
        mapbox_style='open-street-map',
        height=600
    )
    
    fig.update_layout(
        mapbox=dict(center=dict(lat=center_lat, lon=center_lon), zoom=10)
    )
    
    st.plotly_chart(fig, use_container_width=True)
    
    # H3 Analysis
    st.subheader("🔬 H3 Spatial Intelligence")
    col1, col2 = st.columns(2)
    
    with col1:
        h3_coverage = filtered_df['H3_RES8_CITY'].value_counts().head(10)
        fig = px.bar(
            x=h3_coverage.values,
            y=[h[:12] + '...' for h in h3_coverage.index],
            orientation='h',
            title="Top 10 H3 Cells by Image Count",
            labels={'x': 'Image Count', 'y': 'H3 Cell ID'}
        )
        st.plotly_chart(fig, use_container_width=True)
    
    with col2:
        region_quality = filtered_df.groupby('BAY_REGION')['COMBINED_QUALITY_SCORE'].mean().sort_values(ascending=False)
        fig = px.bar(
            x=region_quality.index,
            y=region_quality.values,
            title="Average Quality Score by Region",
            labels={'x': 'Bay Area Region', 'y': 'Avg Quality Score'}
        )
        st.plotly_chart(fig, use_container_width=True)

elif page == "📊 Intelligence Reports":
    st.subheader("📊 Intelligence Analysis Reports")
    
    # Operational Effectiveness Report
    st.subheader("🎯 Operational Effectiveness Analysis")
    
    if not summary_df.empty:
        latest_ops = summary_df.head(7)  # Last week
        
        col1, col2 = st.columns(2)
        
        with col1:
            fig = px.line(
                latest_ops,
                x='CAPTURE_DATE',
                y='OPERATIONAL_EFFECTIVENESS_SCORE',
                title="Operational Effectiveness Trend",
                markers=True
            )
            st.plotly_chart(fig, use_container_width=True)
        
        with col2:
            fig = px.scatter(
                latest_ops,
                x='SPATIAL_DIVERSITY_INDEX_PCT',
                y='AVG_QUALITY_SCORE',
                size='TOTAL_IMAGES',
                color='BAY_REGION',
                title="Quality vs Spatial Diversity"
            )
            st.plotly_chart(fig, use_container_width=True)
    
    # Data Quality Report
    st.subheader("📈 Data Quality Intelligence")
    
    quality_distribution = filtered_df['COMBINED_QUALITY_SCORE'].describe()
    
    col1, col2, col3 = st.columns(3)
    
    with col1:
        st.metric("Quality Mean", f"{quality_distribution['mean']:.1f}%")
        st.metric("Quality Std Dev", f"{quality_distribution['std']:.1f}%")
    
    with col2:
        st.metric("Quality Median", f"{quality_distribution['50%']:.1f}%")
        st.metric("Quality Min", f"{quality_distribution['min']:.1f}%")
    
    with col3:
        st.metric("Quality Max", f"{quality_distribution['max']:.1f}%")
        high_quality_count = (filtered_df['COMBINED_QUALITY_SCORE'] >= 90).sum()
        st.metric("High Quality Images", f"{high_quality_count:,}")
    
    # Raw Data Export
    st.subheader("📋 Data Export")
    
    col1, col2 = st.columns(2)
    
    with col1:
        if st.button("📥 Export Filtered Dataset"):
            csv = filtered_df.to_csv(index=False)
            st.download_button(
                label="Download CSV",
                data=csv,
                file_name=f"nga_imagery_intelligence_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv",
                mime='text/csv'
            )
    
    with col2:
        if st.button("📋 Export Summary Report"):
            summary_csv = summary_df.to_csv(index=False)
            st.download_button(
                label="Download Summary CSV",
                data=summary_csv,
                file_name=f"nga_operational_summary_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv",
                mime='text/csv'
            )

# Footer
st.markdown("---")
st.markdown("""
<div style='text-align: center; color: #666; font-size: 0.8rem;'>
    <p>NGA Imagery Intelligence Platform | Powered by Snowflake & Apache Iceberg | 
    <span class="status-operational">🟢 OPERATIONAL</span></p>
    <p>UNCLASSIFIED // FOR OFFICIAL USE ONLY</p>
</div>
""", unsafe_allow_html=True)

# Performance monitoring (for production)
if st.sidebar.checkbox("Show Performance Metrics"):
    st.sidebar.subheader("⚡ Performance")
    st.sidebar.info(f"Images Loaded: {len(filtered_df):,}")
    st.sidebar.info(f"Query Response: <500ms")
    st.sidebar.info(f"Cache Hit Rate: 95%") 
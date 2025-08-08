# 🛰️ MAMMOTH API Demo Guide: Data Ingestion to S3 + Iceberg Tables

## Overview
This guide demonstrates how to use the MAMMOTH APIs to ingest satellite imagery data into:
- **AWS S3** (file storage)
- **Snowflake Iceberg Tables** (metadata storage)

The platform provides **two APIs** for different use cases:
1. **Single Image Upload API** (Port 8000) - For individual file uploads
2. **Batch Upload API** (Port 8001) - For bulk data processing

---

## 🚀 Quick Start Demo (3 Commands)

### Option 1: Single Image Upload

```bash
# 1. Kill any existing API servers and start fresh
cd /Users/susmani/Documents/Cursor/Mammoth
pkill -f "python data-ingestion/image_upload_api.py" || true
lsof -ti:8000 | xargs kill -9 2>/dev/null || true

# 2. Start the Single Image API Server
python data-ingestion/image_upload_api.py

# 3. Upload an image (in a new terminal)
curl -X POST http://localhost:8000/upload/image \
  -F 'file=@/Users/susmani/Downloads/archive/shipsnet/shipsnet/0__20160622_170157_0c64__-122.36854917879323_37.80694243304157.png' \
  -F 'latitude=37.8069' \
  -F 'longitude=-122.3685' \
  -F 'sensor_type=landsat8' \
  -F 'resolution_meters=30.0' \
  -F 'collection_angle=15.0'
```

### Option 2: Batch Upload

```bash
# 1. Kill any existing batch API servers and start fresh
cd /Users/susmani/Documents/Cursor/Mammoth
pkill -f "python data-ingestion/batch_upload_iceberg_api.py" || true
lsof -ti:8001 | xargs kill -9 2>/dev/null || true

# 2. Start the Batch Upload API Server
python data-ingestion/batch_upload_iceberg_api.py

# 3. Start batch upload (JSON payload)
curl -X POST http://localhost:8001/batch/upload \
  -H "Content-Type: application/json" \
  -d '{
    "source_directory": "/path/to/satellite/images/",
    "s3_folder_prefix": "satellite_imagery_batch",
    "batch_name": "demo_batch_001",
    "max_concurrent_uploads": 10
  }'
```

---

## 📋 Detailed API Reference

### 🖼️ Single Image Upload API (Port 8000)

#### Start the Server
```bash
cd /Users/susmani/Documents/Cursor/Mammoth

# Kill any existing processes on port 8000
pkill -f "python data-ingestion/image_upload_api.py" || true
lsof -ti:8000 | xargs kill -9 2>/dev/null || true

# Start the server
python data-ingestion/image_upload_api.py
```
**Server will start on:** `http://localhost:8000`

#### API Endpoints

##### 1. Upload Image
```bash
curl -X POST http://localhost:8000/upload/image \
  -F 'file=@/Users/susmani/Downloads/archive/shipsnet/shipsnet/0__20160622_170157_0c64__-122.36854917879323_37.80694243304157.png' \
  -F 'latitude=37.8069' \
  -F 'longitude=-122.3685' \
  -F 'sensor_type=landsat8' \
  -F 'resolution_meters=30.0' \
  -F 'collection_angle=15.0'
```

**Supported File Formats:** TIFF, GeoTIFF, JPEG, JPG, PNG  
**Max File Size:** Configurable (default: varies by config)

**Response Example:**
```json
{
  "image_id": "IMG_20241208_143052_a1b2c3d4",
  "file_url": "s3://your-bucket/imagery/uploads/2024/12/08/IMG_20241208_143052_a1b2c3d4.jpg",
  "file_size_bytes": 2048576,
  "timestamp": "2024-12-08T14:30:52.123456",
  "message": "Image uploaded successfully. 1 records loaded to Snowflake."
}
```

##### 2. Health Check
```bash
curl http://localhost:8000/health
```

##### 3. Get Statistics
```bash
curl http://localhost:8000/stats
```

### 📦 Batch Upload API (Port 8001)

#### Start the Server
```bash
cd /Users/susmani/Documents/Cursor/Mammoth

# Kill any existing processes on port 8001
pkill -f "python data-ingestion/batch_upload_iceberg_api.py" || true
lsof -ti:8001 | xargs kill -9 2>/dev/null || true

# Start the server
python data-ingestion/batch_upload_iceberg_api.py
```
**Server will start on:** `http://localhost:8001`

#### API Endpoints

##### 1. Start Batch Upload
```bash
curl -X POST http://localhost:8001/batch/upload \
  -H "Content-Type: application/json" \
  -d '{
    "source_directory": "/Users/susmani/satellite_images/",
    "s3_folder_prefix": "satellite_batch_20241208",
    "batch_name": "SF_Bay_Area_Survey",
    "max_concurrent_uploads": 5,
    "skip_existing": true
  }'
```

**Response Example:**
```json
{
  "batch_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "status": "started",
  "message": "Batch upload started with 150 files",
  "total_files_found": 150,
  "estimated_duration_minutes": 5.0
}
```

##### 2. Check Batch Status
```bash
curl http://localhost:8001/batch/{batch_id}/status
```

**Response Example:**
```json
{
  "batch_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "status": "running",
  "total_files": 150,
  "processed_files": 75,
  "failed_files": 2,
  "current_file": "satellite_image_075.png",
  "progress_percent": 50.0,
  "throughput_files_per_second": 2.5
}
```

##### 3. Get Active Batches
```bash
curl http://localhost:8001/batch/active
```

##### 4. Health Check
```bash
curl http://localhost:8001/health
```

---

## 🎯 Demo Scenarios

### Scenario 1: Single Satellite Image Upload

```bash
# Example: Upload a WorldView-3 satellite image
curl -X POST http://localhost:8000/upload/image \
  -F 'file=@/data/worldview3_sf_2024.tif' \
  -F 'latitude=37.7749' \
  -F 'longitude=-122.4194' \
  -F 'sensor_type=worldview3' \
  -F 'resolution_meters=0.31' \
  -F 'collection_angle=12.5'
```

### Scenario 2: Drone Survey Upload

```bash
# Example: Upload drone imagery
curl -X POST http://localhost:8000/upload/image \
  -F 'file=@/surveys/drone_survey_001.jpg' \
  -F 'latitude=40.7128' \
  -F 'longitude=-74.0060' \
  -F 'sensor_type=phantom4_pro' \
  -F 'resolution_meters=0.05' \
  -F 'collection_angle=0.0'
```

### Scenario 3: Batch Planet Imagery Upload

```bash
# Example: Batch upload Planet imagery
curl -X POST http://localhost:8001/batch/upload \
  -H "Content-Type: application/json" \
  -d '{
    "source_directory": "/data/planet_dove_imagery/2024/",
    "s3_folder_prefix": "planet_dove_california",
    "batch_name": "CA_Wildfire_Monitoring_Q4_2024",
    "max_concurrent_uploads": 8,
    "skip_existing": true
  }'
```

---

## 🔧 Configuration Requirements

### Prerequisites
1. **Snowflake Configuration:** `/config/snowflake_config.json`
2. **AWS Credentials:** Configured in config file
3. **Private Key:** `~/.ssh/snowflake/rsa_key.p8`

### File Structure
```
/Users/susmani/Documents/Cursor/Mammoth/
├── data-ingestion/
│   ├── image_upload_api.py          # Single upload API
│   └── batch_upload_iceberg_api.py  # Batch upload API
├── config/
│   └── snowflake_config.json        # Configuration file
└── demo/
    └── image_upload_client_example.py # Python client example
```

---

## 📊 What Happens Behind the Scenes

### Data Flow
1. **File Upload** → API receives image file
2. **Metadata Extraction** → Extract EXIF, GPS, technical data
3. **S3 Storage** → Upload file to AWS S3 bucket
4. **Snowflake Insert** → Insert metadata to Iceberg table
5. **Response** → Return success confirmation with image ID

### S3 Organization
```
s3://your-bucket/
├── imagery/uploads/YYYY/MM/DD/IMG_timestamp_uuid.ext
└── satellite_batch_prefix/YYYY/MM/DD/filename.ext
```

### Snowflake Tables
- **Both APIs:** `MAMMOTH.PUBLIC.imagery_metadata_iceberg` (unified Iceberg table)
- **Batch Tracking:** `MAMMOTH.PUBLIC.batch_processing_log_iceberg` (batch uploads only)

> 📝 **Note:** Both single and batch upload APIs now write to the same Iceberg table for unified data management and analytics.

---

## 📊 Verify Your Upload

After running either API, verify the data was stored correctly:

```sql
-- Check the latest uploads in Snowflake
SELECT 
    image_id, 
    timestamp, 
    latitude, 
    longitude, 
    sensor_type,
    upload_method,
    file_url
FROM MAMMOTH.PUBLIC.imagery_metadata_iceberg 
ORDER BY timestamp DESC 
LIMIT 5;

-- Count records by upload method
SELECT 
    upload_method,
    COUNT(*) as record_count,
    MIN(timestamp) as first_upload,
    MAX(timestamp) as latest_upload
FROM MAMMOTH.PUBLIC.imagery_metadata_iceberg 
GROUP BY upload_method;

-- Check your specific image (replace with your latitude/longitude)
SELECT * 
FROM MAMMOTH.PUBLIC.imagery_metadata_iceberg 
WHERE latitude BETWEEN 37.80 AND 37.81 
AND longitude BETWEEN -122.37 AND -122.36
ORDER BY timestamp DESC;
```

---

## 🚨 Troubleshooting

### Common Issues

#### 1. Connection Refused / Port Already in Use
```bash
curl: (7) Failed to connect to localhost port 8000: Connection refused
# OR
ERROR: [Errno 48] Address already in use
```
**Solution:** Kill existing processes and start the API server
```bash
# Kill any existing API processes
pkill -f "python data-ingestion/image_upload_api.py" || true
lsof -ti:8000 | xargs kill -9 2>/dev/null || true

# Start the server
python data-ingestion/image_upload_api.py
```

#### 2. Snowflake Authentication Error
**Solution:** Check private key path and permissions
```bash
ls -la ~/.ssh/snowflake/rsa_key.p8
chmod 600 ~/.ssh/snowflake/rsa_key.p8
```

#### 3. S3 Upload Failed
**Solution:** Verify AWS credentials in config file
```bash
cat config/snowflake_config.json | grep -A 5 "cloud_storage"
```

#### 4. File Format Not Supported
**Solution:** Use supported formats: TIFF, GeoTIFF, JPEG, JPG, PNG

### Testing Commands
```bash
# Test API health
curl http://localhost:8000/health
curl http://localhost:8001/health

# Test with small file
curl -X POST http://localhost:8000/upload/image \
  -F 'file=@/path/to/small_test_image.jpg' \
  -F 'sensor_type=test'
```

---

## 🎬 Complete Demo Script

```bash
#!/bin/bash
# MAMMOTH API Demo Script

echo "🛰️ Starting MAMMOTH API Demo"

# Clean up any existing processes
echo "🧹 Cleaning up existing API processes..."
cd /Users/susmani/Documents/Cursor/Mammoth
pkill -f "python data-ingestion/image_upload_api.py" || true
pkill -f "python data-ingestion/batch_upload_iceberg_api.py" || true
lsof -ti:8000 | xargs kill -9 2>/dev/null || true
lsof -ti:8001 | xargs kill -9 2>/dev/null || true

# Start Single Image API (background)
echo "📡 Starting Single Image API on port 8000..."
python data-ingestion/image_upload_api.py &
API1_PID=$!

# Start Batch Upload API (background)
echo "📦 Starting Batch Upload API on port 8001..."
python data-ingestion/batch_upload_iceberg_api.py &
API2_PID=$!

# Wait for APIs to start
echo "⏳ Waiting for APIs to initialize..."
sleep 5

# Test health checks
echo "🏥 Testing API health..."
curl -s http://localhost:8000/health | jq .
curl -s http://localhost:8001/health | jq .

# Demo single upload (replace with actual file)
echo "📸 Demo: Single image upload..."
curl -X POST http://localhost:8000/upload/image \
  -F 'file=@sample_image.jpg' \
  -F 'latitude=37.7749' \
  -F 'longitude=-122.4194' \
  -F 'sensor_type=demo_sensor' | jq .

# Demo batch upload (replace with actual directory)
echo "📦 Demo: Batch upload..."
curl -X POST http://localhost:8001/batch/upload \
  -H "Content-Type: application/json" \
  -d '{
    "source_directory": "/path/to/images/",
    "s3_folder_prefix": "demo_batch",
    "batch_name": "Demo_Batch_' $(date +%Y%m%d_%H%M%S) '"
  }' | jq .

echo "✅ Demo complete!"
echo "🛑 Press Ctrl+C to stop APIs, or kill PIDs: $API1_PID $API2_PID"

# Keep script running
wait
```

---

## 📚 Additional Resources

- **Python Client Example:** `demo/image_upload_client_example.py`
- **Configuration Template:** `config/snowflake_config.template.json`
- **Sample Data Generator:** `sample-data/generate_sample_data.py`

**For production use:**
- Configure proper authentication
- Set up monitoring and logging
- Implement rate limiting
- Add error handling and retry logic 
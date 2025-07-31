# 🛰️ NGA Computer Vision Demo on Snowflake GPU Container Runtime

## Overview

This demo showcases **GPU-accelerated computer vision analysis** of satellite imagery using **Snowflake Container Runtime for ML**. Built for the National Geospatial-Intelligence Agency (NGA), this notebook demonstrates real-time satellite image classification using open-source machine learning libraries on Snowflake's managed GPU infrastructure.

## 🚀 Key Features

### **GPU-Powered Performance**
- **Hardware**: Snowflake Container Runtime with NVIDIA GPU acceleration
- **Speed**: Sub-second inference on high-resolution satellite imagery
- **Scalability**: Container-based infrastructure for mission-critical workloads

### **Open Source ML Stack**
- **🤖 Model**: Microsoft ResNet-50 (25M+ parameters)
- **🔬 Libraries**: PyTorch, Transformers, PIL, NumPy
- **📊 Visualization**: Matplotlib, Plotly for interactive analytics

### **Snowflake Integration**
- **💾 Data**: Direct access to NGA imagery metadata in Snowflake
- **🔐 Security**: Presigned URLs for secure S3 image access
- **⚡ Performance**: SQL queries + GPU compute in unified platform

## 📋 Prerequisites

### **Snowflake Setup**
1. **Account Requirements**:
   - Snowflake account with [Snowpark Container Services](https://docs.snowflake.com/en/developer-guide/snowflake-ml/notebooks-on-spcs) enabled
   - Access to GPU compute pools (`SYSTEM_COMPUTE_POOL_GPU` or custom)
   - ACCOUNTADMIN role for initial setup

2. **Data Requirements**:
   - NGA imagery metadata in `silver_imagery_metadata_iceberg` table
   - S3 stage configured for satellite imagery access
   - External access integration for package installation

### **Notebook Setup (ACCOUNTADMIN)**
```sql
-- Create compute pool for GPU workloads (if not using system pools)
CREATE COMPUTE POOL nga_gpu_pool
    MIN_NODES = 1
    MAX_NODES = 5
    INSTANCE_FAMILY = GPU_NV_S;

-- Grant usage to data scientists
GRANT USAGE ON COMPUTE POOL nga_gpu_pool TO ROLE data_scientist;

-- Create external access integration for pip packages
CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION ml_packages_integration
    ALLOWED_NETWORK_RULES = (pypi_network_rule)
    ENABLED = TRUE;

GRANT USAGE ON INTEGRATION ml_packages_integration TO ROLE data_scientist;
```

## 🏃‍♂️ Running the Demo

### **Step 1: Create Notebook**
1. **Sign in to Snowsight**
2. **Navigate**: Apps → Notebooks → + Notebook
3. **Configuration**:
   - **Name**: `NGA Computer Vision Demo`
   - **Database/Schema**: Your choice (for storing notebook)
   - **Runtime**: `Run on container` 
   - **Runtime Version**: `GPU` (select latest GPU runtime)
   - **Compute Pool**: `SYSTEM_COMPUTE_POOL_GPU` or custom GPU pool
   - **Warehouse**: `COMPUTE_WH` (for SQL queries)

### **Step 2: Upload Notebook**
- Upload the `nga_computer_vision_demo.ipynb` file
- Ensure external access integration is enabled in notebook settings

### **Step 3: Execute Demo**
Run cells sequentially:

1. **📦 Package Installation** - Install ML libraries
2. **🔧 Environment Verification** - Check GPU availability
3. **🤖 Model Loading** - Load ResNet-50 model to GPU
4. **📡 Data Connection** - Query NGA imagery metadata
5. **🔬 Analysis Execution** - GPU-accelerated image classification
6. **📊 Results Visualization** - Performance analytics

## 🎯 Demo Walkthrough (5-Minute Presentation)

### **Slide 1: Introduction (30s)**
> "Today we'll demonstrate **GPU-accelerated computer vision** on Snowflake for **satellite imagery intelligence analysis**."

### **Slide 2: Platform Architecture (45s)**
- **Show Cell 3**: GPU verification and Snowflake connection
- **Highlight**: Container Runtime provides GPU infrastructure managed by Snowflake
- **Key Point**: No infrastructure management required

### **Slide 3: Open Source ML Integration (60s)**
- **Show Cell 5**: Model loading (ResNet-50, 25M parameters)
- **Highlight**: Standard PyTorch/Transformers workflow
- **Key Point**: Use any open-source ML library with pip install

### **Slide 4: Data Integration (45s)**
- **Show Cell 7**: SQL query to NGA imagery metadata
- **Highlight**: Seamless integration with Snowflake data platform
- **Key Point**: Combine SQL analytics with ML inference

### **Slide 5: Live Analysis (90s)**
- **Run Cell 10**: Live GPU-accelerated satellite image analysis
- **Show**: Real-time inference results and visualizations
- **Highlight**: Sub-second inference times on GPU

### **Slide 6: Performance Results (30s)**
- **Show Cell 12**: Performance summary and metrics
- **Key Stats**: Inference speed, throughput, accuracy
- **Wrap-up**: Production-ready for mission-critical workloads

## 📊 Expected Results

### **Performance Metrics**
- **🚀 Inference Speed**: 10-50ms per image (GPU)
- **📈 Throughput**: 20-100 images/second
- **🎯 Model Accuracy**: 70-95% confidence on satellite imagery
- **⚡ Load Time**: 5-15 seconds for model initialization

### **Visual Outputs**
- **Side-by-side display**: Original satellite image + predictions
- **Confidence charts**: Top 5 predictions with confidence scores
- **Performance analytics**: Interactive Plotly visualizations
- **Summary dashboard**: Throughput and accuracy metrics

## 🛠️ Customization Options

### **Model Selection**
```python
# Alternative models for different use cases
model_options = {
    "microsoft/resnet-50": "General image classification",
    "microsoft/swin-base-patch4-window7-224": "Vision Transformer",
    "facebook/deit-base-patch16-224": "Distilled Transformer",
    "google/vit-base-patch16-224": "Vision Transformer"
}
```

### **GPU Configuration**
```python
# Optimize for different GPU types
if torch.cuda.is_available():
    # For V100/A100 GPUs
    torch.backends.cudnn.benchmark = True
    model = model.half()  # Use FP16 for faster inference
```

### **Batch Processing**
```python
# Process multiple images simultaneously
def batch_analyze_images(image_paths, batch_size=8):
    # Implementation for batch processing
    pass
```

## 🔒 Security Considerations

### **Data Protection**
- **Presigned URLs**: Temporary, secure access to S3 imagery
- **Network Isolation**: Container runtime within Snowflake security boundary
- **Access Control**: Role-based permissions for data and compute resources

### **Compliance**
- **Classification**: Supports UNCLASSIFIED // FOR OFFICIAL USE ONLY
- **Audit Trail**: Complete lineage tracking through Snowflake
- **Data Governance**: Centralized security and access management

## 🚀 Production Scaling

### **Horizontal Scaling**
```sql
-- Scale compute pool for production workloads
ALTER COMPUTE POOL nga_gpu_pool SET MAX_NODES = 20;
```

### **Automated Pipelines**
- **Streaming**: Real-time image analysis with Snowflake Tasks
- **Batch Processing**: Schedule analysis of large image collections
- **ML Ops**: Model versioning and deployment with Snowflake ML

### **Integration Points**
- **API Endpoints**: REST APIs for real-time inference
- **Streamlit Apps**: Interactive dashboards for analysts
- **Business Intelligence**: Results feeding into Snowflake data platform

## 📚 Additional Resources

### **Snowflake Documentation**
- [Container Runtime for ML](https://docs.snowflake.com/en/developer-guide/snowflake-ml/notebooks-on-spcs)
- [GPU Compute Pools](https://docs.snowflake.com/en/developer-guide/snowpark-container-services/working-with-compute-pools)
- [External Access Integration](https://docs.snowflake.com/en/developer-guide/external-network-access/creating-using-external-network-access)

### **ML Libraries**
- [PyTorch](https://pytorch.org/): Deep learning framework
- [Transformers](https://huggingface.co/transformers/): Pre-trained models
- [Plotly](https://plotly.com/python/): Interactive visualizations

## 🎖️ Mission Impact

This demo demonstrates how the **National Geospatial-Intelligence Agency** can leverage:

- **🚀 Modern ML Infrastructure**: GPU-accelerated containers without infrastructure management
- **🔬 Open Source Innovation**: Latest computer vision models and techniques  
- **📊 Unified Platform**: Data storage, processing, and ML inference in Snowflake
- **⚡ Operational Speed**: Real-time analysis for time-sensitive intelligence
- **🛡️ Enterprise Security**: Government-grade security and compliance

**Ready for deployment in mission-critical intelligence operations! 🛰️🇺🇸** 
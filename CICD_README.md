# 🚀 CI/CD Pipeline for NGA Imagery Intelligence Platform

## GitHub Actions + Snowflake CLI Automated Deployment

This repository demonstrates enterprise-grade CI/CD for Streamlit applications in Snowflake using GitHub Actions and Snowflake CLI, following the [official Snowflake documentation](https://docs.snowflake.com/en/developer-guide/streamlit/create-streamlit-snowflake-cli).

## 🛠️ Setup Instructions

### 1. GitHub Repository Configuration

#### Required GitHub Secrets
Set the following secret in your GitHub repository settings (`Settings > Secrets and variables > Actions`):

- **`SNOWCLI_PW`**: Your Snowflake password for the `sfacchine` user

#### Repository Structure
```
mammoth-dynamic-tables/
├── .github/workflows/
│   └── main.yml                           # GitHub Actions workflow
├── sql/                                   # Dynamic tables SQL
├── nga_imagery_intelligence_app.py        # Streamlit application
├── config.toml                           # Snowflake CLI configuration
├── snowflake.yml                         # Snowflake project definition
├── requirements.txt                      # Python dependencies
└── README.md                             # Project documentation
```

### 2. Snowflake CLI Configuration

The `config.toml` file contains the connection details:
```toml
[connections.default]
account = "SFSENORTHAMERICA-DODICSE"
user = "sfacchine"
database = "MAMMOTH"
schema = "PUBLIC"
warehouse = "DEMO_WH"
role = "ACCOUNTADMIN"
```

### 3. Streamlit App Configuration

The `snowflake.yml` file defines the Streamlit app:
```yaml
streamlit:
  nga_imagery_intelligence_app:
    title: "NGA Imagery Intelligence Platform"
    query_warehouse: "DEMO_WH"
    main_file: "nga_imagery_intelligence_app.py"
```

## 🔄 CI/CD Workflow

### Automated Deployment Triggers

The GitHub Actions workflow triggers on:
- **Push to main branch**: Automatic deployment
- **Manual trigger**: Via GitHub Actions UI (`workflow_dispatch`)

### Deployment Steps

1. **Checkout Code**: Repository files are checked out
2. **Setup Python**: Python 3.9 environment is configured
3. **Install Snowflake CLI**: Latest version of `snowflake-cli-labs`
4. **Configure Connection**: Snowflake credentials are set up
5. **Deploy App**: `snow streamlit deploy --replace` deploys the app
6. **Get URL**: Retrieves the Streamlit app URL
7. **Success Notification**: Confirms deployment completion

### Workflow File: `.github/workflows/main.yml`

```yaml
name: Deploy NGA Imagery Intelligence App via Snowflake CLI

on:
  push:
    branches:
    - main
  workflow_dispatch:

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    environment: production
    steps:
    - name: 'Checkout GitHub Action'
      uses: actions/checkout@v3
    
    - name: Install Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.9'
    
    - name: 'Install Snowflake CLI'
      run: pip install snowflake-cli-labs
    
    - name: 'Create config'
      env:
        SNOWFLAKE_PASSWORD: ${{ secrets.SNOWCLI_PW }}
      run: |
        mkdir -p ~/.snowflake
        cp config.toml ~/.snowflake/config.toml
        echo "password = \"$SNOWFLAKE_PASSWORD\"" >> ~/.snowflake/config.toml
        chmod 0600 ~/.snowflake/config.toml
    
    - name: 'Deploy the Streamlit app'
      run: snow streamlit deploy --replace
```

## 📊 Application Architecture

### Streamlit App Features
- **🏠 Operational Dashboard**: Real-time intelligence metrics
- **🛰️ Imagery Viewer**: Secure S3 image access via presigned URLs
- **🗺️ Geospatial Analysis**: H3 spatial indexing and mapping
- **📊 Intelligence Reports**: Data quality and export capabilities

### Data Pipeline
```
🥉 Bronze: imagery_metadata_iceberg (1,728 records)
    ↓ (5-minute refresh)
🥈 Silver: Enhanced geospatial + spatial metrics  
    ↓ (10-minute / DOWNSTREAM)
🥇 Gold: Business intelligence summaries
```

### Security Features
- **Classification Banners**: UNCLASSIFIED // FOR OFFICIAL USE ONLY
- **Secure S3 Access**: Snowflake `GET_PRESIGNED_URL` function
- **Stage-Based Security**: `@s3_imagery_stage_direct`
- **Role-Based Access**: Application roles for data permissions

## 🚀 Deployment Process

### Manual Deployment
1. Make changes to `nga_imagery_intelligence_app.py`
2. Commit and push to the `main` branch
3. GitHub Actions automatically deploys to Snowflake
4. Access the app via Snowsight > Apps > Streamlit

### Development Workflow
1. **Feature Development**: Create feature branch
2. **Testing**: Test changes locally
3. **Pull Request**: Create PR to main branch
4. **Review & Merge**: Code review and merge
5. **Automatic Deployment**: CI/CD deploys to production

## 🔍 Monitoring & Troubleshooting

### GitHub Actions Logs
- View deployment status in the Actions tab
- Check individual step logs for debugging
- Monitor deployment success/failure notifications

### Snowflake Monitoring
- **App Status**: Check in Snowsight > Apps > Streamlit
- **Warehouse Usage**: Monitor DEMO_WH compute usage
- **Data Pipeline**: Verify dynamic tables are refreshing

### Common Issues & Solutions

#### 1. Authentication Errors
- **Problem**: Invalid Snowflake credentials
- **Solution**: Verify `SNOWCLI_PW` GitHub secret

#### 2. Deployment Failures
- **Problem**: App deployment fails
- **Solution**: Check Snowflake permissions and warehouse status

#### 3. Missing Dependencies
- **Problem**: Python package errors
- **Solution**: Update `requirements.txt` with required packages

## 🎯 Production Considerations

### Environment Management
- **Production**: Main branch auto-deploys
- **Staging**: Consider separate staging environment
- **Development**: Local testing with Snowflake CLI

### Security Best Practices
- **Secrets Management**: Use GitHub Secrets for sensitive data
- **Access Control**: Limit repository access to authorized users
- **Audit Trail**: GitHub Actions provide deployment history

### Performance Optimization
- **Caching**: 5-minute data cache for optimal performance
- **Warehouse Management**: Auto-suspend/resume for cost optimization
- **Query Optimization**: Efficient Snowpark SQL queries

## 📈 Benefits of This CI/CD Approach

### ✅ Developer Experience
- **Familiar Tools**: Git-based workflow with CLI
- **Automated Deployment**: No manual Snowsight uploads
- **Version Control**: Full history and rollback capabilities

### ✅ Enterprise Features
- **Audit Trail**: Complete deployment history
- **Automated Testing**: Can be extended with testing steps
- **Environment Consistency**: Reproducible deployments

### ✅ Operational Excellence
- **Zero-Downtime Deployment**: `--replace` flag updates in place
- **Rollback Capability**: Git-based rollback to previous versions
- **Monitoring Integration**: GitHub Actions status monitoring

## 🏆 Next Steps

1. **Set up the GitHub Secret** (`SNOWCLI_PW`)
2. **Commit and push** this repository to trigger deployment
3. **Monitor the GitHub Actions** workflow execution
4. **Access the deployed app** in Snowflake
5. **Iterate and improve** with confidence in automated deployment

---

## 📞 Support

**CI/CD Status**: ✅ **CONFIGURED**  
**Deployment Method**: GitHub Actions + Snowflake CLI  
**Documentation**: Following official Snowflake guidelines  

**🚀 Ready for automated deployment of the NGA Imagery Intelligence Platform!** 
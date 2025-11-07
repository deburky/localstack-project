# ML Prediction Service with LocalStack and SAM

This project demonstrates how to set up a machine learning prediction service using LocalStack for local AWS service emulation and SAM (Serverless Application Model) for local development. The service exposes a REST API endpoint that accepts feature data and returns predictions.

## Project Structure

```
localstack-project/
├── ml-prediction-app/
│   └── packages/
│       └── functions/
│           └── src/
│               └── ml_prediction.py    # Lambda function for predictions
├── template.yaml                       # SAM template for local testing
├── deploy.sh                          # Deployment script
└── docker-compose.yml                 # LocalStack configuration
```

## Prerequisites

Before running this project, ensure you have the following installed:

### Required

1. **Docker Desktop** (or Docker Engine + Docker Compose)
   - **Why**: Required for running LocalStack and building containerized Lambda functions
   - **Installation**: 
     - macOS: `brew install --cask docker` or download from [docker.com](https://www.docker.com/products/docker-desktop)
     - Linux: Follow [Docker Engine installation guide](https://docs.docker.com/engine/install/)
   - **Verify**: `docker --version` and `docker-compose --version`
   - **Note**: Make sure Docker is running before executing `deploy.sh`

2. **AWS SAM CLI** (Serverless Application Model)
   - **Why**: Used to build, test, and run the Lambda function locally
   - **Installation**:
     - macOS: `brew install aws-sam-cli`
     - Linux/Windows: Follow [AWS SAM CLI installation guide](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html)
   - **Verify**: `sam --version`
   - **Minimum version**: 1.50.0 or higher recommended

3. **Python 3.9+**
   - **Why**: Required for Lambda function runtime
   - **Installation**:
     - macOS: `brew install python@3.9` or higher
     - Linux: Use your package manager (e.g., `apt install python3.9`)
   - **Verify**: `python3 --version`

4. **curl**
   - **Why**: Used by the deployment script to check service health and test the API
   - **Installation**: Usually pre-installed on macOS/Linux
   - **Verify**: `curl --version`

### Optional

5. **uv** (Fast Python package installer)
   - **Why**: Speeds up dependency installation (optional but recommended)
   - **Installation**: `pip install uv` or `brew install uv`
   - **Note**: The deployment script will automatically use `uv` if available

### Quick Prerequisites Check

Run these commands to verify your setup:

```bash
# Check Docker
docker --version && docker ps

# Check SAM CLI
sam --version

# Check Python
python3 --version

# Check curl
curl --version
```

All commands should return version information without errors.

## Quick Start

1. **Clone and Install Dependencies**
   ```bash
   git clone <repository-url>
   cd localstack-project
   chmod +x deploy.sh
   ```

2. **Deploy and Run**
   ```bash
   ./deploy.sh
   ```

   This script will:
   - Start LocalStack if not running
   - Build and deploy the SAM application
   - Start the API in the background
   - Run a test prediction

## Testing the API

Once deployed, you can test the API using curl:

```bash
curl -X POST "http://127.0.0.1:3000/predict" \
  -H "Content-Type: application/json" \
  -d '{"features": [1.0, 2.0, 3.0, 4.0]}'
```

Expected response:
```json
{
  "prediction": 30.0,
  "features": [1.0, 2.0, 3.0, 4.0]
}
```

## How It Works

1. **Lambda Function (`ml_prediction.py`)**
   - Accepts POST requests with feature data
   - Performs a simple calculation (sum of features * 3.0) as a mock prediction
   - Returns prediction results in JSON format

2. **SAM Template (`template.yaml`)**
   - Defines the API Gateway and Lambda function
   - Configures the integration between them
   - Sets up environment variables and permissions

3. **LocalStack**
   - Provides local emulation of AWS services
   - Runs in Docker container
   - Exposes services on port 4566

## Development

### Making Changes

1. Edit the Lambda function in `ml-prediction-app/packages/functions/src/ml_prediction.py`
2. Modify the SAM template in `template.yaml` if needed
3. Run `./deploy.sh` to deploy your changes

### Stopping the Service

To stop the API, find its PID and kill it:
```bash
ps aux | grep "sam local start-api"
kill <PID>
```

## Troubleshooting

### Common Issues

1. **"sam: No such file or directory" error**
   - **Problem**: AWS SAM CLI is not installed
   - **Solution**: Install SAM CLI using `brew install aws-sam-cli` (macOS) or follow the [official guide](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html)
   - **Check**: Run `sam --version` to verify installation

2. **Docker-related errors**
   - **Problem**: Docker is not running or not installed
   - **Solution**: 
     - Start Docker Desktop application
     - Verify with `docker ps` - should not return an error
   - **Common error**: "Cannot connect to the Docker daemon"

3. **LocalStack Connection Issues**
   ```bash
   # Check LocalStack health
   curl http://localhost:4566/_localstack/health
   
   # If not running, start it manually
   docker-compose up -d
   ```

4. **API Issues**
   - Check `sam_api.log` for API Gateway and Lambda logs
   - Verify the API is running: `curl http://127.0.0.1:3000/predict`
   - Look for port conflicts (port 3000 already in use)

5. **Deployment Issues**
   - Run `sam validate` to check template syntax
   - Check SAM build output in `.aws-sam/build`
   - Ensure you have sufficient disk space for Docker images

## Environment Variables

The deployment script automatically sets these variables:
- `AWS_ACCESS_KEY_ID=test`
- `AWS_SECRET_ACCESS_KEY=test`
- `AWS_DEFAULT_REGION=us-east-1`
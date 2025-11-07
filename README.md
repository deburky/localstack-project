# ML Prediction Service with LocalStack and SAM

This project demonstrates how to set up a machine learning prediction service using LocalStack for local AWS service emulation and SAM (Serverless Application Model) for local development. The service exposes a REST API endpoint that accepts feature data and returns predictions using pre-trained scikit-learn models.

## Project Structure

```
localstack-project/
├── src/
│   ├── train.py              # Script to train and save ML models
│   ├── inference.py          # Lambda function for predictions
│   ├── Dockerfile            # Container definition for Lambda
│   ├── requirements.txt      # Python dependencies
│   ├── model.pkl             # Pre-trained outlier detection model (generated)
│   └── scaler.pkl            # Pre-trained feature scaler (generated)
├── tests/
│   └── test_s3_operations.py
├── .github/
│   └── workflows/
│       └── deploy-and-test.yml  # CI/CD pipeline
├── template.yaml             # SAM template for infrastructure
├── deploy.sh                 # Deployment script
├── Makefile                  # Convenient make commands
└── docker-compose.yml        # LocalStack configuration
```

## Prerequisites

Before running this project, ensure you have the following installed:

### Required

1. **Docker Desktop** (or Docker Engine + Docker Compose)
   - **Why**: Required for running LocalStack and building containerized Lambda functions
   - **Installation**: 
     - macOS: `brew install --cask docker` or download from [docker.com](https://www.docker.com/products/docker-desktop)
     - Linux: Follow [Docker Engine installation guide](https://docs.docker.com/engine/install/)
   - **Verify**: `docker --version` && `docker-compose --version`

2. **AWS SAM CLI** (Serverless Application Model)
   - **Why**: Used to build, test, and run the Lambda function locally
   - **Installation**:
     - macOS: `brew install aws-sam-cli`
     - Linux/Windows: Follow [AWS SAM CLI installation guide](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html)
   - **Verify**: `sam --version`

3. **Python 3.9+**
   - **Why**: Required for Lambda function runtime and training scripts
   - **Installation**:
     - macOS: `brew install python@3.9`
     - Linux: Use your package manager (e.g., `apt install python3.9`)
   - **Verify**: `python3 --version`

4. **Make** (optional but recommended)
   - **Why**: Simplifies running common commands
   - **Installation**: Usually pre-installed on macOS/Linux
   - **Verify**: `make --version`

### Quick Prerequisites Check

```bash
# Check all tools
docker --version && docker ps
sam --version
python3 --version
make --version
```

## Quick Start

### Using Makefile (Recommended)

```bash
# 1. Install dependencies
make install

# 2. Train ML models
make train-models

# 3. Start LocalStack and deploy
make start
```

### Manual Setup

```bash
# 1. Install dependencies
pip install -r requirements.txt

# 2. Train ML models
cd src && python train.py && cd ..

# 3. Deploy
./deploy.sh
```

## Available Make Commands

Run `make help` to see all available commands:

### Main Commands
- `make install` - Install Python dependencies
- `make train-models` - Train and save ML models
- `make start` - Start LocalStack and deploy the service
- `make stop` - Stop LocalStack and SAM API
- `make restart` - Restart LocalStack and redeploy
- `make build` - Build SAM application
- `make deploy` - Deploy to LocalStack
- `make test` - Run tests
- `make test-endpoint` - Quick test of the prediction endpoint
- `make clean` - Clean up everything (containers, images, logs)
- `make deep-clean` - Deep clean (removes ALL Docker images/containers)

### LocalStack Utilities
- `make localstack-status` - Check LocalStack health
- `make list-stacks` - List CloudFormation stacks
- `make list-lambdas` - List Lambda functions
- `make list-apis` - List API Gateway APIs

## LocalStack CLI Utilities

The project includes convenient commands for interacting with LocalStack services using `awslocal`.

### Using awslocal

`awslocal` is a wrapper for the AWS CLI that automatically configures the endpoint for LocalStack, making it simpler to interact with local AWS services.

**Installation:**
```bash
pip install awscli-local
```

**Why use awslocal?**

Instead of typing:
```bash
aws --endpoint-url=http://localhost:4566 lambda list-functions
```

You can simply use:
```bash
awslocal lambda list-functions
```

### Quick Examples

```bash
# Check LocalStack health
make localstack-status

# List all Lambda functions
make list-lambdas
# Or directly: awslocal lambda list-functions

# List CloudFormation stacks
make list-stacks
# Or directly: awslocal cloudformation list-stacks

# List API Gateway APIs
make list-apis
# Or directly: awslocal apigateway get-rest-apis

# S3 operations
awslocal s3 mb s3://my-bucket
awslocal s3 ls
awslocal s3 cp file.txt s3://my-bucket/

# Lambda operations
awslocal lambda invoke --function-name PredictFunction output.json
awslocal lambda get-function --function-name PredictFunction

# CloudFormation operations
awslocal cloudformation describe-stacks --stack-name sam-app
awslocal cloudformation list-stack-resources --stack-name sam-app
```

### Configuration

`awslocal` automatically uses these settings:
- **Endpoint**: `http://localhost:4566`
- **Region**: `us-east-1` (default)
- **Credentials**: `test/test` (dummy credentials for LocalStack)

You can override these with environment variables:
```bash
export AWS_ENDPOINT_URL=http://localhost:4566
export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
```

## ML Model Training

The service uses pre-trained ML models for better performance:

### Training Models

```bash
# Using Make
make train-models

# Or manually
cd src && python train.py
```

This generates:
- `model.pkl` - IsolationForest for anomaly detection
- `scaler.pkl` - StandardScaler for feature normalization

### Model Details

- **Outlier Detection**: IsolationForest with 10% contamination
- **Feature Scaling**: StandardScaler for normalization
- **Training Data**: 1000 samples with 4 features (synthetic data)

## Running the Service

Run the Make command:

```bash
make start
```

This will:
1. Start LocalStack (if not running)
2. Train ML models (if not already trained)
3. Build the SAM application with Docker
4. Start the API on `http://127.0.0.1:3000`
5. Run a test prediction

## Testing the API

### Quick Test

```bash
make test-endpoint
```

### Manual Test

After deploying the endpoint, make predictions by sending a payload request:

```bash
curl -X POST "http://127.0.0.1:3000/predict" \
  -H "Content-Type: application/json" \
  -d '{"features": [1.0, 2.0, 3.0, 4.0]}'
```

### Example Response

```json
{
  "prediction": {
    "base_prediction": -7.846485258771873,
    "confidence": 0.7292884072848042,
    "feature_importance": [
      0.099999999999,
      0.199999999998,
      0.299999999997,
      0.399999999996
    ],
    "is_anomaly": false,
    "stats": {
      "mean": 2.5,
      "std": 1.118033988749895,
      "min": 1.0,
      "max": 4.0
    }
  },
  "features": [1.0, 2.0, 3.0, 4.0],
  "features_scaled": [
    -1.3051872133935079,
    -0.9086410233196137,
    -0.6313678379293637,
    -0.2933980288662639
  ]
}
```

### Testing Anomaly Detection

Test with extreme values to trigger anomaly detection:

```bash
curl -X POST "http://127.0.0.1:3000/predict" \
  -H "Content-Type: application/json" \
  -d '{"features": [100.0, 200.0, 300.0, 400.0]}'
```

Response shows anomaly detected:

```json
{
  "prediction": {
    "base_prediction": 752.4973097028189,
    "confidence": 0.028924642251139054,
    "feature_importance": [0.1, 0.2, 0.3, 0.4],
    "is_anomaly": true,
    "stats": {
      "mean": 250.0,
      "std": 111.80339887498948,
      "min": 100.0,
      "max": 400.0
    }
  },
  "features": [100.0, 200.0, 300.0, 400.0],
  "features_scaled": [30.65, 58.46, 92.64, 119.24]
}
```

## How It Works

### 1. Model Training (`train.py`)
- Generates synthetic training data (1000 samples)
- Trains IsolationForest for anomaly detection
- Trains StandardScaler for feature normalization
- Saves models as `.pkl` files

### 2. Lambda Function (`inference.py`)
- Loads pre-trained models at startup (cold start optimization)
- Accepts POST requests with feature data
- Scales features using pre-trained scaler
- Detects anomalies using pre-trained model
- Calculates prediction statistics
- Returns comprehensive prediction results

### 3. SAM Template (`template.yaml`)
- Defines Lambda function as container image
- Configures API Gateway integration
- Sets up proper IAM permissions
- Manages deployment stages

### 4. LocalStack
- Provides local emulation of AWS services
- Runs in Docker container on port 4566
- Supports S3, Lambda, API Gateway, IAM, STS, CloudFormation

## Development

### Making Changes

1. **Update ML Models**
   ```bash
   # Retrain models with new data
   cd src && python train.py
   ```

2. **Update Lambda Function**
   ```bash
   # Edit src/inference.py
   # Then rebuild and redeploy
   make restart
   ```

3. **Update Infrastructure**
   ```bash
   # Edit template.yaml
   # Validate and deploy
   sam validate
   make deploy
   ```

### Stopping the Service

```bash
# Stop everything
make stop

# Or manually
docker-compose down
pkill -f "sam local start-api"
```

## CI/CD

The project includes a GitHub Actions workflow (`.github/workflows/deploy-and-test.yml`) that:

- ✅ Validates SAM template
- ✅ Builds the application
- ✅ Runs Python tests
- ✅ Checks code quality with flake8

## Troubleshooting

### Common Issues

1. **Models Not Loading**
   ```bash
   # Problem: Models not found in Lambda
   # Solution: Train models before building
   make train-models
   make build
   ```

2. **Docker Issues**
   ```bash
   # Check Docker is running
   docker ps
   
   # Restart Docker if needed
   make clean
   make start
   ```

3. **LocalStack Connection Issues**
   ```bash
   # Check LocalStack health
   curl http://localhost:4566/_localstack/health
   
   # Restart LocalStack
   docker-compose restart
   ```

4. **Port Already in Use**
   ```bash
   # Find process using port 3000
   lsof -i :3000
   
   # Kill the process
   kill -9 <PID>
   ```

5. **SAM Build Failures**
   ```bash
   # Clean and rebuild
   make clean
   make build
   ```

## Environment Variables

The deployment automatically sets:
- `AWS_ACCESS_KEY_ID=test`
- `AWS_SECRET_ACCESS_KEY=test`
- `AWS_DEFAULT_REGION=us-east-1`
- `AWS_ENDPOINT_URL=http://localhost:4566`

## Key Features

### Performance Optimizations
- ✅ **Pre-trained Models**: Models are trained once and loaded at Lambda startup for fast inference
- ✅ **Cold Start Optimization**: Models loaded during initialization, not per request
- ✅ **Efficient Scaling**: StandardScaler pre-fitted on training data

### ML Capabilities
- ✅ **Anomaly Detection**: IsolationForest detects outliers in real-time
- ✅ **Feature Scaling**: StandardScaler normalizes inputs for consistent predictions
- ✅ **Comprehensive Metrics**: Returns confidence scores, feature importance, and statistics
- ✅ **Robust Error Handling**: Validates input and handles edge cases gracefully

### Development & Deployment
- ✅ **Container-based Lambda**: Docker images for consistent environments
- ✅ **Local Development**: SAM and LocalStack for testing without AWS
- ✅ **CI/CD Pipeline**: GitHub Actions with automated testing
- ✅ **Simple Commands**: Makefile for easy deployment and management
- ✅ **Automated Training**: Models trained automatically during deployment

### Production Ready
- ✅ **Comprehensive Testing**: Unit tests and integration tests
- ✅ **Code Quality**: Flake8 linting and validation
- ✅ **Detailed Logging**: Debug and error tracking
- ✅ **Documentation**: Complete README with examples

## Conclusion

This project demonstrates how to:

- **Build ML services with AWS Lambda** using containerized deployments
- **Use LocalStack for local development** to avoid AWS costs during development
- **Implement scikit-learn in serverless functions** with pre-trained models
- **Automate deployment and testing** with Makefile and GitHub Actions
- **Create production-ready ML endpoints** with anomaly detection and comprehensive metrics
- **Optimize for performance** by loading models once at startup
- **Implement CI/CD** with automated testing using `act` before pushing to GitHub

## License

MIT

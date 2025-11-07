#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Error handling
set -euo pipefail
trap 'echo -e "${RED}❌ Error on line $LINENO${NC}"' ERR

# Debug mode if needed
if [[ "${DEBUG:-}" == "true" ]]; then
    set -x
fi

echo "🚀 Starting ML Prediction Stack test..."

# Check if LocalStack is running
echo "Checking LocalStack status..."
HEALTH_CHECK=$(curl -s http://localhost:4566/_localstack/health)
if ! echo "$HEALTH_CHECK" | grep -q "\"running\""; then
    echo -e "${RED}❌ LocalStack is not running. Please start it first:${NC}"
    echo "cd localstack-project && docker-compose up -d"
    exit 1
fi

# Set AWS credentials for LocalStack
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1

# Check Node.js and pnpm versions
echo -e "${YELLOW}ℹ️ Environment information:${NC}"
node --version
pnpm --version

# Install dependencies
echo "📦 Installing dependencies..."
cd ml-prediction-app
pnpm install

# Build the project
echo "🔨 Building the project..."
pnpm run build

# Deploy with debug output
echo "🚀 Deploying the stack..."
DEBUG=sst:* AWS_PROFILE=default pnpm run deploy

# Wait for deployment and check status
echo "⏳ Waiting for deployment to complete..."
for i in {1..30}; do
    echo -n "."
    if aws --endpoint-url=http://localhost:4566 --region us-east-1 \
        cloudformation describe-stacks --stack-name ml-prediction-app-test 2>/dev/null; then
        echo -e "\n${GREEN}✅ Stack deployed successfully${NC}"
        break
    fi
    sleep 2
done

# Get API ID
echo "🔍 Getting API endpoint..."
API_ID=$(aws --endpoint-url=http://localhost:4566 --region us-east-1 \
  apigateway get-rest-apis --query 'items[?name==`ml-prediction-app`].id' \
  --output text)

if [ -z "$API_ID" ]; then
    echo -e "${RED}❌ Could not find API ID. Deployment might have failed.${NC}"
    exit 1
fi

# Test the endpoint
echo "🧪 Testing prediction endpoint..."
RESPONSE=$(curl -s -X POST \
  "http://localhost:4566/restapis/$API_ID/test/_user_request_/predict" \
  -H "Content-Type: application/json" \
  -d '{"features": [1.0, 2.0, 3.0, 4.0]}')

# Verify response
echo "Response: $RESPONSE"
if echo "$RESPONSE" | grep -q "\"prediction\":30"; then
    echo -e "${GREEN}✅ Test passed! Prediction endpoint is working correctly.${NC}"
else
    echo -e "${RED}❌ Test failed! Unexpected response.${NC}"
    exit 1
fi

# Cleanup (optional)
read -p "Do you want to remove the stack? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🧹 Cleaning up..."
    pnpm run remove
fi

echo -e "${GREEN}✨ All done!${NC}"
#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🚀 Starting ML Prediction Service deployment...${NC}"

# Check if LocalStack is running
echo -e "\n${YELLOW}1. Checking LocalStack status...${NC}"
HEALTH_CHECK=$(curl -s http://localhost:4566/_localstack/health)
if ! echo "$HEALTH_CHECK" | grep -q "\"running\""; then
    echo -e "${RED}❌ LocalStack is not running. Starting it...${NC}"
    docker-compose up -d
    sleep 5
else
    echo -e "${GREEN}✅ LocalStack is running${NC}"
fi

# Set AWS credentials for LocalStack
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1

# Deploy with SAM
echo -e "\n${YELLOW}2. Building and deploying with SAM...${NC}"
export PIP_NO_CACHE_DIR=false
export PIP_USE_PEP517=false
# Use UV for pip installation if available
if command -v uv >/dev/null 2>&1; then
    echo -e "${GREEN}Using uv for dependency installation${NC}"
    export PIP_COMMAND="uv pip"
fi
sam build --use-container --use-container

# Start the API in background, redirecting output to a log file
echo -e "\n${YELLOW}3. Starting SAM API...${NC}"
nohup sam local start-api --warm-containers EAGER > sam_api.log 2>&1 &
SAM_PID=$!

# Wait for API to be ready
echo -e "\n${YELLOW}4. Waiting for API to start...${NC}"

# Function to check if process is still running
check_process() {
    if ! kill -0 $SAM_PID 2>/dev/null; then
        echo -e "${RED}❌ SAM API process failed to start. Check sam_api.log for details${NC}"
        exit 1
    fi
}

# Wait for API to become available (timeout after 30 seconds)
for i in {1..30}; do
    check_process
    if curl -s "http://127.0.0.1:3000/predict" -o /dev/null; then
        echo -e "\n${GREEN}✅ API is ready${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "\n${RED}❌ API failed to start within timeout. Check sam_api.log for details${NC}"
        kill $SAM_PID 2>/dev/null
        exit 1
    fi
    echo -n "."
    sleep 1
done

# Store the endpoint
ENDPOINT="http://127.0.0.1:3000/predict"

# Function to cleanup on exit
cleanup() {
    echo -e "\n${YELLOW}Cleaning up...${NC}"
    kill $SAM_PID 2>/dev/null
    exit 0
}

# Set up trap for cleanup
trap cleanup SIGINT SIGTERM

# Test the endpoint
echo -e "\n${YELLOW}5. Making a test prediction...${NC}"
curl -X POST "$ENDPOINT" \
  -H "Content-Type: application/json" \
  -d '{"features": [1.0, 2.0, 3.0, 4.0]}'

echo -e "\n\n${GREEN}✅ Deployment and test complete!${NC}"

# Find the actual running SAM API process
ACTUAL_PID=$(ps aux | grep '[s]am local start-api' | awk '{print $2}')

if [ -n "$ACTUAL_PID" ]; then
    echo -e "${GREEN}🚀 API is running in the background (PID: $ACTUAL_PID)${NC}"
    echo -e "\n${YELLOW}To make predictions, use:${NC}"
    echo "curl -X POST \"$ENDPOINT\" \\"
    echo "  -H \"Content-Type: application/json\" \\"
    echo "  -d '{\"features\": [1.0, 2.0, 3.0, 4.0]}'"
    echo -e "\n${YELLOW}To stop the API, run:${NC}"
    echo "kill $ACTUAL_PID"
else
    echo -e "${RED}⚠️  Could not find running API process${NC}"
fi
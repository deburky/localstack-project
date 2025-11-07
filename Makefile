.PHONY: help start stop restart build deploy test clean train-models install

# Default target
help:
	@echo "🚀 LocalStack ML Prediction Service - Available Commands:"
	@echo ""
	@echo "  make install        - Install Python dependencies"
	@echo "  make train-models   - Train and save ML models"
	@echo "  make start          - Start LocalStack and deploy the service"
	@echo "  make stop           - Stop LocalStack and SAM API"
	@echo "  make restart        - Restart LocalStack and redeploy"
	@echo "  make build          - Build SAM application"
	@echo "  make deploy         - Deploy to LocalStack (requires LocalStack running)"
	@echo "  make test           - Run tests"
	@echo "  make test-endpoint  - Quick test of the prediction endpoint"
	@echo "  make clean          - Clean up everything (containers, images, logs)"
	@echo "  make deep-clean     - Deep clean (removes ALL Docker images/containers)"
	@echo ""

# Install dependencies
install:
	@echo "📦 Installing dependencies..."
	pip install -r requirements.txt
	@echo "✅ Dependencies installed!"

# Train ML models
train-models:
	@echo "🎓 Training ML models..."
	cd src && python train.py
	@echo "✅ Models trained and saved!"

# Start LocalStack and deploy
start:
	@echo "🚀 Starting LocalStack and deploying service..."
	docker-compose up -d
	@sleep 5
	bash deploy.sh

# Stop LocalStack and SAM API
stop:
	@echo "🛑 Stopping services..."
	@pkill -f "sam local start-api" || true
	@docker-compose down
	@echo "✅ Services stopped!"

# Restart everything
restart: stop start

# Build SAM application
build:
	@echo "🔨 Building SAM application..."
	sam build --use-container
	@echo "✅ Build complete!"

# Deploy to LocalStack (assumes LocalStack is running)
deploy:
	@echo "🚀 Deploying to LocalStack..."
	bash deploy.sh

# Run tests
test:
	@echo "🧪 Running tests..."
	pytest tests/ -v
	@echo "✅ Tests complete!"

# Clean up everything
clean:
	@echo "🧹 Cleaning up..."
	@pkill -f "sam local start-api" || true
	@docker-compose down -v
	@docker stop $$(docker ps -aq) 2>/dev/null || true
	@docker rm $$(docker ps -aq) 2>/dev/null || true
	@docker rmi $$(docker images -q predictfunction) 2>/dev/null || true
	@rm -rf .aws-sam
	@rm -f sam_api.log
	@find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.pyc" -delete 2>/dev/null || true
	@echo "✅ Cleanup complete!"

# Deep clean (removes all Docker images and containers)
deep-clean: clean
	@echo "🧹 Deep cleaning Docker..."
	@docker system prune -af --volumes
	@echo "✅ Deep clean complete!"

# Quick test endpoint (assumes service is running)
test-endpoint:
	@echo "🧪 Testing prediction endpoint..."
	@curl -X POST "http://127.0.0.1:3000/predict" \
		-H "Content-Type: application/json" \
		-d '{"features": [1.0, 2.0, 3.0, 4.0]}' | jq .


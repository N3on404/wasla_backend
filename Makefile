.PHONY: build run test clean docker-up docker-down

# Build all services
build:
	@echo "Building all services..."
	go build -o bin/auth-service ./cmd/auth-service
	go build -o bin/queue-service ./cmd/queue-service
	go build -o bin/booking-service ./cmd/booking-service
	go build -o bin/websocket-hub ./cmd/websocket-hub
	go build -o bin/printer-service ./cmd/printer-service
	@echo "Build complete!"

# Run auth service locally
run-auth:
	@echo "Starting auth service..."
	go run ./cmd/auth-service

# Run printer service locally
run-printer:
	@echo "Starting printer service..."
	go run ./cmd/printer-service

# Run all services
run-all:
	@echo "Starting all services..."
	go run ./cmd/auth-service &
	go run ./cmd/queue-service &
	go run ./cmd/booking-service &
	go run ./cmd/websocket-hub &
	go run ./cmd/printer-service &
	wait

# Test all packages
test:
	@echo "Running tests..."
	go test ./...

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -rf bin/
	go clean

# Start Docker services
docker-up:
	@echo "Starting Docker services..."
	docker-compose up -d postgres redis

# Stop Docker services
docker-down:
	@echo "Stopping Docker services..."
	docker-compose down

# Build and run auth service with Docker
docker-auth:
	@echo "Building and running auth service with Docker..."
	docker-compose up --build auth-service

# Run database migrations
migrate:
	@echo "Running database migrations..."
	# Add migration commands here when you have them

# Install dependencies
deps:
	@echo "Installing dependencies..."
	go mod download
	go mod tidy

# Format code
fmt:
	@echo "Formatting code..."
	go fmt ./...

# Lint code
lint:
	@echo "Linting code..."
	golangci-lint run

# Help
help:
	@echo "Available commands:"
	@echo "  build        - Build all services"
	@echo "  run-auth     - Run auth service locally"
	@echo "  run-printer  - Run printer service locally"
	@echo "  run-all      - Run all services locally"
	@echo "  test         - Run tests"
	@echo "  clean        - Clean build artifacts"
	@echo "  docker-up    - Start Docker services (postgres, redis)"
	@echo "  docker-down  - Stop Docker services"
	@echo "  docker-auth  - Build and run auth service with Docker"
	@echo "  migrate      - Run database migrations"
	@echo "  deps         - Install dependencies"
	@echo "  fmt          - Format code"
	@echo "  lint         - Lint code"
	@echo "  help         - Show this help"

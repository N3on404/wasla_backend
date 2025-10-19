package main

import (
	"log"
	"os"

	"station-backend/internal/websocket"
	"station-backend/pkg/middleware"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

func main() {
	// Load environment variables
	if err := godotenv.Load("configs/environment.env"); err != nil {
		log.Printf("Warning: Could not load .env file: %v", err)
	}

	// Initialize WebSocket hub
	hub := websocket.NewHub()
	go hub.Run()

	// Initialize handler
	wsHandler := websocket.NewHandler(hub)

	// Setup Gin router
	// Set Gin mode based on environment
	if os.Getenv("ENVIRONMENT") == "production" {
		gin.SetMode(gin.ReleaseMode)
	}
	r := gin.Default()

	// Middleware
	r.Use(middleware.CORS())
	r.Use(middleware.Logger())

	// Health check endpoint
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status":  "healthy",
			"service": "websocket-hub",
			"clients": hub.GetConnectedClients(),
		})
	})

	// WebSocket endpoint (requires authentication)
	r.GET("/ws/queue/:stationId", middleware.AuthRequired(), wsHandler.WebSocketHandler)

	// Admin endpoints (for testing and management)
	admin := r.Group("/admin")
	admin.Use(middleware.AuthRequired())
	{
		admin.POST("/broadcast", wsHandler.BroadcastMessage)
		admin.GET("/stats", wsHandler.GetConnectionStats)
		admin.POST("/test/:stationId", wsHandler.TestConnection)
	}

	// Get port from environment or use default
	port := os.Getenv("WEBSOCKET_HUB_PORT")
	if port == "" {
		port = "8004"
	}

	log.Printf("WebSocket Hub starting on port %s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}

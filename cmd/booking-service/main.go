package main

import (
	"log"
	"os"

	"station-backend/internal/booking"
	"station-backend/internal/database"
	"station-backend/internal/statistics"
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
	db, err := database.NewPostgres()
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()

	wsHub := websocket.NewHub()
	go wsHub.Run()

	// Initialize statistics logger
	statsLogger := statistics.NewStatisticsLogger(db.Pool)

	repo := booking.NewRepository(db.Pool)
	service := booking.NewService(repo, wsHub, statsLogger)
	h := booking.NewHandler(service)

	r := gin.Default()
	r.Use(middleware.CORS())
	r.Use(middleware.Logger())
	r.GET("/health", func(c *gin.Context) { c.String(200, "ok") })

	// Minimal OpenAPI + Swagger UI
	booking.RegisterDocsRoutes(r)

	api := r.Group("/api/v1")
	{
		api.POST("/bookings", middleware.AuthRequired(), h.Create)
		api.POST("/bookings/by-queue-entry", middleware.AuthRequired(), h.CreateByQueueEntry)
		api.POST("/bookings/cancel-one-by-queue-entry", middleware.AuthRequired(), h.CancelOneByQueueEntry)
		api.PUT("/bookings/:id/cancel", middleware.AuthRequired(), h.Cancel)
		api.GET("/trips", middleware.AuthRequired(), h.ListTrips)
		api.GET("/trips/today", middleware.AuthRequired(), h.ListTodayTrips)
		api.GET("/trips/today/count", middleware.AuthRequired(), h.GetTodayTripsCount)
	}

	port := os.Getenv("BOOKING_SERVICE_PORT")
	if port == "" {
		port = "8003"
	}
	log.Printf("Booking service starting on port %s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal("server error:", err)
	}
}

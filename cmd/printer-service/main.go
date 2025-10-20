package main

import (
	"log"
	"os"

	"station-backend/internal/database"
	"station-backend/internal/printer"
	"station-backend/internal/queue"
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

	// Initialize Redis for printer service
	redis, err := database.NewRedis()
	if err != nil {
		log.Fatal("Failed to connect to Redis:", err)
	}
	defer redis.Close()

	// Initialize PostgreSQL for queue service
	db, err := database.NewPostgres()
	if err != nil {
		log.Fatal("DB error:", err)
	}
	defer db.Close()

	// Initialize repository
	printerRepo := printer.NewRepository(redis.Client)

	// Initialize queue repository and service
	queueRepo := queue.NewRepository(db.Pool)
	wsHub := websocket.NewHub()
	statsLogger := statistics.NewStatisticsLogger(db.Pool)
	queueService := queue.NewService(queueRepo, wsHub, statsLogger)

	// Initialize service
	printerService := printer.NewService(printerRepo)

	// Initialize handler
	printerHandler := printer.NewHandler(printerService, queueService)

	// Setup Gin router
	// Set Gin mode based on environment
	if os.Getenv("ENVIRONMENT") == "production" {
		gin.SetMode(gin.ReleaseMode)
	}
	r := gin.Default()

	// Middleware
	r.Use(middleware.CORS())
	r.Use(middleware.Logger())

	// Printer routes
	printerGroup := r.Group("/api/printer")
	{
		// Configuration routes
		printerGroup.GET("/config/:id", printerHandler.GetPrinterConfig)
		printerGroup.PUT("/config/:id", printerHandler.UpdatePrinterConfig)
		printerGroup.POST("/test/:id", printerHandler.TestPrinterConnection)

		// Queue routes
		printerGroup.GET("/queue", printerHandler.GetPrintQueue)
		printerGroup.GET("/queue/status", printerHandler.GetPrintQueueStatus)
		printerGroup.POST("/queue/add", printerHandler.AddPrintJob)

		// Print routes
		printerGroup.POST("/:id/print/booking", printerHandler.PrintBookingTicket)
		printerGroup.POST("/:id/print/entry", printerHandler.PrintEntryTicket)
		printerGroup.POST("/:id/print/exit", printerHandler.PrintExitTicket)
		printerGroup.POST("/:id/print/daypass", printerHandler.PrintDayPassTicket)
		printerGroup.POST("/:id/print/exitpass", printerHandler.PrintExitPassTicket)
		printerGroup.POST("/:id/print/exitpass-and-remove", printerHandler.PrintExitPassAndRemoveFromQueue)
		printerGroup.POST("/:id/print/talon", printerHandler.PrintTalon)

		// Alternate patterns to avoid any param matching issues
		printerGroup.POST("/print/:id/booking", printerHandler.PrintBookingTicket)
		printerGroup.POST("/print/:id/entry", printerHandler.PrintEntryTicket)
		printerGroup.POST("/print/:id/exit", printerHandler.PrintExitTicket)
		printerGroup.POST("/print/:id/daypass", printerHandler.PrintDayPassTicket)
		printerGroup.POST("/print/:id/exitpass", printerHandler.PrintExitPassTicket)
		printerGroup.POST("/print/:id/exitpass-and-remove", printerHandler.PrintExitPassAndRemoveFromQueue)
		printerGroup.POST("/print/:id/talon", printerHandler.PrintTalon)
	}

	// Health check
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok", "service": "printer-service"})
	})

	// Get port from environment or use default
	port := os.Getenv("PRINTER_SERVICE_PORT")
	if port == "" {
		port = "8084"
	}

	log.Printf("Printer service starting on port %s", port)
	log.Fatal(r.Run(":" + port))
}

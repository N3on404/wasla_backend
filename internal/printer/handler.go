package printer

import (
	"context"
	"net/http"
	"time"

	"station-backend/internal/queue"

	"github.com/gin-gonic/gin"
)

// Handler handles HTTP requests for printer operations
type Handler struct {
	service      *Service
	queueService *queue.Service
}

// NewHandler creates a new printer handler
func NewHandler(service *Service, queueService *queue.Service) *Handler {
	return &Handler{
		service:      service,
		queueService: queueService,
	}
}

// GetPrinterConfig godoc
// @Summary Get printer configuration
// @Description Get the configuration for a specific printer
// @Tags printer
// @Accept json
// @Produce json
// @Param id path string true "Printer ID"
// @Success 200 {object} PrinterConfig
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /printer/config/{id} [get]
func (h *Handler) GetPrinterConfig(c *gin.Context) {
	printerID := c.Param("id")
	if printerID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "printer ID is required"})
		return
	}

	config, err := h.service.GetPrinterConfig(printerID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, config)
}

// UpdatePrinterConfig godoc
// @Summary Update printer configuration
// @Description Update the configuration for a specific printer
// @Tags printer
// @Accept json
// @Produce json
// @Param id path string true "Printer ID"
// @Param config body PrinterConfig true "Printer configuration"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /printer/config/{id} [put]
func (h *Handler) UpdatePrinterConfig(c *gin.Context) {
	printerID := c.Param("id")
	if printerID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "printer ID is required"})
		return
	}

	var config PrinterConfig
	if err := c.ShouldBindJSON(&config); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	config.ID = printerID

	err := h.service.UpdatePrinterConfig(&config)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "printer configuration updated successfully"})
}

// TestPrinterConnection godoc
// @Summary Test printer connection
// @Description Test the connection to a specific printer
// @Tags printer
// @Accept json
// @Produce json
// @Param id path string true "Printer ID"
// @Success 200 {object} PrinterStatus
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /printer/test/{id} [post]
func (h *Handler) TestPrinterConnection(c *gin.Context) {
	printerID := c.Param("id")
	if printerID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "printer ID is required"})
		return
	}

	err := h.service.TestPrinterConnection(printerID)
	status := &PrinterStatus{
		Connected: err == nil,
		Error:     "",
	}

	if err != nil {
		status.Error = err.Error()
		c.JSON(http.StatusOK, status)
		return
	}

	c.JSON(http.StatusOK, status)
}

// GetPrintQueue godoc
// @Summary Get print queue
// @Description Get the current print queue
// @Tags printer
// @Accept json
// @Produce json
// @Success 200 {array} QueuedPrintJob
// @Failure 500 {object} map[string]string
// @Router /printer/queue [get]
func (h *Handler) GetPrintQueue(c *gin.Context) {
	queue, err := h.service.GetPrintQueue()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, queue)
}

// GetPrintQueueStatus godoc
// @Summary Get print queue status
// @Description Get the current status of the print queue
// @Tags printer
// @Accept json
// @Produce json
// @Success 200 {object} PrintQueueStatus
// @Failure 500 {object} map[string]string
// @Router /printer/queue/status [get]
func (h *Handler) GetPrintQueueStatus(c *gin.Context) {
	status, err := h.service.GetPrintQueueStatus()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, status)
}

// PrintBookingTicket godoc
// @Summary Print booking ticket
// @Description Print a booking ticket using printer config from request
// @Tags printer
// @Accept json
// @Produce json
// @Param ticket body TicketData true "Ticket data with printer config"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /printer/print/booking [post]
func (h *Handler) PrintBookingTicket(c *gin.Context) {
	var ticketData TicketData
	if err := c.ShouldBindJSON(&ticketData); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	err := h.service.PrintBookingTicket(&ticketData)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "booking ticket printed successfully"})
}

// PrintEntryTicket godoc
// @Summary Print entry ticket
// @Description Print an entry ticket using printer config from request
// @Tags printer
// @Accept json
// @Produce json
// @Param ticket body TicketData true "Ticket data with printer config"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /printer/print/entry [post]
func (h *Handler) PrintEntryTicket(c *gin.Context) {
	var ticketData TicketData
	if err := c.ShouldBindJSON(&ticketData); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	err := h.service.PrintEntryTicket(&ticketData)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "entry ticket printed successfully"})
}

// PrintExitTicket godoc
// @Summary Print exit ticket
// @Description Print an exit ticket using printer config from request
// @Tags printer
// @Accept json
// @Produce json
// @Param ticket body TicketData true "Ticket data with printer config"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /printer/print/exit [post]
func (h *Handler) PrintExitTicket(c *gin.Context) {
	var ticketData TicketData
	if err := c.ShouldBindJSON(&ticketData); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	err := h.service.PrintExitTicket(&ticketData)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "exit ticket printed successfully"})
}

// PrintDayPassTicket godoc
// @Summary Print day pass ticket
// @Description Print a day pass ticket using printer config from request
// @Tags printer
// @Accept json
// @Produce json
// @Param ticket body TicketData true "Ticket data with printer config"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /printer/print/daypass [post]
func (h *Handler) PrintDayPassTicket(c *gin.Context) {
	var ticketData TicketData
	if err := c.ShouldBindJSON(&ticketData); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	err := h.service.PrintDayPassTicket(&ticketData)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "day pass ticket printed successfully"})
}

// PrintExitPassTicket godoc
// @Summary Print exit pass ticket
// @Description Print an exit pass ticket using printer config from request
// @Tags printer
// @Accept json
// @Produce json
// @Param ticket body TicketData true "Ticket data with printer config"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /printer/print/exitpass [post]
func (h *Handler) PrintExitPassTicket(c *gin.Context) {
	var ticketData TicketData
	if err := c.ShouldBindJSON(&ticketData); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	err := h.service.PrintExitPassTicket(&ticketData)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "exit pass ticket printed successfully"})
}

// PrintExitPassAndRemoveFromQueue godoc
// @Summary Print exit pass ticket and remove vehicle from queue
// @Description Print an exit pass ticket with booked seats calculation and remove the vehicle from queue
// @Tags printer
// @Accept json
// @Produce json
// @Param request body ExitPassAndRemoveRequest true "Exit pass and remove request with printer config"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /printer/print/exitpass-and-remove [post]
func (h *Handler) PrintExitPassAndRemoveFromQueue(c *gin.Context) {
	var request ExitPassAndRemoveRequest
	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var totalAmount float64
	var seatNumber int

	// Check if vehicle has bookings or is empty
	if request.BookedSeats > 0 {
		// Vehicle has bookings: calculate total amount as booked seats × base price
		totalAmount = float64(request.BookedSeats) * request.BasePrice
		seatNumber = request.BookedSeats
	} else {
		// Vehicle is empty: calculate total amount as service fees × vehicle capacity
		serviceFeePerSeat := 0.15 // Service fee per seat
		totalAmount = serviceFeePerSeat * float64(request.TotalSeats)
		seatNumber = request.TotalSeats // Use total seats for empty vehicle
	}

	// Create ticket data for printing
	ticketData := &TicketData{
		LicensePlate:    request.LicensePlate,
		DestinationName: request.DestinationName,
		SeatNumber:      seatNumber,
		TotalAmount:     totalAmount,
		CreatedBy:       request.CreatedBy,
		CreatedAt:       time.Now(),
		StationName:     request.StationName,
		RouteName:       request.RouteName,
		VehicleCapacity: request.TotalSeats,
		BasePrice:       request.BasePrice,
		ExitPassCount:   request.ExitPassCount,
		CompanyName:     request.CompanyName,
		CompanyLogo:     request.CompanyLogo,
		StaffFirstName:  request.StaffFirstName,
		StaffLastName:   request.StaffLastName,
		PrinterConfig:   request.PrinterConfig,
	}

	// Print the exit pass ticket
	err := h.service.PrintExitPassTicket(ticketData)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to print exit pass ticket: " + err.Error()})
		return
	}

	// Create a trip record before removing from queue
	if request.QueueEntryID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "queueEntryId is required"})
		return
	}

	// Create trip record with appropriate seat count
	tripSeatsBooked := request.BookedSeats
	if request.BookedSeats == 0 {
		// For empty vehicles, record the vehicle capacity as "seats booked" for trip tracking
		tripSeatsBooked = request.TotalSeats
	}

	if _, tripErr := h.queueService.CreateTripFromExit(context.Background(), request.QueueEntryID, request.LicensePlate, request.DestinationName, tripSeatsBooked, request.TotalSeats, request.BasePrice); tripErr != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create trip record: " + tripErr.Error()})
		return
	}

	// Remove vehicle from queue
	err = h.queueService.DeleteQueueEntry(context.Background(), request.QueueEntryID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to remove vehicle from queue: " + err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message":     "exit pass ticket printed and vehicle removed from queue successfully",
		"totalAmount": totalAmount,
		"bookedSeats": request.BookedSeats,
		"basePrice":   request.BasePrice,
		"isEmpty":     request.BookedSeats == 0,
	})
}

// PrintTalon godoc
// @Summary Print talon
// @Description Print a talon using printer config from request
// @Tags printer
// @Accept json
// @Produce json
// @Param ticket body TicketData true "Ticket data with printer config"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /printer/print/talon [post]
func (h *Handler) PrintTalon(c *gin.Context) {
	var ticketData TicketData
	if err := c.ShouldBindJSON(&ticketData); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	err := h.service.PrintTalon(&ticketData)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "talon printed successfully"})
}

// AddPrintJob godoc
// @Summary Add print job to queue
// @Description Add a print job to the print queue
// @Tags printer
// @Accept json
// @Produce json
// @Param job body map[string]interface{} true "Print job data"
// @Success 200 {object} QueuedPrintJob
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /printer/queue/add [post]
func (h *Handler) AddPrintJob(c *gin.Context) {
	var request struct {
		JobType   string `json:"jobType" binding:"required"`
		Content   string `json:"content" binding:"required"`
		StaffName string `json:"staffName"`
		Priority  int    `json:"priority"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	jobType := PrintJobType(request.JobType)
	priority := request.Priority
	if priority == 0 {
		priority = 100 // Default priority
	}

	job, err := h.service.AddPrintJob(jobType, request.Content, request.StaffName, priority)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, job)
}

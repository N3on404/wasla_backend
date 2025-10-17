package printer

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// Handler handles HTTP requests for printer operations
type Handler struct {
	service *Service
}

// NewHandler creates a new printer handler
func NewHandler(service *Service) *Handler {
	return &Handler{
		service: service,
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
// @Description Print a booking ticket
// @Tags printer
// @Accept json
// @Produce json
// @Param id path string true "Printer ID"
// @Param ticket body TicketData true "Ticket data"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /printer/{id}/print/booking [post]
func (h *Handler) PrintBookingTicket(c *gin.Context) {
	printerID := c.Param("id")
	if printerID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "printer ID is required"})
		return
	}

	var ticketData TicketData
	if err := c.ShouldBindJSON(&ticketData); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	err := h.service.PrintBookingTicket(printerID, &ticketData)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "booking ticket printed successfully"})
}

// PrintEntryTicket godoc
// @Summary Print entry ticket
// @Description Print an entry ticket
// @Tags printer
// @Accept json
// @Produce json
// @Param id path string true "Printer ID"
// @Param ticket body TicketData true "Ticket data"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /printer/{id}/print/entry [post]
func (h *Handler) PrintEntryTicket(c *gin.Context) {
	printerID := c.Param("id")
	if printerID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "printer ID is required"})
		return
	}

	var ticketData TicketData
	if err := c.ShouldBindJSON(&ticketData); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	err := h.service.PrintEntryTicket(printerID, &ticketData)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "entry ticket printed successfully"})
}

// PrintExitTicket godoc
// @Summary Print exit ticket
// @Description Print an exit ticket
// @Tags printer
// @Accept json
// @Produce json
// @Param id path string true "Printer ID"
// @Param ticket body TicketData true "Ticket data"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /printer/{id}/print/exit [post]
func (h *Handler) PrintExitTicket(c *gin.Context) {
	printerID := c.Param("id")
	if printerID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "printer ID is required"})
		return
	}

	var ticketData TicketData
	if err := c.ShouldBindJSON(&ticketData); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	err := h.service.PrintExitTicket(printerID, &ticketData)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "exit ticket printed successfully"})
}

// PrintDayPassTicket godoc
// @Summary Print day pass ticket
// @Description Print a day pass ticket
// @Tags printer
// @Accept json
// @Produce json
// @Param id path string true "Printer ID"
// @Param ticket body TicketData true "Ticket data"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /printer/{id}/print/daypass [post]
func (h *Handler) PrintDayPassTicket(c *gin.Context) {
	printerID := c.Param("id")
	if printerID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "printer ID is required"})
		return
	}

	var ticketData TicketData
	if err := c.ShouldBindJSON(&ticketData); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	err := h.service.PrintDayPassTicket(printerID, &ticketData)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "day pass ticket printed successfully"})
}

// PrintExitPassTicket godoc
// @Summary Print exit pass ticket
// @Description Print an exit pass ticket
// @Tags printer
// @Accept json
// @Produce json
// @Param id path string true "Printer ID"
// @Param ticket body TicketData true "Ticket data"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /printer/{id}/print/exitpass [post]
func (h *Handler) PrintExitPassTicket(c *gin.Context) {
	printerID := c.Param("id")
	if printerID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "printer ID is required"})
		return
	}

	var ticketData TicketData
	if err := c.ShouldBindJSON(&ticketData); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	err := h.service.PrintExitPassTicket(printerID, &ticketData)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "exit pass ticket printed successfully"})
}

// PrintTalon godoc
// @Summary Print talon
// @Description Print a talon
// @Tags printer
// @Accept json
// @Produce json
// @Param id path string true "Printer ID"
// @Param ticket body TicketData true "Ticket data"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /printer/{id}/print/talon [post]
func (h *Handler) PrintTalon(c *gin.Context) {
	printerID := c.Param("id")
	if printerID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "printer ID is required"})
		return
	}

	var ticketData TicketData
	if err := c.ShouldBindJSON(&ticketData); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	err := h.service.PrintTalon(printerID, &ticketData)
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

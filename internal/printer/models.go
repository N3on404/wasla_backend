package printer

import (
	"time"
)

// PrinterConfig represents the configuration for a thermal printer
type PrinterConfig struct {
	ID        string `json:"id"`
	Name      string `json:"name"`
	IP        string `json:"ip"`
	Port      int    `json:"port"`
	Width     int    `json:"width"`
	Timeout   int    `json:"timeout"`
	Model     string `json:"model"`
	Enabled   bool   `json:"enabled"`
	IsDefault bool   `json:"isDefault"`
}

// PrintJob represents a print job to be sent to the printer
type PrintJob struct {
	Content        string `json:"content"`
	Align          string `json:"align,omitempty"` // "left", "center", "right"
	Bold           bool   `json:"bold,omitempty"`
	Underline      bool   `json:"underline,omitempty"`
	Size           string `json:"size,omitempty"` // "normal", "double_height", "double_width", "quad"
	Cut            bool   `json:"cut,omitempty"`
	OpenCashDrawer bool   `json:"openCashDrawer,omitempty"`
}

// PrinterStatus represents the current status of a printer
type PrinterStatus struct {
	Connected bool   `json:"connected"`
	Error     string `json:"error,omitempty"`
}

// PrintJobType represents the type of print job
type PrintJobType string

const (
	PrintJobTypeBookingTicket  PrintJobType = "booking_ticket"
	PrintJobTypeEntryTicket    PrintJobType = "entry_ticket"
	PrintJobTypeExitTicket     PrintJobType = "exit_ticket"
	PrintJobTypeDayPassTicket  PrintJobType = "day_pass_ticket"
	PrintJobTypeExitPassTicket PrintJobType = "exit_pass_ticket"
	PrintJobTypeTalon          PrintJobType = "talon"
	PrintJobTypeStandardTicket PrintJobType = "standard_ticket"
	PrintJobTypeReceipt        PrintJobType = "receipt"
	PrintJobTypeQRCode         PrintJobType = "qr_code"
)

// QueuedPrintJob represents a print job in the queue
type QueuedPrintJob struct {
	ID         string       `json:"id"`
	JobType    PrintJobType `json:"jobType"`
	Content    string       `json:"content"`
	StaffName  string       `json:"staffName,omitempty"`
	Priority   int          `json:"priority"` // 0 = highest priority, 255 = lowest
	CreatedAt  time.Time    `json:"createdAt"`
	RetryCount int          `json:"retryCount"`
}

// PrintQueueStatus represents the status of the print queue
type PrintQueueStatus struct {
	QueueLength   int        `json:"queueLength"`
	IsProcessing  bool       `json:"isProcessing"`
	LastPrintedAt *time.Time `json:"lastPrintedAt,omitempty"`
	FailedJobs    int        `json:"failedJobs"`
}

// TicketData represents the data for printing tickets
type TicketData struct {
	LicensePlate     string    `json:"licensePlate"`
	DestinationName  string    `json:"destinationName"`
	SeatNumber       int       `json:"seatNumber"`
	VerificationCode string    `json:"verificationCode"`
	TotalAmount      float64   `json:"totalAmount"`
	CreatedBy        string    `json:"createdBy"`
	CreatedAt        time.Time `json:"createdAt"`
	StationName      string    `json:"stationName"`
	RouteName        string    `json:"routeName"`
	PreviousVehicles []string  `json:"previousVehicles,omitempty"` // For exit pass tickets
}

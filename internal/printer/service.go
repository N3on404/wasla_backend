package printer

import (
	"bytes"
	"fmt"
	"strings"
	"time"
)

// Service handles printer business logic
type Service struct {
	repo *Repository
}

// NewService creates a new printer service
func NewService(repo *Repository) *Service {
	return &Service{
		repo: repo,
	}
}

// GetPrinterConfig retrieves printer configuration
func (s *Service) GetPrinterConfig(printerID string) (*PrinterConfig, error) {
	return s.repo.GetPrinterConfig(printerID)
}

// UpdatePrinterConfig updates printer configuration
func (s *Service) UpdatePrinterConfig(config *PrinterConfig) error {
	return s.repo.SavePrinterConfig(config)
}

// TestPrinterConnection tests the connection to a printer
func (s *Service) TestPrinterConnection(printerID string) error {
	config, err := s.repo.GetPrinterConfig(printerID)
	if err != nil {
		return err
	}

	return s.repo.TestPrinterConnection(config)
}

// GetPrintQueue retrieves the current print queue
func (s *Service) GetPrintQueue() ([]QueuedPrintJob, error) {
	return s.repo.GetPrintQueue()
}

// GetPrintQueueStatus retrieves the print queue status
func (s *Service) GetPrintQueueStatus() (*PrintQueueStatus, error) {
	return s.repo.GetPrintQueueStatus()
}

// AddPrintJob adds a job to the print queue
func (s *Service) AddPrintJob(jobType PrintJobType, content string, staffName string, priority int) (*QueuedPrintJob, error) {
	job := &QueuedPrintJob{
		ID:         generateJobID(),
		JobType:    jobType,
		Content:    content,
		StaffName:  staffName,
		Priority:   priority,
		CreatedAt:  time.Now(),
		RetryCount: 0,
	}

	err := s.repo.AddPrintJob(job)
	if err != nil {
		return nil, err
	}

	return job, nil
}

// PrintTicket prints a ticket directly
func (s *Service) PrintTicket(printerID string, ticketData *TicketData, jobType PrintJobType) error {
	config, err := s.repo.GetPrinterConfig(printerID)
	if err != nil {
		return err
	}

	if !config.Enabled {
		return fmt.Errorf("printer %s is disabled", config.Name)
	}

	// Generate ticket content based on type
	var content string
	switch jobType {
	case PrintJobTypeBookingTicket:
		content = s.generateBookingTicketContent(ticketData)
	case PrintJobTypeEntryTicket:
		content = s.generateEntryTicketContent(ticketData)
	case PrintJobTypeExitTicket:
		content = s.generateExitTicketContent(ticketData)
	case PrintJobTypeDayPassTicket:
		content = s.generateDayPassTicketContent(ticketData)
	case PrintJobTypeExitPassTicket:
		content = s.generateExitPassTicketContent(ticketData)
	case PrintJobTypeTalon:
		content = s.generateTalonContent(ticketData)
	default:
		content = s.generateStandardTicketContent(ticketData)
	}

	// Convert content to ESC/POS commands
	escPosData := s.convertToESCPOS(content, config)

	// Send to printer
	return s.repo.SendPrintData(config, escPosData)
}

// PrintBookingTicket prints a booking ticket
func (s *Service) PrintBookingTicket(printerID string, ticketData *TicketData) error {
	return s.PrintTicket(printerID, ticketData, PrintJobTypeBookingTicket)
}

// PrintEntryTicket prints an entry ticket
func (s *Service) PrintEntryTicket(printerID string, ticketData *TicketData) error {
	return s.PrintTicket(printerID, ticketData, PrintJobTypeEntryTicket)
}

// PrintExitTicket prints an exit ticket
func (s *Service) PrintExitTicket(printerID string, ticketData *TicketData) error {
	return s.PrintTicket(printerID, ticketData, PrintJobTypeExitTicket)
}

// PrintDayPassTicket prints a day pass ticket
func (s *Service) PrintDayPassTicket(printerID string, ticketData *TicketData) error {
	return s.PrintTicket(printerID, ticketData, PrintJobTypeDayPassTicket)
}

// PrintExitPassTicket prints an exit pass ticket
func (s *Service) PrintExitPassTicket(printerID string, ticketData *TicketData) error {
	return s.PrintTicket(printerID, ticketData, PrintJobTypeExitPassTicket)
}

// PrintTalon prints a talon
func (s *Service) PrintTalon(printerID string, ticketData *TicketData) error {
	return s.PrintTicket(printerID, ticketData, PrintJobTypeTalon)
}

// Generate ticket content methods
func (s *Service) generateBookingTicketContent(data *TicketData) string {
	var content strings.Builder

	content.WriteString("================================\n")
	content.WriteString("      BILLET DE RÉSERVATION\n")
	content.WriteString("================================\n\n")
	content.WriteString(fmt.Sprintf("Véhicule: %s\n", data.LicensePlate))
	content.WriteString(fmt.Sprintf("Destination: %s\n", data.DestinationName))
	content.WriteString(fmt.Sprintf("Siège: %d\n", data.SeatNumber))
	content.WriteString(fmt.Sprintf("Code: %s\n", data.VerificationCode))
	content.WriteString(fmt.Sprintf("Montant: %.2f TND\n", data.TotalAmount))
	content.WriteString(fmt.Sprintf("Créé par: %s\n", data.CreatedBy))
	content.WriteString(fmt.Sprintf("Date: %s\n", data.CreatedAt.Format("2006-01-02 15:04")))
	content.WriteString("\n================================\n")
	content.WriteString("Merci de nous avoir choisis!\n")
	content.WriteString("================================\n\n\n\n")

	return content.String()
}

func (s *Service) generateEntryTicketContent(data *TicketData) string {
	var content strings.Builder

	content.WriteString("================================\n")
	content.WriteString("        BILLET D'ENTRÉE\n")
	content.WriteString("================================\n\n")
	content.WriteString(fmt.Sprintf("Véhicule: %s\n", data.LicensePlate))
	content.WriteString(fmt.Sprintf("Route: %s\n", data.RouteName))
	content.WriteString(fmt.Sprintf("Station: %s\n", data.StationName))
	content.WriteString(fmt.Sprintf("Code: %s\n", data.VerificationCode))
	content.WriteString(fmt.Sprintf("Date: %s\n", data.CreatedAt.Format("2006-01-02 15:04")))
	content.WriteString("\n================================\n")
	content.WriteString("Bon voyage!\n")
	content.WriteString("================================\n\n\n\n")

	return content.String()
}

func (s *Service) generateExitTicketContent(data *TicketData) string {
	var content strings.Builder

	content.WriteString("================================\n")
	content.WriteString("        BILLET DE SORTIE\n")
	content.WriteString("================================\n\n")
	content.WriteString(fmt.Sprintf("Véhicule: %s\n", data.LicensePlate))
	content.WriteString(fmt.Sprintf("Route: %s\n", data.RouteName))
	content.WriteString(fmt.Sprintf("Station: %s\n", data.StationName))
	content.WriteString(fmt.Sprintf("Code: %s\n", data.VerificationCode))
	content.WriteString(fmt.Sprintf("Date: %s\n", data.CreatedAt.Format("2006-01-02 15:04")))
	content.WriteString("\n================================\n")
	content.WriteString("Merci!\n")
	content.WriteString("================================\n\n\n\n")

	return content.String()
}

func (s *Service) generateDayPassTicketContent(data *TicketData) string {
	var content strings.Builder

	content.WriteString("================================\n")
	content.WriteString("      BILLET PASS JOURNÉE\n")
	content.WriteString("================================\n\n")
	content.WriteString(fmt.Sprintf("Véhicule: %s\n", data.LicensePlate))
	content.WriteString(fmt.Sprintf("Route: %s\n", data.RouteName))
	content.WriteString(fmt.Sprintf("Station: %s\n", data.StationName))
	content.WriteString(fmt.Sprintf("Code: %s\n", data.VerificationCode))
	content.WriteString(fmt.Sprintf("Montant: %.2f TND\n", data.TotalAmount))
	content.WriteString(fmt.Sprintf("Date: %s\n", data.CreatedAt.Format("2006-01-02 15:04")))
	content.WriteString("\n================================\n")
	content.WriteString("Valide toute la journée!\n")
	content.WriteString("================================\n\n\n\n")

	return content.String()
}

func (s *Service) generateExitPassTicketContent(data *TicketData) string {
	var content strings.Builder

	content.WriteString("================================\n")
	content.WriteString("     BILLET AUTORISATION SORTIE\n")
	content.WriteString("================================\n\n")
	content.WriteString(fmt.Sprintf("Véhicule: %s\n", data.LicensePlate))
	content.WriteString(fmt.Sprintf("Route: %s\n", data.RouteName))
	content.WriteString(fmt.Sprintf("Station: %s\n", data.StationName))
	content.WriteString(fmt.Sprintf("Code: %s\n", data.VerificationCode))
	content.WriteString(fmt.Sprintf("Date: %s\n", data.CreatedAt.Format("2006-01-02 15:04")))
	content.WriteString("\n================================\n")
	content.WriteString("Sortie autorisée!\n")
	content.WriteString("================================\n\n\n\n")

	return content.String()
}

func (s *Service) generateTalonContent(data *TicketData) string {
	var content strings.Builder

	content.WriteString("================================\n")
	content.WriteString("            TALON\n")
	content.WriteString("================================\n\n")
	content.WriteString(fmt.Sprintf("Véhicule: %s\n", data.LicensePlate))
	content.WriteString(fmt.Sprintf("Route: %s\n", data.RouteName))
	content.WriteString(fmt.Sprintf("Station: %s\n", data.StationName))
	content.WriteString(fmt.Sprintf("Code: %s\n", data.VerificationCode))
	content.WriteString(fmt.Sprintf("Date: %s\n", data.CreatedAt.Format("2006-01-02 15:04")))
	content.WriteString("\n================================\n")
	content.WriteString("Billet de position dans la file\n")
	content.WriteString("================================\n\n\n\n")

	return content.String()
}

func (s *Service) generateStandardTicketContent(data *TicketData) string {
	var content strings.Builder

	content.WriteString("================================\n")
	content.WriteString("        BILLET STANDARD\n")
	content.WriteString("================================\n\n")
	content.WriteString(fmt.Sprintf("Véhicule: %s\n", data.LicensePlate))
	content.WriteString(fmt.Sprintf("Destination: %s\n", data.DestinationName))
	content.WriteString(fmt.Sprintf("Code: %s\n", data.VerificationCode))
	content.WriteString(fmt.Sprintf("Montant: %.2f TND\n", data.TotalAmount))
	content.WriteString(fmt.Sprintf("Date: %s\n", data.CreatedAt.Format("2006-01-02 15:04")))
	content.WriteString("\n================================\n")
	content.WriteString("Merci!\n")
	content.WriteString("================================\n\n\n\n")

	return content.String()
}

// Convert text content to ESC/POS commands
func (s *Service) convertToESCPOS(content string, config *PrinterConfig) []byte {
	var buffer bytes.Buffer

	// Initialize printer
	buffer.WriteByte(0x1B) // ESC
	buffer.WriteByte(0x40) // @

	// Set character size (normal)
	buffer.WriteByte(0x1B) // ESC
	buffer.WriteByte(0x21) // !
	buffer.WriteByte(0x00) // Normal size

	// Set alignment to center for title
	buffer.WriteByte(0x1B) // ESC
	buffer.WriteByte(0x61) // a
	buffer.WriteByte(0x01) // Center

	// Print content
	lines := strings.Split(content, "\n")
	for _, line := range lines {
		if strings.Contains(line, "BILLET") || strings.Contains(line, "TALON") || strings.Contains(line, "AUTORISATION") {
			// Bold for titles
			buffer.WriteByte(0x1B) // ESC
			buffer.WriteByte(0x21) // !
			buffer.WriteByte(0x08) // Bold
		} else {
			// Normal text
			buffer.WriteByte(0x1B) // ESC
			buffer.WriteByte(0x21) // !
			buffer.WriteByte(0x00) // Normal
		}

		buffer.WriteString(line)
		buffer.WriteByte(0x0A) // Line feed

		// Reset alignment after title
		if strings.Contains(line, "BILLET") || strings.Contains(line, "TALON") || strings.Contains(line, "AUTORISATION") {
			buffer.WriteByte(0x1B) // ESC
			buffer.WriteByte(0x61) // a
			buffer.WriteByte(0x00) // Left align
		}
	}

	// Cut paper
	buffer.WriteByte(0x1D) // GS
	buffer.WriteByte(0x56) // V
	buffer.WriteByte(0x00) // Full cut

	return buffer.Bytes()
}

// Helper function to generate unique job ID
func generateJobID() string {
	return fmt.Sprintf("job_%d", time.Now().UnixNano())
}

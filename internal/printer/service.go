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

	// Compact header with company name
	if data.CompanyName != "" {
		content.WriteString("================================\n")
		content.WriteString(fmt.Sprintf("  %s\n", strings.ToUpper("STE DHRAIFF SERVICES TRANSPORT")))
		content.WriteString("================================\n")
	}

	// Compact ticket title
	content.WriteString("     BILLET DE RÉSERVATION\n")
	content.WriteString("--------------------------------\n")

	// Essential information in compact format
	content.WriteString(fmt.Sprintf("Vehicule: %s\n", data.LicensePlate))
	content.WriteString(fmt.Sprintf("Destination: %s\n", data.DestinationName))
	content.WriteString(fmt.Sprintf("Siège: %d\n", data.SeatNumber))

	// Detailed pricing breakdown
	if data.BasePrice > 0 {
		serviceFee := 0.15
		content.WriteString(fmt.Sprintf("Prix de base: %.2f TND\n", data.BasePrice))
		content.WriteString(fmt.Sprintf("Frais de service: %.2f TND\n", serviceFee))
		content.WriteString(fmt.Sprintf("Total: %.2f TND\n", data.TotalAmount))
	} else {
		content.WriteString(fmt.Sprintf("Montant: %.2f TND\n", data.TotalAmount))
	}

	content.WriteString(fmt.Sprintf("Date: %s\n", data.CreatedAt.Format("02/01/2006 15:04")))
	content.WriteString(fmt.Sprintf("Agent: %s\n", data.CreatedBy))

	// Compact footer
	content.WriteString("--------------------------------\n")
	content.WriteString("Merci de nous avoir choisis!\n")

	// Staff information at the bottom (compact)
	if data.StaffFirstName != "" && data.StaffLastName != "" {
		content.WriteString(fmt.Sprintf("Agent: %s %s\n", data.StaffFirstName, data.StaffLastName))
	}

	content.WriteString("\n\n")

	return content.String()
}

func (s *Service) generateEntryTicketContent(data *TicketData) string {
	var content strings.Builder

	// Compact header with company name
	if data.CompanyName != "" {
		content.WriteString("================================\n")
		content.WriteString(fmt.Sprintf("  %s\n", strings.ToUpper("STE DHRAIFF SERVICES TRANSPORT")))
		content.WriteString("================================\n")
	}

	// Compact ticket title
	content.WriteString("        BILLET D'ENTRÉE\n")
	content.WriteString("--------------------------------\n")

	// Essential information in compact format
	content.WriteString(fmt.Sprintf("Vehicule: %s\n", data.LicensePlate))
	content.WriteString(fmt.Sprintf("Route: %s\n", data.RouteName))
	content.WriteString(fmt.Sprintf("Date: %s\n", data.CreatedAt.Format("02/01/2006 15:04")))
	content.WriteString(fmt.Sprintf("Agent: %s\n", data.CreatedBy))
	// Compact footer
	content.WriteString("--------------------------------\n")
	content.WriteString("Bon voyage!\n")

	// Staff information at the bottom (compact)
	if data.StaffFirstName != "" && data.StaffLastName != "" {
		content.WriteString(fmt.Sprintf("Agent: %s %s\n", data.StaffFirstName, data.StaffLastName))
	}

	content.WriteString("\n\n")

	return content.String()
}

func (s *Service) generateExitTicketContent(data *TicketData) string {
	var content strings.Builder

	// Compact header with company name
	if data.CompanyName != "" {
		content.WriteString("================================\n")
		content.WriteString(fmt.Sprintf("  %s\n", strings.ToUpper("STE DHRAIFF SERVICES TRANSPORT")))
		content.WriteString("================================\n")
	}

	// Compact ticket title
	content.WriteString("        BILLET DE SORTIE\n")
	content.WriteString("--------------------------------\n")

	// Essential information in compact format
	content.WriteString(fmt.Sprintf("Vehicule: %s\n", data.LicensePlate))
	content.WriteString(fmt.Sprintf("Route: %s\n", data.RouteName))
	content.WriteString(fmt.Sprintf("Station: %s\n", data.StationName))
	content.WriteString(fmt.Sprintf("Date: %s\n", data.CreatedAt.Format("02/01/2006 15:04")))
	content.WriteString(fmt.Sprintf("Agent: %s\n", data.CreatedBy))
	// Compact footer
	content.WriteString("--------------------------------\n")
	content.WriteString("Merci!\n")

	// Staff information at the bottom (compact)
	if data.StaffFirstName != "" && data.StaffLastName != "" {
		content.WriteString(fmt.Sprintf("Agent: %s %s\n", data.StaffFirstName, data.StaffLastName))
	}

	content.WriteString("\n\n")

	return content.String()
}

func (s *Service) generateDayPassTicketContent(data *TicketData) string {
	var content strings.Builder

	// Compact header with company name
	if data.CompanyName != "" {
		content.WriteString("================================\n")
		content.WriteString(fmt.Sprintf("  %s\n", strings.ToUpper("STE DHRAIFF SERVICES TRANSPORT")))
		content.WriteString("================================\n")
	}

	// Compact ticket title
	content.WriteString("      BILLET PASS JOURNÉE\n")
	content.WriteString("--------------------------------\n")

	// Essential information in compact format
	content.WriteString(fmt.Sprintf("Vehicule: %s\n", data.LicensePlate))
	content.WriteString(fmt.Sprintf("Route: %s\n", data.RouteName))
	content.WriteString(fmt.Sprintf("Montant: %.2f TND\n", data.TotalAmount))
	content.WriteString(fmt.Sprintf("Date: %s\n", data.CreatedAt.Format("02/01/2006 15:04")))
	content.WriteString(fmt.Sprintf("Agent: %s\n", data.CreatedBy))
	// Compact footer
	content.WriteString("--------------------------------\n")
	content.WriteString("Valide toute la journée!\n")

	// Staff information at the bottom (compact)
	if data.StaffFirstName != "" && data.StaffLastName != "" {
		content.WriteString(fmt.Sprintf("Agent: %s %s\n", data.StaffFirstName, data.StaffLastName))
	}

	content.WriteString("\n\n")

	return content.String()
}

func (s *Service) generateExitPassTicketContent(data *TicketData) string {
	var content strings.Builder

	// Compact header with company name
	if data.CompanyName != "" {
		content.WriteString("================================\n")
		content.WriteString(fmt.Sprintf("  %s\n", strings.ToUpper("STE DHRAIFF SERVICES TRANSPORT")))
		content.WriteString("================================\n")
	}

	// Compact ticket title with exit pass count in top right
	content.WriteString("   🚪 BILLET AUTORISATION SORTIE")
	// Add spaces to position exit pass count in top right (assuming 32 char width)
	if data.ExitPassCount > 0 {
		countSpaces := 32 - 30 - 4 // 32 total - "🚪 BILLET AUTORISATION SORTIE" (30) - count (4) = -2 spaces
		for i := 0; i < countSpaces; i++ {
			content.WriteString(" ")
		}
		content.WriteString(fmt.Sprintf("(%d)\n", data.ExitPassCount))
	} else {
		content.WriteString("\n")
	}
	content.WriteString("--------------------------------\n")

	// Essential information in compact format
	content.WriteString(fmt.Sprintf("Vehicule: %s\n", data.LicensePlate))
	content.WriteString(fmt.Sprintf("Destination: %s\n", data.DestinationName))
	content.WriteString(fmt.Sprintf("Montant Total: %.2f TND\n", data.TotalAmount))
	fmt.Printf("DEBUG: Exit pass ticket time - Original: %v\n", data.CreatedAt)
	content.WriteString(fmt.Sprintf("Date: %s\n", data.CreatedAt.Format("02/01/2006 15:04")))
	content.WriteString(fmt.Sprintf("Agent: %s\n", data.CreatedBy))
	// Compact footer
	content.WriteString("--------------------------------\n")
	content.WriteString("🚪 Sortie autorisée!\n")

	// Staff information at the bottom (compact)
	if data.StaffFirstName != "" && data.StaffLastName != "" {
		content.WriteString(fmt.Sprintf("Agent: %s %s\n", data.StaffFirstName, data.StaffLastName))
	}

	content.WriteString("\n\n")

	return content.String()
}

func (s *Service) generateTalonContent(data *TicketData) string {
	var content strings.Builder

	// Minimal talon with seat index in top right
	// Add spaces to position seat number in top right (assuming 32 char width)
	seatSpaces := 32 - 5 - 3 // 32 total - "Vehicule Number Plate" (5) - seat number (3) = 24 spaces
	content.WriteString(fmt.Sprintf("Vehicule: %s\n", data.LicensePlate))
	for i := 0; i < seatSpaces; i++ {
		content.WriteString(" ")
	}
	content.WriteString(fmt.Sprintf("(%d)\n", data.SeatNumber))
	content.WriteString("-----\n")
	content.WriteString(fmt.Sprintf("Montant: %.2f TND\n", data.TotalAmount))
	content.WriteString(fmt.Sprintf("Heure: %s\n", data.CreatedAt.Format("02/01/2006 15:04")))
	content.WriteString(fmt.Sprintf("Agent: %s\n", data.CreatedBy))
	content.WriteString("\n")

	return content.String()
}

func (s *Service) generateStandardTicketContent(data *TicketData) string {
	var content strings.Builder

	// Compact header with company name
	if data.CompanyName != "" {
		content.WriteString("================================\n")
		content.WriteString(fmt.Sprintf("  %s\n", strings.ToUpper("STE DHRAIFF SERVICES TRANSPORT")))
		content.WriteString("================================\n")
	}

	// Compact ticket title
	content.WriteString("        BILLET STANDARD\n")
	content.WriteString("--------------------------------\n")

	// Essential information in compact format
	content.WriteString(fmt.Sprintf("Vehicule: %s\n", data.LicensePlate))
	content.WriteString(fmt.Sprintf("Destination: %s\n", data.DestinationName))
	content.WriteString(fmt.Sprintf("Montant: %.2f TND\n", data.TotalAmount))
	content.WriteString(fmt.Sprintf("Date: %s\n", data.CreatedAt.Format("02/01/2006 15:04")))
	content.WriteString(fmt.Sprintf("Agent: %s\n", data.CreatedBy))
	// Compact footer
	content.WriteString("--------------------------------\n")
	content.WriteString("Merci!\n")

	// Staff information at the bottom (compact)
	if data.StaffFirstName != "" && data.StaffLastName != "" {
		content.WriteString(fmt.Sprintf("Agent: %s %s\n", data.StaffFirstName, data.StaffLastName))
	}

	content.WriteString("\n\n")

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
		if strings.Contains(line, "BILLET") || strings.Contains(line, "TALON") || strings.Contains(line, "AUTORISATION") || strings.Contains(line, "STANDARD") {
			// Bold for titles
			buffer.WriteByte(0x1B) // ESC
			buffer.WriteByte(0x21) // !
			buffer.WriteByte(0x08) // Bold
		} else if strings.Contains(line, "Agent:") {
			// Italic for staff information
			buffer.WriteByte(0x1B) // ESC
			buffer.WriteByte(0x21) // !
			buffer.WriteByte(0x40) // Italic
		} else {
			// Normal text
			buffer.WriteByte(0x1B) // ESC
			buffer.WriteByte(0x21) // !
			buffer.WriteByte(0x00) // Normal
		}

		buffer.WriteString(line)
		buffer.WriteByte(0x0A) // Line feed

		// Reset alignment after title
		if strings.Contains(line, "BILLET") || strings.Contains(line, "TALON") || strings.Contains(line, "AUTORISATION") || strings.Contains(line, "STANDARD") {
			buffer.WriteByte(0x1B) // ESC
			buffer.WriteByte(0x61) // a
			buffer.WriteByte(0x00) // Left align
		}
	}

	// Add extra line feeds before cutting to ensure all content is printed
	buffer.WriteByte(0x0A) // Line feed
	buffer.WriteByte(0x0A) // Line feed

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

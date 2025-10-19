package statistics

import (
	"context"
	"fmt"
	"time"
)

type Service struct {
	repo Repository
}

func NewService(repo Repository) *Service {
	return &Service{repo: repo}
}

// LogSeatBooking logs a seat booking transaction
func (s *Service) LogSeatBooking(ctx context.Context, staffID, bookingID, stationID string, seats int) error {
	// Calculate income: 0.2 TND per seat
	seatIncome := float64(seats) * 0.2

	req := LogTransactionRequest{
		StaffID:         staffID,
		TransactionType: "SEAT_BOOKING",
		TransactionID:   bookingID,
		Amount:          seatIncome,
		Quantity:        seats,
		StationID:       stationID,
	}

	return s.repo.LogTransaction(ctx, req)
}

// LogDayPassSale logs a day pass sale transaction
func (s *Service) LogDayPassSale(ctx context.Context, staffID, dayPassID, stationID string) error {
	// Day pass income: 2 TND per day pass
	req := LogTransactionRequest{
		StaffID:         staffID,
		TransactionType: "DAY_PASS_SALE",
		TransactionID:   dayPassID,
		Amount:          2.0,
		Quantity:        1,
		StationID:       stationID,
	}

	return s.repo.LogTransaction(ctx, req)
}

// GetStaffDailyIncome gets daily income summary for a specific staff member
func (s *Service) GetStaffDailyIncome(ctx context.Context, staffID string, date time.Time) (*StaffIncomeSummary, error) {
	return s.repo.GetStaffDailyIncome(ctx, staffID, date)
}

// GetStationDailyIncome gets daily income summary for a specific station
func (s *Service) GetStationDailyIncome(ctx context.Context, stationID string, date time.Time) (*StationIncomeSummary, error) {
	return s.repo.GetStationDailyIncome(ctx, stationID, date)
}

// GetStaffIncomeRange gets income summary for a staff member over a date range
func (s *Service) GetStaffIncomeRange(ctx context.Context, staffID string, startDate, endDate time.Time) ([]StaffIncomeSummary, error) {
	if startDate.After(endDate) {
		return nil, fmt.Errorf("start date cannot be after end date")
	}

	// Limit date range to 1 year
	if endDate.Sub(startDate) > 365*24*time.Hour {
		return nil, fmt.Errorf("date range cannot exceed 1 year")
	}

	return s.repo.GetStaffIncomeRange(ctx, staffID, startDate, endDate)
}

// GetStationIncomeRange gets income summary for a station over a date range
func (s *Service) GetStationIncomeRange(ctx context.Context, stationID string, startDate, endDate time.Time) ([]StationIncomeSummary, error) {
	if startDate.After(endDate) {
		return nil, fmt.Errorf("start date cannot be after end date")
	}

	// Limit date range to 1 year
	if endDate.Sub(startDate) > 365*24*time.Hour {
		return nil, fmt.Errorf("date range cannot exceed 1 year")
	}

	return s.repo.GetStationIncomeRange(ctx, stationID, startDate, endDate)
}

// GetAllStaffIncomeForDate gets income summary for all staff members for a specific date
func (s *Service) GetAllStaffIncomeForDate(ctx context.Context, date time.Time) ([]StaffIncomeSummary, error) {
	return s.repo.GetAllStaffIncomeForDate(ctx, date)
}

// GetAllStationIncomeForDate gets income summary for all stations for a specific date
func (s *Service) GetAllStationIncomeForDate(ctx context.Context, date time.Time) ([]StationIncomeSummary, error) {
	return s.repo.GetAllStationIncomeForDate(ctx, date)
}

// GetStaffTransactionLog gets transaction log for a specific staff member
func (s *Service) GetStaffTransactionLog(ctx context.Context, staffID string, limit int) ([]StaffTransactionLog, error) {
	return s.repo.GetStaffTransactionLog(ctx, staffID, limit)
}

// GetStationTransactionLog gets transaction log for a specific station
func (s *Service) GetStationTransactionLog(ctx context.Context, stationID string, limit int) ([]StaffTransactionLog, error) {
	return s.repo.GetStationTransactionLog(ctx, stationID, limit)
}

// GetTodayStaffIncome gets today's income for a specific staff member
func (s *Service) GetTodayStaffIncome(ctx context.Context, staffID string) (*StaffIncomeSummary, error) {
	return s.repo.GetStaffDailyIncome(ctx, staffID, time.Now())
}

// GetTodayStationIncome gets today's income for a specific station
func (s *Service) GetTodayStationIncome(ctx context.Context, stationID string) (*StationIncomeSummary, error) {
	return s.repo.GetStationDailyIncome(ctx, stationID, time.Now())
}

// GetStaffIncomeThisWeek gets this week's income for a specific staff member
func (s *Service) GetStaffIncomeThisWeek(ctx context.Context, staffID string) ([]StaffIncomeSummary, error) {
	now := time.Now()
	startOfWeek := now.AddDate(0, 0, -int(now.Weekday()))
	startOfWeek = time.Date(startOfWeek.Year(), startOfWeek.Month(), startOfWeek.Day(), 0, 0, 0, 0, startOfWeek.Location())

	return s.repo.GetStaffIncomeRange(ctx, staffID, startOfWeek, now)
}

// GetStationIncomeThisWeek gets this week's income for a specific station
func (s *Service) GetStationIncomeThisWeek(ctx context.Context, stationID string) ([]StationIncomeSummary, error) {
	now := time.Now()
	startOfWeek := now.AddDate(0, 0, -int(now.Weekday()))
	startOfWeek = time.Date(startOfWeek.Year(), startOfWeek.Month(), startOfWeek.Day(), 0, 0, 0, 0, startOfWeek.Location())

	return s.repo.GetStationIncomeRange(ctx, stationID, startOfWeek, now)
}

// GetStaffIncomeThisMonth gets this month's income for a specific staff member
func (s *Service) GetStaffIncomeThisMonth(ctx context.Context, staffID string) ([]StaffIncomeSummary, error) {
	now := time.Now()
	startOfMonth := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, now.Location())

	return s.repo.GetStaffIncomeRange(ctx, staffID, startOfMonth, now)
}

// GetStationIncomeThisMonth gets this month's income for a specific station
func (s *Service) GetStationIncomeThisMonth(ctx context.Context, stationID string) ([]StationIncomeSummary, error) {
	now := time.Now()
	startOfMonth := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, now.Location())

	return s.repo.GetStationIncomeRange(ctx, stationID, startOfMonth, now)
}

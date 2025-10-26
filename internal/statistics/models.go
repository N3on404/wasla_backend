package statistics

import (
	"time"
)

// StaffDailyStatistics represents daily income statistics for a staff member
type StaffDailyStatistics struct {
	ID                 string    `json:"id"`
	StaffID            string    `json:"staffId"`
	StaffName          string    `json:"staffName"`
	Date               time.Time `json:"date"`
	TotalSeatsBooked   int       `json:"totalSeatsBooked"`
	TotalSeatIncome    float64   `json:"totalSeatIncome"`
	TotalDayPassesSold int       `json:"totalDayPassesSold"`
	TotalDayPassIncome float64   `json:"totalDayPassIncome"`
	TotalIncome        float64   `json:"totalIncome"`
	TotalTransactions  int       `json:"totalTransactions"`
	CreatedAt          time.Time `json:"createdAt"`
	UpdatedAt          time.Time `json:"updatedAt"`
}

// StationDailyStatistics represents daily income statistics for a station
type StationDailyStatistics struct {
	ID                 string    `json:"id"`
	StationID          string    `json:"stationId"`
	StationName        string    `json:"stationName"`
	Date               time.Time `json:"date"`
	TotalSeatsBooked   int       `json:"totalSeatsBooked"`
	TotalSeatIncome    float64   `json:"totalSeatIncome"`
	TotalDayPassesSold int       `json:"totalDayPassesSold"`
	TotalDayPassIncome float64   `json:"totalDayPassIncome"`
	TotalIncome        float64   `json:"totalIncome"`
	TotalTransactions  int       `json:"totalTransactions"`
	ActiveStaffCount   int       `json:"activeStaffCount"`
	CreatedAt          time.Time `json:"createdAt"`
	UpdatedAt          time.Time `json:"updatedAt"`
}

// StaffTransactionLog represents individual transaction records
type StaffTransactionLog struct {
	ID              string    `json:"id"`
	StaffID         string    `json:"staffId"`
	StaffName       string    `json:"staffName"`
	TransactionType string    `json:"transactionType"` // "SEAT_BOOKING" or "DAY_PASS_SALE"
	TransactionID   string    `json:"transactionId"`
	Amount          float64   `json:"amount"`
	Quantity        int       `json:"quantity"`
	StationID       string    `json:"stationId"`
	StationName     string    `json:"stationName"`
	CreatedAt       time.Time `json:"createdAt"`
}

// StaffIncomeSummary represents income summary for a staff member
type StaffIncomeSummary struct {
	StaffID                 string    `json:"staffId"`
	StaffName               string    `json:"staffName"`
	Date                    time.Time `json:"date"`
	SeatBookings            int       `json:"seatBookings"`
	SeatIncome              float64   `json:"seatIncome"`
	DayPassSales            int       `json:"dayPassSales"`
	DayPassIncome           float64   `json:"dayPassIncome"`
	TotalIncome             float64   `json:"totalIncome"`
	TotalTransactions       int       `json:"totalTransactions"`
	AverageIncomePerSeat    float64   `json:"averageIncomePerSeat"`
	AverageIncomePerDayPass float64   `json:"averageIncomePerDayPass"`
}

// StationIncomeSummary represents income summary for a station
type StationIncomeSummary struct {
	StationID               string    `json:"stationId"`
	StationName             string    `json:"stationName"`
	Date                    time.Time `json:"date"`
	TotalSeatBookings       int       `json:"totalSeatBookings"`
	TotalSeatIncome         float64   `json:"totalSeatIncome"`
	TotalDayPassSales       int       `json:"totalDayPassSales"`
	TotalDayPassIncome      float64   `json:"totalDayPassIncome"`
	TotalIncome             float64   `json:"totalIncome"`
	TotalTransactions       int       `json:"totalTransactions"`
	ActiveStaffCount        int       `json:"activeStaffCount"`
	AverageIncomePerStaff   float64   `json:"averageIncomePerStaff"`
	AverageIncomePerSeat    float64   `json:"averageIncomePerSeat"`
	AverageIncomePerDayPass float64   `json:"averageIncomePerDayPass"`
}

// GetStaffIncomeRequest represents request to get staff income
type GetStaffIncomeRequest struct {
	StaffID string    `json:"staffId"`
	Date    time.Time `json:"date"`
}

// GetStationIncomeRequest represents request to get station income
type GetStationIncomeRequest struct {
	StationID string    `json:"stationId"`
	Date      time.Time `json:"date"`
}

// GetStaffIncomeRangeRequest represents request to get staff income for a date range
type GetStaffIncomeRangeRequest struct {
	StaffID   string    `json:"staffId"`
	StartDate time.Time `json:"startDate"`
	EndDate   time.Time `json:"endDate"`
}

// GetStationIncomeRangeRequest represents request to get station income for a date range
type GetStationIncomeRangeRequest struct {
	StationID string    `json:"stationId"`
	StartDate time.Time `json:"startDate"`
	EndDate   time.Time `json:"endDate"`
}

// LogTransactionRequest represents request to log a transaction
type LogTransactionRequest struct {
	StaffID         string  `json:"staffId"`
	TransactionType string  `json:"transactionType"` // "SEAT_BOOKING" or "DAY_PASS_SALE"
	TransactionID   string  `json:"transactionId"`
	Amount          float64 `json:"amount"`
	Quantity        int     `json:"quantity"`
	StationID       string  `json:"stationId"`
}

// ActualIncomeSummary represents actual income calculated with destination base prices
type ActualIncomeSummary struct {
	Date                    time.Time `json:"date"`
	SeatsBooked             int       `json:"seatsBooked"`
	ActualSeatIncome        float64   `json:"actualSeatIncome"` // Base price + 0.150 per seat
	DayPassSales            int       `json:"dayPassSales"`
	DayPassIncome           float64   `json:"dayPassIncome"`           // 2.0 per day pass
	TotalActualIncome       float64   `json:"totalActualIncome"`       // actualSeatIncome + dayPassIncome
	SeatsWithoutDestination int       `json:"seatsWithoutDestination"` // bookings without queue/destination info
}

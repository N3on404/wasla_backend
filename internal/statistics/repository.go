package statistics

import (
	"context"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Repository interface {
	LogTransaction(ctx context.Context, req LogTransactionRequest) error
	GetStaffDailyIncome(ctx context.Context, staffID string, date time.Time) (*StaffIncomeSummary, error)
	GetStationDailyIncome(ctx context.Context, stationID string, date time.Time) (*StationIncomeSummary, error)
	GetStaffIncomeRange(ctx context.Context, staffID string, startDate, endDate time.Time) ([]StaffIncomeSummary, error)
	GetStationIncomeRange(ctx context.Context, stationID string, startDate, endDate time.Time) ([]StationIncomeSummary, error)
	GetAllStaffIncomeForDate(ctx context.Context, date time.Time) ([]StaffIncomeSummary, error)
	GetAllStationIncomeForDate(ctx context.Context, date time.Time) ([]StationIncomeSummary, error)
	GetStaffTransactionLog(ctx context.Context, staffID string, limit int) ([]StaffTransactionLog, error)
	GetStationTransactionLog(ctx context.Context, stationID string, limit int) ([]StaffTransactionLog, error)
	GetActualIncomeForDate(ctx context.Context, date time.Time) (*ActualIncomeSummary, error)
	GetActualIncomeForPeriod(ctx context.Context, startTime, endTime time.Time) (*ActualIncomeSummary, error)
	GetActualIncomeForMonth(ctx context.Context, year, month int) (*ActualIncomeSummary, error)
	GetAllStaffIncomeForMonth(ctx context.Context, year, month int) ([]StaffIncomeSummary, error)
}

type RepositoryImpl struct {
	db *pgxpool.Pool
}

func NewRepository(db *pgxpool.Pool) Repository {
	return &RepositoryImpl{db: db}
}

// LogTransaction logs a staff transaction and updates daily statistics
func (r *RepositoryImpl) LogTransaction(ctx context.Context, req LogTransactionRequest) error {
	_, err := r.db.Exec(ctx, `
		SELECT log_staff_transaction($1, $2, $3, $4, $5, $6)
	`, req.StaffID, req.TransactionType, req.TransactionID, req.Amount, req.Quantity, req.StationID)
	return err
}

// GetStaffDailyIncome gets daily income summary for a specific staff member
func (r *RepositoryImpl) GetStaffDailyIncome(ctx context.Context, staffID string, date time.Time) (*StaffIncomeSummary, error) {
	var summary StaffIncomeSummary

	query := `
		SELECT 
			s.id as staff_id,
			CONCAT(s.first_name, ' ', s.last_name) as staff_name,
			sds.date,
			COALESCE(sds.total_seats_booked, 0) as seat_bookings,
			COALESCE(sds.total_seat_income, 0.00) as seat_income,
			COALESCE(sds.total_day_passes_sold, 0) as day_pass_sales,
			COALESCE(sds.total_day_pass_income, 0.00) as day_pass_income,
			COALESCE(sds.total_income, 0.00) as total_income,
			COALESCE(sds.total_transactions, 0) as total_transactions,
			CASE 
				WHEN COALESCE(sds.total_seats_booked, 0) > 0 
				THEN COALESCE(sds.total_seat_income, 0.00) / sds.total_seats_booked 
				ELSE 0.00 
			END as avg_income_per_seat,
			CASE 
				WHEN COALESCE(sds.total_day_passes_sold, 0) > 0 
				THEN COALESCE(sds.total_day_pass_income, 0.00) / sds.total_day_passes_sold 
				ELSE 0.00 
			END as avg_income_per_day_pass
		FROM staff s
		LEFT JOIN staff_daily_statistics sds ON s.id = sds.staff_id AND sds.date = $2
		WHERE s.id = $1
	`

	err := r.db.QueryRow(ctx, query, staffID, date).Scan(
		&summary.StaffID, &summary.StaffName, &summary.Date,
		&summary.SeatBookings, &summary.SeatIncome, &summary.DayPassSales,
		&summary.DayPassIncome, &summary.TotalIncome, &summary.TotalTransactions,
		&summary.AverageIncomePerSeat, &summary.AverageIncomePerDayPass,
	)

	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, fmt.Errorf("staff member not found")
		}
		return nil, err
	}

	return &summary, nil
}

// GetStationDailyIncome gets daily income summary for a specific station
func (r *RepositoryImpl) GetStationDailyIncome(ctx context.Context, stationID string, date time.Time) (*StationIncomeSummary, error) {
	var summary StationIncomeSummary

	query := `
		SELECT 
			st.id as station_id,
			st.station_name,
			stds.date,
			COALESCE(stds.total_seats_booked, 0) as total_seat_bookings,
			COALESCE(stds.total_seat_income, 0.00) as total_seat_income,
			COALESCE(stds.total_day_passes_sold, 0) as total_day_pass_sales,
			COALESCE(stds.total_day_pass_income, 0.00) as total_day_pass_income,
			COALESCE(stds.total_income, 0.00) as total_income,
			COALESCE(stds.total_transactions, 0) as total_transactions,
			COALESCE(stds.active_staff_count, 0) as active_staff_count,
			CASE 
				WHEN COALESCE(stds.active_staff_count, 0) > 0 
				THEN COALESCE(stds.total_income, 0.00) / stds.active_staff_count 
				ELSE 0.00 
			END as avg_income_per_staff,
			CASE 
				WHEN COALESCE(stds.total_seats_booked, 0) > 0 
				THEN COALESCE(stds.total_seat_income, 0.00) / stds.total_seats_booked 
				ELSE 0.00 
			END as avg_income_per_seat,
			CASE 
				WHEN COALESCE(stds.total_day_passes_sold, 0) > 0 
				THEN COALESCE(stds.total_day_pass_income, 0.00) / stds.total_day_passes_sold 
				ELSE 0.00 
			END as avg_income_per_day_pass
		FROM stations st
		LEFT JOIN station_daily_statistics stds ON st.id = stds.station_id AND stds.date = $2
		WHERE st.id = $1
	`

	err := r.db.QueryRow(ctx, query, stationID, date).Scan(
		&summary.StationID, &summary.StationName, &summary.Date,
		&summary.TotalSeatBookings, &summary.TotalSeatIncome, &summary.TotalDayPassSales,
		&summary.TotalDayPassIncome, &summary.TotalIncome, &summary.TotalTransactions,
		&summary.ActiveStaffCount, &summary.AverageIncomePerStaff,
		&summary.AverageIncomePerSeat, &summary.AverageIncomePerDayPass,
	)

	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, fmt.Errorf("station not found")
		}
		return nil, err
	}

	return &summary, nil
}

// GetStaffIncomeRange gets income summary for a staff member over a date range
func (r *RepositoryImpl) GetStaffIncomeRange(ctx context.Context, staffID string, startDate, endDate time.Time) ([]StaffIncomeSummary, error) {
	query := `
		SELECT 
			s.id as staff_id,
			CONCAT(s.first_name, ' ', s.last_name) as staff_name,
			sds.date,
			COALESCE(sds.total_seats_booked, 0) as seat_bookings,
			COALESCE(sds.total_seat_income, 0.00) as seat_income,
			COALESCE(sds.total_day_passes_sold, 0) as day_pass_sales,
			COALESCE(sds.total_day_pass_income, 0.00) as day_pass_income,
			COALESCE(sds.total_income, 0.00) as total_income,
			COALESCE(sds.total_transactions, 0) as total_transactions,
			CASE 
				WHEN COALESCE(sds.total_seats_booked, 0) > 0 
				THEN COALESCE(sds.total_seat_income, 0.00) / sds.total_seats_booked 
				ELSE 0.00 
			END as avg_income_per_seat,
			CASE 
				WHEN COALESCE(sds.total_day_passes_sold, 0) > 0 
				THEN COALESCE(sds.total_day_pass_income, 0.00) / sds.total_day_passes_sold 
				ELSE 0.00 
			END as avg_income_per_day_pass
		FROM staff s
		LEFT JOIN staff_daily_statistics sds ON s.id = sds.staff_id 
		WHERE s.id = $1 AND sds.date BETWEEN $2 AND $3
		ORDER BY sds.date DESC
	`

	rows, err := r.db.Query(ctx, query, staffID, startDate, endDate)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var summaries []StaffIncomeSummary
	for rows.Next() {
		var summary StaffIncomeSummary
		err := rows.Scan(
			&summary.StaffID, &summary.StaffName, &summary.Date,
			&summary.SeatBookings, &summary.SeatIncome, &summary.DayPassSales,
			&summary.DayPassIncome, &summary.TotalIncome, &summary.TotalTransactions,
			&summary.AverageIncomePerSeat, &summary.AverageIncomePerDayPass,
		)
		if err != nil {
			return nil, err
		}
		summaries = append(summaries, summary)
	}

	return summaries, nil
}

// GetStationIncomeRange gets income summary for a station over a date range
func (r *RepositoryImpl) GetStationIncomeRange(ctx context.Context, stationID string, startDate, endDate time.Time) ([]StationIncomeSummary, error) {
	query := `
		SELECT 
			st.id as station_id,
			st.station_name,
			stds.date,
			COALESCE(stds.total_seats_booked, 0) as total_seat_bookings,
			COALESCE(stds.total_seat_income, 0.00) as total_seat_income,
			COALESCE(stds.total_day_passes_sold, 0) as total_day_pass_sales,
			COALESCE(stds.total_day_pass_income, 0.00) as total_day_pass_income,
			COALESCE(stds.total_income, 0.00) as total_income,
			COALESCE(stds.total_transactions, 0) as total_transactions,
			COALESCE(stds.active_staff_count, 0) as active_staff_count,
			CASE 
				WHEN COALESCE(stds.active_staff_count, 0) > 0 
				THEN COALESCE(stds.total_income, 0.00) / stds.active_staff_count 
				ELSE 0.00 
			END as avg_income_per_staff,
			CASE 
				WHEN COALESCE(stds.total_seats_booked, 0) > 0 
				THEN COALESCE(stds.total_seat_income, 0.00) / stds.total_seats_booked 
				ELSE 0.00 
			END as avg_income_per_seat,
			CASE 
				WHEN COALESCE(stds.total_day_passes_sold, 0) > 0 
				THEN COALESCE(stds.total_day_pass_income, 0.00) / stds.total_day_passes_sold 
				ELSE 0.00 
			END as avg_income_per_day_pass
		FROM stations st
		LEFT JOIN station_daily_statistics stds ON st.id = stds.station_id 
		WHERE st.id = $1 AND stds.date BETWEEN $2 AND $3
		ORDER BY stds.date DESC
	`

	rows, err := r.db.Query(ctx, query, stationID, startDate, endDate)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var summaries []StationIncomeSummary
	for rows.Next() {
		var summary StationIncomeSummary
		err := rows.Scan(
			&summary.StationID, &summary.StationName, &summary.Date,
			&summary.TotalSeatBookings, &summary.TotalSeatIncome, &summary.TotalDayPassSales,
			&summary.TotalDayPassIncome, &summary.TotalIncome, &summary.TotalTransactions,
			&summary.ActiveStaffCount, &summary.AverageIncomePerStaff,
			&summary.AverageIncomePerSeat, &summary.AverageIncomePerDayPass,
		)
		if err != nil {
			return nil, err
		}
		summaries = append(summaries, summary)
	}

	return summaries, nil
}

// GetAllStaffIncomeForDate gets income summary for all staff members for a specific date
func (r *RepositoryImpl) GetAllStaffIncomeForDate(ctx context.Context, date time.Time) ([]StaffIncomeSummary, error) {
	query := `
		SELECT 
			s.id as staff_id,
			CONCAT(s.first_name, ' ', s.last_name) as staff_name,
			$1::date as date,
			COALESCE(booking_stats.total_seats_booked, 0) as seat_bookings,
			COALESCE(booking_stats.total_seats_booked, 0) * 0.150 as seat_income,
			COALESCE(daypass_stats.total_day_passes_sold, 0) as day_pass_sales,
			COALESCE(daypass_stats.total_day_passes_sold, 0) * 2.0 as day_pass_income,
			(COALESCE(booking_stats.total_seats_booked, 0) * 0.150) + (COALESCE(daypass_stats.total_day_passes_sold, 0) * 2.0) as total_income,
			COALESCE(booking_stats.total_transactions, 0) + COALESCE(daypass_stats.total_transactions, 0) as total_transactions,
			0.150 as avg_income_per_seat,
			2.0 as avg_income_per_day_pass
		FROM staff s
		LEFT JOIN (
			SELECT 
				created_by as staff_id,
				SUM(seats_booked) as total_seats_booked,
				COUNT(*) as total_transactions
			FROM bookings 
			WHERE DATE(created_at) = $1 
				AND booking_status = 'ACTIVE'
				AND created_by IS NOT NULL
			GROUP BY created_by
		) booking_stats ON s.id = booking_stats.staff_id
		LEFT JOIN (
			SELECT 
				created_by as staff_id,
				COUNT(*) as total_day_passes_sold,
				COUNT(*) as total_transactions
			FROM day_passes 
			WHERE DATE(created_at) = $1 
				AND is_active = true
				AND created_by IS NOT NULL
			GROUP BY created_by
		) daypass_stats ON s.id = daypass_stats.staff_id
		WHERE s.is_active = true
			AND (booking_stats.staff_id IS NOT NULL OR daypass_stats.staff_id IS NOT NULL)
		ORDER BY ((COALESCE(booking_stats.total_seats_booked, 0) * 0.150) + (COALESCE(daypass_stats.total_day_passes_sold, 0) * 2.0)) DESC
	`

	rows, err := r.db.Query(ctx, query, date)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var summaries []StaffIncomeSummary
	for rows.Next() {
		var summary StaffIncomeSummary
		err := rows.Scan(
			&summary.StaffID, &summary.StaffName, &summary.Date,
			&summary.SeatBookings, &summary.SeatIncome, &summary.DayPassSales,
			&summary.DayPassIncome, &summary.TotalIncome, &summary.TotalTransactions,
			&summary.AverageIncomePerSeat, &summary.AverageIncomePerDayPass,
		)
		if err != nil {
			return nil, err
		}
		summaries = append(summaries, summary)
	}

	return summaries, nil
}

// GetAllStationIncomeForDate gets income summary for all stations for a specific date
func (r *RepositoryImpl) GetAllStationIncomeForDate(ctx context.Context, date time.Time) ([]StationIncomeSummary, error) {
	query := `
		SELECT 
			st.id as station_id,
			st.station_name,
			stds.date,
			COALESCE(stds.total_seats_booked, 0) as total_seat_bookings,
			COALESCE(stds.total_seat_income, 0.00) as total_seat_income,
			COALESCE(stds.total_day_passes_sold, 0) as total_day_pass_sales,
			COALESCE(stds.total_day_pass_income, 0.00) as total_day_pass_income,
			COALESCE(stds.total_income, 0.00) as total_income,
			COALESCE(stds.total_transactions, 0) as total_transactions,
			COALESCE(stds.active_staff_count, 0) as active_staff_count,
			CASE 
				WHEN COALESCE(stds.active_staff_count, 0) > 0 
				THEN COALESCE(stds.total_income, 0.00) / stds.active_staff_count 
				ELSE 0.00 
			END as avg_income_per_staff,
			CASE 
				WHEN COALESCE(stds.total_seats_booked, 0) > 0 
				THEN COALESCE(stds.total_seat_income, 0.00) / stds.total_seats_booked 
				ELSE 0.00 
			END as avg_income_per_seat,
			CASE 
				WHEN COALESCE(stds.total_day_passes_sold, 0) > 0 
				THEN COALESCE(stds.total_day_pass_income, 0.00) / stds.total_day_passes_sold 
				ELSE 0.00 
			END as avg_income_per_day_pass
		FROM stations st
		LEFT JOIN station_daily_statistics stds ON st.id = stds.station_id AND stds.date = $1
		WHERE st.is_operational = true
		ORDER BY COALESCE(stds.total_income, 0.00) DESC
	`

	rows, err := r.db.Query(ctx, query, date)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var summaries []StationIncomeSummary
	for rows.Next() {
		var summary StationIncomeSummary
		err := rows.Scan(
			&summary.StationID, &summary.StationName, &summary.Date,
			&summary.TotalSeatBookings, &summary.TotalSeatIncome, &summary.TotalDayPassSales,
			&summary.TotalDayPassIncome, &summary.TotalIncome, &summary.TotalTransactions,
			&summary.ActiveStaffCount, &summary.AverageIncomePerStaff,
			&summary.AverageIncomePerSeat, &summary.AverageIncomePerDayPass,
		)
		if err != nil {
			return nil, err
		}
		summaries = append(summaries, summary)
	}

	return summaries, nil
}

// GetStaffTransactionLog gets transaction log for a specific staff member
func (r *RepositoryImpl) GetStaffTransactionLog(ctx context.Context, staffID string, limit int) ([]StaffTransactionLog, error) {
	if limit <= 0 || limit > 1000 {
		limit = 100
	}

	query := `
		SELECT 
			stl.id,
			stl.staff_id,
			CONCAT(s.first_name, ' ', s.last_name) as staff_name,
			stl.transaction_type,
			stl.transaction_id,
			stl.amount,
			stl.quantity,
			stl.station_id,
			st.station_name,
			stl.created_at
		FROM staff_transaction_log stl
		JOIN staff s ON s.id = stl.staff_id
		JOIN stations st ON st.id = stl.station_id
		WHERE stl.staff_id = $1
		ORDER BY stl.created_at DESC
		LIMIT $2
	`

	rows, err := r.db.Query(ctx, query, staffID, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var logs []StaffTransactionLog
	for rows.Next() {
		var log StaffTransactionLog
		err := rows.Scan(
			&log.ID, &log.StaffID, &log.StaffName, &log.TransactionType,
			&log.TransactionID, &log.Amount, &log.Quantity,
			&log.StationID, &log.StationName, &log.CreatedAt,
		)
		if err != nil {
			return nil, err
		}
		logs = append(logs, log)
	}

	return logs, nil
}

// GetStationTransactionLog gets transaction log for a specific station
func (r *RepositoryImpl) GetStationTransactionLog(ctx context.Context, stationID string, limit int) ([]StaffTransactionLog, error) {
	if limit <= 0 || limit > 1000 {
		limit = 100
	}

	query := `
		SELECT 
			stl.id,
			stl.staff_id,
			CONCAT(s.first_name, ' ', s.last_name) as staff_name,
			stl.transaction_type,
			stl.transaction_id,
			stl.amount,
			stl.quantity,
			stl.station_id,
			st.station_name,
			stl.created_at
		FROM staff_transaction_log stl
		JOIN staff s ON s.id = stl.staff_id
		JOIN stations st ON st.id = stl.station_id
		WHERE stl.station_id = $1
		ORDER BY stl.created_at DESC
		LIMIT $2
	`

	rows, err := r.db.Query(ctx, query, stationID, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var logs []StaffTransactionLog
	for rows.Next() {
		var log StaffTransactionLog
		err := rows.Scan(
			&log.ID, &log.StaffID, &log.StaffName, &log.TransactionType,
			&log.TransactionID, &log.Amount, &log.Quantity,
			&log.StationID, &log.StationName, &log.CreatedAt,
		)
		if err != nil {
			return nil, err
		}
		logs = append(logs, log)
	}

	return logs, nil
}

// GetActualIncomeForDate calculates actual income for a specific date
func (r *RepositoryImpl) GetActualIncomeForDate(ctx context.Context, date time.Time) (*ActualIncomeSummary, error) {
	var summary ActualIncomeSummary

	query := `
		WITH today_bookings AS (
			SELECT 
				b.seats_booked,
				q.destination_id,
				COALESCE(r.base_price, 0.0) as base_price
			FROM bookings b
			LEFT JOIN vehicle_queue q ON b.queue_id = q.id
			LEFT JOIN routes r ON r.station_id = q.destination_id
			WHERE DATE(b.created_at) = $1
				AND b.booking_status = 'ACTIVE'
		),
		day_passes_today AS (
			SELECT COUNT(*) as count
			FROM day_passes
			WHERE DATE(created_at) = $1
				AND is_active = true
		)
		SELECT 
			COALESCE(SUM(seats_booked), 0) as seats_booked,
			COALESCE(SUM(seats_booked * (base_price + 0.150)), 0) as actual_seat_income,
			COALESCE((SELECT count FROM day_passes_today), 0) as day_pass_sales,
			COALESCE((SELECT count FROM day_passes_today) * 2.0, 0) as day_pass_income,
			COUNT(*) FILTER (WHERE base_price = 0) as seats_without_destination
		FROM today_bookings;
	`

	err := r.db.QueryRow(ctx, query, date).Scan(
		&summary.SeatsBooked,
		&summary.ActualSeatIncome,
		&summary.DayPassSales,
		&summary.DayPassIncome,
		&summary.SeatsWithoutDestination,
	)
	if err != nil {
		return nil, err
	}

	summary.TotalActualIncome = summary.ActualSeatIncome + summary.DayPassIncome
	summary.Date = date

	return &summary, nil
}

// GetActualIncomeForPeriod calculates actual income for a time period
func (r *RepositoryImpl) GetActualIncomeForPeriod(ctx context.Context, startTime, endTime time.Time) (*ActualIncomeSummary, error) {
	var summary ActualIncomeSummary

	query := `
		WITH period_bookings AS (
			SELECT 
				b.seats_booked,
				q.destination_id,
				COALESCE(r.base_price, 0.0) as base_price
			FROM bookings b
			LEFT JOIN vehicle_queue q ON b.queue_id = q.id
			LEFT JOIN routes r ON r.station_id = q.destination_id
			WHERE b.created_at >= $1::timestamp
				AND b.created_at <= $2::timestamp
				AND b.booking_status = 'ACTIVE'
		),
		day_passes_period AS (
			SELECT COUNT(*) as count
			FROM day_passes
			WHERE created_at >= $1::timestamp
				AND created_at <= $2::timestamp
				AND is_active = true
		)
		SELECT 
			COALESCE(SUM(seats_booked), 0) as seats_booked,
			COALESCE(SUM(seats_booked * (base_price + 0.150)), 0) as actual_seat_income,
			COALESCE((SELECT count FROM day_passes_period), 0) as day_pass_sales,
			COALESCE((SELECT count FROM day_passes_period) * 2.0, 0) as day_pass_income,
			COUNT(*) FILTER (WHERE base_price = 0) as seats_without_destination
		FROM period_bookings;
	`

	err := r.db.QueryRow(ctx, query, startTime, endTime).Scan(
		&summary.SeatsBooked,
		&summary.ActualSeatIncome,
		&summary.DayPassSales,
		&summary.DayPassIncome,
		&summary.SeatsWithoutDestination,
	)
	if err != nil {
		return nil, err
	}

	summary.TotalActualIncome = summary.ActualSeatIncome + summary.DayPassIncome
	summary.Date = startTime

	return &summary, nil
}

// GetActualIncomeForMonth calculates actual income for a specific month
func (r *RepositoryImpl) GetActualIncomeForMonth(ctx context.Context, year, month int) (*ActualIncomeSummary, error) {
	var summary ActualIncomeSummary

	query := `
		WITH month_bookings AS (
			SELECT 
				b.seats_booked,
				q.destination_id,
				COALESCE(r.base_price, 0.0) as base_price
			FROM bookings b
			LEFT JOIN vehicle_queue q ON b.queue_id = q.id
			LEFT JOIN routes r ON r.station_id = q.destination_id
			WHERE EXTRACT(YEAR FROM b.created_at) = $1
				AND EXTRACT(MONTH FROM b.created_at) = $2
				AND b.booking_status = 'ACTIVE'
		),
		day_passes_month AS (
			SELECT COUNT(*) as count
			FROM day_passes
			WHERE EXTRACT(YEAR FROM created_at) = $1
				AND EXTRACT(MONTH FROM created_at) = $2
				AND is_active = true
		)
		SELECT 
			COALESCE(SUM(seats_booked), 0) as seats_booked,
			COALESCE(SUM(seats_booked * (base_price + 0.150)), 0) as actual_seat_income,
			COALESCE((SELECT count FROM day_passes_month), 0) as day_pass_sales,
			COALESCE((SELECT count FROM day_passes_month) * 2.0, 0) as day_pass_income,
			COUNT(*) FILTER (WHERE base_price = 0) as seats_without_destination
		FROM month_bookings;
	`

	err := r.db.QueryRow(ctx, query, year, month).Scan(
		&summary.SeatsBooked,
		&summary.ActualSeatIncome,
		&summary.DayPassSales,
		&summary.DayPassIncome,
		&summary.SeatsWithoutDestination,
	)
	if err != nil {
		return nil, err
	}

	summary.TotalActualIncome = summary.ActualSeatIncome + summary.DayPassIncome
	summary.Date = time.Date(year, time.Month(month), 1, 0, 0, 0, 0, time.UTC)

	return &summary, nil
}

// GetAllStaffIncomeForMonth gets income summary for all staff members for a specific month
func (r *RepositoryImpl) GetAllStaffIncomeForMonth(ctx context.Context, year, month int) ([]StaffIncomeSummary, error) {
	query := `
		SELECT 
			s.id as staff_id,
			CONCAT(s.first_name, ' ', s.last_name) as staff_name,
			$3::date as date,
			COALESCE(booking_stats.total_seats_booked, 0) as seat_bookings,
			COALESCE(booking_stats.total_seats_booked, 0) * 0.150 as seat_income,
			COALESCE(daypass_stats.total_day_passes_sold, 0) as day_pass_sales,
			COALESCE(daypass_stats.total_day_passes_sold, 0) * 2.0 as day_pass_income,
			(COALESCE(booking_stats.total_seats_booked, 0) * 0.150) + (COALESCE(daypass_stats.total_day_passes_sold, 0) * 2.0) as total_income,
			COALESCE(booking_stats.total_transactions, 0) + COALESCE(daypass_stats.total_transactions, 0) as total_transactions,
			0.150 as avg_income_per_seat,
			2.0 as avg_income_per_day_pass
		FROM staff s
		LEFT JOIN (
			SELECT 
				created_by as staff_id,
				SUM(seats_booked) as total_seats_booked,
				COUNT(*) as total_transactions
			FROM bookings 
			WHERE EXTRACT(YEAR FROM created_at) = $1 
				AND EXTRACT(MONTH FROM created_at) = $2
				AND booking_status = 'ACTIVE'
				AND created_by IS NOT NULL
			GROUP BY created_by
		) booking_stats ON s.id = booking_stats.staff_id
		LEFT JOIN (
			SELECT 
				created_by as staff_id,
				COUNT(*) as total_day_passes_sold,
				COUNT(*) as total_transactions
			FROM day_passes 
			WHERE EXTRACT(YEAR FROM created_at) = $1 
				AND EXTRACT(MONTH FROM created_at) = $2
				AND is_active = true
				AND created_by IS NOT NULL
			GROUP BY created_by
		) daypass_stats ON s.id = daypass_stats.staff_id
		WHERE s.is_active = true
			AND (booking_stats.staff_id IS NOT NULL OR daypass_stats.staff_id IS NOT NULL)
		ORDER BY ((COALESCE(booking_stats.total_seats_booked, 0) * 0.150) + (COALESCE(daypass_stats.total_day_passes_sold, 0) * 2.0)) DESC
	`

	// Create a date value for the month
	dateValue := fmt.Sprintf("%d-%02d-01", year, month)
	rows, err := r.db.Query(ctx, query, year, month, dateValue)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var summaries []StaffIncomeSummary
	for rows.Next() {
		var summary StaffIncomeSummary
		err := rows.Scan(
			&summary.StaffID, &summary.StaffName, &summary.Date,
			&summary.SeatBookings, &summary.SeatIncome, &summary.DayPassSales,
			&summary.DayPassIncome, &summary.TotalIncome, &summary.TotalTransactions,
			&summary.AverageIncomePerSeat, &summary.AverageIncomePerDayPass,
		)
		if err != nil {
			return nil, err
		}
		summaries = append(summaries, summary)
	}

	return summaries, nil
}

package booking

import (
	"context"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Repository interface {
	CreateBookingByDestination(ctx context.Context, req CreateBookingByDestinationRequest) (*Booking, error)
	CreateBookingByQueueEntry(ctx context.Context, req CreateBookingByQueueEntryRequest) (*CreateBookingByQueueEntryResponse, error)
	CancelBooking(ctx context.Context, bookingID string, staffID string, reason *string) (*Booking, error)
	ListQueueSnapshot(ctx context.Context, destinationID string) ([]QueueEntry, error)
	GetDestinationByQueueEntry(ctx context.Context, queueEntryID string) (string, error)
	HasTripForQueue(ctx context.Context, queueID string) (bool, error)
	ListTrips(ctx context.Context, limit int) ([]Trip, error)
	CancelOneBookingByQueueEntry(ctx context.Context, queueEntryID string, staffID string) (*Booking, error)
	ListTodayTrips(ctx context.Context, search string, limit int) ([]Trip, error)
	GetTodayTripsCount(ctx context.Context) (int, error)
}

type RepositoryImpl struct {
	db *pgxpool.Pool
}

func NewRepository(db *pgxpool.Pool) Repository { return &RepositoryImpl{db: db} }

// CreateBookingByDestination allocates seats from the first queue entry with sufficient seats, else tries next entries in order
func (r *RepositoryImpl) CreateBookingByDestination(ctx context.Context, req CreateBookingByDestinationRequest) (*Booking, error) {
	if req.Seats <= 0 {
		return nil, fmt.Errorf("seats must be > 0")
	}

	tx, err := r.db.Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	// Always try exact-fit first, then fall back to first-eligible
	var row pgx.Row
	var queueID, vehicleID string
	var pricePerSeat float64
	{
		if req.SubRoute != nil && *req.SubRoute != "" {
			row = tx.QueryRow(ctx, `
                WITH candidate AS (
                    SELECT id
                    FROM vehicle_queue
                    WHERE destination_id=$1 AND queue_type='REGULAR' AND status IN ('WAITING','LOADING','READY')
                      AND sub_route=$3 AND available_seats = $2
                    ORDER BY queue_position ASC
                    LIMIT 1
                    FOR UPDATE
                )
                UPDATE vehicle_queue q
                SET available_seats = q.available_seats - $2
                FROM candidate c
                WHERE q.id = c.id
                RETURNING q.id, q.vehicle_id, q.base_price`, req.DestinationID, req.Seats, *req.SubRoute)
		} else {
			row = tx.QueryRow(ctx, `
                WITH candidate AS (
                    SELECT id
                    FROM vehicle_queue
                    WHERE destination_id=$1 AND queue_type='REGULAR' AND status IN ('WAITING','LOADING','READY')
                      AND available_seats = $2
                    ORDER BY queue_position ASC
                    LIMIT 1
                    FOR UPDATE
                )
                UPDATE vehicle_queue q
                SET available_seats = q.available_seats - $2
                FROM candidate c
                WHERE q.id = c.id
                RETURNING q.id, q.vehicle_id, q.base_price`, req.DestinationID, req.Seats)
		}
		var tmpQ, tmpV string
		var tmpP float64
		if err := row.Scan(&tmpQ, &tmpV, &tmpP); err != nil {
			if err != pgx.ErrNoRows {
				return nil, err
			}
		} else {
			// exact fit success; set for downstream use
			queueID, vehicleID, pricePerSeat = tmpQ, tmpV, tmpP
		}
	}

	// If exact-fit not requested or not found, fall back to first-eligible
	if queueID == "" {
		if req.SubRoute != nil && *req.SubRoute != "" {
			row = tx.QueryRow(ctx, `
                WITH candidate AS (
                    SELECT id
                    FROM vehicle_queue
                    WHERE destination_id=$1 AND queue_type='REGULAR' AND status IN ('WAITING','LOADING','READY')
                      AND sub_route=$3 AND available_seats >= $2
                    ORDER BY queue_position ASC
                    LIMIT 1
                    FOR UPDATE
                )
                UPDATE vehicle_queue q
                SET available_seats = q.available_seats - $2
                FROM candidate c
                WHERE q.id = c.id
                RETURNING q.id, q.vehicle_id, q.base_price`, req.DestinationID, req.Seats, *req.SubRoute)
		} else {
			row = tx.QueryRow(ctx, `
                WITH candidate AS (
                    SELECT id
                    FROM vehicle_queue
                    WHERE destination_id=$1 AND queue_type='REGULAR' AND status IN ('WAITING','LOADING','READY')
                      AND available_seats >= $2
                    ORDER BY queue_position ASC
                    LIMIT 1
                    FOR UPDATE
                )
                UPDATE vehicle_queue q
                SET available_seats = q.available_seats - $2
                FROM candidate c
                WHERE q.id = c.id
                RETURNING q.id, q.vehicle_id, q.base_price`, req.DestinationID, req.Seats)
		}

		if err := row.Scan(&queueID, &vehicleID, &pricePerSeat); err != nil {
			if err == pgx.ErrNoRows {
				return nil, fmt.Errorf("no vehicle with enough seats available for this destination")
			}
			return nil, err
		}
	}

	// Update vehicle status based on seats after deduction
	if _, err := tx.Exec(ctx, `
        UPDATE vehicle_queue SET status = CASE
            WHEN available_seats = 0 THEN 'READY'
            WHEN available_seats < total_seats THEN 'LOADING'
            ELSE 'WAITING'
        END WHERE id = $1`, queueID); err != nil {
		return nil, err
	}

	// Fetch license plate for response (not strictly necessary for booking creation)
	var licensePlate string
	if err := tx.QueryRow(ctx, `SELECT license_plate FROM vehicles WHERE id=$1`, vehicleID).Scan(&licensePlate); err != nil {
		return nil, err
	}

	// If vehicle is now READY (fully booked), create a trip record (needs licensePlate)
	var isReady bool
	var destID, destName string
	var totalSeats, availableSeats int
	if err := tx.QueryRow(ctx, `
        SELECT (available_seats = 0) AS ready, destination_id, destination_name, total_seats, available_seats
        FROM vehicle_queue WHERE id = $1`, queueID).Scan(&isReady, &destID, &destName, &totalSeats, &availableSeats); err != nil {
		return nil, err
	}
	if isReady {
		seatsForTrip := totalSeats
		if _, err := tx.Exec(ctx, `
            INSERT INTO trips (
                id, vehicle_id, license_plate, destination_id, destination_name, queue_id, seats_booked, start_time, created_at
            ) VALUES (
                substr(md5(random()::text || clock_timestamp()::text),1,24),
                $1, $2, $3, $4, $5, $6, NOW(), NOW()
            )`, vehicleID, licensePlate, destID, destName, queueID, seatsForTrip); err != nil {
			return nil, err
		}
	}

	// Create booking (local schema)
	row = tx.QueryRow(ctx, `
        INSERT INTO bookings (
            id, queue_id, seats_booked, total_amount, booking_source, booking_type,
            booking_status, payment_status, payment_method, verification_code,
            is_verified, created_by
        ) VALUES (
            substr(md5(random()::text || clock_timestamp()::text),1,24),
            $1, $2, $3, 'CASH_STATION', 'CASH', 'ACTIVE', 'PAID', 'CASH',
            LPAD(CAST(FLOOR(random()*1000000) AS TEXT), 6, '0'), false, $4
        )
        RETURNING id, created_at`, queueID, req.Seats, float64(req.Seats)*pricePerSeat, req.StaffID)

	var b Booking
	b.VehicleID = vehicleID
	b.LicensePlate = licensePlate
	b.SeatsBooked = req.Seats
	b.TotalAmount = float64(req.Seats) * pricePerSeat
	b.BookingStatus = "ACTIVE"
	b.PaymentStatus = "PAID"
	b.CreatedBy = req.StaffID
	b.QueueID = queueID

	if err := row.Scan(&b.ID, &b.CreatedAt); err != nil {
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}
	return &b, nil
}

func (r *RepositoryImpl) CancelBooking(ctx context.Context, bookingID string, staffID string, reason *string) (*Booking, error) {
	tx, err := r.db.Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	var vehicleID string
	var seats int
	var status string
	if err := tx.QueryRow(ctx, `SELECT COALESCE(queue_id,''), seats_booked, booking_status FROM bookings WHERE id=$1 FOR UPDATE`, bookingID).Scan(&vehicleID, &seats, &status); err != nil {
		return nil, err
	}
	if status != "ACTIVE" {
		return nil, fmt.Errorf("booking already %s", status)
	}

	// Restore seats to that queue entry
	if _, err := tx.Exec(ctx, `UPDATE vehicle_queue SET available_seats = LEAST(total_seats, available_seats + $2) WHERE id=$1`, vehicleID, seats); err != nil {
		return nil, err
	}

	// Update status after cancellation
	if _, err := tx.Exec(ctx, `
        UPDATE vehicle_queue SET status = CASE
            WHEN available_seats = 0 THEN 'READY'
            WHEN available_seats < total_seats THEN 'LOADING'
            ELSE 'WAITING'
        END WHERE id = $1`, vehicleID); err != nil {
		return nil, err
	}

	// If the queue entry is no longer READY after restoration, remove any existing trip tied to this queue entry
	var nowReady bool
	if err := tx.QueryRow(ctx, `SELECT (available_seats = 0) FROM vehicle_queue WHERE id=$1`, vehicleID).Scan(&nowReady); err == nil {
		if !nowReady {
			if _, derr := tx.Exec(ctx, `DELETE FROM trips WHERE queue_id = $1`, vehicleID); derr != nil {
				return nil, derr
			}
		}
	}

	// Mark booking cancelled
	ct, err := tx.Exec(ctx, `UPDATE bookings SET booking_status='CANCELLED', cancelled_at=NOW(), cancelled_by=$2, cancellation_reason=$3 WHERE id=$1`, bookingID, staffID, reason)
	if err != nil {
		return nil, err
	}
	if ct.RowsAffected() == 0 {
		return nil, fmt.Errorf("booking not updated")
	}

	var b Booking
	if err := tx.QueryRow(ctx, `SELECT id, seats_booked, total_amount, booking_status, payment_status, verification_code, created_by, created_at FROM bookings WHERE id=$1`, bookingID).Scan(
		&b.ID, &b.SeatsBooked, &b.TotalAmount, &b.BookingStatus, &b.PaymentStatus, &b.VerificationCode, &b.CreatedBy, &b.CreatedAt,
	); err != nil {
		return nil, err
	}
	b.QueueID = vehicleID

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}
	return &b, nil
}

// CancelOneBookingByQueueEntry finds the most recent ACTIVE booking for a queue entry and cancels it
func (r *RepositoryImpl) CancelOneBookingByQueueEntry(ctx context.Context, queueEntryID string, staffID string) (*Booking, error) {
	var bookingID string
	if err := r.db.QueryRow(ctx, `SELECT id FROM bookings WHERE queue_id=$1 AND booking_status='ACTIVE' ORDER BY created_at DESC LIMIT 1`, queueEntryID).Scan(&bookingID); err != nil {
		if err == pgx.ErrNoRows {
			return nil, fmt.Errorf("no active bookings to cancel for this queue entry")
		}
		return nil, err
	}
	return r.CancelBooking(ctx, bookingID, staffID, nil)
}

// ListQueueSnapshot returns the current queue for a destination (minimal columns for UI refresh)
func (r *RepositoryImpl) ListQueueSnapshot(ctx context.Context, destinationID string) ([]QueueEntry, error) {
	rows, err := r.db.Query(ctx, `
        SELECT q.id, q.vehicle_id, v.license_plate, q.destination_id, q.destination_name,
               q.sub_route, q.sub_route_name, q.queue_type, q.queue_position, q.status,
               q.entered_at, q.available_seats, q.total_seats, q.base_price,
               q.estimated_departure, q.actual_departure
        FROM vehicle_queue q
        JOIN vehicles v ON v.id = q.vehicle_id
        WHERE q.destination_id = $1
        ORDER BY q.queue_position ASC`, destinationID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []QueueEntry
	for rows.Next() {
		var e QueueEntry
		if err := rows.Scan(&e.ID, &e.VehicleID, &e.LicensePlate, &e.DestinationID, &e.DestinationName,
			&e.SubRoute, &e.SubRouteName, &e.QueueType, &e.QueuePosition, &e.Status,
			&e.EnteredAt, &e.AvailableSeats, &e.TotalSeats, &e.BasePrice, &e.EstimatedDeparture, &e.ActualDeparture); err != nil {
			return nil, err
		}
		list = append(list, e)
	}
	return list, nil
}

// HasTripForQueue returns whether a trip exists for the given queue entry
func (r *RepositoryImpl) HasTripForQueue(ctx context.Context, queueID string) (bool, error) {
	var exists bool
	if err := r.db.QueryRow(ctx, `SELECT EXISTS (SELECT 1 FROM trips WHERE queue_id = $1)`, queueID).Scan(&exists); err != nil {
		return false, err
	}
	return exists, nil
}

func (r *RepositoryImpl) ListTrips(ctx context.Context, limit int) ([]Trip, error) {
	if limit <= 0 || limit > 200 {
		limit = 50
	}
	rows, err := r.db.Query(ctx, `
        SELECT id, vehicle_id, license_plate, destination_id, destination_name, queue_id, seats_booked, start_time, created_at
        FROM trips ORDER BY start_time DESC LIMIT $1`, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var list []Trip
	for rows.Next() {
		var t Trip
		if err := rows.Scan(&t.ID, &t.VehicleID, &t.LicensePlate, &t.DestinationID, &t.DestinationName, &t.QueueID, &t.SeatsBooked, &t.VehicleCapacity, &t.BasePrice, &t.StartTime, &t.CreatedAt); err != nil {
			return nil, err
		}
		list = append(list, t)
	}
	return list, nil
}

// ListTodayTrips returns trips for the current day, optionally filtered by license plate
func (r *RepositoryImpl) ListTodayTrips(ctx context.Context, search string, limit int) ([]Trip, error) {
	if limit <= 0 || limit > 200 {
		limit = 100
	}
	var rows pgx.Rows
	var err error
	if search != "" {
		rows, err = r.db.Query(ctx, `
            SELECT id, vehicle_id, license_plate, destination_id, destination_name, queue_id, seats_booked, 
                   vehicle_capacity, base_price, start_time, created_at
            FROM trips
            WHERE start_time::date = CURRENT_DATE AND license_plate ILIKE '%' || $1 || '%'
            ORDER BY start_time DESC
            LIMIT $2
        `, search, limit)
	} else {
		rows, err = r.db.Query(ctx, `
            SELECT id, vehicle_id, license_plate, destination_id, destination_name, queue_id, seats_booked, 
                   vehicle_capacity, base_price, start_time, created_at
            FROM trips
            WHERE start_time::date = CURRENT_DATE
            ORDER BY start_time DESC
            LIMIT $1
        `, limit)
	}
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var list []Trip
	for rows.Next() {
		var t Trip
		if err := rows.Scan(&t.ID, &t.VehicleID, &t.LicensePlate, &t.DestinationID, &t.DestinationName, &t.QueueID, &t.SeatsBooked, &t.VehicleCapacity, &t.BasePrice, &t.StartTime, &t.CreatedAt); err != nil {
			return nil, err
		}
		list = append(list, t)
	}
	return list, nil
}

// CreateBookingByQueueEntry creates individual bookings for each seat on a specific queue entry
func (r *RepositoryImpl) CreateBookingByQueueEntry(ctx context.Context, req CreateBookingByQueueEntryRequest) (*CreateBookingByQueueEntryResponse, error) {
	if req.Seats <= 0 {
		return nil, fmt.Errorf("seats must be > 0")
	}

	tx, err := r.db.Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	// Get staff name for display
	var staffName string
	if req.StaffID != "" {
		err = tx.QueryRow(ctx, `SELECT CONCAT(first_name, ' ', last_name) FROM staff WHERE id = $1`, req.StaffID).Scan(&staffName)
		if err != nil {
			staffName = "Unknown Staff" // Fallback if staff not found
		}
	} else {
		staffName = "System"
	}
	var queueID, vehicleID string
	var pricePerSeat float64
	var availableSeats int
	err = tx.QueryRow(ctx, `
		SELECT id, vehicle_id, base_price, available_seats
		FROM vehicle_queue
		WHERE id = $1 AND queue_type='REGULAR' AND status IN ('WAITING','LOADING','READY')
		FOR UPDATE`, req.QueueEntryID).Scan(&queueID, &vehicleID, &pricePerSeat, &availableSeats)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, fmt.Errorf("queue entry not found or not available for booking")
		}
		return nil, err
	}

	if availableSeats < req.Seats {
		return nil, fmt.Errorf("not enough seats available (requested: %d, available: %d)", req.Seats, availableSeats)
	}

	// Deduct seats from the specific queue entry
	_, err = tx.Exec(ctx, `
		UPDATE vehicle_queue 
		SET available_seats = available_seats - $2
		WHERE id = $1`, queueID, req.Seats)
	if err != nil {
		return nil, err
	}

	// Update vehicle status based on seats after deduction
	if _, err := tx.Exec(ctx, `
		UPDATE vehicle_queue SET status = CASE
			WHEN available_seats = 0 THEN 'READY'
			WHEN available_seats < total_seats THEN 'LOADING'
			ELSE 'WAITING'
		END WHERE id = $1`, queueID); err != nil {
		return nil, err
	}

	// Fetch license plate for response
	var licensePlate string
	if err := tx.QueryRow(ctx, `SELECT license_plate FROM vehicles WHERE id=$1`, vehicleID).Scan(&licensePlate); err != nil {
		return nil, err
	}

	// Check if vehicle is now READY (fully booked) after this booking
	var isReady bool
	var destID, destName string
	var totalSeats, newAvailableSeats int
	if err := tx.QueryRow(ctx, `
		SELECT (available_seats = 0) AS ready, destination_id, destination_name, total_seats, available_seats
		FROM vehicle_queue WHERE id = $1`, queueID).Scan(&isReady, &destID, &destName, &totalSeats, &newAvailableSeats); err != nil {
		return nil, err
	}

	// Get base price from vehicle_queue table
	var basePrice float64
	err = tx.QueryRow(ctx, `SELECT base_price FROM vehicle_queue WHERE id = $1`, queueID).Scan(&basePrice)
	if err != nil {
		basePrice = 15.0 // Default price if not found
	}

	// Check if vehicle is now fully booked after this booking
	var exitPass *ExitPass
	fmt.Printf("DEBUG: Checking if vehicle becomes fully booked - newAvailableSeats: %d\n", newAvailableSeats)
	if newAvailableSeats == 0 {
		fmt.Printf("DEBUG: Vehicle is now fully booked! Creating trip record...\n")
		// Vehicle is now fully booked, create trip record
		tripID := fmt.Sprintf("trip_%d", time.Now().UnixNano())
		currentExitTime := time.Now().In(time.FixedZone("Africa/Tunis", 3600)) // Use Tunisia timezone

		// Create trip record
		fmt.Printf("DEBUG: Inserting trip record with ID: %s, Vehicle: %s, Destination: %s\n", tripID, licensePlate, destName)
		if _, err := tx.Exec(ctx, `
			INSERT INTO trips (
				id, vehicle_id, license_plate, destination_id, destination_name, queue_id, seats_booked, 
				vehicle_capacity, base_price, start_time, created_at
			) VALUES (
				$1, $2, $3, $4, $5, $6, $7, $8, $9, NOW(), NOW()
			)`, tripID, vehicleID, licensePlate, destID, destName, queueID, totalSeats, totalSeats, basePrice); err != nil {
			fmt.Printf("DEBUG: Error creating trip record: %v\n", err)
			return nil, err
		}
		fmt.Printf("DEBUG: Trip record created successfully!\n")

		// Calculate total amount (vehicle capacity * base price without service fees)
		totalPrice := basePrice * float64(totalSeats)

		// Create exit pass information for frontend
		exitPass = &ExitPass{
			ID:              tripID, // Use trip ID as exit pass ID
			QueueID:         queueID,
			VehicleID:       vehicleID,
			LicensePlate:    licensePlate,
			DestinationID:   destID,
			DestinationName: destName,
			CurrentExitTime: currentExitTime,
			TotalPrice:      totalPrice,
			CreatedBy:       req.StaffID,
			CreatedByName:   staffName,
			CreatedAt:       time.Now(),
			// Vehicle and pricing information for ticket generation
			VehicleCapacity: totalSeats, // Vehicle capacity
			BasePrice:       basePrice,  // Base price per seat from route
		}
		fmt.Printf("DEBUG: Exit pass created for frontend\n")
	} else {
		fmt.Printf("DEBUG: Vehicle not fully booked yet - available seats: %d\n", newAvailableSeats)
	}

	// Get the next available seat numbers for this queue based on existing bookings
	var nextSeatNumber int
	err = tx.QueryRow(ctx, `
		SELECT COUNT(*) + 1 
		FROM bookings 
		WHERE queue_id = $1 AND booking_status = 'ACTIVE'`, queueID).Scan(&nextSeatNumber)
	if err != nil {
		nextSeatNumber = 1 // Start from 1 if no bookings exist
	}

	// Create individual bookings for each seat
	var bookings []Booking
	seatPrice := pricePerSeat + 0.2 // base price + 0.2 TND fee per seat

	for i := 0; i < req.Seats; i++ {
		var bookingID string
		var verificationCode string
		var createdAt time.Time
		currentSeatNumber := nextSeatNumber + i

		err = tx.QueryRow(ctx, `
			INSERT INTO bookings (
				id, queue_id, seats_booked, total_amount, booking_source, booking_type,
				booking_status, payment_status, payment_method, verification_code,
				is_verified, created_by
			) VALUES (
				substr(md5(random()::text || clock_timestamp()::text),1,24),
				$1, 1, $2, 'CASH_STATION', 'CASH', 'ACTIVE', 'PAID', 'CASH',
				LPAD(CAST(FLOOR(random()*1000000) AS TEXT), 6, '0'), false, $3
			)
			RETURNING id, verification_code, created_at`, queueID, seatPrice, req.StaffID).Scan(&bookingID, &verificationCode, &createdAt)
		if err != nil {
			return nil, err
		}

		bookings = append(bookings, Booking{
			ID:               bookingID,
			QueueID:          queueID,
			VehicleID:        vehicleID,
			LicensePlate:     licensePlate,
			SeatsBooked:      1,                 // Each booking is for 1 seat
			SeatNumber:       currentSeatNumber, // Individual seat number based on booking order
			TotalAmount:      seatPrice,
			BookingStatus:    "ACTIVE",
			PaymentStatus:    "PAID",
			VerificationCode: verificationCode,
			CreatedBy:        req.StaffID,
			CreatedByName:    staffName, // Staff name instead of just ID
			CreatedAt:        createdAt,
		})
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	// Return response with bookings and exit pass information
	response := &CreateBookingByQueueEntryResponse{
		Bookings:    bookings,
		ExitPass:    exitPass,
		HasExitPass: exitPass != nil,
	}

	return response, nil
}

// GetDestinationByQueueEntry gets the destination ID for a queue entry
func (r *RepositoryImpl) GetDestinationByQueueEntry(ctx context.Context, queueEntryID string) (string, error) {
	var destinationID string
	err := r.db.QueryRow(ctx, `SELECT destination_id FROM vehicle_queue WHERE id = $1`, queueEntryID).Scan(&destinationID)
	if err != nil {
		return "", err
	}
	return destinationID, nil
}

// GetTodayTripsCount returns the count of trips for today
func (r *RepositoryImpl) GetTodayTripsCount(ctx context.Context) (int, error) {
	var count int
	err := r.db.QueryRow(ctx, `SELECT COUNT(*) FROM trips WHERE start_time::date = CURRENT_DATE`).Scan(&count)
	if err != nil {
		return 0, err
	}
	return count, nil
}

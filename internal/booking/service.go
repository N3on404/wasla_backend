package booking

import (
	"context"
	"station-backend/internal/statistics"
	"station-backend/internal/websocket"
)

type Service struct {
	repo        Repository
	ws          *websocket.Hub
	statsLogger *statistics.StatisticsLogger
}

func NewService(repo Repository, ws *websocket.Hub, statsLogger *statistics.StatisticsLogger) *Service {
	return &Service{repo: repo, ws: ws, statsLogger: statsLogger}
}

func (s *Service) CreateBookingByDestination(ctx context.Context, req CreateBookingByDestinationRequest) (*Booking, error) {
	b, err := s.repo.CreateBookingByDestination(ctx, req)
	if err == nil {
		// Log statistics for seat booking
		if s.statsLogger != nil && req.StaffID != "" {
			// For now, use destination ID as station ID (you may need to modify this based on your system)
			stationID := req.DestinationID // This might need to be changed to actual station ID
			s.statsLogger.LogSeatBookingTransactionAsync(req.StaffID, b.ID, stationID, b.SeatsBooked)
		}

		if s.ws != nil {
			// Broadcast booking event
			s.ws.BroadcastToStation(req.DestinationID, "booking_created", b)
			// Also broadcast seats/queue snapshot for clients to refresh
			if queue, qerr := s.repo.ListQueueSnapshot(ctx, req.DestinationID); qerr == nil {
				s.ws.BroadcastToStation(req.DestinationID, "seats_updated", map[string]interface{}{
					"booking": b,
					"queue":   queue,
				})
			}
			// Notify specific vehicle status change
			s.ws.BroadcastToStation(req.DestinationID, "vehicle_status_changed", map[string]interface{}{
				"queueId":   b.QueueID,
				"vehicleId": b.VehicleID,
			})
		}
	}
	return b, err
}

func (s *Service) CreateBookingByQueueEntry(ctx context.Context, req CreateBookingByQueueEntryRequest) (*CreateBookingByQueueEntryResponse, error) {
	response, err := s.repo.CreateBookingByQueueEntry(ctx, req)
	if err == nil {
		// Log statistics for seat bookings
		if s.statsLogger != nil && req.StaffID != "" && len(response.Bookings) > 0 {
			// Get destination ID from the queue entry for station ID
			if destID, derr := s.repo.GetDestinationByQueueEntry(ctx, req.QueueEntryID); derr == nil {
				stationID := destID // This might need to be changed to actual station ID
				// Log each seat booking
				for _, booking := range response.Bookings {
					s.statsLogger.LogSeatBookingTransactionAsync(req.StaffID, booking.ID, stationID, booking.SeatsBooked)
				}
			}
		}

		if s.ws != nil && len(response.Bookings) > 0 {
			// Get destination ID from the queue entry for broadcasting
			if destID, derr := s.repo.GetDestinationByQueueEntry(ctx, req.QueueEntryID); derr == nil {
				// Broadcast booking events for each booking
				for _, booking := range response.Bookings {
					s.ws.BroadcastToStation(destID, "booking_created", booking)
				}
				// Also broadcast seats/queue snapshot for clients to refresh
				if queue, qerr := s.repo.ListQueueSnapshot(ctx, destID); qerr == nil {
					s.ws.BroadcastToStation(destID, "seats_updated", map[string]interface{}{
						"bookings": response.Bookings,
						"queue":    queue,
					})
				}
				// Notify specific vehicle status change
				s.ws.BroadcastToStation(destID, "vehicle_status_changed", map[string]interface{}{
					"queueId":   response.Bookings[0].QueueID,
					"vehicleId": response.Bookings[0].VehicleID,
				})

				// Broadcast exit pass event if created
				if response.HasExitPass && response.ExitPass != nil {
					// Convert ExitPass to ExitPassCreatedEvent for WebSocket
					exitPassEvent := &ExitPassCreatedEvent{
						ExitPassID:       response.ExitPass.ID,
						QueueID:          response.ExitPass.QueueID,
						VehicleID:        response.ExitPass.VehicleID,
						LicensePlate:     response.ExitPass.LicensePlate,
						DestinationID:    response.ExitPass.DestinationID,
						DestinationName:  response.ExitPass.DestinationName,
						PreviousVehicles: []string{}, // Empty array since we removed previous vehicles logic
						TotalPrice:       response.ExitPass.TotalPrice,
						CreatedBy:        response.ExitPass.CreatedBy,
						CreatedByName:    response.ExitPass.CreatedByName,
						CreatedAt:        response.ExitPass.CreatedAt,
					}
					s.ws.BroadcastToStation(destID, "exit_pass_created", exitPassEvent)
				}
			}
		}
	}
	return response, err
}

func (s *Service) CancelBooking(ctx context.Context, bookingID string, staffID string, reason *string) (*Booking, error) {
	b, err := s.repo.CancelBooking(ctx, bookingID, staffID, reason)
	if err == nil && s.ws != nil {
		s.ws.BroadcastToStation("*", "booking_cancelled", map[string]interface{}{"bookingId": bookingID})
		// Also broadcast that vehicle status may have changed due to seat restoration
		s.ws.BroadcastToStation("*", "vehicle_status_changed", map[string]interface{}{
			"queueId":   b.QueueID,
			"vehicleId": b.VehicleID,
		})
		// If READY was broken, announce trip removal
		if hasTrip, terr := s.repo.HasTripForQueue(ctx, b.QueueID); terr == nil && !hasTrip {
			s.ws.BroadcastToStation("*", "trip_removed", map[string]interface{}{
				"queueId": b.QueueID,
			})
		}
	}
	return b, err
}

func (s *Service) ListTrips(ctx context.Context, limit int) ([]Trip, error) {
	return s.repo.ListTrips(ctx, limit)
}

func (s *Service) ListTodayTrips(ctx context.Context, search string, limit int) ([]Trip, error) {
	return s.repo.ListTodayTrips(ctx, search, limit)
}

func (s *Service) GetTodayTripsCount(ctx context.Context, destinationID *string) (int, error) {
	return s.repo.GetTodayTripsCount(ctx, destinationID)
}

func (s *Service) CancelOneBookingByQueueEntry(ctx context.Context, req CancelOneByQueueEntryRequest) (*Booking, error) {
	b, err := s.repo.CancelOneBookingByQueueEntry(ctx, req.QueueEntryID, req.StaffID)
	if err == nil && s.ws != nil {
		if destID, derr := s.repo.GetDestinationByQueueEntry(ctx, req.QueueEntryID); derr == nil {
			s.ws.BroadcastToStation(destID, "booking_cancelled", map[string]interface{}{"bookingId": b.ID})
			// Broadcast seats/queue snapshot for clients to refresh
			if queue, qerr := s.repo.ListQueueSnapshot(ctx, destID); qerr == nil {
				s.ws.BroadcastToStation(destID, "seats_updated", map[string]interface{}{
					"queue": queue,
				})
			}
			// Vehicle status might have changed
			s.ws.BroadcastToStation(destID, "vehicle_status_changed", map[string]interface{}{
				"queueId":   b.QueueID,
				"vehicleId": b.VehicleID,
			})
		}
	}
	return b, err
}

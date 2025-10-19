# Station Statistics System

This system tracks staff income and station statistics for the petrol station booking system with **real-time WebSocket updates**.

## Overview

The statistics system automatically tracks:
- **Seat Bookings**: 0.2 TND per seat booked by staff
- **Day Pass Sales**: 2.0 TND per day pass sold by staff
- **Daily Income**: Total income per staff member per day
- **Station Statistics**: Aggregated statistics per station
- **Real-Time Updates**: Live WebSocket broadcasts of all statistics changes

## Database Schema

The system adds three main tables:

### 1. `staff_daily_statistics`
Tracks daily income for each staff member:
- `staff_id`: Reference to staff member
- `date`: Date of statistics
- `total_seats_booked`: Number of seats booked
- `total_seat_income`: Income from seat bookings (0.2 TND per seat)
- `total_day_passes_sold`: Number of day passes sold
- `total_day_pass_income`: Income from day pass sales (2 TND per pass)
- `total_income`: Total income for the day
- `total_transactions`: Total number of transactions

### 2. `station_daily_statistics`
Tracks daily statistics for each station:
- `station_id`: Reference to station
- `date`: Date of statistics
- Similar fields as staff statistics but aggregated per station
- `active_staff_count`: Number of staff who made transactions

### 3. `staff_transaction_log`
Logs individual transactions:
- `staff_id`: Staff member who made the transaction
- `transaction_type`: "SEAT_BOOKING" or "DAY_PASS_SALE"
- `transaction_id`: Reference to booking or day pass
- `amount`: Transaction amount
- `quantity`: Number of seats or passes
- `station_id`: Station where transaction occurred

## API Endpoints

### Staff Income Endpoints

#### Get Daily Income for Staff Member
```
GET /api/v1/statistics/staff/{staffId}/daily?date=2024-01-15
```

#### Get Today's Income for Staff Member
```
GET /api/v1/statistics/staff/{staffId}/today
```

#### Get Income Range for Staff Member
```
GET /api/v1/statistics/staff/{staffId}/range?startDate=2024-01-01&endDate=2024-01-31
```

#### Get All Staff Income for Date
```
GET /api/v1/statistics/staff/all?date=2024-01-15
```

#### Get Staff Transaction Log
```
GET /api/v1/statistics/staff/{staffId}/transactions?limit=100
```

### Station Income Endpoints

#### Get Daily Income for Station
```
GET /api/v1/statistics/station/{stationId}/daily?date=2024-01-15
```

#### Get Today's Income for Station
```
GET /api/v1/statistics/station/{stationId}/today
```

#### Get Income Range for Station
```
GET /api/v1/statistics/station/{stationId}/range?startDate=2024-01-01&endDate=2024-01-31
```

#### Get All Station Income for Date
```
GET /api/v1/statistics/station/all?date=2024-01-15
```

#### Get Station Transaction Log
```
GET /api/v1/statistics/station/{stationId}/transactions?limit=100
```

### Real-Time WebSocket Endpoint

#### Connect to Real-Time Statistics
```
WS /api/v1/statistics/ws
```

**WebSocket Message Types:**

1. **`staff_income_update`** - Staff income changes
2. **`station_income_update`** - Station statistics changes  
3. **`transaction_update`** - New transactions (seat bookings/day passes)

**Example WebSocket Message:**
```json
{
  "type": "transaction_update",
  "staffId": "staff-uuid",
  "stationId": "station-uuid", 
  "data": {
    "transactionId": "booking-uuid",
    "staffId": "staff-uuid",
    "staffName": "Ahmed Ben Ali",
    "transactionType": "SEAT_BOOKING",
    "amount": 0.4,
    "quantity": 2,
    "stationId": "station-uuid",
    "stationName": "Station Tunis",
    "createdAt": "2024-01-15T10:30:00Z"
  },
  "timestamp": "2024-01-15T10:30:00Z"
}
```

## Response Examples

### Staff Income Summary
```json
{
  "staffId": "staff-uuid",
  "staffName": "Ahmed Ben Ali",
  "date": "2024-01-15T00:00:00Z",
  "seatBookings": 25,
  "seatIncome": 5.0,
  "dayPassSales": 3,
  "dayPassIncome": 6.0,
  "totalIncome": 11.0,
  "totalTransactions": 28,
  "averageIncomePerSeat": 0.2,
  "averageIncomePerDayPass": 2.0
}
```

### Station Income Summary
```json
{
  "stationId": "station-uuid",
  "stationName": "Station Tunis",
  "date": "2024-01-15T00:00:00Z",
  "totalSeatBookings": 150,
  "totalSeatIncome": 30.0,
  "totalDayPassSales": 20,
  "totalDayPassIncome": 40.0,
  "totalIncome": 70.0,
  "totalTransactions": 170,
  "activeStaffCount": 5,
  "averageIncomePerStaff": 14.0,
  "averageIncomePerSeat": 0.2,
  "averageIncomePerDayPass": 2.0
}
```

## Setup Instructions

### 1. Run Database Migration
```bash
# Apply the statistics schema migration
psql -d your_database -f migrations/002_statistics_schema.sql
```

### 2. Start Statistics Service
```bash
# The statistics service runs on port 8005 by default
go run cmd/statistics-service/main.go
```

### 3. Test Real-Time Dashboard
```bash
# Open the dashboard in your browser
open statistics-dashboard.html
# Or navigate to: http://localhost:8006/statistics-dashboard.html
```

### 4. Update Existing Services
The booking and queue services have been updated to automatically log statistics with real-time broadcasting. No additional configuration is needed.

## Automatic Logging

The system automatically logs transactions when:

1. **Seat Bookings**: When staff create bookings through the booking service
2. **Day Pass Sales**: When staff add vehicles to queue (which creates day passes)

The logging happens asynchronously to avoid impacting booking performance, and **real-time updates are broadcast via WebSocket** to all connected clients.

## Database Functions

The system includes PostgreSQL functions for efficient statistics updates:

- `log_staff_transaction()`: Logs a transaction and updates daily statistics
- `update_staff_daily_stats()`: Updates staff daily statistics
- `update_station_daily_statistics()`: Updates station daily statistics

## Usage Examples

### Get Today's Income for All Staff
```bash
curl -H "Authorization: Bearer your-token" \
  "http://localhost:8005/api/v1/statistics/staff/all"
```

### Get Staff Income for Last Week
```bash
curl -H "Authorization: Bearer your-token" \
  "http://localhost:8005/api/v1/statistics/staff/staff-uuid/range?startDate=2024-01-08&endDate=2024-01-14"
```

### Get Station Performance Today
```bash
curl -H "Authorization: Bearer your-token" \
  "http://localhost:8006/api/v1/statistics/station/station-uuid/today"
```

### Connect to Real-Time Updates (JavaScript)
```javascript
const ws = new WebSocket('ws://localhost:8006/api/v1/statistics/ws');

ws.onmessage = function(event) {
  const data = JSON.parse(event.data);
  console.log('Real-time update:', data);
  
  switch(data.type) {
    case 'transaction_update':
      // Handle new transaction
      break;
    case 'staff_income_update':
      // Handle staff income change
      break;
    case 'station_income_update':
      // Handle station statistics change
      break;
  }
};
```

## Notes

- All income calculations are in TND (Tunisian Dinar)
- Statistics are calculated automatically when transactions occur
- **Real-time updates are broadcast via WebSocket** to all connected clients
- The system uses asynchronous logging to maintain performance
- Date parameters use YYYY-MM-DD format
- All REST endpoints require authentication (WebSocket endpoint does not require auth)
- Station ID is currently mapped from destination ID (may need adjustment based on your system)
- **Test the real-time dashboard**: Open `statistics-dashboard.html` in your browser

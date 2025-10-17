package auth

import (
	"context"
	"fmt"

	"station-backend/internal/models"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Repository interface {
	GetStaffByCIN(ctx context.Context, cin string) (*models.Staff, error)
	UpdateLastLogin(ctx context.Context, staffID string) error
}

type RepositoryImpl struct {
	db *pgxpool.Pool
}

func NewRepository(db *pgxpool.Pool) Repository {
	return RepositoryImpl{db: db}
}

func (r RepositoryImpl) GetStaffByCIN(ctx context.Context, cin string) (*models.Staff, error) {
	query := `
		SELECT id, cin, phone_number, first_name, last_name, role, is_active, last_login, created_at, updated_at
		FROM staff 
		WHERE cin = $1 AND is_active = true
	`

	var staff models.Staff
	err := r.db.QueryRow(ctx, query, cin).Scan(
		&staff.ID,
		&staff.CIN,
		&staff.PhoneNumber,
		&staff.FirstName,
		&staff.LastName,
		&staff.Role,
		&staff.IsActive,
		&staff.LastLogin,
		&staff.CreatedAt,
		&staff.UpdatedAt,
	)

	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, fmt.Errorf("staff with CIN %s not found", cin)
		}
		return nil, fmt.Errorf("failed to get staff: %w", err)
	}

	return &staff, nil
}

func (r RepositoryImpl) UpdateLastLogin(ctx context.Context, staffID string) error {
	query := `UPDATE staff SET last_login = NOW() WHERE id = $1`
	
	_, err := r.db.Exec(ctx, query, staffID)
	if err != nil {
		return fmt.Errorf("failed to update last login: %w", err)
	}

	return nil
}

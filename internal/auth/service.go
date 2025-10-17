package auth

import (
	"context"
	"fmt"
	"os"
	"time"

	"station-backend/internal/models"
	"station-backend/pkg/utils"

	"github.com/redis/go-redis/v9"
)

type Service struct {
	repo  Repository
	redis *redis.Client
}

func NewService(repo Repository, redis *redis.Client) *Service {
	return &Service{
		repo:  repo,
		redis: redis,
	}
}

func (s *Service) ValidateStaff(cin string) (*models.Staff, error) {
	ctx := context.Background()

	staff, err := s.repo.GetStaffByCIN(ctx, cin)
	if err != nil {
		return nil, fmt.Errorf("staff not found: %w", err)
	}

	if !staff.IsActive {
		return nil, fmt.Errorf("staff account is inactive")
	}

	// Update last login
	if err := s.repo.UpdateLastLogin(ctx, staff.ID); err != nil {
		// Log error but don't fail the login
		fmt.Printf("Failed to update last login: %v\n", err)
	}

	return staff, nil
}

func (s *Service) GenerateToken(staff *models.Staff) (string, error) {
	secretKey := os.Getenv("JWT_SECRET_KEY")
	if secretKey == "" {
		secretKey = "your-secret-key-change-this-in-production"
	}

	return utils.GenerateJWT(staff.ID, staff.FirstName, staff.LastName, secretKey)
}

func (s *Service) StoreSession(staffID, token string) error {
	ctx := context.Background()

	// Store session in Redis with 24 hour expiration
	expiration := 24 * time.Hour
	return s.redis.Set(ctx, fmt.Sprintf("session:%s", staffID), token, expiration).Err()
}

func (s *Service) ValidateSession(staffID string) (bool, error) {
	ctx := context.Background()

	_, err := s.redis.Get(ctx, fmt.Sprintf("session:%s", staffID)).Result()
	if err == redis.Nil {
		return false, nil // Session not found
	}
	if err != nil {
		return false, err
	}

	return true, nil
}

func (s *Service) Logout(staffID string) error {
	ctx := context.Background()

	return s.redis.Del(ctx, fmt.Sprintf("session:%s", staffID)).Err()
}

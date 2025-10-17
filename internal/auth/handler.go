package auth

import (
	"net/http"

	"station-backend/internal/models"
	"station-backend/pkg/utils"

	"github.com/gin-gonic/gin"
)

type Handler struct {
	service *Service
}

func NewHandler(service *Service) *Handler {
	return &Handler{service: service}
}

func (h *Handler) Login(c *gin.Context) {
	var req models.LoginRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid request format")
		return
	}

	// Validate CIN
	staff, err := h.service.ValidateStaff(req.CIN)
	if err != nil {
		utils.UnauthorizedResponse(c, "Invalid CIN or inactive account")
		return
	}

	// Generate JWT token
	token, err := h.service.GenerateToken(staff)
	if err != nil {
		utils.InternalServerErrorResponse(c, "Token generation failed", err)
		return
	}

	// Store session in Redis
	err = h.service.StoreSession(staff.ID, token)
	if err != nil {
		utils.InternalServerErrorResponse(c, "Session storage failed", err)
		return
	}

	response := models.LoginResponse{
		Token: token,
		Staff: *staff,
	}

	utils.SuccessResponse(c, http.StatusOK, "Login successful", response)
}

func (h *Handler) RefreshToken(c *gin.Context) {
	// Get staff ID from context (set by AuthRequired middleware)
	staffID, exists := c.Get("staff_id")
	if !exists {
		utils.UnauthorizedResponse(c, "Staff ID not found in context")
		return
	}

	// Validate current session
	valid, err := h.service.ValidateSession(staffID.(string))
	if err != nil {
		utils.InternalServerErrorResponse(c, "Session validation failed", err)
		return
	}

	if !valid {
		utils.UnauthorizedResponse(c, "Invalid session")
		return
	}

	// Generate new token
	staff := &models.Staff{ID: staffID.(string)}
	token, err := h.service.GenerateToken(staff)
	if err != nil {
		utils.InternalServerErrorResponse(c, "Token generation failed", err)
		return
	}

	// Update session in Redis
	err = h.service.StoreSession(staff.ID, token)
	if err != nil {
		utils.InternalServerErrorResponse(c, "Session update failed", err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "Token refreshed successfully", gin.H{
		"token": token,
	})
}

func (h *Handler) Logout(c *gin.Context) {
	// Get staff ID from context
	staffID, exists := c.Get("staff_id")
	if !exists {
		utils.UnauthorizedResponse(c, "Staff ID not found in context")
		return
	}

	// Remove session from Redis
	err := h.service.Logout(staffID.(string))
	if err != nil {
		utils.InternalServerErrorResponse(c, "Logout failed", err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "Logout successful", nil)
}

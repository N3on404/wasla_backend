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

// ===== Staff CRUD =====
func (h *Handler) ListStaff(c *gin.Context) {
	list, err := h.service.ListStaff(c.Request.Context())
	if err != nil {
		utils.InternalServerErrorResponse(c, "Failed to list staff", err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "Staff fetched", list)
}

func (h *Handler) GetStaff(c *gin.Context) {
	id := c.Param("id")
	s, err := h.service.GetStaffByID(c.Request.Context(), id)
	if err != nil {
		utils.NotFoundResponse(c, "Staff not found")
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "Staff fetched", s)
}

func (h *Handler) CreateStaff(c *gin.Context) {
	var in struct {
		CIN         string `json:"cin"`
		PhoneNumber string `json:"phoneNumber"`
		FirstName   string `json:"firstName"`
		LastName    string `json:"lastName"`
		Role        string `json:"role"`
	}
	if err := c.ShouldBindJSON(&in); err != nil {
		utils.BadRequestResponse(c, "Invalid request")
		return
	}
	s := models.Staff{CIN: in.CIN, PhoneNumber: in.PhoneNumber, FirstName: in.FirstName, LastName: in.LastName, Role: in.Role, IsActive: true}
	out, err := h.service.CreateStaff(c.Request.Context(), s)
	if err != nil {
		utils.BadRequestResponse(c, err.Error())
		return
	}
	utils.SuccessResponse(c, http.StatusCreated, "Staff created", out)
}

func (h *Handler) UpdateStaff(c *gin.Context) {
	id := c.Param("id")
	var in struct {
		PhoneNumber string `json:"phoneNumber"`
		FirstName   string `json:"firstName"`
		LastName    string `json:"lastName"`
		Role        string `json:"role"`
		IsActive    *bool  `json:"isActive"`
	}
	if err := c.ShouldBindJSON(&in); err != nil {
		utils.BadRequestResponse(c, "Invalid request")
		return
	}
	s := models.Staff{PhoneNumber: in.PhoneNumber, FirstName: in.FirstName, LastName: in.LastName, Role: in.Role}
	if in.IsActive != nil {
		s.IsActive = *in.IsActive
	}
	out, err := h.service.UpdateStaff(c.Request.Context(), id, s)
	if err != nil {
		utils.InternalServerErrorResponse(c, "Failed to update staff", err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "Staff updated", out)
}

func (h *Handler) DeleteStaff(c *gin.Context) {
	id := c.Param("id")
	if err := h.service.DeleteStaff(c.Request.Context(), id); err != nil {
		utils.InternalServerErrorResponse(c, "Failed to delete staff", err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "Staff deleted", nil)
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

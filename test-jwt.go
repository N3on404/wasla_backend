package main

import (
	"fmt"
	"os"
	"station-backend/pkg/utils"
	"github.com/joho/godotenv"
)

func main() {
	// Load environment variables
	if err := godotenv.Load("configs/environment.env"); err != nil {
		fmt.Printf("Warning: Could not load .env file: %v\n", err)
	}

	// Test JWT validation
	token := "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NjA1OTYwNzYsImlhdCI6MTc2MDUwOTY3Niwic3RhZmZfaWQiOiJzdGFmZi0wMDEifQ.2WTeP7xgzw88ijNljZhdIiC02s9hLeyKWvCuTAY3jZk"
	secretKey := os.Getenv("JWT_SECRET_KEY")
	if secretKey == "" {
		secretKey = "your-secret-key-change-this-in-production"
	}

	fmt.Printf("JWT Secret: %s\n", secretKey)
	
	claims, err := utils.ValidateJWT(token, secretKey)
	if err != nil {
		fmt.Printf("JWT validation failed: %v\n", err)
	} else {
		fmt.Printf("JWT validation successful: %+v\n", claims)
	}
}

package main

import (
	"log"
	"os"
	"strconv"
)

type Config struct {
	Port            int
	DatabaseURL     string
	JWTSecret       string
	SupabaseJWKSURL string
}

func LoadConfig() Config {
	port := 8080
	if p := os.Getenv("PORT"); p != "" {
		if v, err := strconv.Atoi(p); err == nil {
			port = v
		}
	}

	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		log.Fatal("DATABASE_URL env var is required")
	}

	jwtSecret := os.Getenv("JWT_SECRET")
	if jwtSecret == "" {
		jwtSecret = os.Getenv("SUPABASE_JWT_SECRET")
	}
	if jwtSecret == "" {
		log.Fatal("JWT_SECRET or SUPABASE_JWT_SECRET env var is required")
	}

	return Config{
		Port:            port,
		DatabaseURL:     dbURL,
		JWTSecret:       jwtSecret,
		SupabaseJWKSURL: os.Getenv("SUPABASE_JWKS_URL"),
	}
}

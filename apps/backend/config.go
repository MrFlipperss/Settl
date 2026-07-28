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
	SupabaseURL     string
	SupabaseAnonKey string
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

	supaURL := os.Getenv("SUPABASE_URL")
	supaAnonKey := os.Getenv("SUPABASE_ANON_KEY")

	if jwtSecret == "" && (supaURL == "" || supaAnonKey == "") {
		log.Fatal("Set JWT_SECRET (or SUPABASE_JWT_SECRET), or both SUPABASE_URL and SUPABASE_ANON_KEY")
	}

	return Config{
		Port:            port,
		DatabaseURL:     dbURL,
		JWTSecret:       jwtSecret,
		SupabaseJWKSURL: os.Getenv("SUPABASE_JWKS_URL"),
		SupabaseURL:     supaURL,
		SupabaseAnonKey: supaAnonKey,
	}
}

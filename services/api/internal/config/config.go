// Package config loads runtime configuration from environment variables.
package config

import (
	"errors"
	"net"
	"os"
	"strings"
)

const (
	defaultAPIHost = "127.0.0.1"
	defaultAPIPort = "8080"
)

// Config contains the values required to start the API.
type Config struct {
	Address     string
	DatabaseDSN string
}

// Load reads and validates the API configuration.
func Load() (Config, error) {
	databaseDSN := strings.TrimSpace(os.Getenv("DATABASE_DSN"))
	if databaseDSN == "" {
		return Config{}, errors.New("DATABASE_DSN is required")
	}

	host := valueOrDefault("API_HOST", defaultAPIHost)
	port := valueOrDefault("API_PORT", defaultAPIPort)

	return Config{
		Address:     net.JoinHostPort(host, port),
		DatabaseDSN: databaseDSN,
	}, nil
}

func valueOrDefault(key, fallback string) string {
	value := strings.TrimSpace(os.Getenv(key))
	if value == "" {
		return fallback
	}
	return value
}

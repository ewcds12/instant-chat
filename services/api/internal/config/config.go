// Package config loads runtime configuration from environment variables.
package config

import (
	"errors"
	"net"
	"os"
	"strconv"
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
	MinIO       MinIOConfig
}

// MinIOConfig contains private object-storage connection settings.
type MinIOConfig struct {
	Endpoint  string
	AccessKey string
	SecretKey string
	Bucket    string
	UseTLS    bool
}

// Load reads and validates the API configuration.
func Load() (Config, error) {
	databaseDSN := strings.TrimSpace(os.Getenv("DATABASE_DSN"))
	if databaseDSN == "" {
		return Config{}, errors.New("DATABASE_DSN is required")
	}

	host := valueOrDefault("API_HOST", defaultAPIHost)
	port := valueOrDefault("API_PORT", defaultAPIPort)
	minioConfig, err := loadMinIOConfig()
	if err != nil {
		return Config{}, err
	}

	return Config{
		Address:     net.JoinHostPort(host, port),
		DatabaseDSN: databaseDSN,
		MinIO:       minioConfig,
	}, nil
}

func loadMinIOConfig() (MinIOConfig, error) {
	endpoint, err := requiredValue("MINIO_ENDPOINT")
	if err != nil {
		return MinIOConfig{}, err
	}
	accessKey, err := requiredValue("MINIO_ACCESS_KEY")
	if err != nil {
		return MinIOConfig{}, err
	}
	secretKey, err := requiredValue("MINIO_SECRET_KEY")
	if err != nil {
		return MinIOConfig{}, err
	}
	bucket, err := requiredValue("MINIO_BUCKET")
	if err != nil {
		return MinIOConfig{}, err
	}
	useTLS, err := strconv.ParseBool(valueOrDefault("MINIO_USE_TLS", "false"))
	if err != nil {
		return MinIOConfig{}, errors.New("MINIO_USE_TLS must be true or false")
	}
	return MinIOConfig{
		Endpoint: endpoint, AccessKey: accessKey, SecretKey: secretKey,
		Bucket: bucket, UseTLS: useTLS,
	}, nil
}

func requiredValue(key string) (string, error) {
	value := strings.TrimSpace(os.Getenv(key))
	if value == "" {
		return "", errors.New(key + " is required")
	}
	return value, nil
}

func valueOrDefault(key, fallback string) string {
	value := strings.TrimSpace(os.Getenv(key))
	if value == "" {
		return fallback
	}
	return value
}

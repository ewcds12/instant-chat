package config

import "testing"

func TestLoadRequiresDatabaseDSN(t *testing.T) {
	t.Setenv("DATABASE_DSN", "")

	if _, err := Load(); err == nil {
		t.Fatal("Load() error = nil, want an error")
	}
}

func TestLoadUsesConfiguredAddress(t *testing.T) {
	t.Setenv("DATABASE_DSN", "user:password@tcp(localhost:3306)/instant_chat")
	t.Setenv("API_HOST", "0.0.0.0")
	t.Setenv("API_PORT", "9090")
	setMinIOEnvironment(t)

	got, err := Load()
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}

	if got.Address != "0.0.0.0:9090" {
		t.Fatalf("Load().Address = %q, want %q", got.Address, "0.0.0.0:9090")
	}
}

func TestLoadRequiresMinIOConfiguration(t *testing.T) {
	t.Setenv("DATABASE_DSN", "user:password@tcp(localhost:3306)/instant_chat")
	t.Setenv("MINIO_ENDPOINT", "")

	if _, err := Load(); err == nil {
		t.Fatal("Load() error = nil, want an error")
	}
}

func setMinIOEnvironment(t *testing.T) {
	t.Helper()
	t.Setenv("MINIO_ENDPOINT", "127.0.0.1:9000")
	t.Setenv("MINIO_ACCESS_KEY", "test-access-key")
	t.Setenv("MINIO_SECRET_KEY", "test-secret-key")
	t.Setenv("MINIO_BUCKET", "instant-chat-files")
	t.Setenv("MINIO_USE_TLS", "false")
}

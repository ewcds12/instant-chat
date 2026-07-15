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

	got, err := Load()
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}

	if got.Address != "0.0.0.0:9090" {
		t.Fatalf("Load().Address = %q, want %q", got.Address, "0.0.0.0:9090")
	}
}

package main

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	_ "github.com/go-sql-driver/mysql"

	"github.com/ewcds12/instant-chat/services/api/internal/auth"
	"github.com/ewcds12/instant-chat/services/api/internal/config"
	"github.com/ewcds12/instant-chat/services/api/internal/health"
	"github.com/ewcds12/instant-chat/services/api/internal/httpapi"
)

const (
	readHeaderTimeout = 5 * time.Second
	readTimeout       = 10 * time.Second
	writeTimeout      = 10 * time.Second
	idleTimeout       = 60 * time.Second
	shutdownTimeout   = 10 * time.Second
	connectionMaxAge  = 5 * time.Minute
	authRateWindow    = time.Minute
	authRateLimit     = 10
)

func main() {
	if err := run(); err != nil {
		slog.Error("API stopped", "error", err)
		os.Exit(1)
	}
}

func run() error {
	cfg, err := config.Load()
	if err != nil {
		return fmt.Errorf("load configuration: %w", err)
	}

	database, err := sql.Open("mysql", cfg.DatabaseDSN)
	if err != nil {
		return fmt.Errorf("open database: %w", err)
	}
	defer database.Close()

	database.SetMaxOpenConns(20)
	database.SetMaxIdleConns(5)
	database.SetConnMaxLifetime(connectionMaxAge)

	mux := http.NewServeMux()
	mux.Handle("GET /api/v1/health", health.NewHandler(database))

	authService, err := auth.NewService(
		auth.NewMySQLRepository(database),
		auth.NewPasswordHasher(),
	)
	if err != nil {
		return fmt.Errorf("initialize authentication: %w", err)
	}
	authHandler := auth.NewHandler(authService)
	registerLimiter := httpapi.NewIPRateLimiter(authRateLimit, authRateWindow)
	loginLimiter := httpapi.NewIPRateLimiter(authRateLimit, authRateWindow)
	mux.Handle("POST /api/v1/auth/register", registerLimiter.Handler(http.HandlerFunc(authHandler.Register)))
	mux.Handle("POST /api/v1/auth/login", loginLimiter.Handler(http.HandlerFunc(authHandler.Login)))
	mux.HandleFunc("POST /api/v1/auth/refresh", authHandler.Refresh)
	mux.HandleFunc("POST /api/v1/auth/logout", authHandler.Logout)
	mux.HandleFunc("GET /api/v1/auth/me", authHandler.CurrentUser)

	server := &http.Server{
		Addr:              cfg.Address,
		Handler:           httpapi.RequestIDMiddleware(mux),
		ReadHeaderTimeout: readHeaderTimeout,
		ReadTimeout:       readTimeout,
		WriteTimeout:      writeTimeout,
		IdleTimeout:       idleTimeout,
	}

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	serverErrors := make(chan error, 1)
	go func() {
		serverErrors <- server.ListenAndServe()
	}()

	slog.Info("API listening", "address", cfg.Address)
	select {
	case err := <-serverErrors:
		if errors.Is(err, http.ErrServerClosed) {
			return nil
		}
		return fmt.Errorf("serve API: %w", err)
	case <-ctx.Done():
		shutdownCtx, cancel := context.WithTimeout(context.Background(), shutdownTimeout)
		defer cancel()
		if err := server.Shutdown(shutdownCtx); err != nil {
			return fmt.Errorf("shutdown API: %w", err)
		}
		return nil
	}
}

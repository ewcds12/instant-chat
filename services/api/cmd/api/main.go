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
	"github.com/ewcds12/instant-chat/services/api/internal/contacts"
	"github.com/ewcds12/instant-chat/services/api/internal/conversations"
	"github.com/ewcds12/instant-chat/services/api/internal/health"
	"github.com/ewcds12/instant-chat/services/api/internal/httpapi"
	"github.com/ewcds12/instant-chat/services/api/internal/messages"
	"github.com/ewcds12/instant-chat/services/api/internal/news"
	"github.com/ewcds12/instant-chat/services/api/internal/posts"
	"github.com/ewcds12/instant-chat/services/api/internal/realtime"
)

const (
	readHeaderTimeout = 5 * time.Second
	readTimeout       = 60 * time.Minute
	writeTimeout      = 60 * time.Minute
	idleTimeout       = 60 * time.Second
	shutdownTimeout   = 10 * time.Second
	connectionMaxAge  = 5 * time.Minute
	authRateWindow    = time.Minute
	authRateLimit     = 10
	messageRateWindow = time.Minute
	messageRateLimit  = 60
	postRateWindow    = time.Minute
	postRateLimit     = 20
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

	fileStorage, err := initializeFileStorage(cfg.MinIO)
	if err != nil {
		return err
	}

	mux := http.NewServeMux()
	mux.Handle("GET /api/v1/health", health.NewHandler(database))

	realtimeHub := realtime.NewHub(realtime.NewMySQLRepository(database))
	defer realtimeHub.Close()
	authService, err := auth.NewService(
		auth.NewMySQLRepository(database),
		auth.NewPasswordHasher(),
	)
	if err != nil {
		return fmt.Errorf("initialize authentication: %w", err)
	}
	authHandler := auth.NewHandler(authService, realtimeHub)
	registerLimiter := httpapi.NewIPRateLimiter(authRateLimit, authRateWindow)
	loginLimiter := httpapi.NewIPRateLimiter(authRateLimit, authRateWindow)
	mux.Handle("POST /api/v1/auth/register", registerLimiter.Handler(http.HandlerFunc(authHandler.Register)))
	mux.Handle("POST /api/v1/auth/login", loginLimiter.Handler(http.HandlerFunc(authHandler.Login)))
	mux.HandleFunc("POST /api/v1/auth/refresh", authHandler.Refresh)
	mux.HandleFunc("POST /api/v1/auth/logout", authHandler.Logout)
	mux.HandleFunc("GET /api/v1/auth/me", authHandler.CurrentUser)
	mux.Handle("PATCH /api/v1/auth/me", authHandler.RequireUser(http.HandlerFunc(authHandler.UpdateProfile)))
	mux.Handle("PUT /api/v1/auth/me/avatar", authHandler.RequireUser(http.HandlerFunc(authHandler.UpdateAvatar)))
	mux.Handle("GET /api/v1/users/{user_id}/avatar", authHandler.RequireUser(http.HandlerFunc(authHandler.Avatar)))

	contactRepository := contacts.NewMySQLRepository(database)
	contactHandler := contacts.NewHandler(contacts.NewService(contactRepository))
	conversationHandler := conversations.NewHandler(conversations.NewService(
		conversations.NewMySQLRepository(database), contactRepository,
	))
	messageHandler := messages.NewHandler(messages.NewService(
		messages.NewMySQLRepository(database, fileStorage),
		realtimeHub,
	))
	postHandler := posts.NewHandler(posts.NewService(
		posts.NewMySQLRepository(database, fileStorage),
	))
	newsHandler := news.NewHandler(news.NewService(&http.Client{Timeout: 5 * time.Second}))
	realtimeHandler := realtime.NewHandler(realtimeHub)
	messageLimiter := httpapi.NewIPRateLimiter(messageRateLimit, messageRateWindow)
	postLimiter := httpapi.NewIPRateLimiter(postRateLimit, postRateWindow)
	protected := func(handler http.HandlerFunc) http.Handler {
		return authHandler.RequireUser(handler)
	}
	mux.Handle("GET /api/v1/users/search", protected(contactHandler.SearchUser))
	mux.Handle("POST /api/v1/contact-requests", protected(contactHandler.SendRequest))
	mux.Handle("GET /api/v1/contact-requests", protected(contactHandler.ListRequests))
	mux.Handle("POST /api/v1/contact-requests/{request_id}/accept", protected(contactHandler.AcceptRequest))
	mux.Handle("POST /api/v1/contact-requests/{request_id}/reject", protected(contactHandler.RejectRequest))
	mux.Handle("POST /api/v1/contact-requests/{request_id}/cancel", protected(contactHandler.CancelRequest))
	mux.Handle("GET /api/v1/contacts", protected(contactHandler.ListContacts))
	mux.Handle("PUT /api/v1/contacts/{user_id}/remark", protected(contactHandler.SetContactRemark))
	mux.Handle("DELETE /api/v1/contacts/{user_id}", protected(contactHandler.RemoveContact))
	mux.Handle("POST /api/v1/conversations", protected(conversationHandler.CreateDirect))
	mux.Handle("GET /api/v1/conversations", protected(conversationHandler.List))
	mux.Handle("POST /api/v1/conversations/{conversation_id}/read", protected(conversationHandler.MarkRead))
	mux.Handle(
		"POST /api/v1/conversations/{conversation_id}/messages",
		authHandler.RequireUser(messageLimiter.Handler(http.HandlerFunc(messageHandler.Send))),
	)
	mux.Handle(
		"POST /api/v1/conversations/{conversation_id}/messages/images",
		authHandler.RequireUser(messageLimiter.Handler(http.HandlerFunc(messageHandler.SendImage))),
	)
	mux.Handle(
		"POST /api/v1/conversations/{conversation_id}/messages/files",
		authHandler.RequireUser(messageLimiter.Handler(http.HandlerFunc(messageHandler.SendFile))),
	)
	mux.Handle(
		"GET /api/v1/conversations/{conversation_id}/messages",
		protected(messageHandler.List),
	)
	mux.Handle(
		"POST /api/v1/conversations/{conversation_id}/messages/{message_id}/recall",
		authHandler.RequireUser(messageLimiter.Handler(http.HandlerFunc(messageHandler.Recall))),
	)
	mux.Handle(
		"DELETE /api/v1/conversations/{conversation_id}/messages/{message_id}",
		authHandler.RequireUser(messageLimiter.Handler(http.HandlerFunc(messageHandler.Delete))),
	)
	mux.Handle("GET /api/v1/message-images/{image_id}", protected(messageHandler.Image))
	mux.Handle("GET /api/v1/message-files/{file_id}", protected(messageHandler.File))
	mux.Handle("GET /api/v1/posts", protected(postHandler.List))
	mux.Handle("GET /api/v1/news/daily", protected(newsHandler.Daily))
	mux.Handle(
		"POST /api/v1/posts",
		authHandler.RequireUser(postLimiter.Handler(http.HandlerFunc(postHandler.Create))),
	)
	mux.Handle("DELETE /api/v1/posts/{post_id}", protected(postHandler.Delete))
	mux.Handle("GET /api/v1/posts/{post_id}/comments", protected(postHandler.ListComments))
	mux.Handle(
		"POST /api/v1/posts/{post_id}/comments",
		authHandler.RequireUser(postLimiter.Handler(http.HandlerFunc(postHandler.CreateComment))),
	)
	mux.Handle(
		"DELETE /api/v1/posts/{post_id}/comments/{comment_id}",
		protected(postHandler.DeleteComment),
	)
	mux.Handle(
		"POST /api/v1/posts/{post_id}/reports",
		authHandler.RequireUser(postLimiter.Handler(http.HandlerFunc(postHandler.Report))),
	)
	mux.Handle("GET /api/v1/post-images/{image_id}", protected(postHandler.Image))
	mux.Handle("GET /api/v1/realtime", protected(realtimeHandler.Connect))

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
		realtimeHub.Close()
		shutdownCtx, cancel := context.WithTimeout(context.Background(), shutdownTimeout)
		defer cancel()
		if err := server.Shutdown(shutdownCtx); err != nil {
			return fmt.Errorf("shutdown API: %w", err)
		}
		return nil
	}
}

package main

import (
	"context"
	"fmt"
	"time"

	"github.com/ewcds12/instant-chat/services/api/internal/config"
	"github.com/ewcds12/instant-chat/services/api/internal/uploads"
)

const objectStorageStartupTimeout = 15 * time.Second

func initializeFileStorage(cfg config.MinIOConfig) (*uploads.MinIOStore, error) {
	storage, err := uploads.NewMinIOStore(
		cfg.Endpoint,
		cfg.AccessKey,
		cfg.SecretKey,
		cfg.Bucket,
		cfg.UseTLS,
	)
	if err != nil {
		return nil, err
	}
	ctx, cancel := context.WithTimeout(context.Background(), objectStorageStartupTimeout)
	defer cancel()
	if err := storage.EnsureBucket(ctx); err != nil {
		return nil, fmt.Errorf("initialize file object storage: %w", err)
	}
	return storage, nil
}

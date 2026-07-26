// Package uploads provides private object storage for message attachments.
package uploads

import (
	"context"
	"fmt"
	"io"

	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
)

// MinIOStore stores private objects in one S3-compatible bucket.
type MinIOStore struct {
	client *minio.Client
	bucket string
}

// NewMinIOStore creates a MinIO-backed object store without network I/O.
func NewMinIOStore(
	endpoint string,
	accessKey string,
	secretKey string,
	bucket string,
	useTLS bool,
) (*MinIOStore, error) {
	client, err := minio.New(endpoint, &minio.Options{
		Creds:  credentials.NewStaticV4(accessKey, secretKey, ""),
		Secure: useTLS,
		Region: "us-east-1",
	})
	if err != nil {
		return nil, fmt.Errorf("create MinIO client: %w", err)
	}
	return &MinIOStore{client: client, bucket: bucket}, nil
}

// EnsureBucket creates the private attachment bucket when it is missing.
func (s *MinIOStore) EnsureBucket(ctx context.Context) error {
	exists, err := s.client.BucketExists(ctx, s.bucket)
	if err != nil {
		return fmt.Errorf("check MinIO bucket: %w", err)
	}
	if exists {
		return nil
	}
	if err := s.client.MakeBucket(ctx, s.bucket, minio.MakeBucketOptions{}); err != nil {
		return fmt.Errorf("create MinIO bucket: %w", err)
	}
	return nil
}

// Put streams one object into the private attachment bucket.
func (s *MinIOStore) Put(
	ctx context.Context,
	key string,
	reader io.Reader,
	size int64,
	contentType string,
) error {
	_, err := s.client.PutObject(
		ctx,
		s.bucket,
		key,
		reader,
		size,
		minio.PutObjectOptions{ContentType: contentType},
	)
	if err != nil {
		return fmt.Errorf("put MinIO object: %w", err)
	}
	return nil
}

// Open returns a readable object after verifying that it exists.
func (s *MinIOStore) Open(ctx context.Context, key string) (io.ReadCloser, error) {
	object, err := s.client.GetObject(ctx, s.bucket, key, minio.GetObjectOptions{})
	if err != nil {
		return nil, fmt.Errorf("get MinIO object: %w", err)
	}
	if _, err := object.Stat(); err != nil {
		_ = object.Close()
		return nil, fmt.Errorf("stat MinIO object: %w", err)
	}
	return object, nil
}

// Delete removes one object from the private attachment bucket.
func (s *MinIOStore) Delete(ctx context.Context, key string) error {
	if err := s.client.RemoveObject(
		ctx,
		s.bucket,
		key,
		minio.RemoveObjectOptions{},
	); err != nil {
		return fmt.Errorf("delete MinIO object: %w", err)
	}
	return nil
}

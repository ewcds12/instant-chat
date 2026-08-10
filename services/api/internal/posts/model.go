// Package posts manages the global authenticated public post feed.
package posts

import (
	"context"
	"errors"
	"io"
	"time"
)

var (
	// ErrPostNotFound hides whether a post exists from unauthorized callers.
	ErrPostNotFound = errors.New("post not found")
	// ErrPostImageNotFound hides whether a post image exists from unauthorized callers.
	ErrPostImageNotFound = errors.New("post image not found")
	// ErrUserNotFound indicates that a block target does not exist.
	ErrUserNotFound = errors.New("user not found")
)

// InputError describes one invalid post request field.
type InputError struct {
	Message string
}

func (e *InputError) Error() string { return e.Message }

// Author is the public identity attached to a post.
type Author struct {
	ID          uint64
	Username    string
	DisplayName string
	HasAvatar   bool
	CreatedAt   time.Time
}

// Post is one globally visible authenticated post.
type Post struct {
	ID        uint64
	Author    Author
	Body      string
	Images    []Image
	CreatedAt time.Time
}

// Image is public metadata for one post image.
type Image struct {
	ID          uint64
	Position    uint8
	ContentType string
	ByteSize    uint32
}

// ImageUpload is one validated post image candidate.
type ImageUpload struct {
	ContentType string
	Data        []byte
}

// ImageFile is one authorized post image stream.
type ImageFile struct {
	ContentType string
	ByteSize    uint32
	Content     io.ReadCloser
}

// Page is one descending global feed page.
type Page struct {
	Posts      []Post
	NextCursor *uint64
}

// BlockedUser is one user hidden from the current user's feed.
type BlockedUser struct {
	Author
}

// ObjectStore persists private post image bytes.
type ObjectStore interface {
	Put(context.Context, string, io.Reader, int64, string) error
	Open(context.Context, string) (io.ReadCloser, error)
	Delete(context.Context, string) error
}

// Repository defines persistence required by post use cases.
type Repository interface {
	Create(context.Context, uint64, string, []ImageUpload) (Post, error)
	List(context.Context, uint64, *uint64, int) ([]Post, error)
	Image(context.Context, uint64, uint64) (ImageFile, error)
	Delete(context.Context, uint64, uint64) error
	Report(context.Context, uint64, uint64, string) error
	Block(context.Context, uint64, uint64) error
	Unblock(context.Context, uint64, uint64) error
	ListBlocked(context.Context, uint64) ([]BlockedUser, error)
}

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
	// ErrCommentNotFound hides whether a comment exists from unauthorized callers.
	ErrCommentNotFound = errors.New("post comment not found")
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
	ID           uint64
	Author       Author
	Body         string
	Images       []Image
	CommentCount uint64
	CreatedAt    time.Time
}

// Comment is one authenticated public response to a post.
type Comment struct {
	ID              uint64
	PostID          uint64
	ParentCommentID *uint64
	Author          Author
	Body            string
	CreatedAt       time.Time
}

// CommentPage is one descending comment page.
type CommentPage struct {
	Comments   []Comment
	NextCursor *uint64
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

// ObjectStore persists private post image bytes.
type ObjectStore interface {
	Put(context.Context, string, io.Reader, int64, string) error
	Open(context.Context, string) (io.ReadCloser, error)
	Delete(context.Context, string) error
}

// Repository defines persistence required by post use cases.
type Repository interface {
	Create(context.Context, uint64, string, []ImageUpload) (Post, error)
	List(context.Context, *uint64, int) ([]Post, error)
	Image(context.Context, uint64) (ImageFile, error)
	Delete(context.Context, uint64, uint64) error
	Report(context.Context, uint64, uint64, string) error
	CreateComment(context.Context, uint64, uint64, *uint64, string) (Comment, error)
	ListComments(context.Context, uint64, *uint64, int) ([]Comment, error)
	DeleteComment(context.Context, uint64, uint64, uint64) error
}

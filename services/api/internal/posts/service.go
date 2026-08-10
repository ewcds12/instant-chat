package posts

import (
	"context"
	"strings"
	"unicode/utf8"
)

const (
	defaultPageSize  = 20
	maximumPageSize  = 50
	maximumBodyRunes = 1000
	maximumImages    = 4
	maximumImageSize = 15 * 1024 * 1024
	maximumReason    = 500
)

var allowedImageTypes = map[string]struct{}{
	"image/gif":  {},
	"image/jpeg": {},
	"image/png":  {},
	"image/webp": {},
}

// Service applies public post business rules.
type Service struct {
	repository Repository
}

// NewService creates a public post service.
func NewService(repository Repository) *Service {
	return &Service{repository: repository}
}

// Create validates and persists one public post.
func (s *Service) Create(
	ctx context.Context,
	authorID uint64,
	body string,
	images []ImageUpload,
) (Post, error) {
	body = strings.TrimSpace(body)
	if body == "" && len(images) == 0 {
		return Post{}, &InputError{Message: "Add text or at least one photo."}
	}
	if !utf8.ValidString(body) || utf8.RuneCountInString(body) > maximumBodyRunes {
		return Post{}, &InputError{Message: "Post text must contain at most 1,000 characters."}
	}
	if len(images) > maximumImages {
		return Post{}, &InputError{Message: "A post can contain up to 4 photos."}
	}
	for _, image := range images {
		if _, allowed := allowedImageTypes[image.ContentType]; !allowed {
			return Post{}, &InputError{Message: "Photos must be PNG, JPEG, GIF, or WebP images."}
		}
		if len(image.Data) == 0 || len(image.Data) > maximumImageSize {
			return Post{}, &InputError{Message: "Each photo must be no larger than 15 MB."}
		}
	}
	return s.repository.Create(ctx, authorID, body, images)
}

// List returns one descending global feed page.
func (s *Service) List(
	ctx context.Context,
	viewerID uint64,
	before *uint64,
	limit int,
) (Page, error) {
	if limit == 0 {
		limit = defaultPageSize
	}
	if limit < 1 || limit > maximumPageSize {
		return Page{}, &InputError{Message: "Limit must be between 1 and 50."}
	}
	posts, err := s.repository.List(ctx, viewerID, before, limit)
	if err != nil {
		return Page{}, err
	}
	var next *uint64
	if len(posts) == limit {
		cursor := posts[len(posts)-1].ID
		next = &cursor
	}
	return Page{Posts: posts, NextCursor: next}, nil
}

// Image opens one post image visible to the current user.
func (s *Service) Image(ctx context.Context, viewerID, imageID uint64) (ImageFile, error) {
	return s.repository.Image(ctx, viewerID, imageID)
}

// Delete permanently removes one post owned by the current user.
func (s *Service) Delete(ctx context.Context, authorID, postID uint64) error {
	return s.repository.Delete(ctx, authorID, postID)
}

// Report records or updates the current user's report for one post.
func (s *Service) Report(
	ctx context.Context,
	reporterID, postID uint64,
	reason string,
) error {
	reason = strings.TrimSpace(reason)
	if reason == "" || !utf8.ValidString(reason) || utf8.RuneCountInString(reason) > maximumReason {
		return &InputError{Message: "Report reason must contain 1 to 500 characters."}
	}
	return s.repository.Report(ctx, reporterID, postID, reason)
}

// Block hides one user's posts from the current user's feed.
func (s *Service) Block(ctx context.Context, blockerID, blockedUserID uint64) error {
	if blockerID == blockedUserID {
		return &InputError{Message: "You cannot block yourself."}
	}
	return s.repository.Block(ctx, blockerID, blockedUserID)
}

// Unblock restores one user's posts to the current user's feed.
func (s *Service) Unblock(ctx context.Context, blockerID, blockedUserID uint64) error {
	return s.repository.Unblock(ctx, blockerID, blockedUserID)
}

// ListBlocked returns users hidden from the current user's feed.
func (s *Service) ListBlocked(ctx context.Context, blockerID uint64) ([]BlockedUser, error) {
	return s.repository.ListBlocked(ctx, blockerID)
}

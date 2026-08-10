package posts

import (
	"context"
	"errors"
	"testing"
)

type fakeRepository struct {
	createdBody   string
	createdImages []ImageUpload
	listedLimit   int
	posts         []Post
	reported      string
	blockedUserID uint64
	err           error
}

func (f *fakeRepository) Create(
	_ context.Context,
	_ uint64,
	body string,
	images []ImageUpload,
) (Post, error) {
	f.createdBody = body
	f.createdImages = images
	return Post{ID: 9, Body: body}, f.err
}

func (f *fakeRepository) List(
	_ context.Context,
	_ uint64,
	_ *uint64,
	limit int,
) ([]Post, error) {
	f.listedLimit = limit
	return f.posts, f.err
}

func (f *fakeRepository) Image(context.Context, uint64, uint64) (ImageFile, error) {
	return ImageFile{}, f.err
}

func (f *fakeRepository) Delete(context.Context, uint64, uint64) error { return f.err }

func (f *fakeRepository) Report(_ context.Context, _, _ uint64, reason string) error {
	f.reported = reason
	return f.err
}

func (f *fakeRepository) Block(_ context.Context, _, userID uint64) error {
	f.blockedUserID = userID
	return f.err
}

func (f *fakeRepository) Unblock(context.Context, uint64, uint64) error { return f.err }

func (f *fakeRepository) ListBlocked(context.Context, uint64) ([]BlockedUser, error) {
	return nil, f.err
}

func TestServiceCreateTrimsTextAndAcceptsPhoto(t *testing.T) {
	repository := &fakeRepository{}
	service := NewService(repository)
	image := ImageUpload{ContentType: "image/png", Data: []byte{1, 2, 3}}

	post, err := service.Create(context.Background(), 7, "  Hello world  ", []ImageUpload{image})

	if err != nil {
		t.Fatalf("Create() error = %v", err)
	}
	if post.ID != 9 || repository.createdBody != "Hello world" {
		t.Fatalf("post = %+v, stored body = %q", post, repository.createdBody)
	}
	if len(repository.createdImages) != 1 {
		t.Fatalf("stored images = %d, want 1", len(repository.createdImages))
	}
}

func TestServiceCreateRejectsEmptyPost(t *testing.T) {
	service := NewService(&fakeRepository{})

	_, err := service.Create(context.Background(), 7, "   ", nil)

	var inputError *InputError
	if !errors.As(err, &inputError) {
		t.Fatalf("Create() error = %v, want InputError", err)
	}
}

func TestServiceCreateRejectsTooManyPhotos(t *testing.T) {
	service := NewService(&fakeRepository{})
	images := make([]ImageUpload, 5)
	for index := range images {
		images[index] = ImageUpload{ContentType: "image/jpeg", Data: []byte{1}}
	}

	_, err := service.Create(context.Background(), 7, "Photos", images)

	var inputError *InputError
	if !errors.As(err, &inputError) {
		t.Fatalf("Create() error = %v, want InputError", err)
	}
}

func TestServiceListUsesDefaultLimitAndReturnsCursor(t *testing.T) {
	posts := make([]Post, defaultPageSize)
	for index := range posts {
		posts[index].ID = uint64(100 - index)
	}
	repository := &fakeRepository{posts: posts}
	service := NewService(repository)

	page, err := service.List(context.Background(), 7, nil, 0)

	if err != nil {
		t.Fatalf("List() error = %v", err)
	}
	if repository.listedLimit != defaultPageSize {
		t.Fatalf("limit = %d, want %d", repository.listedLimit, defaultPageSize)
	}
	if page.NextCursor == nil || *page.NextCursor != posts[len(posts)-1].ID {
		t.Fatalf("next cursor = %v", page.NextCursor)
	}
}

func TestServiceReportTrimsReason(t *testing.T) {
	repository := &fakeRepository{}
	service := NewService(repository)

	err := service.Report(context.Background(), 7, 12, "  Spam  ")

	if err != nil || repository.reported != "Spam" {
		t.Fatalf("Report() error = %v, reason = %q", err, repository.reported)
	}
}

func TestServiceBlockRejectsCurrentUser(t *testing.T) {
	repository := &fakeRepository{}
	service := NewService(repository)

	err := service.Block(context.Background(), 7, 7)

	var inputError *InputError
	if !errors.As(err, &inputError) || repository.blockedUserID != 0 {
		t.Fatalf("Block() error = %v, blocked ID = %d", err, repository.blockedUserID)
	}
}

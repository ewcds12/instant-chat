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
	commentBody   string
	commentParent *uint64
	comments      []Comment
	commentLimit  int
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
	_ *uint64,
	limit int,
) ([]Post, error) {
	f.listedLimit = limit
	return f.posts, f.err
}

func (f *fakeRepository) Image(context.Context, uint64) (ImageFile, error) {
	return ImageFile{}, f.err
}

func (f *fakeRepository) Delete(context.Context, uint64, uint64) error { return f.err }

func (f *fakeRepository) Report(_ context.Context, _, _ uint64, reason string) error {
	f.reported = reason
	return f.err
}

func (f *fakeRepository) CreateComment(
	_ context.Context,
	_, _ uint64,
	parentCommentID *uint64,
	body string,
) (Comment, error) {
	f.commentBody = body
	f.commentParent = parentCommentID
	return Comment{ID: 21, Body: body}, f.err
}

func (f *fakeRepository) ListComments(
	_ context.Context,
	_ uint64,
	_ *uint64,
	limit int,
) ([]Comment, error) {
	f.commentLimit = limit
	return f.comments, f.err
}

func (f *fakeRepository) DeleteComment(context.Context, uint64, uint64, uint64) error {
	return f.err
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

	page, err := service.List(context.Background(), nil, 0)

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

func TestServiceCreateCommentTrimsBody(t *testing.T) {
	repository := &fakeRepository{}
	service := NewService(repository)

	comment, err := service.CreateComment(context.Background(), 7, 41, nil, "  Nice post.  ")

	if err != nil || comment.ID != 21 || repository.commentBody != "Nice post." {
		t.Fatalf("CreateComment() = %+v, %v; body = %q", comment, err, repository.commentBody)
	}
}

func TestServiceCreateCommentRejectsEmptyBody(t *testing.T) {
	service := NewService(&fakeRepository{})

	_, err := service.CreateComment(context.Background(), 7, 41, nil, "   ")

	var inputError *InputError
	if !errors.As(err, &inputError) {
		t.Fatalf("CreateComment() error = %v, want InputError", err)
	}
}

func TestServiceCreateReplyPreservesParent(t *testing.T) {
	repository := &fakeRepository{}
	service := NewService(repository)
	parentID := uint64(20)

	_, err := service.CreateComment(context.Background(), 7, 41, &parentID, "Reply")

	if err != nil || repository.commentParent == nil || *repository.commentParent != parentID {
		t.Fatalf("CreateComment() error = %v, parent = %v", err, repository.commentParent)
	}
}

func TestServiceListCommentsUsesDefaultLimitAndReturnsCursor(t *testing.T) {
	comments := make([]Comment, defaultCommentPageSize)
	for index := range comments {
		comments[index].ID = uint64(100 - index)
	}
	repository := &fakeRepository{comments: comments}
	service := NewService(repository)

	page, err := service.ListComments(context.Background(), 41, nil, 0)

	if err != nil {
		t.Fatalf("ListComments() error = %v", err)
	}
	if repository.commentLimit != defaultCommentPageSize {
		t.Fatalf("limit = %d, want %d", repository.commentLimit, defaultCommentPageSize)
	}
	if page.NextCursor == nil || *page.NextCursor != comments[len(comments)-1].ID {
		t.Fatalf("next cursor = %v", page.NextCursor)
	}
}

func TestServiceListCommentsCursorUsesLastRoot(t *testing.T) {
	parentID := uint64(100)
	comments := []Comment{
		{ID: 100},
		{ID: 101, ParentCommentID: &parentID},
	}
	repository := &fakeRepository{comments: comments}
	service := NewService(repository)

	page, err := service.ListComments(context.Background(), 41, nil, 1)

	if err != nil || page.NextCursor == nil || *page.NextCursor != 100 {
		t.Fatalf("ListComments() = %+v, %v", page, err)
	}
}

package posts

import (
	"bytes"
	"context"
	"encoding/json"
	"io"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/ewcds12/instant-chat/services/api/internal/auth"
	"github.com/ewcds12/instant-chat/services/api/internal/httpapi"
)

type stubPostService struct {
	userID        uint64
	body          string
	images        []ImageUpload
	commentPostID uint64
	commentBody   string
	commentID     uint64
}

func (s *stubPostService) Create(
	_ context.Context,
	userID uint64,
	body string,
	images []ImageUpload,
) (Post, error) {
	s.userID, s.body, s.images = userID, body, images
	return testPost(), nil
}

func (s *stubPostService) List(
	_ context.Context,
	_ *uint64,
	_ int,
) (Page, error) {
	cursor := uint64(40)
	return Page{Posts: []Post{testPost()}, NextCursor: &cursor}, nil
}

func (s *stubPostService) Image(context.Context, uint64) (ImageFile, error) {
	return ImageFile{ContentType: "image/png", ByteSize: 3, Content: io.NopCloser(strings.NewReader("PNG"))}, nil
}

func (s *stubPostService) Delete(context.Context, uint64, uint64) error { return nil }

func (s *stubPostService) Report(context.Context, uint64, uint64, string) error { return nil }

func (s *stubPostService) CreateComment(
	_ context.Context,
	userID, postID uint64,
	body string,
) (Comment, error) {
	s.userID, s.commentPostID, s.commentBody = userID, postID, body
	return testComment(), nil
}

func (s *stubPostService) ListComments(
	context.Context,
	uint64,
	*uint64,
	int,
) (CommentPage, error) {
	cursor := uint64(20)
	return CommentPage{Comments: []Comment{testComment()}, NextCursor: &cursor}, nil
}

func (s *stubPostService) DeleteComment(_ context.Context, userID, postID, commentID uint64) error {
	s.userID, s.commentPostID, s.commentID = userID, postID, commentID
	return nil
}

type stubAuthService struct{}

func (stubAuthService) Register(context.Context, string, string, string) (auth.Session, error) {
	return auth.Session{}, nil
}
func (stubAuthService) Login(context.Context, string, string) (auth.Session, error) {
	return auth.Session{}, nil
}
func (stubAuthService) Refresh(context.Context, string) (auth.Session, error) {
	return auth.Session{}, nil
}
func (stubAuthService) CurrentUser(context.Context, string) (auth.User, error) {
	return auth.User{ID: 7, Username: "retro_user"}, nil
}
func (stubAuthService) UpdateProfile(context.Context, uint64, auth.ProfileInput) (auth.User, error) {
	return auth.User{}, nil
}
func (stubAuthService) UpdateAvatar(context.Context, uint64, auth.AvatarUpload) (auth.User, error) {
	return auth.User{}, nil
}
func (stubAuthService) Avatar(context.Context, uint64) (auth.Avatar, error) {
	return auth.Avatar{}, nil
}
func (stubAuthService) Logout(context.Context, string, string) error { return nil }

func authenticated(next http.Handler) http.Handler {
	authHandler := auth.NewHandler(stubAuthService{})
	return httpapi.RequestIDMiddleware(authHandler.RequireUser(next))
}

func TestHandlerCreateAcceptsTextAndPhoto(t *testing.T) {
	service := &stubPostService{}
	handler := NewHandler(service)
	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)
	_ = writer.WriteField("body", "Hello world")
	file, err := writer.CreateFormFile("images", "photo.png")
	if err != nil {
		t.Fatal(err)
	}
	_, _ = file.Write([]byte{0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a})
	_ = writer.Close()
	request := httptest.NewRequest(http.MethodPost, "/api/v1/posts", body)
	request.Header.Set("Authorization", "Bearer token")
	request.Header.Set("Content-Type", writer.FormDataContentType())
	recorder := httptest.NewRecorder()

	authenticated(http.HandlerFunc(handler.Create)).ServeHTTP(recorder, request)

	if recorder.Code != http.StatusCreated {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body.String())
	}
	if service.userID != 7 || service.body != "Hello world" || len(service.images) != 1 {
		t.Fatalf("user = %d, body = %q, images = %d", service.userID, service.body, len(service.images))
	}
}

func TestHandlerListReturnsStringCursorAndImagePosition(t *testing.T) {
	service := &stubPostService{}
	handler := NewHandler(service)
	request := httptest.NewRequest(http.MethodGet, "/api/v1/posts", nil)
	request.Header.Set("Authorization", "Bearer token")
	recorder := httptest.NewRecorder()

	authenticated(http.HandlerFunc(handler.List)).ServeHTTP(recorder, request)

	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body.String())
	}
	var response struct {
		NextCursor *string        `json:"next_cursor"`
		Posts      []postResponse `json:"posts"`
	}
	if err := json.Unmarshal(recorder.Body.Bytes(), &response); err != nil {
		t.Fatal(err)
	}
	if response.NextCursor == nil || *response.NextCursor != "40" {
		t.Fatalf("next cursor = %v", response.NextCursor)
	}
	if len(response.Posts) != 1 || response.Posts[0].Images[0].Position != 0 {
		t.Fatalf("posts = %+v", response.Posts)
	}
}

func TestHandlerCreateCommentUsesAuthenticatedAuthor(t *testing.T) {
	service := &stubPostService{}
	handler := NewHandler(service)
	request := httptest.NewRequest(
		http.MethodPost,
		"/api/v1/posts/41/comments",
		strings.NewReader(`{"body":"Nice post."}`),
	)
	request.SetPathValue("post_id", "41")
	request.Header.Set("Authorization", "Bearer token")
	recorder := httptest.NewRecorder()

	authenticated(http.HandlerFunc(handler.CreateComment)).ServeHTTP(recorder, request)

	if recorder.Code != http.StatusCreated {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body.String())
	}
	if service.userID != 7 || service.commentPostID != 41 || service.commentBody != "Nice post." {
		t.Fatalf(
			"user = %d, post = %d, body = %q",
			service.userID, service.commentPostID, service.commentBody,
		)
	}
}

func TestHandlerListCommentsReturnsStringCursor(t *testing.T) {
	handler := NewHandler(&stubPostService{})
	request := httptest.NewRequest(http.MethodGet, "/api/v1/posts/41/comments", nil)
	request.SetPathValue("post_id", "41")
	request.Header.Set("Authorization", "Bearer token")
	recorder := httptest.NewRecorder()

	authenticated(http.HandlerFunc(handler.ListComments)).ServeHTTP(recorder, request)

	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body.String())
	}
	var response struct {
		Comments   []commentResponse `json:"comments"`
		NextCursor *string           `json:"next_cursor"`
	}
	if err := json.Unmarshal(recorder.Body.Bytes(), &response); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	if len(response.Comments) != 1 || response.NextCursor == nil || *response.NextCursor != "20" {
		t.Fatalf("response = %+v", response)
	}
}

func TestHandlerDeleteCommentUsesAuthenticatedAuthorAndPathIDs(t *testing.T) {
	service := &stubPostService{}
	handler := NewHandler(service)
	request := httptest.NewRequest(http.MethodDelete, "/api/v1/posts/41/comments/21", nil)
	request.SetPathValue("post_id", "41")
	request.SetPathValue("comment_id", "21")
	request.Header.Set("Authorization", "Bearer token")
	recorder := httptest.NewRecorder()

	authenticated(http.HandlerFunc(handler.DeleteComment)).ServeHTTP(recorder, request)

	if recorder.Code != http.StatusNoContent {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body.String())
	}
	if service.userID != 7 || service.commentPostID != 41 || service.commentID != 21 {
		t.Fatalf(
			"user = %d, post = %d, comment = %d",
			service.userID, service.commentPostID, service.commentID,
		)
	}
}

func testPost() Post {
	return Post{
		ID: 41,
		Author: Author{
			ID: 7, Username: "retro_user", DisplayName: "Retro User", HasAvatar: true,
			CreatedAt: time.Date(2026, 8, 9, 8, 0, 0, 0, time.UTC),
		},
		Body: "Hello world", Images: []Image{{ID: 3, Position: 0, ContentType: "image/png", ByteSize: 8}},
		CreatedAt: time.Date(2026, 8, 9, 9, 0, 0, 0, time.UTC),
	}
}

func testComment() Comment {
	return Comment{
		ID: 21, PostID: 41,
		Author: Author{
			ID: 7, Username: "retro_user", DisplayName: "Retro User", HasAvatar: true,
			CreatedAt: time.Date(2026, 8, 9, 8, 0, 0, 0, time.UTC),
		},
		Body: "Nice post.", CreatedAt: time.Date(2026, 8, 9, 10, 0, 0, 0, time.UTC),
	}
}

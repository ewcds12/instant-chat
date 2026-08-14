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
	userID uint64
	body   string
	images []ImageUpload
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

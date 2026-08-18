package posts

import (
	"bytes"
	"context"
	"crypto/rand"
	"database/sql"
	"encoding/hex"
	"errors"
	"fmt"
	"log/slog"
	"time"

	"github.com/ewcds12/instant-chat/services/api/internal/store"
)

// MySQLRepository persists posts in MySQL and image bytes in private object storage.
type MySQLRepository struct {
	database    *sql.DB
	queries     *store.Queries
	objectStore ObjectStore
}

// NewMySQLRepository creates a MySQL-backed post repository.
func NewMySQLRepository(database *sql.DB, objectStore ObjectStore) *MySQLRepository {
	return &MySQLRepository{
		database: database, queries: store.New(database), objectStore: objectStore,
	}
}

// Create stores image objects and creates one post transactionally.
func (r *MySQLRepository) Create(
	ctx context.Context,
	authorID uint64,
	body string,
	images []ImageUpload,
) (Post, error) {
	stored, err := r.storeImages(ctx, authorID, images)
	if err != nil {
		return Post{}, err
	}
	tx, err := r.database.BeginTx(ctx, nil)
	if err != nil {
		r.cleanupObjects(stored)
		return Post{}, fmt.Errorf("begin post transaction: %w", err)
	}
	queries := r.queries.WithTx(tx)
	result, err := queries.CreatePost(ctx, store.CreatePostParams{AuthorID: authorID, Body: body})
	if err != nil {
		_ = tx.Rollback()
		r.cleanupObjects(stored)
		return Post{}, fmt.Errorf("create post: %w", err)
	}
	postID, err := result.LastInsertId()
	if err != nil {
		_ = tx.Rollback()
		r.cleanupObjects(stored)
		return Post{}, fmt.Errorf("read created post ID: %w", err)
	}
	if postID <= 0 {
		_ = tx.Rollback()
		r.cleanupObjects(stored)
		return Post{}, errors.New("read created post ID: database returned a non-positive ID")
	}
	for index, image := range stored {
		_, err = queries.CreatePostImage(ctx, store.CreatePostImageParams{
			PostID: uint64(postID), Position: uint8(index), ContentType: image.ContentType,
			ByteSize: uint32(len(image.Data)), ObjectKey: image.ObjectKey,
		})
		if err != nil {
			_ = tx.Rollback()
			r.cleanupObjects(stored)
			return Post{}, fmt.Errorf("create post image: %w", err)
		}
	}
	if err := tx.Commit(); err != nil {
		r.cleanupObjects(stored)
		return Post{}, fmt.Errorf("commit post transaction: %w", err)
	}
	return r.get(ctx, uint64(postID), authorID)
}

type storedImage struct {
	ImageUpload
	ObjectKey string
}

func (r *MySQLRepository) storeImages(
	ctx context.Context,
	authorID uint64,
	images []ImageUpload,
) ([]storedImage, error) {
	stored := make([]storedImage, 0, len(images))
	for _, image := range images {
		key, err := newObjectKey(authorID)
		if err != nil {
			r.cleanupObjects(stored)
			return nil, err
		}
		if err := r.objectStore.Put(
			ctx, key, bytes.NewReader(image.Data), int64(len(image.Data)), image.ContentType,
		); err != nil {
			r.cleanupObjects(stored)
			return nil, fmt.Errorf("store post image: %w", err)
		}
		stored = append(stored, storedImage{ImageUpload: image, ObjectKey: key})
	}
	return stored, nil
}

func newObjectKey(authorID uint64) (string, error) {
	random := make([]byte, 16)
	if _, err := rand.Read(random); err != nil {
		return "", fmt.Errorf("generate post image key: %w", err)
	}
	return fmt.Sprintf("posts/%d/%s", authorID, hex.EncodeToString(random)), nil
}

func (r *MySQLRepository) cleanupObjects(images []storedImage) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	for _, image := range images {
		if err := r.objectStore.Delete(ctx, image.ObjectKey); err != nil {
			slog.Error("remove unused post image object", "error", err)
		}
	}
}

// List returns one descending global post page.
func (r *MySQLRepository) List(
	ctx context.Context,
	viewerID uint64,
	before *uint64,
	limit int,
) ([]Post, error) {
	if before == nil {
		rows, err := r.queries.ListLatestPosts(ctx, store.ListLatestPostsParams{
			ViewerID: viewerID, Limit: int32(limit),
		})
		if err != nil {
			return nil, fmt.Errorf("list latest posts: %w", err)
		}
		posts := make([]Post, 0, limit)
		for _, row := range rows {
			posts = appendPost(posts, recordFromLatest(row))
		}
		return posts, nil
	}
	rows, err := r.queries.ListPostsBefore(ctx, store.ListPostsBeforeParams{
		ViewerID: viewerID, BeforePostID: *before, Limit: int32(limit),
	})
	if err != nil {
		return nil, fmt.Errorf("list posts before cursor: %w", err)
	}
	posts := make([]Post, 0, limit)
	for _, row := range rows {
		posts = appendPost(posts, recordFromBefore(row))
	}
	return posts, nil
}

func (r *MySQLRepository) get(ctx context.Context, postID, viewerID uint64) (Post, error) {
	rows, err := r.queries.GetPost(ctx, store.GetPostParams{
		ViewerID: viewerID, PostID: postID,
	})
	if err != nil {
		return Post{}, fmt.Errorf("read post: %w", err)
	}
	if len(rows) == 0 {
		return Post{}, ErrPostNotFound
	}
	posts := make([]Post, 0, 1)
	for _, row := range rows {
		posts = appendPost(posts, recordFromGet(row))
	}
	return posts[0], nil
}

// Like idempotently records one authenticated user's like.
func (r *MySQLRepository) Like(ctx context.Context, userID, postID uint64) (LikeState, error) {
	if err := r.queries.LikePost(ctx, store.LikePostParams{
		UserID: userID, PostID: postID,
	}); err != nil {
		return LikeState{}, fmt.Errorf("like post: %w", err)
	}
	return r.likeState(ctx, userID, postID)
}

// Unlike idempotently removes one authenticated user's like.
func (r *MySQLRepository) Unlike(ctx context.Context, userID, postID uint64) (LikeState, error) {
	if err := r.queries.UnlikePost(ctx, store.UnlikePostParams{
		PostID: postID, UserID: userID,
	}); err != nil {
		return LikeState{}, fmt.Errorf("unlike post: %w", err)
	}
	return r.likeState(ctx, userID, postID)
}

func (r *MySQLRepository) likeState(
	ctx context.Context,
	userID, postID uint64,
) (LikeState, error) {
	row, err := r.queries.GetPostLikeState(ctx, store.GetPostLikeStateParams{
		UserID: userID, PostID: postID,
	})
	if errors.Is(err, sql.ErrNoRows) {
		return LikeState{}, ErrPostNotFound
	}
	if err != nil {
		return LikeState{}, fmt.Errorf("read post like state: %w", err)
	}
	return LikeState{LikeCount: uint64(row.LikeCount), LikedByMe: row.LikedByMe}, nil
}

// Image opens one private post image for an authenticated request.
func (r *MySQLRepository) Image(ctx context.Context, imageID uint64) (ImageFile, error) {
	row, err := r.queries.GetPostImage(ctx, imageID)
	if errors.Is(err, sql.ErrNoRows) {
		return ImageFile{}, ErrPostImageNotFound
	}
	if err != nil {
		return ImageFile{}, fmt.Errorf("read post image: %w", err)
	}
	content, err := r.objectStore.Open(ctx, row.ObjectKey)
	if err != nil {
		return ImageFile{}, fmt.Errorf("open post image: %w", err)
	}
	return ImageFile{ContentType: row.ContentType, ByteSize: row.ByteSize, Content: content}, nil
}

// Delete removes one post owned by the current user.
func (r *MySQLRepository) Delete(ctx context.Context, authorID, postID uint64) error {
	keys, err := r.queries.ListPostObjectKeysForAuthor(
		ctx, store.ListPostObjectKeysForAuthorParams{PostID: postID, AuthorID: authorID},
	)
	if err != nil {
		return fmt.Errorf("list post image objects: %w", err)
	}
	result, err := r.queries.DeletePostForAuthor(
		ctx, store.DeletePostForAuthorParams{PostID: postID, AuthorID: authorID},
	)
	if err != nil {
		return fmt.Errorf("delete post: %w", err)
	}
	count, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("read deleted post count: %w", err)
	}
	if count == 0 {
		return ErrPostNotFound
	}
	for _, key := range keys {
		if err := r.objectStore.Delete(ctx, key); err != nil {
			slog.Error("remove deleted post image object", "error", err)
		}
	}
	return nil
}

// Report creates or updates one report for the current user.
func (r *MySQLRepository) Report(ctx context.Context, reporterID, postID uint64, reason string) error {
	reportable, err := r.queries.ReportablePostExists(ctx, store.ReportablePostExistsParams{
		PostID: postID, ReporterID: reporterID,
	})
	if err != nil {
		return fmt.Errorf("check reportable post: %w", err)
	}
	if !reportable {
		return ErrPostNotFound
	}
	_, err = r.queries.ReportPost(ctx, store.ReportPostParams{
		ReporterID: reporterID, Reason: reason, PostID: postID,
	})
	if err != nil {
		return fmt.Errorf("report post: %w", err)
	}
	return nil
}

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
	return r.get(ctx, authorID, uint64(postID))
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

// List returns one descending post page visible to the current user.
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
		BeforePostID: *before, ViewerID: viewerID, Limit: int32(limit),
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

func (r *MySQLRepository) get(ctx context.Context, viewerID, postID uint64) (Post, error) {
	rows, err := r.queries.GetPostForViewer(ctx, store.GetPostForViewerParams{
		PostID: postID, ViewerID: viewerID,
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

// Image opens one private post image visible to the current user.
func (r *MySQLRepository) Image(ctx context.Context, viewerID, imageID uint64) (ImageFile, error) {
	row, err := r.queries.GetPostImageForViewer(ctx, store.GetPostImageForViewerParams{
		ImageID: imageID, ViewerID: viewerID,
	})
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

// Block hides one user's posts from the current user's feed.
func (r *MySQLRepository) Block(ctx context.Context, blockerID, blockedUserID uint64) error {
	exists, err := r.queries.UserExists(ctx, blockedUserID)
	if err != nil {
		return fmt.Errorf("check blocked user: %w", err)
	}
	if !exists {
		return ErrUserNotFound
	}
	if err := r.queries.BlockUser(ctx, store.BlockUserParams{
		BlockerID: blockerID, BlockedUserID: blockedUserID,
	}); err != nil {
		return fmt.Errorf("block user: %w", err)
	}
	return nil
}

// Unblock restores one user's posts to the current user's feed.
func (r *MySQLRepository) Unblock(ctx context.Context, blockerID, blockedUserID uint64) error {
	if err := r.queries.UnblockUser(ctx, store.UnblockUserParams{
		BlockerID: blockerID, BlockedUserID: blockedUserID,
	}); err != nil {
		return fmt.Errorf("unblock user: %w", err)
	}
	return nil
}

// ListBlocked returns users hidden from the current user's feed.
func (r *MySQLRepository) ListBlocked(ctx context.Context, blockerID uint64) ([]BlockedUser, error) {
	rows, err := r.queries.ListBlockedUsers(ctx, blockerID)
	if err != nil {
		return nil, fmt.Errorf("list blocked users: %w", err)
	}
	users := make([]BlockedUser, 0, len(rows))
	for _, row := range rows {
		users = append(users, BlockedUser{Author: Author{
			ID: row.ID, Username: row.Username, DisplayName: row.DisplayName,
			HasAvatar: row.AvatarContentType.Valid, CreatedAt: row.CreatedAt,
		}})
	}
	return users, nil
}

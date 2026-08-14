package posts

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/ewcds12/instant-chat/services/api/internal/store"
)

// CreateComment persists one comment for an existing post.
func (r *MySQLRepository) CreateComment(
	ctx context.Context,
	authorID, postID uint64,
	body string,
) (Comment, error) {
	exists, err := r.queries.PostExists(ctx, postID)
	if err != nil {
		return Comment{}, fmt.Errorf("check commented post: %w", err)
	}
	if !exists {
		return Comment{}, ErrPostNotFound
	}
	result, err := r.queries.CreatePostComment(ctx, store.CreatePostCommentParams{
		PostID: postID, AuthorID: authorID, Body: body,
	})
	if err != nil {
		return Comment{}, fmt.Errorf("create post comment: %w", err)
	}
	commentID, err := result.LastInsertId()
	if err != nil {
		return Comment{}, fmt.Errorf("read created comment ID: %w", err)
	}
	if commentID <= 0 {
		return Comment{}, errors.New("read created comment ID: database returned a non-positive ID")
	}
	row, err := r.queries.GetPostComment(ctx, uint64(commentID))
	if err != nil {
		return Comment{}, fmt.Errorf("read created post comment: %w", err)
	}
	return commentFromColumns(
		row.ID, row.PostID, row.Body, row.CreatedAt, row.AuthorID,
		row.AuthorUsername, row.AuthorDisplayName,
		row.AuthorAvatarContentType.Valid, row.AuthorCreatedAt,
	), nil
}

// ListComments returns one descending comment page for an existing post.
func (r *MySQLRepository) ListComments(
	ctx context.Context,
	postID uint64,
	before *uint64,
	limit int,
) ([]Comment, error) {
	exists, err := r.queries.PostExists(ctx, postID)
	if err != nil {
		return nil, fmt.Errorf("check commented post: %w", err)
	}
	if !exists {
		return nil, ErrPostNotFound
	}
	if before == nil {
		rows, err := r.queries.ListLatestPostComments(ctx, store.ListLatestPostCommentsParams{
			PostID: postID, Limit: int32(limit),
		})
		if err != nil {
			return nil, fmt.Errorf("list latest post comments: %w", err)
		}
		comments := make([]Comment, 0, len(rows))
		for _, row := range rows {
			comments = append(comments, commentFromColumns(
				row.ID, row.PostID, row.Body, row.CreatedAt, row.AuthorID,
				row.AuthorUsername, row.AuthorDisplayName,
				row.AuthorAvatarContentType.Valid, row.AuthorCreatedAt,
			))
		}
		return comments, nil
	}
	rows, err := r.queries.ListPostCommentsBefore(ctx, store.ListPostCommentsBeforeParams{
		PostID: postID, BeforeCommentID: *before, Limit: int32(limit),
	})
	if err != nil {
		return nil, fmt.Errorf("list older post comments: %w", err)
	}
	comments := make([]Comment, 0, len(rows))
	for _, row := range rows {
		comments = append(comments, commentFromColumns(
			row.ID, row.PostID, row.Body, row.CreatedAt, row.AuthorID,
			row.AuthorUsername, row.AuthorDisplayName,
			row.AuthorAvatarContentType.Valid, row.AuthorCreatedAt,
		))
	}
	return comments, nil
}

// DeleteComment removes one comment owned by the current user.
func (r *MySQLRepository) DeleteComment(
	ctx context.Context,
	authorID, postID, commentID uint64,
) error {
	result, err := r.queries.DeletePostCommentForAuthor(
		ctx,
		store.DeletePostCommentForAuthorParams{
			CommentID: commentID, PostID: postID, AuthorID: authorID,
		},
	)
	if err != nil {
		return fmt.Errorf("delete post comment: %w", err)
	}
	count, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("read deleted comment count: %w", err)
	}
	if count == 0 {
		return ErrCommentNotFound
	}
	return nil
}

func commentFromColumns(
	id, postID uint64,
	body string,
	createdAt time.Time,
	authorID uint64,
	authorUsername, authorDisplayName string,
	authorHasAvatar bool,
	authorCreatedAt time.Time,
) Comment {
	return Comment{
		ID: id, PostID: postID, Body: body, CreatedAt: createdAt,
		Author: Author{
			ID: authorID, Username: authorUsername, DisplayName: authorDisplayName,
			HasAvatar: authorHasAvatar, CreatedAt: authorCreatedAt,
		},
	}
}

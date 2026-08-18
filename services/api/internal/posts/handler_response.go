package posts

import (
	"strconv"
	"time"
)

type authorResponse struct {
	ID          string    `json:"id"`
	Username    string    `json:"username"`
	DisplayName string    `json:"display_name"`
	AvatarURL   *string   `json:"avatar_url"`
	CreatedAt   time.Time `json:"created_at"`
}

type imageResponse struct {
	ID          string `json:"id"`
	Position    uint8  `json:"position"`
	URL         string `json:"url"`
	ContentType string `json:"content_type"`
	ByteSize    uint32 `json:"byte_size"`
}

type postResponse struct {
	ID           string          `json:"id"`
	Author       authorResponse  `json:"author"`
	Body         string          `json:"body"`
	Images       []imageResponse `json:"images"`
	CommentCount uint64          `json:"comment_count"`
	LikeCount    uint64          `json:"like_count"`
	LikedByMe    bool            `json:"liked_by_me"`
	CreatedAt    time.Time       `json:"created_at"`
}

type likeResponse struct {
	LikeCount uint64 `json:"like_count"`
	LikedByMe bool   `json:"liked_by_me"`
}

type commentResponse struct {
	ID              string         `json:"id"`
	PostID          string         `json:"post_id"`
	ParentCommentID *string        `json:"parent_comment_id"`
	Author          authorResponse `json:"author"`
	Body            string         `json:"body"`
	CreatedAt       time.Time      `json:"created_at"`
}

func responseFromPost(post Post) postResponse {
	images := make([]imageResponse, 0, len(post.Images))
	for _, image := range post.Images {
		id := strconv.FormatUint(image.ID, 10)
		images = append(images, imageResponse{
			ID: id, Position: image.Position, URL: "/api/v1/post-images/" + id,
			ContentType: image.ContentType, ByteSize: image.ByteSize,
		})
	}
	return postResponse{
		ID: strconv.FormatUint(post.ID, 10), Author: responseFromAuthor(post.Author),
		Body: post.Body, Images: images, CommentCount: post.CommentCount,
		LikeCount: post.LikeCount, LikedByMe: post.LikedByMe,
		CreatedAt: post.CreatedAt.UTC(),
	}
}

func responseFromLike(state LikeState) likeResponse {
	return likeResponse{LikeCount: state.LikeCount, LikedByMe: state.LikedByMe}
}

func responseFromComment(comment Comment) commentResponse {
	response := commentResponse{
		ID:     strconv.FormatUint(comment.ID, 10),
		PostID: strconv.FormatUint(comment.PostID, 10),
		Author: responseFromAuthor(comment.Author), Body: comment.Body,
		CreatedAt: comment.CreatedAt.UTC(),
	}
	if comment.ParentCommentID != nil {
		value := strconv.FormatUint(*comment.ParentCommentID, 10)
		response.ParentCommentID = &value
	}
	return response
}

func responseFromAuthor(author Author) authorResponse {
	response := authorResponse{
		ID: strconv.FormatUint(author.ID, 10), Username: author.Username,
		DisplayName: author.DisplayName, CreatedAt: author.CreatedAt.UTC(),
	}
	if author.HasAvatar {
		url := "/api/v1/users/" + response.ID + "/avatar"
		response.AvatarURL = &url
	}
	return response
}

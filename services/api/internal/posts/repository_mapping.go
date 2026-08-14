package posts

import (
	"database/sql"
	"time"

	"github.com/ewcds12/instant-chat/services/api/internal/store"
)

type postRecord struct {
	id                uint64
	body              string
	createdAt         time.Time
	commentCount      uint64
	authorID          uint64
	authorUsername    string
	authorDisplayName string
	authorHasAvatar   bool
	authorCreatedAt   time.Time
	imageID           sql.NullInt64
	imagePosition     sql.NullInt16
	imageContentType  sql.NullString
	imageByteSize     sql.NullInt32
}

func recordFromGet(row store.GetPostRow) postRecord {
	return postRecord{
		id: row.ID, body: row.Body, createdAt: row.CreatedAt,
		commentCount: uint64(row.CommentCount),
		authorID:     row.AuthorID, authorUsername: row.AuthorUsername,
		authorDisplayName: row.AuthorDisplayName,
		authorHasAvatar:   row.AuthorAvatarContentType.Valid,
		authorCreatedAt:   row.AuthorCreatedAt, imageID: row.ImageID,
		imagePosition:    row.ImagePosition,
		imageContentType: row.ImageContentType, imageByteSize: row.ImageByteSize,
	}
}

func recordFromLatest(row store.ListLatestPostsRow) postRecord {
	return postRecord{
		id: row.ID, body: row.Body, createdAt: row.CreatedAt,
		commentCount: uint64(row.CommentCount),
		authorID:     row.AuthorID, authorUsername: row.AuthorUsername,
		authorDisplayName: row.AuthorDisplayName,
		authorHasAvatar:   row.AuthorAvatarContentType.Valid,
		authorCreatedAt:   row.AuthorCreatedAt, imageID: row.ImageID,
		imagePosition:    row.ImagePosition,
		imageContentType: row.ImageContentType, imageByteSize: row.ImageByteSize,
	}
}

func recordFromBefore(row store.ListPostsBeforeRow) postRecord {
	return postRecord{
		id: row.ID, body: row.Body, createdAt: row.CreatedAt,
		commentCount: uint64(row.CommentCount),
		authorID:     row.AuthorID, authorUsername: row.AuthorUsername,
		authorDisplayName: row.AuthorDisplayName,
		authorHasAvatar:   row.AuthorAvatarContentType.Valid,
		authorCreatedAt:   row.AuthorCreatedAt, imageID: row.ImageID,
		imagePosition:    row.ImagePosition,
		imageContentType: row.ImageContentType, imageByteSize: row.ImageByteSize,
	}
}

func appendPost(posts []Post, record postRecord) []Post {
	if len(posts) == 0 || posts[len(posts)-1].ID != record.id {
		posts = append(posts, Post{
			ID: record.id,
			Author: Author{
				ID: record.authorID, Username: record.authorUsername,
				DisplayName: record.authorDisplayName, HasAvatar: record.authorHasAvatar,
				CreatedAt: record.authorCreatedAt,
			},
			Body: record.body, Images: []Image{}, CommentCount: record.commentCount,
			CreatedAt: record.createdAt,
		})
	}
	if record.imageID.Valid && record.imagePosition.Valid && record.imageContentType.Valid && record.imageByteSize.Valid {
		post := &posts[len(posts)-1]
		post.Images = append(post.Images, Image{
			ID: uint64(record.imageID.Int64), Position: uint8(record.imagePosition.Int16),
			ContentType: record.imageContentType.String,
			ByteSize:    uint32(record.imageByteSize.Int32),
		})
	}
	return posts
}

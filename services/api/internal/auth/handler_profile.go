package auth

import (
	"io"
	"net/http"

	"github.com/ewcds12/instant-chat/services/api/internal/httpapi"
)

const maximumAvatarRequestBytes = maximumAvatarBytes + 1024*1024

func avatarUpload(w http.ResponseWriter, r *http.Request) (AvatarUpload, bool) {
	r.Body = http.MaxBytesReader(w, r.Body, maximumAvatarRequestBytes)
	if err := r.ParseMultipartForm(maximumAvatarBytes); err != nil {
		writeProfileInputError(w, r, "Profile photo upload must be a valid multipart form.")
		return AvatarUpload{}, false
	}
	file, _, err := r.FormFile("avatar")
	if err != nil {
		writeProfileInputError(w, r, "Profile photo is required.")
		return AvatarUpload{}, false
	}
	defer file.Close()
	data, err := io.ReadAll(io.LimitReader(file, maximumAvatarBytes+1))
	if err != nil {
		writeProfileInputError(w, r, "Profile photo could not be read.")
		return AvatarUpload{}, false
	}
	return AvatarUpload{ContentType: detectAvatarContentType(data), Data: data}, true
}

func detectAvatarContentType(data []byte) string {
	if len(data) >= 12 && string(data[0:4]) == "RIFF" && string(data[8:12]) == "WEBP" {
		return "image/webp"
	}
	return http.DetectContentType(data)
}

func writeProfileInputError(w http.ResponseWriter, r *http.Request, message string) {
	httpapi.WriteError(w, http.StatusBadRequest, "invalid_argument", message, httpapi.RequestID(r.Context()))
}

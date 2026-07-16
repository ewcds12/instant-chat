package messages

import (
	"io"
	"net/http"
)

func imageUpload(w http.ResponseWriter, r *http.Request) (ImageUpload, string, bool) {
	r.Body = http.MaxBytesReader(w, r.Body, maximumImageBytes+1024*1024)
	if err := r.ParseMultipartForm(maximumImageBytes); err != nil {
		writeInvalidArgument(w, r, "Image upload must be a valid multipart form.")
		return ImageUpload{}, "", false
	}
	file, _, err := r.FormFile("image")
	if err != nil {
		writeInvalidArgument(w, r, "Image file is required.")
		return ImageUpload{}, "", false
	}
	defer file.Close()
	data, err := io.ReadAll(io.LimitReader(file, maximumImageBytes+1))
	if err != nil {
		writeInvalidArgument(w, r, "Image file could not be read.")
		return ImageUpload{}, "", false
	}
	return ImageUpload{ContentType: detectImageContentType(data), Data: data},
		r.FormValue("client_message_id"), true
}

func detectImageContentType(data []byte) string {
	if len(data) >= 12 &&
		string(data[0:4]) == "RIFF" &&
		string(data[8:12]) == "WEBP" {
		return "image/webp"
	}
	return http.DetectContentType(data)
}

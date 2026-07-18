package messages

import (
	"io"
	"net/http"
	"path/filepath"
	"strings"
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

func fileUpload(w http.ResponseWriter, r *http.Request) (FileUpload, string, bool) {
	r.Body = http.MaxBytesReader(w, r.Body, maximumFileBytes+1024*1024)
	if err := r.ParseMultipartForm(maximumFileBytes); err != nil {
		writeInvalidArgument(w, r, "File upload must be a valid multipart form.")
		return FileUpload{}, "", false
	}
	file, header, err := r.FormFile("file")
	if err != nil {
		writeInvalidArgument(w, r, "File is required.")
		return FileUpload{}, "", false
	}
	defer file.Close()
	data, err := io.ReadAll(io.LimitReader(file, maximumFileBytes+1))
	if err != nil {
		writeInvalidArgument(w, r, "File could not be read.")
		return FileUpload{}, "", false
	}
	return FileUpload{
		Filename:    cleanFilename(header.Filename),
		ContentType: detectFileContentType(header.Header.Get("Content-Type"), data),
		Data:        data,
	}, r.FormValue("client_message_id"), true
}

func detectImageContentType(data []byte) string {
	if len(data) >= 12 &&
		string(data[0:4]) == "RIFF" &&
		string(data[8:12]) == "WEBP" {
		return "image/webp"
	}
	return http.DetectContentType(data)
}

func detectFileContentType(header string, data []byte) string {
	if value := strings.TrimSpace(header); value != "" {
		return value
	}
	return http.DetectContentType(data)
}

func cleanFilename(value string) string {
	name := strings.TrimSpace(filepath.Base(value))
	if name == "." {
		return ""
	}
	return name
}

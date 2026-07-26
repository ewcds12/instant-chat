package messages

import (
	"io"
	"net/http"
	"path/filepath"
	"strings"
)

const multipartMemoryBytes = 1024 * 1024

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

func fileUpload(
	w http.ResponseWriter,
	r *http.Request,
) (FileUpload, string, func(), bool) {
	r.Body = http.MaxBytesReader(w, r.Body, maximumFileBytes+1024*1024)
	if err := r.ParseMultipartForm(multipartMemoryBytes); err != nil {
		writeInvalidArgument(w, r, "File upload must be a valid multipart form.")
		return FileUpload{}, "", nil, false
	}
	removeForm := func() { _ = r.MultipartForm.RemoveAll() }
	file, header, err := r.FormFile("file")
	if err != nil {
		removeForm()
		writeInvalidArgument(w, r, "File is required.")
		return FileUpload{}, "", nil, false
	}
	cleanup := func() {
		_ = file.Close()
		removeForm()
	}
	sniff := make([]byte, 512)
	read, err := io.ReadFull(file, sniff)
	if err != nil && err != io.EOF && err != io.ErrUnexpectedEOF {
		cleanup()
		writeInvalidArgument(w, r, "File could not be read.")
		return FileUpload{}, "", nil, false
	}
	if _, err := file.Seek(0, io.SeekStart); err != nil {
		cleanup()
		writeInvalidArgument(w, r, "File could not be read.")
		return FileUpload{}, "", nil, false
	}
	return FileUpload{
		Filename:    cleanFilename(header.Filename),
		ContentType: detectFileContentType(header.Header.Get("Content-Type"), sniff[:read]),
		ByteSize:    header.Size,
		Reader:      file,
	}, r.FormValue("client_message_id"), cleanup, true
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

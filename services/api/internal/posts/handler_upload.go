package posts

import (
	"bytes"
	"io"
	"net/http"
)

const maximumMultipartBytes = (maximumImages * maximumImageSize) + (1024 * 1024)

func postUpload(
	w http.ResponseWriter,
	r *http.Request,
) (string, []ImageUpload, func(), bool) {
	r.Body = http.MaxBytesReader(w, r.Body, maximumMultipartBytes)
	if err := r.ParseMultipartForm(maximumMultipartBytes); err != nil {
		writeInvalidArgument(w, r, "Post data is too large or invalid.")
		return "", nil, nil, false
	}
	cleanup := func() { _ = r.MultipartForm.RemoveAll() }
	headers := r.MultipartForm.File["images"]
	if len(headers) > maximumImages {
		cleanup()
		writeInvalidArgument(w, r, "A post can contain up to 4 photos.")
		return "", nil, nil, false
	}
	images := make([]ImageUpload, 0, len(headers))
	for _, header := range headers {
		file, err := header.Open()
		if err != nil {
			cleanup()
			writeInvalidArgument(w, r, "A selected photo could not be read.")
			return "", nil, nil, false
		}
		data, readErr := io.ReadAll(io.LimitReader(file, maximumImageSize+1))
		_ = file.Close()
		if readErr != nil || len(data) == 0 || len(data) > maximumImageSize {
			cleanup()
			writeInvalidArgument(w, r, "Each photo must be no larger than 15 MB.")
			return "", nil, nil, false
		}
		images = append(images, ImageUpload{
			ContentType: detectImageContentType(data), Data: data,
		})
	}
	return r.FormValue("body"), images, cleanup, true
}

func detectImageContentType(data []byte) string {
	if len(data) >= 12 && bytes.Equal(data[:4], []byte("RIFF")) && bytes.Equal(data[8:12], []byte("WEBP")) {
		return "image/webp"
	}
	return http.DetectContentType(data)
}

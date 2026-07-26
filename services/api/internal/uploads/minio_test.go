package uploads

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"strconv"
	"strings"
	"testing"
)

func TestMinIOStoreCreatesBucketAndTransfersObject(t *testing.T) {
	var bucketCreated bool
	var stored []byte
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch {
		case r.Method == http.MethodHead && r.URL.Path == "/files/":
			if !bucketCreated {
				writeS3Error(w, http.StatusNotFound, "NoSuchBucket")
				return
			}
			w.WriteHeader(http.StatusOK)
		case r.Method == http.MethodPut && r.URL.Path == "/files/":
			bucketCreated = true
			w.WriteHeader(http.StatusOK)
		case r.Method == http.MethodPut && r.URL.Path == "/files/test-object":
			body, _ := io.ReadAll(r.Body)
			stored = decodeAWSChunks(body)
			w.Header().Set("ETag", `"test-etag"`)
			w.WriteHeader(http.StatusOK)
		case r.Method == http.MethodHead && r.URL.Path == "/files/test-object":
			w.Header().Set("Content-Length", fmt.Sprint(len(stored)))
			w.Header().Set("Content-Type", "application/pdf")
			w.Header().Set("ETag", `"test-etag"`)
			w.Header().Set("Last-Modified", "Sun, 26 Jul 2026 08:00:00 GMT")
			w.WriteHeader(http.StatusOK)
		case r.Method == http.MethodGet && r.URL.Path == "/files/test-object":
			w.Header().Set("Content-Length", fmt.Sprint(len(stored)))
			w.Header().Set("Last-Modified", "Sun, 26 Jul 2026 08:00:00 GMT")
			_, _ = w.Write(stored)
		case r.Method == http.MethodDelete && r.URL.Path == "/files/test-object":
			stored = nil
			w.WriteHeader(http.StatusNoContent)
		default:
			t.Errorf("unexpected request: %s %s", r.Method, r.URL.String())
			w.WriteHeader(http.StatusNotFound)
		}
	}))
	defer server.Close()

	store, err := NewMinIOStore(
		strings.TrimPrefix(server.URL, "http://"),
		"access-key",
		"secret-key",
		"files",
		false,
	)
	if err != nil {
		t.Fatalf("NewMinIOStore() error = %v", err)
	}
	ctx := context.Background()
	if err := store.EnsureBucket(ctx); err != nil {
		t.Fatalf("EnsureBucket() error = %v", err)
	}
	if err := store.Put(
		ctx,
		"test-object",
		bytes.NewReader([]byte("PDF")),
		3,
		"application/pdf",
	); err != nil {
		t.Fatalf("Put() error = %v", err)
	}
	content, err := store.Open(ctx, "test-object")
	if err != nil {
		t.Fatalf("Open() error = %v", err)
	}
	got, err := io.ReadAll(content)
	_ = content.Close()
	if err != nil || string(got) != "PDF" {
		t.Fatalf("Open() bytes = %q, error = %v", got, err)
	}
	if err := store.Delete(ctx, "test-object"); err != nil {
		t.Fatalf("Delete() error = %v", err)
	}
}

func decodeAWSChunks(body []byte) []byte {
	var decoded []byte
	for len(body) > 0 {
		lineEnd := bytes.Index(body, []byte("\r\n"))
		if lineEnd < 0 {
			return decoded
		}
		sizeField := strings.SplitN(string(body[:lineEnd]), ";", 2)[0]
		size, err := strconv.ParseInt(sizeField, 16, 64)
		if err != nil || size == 0 {
			return decoded
		}
		body = body[lineEnd+2:]
		if int64(len(body)) < size+2 {
			return decoded
		}
		decoded = append(decoded, body[:size]...)
		body = body[size+2:]
	}
	return decoded
}

func writeS3Error(w http.ResponseWriter, status int, code string) {
	w.Header().Set("Content-Type", "application/xml")
	w.WriteHeader(status)
	_, _ = fmt.Fprintf(w, "<Error><Code>%s</Code></Error>", code)
}

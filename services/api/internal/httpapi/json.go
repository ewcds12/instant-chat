// Package httpapi contains shared HTTP transport behavior.
package httpapi

import (
	"encoding/json"
	"errors"
	"io"
	"net/http"
)

const maximumRequestBody = 1 << 20

// ErrorResponse is the stable API error envelope.
type ErrorResponse struct {
	Error APIError `json:"error"`
}

// APIError contains a machine code and a safe American English message.
type APIError struct {
	Code      string `json:"code"`
	Message   string `json:"message"`
	RequestID string `json:"request_id"`
}

// DecodeJSON decodes exactly one bounded JSON object and rejects unknown fields.
func DecodeJSON(w http.ResponseWriter, r *http.Request, destination any) error {
	r.Body = http.MaxBytesReader(w, r.Body, maximumRequestBody)
	decoder := json.NewDecoder(r.Body)
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(destination); err != nil {
		return err
	}
	if err := decoder.Decode(&struct{}{}); !errors.Is(err, io.EOF) {
		return errors.New("request body must contain exactly one JSON object")
	}
	return nil
}

// WriteJSON writes a JSON response with the supplied status.
func WriteJSON(w http.ResponseWriter, status int, value any) {
	body, err := json.Marshal(value)
	if err != nil {
		http.Error(w, "Failed to encode the response.", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	if _, err := w.Write(body); err != nil {
		return
	}
}

// WriteError writes the stable API error envelope.
func WriteError(w http.ResponseWriter, status int, code, message, requestID string) {
	WriteJSON(w, status, ErrorResponse{Error: APIError{
		Code: code, Message: message, RequestID: requestID,
	}})
}

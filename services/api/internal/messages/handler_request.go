package messages

import (
	"math"
	"net/http"
	"strconv"
)

func optionalRequestID(
	w http.ResponseWriter,
	r *http.Request,
	raw *string,
	label string,
) (*uint64, bool) {
	if raw == nil {
		return nil, true
	}
	value, err := strconv.ParseUint(*raw, 10, 64)
	if err != nil || value == 0 || value > math.MaxInt64 {
		writeInvalidArgument(w, r, label+" must be a positive integer string.")
		return nil, false
	}
	return &value, true
}

package auth

import (
	"context"
	"net/http"
)

type userContextKey struct{}

// RequireUser authenticates the bearer token and attaches its user to the request.
func (h *Handler) RequireUser(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		user, err := h.service.CurrentUser(r.Context(), bearerToken(r))
		if err != nil {
			writeServiceError(w, r, err)
			return
		}
		ctx := context.WithValue(r.Context(), userContextKey{}, user)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

// UserFromContext returns the user attached by RequireUser.
func UserFromContext(ctx context.Context) (User, bool) {
	user, ok := ctx.Value(userContextKey{}).(User)
	return user, ok
}

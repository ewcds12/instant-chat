// Package users contains account identity rules shared by server modules.
package users

import "strings"

const (
	minimumUsernameBytes = 3
	maximumUsernameBytes = 32
)

// NormalizeUsername returns the canonical lowercase username when it is valid.
func NormalizeUsername(value string) (string, bool) {
	normalized := strings.ToLower(strings.TrimSpace(value))
	if len(normalized) < minimumUsernameBytes || len(normalized) > maximumUsernameBytes {
		return "", false
	}
	for index, character := range []byte(normalized) {
		isLetter := character >= 'a' && character <= 'z'
		isNumber := character >= '0' && character <= '9'
		if (!isLetter && !isNumber && character != '_') || (index == 0 && !isLetter) {
			return "", false
		}
	}
	return normalized, true
}

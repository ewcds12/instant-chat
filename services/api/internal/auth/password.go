package auth

import (
	"crypto/rand"
	"crypto/subtle"
	"encoding/base64"
	"errors"
	"fmt"
	"io"
	"strings"

	"golang.org/x/crypto/argon2"
)

const (
	argonMemory      = 19 * 1024
	argonIterations  = 2
	argonParallelism = 1
	argonSaltLength  = 16
	argonKeyLength   = 32
)

type argonParameters struct {
	memory      uint32
	iterations  uint32
	parallelism uint8
	saltLength  uint32
	keyLength   uint32
}

// PasswordHasher hashes and verifies passwords with Argon2id.
type PasswordHasher struct {
	parameters argonParameters
	random     io.Reader
}

// NewPasswordHasher returns a hasher using the project's production parameters.
func NewPasswordHasher() *PasswordHasher {
	return newPasswordHasher(argonParameters{
		memory:      argonMemory,
		iterations:  argonIterations,
		parallelism: argonParallelism,
		saltLength:  argonSaltLength,
		keyLength:   argonKeyLength,
	}, rand.Reader)
}

func newPasswordHasher(parameters argonParameters, random io.Reader) *PasswordHasher {
	return &PasswordHasher{parameters: parameters, random: random}
}

// Hash returns a PHC-formatted Argon2id password digest.
func (h *PasswordHasher) Hash(password string) (string, error) {
	salt := make([]byte, h.parameters.saltLength)
	if _, err := io.ReadFull(h.random, salt); err != nil {
		return "", fmt.Errorf("read password salt: %w", err)
	}

	digest := argon2.IDKey(
		[]byte(password), salt, h.parameters.iterations, h.parameters.memory,
		h.parameters.parallelism, h.parameters.keyLength,
	)
	return fmt.Sprintf(
		"$argon2id$v=%d$m=%d,t=%d,p=%d$%s$%s",
		argon2.Version,
		h.parameters.memory,
		h.parameters.iterations,
		h.parameters.parallelism,
		base64.RawStdEncoding.EncodeToString(salt),
		base64.RawStdEncoding.EncodeToString(digest),
	), nil
}

// Verify compares a password with a PHC-formatted Argon2id digest.
func (h *PasswordHasher) Verify(encodedHash, password string) (bool, error) {
	parameters, salt, expected, err := parsePasswordHash(encodedHash)
	if err != nil {
		return false, err
	}
	actual := argon2.IDKey(
		[]byte(password), salt, parameters.iterations, parameters.memory,
		parameters.parallelism, uint32(len(expected)),
	)
	return subtle.ConstantTimeCompare(actual, expected) == 1, nil
}

func parsePasswordHash(encodedHash string) (argonParameters, []byte, []byte, error) {
	parts := strings.Split(encodedHash, "$")
	if len(parts) != 6 || parts[1] != "argon2id" {
		return argonParameters{}, nil, nil, errors.New("invalid Argon2id hash format")
	}

	var version int
	if _, err := fmt.Sscanf(parts[2], "v=%d", &version); err != nil || version != argon2.Version {
		return argonParameters{}, nil, nil, errors.New("unsupported Argon2id version")
	}

	var parameters argonParameters
	if _, err := fmt.Sscanf(parts[3], "m=%d,t=%d,p=%d", &parameters.memory, &parameters.iterations, &parameters.parallelism); err != nil {
		return argonParameters{}, nil, nil, errors.New("invalid Argon2id parameters")
	}
	if parameters.memory < 7*1024 || parameters.memory > 1024*1024 || parameters.iterations == 0 || parameters.iterations > 10 || parameters.parallelism == 0 || parameters.parallelism > 16 {
		return argonParameters{}, nil, nil, errors.New("unsafe Argon2id parameters")
	}

	salt, err := base64.RawStdEncoding.DecodeString(parts[4])
	if err != nil || len(salt) < 16 || len(salt) > 64 {
		return argonParameters{}, nil, nil, errors.New("invalid Argon2id salt")
	}
	digest, err := base64.RawStdEncoding.DecodeString(parts[5])
	if err != nil || len(digest) < 16 || len(digest) > 64 {
		return argonParameters{}, nil, nil, errors.New("invalid Argon2id digest")
	}
	return parameters, salt, digest, nil
}

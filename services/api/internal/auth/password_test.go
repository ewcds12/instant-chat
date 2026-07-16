package auth

import (
	"bytes"
	"testing"
)

func TestPasswordHasherVerifiesPassword(t *testing.T) {
	hasher := testPasswordHasher()

	encoded, err := hasher.Hash("correct horse battery staple")
	if err != nil {
		t.Fatalf("Hash() error = %v", err)
	}

	valid, err := hasher.Verify(encoded, "correct horse battery staple")
	if err != nil {
		t.Fatalf("Verify() error = %v", err)
	}
	if !valid {
		t.Fatal("Verify() = false, want true")
	}

	valid, err = hasher.Verify(encoded, "incorrect password")
	if err != nil {
		t.Fatalf("Verify() wrong password error = %v", err)
	}
	if valid {
		t.Fatal("Verify() wrong password = true, want false")
	}
}

func TestPasswordHasherRejectsMalformedHash(t *testing.T) {
	if _, err := testPasswordHasher().Verify("not-a-password-hash", "password"); err == nil {
		t.Fatal("Verify() error = nil, want malformed hash error")
	}
}

func testPasswordHasher() *PasswordHasher {
	return newPasswordHasher(argonParameters{
		memory: 7 * 1024, iterations: 1, parallelism: 1, saltLength: 16, keyLength: 16,
	}, bytes.NewReader(make([]byte, 1024)))
}

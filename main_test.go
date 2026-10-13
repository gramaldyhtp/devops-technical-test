package main

import "testing"

func TestVersionVariable(t *testing.T) {
	if version == "" {
		t.Errorf("Expected 'version' variable not to be empty")
	}
}

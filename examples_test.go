package main

import (
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"testing"
)

// opaqueIDAssignment matches an attribute assignment to a bare numeric
// string literal — the signature of a hardcoded catalog/server ID that
// users cannot be expected to know (product_id = "7955", os_id = "88",
// id = "17482"). Slugs, names, ports and TTLs do not match: only quoted
// all-digit values with 2+ digits.
var opaqueIDAssignment = regexp.MustCompile(`(?m)^\s*\w*_?id\s*=\s*"\d{2,}"`)

// TestExamplesHaveNoHardcodedIDs is the docs gate: no example or template
// may assign an opaque numeric ID to an attribute. Reference other
// resources (zone_id = gigahost_dns_zone.x.id) or use slugs instead.
func TestExamplesHaveNoHardcodedIDs(t *testing.T) {
	t.Parallel()

	for _, root := range []string{"examples", "templates"} {
		err := filepath.WalkDir(root, func(path string, d os.DirEntry, err error) error {
			if err != nil {
				return err
			}

			if d.IsDir() || (!strings.HasSuffix(path, ".tf") && !strings.HasSuffix(path, ".tmpl")) {
				return nil
			}

			raw, err := os.ReadFile(path)
			if err != nil {
				return err
			}

			for _, m := range opaqueIDAssignment.FindAllString(string(raw), -1) {
				t.Errorf("%s: hardcoded opaque ID %q — use a slug, a name, or a resource reference", path, strings.TrimSpace(m))
			}

			return nil
		})
		if err != nil {
			t.Fatalf("walk %s: %v", root, err)
		}
	}
}

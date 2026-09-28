package main

import (
	"context"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/hashicorp/terraform-plugin-framework/datasource"
	"github.com/hashicorp/terraform-plugin-framework/provider"
	"github.com/hashicorp/terraform-plugin-framework/resource"
	"github.com/kradalby/gigahost-go/tfprovider"
)

// TestDocsCoverage fails the bump that pins a provider with a resource or data
// source lacking a generated doc or an example; tfplugindocs would silently
// publish it bare.
func TestDocsCoverage(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	p := tfprovider.New("test")()

	var meta provider.MetadataResponse
	p.Metadata(ctx, provider.MetadataRequest{}, &meta)

	check := func(dir, name string) {
		short := strings.TrimPrefix(name, meta.TypeName+"_")

		for _, path := range []string{
			filepath.Join("docs", dir, short+".md"),
			filepath.Join("examples", dir, name),
		} {
			if _, err := os.Stat(path); err != nil {
				t.Errorf("%s: %v", name, err)
			}
		}
	}

	for _, newR := range p.Resources(ctx) {
		var resp resource.MetadataResponse
		newR().Metadata(ctx, resource.MetadataRequest{ProviderTypeName: meta.TypeName}, &resp)
		check("resources", resp.TypeName)
	}

	for _, newD := range p.DataSources(ctx) {
		var resp datasource.MetadataResponse
		newD().Metadata(ctx, datasource.MetadataRequest{ProviderTypeName: meta.TypeName}, &resp)
		check("data-sources", resp.TypeName)
	}
}

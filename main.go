// Command terraform-provider-gigahost is the provider binary for
// gigahost.no. It serves the provider implementation from
// github.com/kradalby/gigahost-go/tfprovider over the standard
// Terraform plugin protocol, which is spoken by both OpenTofu and
// Terraform CLIs.
//
// The binary is named `terraform-provider-*` because that is the
// naming convention both registries require. It is the primary
// driver for OpenTofu and remains fully compatible with Terraform.
package main

import (
	"context"
	"flag"
	"log"

	"github.com/hashicorp/terraform-plugin-framework/providerserver"
	"github.com/kradalby/gigahost-go/tfprovider"
)

// These are injected by the linker during release builds.
var (
	version = "dev"
	commit  = "unknown"
)

func main() {
	var debug bool

	flag.BoolVar(&debug, "debug", false, "run the provider in debug mode (for delve, etc.)")
	flag.Parse()

	// Keep `commit` referenced so it isn't stripped by the linker
	// when not yet used in a user-visible context.
	_ = commit

	if err := providerserver.Serve(context.Background(), tfprovider.New(version), providerserver.ServeOpts{
		Address: "registry.terraform.io/kradalby/gigahost",
		Debug:   debug,
	}); err != nil {
		log.Fatal(err)
	}
}

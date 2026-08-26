# terraform-provider-gigahost

Registry shim for the Gigahost Terraform/OpenTofu provider.

**All development happens in
[kradalby/gigahost-go](https://github.com/kradalby/gigahost-go)** — the
provider implementation lives there as
`github.com/kradalby/gigahost-go/tfprovider`, together with the Go API
client, the CLI, the acceptance tests, and the docs templates. File issues
and pull requests there.

This repository exists because the Terraform and OpenTofu registries require
a dedicated repository named `terraform-provider-gigahost` to ingest GitHub
releases from. It contains only:

- `main.go` — serves the provider from gigahost-go (frozen, never changes)
- `go.mod` — pins gigahost-go **by commit**, as a pseudo-version. The provider
  version is the tag on this repo; gigahost-go is deliberately untagged
- release plumbing (goreleaser, registry manifest, GitHub workflow)
- `CHANGELOG.md` — copied from gigahost-go at release; it is what the
  registries surface
- `docs/` and `examples/` — generated from the pinned gigahost-go commit and
  replaced wholesale on every release. Never hand-edit them here; edit
  `terraform-provider-gigahost/{templates,examples}/` and the schema
  descriptions in `tfprovider/` over in gigahost-go

## Releasing

```console
$ nix run .#bump -- vX.Y.Z          # pins gigahost-go main by commit
$ nix run .#bump -- vX.Y.Z <ref>    # ...or an explicit gigahost-go ref
$ git push origin main vX.Y.Z
```

The tag triggers the goreleaser workflow, which builds, signs, and publishes
the release that both registries ingest.

## License

BSD-3-Clause. See [LICENSE](./LICENSE).

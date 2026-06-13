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
- `go.mod` — pins the gigahost-go version, which IS the provider version
- release plumbing (goreleaser, registry manifest, GitHub workflow)
- `docs/` — generated from the pinned gigahost-go version, never hand-edited

## Releasing

```console
$ # 1. in gigahost-go: tag and push vX.Y.Z
$ # 2. here:
$ nix run .#bump -- vX.Y.Z
$ git push origin main vX.Y.Z
```

The tag triggers the goreleaser workflow, which builds, signs, and publishes
the release that both registries ingest.

## License

MIT. See [LICENSE](./LICENSE).

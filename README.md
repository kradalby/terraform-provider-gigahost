# terraform-provider-gigahost

Registry shim for the Gigahost Terraform/OpenTofu provider.

The provider implementation lives in
[kradalby/gigahost-go](https://github.com/kradalby/gigahost-go) as
`github.com/kradalby/gigahost-go/tfprovider`, together with the Go API
client, the CLI and the acceptance tests. Provider behaviour and schema
descriptions are changed there.

This repository is what the Terraform and OpenTofu registries ingest, and
owns everything registry-facing:

- `main.go` — serves the provider from gigahost-go
- `go.mod` — pins gigahost-go **by commit**, as a pseudo-version. The provider
  version is the tag on this repo; gigahost-go is deliberately untagged
- `templates/`, `examples/` — registry doc sources, and standalone modules
  such as [`examples/nixos-anywhere`](./examples/nixos-anywhere)
- `docs/` — generated from the above and the pinned provider schema; never
  hand-edit
- `CHANGELOG.md`
- release plumbing (goreleaser, registry manifest, GitHub workflow)

## Docs

```console
$ nix run .#docs                    # regenerate docs/ against the pin
$ go work init . ../gigahost-go     # ...or against a local checkout
```

## Releasing

```console
$ $EDITOR CHANGELOG.md              # add a "## X.Y.Z" section, commit
$ nix run .#bump -- vX.Y.Z          # pins gigahost-go main by commit
$ nix run .#bump -- vX.Y.Z <ref>    # ...or an explicit gigahost-go ref
$ git push origin main vX.Y.Z
```

The tag triggers the goreleaser workflow, which builds, signs, and publishes
the release that both registries ingest.

## License

BSD-3-Clause. See [LICENSE](./LICENSE).

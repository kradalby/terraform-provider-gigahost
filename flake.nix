{
  description = "terraform-provider-gigahost: registry shim for github.com/kradalby/gigahost-go/tfprovider";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    flake-checks.url = "github:kradalby/flake-checks";
    flake-checks.inputs.nixpkgs.follows = "nixpkgs";
    flake-checks.inputs.flake-utils.follows = "flake-utils";
  };

  outputs =
    { nixpkgs
    , flake-utils
    , flake-checks
    , ...
    }:
    flake-utils.lib.eachDefaultSystem
      (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            (_: prev: {
              # goimports ships wrapped with a `go` on PATH. That `go` must be
              # at least the go.mod directive, or GOTOOLCHAIN=auto tries to
              # fetch a toolchain from inside the network-less treefmt sandbox.
              gotools = prev.gotools.override {
                buildGoModule = prev.buildGoLatestModule;
                go = prev.go_latest;
              };
            })
          ];
        };
        fc = flake-checks.lib;

        # The Go build/test checks are intentionally NOT exposed: go.mod imports
        # the PRIVATE github.com/kradalby/gigahost-go, which a hermetic nix
        # sandbox cannot fetch. Only the pure formatting check is wired up.
        common = {
          inherit pkgs;
          root = ./.;
          pname = "terraform-provider-gigahost";
          version = "0.0.1";
          vendorHash = null;
          goPkg = pkgs.go_latest;
        };

        deps = with pkgs; [
          go_latest
          git
          goreleaser
          opentofu
          terraform-plugin-docs
        ];

        mkApp = name: text:
          flake-utils.lib.mkApp {
            drv = pkgs.writeShellScriptBin name ''
              set -euo pipefail
              export PATH="${pkgs.lib.makeBinPath deps}:$PATH"
              export CGO_ENABLED=0
              # Never fetch a toolchain: the release artifacts must be built by
              # the Go that Nix pinned, not whatever go.dev serves today.
              export GOTOOLCHAIN=local
              ${text}
            '';
          };
      in
      {
        formatter = fc.formatter common;

        checks = {
          formatting = fc.goFormat common;
        };

        devShells.default = pkgs.mkShell {
          buildInputs = deps;
          # Match the apps: a go.mod ahead of nixpkgs' Go must be a clear
          # error, not a silent download outside the store.
          shellHook = ''
            export GOTOOLCHAIN=local
          '';
        };

        apps = {
          # The entire release process: pin gigahost-go to a commit,
          # regenerate registry docs and examples from it, commit, tag.
          #
          #   nix run .#bump -- v0.0.1          # pins gigahost-go main
          #   nix run .#bump -- v0.0.1 <ref>    # or an explicit ref
          #   git push origin main v0.0.1
          #
          # Only this repo carries tags — gigahost-go is pinned by commit, so
          # go.mod records a pseudo-version. The version argument is this
          # provider's registry version.
          #
          # Docs templates/examples live in gigahost-go under
          # terraform-provider-gigahost/, which is a nested module and thus
          # NOT part of the gigahost-go module zip — so the repo is cloned at
          # the pinned commit instead. tfplugindocs cannot download Terraform
          # (expired signing key, and we ship OpenTofu), so the provider
          # schema is exported with tofu via a dev-override first. That
          # override deliberately says hashicorp/gigahost even though the
          # binary serves kradalby/gigahost: tfplugindocs looks the schema up
          # under the conventional registry.terraform.io/hashicorp/<name>
          # address and finds nothing otherwise.
          #
          # Generation happens entirely under a staging dir, because
          # everything tfplugindocs reads is relative to --provider-dir. Both
          # docs/ and examples/ here are generated artefacts, replaced
          # wholesale from the pinned checkout; gigahost-go is the only place
          # to edit them.
          bump = mkApp "bump" ''
            version="''${1:?usage: nix run .#bump -- vX.Y.Z [gigahost-go-ref]}"
            ref="''${2:-main}"

            # Every check below happens before the first mutation. bump
            # rewrites go.mod, replaces docs/ and examples/, commits and tags —
            # none of which is safe to do halfway, in the wrong directory, or
            # on top of unrelated work.
            case "$version" in
              v[0-9]*.[0-9]*.[0-9]*) ;;
              *) echo "version must look like vX.Y.Z, got $version" >&2; exit 1 ;;
            esac

            grep -qx 'module github.com/kradalby/terraform-provider-gigahost' go.mod 2>/dev/null || {
              echo "run this from the terraform-provider-gigahost repo root" >&2; exit 1; }

            [ -z "$(git status --porcelain)" ] || {
              echo "working tree is dirty; commit or stash first" >&2; exit 1; }

            if git rev-parse -q --verify "refs/tags/$version" >/dev/null; then
              echo "tag $version already exists; pick the next version" >&2; exit 1
            fi

            branch="$(git rev-parse --abbrev-ref HEAD)"
            [ "$branch" = main ] || {
              echo "on branch $branch; release from main so the pushed tag and branch agree" >&2; exit 1; }

            # go.mod is rewritten below; restore it if anything after this fails.
            trap 'git checkout -- go.mod go.sum 2>/dev/null || true' ERR

            # gigahost-go is private (for now): skip proxy + sumdb.
            export GOPRIVATE=github.com/kradalby/*
            export GOFLAGS=-mod=mod

            tmp="$(mktemp -d)"
            trap 'rm -rf "$tmp"' EXIT

            # One clone serves both the pin and the docs inputs, so go.mod and
            # the generated docs cannot drift to different commits.
            git clone --quiet https://github.com/kradalby/gigahost-go.git "$tmp/gigahost-go"
            git -C "$tmp/gigahost-go" checkout --quiet "$ref"
            sha="$(git -C "$tmp/gigahost-go" rev-parse HEAD)"

            # `go get @<sha>` resolves back to a tag when the commit carries
            # one, which would record a version instead of the pseudo-version
            # this repo's whole versioning story depends on.
            if git -C "$tmp/gigahost-go" tag --points-at "$sha" | grep -qE '^v[0-9]'; then
              echo "gigahost-go $sha carries a vX.Y.Z tag; go.mod would record that version instead of a pseudo-version" >&2
              exit 1
            fi
            sub="$tmp/gigahost-go/terraform-provider-gigahost"

            go get "github.com/kradalby/gigahost-go@$sha"
            go mod tidy

            go build -o "$tmp/terraform-provider-gigahost" .

            cat > "$tmp/dev.tfrc" <<EOF
            provider_installation {
              dev_overrides { "registry.terraform.io/hashicorp/gigahost" = "$tmp" }
              direct {}
            }
            EOF
            mkdir -p "$tmp/cfg"
            cat > "$tmp/cfg/main.tf" <<EOF
            terraform {
              required_providers {
                gigahost = {
                  source = "registry.terraform.io/hashicorp/gigahost"
                }
              }
            }

            provider "gigahost" {}
            EOF
            if ! (cd "$tmp/cfg" && TF_CLI_CONFIG_FILE="$tmp/dev.tfrc" \
                    tofu providers schema -json > "$tmp/schema.json" 2>"$tmp/tofu.err"); then
              echo "tofu could not export the provider schema:" >&2
              cat "$tmp/tofu.err" >&2
              exit 1
            fi

            mkdir -p "$tmp/gen"
            cp -R "$sub/templates" "$tmp/gen/templates"
            cp -R "$sub/examples" "$tmp/gen/examples"

            tfplugindocs generate \
              --provider-dir "$tmp/gen" \
              --provider-name gigahost \
              --rendered-provider-name Gigahost \
              --providers-schema "$tmp/schema.json"

            rm -rf docs examples
            cp -R "$tmp/gen/docs" docs
            cp -R "$sub/examples" examples
            cp "$sub/CHANGELOG.md" CHANGELOG.md

            # Explicit, so a stray file in the working tree cannot ride
            # along into a signed public release.
            git add go.mod go.sum docs examples CHANGELOG.md
            git commit -m "release $version: gigahost-go $sha"
            git tag "$version"

            echo "tagged $version — now: git push origin main $version"
          '';

          # Signing is exercised only in CI at real releases, where the GPG
          # secrets live.
          snapshot = mkApp "snapshot" ''
            goreleaser release --snapshot --clean --skip=sign
          '';
        };
      });
}

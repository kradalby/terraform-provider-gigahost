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
    {
      nixpkgs,
      flake-utils,
      flake-checks,
      ...
    }:
    # Not eachDefaultSystem: it still lists x86_64-darwin, which nixpkgs
    # 26.11 dropped, so evaluating any output for it throws.
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ] (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        fc = flake-checks.lib;

        # The Go build/test checks are intentionally NOT exposed: they need a
        # vendorHash, which every bump would change. CI runs them outside the
        # sandbox instead. Only the pure formatting check is wired up.
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

        mkApp =
          name: description: text:
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
          }
          // {
            meta.description = description;
          };

        # Renders docs/ from templates/, examples/ and the schema of the
        # gigahost-go that go.mod (or a local go.work) resolves to. A subshell,
        # so its EXIT trap cannot clobber the caller's.
        #
        # tfplugindocs cannot download Terraform (expired signing key, and we
        # ship OpenTofu), so the provider schema is exported with tofu via a
        # dev-override first. That override deliberately says hashicorp/gigahost
        # even though the binary serves kradalby/gigahost: tfplugindocs looks
        # the schema up under the conventional
        # registry.terraform.io/hashicorp/<name> address and finds nothing
        # otherwise.
        gendocs = ''
          (
            tmp="$(mktemp -d)"
            trap 'rm -rf "$tmp"' EXIT

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

            tfplugindocs generate \
              --provider-name gigahost \
              --rendered-provider-name Gigahost \
              --providers-schema "$tmp/schema.json"
          )
        '';
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
          # docs/ is generated; edit templates/, examples/, or the schema
          # descriptions in gigahost-go's tfprovider instead.
          docs = mkApp "docs" "Regenerate registry docs from the provider schema" gendocs;

          # The entire release process: pin gigahost-go to a commit,
          # regenerate registry docs from it, commit, tag.
          #
          #   nix run .#bump -- v0.0.1          # pins gigahost-go main
          #   nix run .#bump -- v0.0.1 <ref>    # or an explicit ref
          #   git push origin main v0.0.1
          #
          # Only this repo carries tags — gigahost-go is pinned by commit, so
          # go.mod records a pseudo-version. The version argument is this
          # provider's registry version.
          bump = mkApp "bump" "Pin gigahost-go, regenerate docs, commit and tag a release" ''
            version="''${1:?usage: nix run .#bump -- vX.Y.Z [gigahost-go-ref]}"
            ref="''${2:-main}"

            # Every check below happens before the first mutation. bump
            # rewrites go.mod, replaces docs/, commits and tags — none of which
            # is safe to do halfway, in the wrong directory, or on top of
            # unrelated work.
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

            grep -qx "## ''${version#v}" CHANGELOG.md || {
              echo "CHANGELOG.md has no '## ''${version#v}' section" >&2; exit 1; }

            # go.mod and docs/ are rewritten below; restore them if anything
            # after this fails.
            trap 'git checkout -- go.mod go.sum docs 2>/dev/null; git clean -fdq docs 2>/dev/null || true' ERR

            # A local go.work would document the checkout next door, not the pin.
            export GOWORK=off
            # Resolve the ref against GitHub: the proxy caches branch lookups,
            # so @main right after a push can still be the previous commit.
            export GOPRIVATE=github.com/kradalby/gigahost-go
            export GOFLAGS=-mod=mod

            go get "github.com/kradalby/gigahost-go@$ref"
            go mod tidy

            # A ref carrying a vX.Y.Z tag resolves to that version instead of
            # the pseudo-version this repo's whole versioning story depends on.
            pinned="$(go list -m -f '{{.Version}}' github.com/kradalby/gigahost-go)"
            echo "$pinned" | grep -qE -- '[.-][0-9]{14}-[0-9a-f]{12}$' || {
              echo "gigahost-go $ref resolved to $pinned, not a pseudo-version; is it tagged?" >&2
              git checkout -- go.mod go.sum
              exit 1; }
            sha="''${pinned##*-}"

            ${gendocs}

            # Explicit, so a stray file in the working tree cannot ride
            # along into a signed public release.
            git add go.mod go.sum docs
            git commit -m "release $version: gigahost-go $sha"
            git tag "$version"

            echo "tagged $version — now: git push origin main $version"
          '';

          # Signing is exercised only in CI at real releases, where the GPG
          # secrets live.
          snapshot = mkApp "snapshot" "Build an unsigned goreleaser snapshot" ''
            goreleaser release --snapshot --clean --skip=sign
          '';
        };
      }
    );
}

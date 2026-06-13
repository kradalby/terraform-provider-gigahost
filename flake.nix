{
  description = "terraform-provider-gigahost: registry shim for github.com/kradalby/gigahost-go/tfprovider";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { nixpkgs
    , flake-utils
    , ...
    }:
    flake-utils.lib.eachDefaultSystem
      (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        deps = with pkgs; [
          go_1_26
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
              ${text}
            '';
          };
      in
      {
        devShells.default = pkgs.mkShell { buildInputs = deps; };

        apps = {
          # The entire release process: pin gigahost-go to the given tag,
          # regenerate registry docs from that exact version, commit, tag.
          #
          #   nix run .#bump -- v0.2.0
          #   git push origin main v0.2.0
          #
          # Docs templates/examples live in gigahost-go under
          # terraform-provider-gigahost/, which is a nested module and thus
          # NOT part of the gigahost-go module zip — so the repo is cloned at
          # the exact tag instead. tfplugindocs cannot download Terraform
          # (expired signing key, and we ship OpenTofu), so the provider
          # schema is exported with tofu via a dev-override first.
          bump = mkApp "bump" ''
            version="''${1:?usage: nix run .#bump -- vX.Y.Z}"

            # gigahost-go is private (for now): skip proxy + sumdb.
            export GOPRIVATE=github.com/kradalby/*
            export GOFLAGS=-mod=mod

            go get "github.com/kradalby/gigahost-go@$version"
            go mod tidy

            tmp="$(mktemp -d)"
            trap 'rm -rf "$tmp"' EXIT

            git clone --quiet --depth 1 --branch "$version" \
              git@github.com:kradalby/gigahost-go.git "$tmp/gigahost-go"
            sub="$tmp/gigahost-go/terraform-provider-gigahost"

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
            (cd "$tmp/cfg" && TF_CLI_CONFIG_FILE="$tmp/dev.tfrc" tofu providers schema -json > "$tmp/schema.json" 2>/dev/null)

            # tfplugindocs resolves --examples-dir/--website-source-dir
            # relative to provider-dir, so stage them in the working tree
            # for the duration of the run.
            rm -rf docs templates examples
            cp -R "$sub/templates" templates
            cp -R "$sub/examples" examples
            trap 'rm -rf templates examples; rm -rf "$tmp"' EXIT

            tfplugindocs generate \
              --provider-name gigahost \
              --rendered-provider-name Gigahost \
              --providers-schema "$tmp/schema.json" \
              --rendered-website-dir docs

            rm -rf templates examples

            git add -A
            git commit -m "release $version: gigahost-go $version"
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

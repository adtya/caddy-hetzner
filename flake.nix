{
  description = "Flake providing Caddy executable with Hetzner DNS module";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils?ref=main";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
      };
      version = builtins.substring 0 8 (self.lastModifiedDate or self.lastModified or "19700101");
      caddy-src = pkgs.fetchFromGitHub {
        owner = "caddyserver";
        repo = "dist";
        rev = "v2.9.1";
        hash = "sha256-28ahonJ0qeynoqf02gws0LstaL4E08dywSJ8s3tgEDI=";
      };
    in {
      formatter = pkgs.alejandra;
      devShells.default = pkgs.mkShell {
        packages = [
          pkgs.go
        ];
      };
      packages = {
        caddy = pkgs.buildGoModule {
          pname = "caddy";
          inherit version;
          src = ./src;
          runVend = true;
          vendorHash = "sha256-rH4J33idvgkAmXF3NbHolifUwcq7EEIP7zJUy+Qvorw=";

          ldflags = [
            "-s"
            "-w"
            "-X github.com/caddyserver/caddy/v2.CustomVersion=${version}"
          ];

          nativeBuildInputs = [pkgs.installShellFiles];
          postInstall = ''
            install -Dm644 ${caddy-src}/init/caddy.service ${caddy-src}/init/caddy-api.service -t $out/lib/systemd/system

            substituteInPlace $out/lib/systemd/system/caddy.service --replace "/usr/bin/caddy" "$out/bin/caddy"
            substituteInPlace $out/lib/systemd/system/caddy-api.service --replace "/usr/bin/caddy" "$out/bin/caddy"

            $out/bin/caddy manpage --directory manpages
            installManPage manpages/*

            installShellCompletion --cmd caddy \
              --bash <($out/bin/caddy completion bash) \
              --fish <($out/bin/caddy completion fish) \
              --zsh <($out/bin/caddy completion zsh)
          '';
          meta = with pkgs.lib; {
            homepage = "https://caddyserver.com";
            description = "Fast and extensible multi-platform HTTP/1-2-3 web server with automatic HTTPS";
            license = licenses.asl20;
            mainProgram = "caddy";
          };
        };
      };
    });
}

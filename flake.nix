{
  description = "purescript - compiled from source";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
  flake-utils.lib.eachDefaultSystem (
    system:
    let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
        ];
      };

      buildInputs = with pkgs; [
        darwin.apple_sdk.frameworks.CoreServices
        darwin.apple_sdk.frameworks.Cocoa
        darwin.objc4.all
        zlib

        haskell.compiler.ghc923
        stack
      ];

      stackPackage = { name, owner, repo, rev, sha256 }: pkgs.stdenv.mkDerivation {
        inherit buildInputs;
        inherit name;

        src = pkgs.fetchFromGitHub {
          inherit owner repo rev sha256;
        };

        preConfigure = ''
          export STACK_ROOT=$NIX_BUILD_TOP/.stack
        '';

        # /dev/null due to https://github.com/commercialhaskell/stack/issues/5607
        buildPhase = ''
          runHook preBuild
          stack --system-ghc build > /dev/null
          runHook postBuild
        '';

        checkPhase = ''
          runHook preCheck
          stack --system-ghc test > /dev/null
          runHook postCheck
        '';

        installPhase = ''
          runHook preInstall
          stack --system-ghc --local-bin-path=$out/bin build --copy-bins > /dev/null
          runHook postInstall
        '';
      };
    in
    {

      packages.purescript-arm = stackPackage {
          name = "purescript";
          owner = "purescript";
          repo = "purescript";
          rev = "9870ec72cf74708e1b1cfaf01c23e05168f0d691";
          sha256 = "sha256-dQBSNghRMGj0DK+08SgCQESBWkPPUPrzuBVNk964X4Y=";
      };

      # packages.spago-arm = stackPackage {
      #   name = "spago";
      #   owner = "purescript";
      #   repo = "spago";
      #   rev = "d16d4914200783fbd820ba89dbdf67270454faf5";
      #   sha256 = "sha256-dQBSNghRMGj0DK+08SgCQESBWkPPUPrzuBVNk964X4Y=";
      # };

      devShell = pkgs.mkShell {
        name = "purescript-dev";
        inherit buildInputs;
      };
    }
  );
}

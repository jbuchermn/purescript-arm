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
        haskell.compiler.ghc8107
        stack
      ];

      stackPackage = { name, owner, repo, rev, sha256, spagoDoc }: 
      let
        docsSearchApp_0_0_10 = pkgs.fetchurl {
          url = "https://github.com/purescript/purescript-docs-search/releases/download/v0.0.10/docs-search-app.js";
          sha256 = "0m5ah29x290r0zk19hx2wix2djy7bs4plh9kvjz6bs9r45x25pa5";
        };

        docsSearchApp_0_0_11 = pkgs.fetchurl {
          url = "https://github.com/purescript/purescript-docs-search/releases/download/v0.0.11/docs-search-app.js";
          sha256 = "17qngsdxfg96cka1cgrl3zdrpal8ll6vyhhnazqm4hwj16ywjm02";
        };

        purescriptDocsSearch_0_0_10 = pkgs.fetchurl {
          url = "https://github.com/purescript/purescript-docs-search/releases/download/v0.0.10/purescript-docs-search";
          sha256 = "0wc1zyhli4m2yykc6i0crm048gyizxh7b81n8xc4yb7ibjqwhyj3";
        };

        purescriptDocsSearch_0_0_11 = pkgs.fetchurl {
          url = "https://github.com/purescript/purescript-docs-search/releases/download/v0.0.11/purescript-docs-search";
          sha256 = "1hjdprm990vyxz86fgq14ajn0lkams7i00h8k2i2g1a0hjdwppq6";
        };

      in pkgs.stdenv.mkDerivation {
        inherit buildInputs;
        inherit name;

        __noChroot = true;

        src = pkgs.fetchFromGitHub {
          inherit owner repo rev sha256;
        };

        postUnpack = if spagoDoc then ''
          # Spago includes the following two files directly into the binary
          # with Template Haskell.  They are fetched at build-time from the
          # `purescript-docs-search` repo above.  If they cannot be fetched at
          # build-time, they are pulled in from the `templates/` directory in
          # the spago source.
          #
          # However, they are not actually available in the spago source, so they
          # need to fetched with nix and put in the correct place.
          # https://github.com/spacchetti/spago/issues/510
          cp ${docsSearchApp_0_0_10} "$sourceRoot/templates/docs-search-app-0.0.10.js"
          cp ${docsSearchApp_0_0_11} "$sourceRoot/templates/docs-search-app-0.0.11.js"
          cp ${purescriptDocsSearch_0_0_10} "$sourceRoot/templates/purescript-docs-search-0.0.10"
          cp ${purescriptDocsSearch_0_0_11} "$sourceRoot/templates/purescript-docs-search-0.0.11"

          # For some weird reason, on Darwin, the open(2) call to embed these files
          # requires write permissions. The easiest resolution is just to permit that
          # (doesn't cause any harm on other systems).
          chmod u+w \
            "$sourceRoot/templates/docs-search-app-0.0.10.js" \
            "$sourceRoot/templates/purescript-docs-search-0.0.10" \
            "$sourceRoot/templates/docs-search-app-0.0.11.js" \
            "$sourceRoot/templates/purescript-docs-search-0.0.11"
        '' else "";

        # Requires network access
        doCheck = false;

        preConfigure = ''
          export STACK_ROOT=$NIX_BUILD_TOP/.stack
        '';

        # /dev/null due to https://github.com/commercialhaskell/stack/issues/5607
        buildPhase = ''
          runHook preBuild
          stack --system-ghc --prefetch build > /dev/null
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
        spagoDoc = false;
      };

      packages.spago-arm = stackPackage {
        name = "spago";
        owner = "purescript";
        repo = "spago";
        rev = "d16d4914200783fbd820ba89dbdf67270454faf5";
        sha256 = "sha256-MMKt5BWpdvKxGlLB/5TkFEKXODUIHQL5T21wtc/DbQM=";
        spagoDoc = true;
      };

      devShell = pkgs.mkShell {
        name = "purescript-dev";
        buildInputs = buildInputs ++ [
          self.packages.${system}.purescript-arm
          self.packages.${system}.spago-arm
        ];
      };
    }
  );
}

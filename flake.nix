{
  description = "Num Lean package";

  inputs = {
    lean = {
      url = github:leanprover/lean4;
    };
    nixpkgs.url = github:nixos/nixpkgs/nixos-21.05;
    utils = {
      url = github:yatima-inc/nix-utils;
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, lean, utils, nixpkgs }:
    let
      supportedSystems = [
        # "aarch64-linux"
        # "aarch64-darwin"
        "i686-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      inherit (utils) lib;
    in
    lib.eachSystem supportedSystems (system:
      let
        leanPkgs = lean.packages.${system};
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (utils.lib.${system}) buildCLib;
        cpp = buildCLib {
          name = "native-cpp";
          updateCCOptions = d: d ++ [ "-I${leanPkgs.lean-bin-tools-unwrapped}/include" ];
          sourceFiles = [ "ffi.cpp" ];
          src = ./cpp;
          extraDrvArgs = { linkName = "native-cpp"; };
        };
        Utils = leanPkgs.buildLeanPackage {
          name = "Utils";  # must match the name of the top-level .lean file
          # Where the lean files are located
          src = ./lib;
        };
        NumLean = leanPkgs.buildLeanPackage {
          name = "NumLean";
          deps = [ Utils ];
          # Where the lean files are located
          src = ./lib;
          nativeSharedLibs = [ cpp.sharedLib ];
        };
        Main = leanPkgs.buildLeanPackage {
          name = "Main";
          deps = [ NumLean ];
          # Where the lean files are located
          src = ./lib;
        };
        test = leanPkgs.buildLeanPackage {
          name = "Tests";
          deps = [ NumLean ];
          # Where the lean files are located
          src = ./test;
        };
        joinDepsDerivationns = getSubDrv:
          pkgs.lib.concatStringsSep ":" (map (d: "${getSubDrv d}") ([ NumLean Main Utils ] ++ NumLean.allExternalDeps));
      in
      {
        inherit NumLean Main Utils test;
        packages = {
          inherit cpp;
          test = test.executable;
          Main = Main.executable;
        };

        checks.test = test.executable;

        defaultPackage = self.packages.${system}.Main;
        devShell = pkgs.mkShell {
          inputsFrom = [ NumLean.executable ];
          buildInputs = with pkgs; [
            leanPkgs.lean
          ];
          LEAN_PATH = joinDepsDerivationns (d: d.modRoot);
          LEAN_SRC_PATH = joinDepsDerivationns (d: d.src);
        };
      });
}

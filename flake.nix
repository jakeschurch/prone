{
  description = "Prone is a script that generates a lockfile from your github dependencies";

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {inherit system;};
        drv-name = "prone";
        script =
          (
            pkgs.writeScriptBin drv-name (builtins.readFile ./prone.sh)
          )
          .overrideAttrs (old: {
            buildCommand = "${old.buildCommand}\n patchShebangs $out";
          });
        scriptBuildInputs = with pkgs; [gh jq];
      in rec {
        defaultPackage = packages."${drv-name}";
        packages."${drv-name}" = pkgs.symlinkJoin {
          name = drv-name;
          paths = [script] ++ scriptBuildInputs;
          buildInputs = [pkgs.makeWrapper];
          postBuild = "wrapProgram $out/bin/${drv-name} --prefix PATH : $out/bin";
        };
      }
    );
}

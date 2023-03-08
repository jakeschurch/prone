with import <nixpkgs> {}; let
  drv-name = "prone";
  script-src = builtins.readFile ./prone.sh;
  script = (pkgs.writeScriptBin drv-name script-src).overrideAttrs (old: {
    buildCommand = "${old.buildCommand}\n patchShebangs $out";
  });
  scriptBuildInputs = [gh jq];
in
  pkgs.symlinkJoin {
    name = drv-name;
    paths = [script] ++ scriptBuildInputs;
    buildInputs = [pkgs.makeWrapper];
    postBuild = "wrapProgram $out/bin/${drv-name} --prefix PATH : $out/bin";
  }

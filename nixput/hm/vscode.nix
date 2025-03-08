{ config, lib, ... }:
let
  cfg = config.nixput.targets.vscode;
in
{
  config = lib.mkIf cfg.enable {
    programs.vscode.profiles.default.keybindings = lib.pipe cfg.bindings [
      builtins.attrValues
      (builtins.map (keybind: {
        key = if lib.isList keybind.bind then lib.concatStringsSep "+" keybind.bind else keybind.bind;
        command = keybind.action;
        when = keybind.context;
      }))
    ];
  };
}

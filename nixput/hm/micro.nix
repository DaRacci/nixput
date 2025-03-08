{ config, lib, ... }:
let
  cfg = config.nixput.targets.micro;
in
{
  config = lib.mkIf cfg.enable {
    xdg.configFile."micro/bindings.json".text =
      let
        bindingToAttrName = bind: if lib.isList bind then lib.concatStringsSep "-" bind else bind;
      in
      lib.generators.toJSON { } (
        lib.pipe cfg.bindings [
          builtins.attrValues
          (builtins.map (keybind: lib.nameValuePair (bindingToAttrName keybind.bind) keybind.action))
          builtins.listToAttrs
        ]
      );
  };
}

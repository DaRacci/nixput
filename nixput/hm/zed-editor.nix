# TODO - Platform specific keymaps
{
  flake,
  config,
  lib,
  ...
}:
let
  cfg = config.nixput.targets.zed-editor;

  editorContexts = lib.pipe cfg.bindings [
    builtins.attrValues
    (builtins.map (keybind: keybind.context))
    lib.unique
  ];
  bindingToAttrName = bind: if lib.isList bind then lib.concatStringsSep "-" bind else bind;

  baseKeymap = builtins.fromJSON (
    builtins.readFile "${flake}/resources/zed-editor/default-linux.json"
  );

  userKeymap = lib.pipe editorContexts [
    (builtins.map (context: {
      inherit context;
      bindings = lib.pipe cfg.bindings [
        builtins.attrValues
        (builtins.filter (keybind: keybind.context == context))
        (builtins.map (keybind: lib.nameValuePair (bindingToAttrName keybind.bind) keybind.action))
        builtins.listToAttrs
      ];
    }))
    (lib.filter (value: value.bindings != { }))
  ];

  mergedKeymap = builtins.map (
    defaultGroup:
    let
      # thisIsLastContextInList = lib.pipe baseKeymap [
      #   (builtins.filter (keymap: (keymap.context or null) == (defaultGroup.context or null)))
      #   (lib.lists.last)
      #   (keymap: keymap == defaultGroup)
      # ];

      userBindings = lib.pipe userKeymap [
        (builtins.filter (
          keymap:
          let
            defaultContext = defaultGroup.context or null;
            userContext = keymap.context or null;
          in
          defaultContext == userContext
        ))
        (builtins.map (keymap: keymap.bindings))
        (lib.foldl' lib.recursiveUpdate { })
      ];

      overriddenActions = lib.pipe userBindings [
        (lib.filterAttrs (_: action: builtins.elem action (builtins.attrValues defaultGroup.bindings)))
      ];
    in
    {
      # FIXME - This could result in keybinds not being added if they are not overriding anything.
      bindings =
        (lib.filterAttrs (
          _: action: !builtins.elem action (builtins.attrValues overriddenActions)
        ) defaultGroup.bindings)
        // overriddenActions;
    }
    // lib.optionalAttrs (defaultGroup ? context) {
      inherit (defaultGroup) context;
    }
  ) baseKeymap;
in
{
  config = lib.mkIf cfg.enable {
    programs.zed-editor.userKeymaps = mergedKeymap;
  };
}

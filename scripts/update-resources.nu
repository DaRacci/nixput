#!/usr/bin/env nix-shell
#! nix-shell -i nu -p

def main [] {
  let resources = open $"($env.FILE_PWD)/../resources/resources.json" --raw | from json | get resources
  for $resource in $resources {
    mut source = $resource.source
    for $variable in $resource.variables {
      $source = $source | str replace --all $variable.name (nu -c $"($variable.expression) | to nuon" | from nuon)
    }

    print $"Updating ($resource.destination) from ($source)"
    mut content = http get $source --raw

    # If the destination is a json file, ensure that there are no comments.
    # This is necessary because the Nix parser does not support comments.
    if ($resource.destination | str ends-with ".json") {
      # Replace all unicode escape sequences with a double backslash to prevent nu from interpreting them.
      $content = $content
        | str replace "\\u" "\\\\u" --all
        | from json
        | to json
        | str replace "\\\\u" "\\u" --all
    }

    $content | save --force $resource.destination
  }
}

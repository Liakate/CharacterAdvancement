## This is not a "ready-to-install single addon zip"

This pack contains multiple addon folders (plus some shared FrameXML utility files) so it is meant for learning/reference and not as a single one-folder release.

# Annotated UI Source (-Friendly)

This package is the same set of `.lua` and `.xml` files as the original dump, but with extra **GUIDE** and **DOC** comments added.

## What you are looking at

- **.xml files**: describe the *layout* of the UI (frames, buttons, text, sizes, positions).
- **.lua files**: describe the *behavior* of the UI (what happens when you click, when data changes, etc.).

The game reads these files when it loads the addon(s). Comments are ignored by the game.

## How the new comments are marked

- In **Lua** (`.lua`): comments start with `--` and blocks look like:

  - `--[[ GUIDE:... --]]` (file-level overview)
  - `--[[ DOC: SomeFunctionName... --]]` (function-level explanation)

- In **XML** (`.xml`): comments look like:

  - `<!-- GUIDE:... -->` (file-level overview)
  - `<!-- NOTE:... -->` (element-level explanation)

## Added some practical examples

- CA_Pratical_Usage.md

## This is not a "ready-to-install single addon zip"

This pack contains multiple addon folders (plus some shared FrameXML utility files) so it is meant for learning/reference and not as a single one-folder release.

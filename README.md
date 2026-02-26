[![Release](https://img.shields.io/github/v/release/Liakate/CharacterAdvancement?display_name=tag&sort=date)](https://github.com/Liakate/CharacterAdvancement/releases/latest)

# CharacterAdvancement UI Source (Annotated)

> **Note:** This is **not** a “single ready-to-install addon zip”.
> It contains **multiple AddOn folders** (plus a couple of shared FrameXML utility files) and is intended for **learning / reference**.

## What this repo contains

This package mirrors the `.lua` / `.xml` files used by Bronzebeard’s **Collections → Character Advancement** UI, with extra **GUIDE** and **DOC** comments added for readability.

### Included AddOns (all `LoadOnDemand`)

- `Ascension_Collections` — Collections shell + tab system
- `Ascension_CharacterAdvancement` — Character Advancement UI (normal classes)
- `Ascension_CharacterAdvancementSeason9` — Season 9 variant (if your client uses it)
- `Ascension_TalentUI` — shared talent UI dependency
- `Ascension_CoATalents` — CoA (Custom Class) replacement frame

### Shared FrameXML utility files

- `Interface/FrameXML/Util/CharacterAdvancementUtil.lua`
- `Interface/FrameXML/Util/CharacterAdvancementCostUtil.lua`

## How to use these files

- Use this repo as a **reference** while developing / debugging UI behavior.
- For hands-on console commands to probe the UI and APIs, see:
  - **CA_Pratical_Usage.md** (practical `/run` snippets)
  - **CA_Pratical_AddonUsage.md** (small addon examples that wrap the same probes)
  - **LOADED_FILES.md** (what loads when the UI opens)

## Comment markers used in the annotated sources

- **Lua (`.lua`)**
  - `--[[ GUIDE: ... --]]` (file-level overview)
  - `--[[ DOC: SomeFunctionName ... --]]` (function-level explanation)
- **XML (`.xml`)**
  - `<!-- GUIDE: ... -->` (file-level overview)
  - `<!-- NOTE: ... -->` (element-level explanation)

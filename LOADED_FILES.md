# Bronzebeard Character Advancement — Loaded Files

This bundle contains the **exact Lua/XML/TOC files** involved in opening the in-game **Collections → Character Advancement** UI on Bronzebeard,
as captured in the provided `interface.zip` proof pack.

## Table of contents
- [What loads when you open the frame](#what-loads-when-you-open-the-frame)
  - [Always (Collections shell)](#always-collections-shell)
  - [Normal classes (Character Advancement UI)](#normal-classes-character-advancement-ui)
  - [Season 9 variant (if your client uses it)](#season-9-variant-if-your-client-uses-it)
  - [Custom Class characters (CoA Talents replacement frame)](#custom-class-characters-coa-talents-replacement-frame)
  - [Shared utility used by the above UIs](#shared-utility-used-by-the-above-uis)
- [Note about textures](#note-about-textures)

## What loads when you open the frame

### Always (Collections shell)
- `Interface/AddOns/Ascension_Collections/Ascension_Collections.toc` (LoadOnDemand)
  - `CollectionsTabMixin.lua`
  - `Collections.xml` → loads `Collections.lua`

### Normal classes (Character Advancement UI)
- `Interface/AddOns/Ascension_CharacterAdvancement/Ascension_CharacterAdvancement.toc` (LoadOnDemand, depends on Ascension_Collections)
  - `Templates/CharacterAdvancementTemplates.xml` → loads:
    - `CAConnectedNodes.lua`, `CABranchTexture.lua`, `CAClassButton.lua`, `CASpellButton.lua`, `CASpecTab.lua`, `CARarityBar.lua`, `CAGate.lua`, `CASpellCategory.lua`, `CATalentBrowser.lua`
  - `Browser/CharacterAdvancementBrowser.xml` → loads `CharacterAdvancementBrowser.lua`
  - `CharacterAdvancement.xml` → loads `CharacterAdvancement.lua`

### Season 9 variant (if your client uses it)
- Same structure as above, but under:
  - `Interface/AddOns/Ascension_CharacterAdvancementSeason9/`

### Custom Class characters (CoA Talents replacement frame)
- `Interface/AddOns/Ascension_CoATalents/Ascension_CoATalents.toc` (LoadOnDemand, depends on Ascension_Collections + Ascension_TalentUI)
  - `CoACharacterAdvancementUtil.lua`
  - `Templates/CoATalentTemplates.xml` → loads `CoASpecChoiceMixin.lua`, `CoATalentTemplates.lua`
  - `CoATalentFrame.xml` → loads `CoATreeViewMixin.lua`, `CoASpecViewMixin.lua`, `CoATalentFrame.lua`
- `Interface/AddOns/Ascension_TalentUI/Ascension_TalentUI.toc` (dependency)

### Shared utility used by the above UIs
- `Interface/FrameXML/Util/CharacterAdvancementUtil.lua`
- `Interface/FrameXML/Util/CharacterAdvancementCostUtil.lua` (present in the pack)

## Note about textures
The XML/Lua references many texture paths (e.g. `Interface\\...`).
Those textures typically live inside the game’s MPQ/CASC data, not as loose files in this proof pack, so they are not included here.

## Included files in this ZIP

<details>
<summary>Show full file list</summary>

- `Interface/AddOns/Ascension_CharacterAdvancement/Ascension_CharacterAdvancement.toc`
- `Interface/AddOns/Ascension_CharacterAdvancement/Browser/CharacterAdvancementBrowser.lua`
- `Interface/AddOns/Ascension_CharacterAdvancement/Browser/CharacterAdvancementBrowser.xml`
- `Interface/AddOns/Ascension_CharacterAdvancement/CharacterAdvancement.lua`
- `Interface/AddOns/Ascension_CharacterAdvancement/CharacterAdvancement.xml`
- `Interface/AddOns/Ascension_CharacterAdvancement/Templates/CABranchTexture.lua`
- `Interface/AddOns/Ascension_CharacterAdvancement/Templates/CAClassButton.lua`
- `Interface/AddOns/Ascension_CharacterAdvancement/Templates/CAConnectedNodes.lua`
- `Interface/AddOns/Ascension_CharacterAdvancement/Templates/CAGate.lua`
- `Interface/AddOns/Ascension_CharacterAdvancement/Templates/CARarityBar.lua`
- `Interface/AddOns/Ascension_CharacterAdvancement/Templates/CASpecTab.lua`
- `Interface/AddOns/Ascension_CharacterAdvancement/Templates/CASpellButton.lua`
- `Interface/AddOns/Ascension_CharacterAdvancement/Templates/CASpellCategory.lua`
- `Interface/AddOns/Ascension_CharacterAdvancement/Templates/CATalentBrowser.lua`
- `Interface/AddOns/Ascension_CharacterAdvancement/Templates/CharacterAdvancementTemplates.xml`
- `Interface/AddOns/Ascension_CharacterAdvancementSeason9/Ascension_CharacterAdvancementSeason9.toc`
- `Interface/AddOns/Ascension_CharacterAdvancementSeason9/Browser/CharacterAdvancementBrowser.lua`
- `Interface/AddOns/Ascension_CharacterAdvancementSeason9/Browser/CharacterAdvancementBrowser.xml`
- `Interface/AddOns/Ascension_CharacterAdvancementSeason9/CharacterAdvancement.lua`
- `Interface/AddOns/Ascension_CharacterAdvancementSeason9/CharacterAdvancement.xml`
- `Interface/AddOns/Ascension_CharacterAdvancementSeason9/Templates/CAClassButton.lua`
- `Interface/AddOns/Ascension_CharacterAdvancementSeason9/Templates/CAGate.lua`
- `Interface/AddOns/Ascension_CharacterAdvancementSeason9/Templates/CARarityBar.lua`
- `Interface/AddOns/Ascension_CharacterAdvancementSeason9/Templates/CASpecTab.lua`
- `Interface/AddOns/Ascension_CharacterAdvancementSeason9/Templates/CASpellButton.lua`
- `Interface/AddOns/Ascension_CharacterAdvancementSeason9/Templates/CharacterAdvancementTemplates.xml`
- `Interface/AddOns/Ascension_CoATalents/Ascension_CoATalents.toc`
- `Interface/AddOns/Ascension_CoATalents/CoACharacterAdvancementUtil.lua`
- `Interface/AddOns/Ascension_CoATalents/CoASpecViewMixin.lua`
- `Interface/AddOns/Ascension_CoATalents/CoATalentFrame.lua`
- `Interface/AddOns/Ascension_CoATalents/CoATalentFrame.xml`
- `Interface/AddOns/Ascension_CoATalents/CoATreeViewMixin.lua`
- `Interface/AddOns/Ascension_CoATalents/Templates/CoASpecChoiceMixin.lua`
- `Interface/AddOns/Ascension_CoATalents/Templates/CoATalentTemplates.lua`
- `Interface/AddOns/Ascension_CoATalents/Templates/CoATalentTemplates.xml`
- `Interface/AddOns/Ascension_Collections/Ascension_Collections.toc`
- `Interface/AddOns/Ascension_Collections/Collections.lua`
- `Interface/AddOns/Ascension_Collections/Collections.xml`
- `Interface/AddOns/Ascension_Collections/CollectionsTabMixin.lua`
- `Interface/AddOns/Ascension_TalentUI/Ascension_TalentUI.toc`
- `Interface/AddOns/Ascension_TalentUI/Ascension_TalentUI.xml`
- `Interface/AddOns/Ascension_TalentUI/TalentTreeBase.lua`
- `Interface/FrameXML/Util/CharacterAdvancementCostUtil.lua`
- `Interface/FrameXML/Util/CharacterAdvancementUtil.lua`

</details>

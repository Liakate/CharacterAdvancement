# Character Advancement — Practical AddOn Usage

This document converts the **`/run` console snippets** from **CA_Pratical_Usage.md** into **small addon examples** you can drop into your `Interface/AddOns/` folder.

## How to use these examples

Each example below is a *standalone mini-addon*:

1. Create a folder in `Interface/AddOns/` matching the addon name (example: `CA_Example_LoadPack/`)
2. Add the `.toc` and `.lua` files shown.
3. Restart the client (or `/reload`).
4. Use the listed slash commands.

> Notes
> - Many of the UI folders in the CharacterAdvancement repo are **LoadOnDemand**. These examples often call `LoadAddOn()` first.
> - Everything here is **WotLK 3.3.5a-compatible** (no modern `C_AddOns`, no `C_Timer`).

---

## 1) Load the pack (required for most commands)

### AddOn: `CA_Example_LoadPack`

**What it does:** loads the UI pack folders and prints load results + TOC metadata.

**Commands:**
- `/caload` — load the pack (tries all known folders)
- `/cameta` — print loaded state + Version + Interface

**CA_Example_LoadPack.toc**
```toc
## Interface: 30300
## Title: CA Example - Load Pack
## Notes: Loads CharacterAdvancement UI pack folders and prints status.
## Author: You
## Version: 0.1.0

CA_Example_LoadPack.lua
```

**CA_Example_LoadPack.lua**
```lua
local ADDONS = {
  "Ascension_Collections",
  "Ascension_TalentUI",
  "Ascension_CoATalents",
  "Ascension_CharacterAdvancement",
  "Ascension_CharacterAdvancementSeason9",
}

local function PrintMeta(a)
  print(a,
    "loaded", IsAddOnLoaded(a),
    "ver", GetAddOnMetadata(a, "Version"),
    "iface", GetAddOnMetadata(a, "Interface"))
end

SLASH_CAEXLOAD1 = "/caload"
SlashCmdList.CAEXLOAD = function()
  for _, a in ipairs(ADDONS) do
    local ok, why = LoadAddOn(a)
    print("LoadAddOn", a, ok, why)
  end
end

SLASH_CAEXMETA1 = "/cameta"
SlashCmdList.CAEXMETA = function()
  for _, a in ipairs(ADDONS) do
    PrintMeta(a)
  end
end
```

---

## 2) Verify UI objects + navigate Collections tabs

### AddOn: `CA_Example_CollectionsTabs`

**What it does:**
- checks expected global frames exist
- lists `Collections.Tabs`
- jumps to a tab

**Commands:**
- `/caframes` — prints whether key globals exist
- `/catabs` — lists all Collections tab keys/IDs
- `/catab <key>` — go to tab (example: `/catab CharacterAdvancement`)

**CA_Example_CollectionsTabs.toc**
```toc
## Interface: 30300
## Title: CA Example - Collections Tabs
## Notes: List and jump to Collections tabs used by CharacterAdvancement.
## Author: You
## Version: 0.1.0

CA_Example_CollectionsTabs.lua
```

**CA_Example_CollectionsTabs.lua**
```lua
local function EnsureCollections()
  if not IsAddOnLoaded("Ascension_Collections") then
    LoadAddOn("Ascension_Collections")
  end
  return Collections and Collections.Tabs
end

SLASH_CAFRAMES1 = "/caframes"
SlashCmdList.CAFRAMES = function()
  print("Collections", Collections and "OK" or "nil",
        "CharacterAdvancement", CharacterAdvancement and "OK" or "nil",
        "CoATalentFrame", CoATalentFrame and "OK" or "nil")
end

SLASH_CATABS1 = "/catabs"
SlashCmdList.CATABS = function()
  if not EnsureCollections() then
    print("Collections.Tabs missing (is Ascension_Collections loaded?)")
    return
  end
  for k, v in pairs(Collections.Tabs) do
    print("Tab", k, v)
  end
end

SLASH_CATAB1 = "/catab"
SlashCmdList.CATAB = function(msg)
  msg = (msg or ""):gsub("^%s+", ""):gsub("%s+$", "")
  if msg == "" then
    print("Usage: /catab <TabKey>   (example: /catab CharacterAdvancement)")
    return
  end
  if not EnsureCollections() then
    print("Collections.Tabs missing (is Ascension_Collections loaded?)")
    return
  end
  local id = Collections.Tabs[msg]
  if not id then
    print("Unknown tab key:", msg)
    return
  end
  Collections:GoToTab(id)
end
```

---

## 3) Realm / mode snapshot (context for bug reports)

### AddOn: `CA_Example_Context`

**Commands:**
- `/cacontext` — prints client build, realm, hero/custom-class flags, gamemodes (if available)

**CA_Example_Context.toc**
```toc
## Interface: 30300
## Title: CA Example - Context
## Notes: Prints client + realm + mode context useful for debugging UI behavior.
## Author: You
## Version: 0.1.0

CA_Example_Context.lua
```

**CA_Example_Context.lua**
```lua
local function SafeBool(v) return v and "true" or "false" end

SLASH_CACONTEXT1 = "/cacontext"
SlashCmdList.CACONTEXT = function()
  local v, b, d, toc = GetBuildInfo()
  print("build", v, "build#", b, "date", d, "toc", toc, "locale", GetLocale())

  print("realm", GetRealmName())
  if C_Realm and C_Realm.IsLive then print("C_Realm.IsLive", SafeBool(C_Realm.IsLive())) end
  if C_Realm and C_Realm.IsDevelopment then print("C_Realm.IsDev", SafeBool(C_Realm.IsDevelopment())) end

  local cn, cf = UnitClass("player")
  local isHero = (C_Player and C_Player.IsHero and C_Player:IsHero()) and true or false
  print("lvl", UnitLevel("player"), cn, cf, "hero", SafeBool(isHero), "customClass", SafeBool(IsCustomClass()))

  if C_GameMode and Enum and Enum.GameMode then
    for k, id in pairs(Enum.GameMode) do
      if type(id) == "number" then
        print("GameMode", k, id, SafeBool(C_GameMode:IsGameModeActive(id)))
      end
    end
  else
    print("no C_GameMode/Enum.GameMode")
  end
end
```

---

## 4) Character Advancement state snapshot (pending build, spec, points)

### AddOn: `CA_Example_Snapshot`

**Commands:**
- `/casnap` — prints pending build flags + remaining AE/TE + learned AE/TE + expected AE + active spec

**CA_Example_Snapshot.toc**
```toc
## Interface: 30300
## Title: CA Example - Snapshot
## Notes: Prints C_CharacterAdvancement state snapshot used by the UI.
## Author: You
## Version: 0.1.0

CA_Example_Snapshot.lua
```

**CA_Example_Snapshot.lua**
```lua
local function EnsureCA()
  if not (C_CharacterAdvancement and C_CharacterAdvancement.IsPending) then
    LoadAddOn("Ascension_CharacterAdvancement")
    LoadAddOn("Ascension_CharacterAdvancementSeason9")
  end
  return C_CharacterAdvancement and C_CharacterAdvancement.IsPending
end

SLASH_CASNAP1 = "/casnap"
SlashCmdList.CASNAP = function()
  if not EnsureCA() then
    print("C_CharacterAdvancement missing (is the UI pack loaded?)")
    return
  end

  print("pending",
    C_CharacterAdvancement.IsPending(),
    "canApply", C_CharacterAdvancement.CanApplyPendingBuild(),
    "canClear", C_CharacterAdvancement.CanClearPendingBuild())

  print("pendingRemaining AE", C_CharacterAdvancement.GetPendingRemainingAE(),
        "TE", C_CharacterAdvancement.GetPendingRemainingTE())

  local l = UnitLevel("player")
  print("lvl", l,
    "learnedAE", C_CharacterAdvancement.GetLearnedAE(),
    "learnedTE", C_CharacterAdvancement.GetLearnedTE(),
    "expectedAE", C_CharacterAdvancement.GetExpectedAE(l))

  print("activeChrSpec", C_CharacterAdvancement.GetActiveChrSpec(),
        "canSwitch", C_CharacterAdvancement.CanSwitchActiveChrSpec())
end
```

---

## 5) Lists (first N) + tooltip SpellID → CA EntryID mapping

### AddOn: `CA_Example_Lists`

**Commands:**
- `/caknown spells [N]` — prints first N known spell entries
- `/caknown talents [N]` — prints first N known talent entries
- `/caentry` — hover a spell tooltip, then prints SpellID → CA entry

**CA_Example_Lists.toc**
```toc
## Interface: 30300
## Title: CA Example - Lists
## Notes: Prints first-N lists and tooltip SpellID -> CA entry mapping.
## Author: You
## Version: 0.1.0

CA_Example_Lists.lua
```

**CA_Example_Lists.lua**
```lua
local function EnsureCA()
  if not (C_CharacterAdvancement and C_CharacterAdvancement.GetKnownSpellEntries) then
    LoadAddOn("Ascension_CharacterAdvancement")
    LoadAddOn("Ascension_CharacterAdvancementSeason9")
  end
  return C_CharacterAdvancement and C_CharacterAdvancement.GetKnownSpellEntries
end

local function PrintEntries(t, n)
  print("count", #t)
  for i = 1, math.min(#t, n) do
    local e = t[i]
    print(i, "Entry", e.ID, "Spell", e.Spells and e.Spells[1], e.Name)
  end
end

SLASH_CAKNOWN1 = "/caknown"
SlashCmdList.CAKNOWN = function(msg)
  if not EnsureCA() then
    print("C_CharacterAdvancement missing (is the UI pack loaded?)")
    return
  end

  msg = msg or ""
  local kind, n = msg:match("^(%S+)%s*(%d*)$")
  kind = (kind or ""):lower()
  n = tonumber(n) or 20

  if kind == "spells" then
    PrintEntries(C_CharacterAdvancement.GetKnownSpellEntries(), n)
  elseif kind == "talents" then
    PrintEntries(C_CharacterAdvancement.GetKnownTalentEntries(), n)
  else
    print("Usage: /caknown spells [N]  OR  /caknown talents [N]")
  end
end

SLASH_CAENTRY1 = "/caentry"
SlashCmdList.CAENTRY = function()
  if not EnsureCA() then
    print("C_CharacterAdvancement missing (is the UI pack loaded?)")
    return
  end

  local name, _, sid = GameTooltip:GetSpell()
  print("tooltip", name, sid)
  if sid then
    local e = C_CharacterAdvancement.GetEntryBySpellID(sid)
    print("CA entry", e and e.ID, e and e.Type, e and e.RequiredLevel)
  end
end
```

---

## 6) Class-scoped lists (spells, talents, masteries, implicit traits)

### AddOn: `CA_Example_ClassLists`

**Commands:**
- `/caclass spells [N]`
- `/caclass talents [N]`
- `/caclass masteries [N]`
- `/caclass traits [N]`

**CA_Example_ClassLists.toc**
```toc
## Interface: 30300
## Title: CA Example - Class Lists
## Notes: Class-scoped CA lists using CharacterAdvancementUtil + C_CharacterAdvancement.
## Author: You
## Version: 0.1.0

CA_Example_ClassLists.lua
```

**CA_Example_ClassLists.lua**
```lua
local function EnsureDeps()
  if not CharacterAdvancementUtil then
    -- this util file ships in Interface/FrameXML/Util in the UI pack
    -- it should exist once the client has the pack installed; guard anyway
  end
  if not (C_CharacterAdvancement and C_CharacterAdvancement.GetKnownSpellEntriesForClass) then
    LoadAddOn("Ascension_CharacterAdvancement")
    LoadAddOn("Ascension_CharacterAdvancementSeason9")
  end
  return CharacterAdvancementUtil and C_CharacterAdvancement and C_CharacterAdvancement.GetKnownSpellEntriesForClass
end

local function GetClassToken()
  local _, classFile = UnitClass("player")
  return CharacterAdvancementUtil.GetClassDBCByFile(classFile)
end

local function PrintFirst(t, n)
  print("count", #t)
  for i = 1, math.min(#t, n) do
    local e = t[i]
    if e then print(e.ID, e.Spells and e.Spells[1], e.Name) end
  end
end

SLASH_CACLASS1 = "/caclass"
SlashCmdList.CACLASS = function(msg)
  if not EnsureDeps() then
    print("Missing deps (CharacterAdvancementUtil / C_CharacterAdvancement). Is the UI pack installed/loaded?")
    return
  end

  msg = msg or ""
  local kind, n = msg:match("^(%S+)%s*(%d*)$")
  kind = (kind or ""):lower()
  n = tonumber(n) or 15

  local c = GetClassToken()
  if not c then
    print("Could not resolve CA class token for player.")
    return
  end

  if kind == "spells" then
    PrintFirst(C_CharacterAdvancement.GetKnownSpellEntriesForClass(c, "None"), n)
  elseif kind == "talents" then
    PrintFirst(C_CharacterAdvancement.GetKnownTalentEntriesForClass(c, "None"), n)
  elseif kind == "masteries" then
    PrintFirst(C_CharacterAdvancement.GetMasteriesByClass(c, "None"), n)
  elseif kind == "traits" then
    PrintFirst(C_CharacterAdvancement.GetImplicitByClass(c, "None"), n)
  else
    print("Usage: /caclass spells|talents|masteries|traits [N]")
  end
end
```

---

## 7) Categories + spell tags (filter/tree debugging)

### AddOn: `CA_Example_CategoriesTags`

**Commands:**
- `/cacats [N]` — print first N categories with filtered counts
- `/caroottags` — print root tag types
- `/catags <rootId> [N]` — print children of a root tag type

**CA_Example_CategoriesTags.toc**
```toc
## Interface: 30300
## Title: CA Example - Categories & Tags
## Notes: Prints categories and spell tag types used by the CA browser filters.
## Author: You
## Version: 0.1.0

CA_Example_CategoriesTags.lua
```

**CA_Example_CategoriesTags.lua**
```lua
local function EnsureCA()
  if not (C_CharacterAdvancement and C_CharacterAdvancement.GetCategories) then
    LoadAddOn("Ascension_CharacterAdvancement")
    LoadAddOn("Ascension_CharacterAdvancementSeason9")
  end
  return C_CharacterAdvancement and C_CharacterAdvancement.GetCategories
end

SLASH_CACATS1 = "/cacats"
SlashCmdList.CACATS = function(msg)
  if not EnsureCA() then print("C_CharacterAdvancement missing"); return end
  local n = tonumber((msg or ""):match("^(%d+)$")) or 25
  local c = C_CharacterAdvancement.GetCategories()
  print("categories", #c)
  for i = 1, math.min(#c, n) do
    local id = c[i]
    print("cat", id,
      "count", C_CharacterAdvancement.GetNumFilteredEntriesByCategory(id),
      "disp", C_CharacterAdvancement.GetCategoryDisplayInfo(id))
  end
end

SLASH_CAROOT1 = "/caroottags"
SlashCmdList.CAROOT = function()
  if not EnsureCA() then print("C_CharacterAdvancement missing"); return end
  local r = C_CharacterAdvancement.GetRootSpellTagTypes()
  print("rootTags", #r)
  for i = 1, #r do
    local id = r[i]
    print("root", id, C_CharacterAdvancement.GetSpellTagTypeDisplayInfo(id))
  end
end

SLASH_CATAGS1 = "/catags"
SlashCmdList.CATAGS = function(msg)
  if not EnsureCA() then print("C_CharacterAdvancement missing"); return end
  local rootId, n = (msg or ""):match("^(%d+)%s*(%d*)$")
  rootId = tonumber(rootId)
  n = tonumber(n) or 30
  if not rootId then
    print("Usage: /catags <rootId> [N]")
    return
  end
  local t = C_CharacterAdvancement.GetSpellTagTypes(rootId) or {}
  print("childrenOf", rootId, #t)
  for i = 1, math.min(#t, n) do
    local id = t[i]
    print(id, C_CharacterAdvancement.GetSpellTagTypeDisplayInfo(id))
  end
end
```

---

## 8) Costs & resets (CACostUtil / CharacterAdvancementCostUtil.lua)

### AddOn: `CA_Example_Costs`

**Commands:**
- `/cacost reset` — dump reset costs
- `/cacost tooltip` — hover a spell, then print per-entry unlearn costs

**CA_Example_Costs.toc**
```toc
## Interface: 30300
## Title: CA Example - Costs
## Notes: Uses CACostUtil + Enum.UnlearnCost to print reset/unlearn costs.
## Author: You
## Version: 0.1.0

CA_Example_Costs.lua
```

**CA_Example_Costs.lua**
```lua
local function EnsureCost()
  if not CACostUtil then
    -- Provided by the pack's util file in Interface/FrameXML/Util
  end
  if not (C_CharacterAdvancement and C_CharacterAdvancement.GetEntryBySpellID) then
    LoadAddOn("Ascension_CharacterAdvancement")
    LoadAddOn("Ascension_CharacterAdvancementSeason9")
  end
  return CACostUtil and Enum and Enum.UnlearnCost and C_CharacterAdvancement and C_CharacterAdvancement.GetEntryBySpellID
end

SLASH_CACOST1 = "/cacost"
SlashCmdList.CACOST = function(msg)
  if not EnsureCost() then
    print("Missing CACostUtil/Enum.UnlearnCost/C_CharacterAdvancement. Is the pack installed/loaded?")
    return
  end

  msg = (msg or ""):lower()
  if msg == "reset" then
    local c = CACostUtil:GetAbilityAndTalentResetCost()
    for name, idx in pairs(Enum.UnlearnCost) do
      if type(idx) == "number" and c[idx] ~= nil then
        print(name, c[idx])
      end
    end
    return
  end

  if msg == "tooltip" then
    local _, _, sid = GameTooltip:GetSpell()
    local e = sid and C_CharacterAdvancement.GetEntryBySpellID(sid)
    if not e then print("no CA entry for tooltip"); return end
    local c = CACostUtil:GetSingleUnlearnCost(e.ID, 0, 0)
    print("Entry", e.ID,
      "Gold", c[Enum.UnlearnCost.Gold],
      "Marks", c[Enum.UnlearnCost.MarksOfAscension])
    return
  end

  print("Usage: /cacost reset  OR  /cacost tooltip")
end
```

---

## 9) Mystic Enchant probe (Collections wiring uses this)

### AddOn: `CA_Example_MysticProbe`

**Commands:**
- `/camystic` — prints whether Mystic APIs exist and dumps first 10 results if possible

**CA_Example_MysticProbe.toc**
```toc
## Interface: 30300
## Title: CA Example - Mystic Probe
## Notes: Probes Mystic enchant APIs and prints first page (if available).
## Author: You
## Version: 0.1.0

CA_Example_MysticProbe.lua
```

**CA_Example_MysticProbe.lua**
```lua
SLASH_CAMYSTIC1 = "/camystic"
SlashCmdList.CAMYSTIC = function()
  print("C_MysticEnchant", type(C_MysticEnchant), "MysticEnchantUtil", type(MysticEnchantUtil))
  if not (C_MysticEnchant and C_CharacterAdvancement and C_MysticEnchant.QueryEnchants) then
    if not (C_MysticEnchant and C_MysticEnchant.QueryEnchants) then
      print("no QueryEnchants")
    end
    return
  end

  local rows, maxPage = C_MysticEnchant.QueryEnchants(200, 1, "", {})
  print("rows", #rows, "maxPage", maxPage)
  for i = 1, math.min(#rows, 10) do
    local e = rows[i]
    print(i, e.SpellID, e.SpellName, e.Quality, e.Known)
  end
end
```

---

## 10) Event tracer (what fires while you click things)

### AddOn: `CA_Example_EventTrace`

**Commands:**
- `/catrace on` — registers a small set of CA-related events and prints payloads
- `/catrace off` — stops tracing

**CA_Example_EventTrace.toc**
```toc
## Interface: 30300
## Title: CA Example - Event Trace
## Notes: Logs CA-related events to chat to prove event ordering/payloads.
## Author: You
## Version: 0.1.0

CA_Example_EventTrace.lua
```

**CA_Example_EventTrace.lua**
```lua
local f = CreateFrame("Frame")
local active = false

local EVENTS = {
  "CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED",
  "CHARACTER_ADVANCEMENT_LEARN_RESULT",
  "CHARACTER_ADVANCEMENT_UNLEARN_RESULT",
  "CHARACTER_ADVANCEMENT_UPDATE_ENTRIES_RESULT",
  "SPELL_TAGS_CHANGED",
  "SPELL_TAG_TYPES_CHANGED",
  "ASCENSION_CA_SPECIALIZATION_ACTIVE_ID_CHANGED",
}

local function Set(on)
  if on and not active then
    for _, e in ipairs(EVENTS) do f:RegisterEvent(e) end
    f:SetScript("OnEvent", function(_, e, ...)
      print("EVT", e, ...)
    end)
    active = true
    print("CA trace armed")
  elseif (not on) and active then
    for _, e in ipairs(EVENTS) do f:UnregisterEvent(e) end
    f:SetScript("OnEvent", nil)
    active = false
    print("CA trace stopped")
  end
end

SLASH_CATRACE1 = "/catrace"
SlashCmdList.CATRACE = function(msg)
  msg = (msg or ""):lower()
  if msg == "on" then Set(true)
  elseif msg == "off" then Set(false)
  else print("Usage: /catrace on|off") end
end
```

---

## 11) Quick performance snapshots

### AddOn: `CA_Example_Perf`

**Commands:**
- `/camem` — memory usage for the UI pack folders
- `/catime` — time `C_CharacterAdvancement.GetKnownSpellEntries()` (if available)

**CA_Example_Perf.toc**
```toc
## Interface: 30300
## Title: CA Example - Perf
## Notes: Simple memory + timing probes for CA UI pack.
## Author: You
## Version: 0.1.0

CA_Example_Perf.lua
```

**CA_Example_Perf.lua**
```lua
local ADDONS = {
  "Ascension_Collections",
  "Ascension_CharacterAdvancement",
  "Ascension_CharacterAdvancementSeason9",
  "Ascension_TalentUI",
  "Ascension_CoATalents",
}

SLASH_CAMEM1 = "/camem"
SlashCmdList.CAMEM = function()
  UpdateAddOnMemoryUsage()
  for _, a in ipairs(ADDONS) do
    for i = 1, GetNumAddOns() do
      local n = GetAddOnInfo(i)
      if n == a then
        print(a, math.floor(GetAddOnMemoryUsage(i) + 0.5), "KiB")
        break
      end
    end
  end
end

SLASH_CATIME1 = "/catime"
SlashCmdList.CATIME = function()
  if not debugprofilestart then
    print("no debugprofilestart")
    return
  end
  if not (C_CharacterAdvancement and C_CharacterAdvancement.GetKnownSpellEntries) then
    LoadAddOn("Ascension_CharacterAdvancement")
    LoadAddOn("Ascension_CharacterAdvancementSeason9")
  end
  if not (C_CharacterAdvancement and C_CharacterAdvancement.GetKnownSpellEntries) then
    print("C_CharacterAdvancement missing")
    return
  end
  debugprofilestart()
  local t = C_CharacterAdvancement.GetKnownSpellEntries()
  local ms = debugprofilestop()
  print("GetKnownSpellEntries ms", ms, "count", #t)
end
```

---

## Suggested workflow

- Use **CA_Pratical_Usage.md** for quick interactive probing.
- When you find a probe you keep re-running, promote it into a mini-addon from this doc so it’s:
  - repeatable,
  - shareable,
  - and doesn’t require pasting `/run` every time.

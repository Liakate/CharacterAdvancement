# CA_Pratical_Usage.md (CharacterAdvancement.zip)

This cheat-sheet is derived from the **`CharacterAdvancement`**.  
It focuses on console commands that give **developer-usable, concrete output** for the UI pack:

**AddOns in the zip (all `LoadOnDemand`)**
- `Ascension_Collections`
- `Ascension_CharacterAdvancement`
- `Ascension_CharacterAdvancementSeason9`
- `Ascension_TalentUI`
- `Ascension_CoATalents`

> Tip: most `/run` commands are **one-liners**. If a code block shows multiple lines, run them **line by line**.

---

## 0) Load the pack (required for most commands)

### Load all addons from the zip
```txt
/run for _,a in ipairs({"Ascension_Collections","Ascension_TalentUI","Ascension_CoATalents","Ascension_CharacterAdvancement","Ascension_CharacterAdvancementSeason9"})do local ok,why=LoadAddOn(a);print(a,ok,why)end
```

**Expected result:** 5 lines. Successful loads typically print `1` (or `true`) and `nil` reason.  
**Use it for:** confirming the client sees the addon folders and dependencies are satisfied.

### Confirm loaded state + TOC metadata
```txt
/run for _,a in ipairs({"Ascension_Collections","Ascension_CharacterAdvancement","Ascension_CharacterAdvancementSeason9","Ascension_TalentUI","Ascension_CoATalents"})do print(a,"loaded",IsAddOnLoaded(a),"ver",GetAddOnMetadata(a,"Version"),"iface",GetAddOnMetadata(a,"Interface"))end
```

**Expected result:** each addon prints `loaded true/false`, plus `Version` and `Interface` (30300 in the zip).  
**Use it for:** catching “wrong Interface” issues, wrong version, or addon not actually loaded.

---

## 1) Verify the UI objects from this zip exist

### Collections root frame + CA frames
```txt
/run print("Collections",Collections and "OK" or "nil","CharacterAdvancement",CharacterAdvancement and "OK" or "nil","CoATalentFrame",CoATalentFrame and "OK" or "nil")
```

**Expected result:** `OK` for frames that are present/loaded.  
**Use it for:** verifying XML actually created the expected globals (helps diagnose “nothing shows”).

### Dump Collections tab IDs created by `Ascension_Collections`
```txt
/run if not Collections or not Collections.Tabs then print("Collections.Tabs missing (is Collections loaded?)") else for k,v in pairs(Collections.Tabs)do print("Tab",k,v)end end
```

**Expected result:** lines like `Tab CharacterAdvancement <id>`, `Tab Wardrobe <id>`, `Tab Vanity <id>`, possibly `MysticEnchants`, and hero-only tabs if you are a hero.  
**Use it for:** driving the UI programmatically (jumping to tabs, validating gating).

### Jump to a specific Collections tab (example: Character Advancement)
```txt
/run if Collections and Collections.Tabs then Collections:GoToTab(Collections.Tabs.CharacterAdvancement) end
```

**Expected result:** opens Collections and selects the tab.  
**Use it for:** verifying tab wiring and quickly reproducing UI issues.

---

## 2) Realm / server / mode signals (useful context for bug reports)

### Client build + interface
```txt
/run local v,b,d,t=GetBuildInfo();print("build",v,"build#",b,"date",d,"toc",t,"locale",GetLocale())
```

**Expected result:** your client version/build/date + TOC number.  
**Use it for:** attaching exact client context to bug reports.

### Realm identity + Ascension realm flags (if provided by the server build)
```txt
/run print("realm",GetRealmName(),"C_Realm",type(C_Realm),C_Realm and "isLive" or "");if C_Realm and C_Realm.IsLive then print("isLive",C_Realm.IsLive())end;if C_Realm and C_Realm.IsDevelopment then print("isDev",C_Realm.IsDevelopment())end
```

**Expected result:** realm name; optionally `isLive true/false`, `isDev true/false`.  
**Use it for:** explaining why URLs, availability, or feature gates differ between realms.

### Player mode gates used by Collections
```txt
/run local cn,cf=UnitClass("player");print("lvl",UnitLevel("player"),cn,cf,"hero",C_Player and C_Player.IsHero and C_Player:IsHero(),"customClass",IsCustomClass())
```

**Expected result:** level + class + hero flag + whether you are a Conquest-of-Azeroth/custom class character.  
**Use it for:** explaining why Collections shows **CoA talents** vs **Character Advancement** vs **Mystic Enchants** (the UI gates on these).

### Active gamemodes (Wildcard/Draft/etc) if `C_GameMode` exists
```txt
/run if not (C_GameMode and Enum and Enum.GameMode) then print("no C_GameMode/Enum.GameMode") else for k,v in pairs(Enum.GameMode)do if type(v)=="number" then print(k,v,C_GameMode:IsGameModeActive(v))end end end
```

**Expected result:** a list of `GameModeName id true/false`.  
**Use it for:** reproducing mode-specific UI behavior (Collections hides/shows some tabs based on gamemode).

---

## 3) Character Advancement “state snapshot” (pending build, spec, points)

> These call **`C_CharacterAdvancement` APIs that are directly used by the zip UI**.

### Pending build state + whether you can apply/clear it
```txt
/run print("pending",C_CharacterAdvancement.IsPending(),"canApply",C_CharacterAdvancement.CanApplyPendingBuild(),"canClear",C_CharacterAdvancement.CanClearPendingBuild())
```

**Expected result:** `pending true/false` and whether apply/clear is allowed.  
**Use it for:** diagnosing “Apply button disabled” or “changes not saving”.

### Pending remaining currencies (Ability Essence / Talent Essence)
```txt
/run print("pendingRemaining AE",C_CharacterAdvancement.GetPendingRemainingAE(),"TE",C_CharacterAdvancement.GetPendingRemainingTE())
```

**Expected result:** two numbers (remaining AE/TE for the pending build).  
**Use it for:** validating budget logic and why a learn/unlearn is blocked.

### Learned totals + expected AE for your level
```txt
/run local l=UnitLevel("player");print("lvl",l,"learnedAE",C_CharacterAdvancement.GetLearnedAE(),"learnedTE",C_CharacterAdvancement.GetLearnedTE(),"expectedAE",C_CharacterAdvancement.GetExpectedAE(l))
```

**Expected result:** learned AE/TE totals and expected AE at your current level.  
**Use it for:** catching desyncs between client display and server progression.

### Active CA spec + whether switching is allowed right now
```txt
/run print("activeChrSpec",C_CharacterAdvancement.GetActiveChrSpec(),"canSwitch",C_CharacterAdvancement.CanSwitchActiveChrSpec())
```

**Expected result:** active spec ID (number) + `canSwitch true/false`.  
**Use it for:** debugging spec UI, buttons disabled in combat, etc.

---

## 4) Practical SpellID / TalentID outputs (safe, “first N” lists)

### Count of known CA spell entries + first 20 (EntryID + primary SpellID)
```txt
/run local t=C_CharacterAdvancement.GetKnownSpellEntries();print("knownSpellEntries",#t);for i=1,math.min(#t,20)do local e=t[i];print(i,"Entry",e.ID,"Spell",e.Spells and e.Spells[1],e.Name)end
```

**Expected result:** prints total count, then 20 lines of `(EntryID, SpellID, Name)`.  
**Use it for:** quickly sanity-checking “what the server says I know” without opening the UI.

### Count of known CA talent entries + first 20
```txt
/run local t=C_CharacterAdvancement.GetKnownTalentEntries();print("knownTalentEntries",#t);for i=1,math.min(#t,20)do local e=t[i];print(i,"Entry",e.ID,"Spell",e.Spells and e.Spells[1],e.Name)end
```

**Expected result:** prints total count, then 20 talent entry lines.  
**Use it for:** building a talent database sample from live data.

### Tooltip-driven lookup: hover a spell, then run to map SpellID -> CA EntryID
```txt
/run local n,_,sid=GameTooltip:GetSpell();print("tooltip",n,sid);if sid then local e=C_CharacterAdvancement.GetEntryBySpellID(sid);print("CA entry",e and e.ID,e and e.Type,e and e.RequiredLevel)end
```

**Expected result:** shows tooltip spell name + SpellID, then the matching CA entry details (or `nil`).  
**Use it for:** answering “what CA entry is this spell?” instantly while testing.

### Unique SpellID counts across your known entries (helps detect duplicates/rank packs)
```txt
/run local t=C_CharacterAdvancement.GetKnownSpellEntries();local u,n={},0;for _,e in ipairs(t)do for _,s in ipairs(e.Spells or {})do if not u[s]then u[s]=1;n=n+1 end end end;print("uniqueSpellIDs",n,"entries",#t)
```

**Expected result:** `uniqueSpellIDs <n> entries <m>`.  
**Use it for:** confirming your dataset size and verifying rank lists.

---

## 5) Class-scoped lists (what CA says is available for your class context)

The zip uses `CharacterAdvancementUtil.GetClassDBCByFile(select(2,UnitClass("player")))` to translate your class token.

### Known spells for your class (first 15)
```txt
/run local c=CharacterAdvancementUtil.GetClassDBCByFile(select(2,UnitClass("player")));local t=C_CharacterAdvancement.GetKnownSpellEntriesForClass(c,"None");print("class",c,"known",#t);for i=1,15 do local e=t[i];if e then print(e.ID,e.Spells and e.Spells[1],e.Name)end end
```

**Expected result:** prints your CA class token + count + first 15 entries.  
**Use it for:** testing class-filtering logic used by the browser.

### Known talents for your class (first 15)
```txt
/run local c=CharacterAdvancementUtil.GetClassDBCByFile(select(2,UnitClass("player")));local t=C_CharacterAdvancement.GetKnownTalentEntriesForClass(c,"None");print("class",c,"knownTalents",#t);for i=1,15 do local e=t[i];if e then print(e.ID,e.Spells and e.Spells[1],e.Name)end end
```

---

## 6) Masteries + implicit traits (explicitly surfaced in this UI)

### Masteries for your class (first 15)
```txt
/run local c=CharacterAdvancementUtil.GetClassDBCByFile(select(2,UnitClass("player")));local t=C_CharacterAdvancement.GetMasteriesByClass(c,"None");print("masteries",c,#t);for i=1,15 do local e=t[i];if e then print(e.ID,e.Spells and e.Spells[1],e.Name)end end
```

### Implicit traits for your class (first 15)
```txt
/run local c=CharacterAdvancementUtil.GetClassDBCByFile(select(2,UnitClass("player")));local t=C_CharacterAdvancement.GetImplicitByClass(c,"None");print("traits",c,#t);for i=1,15 do local e=t[i];if e then print(e.ID,e.Spells and e.Spells[1],e.Name)end end
```

**Use these for:** verifying mastery/trait unlocks, and building “what exists” lists without opening the panels.

---

## 7) Categories + spell tags (deep browser/filter debugging)

### Category list + filtered counts
```txt
/run local c=C_CharacterAdvancement.GetCategories();print("categories",#c);for i=1,math.min(#c,25)do local id=c[i];print("cat",id,"count",C_CharacterAdvancement.GetNumFilteredEntriesByCategory(id),"disp",C_CharacterAdvancement.GetCategoryDisplayInfo(id))end
```

**Expected result:** prints up to 25 category IDs with current filtered counts.  
**Use it for:** diagnosing “category shows empty” and validating server-side filtering.

### Root spell tag types + display info
```txt
/run local r=C_CharacterAdvancement.GetRootSpellTagTypes();print("rootTags",#r);for i=1,#r do local id=r[i];print("root",id,C_CharacterAdvancement.GetSpellTagTypeDisplayInfo(id))end
```

### Drill into a root tag type (edit `rt`)
```txt
/run local rt=1;local t=C_CharacterAdvancement.GetSpellTagTypes(rt)or {};print("childrenOf",rt,#t);for i=1,math.min(#t,30)do local id=t[i];print(id,C_CharacterAdvancement.GetSpellTagTypeDisplayInfo(id))end
```

**Use it for:** building tag browsers, debugging “tag tree not populating”, and validating icons/names.

---

## 8) Costs & resets (from `CharacterAdvancementCostUtil.lua` in the zip)

### Reset cost snapshot (ability/talent purge)
```txt
/run local c=CACostUtil:GetAbilityAndTalentResetCost();for n,i in pairs(Enum.UnlearnCost)do if type(i)=="number"and c[i]~=nil then print(n,c[i])end end
```

**Expected result:** prints costs by type (Gold, Marks, etc) depending on what `Enum.UnlearnCost` provides.  
**Use it for:** validating economy changes and UI cost displays.

### Per-entry unlearn cost (hover a spell first, then run)
```txt
/run local _,_,sid=GameTooltip:GetSpell();local e=sid and C_CharacterAdvancement.GetEntryBySpellID(sid);if not e then print("no CA entry for tooltip") else local c=CACostUtil:GetSingleUnlearnCost(e.ID,0,0);print("Entry",e.ID,"Gold",c[Enum.UnlearnCost.Gold],"Marks",c[Enum.UnlearnCost.MarksOfAscension])end
```

**Expected result:** prints the unlearn cost for that specific CA entry.  
**Use it for:** reproducing “why did this cost X?” reports with a concrete entry ID.

---

## 9) Mystic Enchant list (Collections tab wiring is in this zip)

`Ascension_Collections` creates the Mystic Enchant tab for non-CoA characters and calls `MysticEnchant_LoadUI` before opening it.
The actual enchanting system APIs are provided by the client/realm.

### Basic “do I have the Mystic API?” probe
```txt
/run print("C_MysticEnchant",type(C_MysticEnchant),"MysticEnchantUtil",type(MysticEnchantUtil))
```

**Expected result:** usually `table` for systems that exist; `nil` if not available on your client.  
**Use it for:** quickly proving whether the feature exists in your build.

### Query and print the first 10 enchants (if the API exists)
```txt
/run if not (C_MysticEnchant and C_MysticEnchant.QueryEnchants) then print("no QueryEnchants") else local r,m=C_MysticEnchant.QueryEnchants(200,1,"",{});print("rows",#r,"maxPage",m);for i=1,math.min(#r,10)do local e=r[i];print(i,e.SpellID,e.SpellName,e.Quality,e.Known)end end
```

**Expected result:** a page of enchants: SpellID, name, quality, known flag.  
**Use it for:** building an enchant list, validating search/paging, or checking “known vs unknown”.

---

## 10) Vanity / Wardrobe discovery (Collections references these panels)

These panels are *selected* by Collections using frame names:
- Vanity: `StoreCollectionFrame`
- Wardrobe: `AppearanceWardrobeFrame`

### Are the frames present (loaded) right now?
```txt
/run print("StoreCollectionFrame",StoreCollectionFrame and "OK" or "nil","AppearanceWardrobeFrame",AppearanceWardrobeFrame and "OK" or "nil")
```

**Expected result:** `OK` once the relevant UI addon is loaded; otherwise `nil`.  
**Use it for:** proving whether a “blank tab” is just a missing LoD load.

### Find related `C_*` namespaces at runtime (quick API surface discovery)
```txt
/run for k,v in pairs(_G)do if type(k)=="string"and k:match("^C_")and (k:lower():find("vanity")or k:lower():find("wardrobe")or k:lower():find("store"))then print(k,type(v))end end
```

**Expected result:** prints matching `C_*` tables (if any exist).  
**Use it for:** figuring out what to probe next for vanity/wardrobe listing APIs.

---

## 11) Event tracer (what fires while you click things)

The CA UI in this zip registers these events (subset):
- `CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED`
- `CHARACTER_ADVANCEMENT_LEARN_RESULT`
- `CHARACTER_ADVANCEMENT_UNLEARN_RESULT`
- `CHARACTER_ADVANCEMENT_UPDATE_ENTRIES_RESULT`
- `SPELL_TAGS_CHANGED`, `SPELL_TAG_TYPES_CHANGED`
- `ASCENSION_CA_SPECIALIZATION_ACTIVE_ID_CHANGED`
- …and more

### Minimal CA event logger
```txt
/run local f=CreateFrame("Frame");for _,e in ipairs({"CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED","CHARACTER_ADVANCEMENT_LEARN_RESULT","CHARACTER_ADVANCEMENT_UNLEARN_RESULT","CHARACTER_ADVANCEMENT_UPDATE_ENTRIES_RESULT","SPELL_TAGS_CHANGED","SPELL_TAG_TYPES_CHANGED"})do f:RegisterEvent(e)end;f:SetScript("OnEvent",function(_,e,...)print("EVT",e,...)end);print("CA trace armed")
```

**Expected result:** prints `CA trace armed`, then prints `EVT <event> ...` as you learn/unlearn, change tags, etc.  
**Use it for:** collecting *hard evidence* of event payloads and ordering for addon development.

---

## 12) Quick performance snapshots for these addons

### Memory usage for each addon in the zip
```txt
/run UpdateAddOnMemoryUsage();for _,a in ipairs({"Ascension_Collections","Ascension_CharacterAdvancement","Ascension_CharacterAdvancementSeason9","Ascension_TalentUI","Ascension_CoATalents"})do for i=1,GetNumAddOns()do local n=GetAddOnInfo(i);if n==a then print(a,math.floor(GetAddOnMemoryUsage(i)+.5),"KiB")break end end end
```

**Expected result:** `AddonName <KiB>` for each.  
**Use it for:** detecting leaks/regressions when you spam-open UI or change filters.

### Time a single CA API call (cheap “is this slow?” check)
```txt
/run if not debugprofilestart then print("no debugprofilestart") else debugprofilestart();local t=C_CharacterAdvancement.GetKnownSpellEntries();print("GetKnownSpellEntries ms",debugprofilestop(),"count",#t) end
```

**Expected result:** elapsed ms + entry count.  
**Use it for:** baseline profiling before you add more processing on top.

---

### Notes for using these outputs in a new addon
- Prefer **counts + first N entries** while iterating in chat, so you don’t spam thousands of lines.
- When a command prints `nil`, it often means **the LoD addon isn't loaded** yet *or* the realm build doesn’t provide that system (`C_MysticEnchant`, vanity APIs, etc).
- The event tracer is the fastest way to prove **what actually happens** (and in what order) without guessing.

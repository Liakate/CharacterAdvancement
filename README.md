[![Release](https://img.shields.io/github/v/release/Liakate/CharacterAdvancement?display_name=tag&sort=date)](https://github.com/Liakate/CharacterAdvancement/releases/latest)

# CharacterAdvancement UI Source (Annotated)

> **Note:** This is **not** a “single ready-to-install addon zip”.
> It contains **multiple AddOn folders** (plus a couple of shared FrameXML utility files) and is intended for **learning / reference**.

This repo mirrors the `.lua` / `.xml` files used by Bronzebeard’s **Collections → Character Advancement** UI, with extra **GUIDE** and **DOC** comments added for readability.

---

## What this repo contains

## Realm sharing note

This client build uses the **same FrameXML + LoadOnDemand AddOns** for **multiple Ascension realms** (at least the following three), so the code in this repo is **not Bronzebeard-only**:

- **Bronzebeard (Warcraft Reborn)**
- **Area 52 (Free Pick)**
- **Elune (Season 9)** — uses the `Ascension_CharacterAdvancementSeason9` variant

### Included AddOns (all `LoadOnDemand`)

- `Ascension_Collections` — Collections shell + tab system
- `Ascension_CharacterAdvancement` — Character Advancement UI (normal classes)
- `Ascension_CharacterAdvancementSeason9` — Season 9 variant (if your client uses it)
- `Ascension_TalentUI` — shared talent UI dependency
- `Ascension_CoATalents` — CoA (Custom Class) replacement frame

### Shared FrameXML utility files

- `Interface/FrameXML/Util/CharacterAdvancementUtil.lua`
- `Interface/FrameXML/Util/CharacterAdvancementCostUtil.lua`

---

## How these client files work together (evidence-first)

Everything below is grounded in **TOC/XML/Lua call sites from this repo**.

### 1) Load-on-demand chain: Collections → (CA or CoA talents)

`Ascension_CharacterAdvancement` is LoadOnDemand and depends on `Ascension_Collections`:

```text
Interface/AddOns/Ascension_CharacterAdvancement/Ascension_CharacterAdvancement.toc
0001: ## Interface: 30300
0002: ## Title: |cfffe8c00A|r|cffff9a35s|r|cffffa954c|r|cffffb771e|r|cffffc58dn|r|cffffd3a9s|r|cffffe2c5i|r|cfffff0e2o|r|cffffffffn|r |cffFFFFFFCharacter Advancement|r
0003: ## Notes: Character Advancement UI
0004: ## Author: Ascension Team
0005: ## LoadOnDemand: 1
0006: ## Version: 1.0.0
0007: ## Dependencies: Ascension_Collections
0008: 
0009: Templates\CharacterAdvancementTemplates.xml
0010: Browser\CharacterAdvancementBrowser.xml
0011: CharacterAdvancement.xml
```

CoA uses a different frame (but still LoadOnDemand) and depends on the shared TalentUI addon too:

```text
Interface/AddOns/Ascension_CoATalents/Ascension_CoATalents.toc
0001: ## Interface: 30300
0002: ## Title: |cfffe8c00A|r|cffff9a35s|r|cffffa954c|r|cffffb771e|r|cffffc58dn|r|cffffd3a9s|r|cffffe2c5i|r|cfffff0e2o|r|cffffffffn|r |cffFFFFFFCoA Talents|r
0003: ## Notes: Talents UI
0004: ## Author: Ascension Team
0005: ## Version: 1.0.0
0006: ## LoadOnDemand: 1
0007: ## Dependencies: Ascension_TalentUI, Ascension_Collections
0008: 
0009: CoACharacterAdvancementUtil.lua
0010: 
0011: Templates\CoATalentTemplates.xml
0012: CoATalentFrame.xml
```

Collections chooses which panel name to attach to the Character Advancement tab, and wires a pre-click loader function:

```text
Interface/AddOns/Ascension_Collections/Collections.lua (SetupTabSystem)
0049: function CollectionsMixin:SetupTabSystem()
0050: 	TabSystemMixin.OnLoad(self)
0051: 	self:SetTabTemplate("CollectionTabTemplate")
0052: 	self:SetTabSelectedSound(SOUNDKIT.CHARACTER_SHEET_TAB_70)
0053: 	self:SetTabPoint("TOPLEFT", self, "BOTTOMLEFT", 12, 10)
0054: 	self:RegisterCallback("OnTabSelected", self.OnTabSelected, self)
0055: 	self.Tabs = {}
0056: 	
0057: 	-- Character Advancement Tab
0058: 	local tab
0059: 	do
0060: 		if IsCustomClass() then
0061: 			tab = self:AddTab(CHARACTER_ADVANCEMENT, "CoATalentFrame")
0062: 		else
0063: 			tab = self:AddTab(CHARACTER_ADVANCEMENT, "CharacterAdvancement")
0064: 		end
0065: 		tab:SetPreClick(CharacterAdvancement_LoadUI)
0066: 		tab:SetIcon("Interface\\Icons\\spell_Paladin_divinecircle")
0067: 		tab:SetTooltip(CHARACTER_ADVANCEMENT, CHARACTER_ADVANCEMENT_TOOLTIP)
0068: 		self.Tabs.CharacterAdvancement = tab:GetTabID()
0069: 	end
```

Collections also:
- disables the CA tab for CoA characters below a configured level threshold
- hides the Collections UI when the player enters combat

```text
Interface/AddOns/Ascension_Collections/Collections.lua (OnShow + PLAYER_REGEN_DISABLED)
0175: 	if Draft then
0176: 		Draft:HideCards()
0177: 	end
0178: 	UpdateMicroButtons()
0179: 	
0180: 	-- disable character advancement tab if player is a coa class and not level 10+
0181: 	local caTab = self:GetCharacterAdvancementTab()
0182: 	caTab:SetTabEnabled(not IsCustomClass() or C_Player:GetLevel() >= COA_AUTO_SHOW_TALENTS_LEVEL, format(FEATURE_BECOMES_AVAILABLE_AT_LEVEL, COA_AUTO_SHOW_TALENTS_LEVEL))
0183: 	
0184: 	-- disable enchanting tab if player is not 60+, is not prestiged, and has not opened the ui before
0185: 	local enchantTab = self:GetMysticEnchantTab()
0186: 	if enchantTab then
0187: 		enchantTab:SetTabEnabled(MysticEnchantUtil.HasUnlockedEnchantTab(), format(MYSTIC_ENCHANTING_ALTAR_UNLOCK, 60))
0188: 	end
0189: 
0190: 	-- skill card tab only shown in draft/wildcard
0191: 	if C_GameMode:IsGameModeActive(Enum.GameMode.WildCard) or C_GameMode:IsGameModeActive(Enum.GameMode.Draft) then
0192: 		self:ShowTabID(self.Tabs.SkillCards)
0193: 	else
0194: 		self:HideTabID(self.Tabs.SkillCards)
0195: 	end
0196: 	
0197: 	HelpTip:Acknowledge("WARDROBE_CHANGE_TRANSMOG_HINT")
0198: end
0199: 
0200: -- DOC: CollectionsMixin:OnHide
0201: -- What this does: Cleans up when the UI closes (stops updates and hides extra popups).
0202: -- When it runs: Runs when this UI element is hidden.
0203: -- Inputs:
0204: --   - self: the UI object this function belongs to
0205: -- Output: A value used by other code (self:GetTabByID(self.Tabs.CharacterAdvan...).
0206: -- What it changes: listens for game events.
0207: function CollectionsMixin:OnHide()
0208: 	PlaySound(SOUNDKIT.CHARACTER_SHEET_CLOSE_70)
0209: 	self:HideCurrentPanel()
0210: 	UpdateMicroButtons()
0211: end
0212: 
0213: function CollectionsMixin:PLAYER_REGEN_DISABLED()
0214: 	HideUIPanel(self)
0215: end
0216: 
```

> `CharacterAdvancement_LoadUI` is referenced, but its **definition is not present in this repo**. From these sources alone, we can only say: *Collections expects it to exist at runtime and uses it as a pre-click loader.*

---

### 2) XML → Lua wiring: scripts, mixins, and event dispatch

The Character Advancement UI loads its Lua behavior via XML `<Script ...>` and is parented to `Collections`:

```text
Interface/AddOns/Ascension_CharacterAdvancement/CharacterAdvancement.xml (script + frame declaration)
0014:      NOTE:
0015:     - This line loads the Lua file 'CharacterAdvancement.lua' which contains the behavior (what happens on clicks/events).
0016:     -->
0017:     <Script file="CharacterAdvancement.lua"/>
0018: 
0019:     <Frame name="CharacterAdvancement" parent="Collections" hidden="true" inherits="RaisedPortraitFrameTemplate">
0020:         <Size x="1165" y="758"/>
0021: 
0022:         <Anchors>
0023:             <Anchor point="BOTTOM" y="8"/>
0024:         </Anchors>
0025:         
```

The same XML file attaches the mixin and routes events to methods:

```text
Interface/AddOns/Ascension_CharacterAdvancement/CharacterAdvancement.xml (mixin + OnEventToMethod)
1606:         
1607:         <Scripts>
1608:             <!--  NOTE: The code inside <OnLoad> is Lua that runs for this UI callback. -->
1609:             <OnLoad>
1610:                 MixinAndLoadScripts(self, "CharacterAdvancementMixin")
1611:             </OnLoad>
1612:             <OnEvent function="OnEventToMethod"/>
```

That “OnEventToMethod” routing is reflected directly in Lua: event handlers are methods whose names match the event. Example (pending-build update):

```text
Interface/AddOns/Ascension_CharacterAdvancement/CharacterAdvancement.lua (event method)
2928: end
2929: 
2930: -- DOC: CharacterAdvancementMixin:CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED
2931: -- What this does: Do a specific piece of work related to 'CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED'.
2932: -- When it runs: Called by other code when needed.
2933: -- Inputs:
2934: --   - self: the UI object this function belongs to
2935: -- Output: Nothing (it mainly updates state and/or the UI).
2936: -- What it changes: updates UI/state.
2937: function CharacterAdvancementMixin:CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED()
2938:     if not self.preserveFilter then
2939:         self:Search()
2940:         self.preserveFilter = false
2941:     end
2942:     local specFile = C_CVar.Get("caLastSpec")
2943: 
2944:     if specFile == "SUMMARY" then
2945:         self:FullUpdate()
2946:     elseif self.Content.AbilityBrowser:IsVisible() then
2947:         self:BrowserSearch()
2948:     else
2949:         self:Refresh()
2950:     end
```

---

### 3) Frame pools + virtual templates: how the UI renders lots of spells/talents efficiently

The main CA frame uses `CreateFramePool(...)` to reuse many button frames (spells, talents, icons) without constantly creating/destroying frames:

```text
Interface/AddOns/Ascension_CharacterAdvancement/CharacterAdvancement.lua (frame pools)
0103:     self.mode = Enum.GameMode.None
0104:     self.CategoryPool = CreateFramePool("Frame", self.Content.ScrollChild.Spells, "CASpellCategoryTemplate")
0105:     self.SpellPool = CreateFramePool("Button", self.Content.ScrollChild.Spells, "CASpellButtonTemplate")
0106:     self.CompactSpellPool = CreateFramePool("Button", self.Content.ScrollChild.Spells, "CACompactSpellButtonTemplate")
0107:     self.TalentPool = CreateFramePool("Button", self.Content.ScrollChild.Talents, "CATalentButtonTemplate")
0108: 
0109:     self.SpellClassIconsPool = CreateFramePool("Button", self.Content.ScrollChild.Spells, "CASummaryClassIconTemplate")
0110:     self.TalentClassIconsPool = CreateFramePool("Button", self.Content.ScrollChild.Talents, "CASummaryClassIconTemplate")
0111: 
```

Those pool templates come from the XML template files. For example, `CATalentButtonTemplate` is a **virtual** `<Button>` template whose `<OnLoad>` attaches the `CATalentButtonMixin` via `MixinAndLoadScripts`:

```text
Interface/AddOns/Ascension_CharacterAdvancement/Templates/CharacterAdvancementTemplates.xml (CATalentButtonTemplate OnLoad)
0936:         </Frames>
0937: 
0938:         <Scripts>
0939:             <!--  NOTE: The code inside <OnLoad> is Lua that runs for this UI callback. -->
0940:             <OnLoad>
0941:                 MixinAndLoadScripts(self, "CATalentButtonMixin")
0942:                 self.Icon.LocationIcon:SetFrameLevel(self.Icon.DisabledOverlay:GetFrameLevel()+1)
0943:                 self.Icon.RankUp:SetFrameLevel(self.Icon.DisabledOverlay:GetFrameLevel()+1)
0944:                 self.Icon.RankFrame:SetFrameLevel(self.Icon.DisabledOverlay:GetFrameLevel()+1)
0945:             </OnLoad>
0946:         </Scripts>
0947:     </Button>
0948:     
0949:     <Button name="CAPrimaryStatButtonTemplate" motionScriptsWhileDisabled="true" virtual="true">
0950:         <Size x="32" y="32"/>
```

The browser uses the exact same pattern: XML creates the row template and attaches `CABrowserRowMixin` on load:

```text
Interface/AddOns/Ascension_CharacterAdvancement/Browser/CharacterAdvancementBrowser.xml (CABrowserRowTemplate OnLoad)
0260:                 self.Icon.Lock:SetAtlas("communities-icon-lock", Const.TextureKit.IgnoreAtlasSize)
0261:     			self.Shadow:SetAtlas("spellbook-text-background", Const.TextureKit.IgnoreAtlasSize)
0262:     			self.Icon.Ring:SetAtlas("category-icon-ring", Const.TextureKit.IgnoreAtlasSize)
0263:     			MixinAndLoadScripts(self, "CABrowserRowMixin")
0264:     		</OnLoad>
0265:     	</Scripts>
0266:     </Frame>
```

---

### 4) “Entry” tables: what fields the UI consumes (proven by usage)

When drawing the talent grid, the UI iterates `C_CharacterAdvancement.GetTalentsByClass(class, spec, false)` and reads entry fields like `ID`, `Row`, `Column`, and (later) builds `talentFrame.NodeMap[entry.ID] = ...`:

```text
Interface/AddOns/Ascension_CharacterAdvancement/CharacterAdvancement.lua (SetTalents: entry fields used for layout + NodeMap)
2211:     if CA_USE_GATES_DEBUG then
2212:         self:RefreshGateInfo(class, spec, true) -- we need to scan it before to button properly update on SetEntry
2213:     end
2214: 
2215:     local height = self.Content:GetHeight()
2216:     local button, column, row, x, y
2217:     for i, entry in ipairs(C_CharacterAdvancement.GetTalentsByClass(class, spec, false)) do
2218:         button = self.TalentPool:Acquire()
2219: 
2220:         if CA_USE_GATES_DEBUG then
2221:             -- work with gates
2222:             local gate = talentFrame:DefineGatesForButton(entry.Row+1)
2223: 
2224:             talentFrame:DefineGateTopLeftNode(gate, entry, button)
2225:             self:RefreshGateInfo(class, spec) -- TODO: needs better optimization we need to scan it before to button properly update on SetEntry
2226: 
2227:             button.gate = gate
2228:         else
2229:             button.gate = nil
2230:         end
2231:         
2232:         button:SetEntry(entry)
2233:         column = entry.Column - 1
2234:         row = entry.Row
2235:         talentFrame.FilledNodes[column] = talentFrame.FilledNodes[column] or {}
2236:         talentFrame.FilledNodes[column][row] = true
2237: 
2238:         x = -58-26 + column * 52 + (talentFrame.shift or 0)-- -26 to center 4 rows under essence text 
2239:         y = yStarting + row * 44
2240: 
2241:         button:ClearAndSetPoint("TOP", talentFrame, "TOP", x, -y)
2242:         button:Show()
2243: 
2244:         if entry.ID == self.LocateID then
2245:             button:ShowLocation()
2246:             self.LocateID = nil
2247:         end
2248: 
2249:         talentFrame.NodeMap[entry.ID] = { button = button, column = column, row = row }
```

Then it traverses `entry.ConnectedNodes` to build the parent → child edge list:

```text
Interface/AddOns/Ascension_CharacterAdvancement/CharacterAdvancement.lua (ConnectedNodes traversal)
2251:         -- connections are backwards
2252:         -- the child node references the parent node
2253:         
2254:         -- something else is a child of this node but couldnt find info about this parent node
2255:         if talentFrame.ConnectedNodes[entry.ID] and not talentFrame.ConnectedNodes[entry.ID].button then
2256:             talentFrame.ConnectedNodes[entry.ID].button = button
2257:             talentFrame.ConnectedNodes[entry.ID].column = column
2258:             talentFrame.ConnectedNodes[entry.ID].row = row
2259:         end
2260: 
2261:         for _, parentNodeID in pairs(entry.ConnectedNodes) do
2262:             -- parent node doesnt already exist 
2263:             if not talentFrame.ConnectedNodes[parentNodeID] then
2264:                 if talentFrame.NodeMap[parentNodeID] then -- already discovered, connect parent.
2265:                     talentFrame.ConnectedNodes[parentNodeID] = talentFrame.NodeMap[parentNodeID]
2266:                 else
2267:                     talentFrame.ConnectedNodes[parentNodeID] = {}
2268:                 end
2269:             end
2270: 
2271:             local parentNode = talentFrame.ConnectedNodes[parentNodeID]
2272: 
2273:             -- attach ourself as a child
2274:             if not parentNode.targets then
2275:                 parentNode.targets = {}
2276:             end
2277:             
2278:             tinsert(parentNode.targets, { column = column, row = row, button = button })
2279:         end
2280: 
```

Those snippets are the *proof* for which entry fields this UI expects to exist (or be nil-safe).

---

### 5) Pending-build (“preview changes”) state machine

The UI has an explicit “preview changes” mode gated by the CVar `previewCharacterAdvancementChanges`:

- in preview mode it uses `CanAddByEntryID(...)` + `AddByEntryID(...)`
- otherwise it uses `CanLearnID(...)` + `CharacterAdvancementUtil.ConfirmOrLearnID(...)`

```text
Interface/AddOns/Ascension_CharacterAdvancement/CharacterAdvancement.lua (dropdown learn logic)
2552:     else -- regular dropdown
2553:         -- swap
2554:         if CharacterAdvancementUtil.IsSwapping() then
2555:             info = UIDropDownMenu_CreateInfo()
2556:             info.notCheckable = true
2557:             info.disabled = not CharacterAdvancementUtil.IsSwapSuggestion(dropdown.targetEntry.ID)
2558:             info.text = (CA_SWAP_BLUE):format(LinkUtil:GetSpellLinkInternalID(CharacterAdvancementUtil.IsSwapping()), LinkUtil:GetSpellLinkInternalID(dropdown.targetEntry.ID))
2559:             -- DOC: info.func
2560:             -- What this does: Call into the Character Advancement system (server/game API) and update the UI with the result.
2561:             -- When it runs: Called by other code when needed.
2562:             -- Inputs: none
2563:             -- Output: Nothing (it mainly updates state and/or the UI).
2564:             -- What it changes: uses Character Advancement API.
2565:             info.func = function()
2566:                 CharacterAdvancementUtil.AttemptSwap(dropdown.targetEntry.ID)
2567:             end
2568:             UIDropDownMenu_AddButton(info, level)
2569:         end
2570: 
2571:         -- learn
2572:         info = UIDropDownMenu_CreateInfo()
2573:         info.notCheckable = true
2574:         info.text = LEARN
2575:         if C_CVar.GetBool("previewCharacterAdvancementChanges") then
2576:             local numRanks = 1
2577:             info.disabled = not C_CharacterAdvancement.CanAddByEntryID(dropdown.targetEntry.ID, numRanks)
2578:             -- DOC: info.func
2579:             -- What this does: Call into the Character Advancement system (server/game API) and update the UI with the result.
2580:             -- When it runs: Called by other code when needed.
2581:             -- Inputs: none
2582:             -- Output: Nothing (it mainly updates state and/or the UI).
2583:             -- What it changes: uses Character Advancement API.
2584:             info.func = function()
2585:                 CharacterAdvancementUtil.MarkForSwap(nil)
2586:                 C_CharacterAdvancement.AddByEntryID(dropdown.targetEntry.ID, numRanks)
2587:             end
2588:         else
2589:             info.disabled = not C_CharacterAdvancement.CanLearnID(dropdown.targetEntry.ID)
2590:             info.func = function()
2591:                 CharacterAdvancementUtil.ConfirmOrLearnID(dropdown.targetEntry.ID)
2592:             end
2593:         end
```

If the user closes the UI while there are pending changes, it shows an “unsaved” popup:

```text
Interface/AddOns/Ascension_CharacterAdvancement/CharacterAdvancement.lua (OnHide pending check)
0432: 
0433:     if C_CharacterAdvancement.IsPending() then
0434:         StaticPopup_Show("CLOSE_CHARACTER_ADVANCEMENT_UNSAVED_PENDING_CHANGES")
0435:     end
0436: end
```

While pending, currency totals come from “pending remaining” getters instead of the player’s item counts:

```text
Interface/AddOns/Ascension_CharacterAdvancement/CharacterAdvancement.lua (RefreshCurrencies pending branch)
1456:     local aeCount, teCount
1457:     if BuildCreatorUtil.IsPickingSpells() then
1458:         local _, remainingAE, _, remainingTE = C_BuildEditor.GetEssenceForLevel(BuildCreatorUtil.GetPickLevel())
1459:         aeCount = remainingAE
1460:         teCount = remainingTE
1461:     else
1462:         aeCount = C_CharacterAdvancement.IsPending() and C_CharacterAdvancement.GetPendingRemainingAE() or GetItemCount(ItemData.ABILITY_ESSENCE)
1463:         teCount = C_CharacterAdvancement.IsPending() and C_CharacterAdvancement.GetPendingRemainingTE() or GetItemCount(ItemData.TALENT_ESSENCE)
1464:     end
```

The “Save Changes” button is enabled/disabled by `CanApplyPendingBuild()` (note the multi-return used for error display):

```text
Interface/AddOns/Ascension_CharacterAdvancement/CharacterAdvancement.lua (CanApplyPendingBuild usage)
1523:     if C_CharacterAdvancement.IsPending() then
1524:         local canApply, reason, traversalError, entryID, entryRank, marksCost, goldCost = C_CharacterAdvancement.CanApplyPendingBuild()
1525:         button:SetEnabled(canApply)
1526:         button.YellowGlowLeft:Show()
1527:         button.YellowGlowRight:Show()
1528:         button.YellowGlowMiddle:Show()
1529:         undoButton:Enable()
1530: 
1531:         if reason and not(canApply) and traversalError then
1532:             local reason = _G[reason] or reason .. ": %s"
1533:             local entry = C_CharacterAdvancement.GetEntryByInternalID(entryID)
1534: 
1535:             if entry then
1536:                 reason = reason:format(entry.Name, entryRank or "", traversalError and _G[traversalError] or traversalError or "")
1537:                 button.ErrorText:SetText(reason)
1538:                 button.ErrorText:Show()
1539:                 button.Shadow:Show()
1540:             end
1541:         end
```

Finally, the shared util shows the apply flow (and the BuildCreator bridge after apply):

```text
Interface/FrameXML/Util/CharacterAdvancementUtil.lua (ConfirmApplyPendingBuild)
0516: function CharacterAdvancementUtil.ConfirmApplyPendingBuild()
0517:     CharacterAdvancementUtil.MarkForSwap(nil)
0518:     local canApply, reason, traversalError, entryID, entryRank, marksCost, goldCost = C_CharacterAdvancement.CanApplyPendingBuild()
0519:     local costString
0520:     if marksCost > 0 then
0521:         local markItem = Item:CreateFromID(ItemData.MARK_OF_ASCENSION)
0522:         local markText = marksCost .. " " .. markItem:GetIconLink(22)
0523: 
0524:         costString = markText
0525:     end
0526: 
0527:     if goldCost > 0 then
0528:         costString = costString and (costString .. "\n") or "" .. GetMoneyString(goldCost)
0529:     end
0530: 
0531:     if costString then
0532:         StaticPopup_Show("CONFIRM_APPLY_PENDING_BUILD", costString)
0533:     else
0534:         --StaticPopup_Show("CONFIRM_APPLY_PENDING_BUILD_NO_COST")
0535:         C_CharacterAdvancement.ApplyPendingBuild()
0536:         if BuildCreatorUtil.GetPendingBuildID() then
0537:             C_BuildCreator.ActivateBuild(BuildCreatorUtil.GetPendingBuildID(), true, true)
0538:             BuildCreatorUtil.ClearPendingBuildID()
0539:         end
0540:     end
```

---

### 6) Browser/search pipeline: categories → filter cache → paged entries

The browser uses a category-based cache in `C_CharacterAdvancement`:

1) Get category IDs (`GetCategories`)  
2) Set filters per category (`SetFilteredEntriesByCategory`)  
3) Ask for counts (`GetNumFilteredEntriesByCategory`)  
4) Fetch entries by index (`GetFilteredEntryAtIndexByCategory`) which returns `(entry, isSuggested)`  

```text
Interface/AddOns/Ascension_CharacterAdvancement/Browser/CharacterAdvancementBrowser.lua (DisplaySearchResults)
0928: function CABrowserMixin:DisplaySearchResults(searchQuery, filterOutput)
0929: 	--dprint("CABrowserMixin:DisplaySearchResults")
0930: 	
0931: 	local categories = C_CharacterAdvancement.GetCategories()
0932: 
0933: 	-- SPELL_CATEGORY_RECENTLY_UNLOCKED = 31;
0934: 	
0935: 	local hasDisabledCategory = false
0936: 
0937: 	for i = 1, #categories do
0938: 		local categoryID = categories[i]
0939: 		local reqLevel = C_CharacterAdvancement.GetCategoryDisplayInfo(categoryID)
0940: 
0941: 		if reqLevel <= UnitLevel("player") or not(hasDisabledCategory) then
0942: 			if not HIDDEN_CATEGORIES[categoryID] then
0943: 				C_CharacterAdvancement.SetFilteredEntriesByCategory(categoryID, filterOutput[2], searchQuery or "", filterOutput[1])
0944: 			end
0945: 		end
0946: 
0947: 		if reqLevel > UnitLevel("player") then
0948: 			hasDisabledCategory = true
0949: 		end
0950: 	end
0951: 
0952: 	self:BuildCategoryMap()
0953: 	self:RefreshScrollFrame()
0954: end
```

Row-count planning per category uses `GetNumFilteredEntriesByCategory`:

```text
Interface/AddOns/Ascension_CharacterAdvancement/Browser/CharacterAdvancementBrowser.lua (BuildCategoryMap)
0810: function CABrowserMixin:BuildCategoryMap()
0811: 	wipe(self.categoryMap)
0812: 	self.categoryMap = {}
0813: 	self.totalRows = 0
0814: 	self.firstRecentCategoryID = nil -- "rowindex = startindex"
0815: 
0816: 	local categories = C_CharacterAdvancement.GetCategories()
0817: 	local hasDisabledCategory = false
0818: 
0819: 	for i = 1, #categories do
0820: 		local categoryID = categories[i]
0821: 		local categoryTotalResults = C_CharacterAdvancement.GetNumFilteredEntriesByCategory(categoryID) 
0822: 		local categoryTakesRows = math.ceil(categoryTotalResults/SPELLS_PER_ROW)
0823: 		local reqLevel = C_CharacterAdvancement.GetCategoryDisplayInfo(categoryID)
0824: 
0825: 		if categoryTakesRows > 0 then
0826: 			if hasDisabledCategory then
0827: 				categoryTakesRows = 1 -- display just category name
0828: 			elseif RECENTLY_UNLOCKED_CATEGORIES[categoryID] then -- for recently unlocked, display header only for 1st recently unlocked
0829: 
0830: 				categoryTotalResults = categoryTotalResults + categoryTakesRows -- add 1 blank element for each row
0831: 				local categoryTakesRowsNew = math.ceil(categoryTotalResults/SPELLS_PER_ROW)
0832: 
0833: 				if categoryTakesRowsNew > categoryTakesRows then
0834: 					categoryTotalResults = categoryTotalResults + (categoryTakesRowsNew-categoryTakesRows)
0835: 				end
0836: 
0837: 				categoryTakesRows = math.ceil(categoryTotalResults/SPELLS_PER_ROW)
0838: 
0839: 				if not self.firstRecentCategoryID then
0840: 					self.firstRecentCategoryID = categoryID
0841: 					categoryTakesRows = categoryTakesRows + 1
0842: 				end
0843: 			else
0844: 				categoryTakesRows = categoryTakesRows + 1 -- add 1 extra row for category name
0845: 			end
0846: 		end
```

Actual entry retrieval for a row uses the indexed getter that returns `entry` plus an `isSuggested` flag:

```text
Interface/AddOns/Ascension_CharacterAdvancement/Browser/CharacterAdvancementBrowser.lua (LoadEntry + OnUpdate icon throttling)
0667: 
0668:     self:SetAvailableVisual(reqLevel <= UnitLevel("player"), name, name.." ("..string.format(CA_BROWSER_UNLOCKS_AT_LEVEL, "|cffFF0000"..reqLevel.."|r")..")|r")
0669: end
0670: 
0671: -- DOC: CABrowserRowMixin:LoadEntry
0672: -- What this does: Show part of the UI (or switch which panel is visible).
0673: -- When it runs: Called by other code when needed.
0674: -- Inputs:
0675: --   - self: the UI object this function belongs to
0676: --   - button: the button that triggered this (the thing you clicked)
0677: --   - index: a position number in a list
0678: -- Output: A value used by other code (self.categoryID).
0679: -- What it changes: shows/hides UI pieces, uses Character Advancement API.
0680: function CABrowserRowMixin:LoadEntry(button, index)
0681: 	local entry, isSuggested = C_CharacterAdvancement.GetFilteredEntryAtIndexByCategory(self:GetCategoryID(), index)
0682: 
0683: 	if entry then
0684: 		button.Icon.Icon:Show()
0685: 		button:SetEntry(entry, isSuggested)
0686: 		--button:MakeClass()
0687: 	end
0688: end
0689: 
0690: -- DOC: CABrowserRowMixin:LoadIconsOnUpdate
0691: -- What this does: Show part of the UI (or switch which panel is visible).
0692: -- When it runs: Called by other code when needed.
0693: -- Inputs:
0694: --   - self: the UI object this function belongs to
0695: -- Output: A value used by other code (self.categoryID).
0696: -- What it changes: shows/hides UI pieces, uses Character Advancement API.
0697: function CABrowserRowMixin:LoadIconsOnUpdate()
0698: 	for i = 1, MAX_ICON_LOADS_PER_FRAME do
0699: 		local button, index = next(self.delayedEntries) 
0700: 
0701: 		if button then
0702: 			self:LoadEntry(button, index)
0703: 			self.delayedEntries[button] = nil
0704: 		else
0705: 			self:SetScript("OnUpdate", nil)
0706: 		end
0707: 	end
0708: end
```

---

### 7) Cost math lives in a shared FrameXML util (`CACostUtil`)

The cost util is plain Lua math plus constants. Example: reset gold cost differs for custom classes:

```text
Interface/FrameXML/Util/CharacterAdvancementCostUtil.lua (constants + cost formulas)
0001: -- GUIDE: What is this file?
0002: -- Purpose: Shared utility helpers (small reusable functions) used by the Character Advancement UI.
0003: --
0004: -- How to read this (no programming experience needed):
0005: -- - Lines starting with '--' are comments meant for humans. The game ignores them.
0006: -- - A 'function' is a named set of steps. Other parts of the UI can call it.
0007: -- - Names with ':' (example: MyFrame:OnLoad) mean the steps belong to a specific UI element.
0008: -- - This addon is event-driven: the game calls certain functions when something happens (open window, click button, etc.).
0009: --
0010: -- Safe edits for non-programmers:
0011: -- - Text near the top (labels, descriptions) is usually safe to change.
0012: -- - Avoid renaming functions unless you also update every place they are referenced.
0013: 
0014: ABILITY_PURGE_MARK_OF_ASCENSION_COST = 10000
0015: TALENT_PURGE_MARK_OF_ASCENSION_COST = 7500
0016: UNLEARN_ABILITY_MARK_OF_ASCENSION_COST = 250
0017: ABILITY_PURGE_MARK_OF_ASCENSION_COA_COST_PER_LEVEL = 167
0018: TALENT_PURGE_MARK_OF_ASCENSION_COA_COST_PER_LEVEL = 125
0019: UNLEARN_ABILITY_MARK_OF_ASCENSION_COA_COST_PER_LEVEL = 4
0020: FREE_RESET_LEVEL = 10
0021: 
0022: CACostUtil = {}
0023: 
0024: -- DOC: CalculateResetCostGold
0025: -- What this does: Do a specific piece of work related to 'CalculateResetCostGold'.
0026: -- When it runs: Called by other code when needed.
0027: -- Inputs:
0028: --   - level: a character level number
0029: --   - value: a value to store/apply
0030: -- Output: A value used by other code (((value * 416.666666667) + (1.1622083333...).
0031: -- What it changes: updates UI/state.
0032: local function CalculateResetCostGold(level, value)
0033: 	if (IsCustomClass()) then
0034: 		return ((value * 416.666666667) + (1.16220833333 * math.pow(level, 2)) + (18.7038333333 * level) - 359.025) * level * 0.25
0035: 	else
```

---

## How to use these files

- Use this repo as a **reference** while developing / debugging UI behavior.
- For hands-on console commands to probe the UI and APIs, see:
  - **CA_Pratical_Usage.md** (practical `/run` snippets)
  - **CA_Pratical_AddonUsage.md** (small addon examples that wrap the same probes)
  - **LOADED_FILES.md** (what loads when the UI opens)

---

## Comment markers used in the annotated sources

- **Lua (`.lua`)**
  - `--[[ GUIDE: ... --]]` (file-level overview)
  - `--[[ DOC: SomeFunctionName ... --]]` (function-level explanation)
- **XML (`.xml`)**
  - `<!-- GUIDE: ... -->` (file-level overview)
  - `<!-- NOTE: ... -->` (element-level explanation)

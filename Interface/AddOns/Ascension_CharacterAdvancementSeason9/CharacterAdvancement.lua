-- GUIDE: What is this file?
-- Purpose: Season 9 version of the Character Advancement window logic (what happens when you open the UI, click tabs, pick talents, etc.).
--
-- How to read this (no programming experience needed):
-- - Lines starting with '--' are comments meant for humans. The game ignores them.
-- - A 'function' is a named set of steps. Other parts of the UI can call it.
-- - Names with ':' (example: MyFrame:OnLoad) mean the steps belong to a specific UI element.
-- - This addon is event-driven: the game calls certain functions when something happens (open window, click button, etc.).
--
-- Safe edits for non-programmers:
-- - Text near the top (labels, descriptions) is usually safe to change.
-- - Avoid renaming functions unless you also update every place they are referenced.

-- TODO: Move to constants?
CA_USE_GATES_DEBUG = false

--[[
    requiresGlobal, requiresTree, isMet, topLeftNode updated in
    CharacterAdvancementMixin:RefreshGateInfo
]]--
CA_TIER_GATES = { -- row ID means tier num
        {tier = 2, spentGlobalRequired = 0, spentTreeRequired = 1, requiresGlobal = 0, requiresTree = 0, isMetTree = false, isMetGlobal = false, topLeftNode = nil},
        {tier = 3, spentGlobalRequired = 0, spentTreeRequired = 2, requiresGlobal = 0, requiresTree = 0, isMetTree = false, isMetGlobal = false, topLeftNode = nil},
        {tier = 4, spentGlobalRequired = 0, spentTreeRequired = 3, requiresGlobal = 0, requiresTree = 0, isMetTree = false, isMetGlobal = false, topLeftNode = nil},
        {tier = 5, spentGlobalRequired = 0, spentTreeRequired = 4, requiresGlobal = 0, requiresTree = 0, isMetTree = false, isMetGlobal = false, topLeftNode = nil},
        {tier = 6, spentGlobalRequired = 25, spentTreeRequired = 5, requiresGlobal = 0, requiresTree = 0, isMetTree = false, isMetGlobal = false, topLeftNode = nil},
        {tier = 7, spentGlobalRequired = 25, spentTreeRequired = 6, requiresGlobal = 0, requiresTree = 0, isMetTree = false, isMetGlobal = false, topLeftNode = nil},
        {tier = 8, spentGlobalRequired = 25, spentTreeRequired = 7, requiresGlobal = 0, requiresTree = 0, isMetTree = false, isMetGlobal = false, topLeftNode = nil},
        {tier = 9, spentGlobalRequired = 25, spentTreeRequired = 8, requiresGlobal = 0, requiresTree = 0, isMetTree = false, isMetGlobal = false, topLeftNode = nil},
    }
--

-- DOC: C_CharacterAdvancement.CanUseBrowser
-- What this does: Checks whether a feature is enabled/allowed and returns true/false.
-- When it runs: Called after this UI registers for events, or when something changes that needs a refresh.
-- Inputs: none
-- Output: A value used by other code (C_Config.GetBoolConfig("CONFIG_ABILITY_B...).
-- What it changes: shows/hides UI pieces, changes text on screen, listens for game events, uses Character Advancement API.
function C_CharacterAdvancement.CanUseBrowser()
    return C_Config.GetBoolConfig("CONFIG_ABILITY_BROWSER_ENABLED")
end

CharacterAdvancementMixin = {}

local HEADER_NO_PRIMARY_STAT_HEIGHT = 30
local HEADER_PRIMARY_STAT_HEIGHT = 96

local NUM_SPEC_TABS = 3
local SUMMARY_SPEC_TAB = NUM_SPEC_TABS + 1
local BROWSER_TAB = SUMMARY_SPEC_TAB + 1
local SCROLL_X_SHIFT = 22

-- DOC: CharacterAdvancementMixin:OnLoad
-- What this does: Sets up this UI element: prepares data, connects events, and sets initial visuals.
-- When it runs: Runs once when this UI element is created/loaded.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, changes text on screen, listens for game events.
function CharacterAdvancementMixin:OnLoad()
    C_CVar.Set("previewCharacterAdvancementChanges", "0")
    self:RegisterEvent("ASCENSION_CA_SPECIALIZATION_ACTIVE_ID_CHANGED")
    PortraitFrame_SetTitle(self, CHARACTER_ADVANCEMENT)
    PortraitFrame_SetIcon(self, "Interface\\Icons\\trade_archaeology_draenei_tome")
    self.SideBar.SpecList.IconSelector.Text:SetText(ENTER_SPEC_NAME_HELP)
    self.Content.LockTalentsFrame:SetFrameLevel(self.Content.NineSlice:GetFrameLevel()+10)
    self.Content.LockTalentsFrame.Text:SetText(CA_TALENTS_UNLOCK_AT_LEVEL or "Unlocks at level 10.")
    self.CloseButton:SetScript("OnClick", function()
        HideUIPanel(Collections)
    end)
    self.mode = Enum.GameMode.None
    self.SpellPool = CreateFramePool("Button", self.Content.ScrollChild.Spells, "CASpellButtonTemplate")
    self.TalentPool = CreateFramePool("Button", self.Content.ScrollChild.Talents, "CATalentButtonTemplate")
    self.GatePool = CreateFramePool("FRAME", self.Content.ScrollChild.Talents, "CATalentGateTemplate")
    self.GatePoolGlobal = CreateFramePool("FRAME", self.Content.ScrollChild.Talents, "CATalentGateGlobalTemplate")

    self:SetupClassButtons()
    self:SetupSpecTabs()
    self:SetupSideBarTabs()
    CharacterAdvancementUtil.InitializeFilter(self.SideBar.SpellList.Header.Filter, GenerateClosure(self.Search, self))
    CharacterAdvancementUtil.InitializeSpellTagFilter(self.Content.Filter, GenerateClosure(self.BrowserSearch, self))
    self.Content.SpellTagFrame:RegisterCallback("OnSpellTagClicked", GenerateClosure(self.RemoveSpellTag, self))
    self:RefreshPrimaryStats()
    self:RefreshCurrencies()
    UIDropDownMenu_Initialize(self.SpellDropDownMenu, GenerateClosure(self.InitializeSpellDropDown, self), "MENU")
    C_GameMode:RegisterCallback("OnGameModeChanged", GenerateClosure(self.OnGameModeChanged, self))

    self.Content.Footer.SpellCurrencyBar:SetJustify("LEFT")
    self.Content.Footer.TalentCurrencyBar:SetJustify("RIGHT")

    -- DOC: self.Navigation.PetTalents:OnTalentCountEnter
    -- What this does: Show part of the UI (or switch which panel is visible).
    -- When it runs: Runs for a UI callback named OnTalentCountEnter.
    -- Inputs:
    --   - self: the UI object this function belongs to
    -- Output: A value used by other code (self.mode == Enum.GameMode.Draft).
    -- What it changes: shows/hides UI pieces, changes text on screen.
    function self.Navigation.PetTalents:OnTalentCountEnter()
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(UNSPENT_TALENT_POINTS:format(GetUnspentTalentPoints(false, true)))
        GameTooltip:Show()
    end
    
    self.InputBlocker:SetFrameLevel(self.Content.NineSlice:GetFrameLevel() + 10)
end

-- DOC: CharacterAdvancementMixin:OnGameModeChanged
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Runs for a UI callback named OnGameModeChanged.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: A value used by other code (self.mode == Enum.GameMode.Draft).
-- What it changes: shows/hides UI pieces.
function CharacterAdvancementMixin:OnGameModeChanged()
    if C_GameMode:IsGameModeActive(Enum.GameMode.Draft) then
        self.mode = Enum.GameMode.Draft
        PortraitFrame_SetTitle(self, format("%s - %s", CHARACTER_ADVANCEMENT, DRAFT_MODE))
        PortraitFrame_SetIcon(self, "Interface\\Icons\\inv_misc_dmc_destructiondeck")
        self.SideBar:ShowTabID(self.SideBar.LoadoutTab)
        self.Content.Footer:Show()
        self.Content.WCRapidRollButton:Hide()
    elseif C_GameMode:IsGameModeActive(Enum.GameMode.WildCard) then
        self.mode = Enum.GameMode.WildCard
        PortraitFrame_SetTitle(self, format("%s - %s", CHARACTER_ADVANCEMENT, WILDCARD_MODE))
        PortraitFrame_SetIcon(self, "Interface\\Icons\\misc_rune_pvp_random")
        self.SideBar:HideTabID(self.SideBar.LoadoutTab)
        self.Content.Footer:Hide()
    else
        self.mode = Enum.GameMode.None
        PortraitFrame_SetTitle(self, CHARACTER_ADVANCEMENT)
        if C_Player:IsDefaultClass() then
            PortraitFrame_SetClassIcon(self, C_Player:GetClass())
        else
            PortraitFrame_SetIcon(self, "Interface\\Icons\\trade_archaeology_draenei_tome")
        end
        if C_Player:IsHero() then
            self:ShowRarityFlyout()
        end
        self.SideBar:ShowTabID(self.SideBar.LoadoutTab)

        self.Content.WCRapidRollButton:Hide()
        if C_GameMode:IsGameModeActive(Enum.GameMode.BuildDraft) then
            self.Content.Footer:Hide()
        else
            self.Content.Footer:Show()
        end
    end
    self:Refresh()
end

-- DOC: CharacterAdvancementMixin:IsDraftMode
-- What this does: Checks a condition and returns true/false.
-- When it runs: Called after this UI registers for events, or when something changes that needs a refresh.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: A value used by other code (self.mode == Enum.GameMode.Draft).
-- What it changes: shows/hides UI pieces, listens for game events.
function CharacterAdvancementMixin:IsDraftMode()
    return self.mode == Enum.GameMode.Draft
end

function CharacterAdvancementMixin:IsWildCardMode()
    return self.mode == Enum.GameMode.WildCard
end

-- DOC: CharacterAdvancementMixin:LockTalentsFrameCheck
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called after this UI registers for events, or when something changes that needs a refresh.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (nil).
-- What it changes: shows/hides UI pieces, listens for game events, uses Character Advancement API.
function CharacterAdvancementMixin:LockTalentsFrameCheck()
    self.Content.LockTalentsFrame:Hide()

    local lastClass = C_CVar.Get("caLastClass")

    if not string.isNilOrEmpty(lastClass) and (lastClass == "BROWSER") and (C_CVar.Get("caLastSpec") == "BROWSER") then
        return
    end

    if (UnitLevel("player") < 10) and not(C_Player:IsPrestiged()) then
        self.Content.LockTalentsFrame:Show()
    end
end

-- DOC: CharacterAdvancementMixin:RegisterUpdateEvents
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called after this UI registers for events, or when something changes that needs a refresh.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: listens for game events, uses Character Advancement API.
function CharacterAdvancementMixin:RegisterUpdateEvents()
    self:RegisterEvent("CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED")
    self:RegisterEvent("WILDCARD_ENTRY_LEARNED")
    self:RegisterEvent("PET_TALENT_UPDATE")
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    self:RegisterEvent("PLAYER_LEVEL_UP")
    self:RegisterEvent("BAG_UPDATE")
    self:RegisterEvent("TOKEN_UPDATED")
    self:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
    self:RegisterEvent("CHARACTER_ADVANCEMENT_SUGGESTIONS_UPDATED")
    self:RegisterEvent("SPELL_TAGS_CHANGED")
    self:RegisterEvent("SPELL_TAG_TYPES_CHANGED")
    self:RegisterEvent("STAT_SUGGESTIONS_UPDATED")
end

-- DOC: CharacterAdvancementMixin:UnregisterUpdateEvents
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: listens for game events, uses Character Advancement API.
function CharacterAdvancementMixin:UnregisterUpdateEvents()
    self:UnregisterEvent("CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED")
    self:UnregisterEvent("WILDCARD_ENTRY_LEARNED")
    self:UnregisterEvent("PET_TALENT_UPDATE")
    self:UnregisterEvent("PLAYER_REGEN_DISABLED")
    self:UnregisterEvent("PLAYER_REGEN_ENABLED")
    self:UnregisterEvent("PLAYER_LEVEL_UP")
    self:UnregisterEvent("BAG_UPDATE")
    self:UnregisterEvent("TOKEN_UPDATED")
    self:UnregisterEvent("CURRENCY_DISPLAY_UPDATE")
    self:UnregisterEvent("CHARACTER_ADVANCEMENT_SUGGESTIONS_UPDATED")
    self:UnregisterEvent("SPELL_TAGS_CHANGED")
    self:UnregisterEvent("SPELL_TAG_TYPES_CHANGED")
    self:UnregisterEvent("STAT_SUGGESTIONS_UPDATED")
end

-- DOC: CharacterAdvancementMixin:OnShow
-- What this does: Prepares the UI right before the player sees it (updates text, lists, or buttons).
-- When it runs: Runs each time this UI element becomes visible.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: uses Character Advancement API.
function CharacterAdvancementMixin:OnShow()
    self:RegisterUpdateEvents()
    if BuildCreatorUtil.IsPickingSpells() then
        self.SideBar.SpellList:SetGetNumResultsFunction(C_BuildEditor.GetNumFilteredEntries)
        self:ForceUpdateRarityFlyout()

        self.OnEditorSpellsChanged = BuildCreatorUtil:RegisterCallbackWithHandle("OnEditorSpellsChanged", function(_, preserveFilter)
            self:ForceUpdateRarityFlyout()
            self:FullUpdate(preserveFilter)
        end)
    else
        self.SideBar.SpellList:SetGetNumResultsFunction(C_CharacterAdvancement.GetNumFilteredEntries)
        C_CharacterAdvancement.ClearRecentlyLearnedEntries()
        if self.OnEditorSpellsChanged then
            self.OnEditorSpellsChanged:Unregister()
            self.OnEditorSpellsChanged = nil
        end
    end
    
    local lastClass = C_CVar.Get("caLastClass")
    local lastSpec = C_CVar.Get("caLastSpec")
    
    if IsDefaultClass() then
        local class = C_Player:GetClass()
        if lastClass ~= class then
            self:SelectClass(class)
        else
            self:SelectClass(lastClass, lastSpec)
        end
    elseif string.isNilOrEmpty(lastClass) then
        if IsDefaultClass() then
            self:SelectClass(class)
        elseif C_CharacterAdvancement.CanUseBrowser() then
            self:SelectBrowser() -- select browser by default
        end
    elseif lastClass == "BROWSER" then
        if not C_CharacterAdvancement.CanUseBrowser() then
            self:SelectClass("DRUID")
        else
            self:SelectBrowser()
        end
    else
        if string.isNilOrEmpty(lastSpec) then
            self:SelectClass(lastClass)
        else
            self:SelectClass(lastClass, lastSpec)
        end
    end

    self.SideBar:SelectTabID(1)
    self:ClearSearch()
    if not self.initialized then
        self.initialized = true
        self:OnGameModeChanged()
    else
        self:Refresh()
    end
end

-- DOC: CharacterAdvancementMixin:OnHide
-- What this does: Cleans up when the UI closes (stops updates and hides extra popups).
-- When it runs: Runs when this UI element is hidden.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: A value used by other code (self:HidePrimaryStatPicker()).
-- What it changes: shows/hides UI pieces.
function CharacterAdvancementMixin:OnHide()
    self:UnregisterUpdateEvents()
    if BuildCreatorUtil.IsPickingSpells() then
        BuildCreatorUtil.SetPickMode(nil)
    end
    if self.OnEditorSpellsChanged then
        self.OnEditorSpellsChanged:Unregister()
        self.OnEditorSpellsChanged = nil
    end
    
    if WildCardRapidRollingFrame and WildCardRapidRollingFrame:IsShown() then
        WildCardRapidRollingFrame:Hide()
    end
end

-- DOC: CharacterAdvancementMixin:UpdateSpellListHeight
-- What this does: Update what is shown on screen so it matches the latest game data.
-- When it runs: Called whenever the screen needs to be redrawn with fresh information.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: A value used by other code (self:HidePrimaryStatPicker()).
-- What it changes: shows/hides UI pieces.
function CharacterAdvancementMixin:UpdateSpellListHeight()
    local header = self.SideBar.SpellList.Header
    local footer = self.SideBar.SpellList.Footer
    
    local height = 450
    local headerHeight = header:GetHeight()
    self.SideBar.SpellList:SetPoint("TOPLEFT", 0, -headerHeight)
    if header.IsCompact then
        height = height + HEADER_PRIMARY_STAT_HEIGHT - HEADER_NO_PRIMARY_STAT_HEIGHT
    end
    if footer.RarityFlyout:IsShown() then
        height = height - 101
    end

    self.SideBar.SpellList:SetHeight(height)
end

-- DOC: CharacterAdvancementMixin:TogglePrimaryStatPicker
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: A value used by other code (self:HidePrimaryStatPicker()).
-- What it changes: shows/hides UI pieces.
function CharacterAdvancementMixin:TogglePrimaryStatPicker()
    if not self:CanShowPrimaryStat() then
        return self:HidePrimaryStatPicker()
    end

    local header = self.SideBar.SpellList.Header
    if header.IsCompact then
        self:ShowPrimaryStatPicker()
    else
        self:HidePrimaryStatPicker()
    end
end

-- DOC: CharacterAdvancementMixin:ShowPrimaryStatPicker
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (nil).
-- What it changes: shows/hides UI pieces, changes text on screen.
function CharacterAdvancementMixin:ShowPrimaryStatPicker()
    local header = self.SideBar.SpellList.Header
    header.IsCompact = false
    header:SetHeight(HEADER_PRIMARY_STAT_HEIGHT)
    header.NineSlice:SetPoint("BOTTOMRIGHT", 0, 30)
    header.NineSlice.Background:Show()
    header.HintText:Show()
    for i = 1, 4 do
        local button = header["PrimaryStat"..i]
        button:Show()
        button:SetFrameLevel(header:GetFrameLevel()+5)
    end
    self:UpdateSpellListHeight()
end

-- DOC: CharacterAdvancementMixin:HidePrimaryStatPicker
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (nil).
-- What it changes: shows/hides UI pieces, changes text on screen.
function CharacterAdvancementMixin:HidePrimaryStatPicker()
    local header = self.SideBar.SpellList.Header
    header.IsCompact = true
    header:SetHeight(HEADER_NO_PRIMARY_STAT_HEIGHT)
    header.NineSlice:SetPoint("BOTTOMRIGHT", 0, 0)
    header.NineSlice.Background:Hide()
    header.HintText:Hide()
    for i = 1, 4 do
        local button = header["PrimaryStat"..i]
        button:Hide()
    end
    self:UpdateSpellListHeight()
end

-- DOC: CharacterAdvancementMixin:ToggleRarityFlyout
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (nil).
-- What it changes: shows/hides UI pieces, changes text on screen.
function CharacterAdvancementMixin:ToggleRarityFlyout()
    if C_GameMode:IsGameModeActive(Enum.GameMode.Draft, Enum.GameMode.WildCard) then
        return
    end

    if not C_Player:IsHero() then
        return
    end

    local footer = self.SideBar.SpellList.Footer
    if footer.RarityFlyout:IsShown() then
        self:HideRarityFlyout()
    else
        self:ShowRarityFlyout()
    end
end

-- DOC: CharacterAdvancementMixin:ShowRarityFlyout
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (nil).
-- What it changes: shows/hides UI pieces, changes text on screen, uses Character Advancement API.
function CharacterAdvancementMixin:ShowRarityFlyout()
    if C_GameMode:IsGameModeActive(Enum.GameMode.Draft, Enum.GameMode.WildCard) then
        return
    end

    if not C_Player:IsHero() then
        return
    end

    local footer = self.SideBar.SpellList.Footer
    footer.RarityFlyout:Show()
    footer.FlyoutButton:SetText(HIDE_RARITIES)
    footer:SetPoint("TOPLEFT", self.SideBar.SpellList, "BOTTOMLEFT", 0, -101)
    self:UpdateSpellListHeight()
end

-- DOC: CharacterAdvancementMixin:HideRarityFlyout
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, changes text on screen, uses Character Advancement API.
function CharacterAdvancementMixin:HideRarityFlyout()
    local footer = self.SideBar.SpellList.Footer
    footer.RarityFlyout:Hide()
    footer.FlyoutButton:SetText(SHOW_RARITIES)
    self:UpdateSpellListHeight()
    footer:SetPoint("TOPLEFT", self.SideBar.SpellList, "BOTTOMLEFT", 0, 0)
end

-- DOC: CharacterAdvancementMixin:SetSearch
-- What this does: Set a value on this UI element and update related visuals.
-- When it runs: Called when code needs to store a value and/or update the visuals.
-- Inputs:
--   - self: the UI object this function belongs to
--   - text: a piece of information passed in by the caller
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, changes text on screen, uses Character Advancement API.
function CharacterAdvancementMixin:SetSearch(text)
    local searchBox = self.SideBar.SpellList.Header.SearchBox
    if searchBox:GetText() == text then
        self:Search()
    else
        searchBox:SetText(text)
    end
end

local OnlyKnownFilter = { FILTER_KNOWN = true }

-- DOC: CharacterAdvancementMixin:Search
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, changes text on screen, uses Character Advancement API.
function CharacterAdvancementMixin:Search()
    local header = self.SideBar.SpellList.Header
    local text = header.SearchBox:GetText():trim()

    local hasFilter = header.Filter:HasAnyFilters()
    if string.isNilOrEmpty(text) and not hasFilter  then
        if BuildCreatorUtil.IsPickingSpells() then
            C_BuildEditor.SetFilteredEntries("", OnlyKnownFilter)
        else
            C_CharacterAdvancement.SetFilteredEntries("", OnlyKnownFilter)
        end
    else
        if BuildCreatorUtil.IsPickingSpells() then
            C_BuildEditor.SetFilteredEntries(text, header.Filter:GetFilter())
        else
            C_CharacterAdvancement.SetFilteredEntries(text, header.Filter:GetFilter())
        end
    end
    local selectedButton = self.SideBar.SpellList:GetSelectedButton()
    if selectedButton then
        selectedButton:OnDeselected()
    end
    self.SideBar.SpellList:SetSelectedIndex(nil)
    self.SideBar.SpellList:RefreshScrollFrame()
end

-- DOC: CharacterAdvancementMixin:BrowserSearch
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, changes text on screen.
function CharacterAdvancementMixin:BrowserSearch()
    local text = self.Content.SearchBox:GetText():trim()
    local filter = {self.Content.Filter:GetFilter()}
    self.Content.AbilityBrowser:DisplaySearchResults(text, filter)

    if filter and filter[1] and (next(filter[1]) or next(filter[2])) then
        self.Content.SpellTagFrame:Show()
        self.Content.SpellTagFrame:SetUpSpellTags(unpack(filter))
    else
        self.Content.SpellTagFrame:Hide()
    end

    if C_CVar.Get("caLastSpec") ~= "BROWSER" then
        self:SelectBrowser()
    end
end

-- DOC: CharacterAdvancementMixin:RemoveSpellTag
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
--   - _: a piece of information passed in by the caller
--   - filter: the filter/search text used to narrow results
--   - tag: a piece of information passed in by the caller
-- Output: Nothing (nil).
-- What it changes: shows/hides UI pieces, changes text on screen.
function CharacterAdvancementMixin:RemoveSpellTag(_, filter, tag)
    if filter then
        self.Content.Filter:SetFilter(filter, false)
    elseif tag then
       self.Content.Filter:SetFilter("FILTER_SPELLTAG_"..tag, false)
   end
end

-- DOC: CharacterAdvancementMixin:ClearSearch
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (nil).
-- What it changes: shows/hides UI pieces, changes text on screen.
function CharacterAdvancementMixin:ClearSearch()
    self:SetSearch("")
    self.Content.SearchBox:SetText("")
end

function CharacterAdvancementMixin:Locate(entry)
    local class, spec = CharacterAdvancementUtil.GetClassFileForEntry(entry)
    if class then
        self.LocateID = entry.ID
        self:SelectClass(class,spec)
    end
end

-- DOC: CharacterAdvancementMixin:SelectBrowser
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (nil).
-- What it changes: shows/hides UI pieces.
function CharacterAdvancementMixin:SelectBrowser()
    C_CVar.Set("caLastClass", "BROWSER")
    C_CVar.Set("caLastSpec", "BROWSER")
    self:FullUpdate(true)

    for class, button in pairs(self.ClassButtons) do
        button:OnDeSelected()
    end

    self.Content:SelectTabID(BROWSER_TAB)

    self.Navigation.Browser:OnSelected()
end

-- DOC: CharacterAdvancementMixin:SelectClass
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
--   - classFile: a piece of information passed in by the caller
--   - specFile: information about a specialization (spec) choice
-- Output: Nothing (nil).
-- What it changes: shows/hides UI pieces.
function CharacterAdvancementMixin:SelectClass(classFile, specFile)
    if not classFile then return end

    if not self.ClassButtons[classFile] then
        classFile = next(self.ClassButtons)
    end

    if not CHARACTER_ADVANCEMENT_CLASS_SPEC_ORDER[classFile] then
        return
    end

    if not self.Content:IsVisible() then
        self.Content:Show()
        self.Navigation.ShareButton:Show()
    end

    C_CVar.Set("caLastClass", classFile)
    for tabID = 1, NUM_SPEC_TABS do
        local spec = CHARACTER_ADVANCEMENT_CLASS_SPEC_ORDER[classFile][tabID]
        local classInfo = C_ClassInfo.GetSpecInfo(classFile, spec)
        self.Content:UpdateTabText(tabID, classInfo.Name)
    end

    self.Navigation.Browser:OnDeSelected()
    
    for class, button in pairs(self.ClassButtons) do
        if class == classFile then
            button:OnSelected()
        else
            button:OnDeSelected()
        end
    end

    if specFile then
        if specFile == "SUMMARY" then
            self.Content:SelectTabID(SUMMARY_SPEC_TAB)
            return
        else
            for tabID = 1, NUM_SPEC_TABS do
                local spec = CHARACTER_ADVANCEMENT_CLASS_SPEC_ORDER[classFile][tabID]
                if spec == specFile then
                    self.Content:SelectTabID(tabID)
                    return
                end
            end
        end
    end

    self.Content:SelectTabID(1) -- no valid spec found, auto select tab 1
end

-- DOC: CharacterAdvancementMixin:SelectSpec
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
--   - tabID: an identifier (a number/string that points to a specific thing)
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, uses Character Advancement API.
function CharacterAdvancementMixin:SelectSpec(tabID)
    if tabID == SUMMARY_SPEC_TAB then
        C_CVar.Set("caLastSpec", "SUMMARY")
    elseif tabID == BROWSER_TAB then
        C_CVar.Set("caLastSpec", "BROWSER")
    else
        C_CVar.Set("caLastSpec", CHARACTER_ADVANCEMENT_CLASS_SPEC_ORDER[C_CVar.Get("caLastClass")][tabID])
    end
    self:FullUpdate(true)
end

-- DOC: CharacterAdvancementMixin:SetupClassButtons
-- What this does: Set a value on this UI element and update related visuals.
-- When it runs: Called when code needs to store a value and/or update the visuals.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, uses Character Advancement API.
function CharacterAdvancementMixin:SetupClassButtons()
    if self.ClassButtons then return end
    self.ClassButtons = {}
    if IsDefaultClass() then
        local class = C_Player:GetClass()
        local button = CreateFrame("Button", "$parentClassButton1", self.Navigation, "CAClassButtonTemplate")
        button:SetPoint("CENTER", 0, 20)
        button:SetClass(class)
        button:Hide() -- default classes dont need these to be shown
        self.ClassButtons[class] = button
    else

        if C_CharacterAdvancement.CanUseBrowser() then
            local width = (#CHARACTER_ADVANCEMENT_CLASS_ORDER + 2) / 2

            local browserButton = self.Navigation.Browser
            browserButton:SetPoint("CENTER", (1 - width) * 84, 16)
            browserButton:Show()

            for i = 1, #CHARACTER_ADVANCEMENT_CLASS_ORDER do  
                local class = CHARACTER_ADVANCEMENT_CLASS_ORDER[i]
                local button = CreateFrame("Button", "$parentClassButton"..i, self.Navigation, "CAClassButtonTemplate")
                button:SetPoint("CENTER", ((i+1) - width) * 84, 16)
                button:SetClass(class)
                button:Show()
                self.ClassButtons[class] = button
            end
        else
            local width = (#CHARACTER_ADVANCEMENT_CLASS_ORDER + 1) / 2

            for i = 1, #CHARACTER_ADVANCEMENT_CLASS_ORDER do  
                local class = CHARACTER_ADVANCEMENT_CLASS_ORDER[i]
                local button = CreateFrame("Button", "$parentClassButton"..i, self.Navigation, "CAClassButtonTemplate")
                button:SetPoint("CENTER", (i - width) * 84, 16)
                button:SetClass(class)
                button:Show()
                self.ClassButtons[class] = button
            end
        end
    end

    self.Navigation.PetTalents:ClearAndSetPoint("BOTTOMRIGHT", self.Content, "BOTTOMRIGHT", -24, 24)
end

-- DOC: CharacterAdvancementMixin:ShowBrowserTabs
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces.
function CharacterAdvancementMixin:ShowBrowserTabs()
    self.Navigation.ShareButton:Hide()
    self.Content.SearchBox:Show()
    self.Content.Filter:Show()
    self.Content:HideTabs()
    self.Content:ShowTabID(BROWSER_TAB)
    self.Content:ShowTabID(SUMMARY_SPEC_TAB)
end

-- DOC: CharacterAdvancementMixin:ShowClassTabs
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, changes text on screen.
function CharacterAdvancementMixin:ShowClassTabs()
    self.Navigation.ShareButton:Show()
    self.Content.SearchBox:Hide()
    self.Content.Filter:Hide()
    self.Content:ShowTabs()
    self.Content:HideTabID(BROWSER_TAB)
    if not C_Player:IsHero() then
        self.Content:HideTabID(SUMMARY_SPEC_TAB)
        self.Navigation.ShareButton:SetPoint("BOTTOMRIGHT", -260, 4)
    else
        self.Navigation.ShareButton:SetPoint("BOTTOMRIGHT", -380, 4)
    end
end

-- DOC: CharacterAdvancementMixin:SetupSpecTabs
-- What this does: Set a value on this UI element and update related visuals.
-- When it runs: Called when code needs to store a value and/or update the visuals.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: changes text on screen.
function CharacterAdvancementMixin:SetupSpecTabs()
    MixinAndLoadScripts(self.Content, "TabSystemMixin")
    self.Content:SetTabTemplate("CASpecTabTemplate")
    self.Content:SetTabPoint("BOTTOMLEFT", self.Content, "TOPLEFT", 12, -1)
    self.Content:SetTabWidthConstraints(124, 180)
    self.Content:SetTabSelectedSound(SOUNDKIT.CHARACTER_SHEET_TAB)
    self.Content:SetTabPadding(8, 0)
    self.Content.tabLevel = self:GetFrameLevel() + 9

    -- DOC: self.Content:UpdateTabLayout
    -- What this does: Update what is shown on screen so it matches the latest game data.
    -- When it runs: Called whenever the screen needs to be redrawn with fresh information.
    -- Inputs:
    --   - self: the UI object this function belongs to
    -- Output: Nothing (it mainly updates state and/or the UI).
    -- What it changes: changes text on screen.
    function self.Content:UpdateTabLayout() -- hack fix for to properly allocate tabs
        local lastTab
        for tabID, tab in pairs(self.tabs) do
            tab:SetFrameLevel(self.tabLevel)
            tab:UpdateWidth()
            if tab:IsShown() then
                self.tabLayout(tabID, tab, lastTab)
                lastTab = tab
            end
        end
    end

    self.Content:SetTabLayout(function(tabID, tab, lastTab)
        if tabID == SUMMARY_SPEC_TAB then
            if self.Content:GetWidth() < 801 then
                tab:ClearAndSetPoint("BOTTOMRIGHT", self.Content, "TOPRIGHT", -8+SCROLL_X_SHIFT, -1)
            else
                tab:ClearAndSetPoint("BOTTOMRIGHT", self.Content, "TOPRIGHT", -8, -1)
            end
        elseif tabID == BROWSER_TAB then
            tab:ClearAndSetPoint(unpack(self.Content.tabPoint))
        elseif not(lastTab) then
            tab:ClearAndSetPoint(unpack(self.Content.tabPoint))
        else
            tab:ClearAndSetPoint("LEFT", lastTab, "RIGHT", self.Content:GetTabPadding())
        end
    end)

    local tab
    for i = 1, NUM_SPEC_TABS do
        tab = self.Content:AddTab("Tab"..i)
        tab:SetFrameLevel(self.Content.NineSlice:GetFrameLevel()+2)
        tab:SetTextPadding(30)
    end

    tab = self.Content:AddTab("Tab"..SUMMARY_SPEC_TAB)
    tab:SetFrameLevel(self.Content.NineSlice:GetFrameLevel()+2)
    tab:SetTextPadding(30)
    tab:SetText(ACHIEVEMENT_SUMMARY_CATEGORY)
    tab:UpdateSpellCounts()

    tab = self.Content:AddTab("Tab"..BROWSER_TAB)
    tab:SetFrameLevel(self.Content.NineSlice:GetFrameLevel()+2)
    tab:SetTextPadding(30)
    tab:SetText(BROWSE)
    tab:UpdateSpellCounts(nil, "BROWSER")

    self.Content:RegisterCallback("OnTabSelected", self.OnSpecTabSelected, self)
    self.Content:SetScript("OnScrollRangeChanged", GenerateClosure(self.ContentOnScrollRangeChanged, self))

    if not C_Player:IsHero() then
        self.Content:HideTabID(SUMMARY_SPEC_TAB)
    end
    self.Content:HideTabID(BROWSER_TAB)
end 

-- DOC: CharacterAdvancementMixin:OnSpecTabSelected
-- What this does: Update text shown to the player.
-- When it runs: Runs for a UI callback named OnSpecTabSelected.
-- Inputs:
--   - self: the UI object this function belongs to
--   - tabID: an identifier (a number/string that points to a specific thing)
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: changes text on screen, uses Character Advancement API.
function CharacterAdvancementMixin:OnSpecTabSelected(tabID)
    self:SelectSpec(tabID)
end

function CharacterAdvancementMixin:SetupSideBarTabs()
    MixinAndLoadScripts(self.SideBar, "TabSystemMixin")
    self.SideBar:SetTabTemplate("TabSystemTopTabOldStyleTemplate")
    self.SideBar:SetTabPoint("BOTTOMLEFT", self.SideBar, "TOPLEFT", 8, 0)
    self.SideBar:SetTabWidthConstraints(77, 77)
    self.SideBar:SetTabSelectedSound(SOUNDKIT.UCHATSCROLLBUTTON)

    self.SideBar.tabLevel = self:GetFrameLevel() + 9
    
    local tab
    -- spell list
    tab = self.SideBar:AddTab(MY_SPELLS_TAB, self.SideBar.SpellList)
    tab:SetTooltip(MY_SPELLS_TAB_TITLE, MY_SPELLS_TAB_TOOLTIP)
    tab:SetTooltipAnchor("ANCHOR_TOP")
    tab:SetFrameLevel(self.SideBar:GetFrameLevel()+8)
    self.SideBar.SpellsTab = tab:GetTabID()

    self.SideBar.SpellList:SetGetNumResultsFunction(C_CharacterAdvancement.GetNumFilteredEntries)
    self.SideBar.SpellList:GetSelectedHighlight():SetTexture(nil)
    self.SideBar.SpellList:SetTemplate("SpellListItemTemplate")

    local header = self.SideBar.SpellList.Header
    header.NineSlice.Background:SetAtlas("garrlanding_rewardslistbg")

    local canChoosePrimaryStat = self:CanShowPrimaryStat()

    if canChoosePrimaryStat then
        self:ShowPrimaryStatPicker()
    else
        self:HidePrimaryStatPicker()
    end

    -- spec list
    tab = self.SideBar:AddTab(MY_SPECS_TAB, self.SideBar.SpecList)
    tab:SetTooltip(MY_SPECS_TAB_TITLE, MY_SPECS_TAB_TOOLTIP)
    tab:SetTooltipAnchor("ANCHOR_TOP")
    tab:SetFrameLevel(self.SideBar.SpecList.NineSlice:GetFrameLevel()+2)
    self.SideBar.SpecTab = tab:GetTabID()

    self.SideBar.SpecList:SetGetNumResultsFunction(SpecializationUtil.GetNumSpecializations)
    self.SideBar.SpecList:GetSelectedHighlight():SetTexture(nil)
    self.SideBar.SpecList:SetTemplate("SpecListItemTemplate")
    self.SideBar.SpecList.IconSelector:SetFrameLevel(self:GetFrameLevel()+60)
    self.SideBar.SpecList.SelectFrame:SetFrameLevel(self:GetFrameLevel()+60)

    -- loadouts
    tab = self.SideBar:AddTab(MY_LOADOUTS_TAB, self.SideBar.LoadoutList)
    tab:SetTooltip(MY_LOADOUTS_TAB_TITLE, MY_LOADOUTS_TAB_TOOLTIP)
    tab:SetTooltipAnchor("ANCHOR_TOP")
    self.SideBar.LoadoutTab = tab:GetTabID()

    self.SideBar.LoadoutList:SetGetNumResultsFunction(function() return TalentLoadoutUtil.GetNumLoadouts() + 1 end)
    self.SideBar.LoadoutList:GetSelectedHighlight():SetTexture(nil)
    self.SideBar.LoadoutList:SetTemplate("LoadoutListItemTemplate")
    TalentLoadoutUtil:RegisterCallback("OWNED_LOADOUTS_CHANGED", function()
        self.SideBar.LoadoutList:RefreshScrollFrame()
    end)
    TalentLoadoutUtil:RegisterCallback("ACTIVE_LOADOUT_CHANGED", function()
        self.SideBar.LoadoutList:RefreshScrollFrame()
    end)

    local footer = self.SideBar.SpellList.Footer
    footer.Background:SetAtlas("professions-specializations-background-footer")
    footer.RarityFlyout:SetFrameLevel(footer:GetFrameLevel()+20)
end

-- DOC: CharacterAdvancementMixin:CanShowPrimaryStat
-- What this does: Update text shown to the player.
-- When it runs: Called when other code needs a yes/no or a piece of information.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: A value used by other code (C_Player:IsHero() and not(C_GameMode:IsG...).
-- What it changes: changes text on screen, uses Character Advancement API.
function CharacterAdvancementMixin:CanShowPrimaryStat()
    return C_Player:IsHero() and not(C_GameMode:IsGameModeActive(Enum.GameMode.BuildDraft))
end

function CharacterAdvancementMixin:RefreshPrimaryStats() -- primary stat can be updated from outside. Load actual known info on:Refresh()
    local canChoosePrimaryStat = self:CanShowPrimaryStat()
    local header = self.SideBar.SpellList.Header

    if not canChoosePrimaryStat then
        self:HidePrimaryStatPicker()
        return
    end

    if header.IsCompact then
        self:ShowPrimaryStatPicker()
    end

    for i = 1, 4 do
        local button = header["PrimaryStat"..i]
        if canChoosePrimaryStat then
            button:SetEntry(C_CharacterAdvancement.GetEntryByInternalID(C_PrimaryStat:GetInternalID(i)))
        end
    end
end

-- DOC: CharacterAdvancementMixin:RefreshCurrencies
-- What this does: Update what is shown on screen so it matches the latest game data.
-- When it runs: Called whenever the screen needs to be redrawn with fresh information.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, changes text on screen.
function CharacterAdvancementMixin:RefreshCurrencies()
    local aeCount = GetItemCount(ItemData.ABILITY_ESSENCE)
    local teCount = GetItemCount(ItemData.TALENT_ESSENCE)

    aeCount = (aeCount == 0) and DISABLED_FONT_COLOR:WrapText(aeCount) or ITEM_QUALITY_COLORS[3]:WrapText(aeCount)
    teCount = (teCount == 0) and DISABLED_FONT_COLOR:WrapText(teCount) or ITEM_QUALITY_COLORS[4]:WrapText(teCount)

    if C_Player:IsDefaultClass() then
        self.Content.ScrollChild.Spells.Total:SetText("")
    else
        self.Content.ScrollChild.Spells.Total:SetText(string.format(ABILITY_ESSENCE_TOTAL, aeCount))
    end
    self.Content.ScrollChild.Talents.Total:SetText(string.format(TALENT_ESSENCE_TOTAL, teCount))
end

-- DOC: CharacterAdvancementMixin:Refresh
-- What this does: Update what is shown on screen so it matches the latest game data.
-- When it runs: Called whenever the screen needs to be redrawn with fresh information.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces.
function CharacterAdvancementMixin:Refresh()
    self:RefreshPrimaryStats()
    -- check for draft
    self.Navigation.DraftButton:SetShown(DraftUtil.HasAnyPicks())

    -- Update Currency Displays
    local talentBar = self.Content.Footer.TalentCurrencyBar
    local spellBar = self.Content.Footer.SpellCurrencyBar
    local rarityBar = self.SideBar.SpellList.Footer.RarityCurrencyBar

    spellBar:ClearCurrencies()
    if not C_Player:IsDefaultClass() then
        spellBar:AddCurrency(ItemData.ABILITY_ESSENCE, true)
    end
    spellBar:AddCurrency(ItemData.MARK_OF_ASCENSION)

    talentBar:ClearCurrencies()
    talentBar:AddCurrency(ItemData.TALENT_ESSENCE, true)

    rarityBar:ClearCurrencies()
    
    -- wildcard currency
    if self:IsWildCardMode() then
        local specID = SpecializationUtil.GetActiveSpecialization()
        rarityBar:AddToken(TokenUtil.GetScrollOfFortuneForSpec(specID))
        rarityBar:AddToken(TokenUtil.GetScrollOfFortuneTalentsForSpec(specID))

        if C_Config.GetBoolConfig("CONFIG_WILDCARD_QUICK_ROLLING_ENABLED") then
            self.Content.WCRapidRollButton:Show()
            local enabled, reason = C_Wildcard.CanUseRapidRolling()
            if enabled then
                self.Content.WCRapidRollButton:Enable()
                self.Content.WCRapidRollButton.tooltipExtra = nil
            else
                self.Content.WCRapidRollButton:Disable()
                self.Content.WCRapidRollButton.tooltipExtra = reason and (_G[reason] or reason) or RAPID_ROLL_UNAVAILABLE:format(GetMaxLevel())
            end
        else
            self.Content.WCRapidRollButton:Hide()
        end
    elseif self:IsDraftMode() then
        rarityBar:AddQuality(Enum.SpellQuality.Uncommon)
        rarityBar:AddQuality(Enum.SpellQuality.Rare)
        rarityBar:AddQuality(Enum.SpellQuality.Epic)
        rarityBar:AddQuality(Enum.SpellQuality.Legendary)
        talentBar:AddCurrency(ItemData.SCROLL_OF_UNLEARNING)
    else
        talentBar:AddCurrency(ItemData.SCROLL_OF_UNLEARNING)
    end

    spellBar:Update()
    talentBar:Update()
    rarityBar:Update()
    
    -- Update Spell List Footer
    local footer = self.SideBar.SpellList.Footer
    if not C_Player:IsHero() or C_GameMode:IsGameModeActive(Enum.GameMode.Draft, Enum.GameMode.WildCard) then
        footer.FlyoutButton:Hide()
        self:HideRarityFlyout()
        
        footer.RarityCurrencyBar:Show()
        footer.RarityCurrencyBar:Update()
    else
        footer.FlyoutButton:Show()
        footer.RarityCurrencyBar:Hide()
    end
    
    -- Update Unlearn Buttons
    local canReset, reason = C_CharacterAdvancement.CanUnlearnAllTalents()
    self.Content.Footer.ResetTalentsButton:SetEnabled(canReset)
    if canReset then
        self.Content.Footer.ResetTalentsButton.tooltipExtra = nil
    else
        self.Content.Footer.ResetTalentsButton.tooltipExtra = CA_CANNOT_PURGE_TALENTS_S:format(_G[reason] or reason)
    end

    if C_Player:IsHero() then
        canReset, reason = C_CharacterAdvancement.CanUnlearnAllSpells()
        self.Content.Footer.ResetSpellsButton:SetEnabled(canReset)
        if canReset then
            self.Content.Footer.ResetSpellsButton.tooltipExtra = nil
        else
            self.Content.Footer.ResetSpellsButton.tooltipExtra = CA_CANNOT_PURGE_ABILITIES_S:format(_G[reason] or reason)
        end
    end
    
    -- Update Spell & Talent Counts
    for _, button in pairs(self.ClassButtons) do
        button:UpdateSpellCounts()
    end

    local classFile = C_CVar.Get("caLastClass")
    local class = CharacterAdvancementUtil.GetClassDBCByFile(classFile)
    
    if class then
        for _, tab in pairs(self.Content.tabs) do
            tab.classFile = classFile
            local spec = CHARACTER_ADVANCEMENT_CLASS_SPEC_ORDER[classFile][tab:GetTabID()]
            tab.spec = spec
            spec = spec and CharacterAdvancementUtil.GetSpecDBCByFile(spec)
            if spec then
                tab:UpdateSpellCounts(class, spec)
            end
        end

        if CA_USE_GATES_DEBUG then
            local specFile = C_CVar.Get("caLastSpec")
            if specFile and specFile ~= "SUMMARY" then
                self:RefreshGateInfo(class, CharacterAdvancementUtil.GetSpecDBCByFile(specFile))
                self:RefreshGates()
            end
        end
    end

    self.Content:GetTabByID(SUMMARY_SPEC_TAB):UpdateSpellCounts()
    
    -- check pet talents
    if HasPetUI() and PetCanBeAbandoned() and (GetNumTalents(1, false, true) > 0) and (C_CVar.Get("caLastSpec") ~= "BROWSER") then
        self.Navigation.PetTalents:Show()
        local unspentPoints = GetUnspentTalentPoints(false, true)
        local hasUnspentPoints = unspentPoints and unspentPoints > 0
        if hasUnspentPoints then
            self.Navigation.PetTalents.Glow:Show()
            self.Navigation.PetTalents.Glow.Animation:Play()
            self.Navigation.PetTalents.UnspentPoints:SetCount(unspentPoints)
            self.Navigation.PetTalents.UnspentPoints:Show()
        else
            self.Navigation.PetTalents.Glow:Hide()
            self.Navigation.PetTalents.Glow.Animation:Stop()
            self.Navigation.PetTalents.UnspentPoints:Hide()
        end
    else
        self.Navigation.PetTalents:Hide()
    end
end

-- DOC: CharacterAdvancementMixin:ForceUpdateRarityFlyout
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, uses Character Advancement API.
function CharacterAdvancementMixin:ForceUpdateRarityFlyout()
    local flyout = self.SideBar.SpellList.Footer.RarityFlyout
    flyout.Uncommon:Update()
    flyout.Rare:Update()
    flyout.Epic:Update()
    flyout.Legendary:Update()
end

-------------------------------------------------------------------------------
--                                   Gates --
-------------------------------------------------------------------------------
-- DOC: CharacterAdvancementMixin:RefreshGates
-- What this does: Update what is shown on screen so it matches the latest game data.
-- When it runs: Called whenever the screen needs to be redrawn with fresh information.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, uses Character Advancement API.
function CharacterAdvancementMixin:RefreshGates()
    self.GatePool:ReleaseAll()
    self.GatePoolGlobal:ReleaseAll()

    -- local lock
    for i, gateInfo in ipairs(CA_TIER_GATES) do
        if not(gateInfo.isMetTree) and gateInfo.topLeftNode and gateInfo.isMetGlobal then -- don't show lock below global lock
            local gate = self.GatePool:Acquire()
            gate:Init(gateInfo)
            gate:SetPoint("RIGHT", gateInfo.topLeftNode, "LEFT", 0, 0)
            gate:Show()
            break
        end
    end

    -- global lock 
    for i, gateInfo in ipairs(CA_TIER_GATES) do
        if not(gateInfo.isMetGlobal) and gateInfo.topLeftNode then -- show lock at first global requirement
            local gate = self.GatePoolGlobal:Acquire()
            gate:Init(gateInfo)
            gate:ClearAndSetPoint("TOP", self.Content.ScrollChild.Talents, "TOP", 0, -(28 + i * 44))
            gate:Show()
            break
        end
    end
end

-- TODO: Work with build creator?
-- DOC: CharacterAdvancementMixin:RefreshGateInfo
-- What this does: Update what is shown on screen so it matches the latest game data.
-- When it runs: Called whenever the screen needs to be redrawn with fresh information.
-- Inputs:
--   - self: the UI object this function belongs to
--   - class: a piece of information passed in by the caller
--   - spec: information about a specialization (spec) choice
--   - hardReset: a piece of information passed in by the caller
-- Output: A value used by other code (gate).
-- What it changes: shows/hides UI pieces, uses Character Advancement API.
function CharacterAdvancementMixin:RefreshGateInfo(class, spec, hardReset)
    local totalTESpent = C_CharacterAdvancement.GetLearnedTE()
    local treeTESpent = 0

    for i, entry in ipairs(C_CharacterAdvancement.GetTalentsByClass(class, spec, Const.CharacterAdvancement.IncludeMasteries)) do
        local rank = C_CharacterAdvancement.GetTalentRankByID(entry.ID)
        if rank and rank > 0 then
            treeTESpent = treeTESpent + (entry.TECost*rank)
        end
    end

    for _, gateInfo in pairs(CA_TIER_GATES) do
        if hardReset then
            gateInfo.topLeftNode = nil -- to be later filled in CharacterAdvancementMixin:SetTalents
        end

        local diffGlobal = gateInfo.spentGlobalRequired - totalTESpent
        local diffTree = gateInfo.spentTreeRequired - treeTESpent

        gateInfo.requiresGlobal = diffGlobal > 0 and diffGlobal or 0
        gateInfo.requiresTree = diffTree > 0 and diffTree or 0

        gateInfo.isMetTree = diffTree <= 0
        gateInfo.isMetGlobal = diffGlobal <= 0

        --gateInfo.isMet = (diffTree <= 0) and (diffGlobal <= 0)
    end
end

-- DOC: CharacterAdvancementMixin:DefineGatesForButton
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
--   - row: a piece of information passed in by the caller
-- Output: A value used by other code (gate).
-- What it changes: shows/hides UI pieces, changes text on screen.
function CharacterAdvancementMixin:DefineGatesForButton(row)
    local gate = nil

    for _, gateInfo in ipairs(CA_TIER_GATES) do
        if gateInfo.tier <= row then
            gate = gateInfo
        else
            break
        end
    end

    return gate
end

-- DOC: CharacterAdvancementMixin:FullUpdate
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
--   - dontSearch: the filter/search text used to narrow results
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, changes text on screen.
function CharacterAdvancementMixin:FullUpdate(dontSearch)
    self:Refresh()
    self:LockTalentsFrameCheck()

    local spellHeight, talentHeight 
    local classFile = C_CVar.Get("caLastClass")

    if C_CVar.Get("caLastSpec") == "SUMMARY" then
        self.Content.ScrollChild:Show()
        self.Content.AbilityBrowser:Hide()
        self.Content.SpellTagFrame:Hide()
        self.Content.BrowserArtwork:Hide()
        if classFile == "BROWSER" then
            self:ShowBrowserTabs()
        else
            self:ShowClassTabs()
        end
        spellHeight = self:SetSpellSummary()
        talentHeight = self:SetTalentSummary()
        self.Content.Background:SetAtlas("ca-background")
        self.Content.SpellsOverlay:SetTexture(nil)
    elseif classFile == "BROWSER" then
        self:ShowBrowserTabs()
        self.Content.ScrollChild:Hide()
        self.Content.AbilityBrowser:Show()
        self.Content.BrowserArtwork:Show()
        self.Content.Background:SetAtlas("ca-background-browser")
        self.Content.SpellsOverlay:SetTexture(nil)
        self:BrowserSearch()
    else
        self:ShowClassTabs()
        self.Content.ScrollChild:Show()
        self.Content.BrowserArtwork:Hide()
        self.Content.AbilityBrowser:Hide()
        self.Content.SpellTagFrame:Hide()

        local specFile = C_CVar.Get("caLastSpec")
        local class = CharacterAdvancementUtil.GetClassDBCByFile(classFile)
        local spec = CharacterAdvancementUtil.GetSpecDBCByFile(specFile)

        local atlas = "ca-background-"..classFile
        
        if AtlasUtil:AtlasExists(atlas) then
            self.Content.Background:SetAtlas(atlas)
        end

        self.Content.SpellsOverlay:SetTexture("Interface\\Pictures\\artifactbook-"..classFile.."-cover")

        spellHeight = self:SetSpells(class, spec)
        talentHeight = self:SetTalents(class, spec)
    end
    
    if not classFile or classFile ~= "BROWSER" then
        self.Content.ScrollChild:SetHeight(math.max(spellHeight, talentHeight))
    end

    self:ContentOnScrollRangeChanged()

    if self.Content:GetVerticalScrollRange() < self.Content:GetVerticalScroll() then
        self.Content:SetVerticalScroll(self.Content:GetVerticalScrollRange())
    end

    self.LocateID = nil
    if not dontSearch then
        self:Search()
    end
end

-- DOC: CharacterAdvancementMixin:SetSpells
-- What this does: Set a value on this UI element and update related visuals.
-- When it runs: Called when code needs to store a value and/or update the visuals.
-- Inputs:
--   - self: the UI object this function belongs to
--   - class: a piece of information passed in by the caller
--   - spec: information about a specialization (spec) choice
-- Output: A value used by other code (height).
-- What it changes: shows/hides UI pieces, uses Character Advancement API.
function CharacterAdvancementMixin:SetSpells(class, spec)
    self.SpellPool:ReleaseAll()
    local height = 536
    local button, x, y
    for i, entry in ipairs(C_CharacterAdvancement.GetSpellsByClass(class, spec, Const.CharacterAdvancement.IncludeMasteries)) do
        button = self.SpellPool:Acquire()
        button:SetEntry(entry)
        x = 22 + ((i - 1) % 3) * 142
        y = 42 + (math.floor((i - 1) / 3) * 44)
        button:SetPoint("TOPLEFT", self.Content.ScrollChild.Spells, "TOPLEFT", x, -y)
        button:Show()

        height = math.max(height, y + button:GetHeight())

        if entry.ID == self.LocateID then
            button:ShowLocation()
            self.LocateID = nil
        end
    end
    
    return height
end

-- DOC: CharacterAdvancementMixin:SetSpellSummary
-- What this does: Set a value on this UI element and update related visuals.
-- When it runs: Called when code needs to store a value and/or update the visuals.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: A value used by other code (height).
-- What it changes: shows/hides UI pieces, uses Character Advancement API.
function CharacterAdvancementMixin:SetSpellSummary()
    self.SpellPool:ReleaseAll()
    local height = 536
    local button, x, y
    for i, entry in ipairs(C_CharacterAdvancement.GetKnownSpellEntries()) do
        button = self.SpellPool:Acquire()
        button:SetEntry(entry)
        x = 22 + ((i - 1) % 3) * 142
        y = 42 + (math.floor((i - 1) / 3) * 44)
        button:SetPoint("TOPLEFT", self.Content.ScrollChild.Spells, "TOPLEFT", x, -y)
        button:Show()

        height = math.max(height, y + button:GetHeight())
    end

    return height
end

-- DOC: CharacterAdvancementMixin:DefineGateTopLeftNode
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
--   - gate: a piece of information passed in by the caller
--   - entry: a piece of information passed in by the caller
--   - button: the button that triggered this (the thing you clicked)
-- Output: Nothing (nil).
-- What it changes: shows/hides UI pieces, uses Character Advancement API.
function CharacterAdvancementMixin:DefineGateTopLeftNode(gate, entry, button)
    if not (gate) then 
        return
    end

    if not gate.topLeftNode or gate.needsUpdate then
        gate.topLeftNode = button
    else
        if gate.topLeftNode.entry and (gate.topLeftNode.entry.Column > entry.Column) then
            gate.topLeftNode = button
        end
    end
end

-- DOC: CharacterAdvancementMixin:SetTalents
-- What this does: Set a value on this UI element and update related visuals.
-- When it runs: Called when code needs to store a value and/or update the visuals.
-- Inputs:
--   - self: the UI object this function belongs to
--   - class: a piece of information passed in by the caller
--   - spec: information about a specialization (spec) choice
-- Output: A value used by other code (height).
-- What it changes: shows/hides UI pieces, uses Character Advancement API.
function CharacterAdvancementMixin:SetTalents(class, spec)
    self.TalentPool:ReleaseAll()

    if CA_USE_GATES_DEBUG then
        self:RefreshGateInfo(class, spec, true) -- we need to scan it before to button properly update on SetEntry
    end

    local height = 536
    local button, column, row, x, y
    for i, entry in ipairs(C_CharacterAdvancement.GetTalentsByClass(class, spec, Const.CharacterAdvancement.IncludeMasteries)) do
        button = self.TalentPool:Acquire()

        if CA_USE_GATES_DEBUG then
            -- work with gates
            local gate = self:DefineGatesForButton(entry.Row+1)

            self:DefineGateTopLeftNode(gate, entry, button)

            button.gate = gate
        else
            button.gate = nil
        end

        button:SetEntry(entry)
        column = entry.Column - 1
        row = entry.Row
        x = -102 + column * 68
        y = 42 + row * 44
        button:SetPoint("TOP", self.Content.ScrollChild.Talents, "TOP", x, -y)
        button:Show()

        if entry.ID == self.LocateID then
            button:ShowLocation()
            self.LocateID = nil
        end
        height = math.max(height, y + button:GetHeight())
    end

    if CA_USE_GATES_DEBUG then
        self:RefreshGates()
    end
    
    return height
end 

-- DOC: CharacterAdvancementMixin:SetTalentSummary
-- What this does: Set a value on this UI element and update related visuals.
-- When it runs: Called when code needs to store a value and/or update the visuals.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: A value used by other code (height).
-- What it changes: shows/hides UI pieces, uses Character Advancement API.
function CharacterAdvancementMixin:SetTalentSummary()
    self.GatePool:ReleaseAll()
    self.GatePoolGlobal:ReleaseAll()
    self.TalentPool:ReleaseAll()
    local height = 536
    
    local column = 0
    local row = 0
    local button, x, y
    for i, entry in ipairs(C_CharacterAdvancement.GetKnownTalentEntries()) do
        button = self.TalentPool:Acquire()
        button:SetEntry(entry)
        column = (i - 1) % 4
        row = math.floor((i - 1) / 4)
        x = -102 + column * 68
        y = 42 + row * 44
        button:SetPoint("TOP", self.Content.ScrollChild.Talents, "TOP", x, -y)
        button:Show()
        height = math.max(height, y + button:GetHeight())
    end

    return height
end

-- DOC: CharacterAdvancementMixin:InitializeSpellDropDown
-- What this does: Call into the Character Advancement system (server/game API) and update the UI with the result.
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
--   - dropdown: a piece of information passed in by the caller
--   - level: a character level number
--   - menuList: a piece of information passed in by the caller
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: uses Character Advancement API.
function CharacterAdvancementMixin:InitializeSpellDropDown(dropdown, level, menuList)
    if not dropdown.targetEntry then return end
    
    -- spell name + icon
    local info = UIDropDownMenu_CreateInfo()
    info.notCheckable = true
    info.isTitle = true
    info.text = dropdown.targetEntry.Name
    info.icon = "Interface\\Icons\\"..dropdown.targetEntry.Icon
    UIDropDownMenu_AddButton(info, level)

    if BuildCreatorUtil.IsPickingSpells() then
        -- build editor mode
        -- get next talent spell if necessary
        local nextSpellID
        if C_CharacterAdvancement.IsTalentSpellID(dropdown.spellID) then
            nextSpellID = BuildCreatorUtil.GetNextTalentSpellID(dropdown.spellID)
        else
            nextSpellID = dropdown.spellID
        end

        -- if next talent or current spell isnt known then show add button
        if not C_BuildEditor.DoesBuildHaveSpellID(nextSpellID) then
            -- Add
            info = UIDropDownMenu_CreateInfo()
            info.notCheckable = true
            info.text = ADD
            -- DOC: info.func
            -- What this does: Do a specific piece of work related to 'func'.
            -- When it runs: Called by other code when needed.
            -- Inputs: none
            -- Output: Nothing (it mainly updates state and/or the UI).
            -- What it changes: updates UI/state.
            info.func = function()
                local spellInfo = C_BuildEditor.GetSpellByID(dropdown.spellID) or BuildCreatorUtil.CreateSpellInfo(nextSpellID, BuildCreatorUtil.GetPickLevel())
                spellInfo.Spell = nextSpellID
                spellInfo.Level = BuildCreatorUtil.GetPickLevel()
                C_BuildEditor.AddSpell(spellInfo)
                BuildCreatorUtil.RefreshFinishPickingPopup()
                BuildCreatorUtil.EditorSpellsChanged()
            end
            UIDropDownMenu_AddButton(info, level)

            -- Add Core
            info = UIDropDownMenu_CreateInfo()
            info.notCheckable = true
            info.text = ADD_CORE
            -- DOC: info.func
            -- What this does: Do a specific piece of work related to 'func'.
            -- When it runs: Called by other code when needed.
            -- Inputs: none
            -- Output: Nothing (it mainly updates state and/or the UI).
            -- What it changes: updates UI/state.
            info.func = function()
                local spellInfo = C_BuildEditor.GetSpellByID(dropdown.spellID) or BuildCreatorUtil.CreateSpellInfo(nextSpellID, BuildCreatorUtil.GetPickLevel())
                spellInfo.Spell = nextSpellID
                spellInfo.Level = BuildCreatorUtil.GetPickLevel()
                spellInfo.IsCoreAbility = true
                C_BuildEditor.AddSpell(spellInfo)
                BuildCreatorUtil.RefreshFinishPickingPopup()
                BuildCreatorUtil.EditorSpellsChanged()
            end
            UIDropDownMenu_AddButton(info, level)

            -- Add Optimal
            info = UIDropDownMenu_CreateInfo()
            info.notCheckable = true
            info.text = ADD_OPTIMAL
            -- DOC: info.func
            -- What this does: Do a specific piece of work related to 'func'.
            -- When it runs: Called by other code when needed.
            -- Inputs: none
            -- Output: Nothing (it mainly updates state and/or the UI).
            -- What it changes: updates UI/state.
            info.func = function()
                local spellInfo = C_BuildEditor.GetSpellByID(dropdown.spellID) or BuildCreatorUtil.CreateSpellInfo(nextSpellID, BuildCreatorUtil.GetPickLevel())
                spellInfo.Spell = nextSpellID
                spellInfo.Level = BuildCreatorUtil.GetPickLevel()
                spellInfo.IsOptimalAbility = true
                C_BuildEditor.AddSpell(spellInfo)
                BuildCreatorUtil.RefreshFinishPickingPopup()
                BuildCreatorUtil.EditorSpellsChanged()
            end
            UIDropDownMenu_AddButton(info, level)

            -- Add Empowering
            info = UIDropDownMenu_CreateInfo()
            info.notCheckable = true
            info.text = ADD_EMPOWERING
            -- DOC: info.func
            -- What this does: Call into the Character Advancement system (server/game API) and update the UI with the result.
            -- When it runs: Called by other code when needed.
            -- Inputs: none
            -- Output: Nothing (it mainly updates state and/or the UI).
            -- What it changes: uses Character Advancement API.
            info.func = function()
                local spellInfo = C_BuildEditor.GetSpellByID(dropdown.spellID) or BuildCreatorUtil.CreateSpellInfo(nextSpellID, BuildCreatorUtil.GetPickLevel())
                spellInfo.Spell = nextSpellID
                spellInfo.Level = BuildCreatorUtil.GetPickLevel()
                spellInfo.IsEmpoweringAbility = true
                C_BuildEditor.AddSpell(spellInfo)
                BuildCreatorUtil.RefreshFinishPickingPopup()
                BuildCreatorUtil.EditorSpellsChanged()
            end
            UIDropDownMenu_AddButton(info, level)

            -- Add Synergistic
            info = UIDropDownMenu_CreateInfo()
            info.notCheckable = true
            info.text = ADD_SYNERGISTIC
            -- DOC: info.func
            -- What this does: Call into the Character Advancement system (server/game API) and update the UI with the result.
            -- When it runs: Called by other code when needed.
            -- Inputs: none
            -- Output: Nothing (it mainly updates state and/or the UI).
            -- What it changes: uses Character Advancement API.
            info.func = function()
                local spellInfo = C_BuildEditor.GetSpellByID(dropdown.spellID) or BuildCreatorUtil.CreateSpellInfo(nextSpellID, BuildCreatorUtil.GetPickLevel())
                spellInfo.Spell = nextSpellID
                spellInfo.Level = BuildCreatorUtil.GetPickLevel()
                spellInfo.IsSynergisticAbility = true
                C_BuildEditor.AddSpell(spellInfo)
                BuildCreatorUtil.RefreshFinishPickingPopup()
                BuildCreatorUtil.EditorSpellsChanged()
            end
            UIDropDownMenu_AddButton(info, level)
        end
        
        -- if build has this spell we can remove it
        if C_BuildEditor.DoesBuildHaveSpellID(dropdown.spellID) then
            -- Remove
            info = UIDropDownMenu_CreateInfo()
            info.notCheckable = true
            info.text = REMOVE
            -- DOC: info.func
            -- What this does: Call into the Character Advancement system (server/game API) and update the UI with the result.
            -- When it runs: Called by other code when needed.
            -- Inputs: none
            -- Output: Nothing (it mainly updates state and/or the UI).
            -- What it changes: uses Character Advancement API.
            info.func = function()
                C_BuildEditor.RemoveSpell(dropdown.spellID)
                BuildCreatorUtil.RefreshFinishPickingPopup()
                BuildCreatorUtil.EditorSpellsChanged()
            end
            UIDropDownMenu_AddButton(info, level)
        end

    else -- regular dropdown
        -- learn
        info = UIDropDownMenu_CreateInfo()
        info.notCheckable = true
        info.text = LEARN
        info.disabled = not C_CharacterAdvancement.CanAddByEntryID(dropdown.targetEntry.ID, 1)
        -- DOC: info.func
        -- What this does: Call into the Character Advancement system (server/game API) and update the UI with the result.
        -- When it runs: Called by other code when needed.
        -- Inputs: none
        -- Output: Nothing (it mainly updates state and/or the UI).
        -- What it changes: uses Character Advancement API.
        info.func = function()
            CharacterAdvancementUtil.ConfirmOrLearnID(dropdown.targetEntry.ID)
        end
        UIDropDownMenu_AddButton(info, level)
        
        if C_AccountInfo.IsGM() then
            info = UIDropDownMenu_CreateInfo()
            info.notCheckable = true
            info.text = "(GM) "..LEARN
            info.disabled = C_CharacterAdvancement.IsKnownSpellID(dropdown.targetEntry.Spells[#dropdown.targetEntry.Spells])
            -- DOC: info.func
            -- What this does: Call into the Character Advancement system (server/game API) and update the UI with the result.
            -- When it runs: Called by other code when needed.
            -- Inputs: none
            -- Output: Nothing (it mainly updates state and/or the UI).
            -- What it changes: uses Character Advancement API.
            info.func = function()
                SendChatMessage(format(".ca2 player addentry %s %s", UnitName("player"), dropdown.targetEntry.ID))
            end
            UIDropDownMenu_AddButton(info, level)

            info = UIDropDownMenu_CreateInfo()
            info.notCheckable = true
            info.text = "(GM) "..UNLEARN
            info.disabled = not C_CharacterAdvancement.IsKnownSpellID(dropdown.spellID)
            -- DOC: info.func
            -- What this does: Call into the Character Advancement system (server/game API) and update the UI with the result.
            -- When it runs: Called by other code when needed.
            -- Inputs: none
            -- Output: Nothing (it mainly updates state and/or the UI).
            -- What it changes: uses Character Advancement API.
            info.func = function()
                SendChatMessage(format(".ca2 player removeentry %s %s", UnitName("player"), dropdown.targetEntry.ID))
            end
            UIDropDownMenu_AddButton(info, level)
        end

        if C_CharacterAdvancement.IsKnownID(dropdown.targetEntry.ID) and C_GameMode:IsGameModeActive(Enum.GameMode.WildCard) then
            -- is known and in wild card
            if C_CharacterAdvancement.IsLockedID(dropdown.targetEntry.ID) then
                -- is locked
                -- unlock
                info = UIDropDownMenu_CreateInfo()
                info.notCheckable = true
                info.text = UNLOCK_SPELL
                -- DOC: info.func
                -- What this does: Call into the Character Advancement system (server/game API) and update the UI with the result.
                -- When it runs: Called by other code when needed.
                -- Inputs: none
                -- Output: Nothing (it mainly updates state and/or the UI).
                -- What it changes: uses Character Advancement API.
                info.func = function()
                    C_CharacterAdvancement.UnlockID(dropdown.targetEntry.ID)
                end
                UIDropDownMenu_AddButton(info, level)
            else
                -- is not locked
                -- lock
                info = UIDropDownMenu_CreateInfo()
                info.notCheckable = true
                info.text = LOCK_SPELL
                -- DOC: info.func
                -- What this does: Call into the Character Advancement system (server/game API) and update the UI with the result.
                -- When it runs: Called by other code when needed.
                -- Inputs: none
                -- Output: Nothing (it mainly updates state and/or the UI).
                -- What it changes: uses Character Advancement API.
                info.func = function()
                    C_CharacterAdvancement.LockID(dropdown.targetEntry.ID)
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end
    end

    local lastClass = C_CVar.Get("caLastClass")

    if string.isNilOrEmpty(lastClass) or (lastClass ~= "BROWSER") then
        -- search
        info = UIDropDownMenu_CreateInfo()
        info.notCheckable = true
        info.text = SEARCH
        -- DOC: info.func
        -- What this does: Call into the Character Advancement system (server/game API) and update the UI with the result.
        -- When it runs: Called by other code when needed.
        -- Inputs: none
        -- Output: Nothing (it mainly updates state and/or the UI).
        -- What it changes: uses Character Advancement API.
        info.func = function()
            self:SetSearch(dropdown.targetEntry.Name)
        end
        UIDropDownMenu_AddButton(info, level)
    end
    
    -- unlearn
    info = UIDropDownMenu_CreateInfo()
    info.notCheckable = true
    info.text = UNLEARN
    info.disabled = not C_CharacterAdvancement.CanRemoveByEntryID(dropdown.targetEntry.ID)
    -- DOC: info.func
    -- What this does: Call into the Character Advancement system (server/game API) and update the UI with the result.
    -- When it runs: Called by other code when needed.
    -- Inputs: none
    -- Output: Nothing (it mainly updates state and/or the UI).
    -- What it changes: uses Character Advancement API.
    info.func = function()
        CharacterAdvancementUtil.ConfirmOrUnlearnID(dropdown.targetEntry.ID)
    end
    UIDropDownMenu_AddButton(info, level)

    if C_CVar.Get("caLastSpec") == "BROWSER" then
        -- "suggestion override"
        info = UIDropDownMenu_CreateInfo()
        info.notCheckable = true

        if C_CharacterAdvancement.IsSuggestionContextOverride(dropdown.targetEntry.ID) then
            info.text = CA_BROWSER_REMOVE_SUGGESTION_OVERRIDE or "Remove suggestion override"
            -- DOC: info.func
            -- What this does: Call into the Character Advancement system (server/game API) and update the UI with the result.
            -- When it runs: Called by other code when needed.
            -- Inputs: none
            -- Output: Nothing (it mainly updates state and/or the UI).
            -- What it changes: uses Character Advancement API.
            info.func = function()
                C_CharacterAdvancement.RemoveSuggestionContextOverride(dropdown.targetEntry.ID)
            end
        else
            info.text = CA_BROWSER_ADD_SUGGESTION_OVERRIDE or "Add suggestion override"
            info.func = function()
                C_CharacterAdvancement.AddSuggestionContextOverride(dropdown.targetEntry.ID)
            end
        end

        UIDropDownMenu_AddButton(info, level)

        -- "clear suggestions override"
        if C_CharacterAdvancement.HasAnySuggestionContextOverrides() then
            info = UIDropDownMenu_CreateInfo()
            info.notCheckable = true
            info.text = CA_CLEAR_ALL_SUGGESTION_OVERRIDES or "Clear all suggestion overrides"
            -- DOC: info.func
            -- What this does: Show part of the UI (or switch which panel is visible).
            -- When it runs: Called by other code when needed.
            -- Inputs: none
            -- Output: Nothing (it mainly updates state and/or the UI).
            -- What it changes: shows/hides UI pieces, uses Character Advancement API.
            info.func = function()
                C_CharacterAdvancement.ClearSuggestionContextOverrides()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end
    
    -- cancel
    info = UIDropDownMenu_CreateInfo()
    info.notCheckable = true
    info.text = CANCEL
    UIDropDownMenu_AddButton(info, level)
    
end

-- DOC: CharacterAdvancementMixin:ShowSpellDropDownMenu
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
--   - spellButton: information about a spell (often a spell ID number)
--   - relativeRegion: a piece of information passed in by the caller
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces.
function CharacterAdvancementMixin:ShowSpellDropDownMenu(spellButton, relativeRegion)
    self.SpellDropDownMenu.targetEntry = spellButton.entry
    self.SpellDropDownMenu.spellID = spellButton.spellID
    if not spellButton.entry then return end
    relativeRegion = relativeRegion or spellButton
    ToggleDropDownMenu(1, nil, self.SpellDropDownMenu, relativeRegion, 0, 0)
end 

-- DOC: CharacterAdvancementMixin:PlayAnimationForToken
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
--   - tokenType: a piece of information passed in by the caller
--   - specID: an identifier (a number/string that points to a specific thing)
--   - count: a piece of information passed in by the caller
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces.
function CharacterAdvancementMixin:PlayAnimationForToken(tokenType, specID, count)
    if (SpecializationUtil.GetActiveSpecialization() ~= specID) then
        self.SideBar:SelectTabID(self.SideBar.SpecTab)
        self.SideBar.SpellList.Footer.RarityCurrencyBar:StopCountAnimation()
    end

    if self.SideBar:GetCurrentTabID() == self.SideBar.SpecTab then
        self.SideBar.SpecList.animatedToken = {tokenType = tokenType, count = count}
    else
        self.SideBar.SpellList.Footer.RarityCurrencyBar:PlayCountAnimation(tokenType, count)
        self.SideBar.SpecList.animatedToken = nil
    end
end

-- DOC: CharacterAdvancementMixin:ContentOnScrollRangeChanged
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
--   - xrange: a piece of information passed in by the caller
--   - yrange: a piece of information passed in by the caller
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces.
function CharacterAdvancementMixin:ContentOnScrollRangeChanged(xrange, yrange)
    ScrollFrame_OnScrollRangeChanged(self.Content, xrange, yrange)
    local maxOffset = self.Content:GetVerticalScrollRange()

    if maxOffset == 0 and (C_CVar.Get("caLastSpec") ~= "BROWSER") then
        self.Content:SetWidth(802)
        self.SideBar:SetPoint("TOPLEFT", self.Content, "TOPRIGHT", 1, 10)
        self.Content.scrollbar:Hide()
        self.Content.ScrollChild.Talents:SetWidth(369)
        self.Content.ScrollBackground:Hide()
        self.Content.ScrollTop:Hide()
        self.Content.ScrollBottom:Hide()
        self.Content.ScrollMiddle:Hide()
        self.Content.Footer:SetPoint("TOPRIGHT", self.Content, "BOTTOMRIGHT", 0, 0)
    else
        self.Content:SetWidth(802-SCROLL_X_SHIFT)
        self.SideBar:SetPoint("TOPLEFT", self.Content, "TOPRIGHT", 1+SCROLL_X_SHIFT, 10)
        self.Content.scrollbar:Show()
        self.Content.ScrollChild.Talents:SetWidth(369-SCROLL_X_SHIFT)
        self.Content.ScrollBackground:Show()
        self.Content.ScrollTop:Show()
        self.Content.ScrollBottom:Show()
        self.Content.ScrollMiddle:Show()
        self.Content.Footer:SetPoint("TOPRIGHT", self.Content, "BOTTOMRIGHT", 0+SCROLL_X_SHIFT, 0)
    end

    self.Content:UpdateTabLayout()
end

-- DOC: CharacterAdvancementMixin:CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED
-- What this does: Do a specific piece of work related to 'CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED'.
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: updates UI/state.
function CharacterAdvancementMixin:CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED()
    if not self.preserveFilter then
        self:Search()
        self.preserveFilter = false
    end
    local specFile = C_CVar.Get("caLastSpec")

    if specFile == "SUMMARY" then
        self:FullUpdate()
    elseif specFile == "BROWSER" then
        self:BrowserSearch()
        self:Refresh()
    else
        self:Refresh()
    end

    self:RefreshCurrencies()
end

-- DOC: CharacterAdvancementMixin:WILDCARD_ENTRY_LEARNED
-- What this does: Do a specific piece of work related to 'WILDCARD_ENTRY_LEARNED'.
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: updates UI/state.
function CharacterAdvancementMixin:WILDCARD_ENTRY_LEARNED()
    self.preserveFilter = false -- wildcard always refreshes filter
    local specFile = C_CVar.Get("caLastSpec")

    if specFile == "SUMMARY" then
        self:FullUpdate()
    elseif specFile == "BROWSER" then
        self:BrowserSearch()
    else
        self:Search()
        self:Refresh()
    end
end

-- DOC: CharacterAdvancementMixin:ASCENSION_CA_SPECIALIZATION_ACTIVE_ID_CHANGED
-- What this does: Do a specific piece of work related to 'ASCENSION_CA_SPECIALIZATION_ACTIVE_ID_CHANGED'.
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
--   - specID: an identifier (a number/string that points to a specific thing)
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: updates UI/state.
function CharacterAdvancementMixin:ASCENSION_CA_SPECIALIZATION_ACTIVE_ID_CHANGED(specID)
    if self:IsShown() then
        self:FullUpdate()
    end
end 

function CharacterAdvancementMixin:PET_TALENT_UPDATE()
    self:Refresh()
end

-- DOC: CharacterAdvancementMixin:PLAYER_REGEN_DISABLED
-- What this does: Do a specific piece of work related to 'PLAYER_REGEN_DISABLED'.
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: updates UI/state.
function CharacterAdvancementMixin:PLAYER_REGEN_DISABLED()
    self:FullUpdate()
end

function CharacterAdvancementMixin:PLAYER_REGEN_ENABLED()
    self:FullUpdate()
end

-- DOC: CharacterAdvancementMixin:PLAYER_LEVEL_UP
-- What this does: Do a specific piece of work related to 'PLAYER_LEVEL_UP'.
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: updates UI/state.
function CharacterAdvancementMixin:PLAYER_LEVEL_UP()
    self:FullUpdate()
end 

function CharacterAdvancementMixin:TOKEN_UPDATED()
    self.SideBar.SpecList:RefreshScrollFrame()
    self.SideBar.SpellList.Footer.RarityCurrencyBar:Update()
end

-- DOC: CharacterAdvancementMixin:BAG_UPDATE
-- What this does: Do a specific piece of work related to 'BAG_UPDATE'.
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: updates UI/state.
function CharacterAdvancementMixin:BAG_UPDATE()
    -- currency bars update themselves
    self:RefreshCurrencies()
end 

function CharacterAdvancementMixin:CURRENCY_DISPLAY_UPDATE()
    -- currency bars update themselves
    self:RefreshCurrencies()
end 

-- DOC: CharacterAdvancementMixin:CHARACTER_ADVANCEMENT_SUGGESTIONS_UPDATED
-- What this does: Do a specific piece of work related to 'CHARACTER_ADVANCEMENT_SUGGESTIONS_UPDATED'.
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: updates UI/state.
function CharacterAdvancementMixin:CHARACTER_ADVANCEMENT_SUGGESTIONS_UPDATED()
    if C_CVar.Get("caLastSpec") == "BROWSER" then
        self:BrowserSearch()
    end
end

function CharacterAdvancementMixin:SPELL_TAGS_CHANGED()
    self:CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED()
end

-- DOC: CharacterAdvancementMixin:SPELL_TAG_TYPES_CHANGED
-- What this does: Do a specific piece of work related to 'SPELL_TAG_TYPES_CHANGED'.
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: updates UI/state.
function CharacterAdvancementMixin:SPELL_TAG_TYPES_CHANGED()
    self.Content.Filter:ClearDropDown()
    CharacterAdvancementUtil.InitializeSpellTagFilter(self.Content.Filter, GenerateClosure(self.BrowserSearch, self))

    self.Content.Filter:ClearFilters()
end

function CharacterAdvancementMixin:STAT_SUGGESTIONS_UPDATED()
    if ShowForcedPrimaryStat(false) then
        ForcedPrimaryStatFrame:CheckSuggestions()
    end
end
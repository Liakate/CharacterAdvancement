-- GUIDE: What is this file?
-- Purpose: Main logic for the Character Advancement window (what happens when you open the UI, click tabs, pick talents, etc.).
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

CA_ABILITY_MASTERIES = CA_ABILITY_MASTERIES or "Ability Masteries"
CA_ABILITY_MASTERIES_DESC = CA_ABILITY_MASTERIES_DESC or "Masteries bundle related spells together for the cost of one ability. You automatically unlock additional spells from your Masteries when you reach their Class Point requirements."
CA_TRAITS_TITLE = CA_TRAITS_TITLE or "Implicit Traits"
CA_TRAITS_DESC = CA_TRAITS_DESC or "Implicit Traits unlock automatically when reaching their required Class Points, and deactivate if you fall below that threshold."
CA_LEARN_SPELLS_UP_TO_LEVEL = CA_LEARN_SPELLS_UP_TO_LEVEL or "Learn Spells up to level |cffFFFFFF%d|r"
CA_TALENTS_GRANT_UP_TO_LEVEL = CA_TALENTS_GRANT_UP_TO_LEVEL or "Talents grant %s Points up to level |cffFFFFFF%d|r"

-- TODO: Move to constants?
if C_Player:IsHero() then
    CA_USE_GATES_DEBUG = true
end
--

-- DOC: C_CharacterAdvancement.CanUseBrowser
-- What this does: Checks whether a feature is enabled/allowed and returns true/false.
-- When it runs: Called after this UI registers for events, or when something changes that needs a refresh.
-- Inputs: none
-- Output: A value used by other code (C_Config.GetBoolConfig("CONFIG_ABILITY_B...).
-- What it changes: changes text on screen, listens for game events, uses Character Advancement API.
function C_CharacterAdvancement.CanUseBrowser()
    return C_Config.GetBoolConfig("CONFIG_ABILITY_BROWSER_ENABLED")
end

CharacterAdvancementMixin = {}

local STICKY_TABS = {
    ["MASTERY"] = true,
    ["TALENTBROWSER"] = true,
    ["SPELLBROWSER"] = true,
}

local CA_NORMAL_FOOTER_HEIGHT = 596
local CA_BIG_FOOTER_HEIGHT = 640
local CA_LOCKTALENTSFRAME_HEIGHT = 579

local GATES_TALENT_SHIFT = -8
local HEADER_NO_PRIMARY_STAT_HEIGHT = 30
local HEADER_PRIMARY_STAT_HEIGHT = 86

local NUM_SPEC_TABS = 3
local SPELL_BROWSER_TAB = NUM_SPEC_TABS + 1
local TALENT_BROWSER_TAB = SPELL_BROWSER_TAB + 1
local MASTERY_TAB = TALENT_BROWSER_TAB + 1
local SUMMARY_SPEC_TAB = MASTERY_TAB + 1

local SCROLL_X_SHIFT = 22
local GATES_HEADERS_X_SHIFT = -96

local NUM_TALENTS_PER_ROW_SUMMARY = 7
local NUM_SPELLS_PER_ROW_SUMMARY = 8

-- DOC: CharacterAdvancementMixin:OnLoad
-- What this does: Sets up this UI element: prepares data, connects events, and sets initial visuals.
-- When it runs: Runs once when this UI element is created/loaded.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: changes text on screen, listens for game events.
function CharacterAdvancementMixin:OnLoad()
    self.classMasteries = {}

    if C_Player:IsDefaultClass() then
        local YShift = 70
        CA_NORMAL_FOOTER_HEIGHT = CA_NORMAL_FOOTER_HEIGHT - YShift
        CA_BIG_FOOTER_HEIGHT = CA_BIG_FOOTER_HEIGHT - YShift
        CA_LOCKTALENTSFRAME_HEIGHT = CA_LOCKTALENTSFRAME_HEIGHT - YShift
        self.SideBar.SpecList:SetHeight(self.SideBar.SpecList:GetHeight()-YShift)
        self:SetHeight(self:GetHeight()-YShift)
    end

    self:RegisterEvent("ASCENSION_CA_SPECIALIZATION_ACTIVE_ID_CHANGED")
    self:RegisterEvent("CHARACTER_ADVANCEMENT_LEARN_RESULT")
    self:RegisterEvent("CHARACTER_ADVANCEMENT_UNLEARN_RESULT")
    self:RegisterEvent("CHARACTER_ADVANCEMENT_PURGE_ABILITIES_RESULT")
    self:RegisterEvent("CHARACTER_ADVANCEMENT_PURGE_TALENTS_RESULT")
    self:RegisterEvent("CHARACTER_ADVANCEMENT_UPDATE_ENTRIES_RESULT")
    PortraitFrame_SetTitle(self, CHARACTER_ADVANCEMENT)
    PortraitFrame_SetIcon(self, "Interface\\Icons\\trade_archaeology_draenei_tome")
    self.SideBar.SpecList.IconSelector.Text:SetText(ENTER_SPEC_NAME_HELP)
    self.Content.LockTalentsFrame:SetScript("OnMouseUp", function() 
            if ForcedPrimaryStatFrame and ForcedPrimaryStatFrame:IsVisible() then
                ForcedPrimaryStatFrame:OnPrimaryStatSelected()
            end
        end)
    self.Content.LockTalentsFrame:SetFrameLevel(self.Content.NineSlice:GetFrameLevel()+10)
    self.Content.LockTalentsFrame.Text:SetText(CA_TALENTS_UNLOCK_AT_LEVEL or "Unlocks at level 10.")
    self.CloseButton:SetScript("OnClick", function()
        HideUIPanel(Collections)
    end)
    self.mode = Enum.GameMode.None
    self.CategoryPool = CreateFramePool("Frame", self.Content.ScrollChild.Spells, "CASpellCategoryTemplate")
    self.SpellPool = CreateFramePool("Button", self.Content.ScrollChild.Spells, "CASpellButtonTemplate")
    self.CompactSpellPool = CreateFramePool("Button", self.Content.ScrollChild.Spells, "CACompactSpellButtonTemplate")
    self.TalentPool = CreateFramePool("Button", self.Content.ScrollChild.Talents, "CATalentButtonTemplate")

    self.SpellClassIconsPool = CreateFramePool("Button", self.Content.ScrollChild.Spells, "CASummaryClassIconTemplate")
    self.TalentClassIconsPool = CreateFramePool("Button", self.Content.ScrollChild.Talents, "CASummaryClassIconTemplate")

    self.GateCounterSpells = CreateFramePool("Frame", self.Content.HeaderSpells, "CATalentGateCounterTemplate")
    self.GateCounterTalents = CreateFramePool("Frame", self.Content.HeaderTalents, "CATalentGateCounterTemplate")

    MixinAndLoadScripts(self.Content.ScrollChild.Talents, "CAConnectedNodesMixin")
    MixinAndLoadScripts(self.Content.ScrollChild.Talents, "CATalentFrameGatesMixin")

    self:SetupClassButtons()
    self:SetupSpecTabs()
    self:SetupSideBarTabs()
    CharacterAdvancementUtil.InitializeFilter(self.SideBar.SpellList.Header.Filter, GenerateClosure(self.Search, self))
    CharacterAdvancementUtil.InitializeSpellTagFilter(self.Content.Filter, GenerateClosure(self.BrowserSearch, self))
    self.Content.SpellTagFrame:RegisterCallback("OnSpellTagClicked", GenerateClosure(self.RemoveSpellTag, self))
    self:RefreshPrimaryStats()
    self:RefreshCurrencies()
    self:RefreshSaveChangesButton()
    UIDropDownMenu_Initialize(self.SpellDropDownMenu, GenerateClosure(self.InitializeSpellDropDown, self), "MENU")
    C_GameMode:RegisterCallback("OnGameModeChanged", GenerateClosure(self.OnGameModeChanged, self))

    self.Content.Footer.SpellCurrencyBar:SetJustify("LEFT")
    self.Content.Footer.TalentCurrencyBar:SetJustify("RIGHT")
    
    self.InputBlocker:SetFrameLevel(self.Content.NineSlice:GetFrameLevel() + 10)

    self.Content.HeaderSpells.TotalShadow:SetAtlas("common-shadow-circle", Const.TextureKit.IgnoreAtlasSize)
    self.Content.HeaderTalents.TotalShadow:SetAtlas("common-shadow-circle", Const.TextureKit.IgnoreAtlasSize)
    self.Content.BackgroundHeaderAdd:SetAtlas("ca-background-header", Const.TextureKit.IgnoreAtlasSize)
    self.Content.BackgroundHeaderAdd:SetParent(self.Content.HeaderSpells)

    self.expectedAEByLevel = {}

    for i = 1, 80 do
        self.expectedAEByLevel[i] = C_CharacterAdvancement.GetExpectedAE(i) or 0
    end

    self.Content.Footer.UndoButton:SetScript("OnClick", GenerateClosure(self.OnClickUndoChanges, self))
    self.Content.Footer.SaveChangesButton:SetScript("OnClick", GenerateClosure(self.OnClickSaveChanges, self))

    Collections:HookScript("OnHide", function()
        self:ClearSearch()
    end)

    --self.SideBar.SpellList.Header.NineSlice.SelectedStatText:ClearAndSetPoint("LEFT", 52, 9)
    --self.SideBar.SpellList.Header.NineSlice.SelectedStatText2:ClearAndSetPoint("RIGHT", -12, 9)
    --self.SideBar.SpellList.Header.NineSlice.SelectedStatText2:ClearAndSetPoint("LEFT", self.SideBar.SpellList.Header.NineSlice.SelectedStatText, "RIGHT", 64, 0)
    if C_Player:IsDefaultClass() then
        self.Navigation2:SetPoint("BOTTOMRIGHT", self, "BOTTOMLEFT", 4, 6)
        self.Navigation2:Hide()
        self:SetSize(self:GetWidth()-125, self:GetHeight())
    end

    self.Content.HeaderTalents:SetFrameLevel(self.Content.TalentBrowser:GetFrameLevel()+4)

    self.PetTalents:SetParent(CharacterAdvancementNineSlice)
    self.PetTalents:ClearAndSetPoint("BOTTOMRIGHT", self.Content, -24, 24)
    self.PetTalents:Show()

    -- DOC: self.PetTalents:OnTalentCountEnter
    -- What this does: Show part of the UI (or switch which panel is visible).
    -- When it runs: Runs for a UI callback named OnTalentCountEnter.
    -- Inputs:
    --   - self: the UI object this function belongs to
    -- Output: Nothing (it mainly updates state and/or the UI).
    -- What it changes: shows/hides UI pieces, changes text on screen.
    function self.PetTalents:OnTalentCountEnter()
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(UNSPENT_TALENT_POINTS:format(GetUnspentTalentPoints(false, true)))
        GameTooltip:Show()
    end

    function self.PetTalents:OnCountLeave()
        GameTooltip:Hide()
    end 
end

-- DOC: CharacterAdvancementMixin:OnGameModeChanged
-- What this does: Hide part of the UI (or close a popup).
-- When it runs: Runs for a UI callback named OnGameModeChanged.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: A value used by other code (self.mode == Enum.GameMode.Draft).
-- What it changes: shows/hides UI pieces.
function CharacterAdvancementMixin:OnGameModeChanged()
    self:ShowNormalFooter()

    CA_USE_GATES_DEBUG = false
    C_CVar.Set("previewCharacterAdvancementChanges", "0")

    if C_GameMode:IsGameModeActive(Enum.GameMode.Draft) then
        self.mode = Enum.GameMode.Draft
        PortraitFrame_SetTitle(self, format("%s - %s", CHARACTER_ADVANCEMENT, DRAFT_MODE))
        PortraitFrame_SetIcon(self, "Interface\\Icons\\inv_misc_dmc_destructiondeck")
        self.Content.WCRapidRollButton:Hide()
    elseif C_GameMode:IsGameModeActive(Enum.GameMode.WildCard) then
        self.mode = Enum.GameMode.WildCard
        PortraitFrame_SetTitle(self, format("%s - %s", CHARACTER_ADVANCEMENT, WILDCARD_MODE))
        PortraitFrame_SetIcon(self, "Interface\\Icons\\misc_rune_pvp_random")
        self.Content.Footer:Hide()
    else
        self.mode = Enum.GameMode.None
        PortraitFrame_SetTitle(self, CHARACTER_ADVANCEMENT)
        if C_Player:IsDefaultClass() then
            CA_USE_GATES_DEBUG = true
            C_CVar.Set("previewCharacterAdvancementChanges", "1")
            self:ShowMaximizedFooter()
            PortraitFrame_SetClassIcon(self, C_Player:GetClass())
        else
            PortraitFrame_SetIcon(self, "Interface\\Icons\\trade_archaeology_draenei_tome")
        end

        if C_Player:IsHero() then
            if C_Config.GetBoolConfig("CONFIG_CHARACTER_ADVANCEMENT_QUALITIES_ENABLED") then
                self:ShowRarityFlyout()
            else -- instead of rarity 
                CA_USE_GATES_DEBUG = true
                C_CVar.Set("previewCharacterAdvancementChanges", "1")
                self:ShowMaximizedFooter()
            end
        end

        self.Content.WCRapidRollButton:Hide()

        if C_GameMode:IsGameModeActive(Enum.GameMode.BuildDraft) then
            self.Content.Footer:Hide()
        end
    end

    self:FullUpdate()
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
-- What it changes: shows/hides UI pieces, listens for game events.
function CharacterAdvancementMixin:LockTalentsFrameCheck()
    if C_Player:IsHero() then
        return
    end

    self.Content.LockTalentsFrame:Hide()

    local lastClass = C_CVar.Get("caLastClass")
    local lastSpec = C_CVar.Get("caLastSpec")

    if not string.isNilOrEmpty(lastClass) and (lastClass == "BROWSER") then
        return
    end

    if not string.isNilOrEmpty(lastSpec) and (lastSpec == "MASTERY") then
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
    self:RegisterEvent("WILDCARD_ENTRY_LEARNED")
    self:RegisterEvent("PET_TALENT_UPDATE")
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    self:RegisterEvent("PLAYER_LEVEL_UP")
    --self:RegisterEvent("BAG_UPDATE")
    self:RegisterEvent("TOKEN_UPDATED")
    self:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
    self:RegisterEvent("CHARACTER_ADVANCEMENT_SUGGESTIONS_UPDATED")
    self:RegisterEvent("SPELL_TAGS_CHANGED")
    self:RegisterEvent("SPELL_TAG_TYPES_CHANGED")
    self:RegisterEvent("STAT_SUGGESTIONS_UPDATED")
    self:RegisterEvent("CHARACTER_ADVANCEMENT_BUILD_LEVEL_UPDATED")
    self:RegisterEvent("CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED")
end

-- DOC: CharacterAdvancementMixin:UnregisterUpdateEvents
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: listens for game events, uses Character Advancement API.
function CharacterAdvancementMixin:UnregisterUpdateEvents()
    self:UnregisterEvent("WILDCARD_ENTRY_LEARNED")
    self:UnregisterEvent("PET_TALENT_UPDATE")
    self:UnregisterEvent("PLAYER_REGEN_DISABLED")
    self:UnregisterEvent("PLAYER_REGEN_ENABLED")
    self:UnregisterEvent("PLAYER_LEVEL_UP")
    --self:UnregisterEvent("BAG_UPDATE")
    self:UnregisterEvent("TOKEN_UPDATED")
    self:UnregisterEvent("CURRENCY_DISPLAY_UPDATE")
    self:UnregisterEvent("CHARACTER_ADVANCEMENT_SUGGESTIONS_UPDATED")
    self:UnregisterEvent("SPELL_TAGS_CHANGED")
    self:UnregisterEvent("SPELL_TAG_TYPES_CHANGED")
    self:UnregisterEvent("STAT_SUGGESTIONS_UPDATED")
    self:UnregisterEvent("CHARACTER_ADVANCEMENT_BUILD_LEVEL_UPDATED")
    self:UnregisterEvent("CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED")
end

-- DOC: CharacterAdvancementMixin:OnShow
-- What this does: Prepares the UI right before the player sees it (updates text, lists, or buttons).
-- When it runs: Runs each time this UI element becomes visible.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: uses Character Advancement API.
function CharacterAdvancementMixin:OnShow()
    StaticPopup_Hide("CLOSE_CHARACTER_ADVANCEMENT_UNSAVED_PENDING_CHANGES")
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

    if not self.initialized then
        self.initialized = true
        self:OnGameModeChanged()
    else
        self:Refresh()
        --self:FullUpdate()
    end

    self:RefreshCurrencies()
    self:RefreshSaveChangesButton()
end

-- DOC: CharacterAdvancementMixin:OnHide
-- What this does: Cleans up when the UI closes (stops updates and hides extra popups).
-- When it runs: Runs when this UI element is hidden.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, uses Character Advancement API.
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

    StaticPopup_Hide("CONFIRM_LEAVING_PENDING")
    CharacterAdvancementUtil.MarkForSwap(nil)

    if ForcedPrimaryStatFrame and ForcedPrimaryStatFrame:IsVisible() then
        ForcedPrimaryStatFrame:OnPrimaryStatSelected()
    end

    if C_CharacterAdvancement.IsPending() then
        StaticPopup_Show("CLOSE_CHARACTER_ADVANCEMENT_UNSAVED_PENDING_CHANGES")
    end
end

-- DOC: CharacterAdvancementMixin:ShowNormalFooter
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, uses Character Advancement API.
function CharacterAdvancementMixin:ShowNormalFooter()
    self.Content.Footer:SetHeight(22)
    self.Content.Footer:Show()
    self.Content.ScrollChild.Spells:SetHeight(CA_NORMAL_FOOTER_HEIGHT)
    self.Content.ScrollChild.Talents:SetHeight(CA_NORMAL_FOOTER_HEIGHT)
    self.Content:SetHeight(CA_NORMAL_FOOTER_HEIGHT)
    self.Content.ScrollChild:SetHeight(CA_NORMAL_FOOTER_HEIGHT)
    self.Content.AbilityBrowser.ScrollFrame:SetHeight(CA_NORMAL_FOOTER_HEIGHT)
    self.Content.AbilityBrowser:SetHeight(CA_NORMAL_FOOTER_HEIGHT+10)
    self.Content.LockTalentsFrame:SetHeight(CA_NORMAL_FOOTER_HEIGHT)
    self.Content.Footer.UndoButton:Hide()
    self.Content.Footer.SaveChangesButton:Hide()

    self.Content.Footer.ResetBuildButton:SetParent(self.Content.Footer)
    self.Content.Footer.ResetBuildButton:ClearAndSetPoint("CENTER", self.Content.Footer, "CENTER", 0, 2)
    self.Content.Footer.ResetBuildButton:SetWidth(180)

    self.SideBar.SpellList.Footer:SetHeight(22)
    self.SideBar.SpellList.Footer.RarityCurrencyBar:ClearAndSetPoint("CENTER", 0, 0)

    self.normalFooter = true
end

-- DOC: CharacterAdvancementMixin:AddFakeLevelTooltip
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
--   - button: the button that triggered this (the thing you clicked)
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, changes text on screen, uses Character Advancement API.
function CharacterAdvancementMixin:AddFakeLevelTooltip(button)
    GameTooltip:AddLine(" ")
    local baseAEAmount = 0

    for i = 1, GetMaxLevel() do
        local diff = self.expectedAEByLevel[i] - baseAEAmount

        if diff > 0 then
            GameTooltip:AddLine(FRIENDS_LEVEL_TEMPLATE:format(i, "|cffFFFFFF+"..diff.."|r Ability Essence"))
            baseAEAmount = self.expectedAEByLevel[i]
        end
    end
end

-- DOC: CharacterAdvancementMixin:RefreshHeaderTotal
-- What this does: Update what is shown on screen so it matches the latest game data.
-- When it runs: Called whenever the screen needs to be redrawn with fresh information.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (nil).
-- What it changes: shows/hides UI pieces, changes text on screen, uses Character Advancement API.
function CharacterAdvancementMixin:RefreshHeaderTotal()
    local classFile = C_CVar.Get("caLastClass")

    self.Content.BackgroundHeaderAdd:Show()
    self.Content.HeaderTalents:ClearAndSetPoint("TOPRIGHT")
    self.Content.HeaderSpells:ClearAndSetPoint("TOPLEFT")
    self.Content.HeaderSpells.SubText:Hide()
    self.Content.HeaderTalents.SubText:Hide()
    self.Content.HeaderSpells.AbilityEssence:Hide()
    self.Content.HeaderSpells.Total:Hide()

    if CA_USE_GATES_DEBUG then
        local totalAESpent = C_CharacterAdvancement.GetGlobalAEInvestment() or 0
        local fakeLevel = 1

        totalAESpent = math.max( totalAESpent, 1)
        
        if totalAESpent >= 7 then
            for i = 1, 80 do 
                fakeLevel = i
                if self.expectedAEByLevel[i] > totalAESpent then
                    break
                end
            end
        end

        local className = classFile and LOCALIZED_CLASS_NAMES_MALE[string.upper(classFile)] or ""

        self.Content.HeaderSpells.SubText:SetText(CA_LEARN_SPELLS_UP_TO_LEVEL:format(fakeLevel)) 
        self.Content.HeaderTalents.SubText:SetText(CA_TALENTS_GRANT_UP_TO_LEVEL:format(className, math.max(10, fakeLevel)))
    end

    if C_Player:IsDefaultClass() then
        self.GateCounterSpells:ReleaseAll()
        self.GateCounterTalents:ReleaseAll()
        self.Content.HeaderSpells.TotalShadow:Hide()
        self.Content.HeaderTalents.TotalShadow:Hide()
        self.Content.HeaderSpells.Total:ClearAndSetPoint("TOP", 0, -10)
        
        if CA_USE_GATES_DEBUG then
            self.Content.HeaderTalents.Total:ClearAndSetPoint("TOP", 0, -10)
        else
            self.Content.HeaderTalents.Total:ClearAndSetPoint("TOP", 0, -10)
        end

        self.Content.BackgroundHeaderAdd:SetAtlas("ca-background-header-cut", Const.TextureKit.IgnoreAtlasSize)
        return
    end
    
    self.Content.HeaderSpells.TotalShadow:Show()
    self.Content.HeaderTalents.TotalShadow:Show()

    if C_CVar.Get("caLastSpec") == "SUMMARY" then
        self.Content.HeaderSpells.AbilityEssence:Show()
        self.Content.HeaderSpells.Total:Show()

        self.Content.HeaderSpells.TotalShadow:Hide()
        self.Content.HeaderTalents.TotalShadow:Hide()
        self.GateCounterSpells:ReleaseAll()
        self.GateCounterTalents:ReleaseAll()
        if not self.normalFooter then
            self.Content.HeaderSpells.Total:ClearAndSetPoint("TOP", 0, -24)
            self.Content.HeaderTalents.Total:ClearAndSetPoint("TOP", 0, -24)
            --self.Content.HeaderSpells.SubText:Show()
            --self.Content.HeaderTalents.SubText:Show()
            self.Content.BackgroundHeaderAdd:SetAtlas("ca-background-header-cut", Const.TextureKit.IgnoreAtlasSize)
            return
        end
    end

    if not self.normalFooter then
        --self.Content.HeaderSpells.SubText:Show()
        --self.Content.HeaderTalents.SubText:Show()

        if CA_USE_GATES_DEBUG and self.Content.HeaderSpells.CounterSpells then
            local spellsLength = 6 + self.Content.HeaderSpells.Total:GetStringWidth() + self.Content.HeaderSpells.AbilityEssence:GetWidth() + self.Content.HeaderSpells.CounterSpells.GateText:GetStringWidth() + self.Content.HeaderSpells.CounterSpells.LockIcon:GetWidth()
            --local talentsLength = self.Content.HeaderTalents.Total:GetStringWidth() + 6 + self.Content.HeaderTalents.TalentEssence:GetWidth() + self.Content.HeaderTalents.CounterTalents.GateText:GetStringWidth() + 6 + self.Content.HeaderTalents.CounterTalents.LockIcon:GetWidth()
    
            self.Content.HeaderSpells.AbilityEssence:Show()
            self.Content.HeaderSpells.Total:Show()

            self.Content.HeaderSpells.CounterSpells:ClearAndSetPoint("LEFT", self.Content.HeaderSpells.Total, "RIGHT", 6, 0)
            --self.Content.HeaderTalents.CounterTalents:ClearAndSetPoint("LEFT", self.Content.HeaderTalents.Total, "RIGHT", 0, 0)
            self.Content.HeaderSpells.Total:ClearAndSetPoint("TOP", -spellsLength/4, -24)
            --self.Content.HeaderTalents.Total:ClearAndSetPoint("TOP", -talentsLength/4, -24)
        else
            self.Content.HeaderSpells.Total:ClearAndSetPoint("TOP", 0, -24)
            self.Content.HeaderTalents.Total:ClearAndSetPoint("TOP", 0, -24)
        end

        self.Content.BackgroundHeaderAdd:SetAtlas("ca-background-header", Const.TextureKit.IgnoreAtlasSize)
    else
        self.Content.HeaderSpells.TotalShadow:Hide()
        self.Content.HeaderTalents.TotalShadow:Hide()
        self.Content.HeaderSpells.Total:ClearAndSetPoint("TOP", 0, -10)
        self.Content.HeaderTalents.Total:ClearAndSetPoint("TOP", 0, -10)

        self.Content.BackgroundHeaderAdd:SetAtlas("ca-background-header-cut", Const.TextureKit.IgnoreAtlasSize)
    end

    if (C_CVar.Get("caLastSpec") == "MASTERY") or (C_CVar.Get("caLastSpec") == "SPELLBROWSER") then
        self.Content.HeaderSpells:ClearAndSetPoint("TOP", 0, 0)
        self.Content.BackgroundHeaderAdd:SetAtlas("ca-background-header", Const.TextureKit.IgnoreAtlasSize)
        self.Content.HeaderTalents:Hide()
    end

    if C_CVar.Get("caLastSpec") == "TALENTBROWSER" then
        local talentsLength = self.Content.HeaderTalents.Total:GetStringWidth() + 6 + self.Content.HeaderTalents.TalentEssence:GetWidth() 
        self.Content.HeaderTalents.Total:ClearAndSetPoint("TOP", 0, -16)

        if self.Content.HeaderTalents.CounterTalents then
            self.Content.HeaderTalents.CounterTalents:Hide()
        end

        self.Content.HeaderTalents.SubText:Hide()

        self.Content.HeaderTalents:ClearAndSetPoint("TOP", 0, 0)
    end
end

-- DOC: CharacterAdvancementMixin:ShowMaximizedFooter
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: A value used by other code (self:HidePrimaryStatPicker()).
-- What it changes: shows/hides UI pieces.
function CharacterAdvancementMixin:ShowMaximizedFooter()
    self.Navigation:SetHeight(36)
    self.Navigation:Hide()

    self.Content.Footer.TalentCurrencyBar:Hide()
    self.Content.Footer.SpellCurrencyBar:Hide()

    self.Content.Footer.UndoButton:Show()
    self.Content.Footer.SaveChangesButton:Show()
    self.Content.Footer:SetHeight(39)
    --self.Content.Footer:Hide()
    self.Content.ScrollChild.Spells:SetHeight(CA_BIG_FOOTER_HEIGHT)
    self.Content.ScrollChild.Talents:SetHeight(CA_BIG_FOOTER_HEIGHT)
    self.Content:SetHeight(CA_BIG_FOOTER_HEIGHT)
    self.Content.ScrollChild:SetHeight(CA_BIG_FOOTER_HEIGHT)
    self.Content.AbilityBrowser:SetHeight(CA_BIG_FOOTER_HEIGHT+10)
    self.Content.AbilityBrowser:SetHeight(CA_BIG_FOOTER_HEIGHT+10)
    self.Content.AbilityBrowser.ScrollFrame:SetHeight(CA_BIG_FOOTER_HEIGHT)
    HybridScrollFrame_CreateButtons(self.Content.AbilityBrowser.ScrollFrame, self.Content.AbilityBrowser.template, 0, 0)

    self.Content.LockTalentsFrame:SetHeight(CA_LOCKTALENTSFRAME_HEIGHT)

    self.SideBar.SpellList.Footer:SetHeight(44)
    self.SideBar.SpellList.Footer.RarityCurrencyBar:ClearAndSetPoint("TOP", 0, 0)

    self.Content.Footer.ResetBuildButton:Show()
    self.Content.Footer.ResetBuildButton:SetWidth(225)
    self.Content.Footer.ResetBuildButton:SetParent(self.SideBar.SpellList.Footer)
    self.Content.Footer.ResetBuildButton:ClearAndSetPoint("BOTTOM", self.SideBar.SpellList.Footer, "BOTTOM", 0, -1)

    self.normalFooter = false
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
    
    local height = CA_NORMAL_FOOTER_HEIGHT-10
    local headerHeight = header:GetHeight()
    self.SideBar.SpellList:SetPoint("TOPLEFT", 0, -headerHeight)
    if header.IsCompact then
        height = height + HEADER_PRIMARY_STAT_HEIGHT - HEADER_NO_PRIMARY_STAT_HEIGHT
    end
    if footer.RarityFlyout:IsShown() then
        height = height - 101
    elseif not self.normalFooter then
        height = height - 22
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
    header.NineSlice:Show()
    --header.ChangeStatButton:Show()
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
    header.NineSlice:Hide()
    --header.NineSlice.SelectedStatText2:Hide()
    --header.ChangeStatButton:Hide()

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

    if not C_Config.GetBoolConfig("CONFIG_CHARACTER_ADVANCEMENT_QUALITIES_ENABLED") then
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

    if not C_Config.GetBoolConfig("CONFIG_CHARACTER_ADVANCEMENT_QUALITIES_ENABLED") then
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
-- Output: Nothing (nil).
-- What it changes: shows/hides UI pieces, changes text on screen, uses Character Advancement API.
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
end

-- DOC: CharacterAdvancementMixin:RemoveSpellTag
-- What this does: Update text shown to the player.
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
--   - _: a piece of information passed in by the caller
--   - filter: the filter/search text used to narrow results
--   - tag: a piece of information passed in by the caller
-- Output: Nothing (nil).
-- What it changes: changes text on screen, uses Character Advancement API.
function CharacterAdvancementMixin:RemoveSpellTag(_, filter, tag)
    if filter then
        self.Content.Filter:SetFilter(filter, false)
    elseif tag then
       self.Content.Filter:SetFilter("FILTER_SPELLTAG_"..tag, false)
   end
end

-- DOC: CharacterAdvancementMixin:ClearSearch
-- What this does: Update text shown to the player.
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (nil).
-- What it changes: changes text on screen, uses Character Advancement API.
function CharacterAdvancementMixin:ClearSearch()
    self:SetSearch("")
    self.Content.SearchBox:SetText("")
end

function CharacterAdvancementMixin:Locate(entry)
    local class, spec = CharacterAdvancementUtil.GetClassFileForEntry(entry)

    if C_Player:IsHero() then
        if C_CharacterAdvancement.IsTalentID(entry.ID) or C_CharacterAdvancement.IsTalentAbilityID(entry.ID) then
            self.Content:SelectTabID(TALENT_BROWSER_TAB)
        elseif C_CharacterAdvancement.IsMastery(entry.Spells[1]) then
            self.Content:SelectTabID(MASTERY_TAB)
        else
            self.Content:SelectTabID(SPELL_BROWSER_TAB)
        end
    end

    if class then
        self.LocateID = entry.ID
        self:SelectClass(class,spec)
    end
end

-- DOC: CharacterAdvancementMixin:SelectSummary
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (nil).
-- What it changes: shows/hides UI pieces, uses Character Advancement API.
function CharacterAdvancementMixin:SelectSummary()
    C_CVar.Set("caLastSpec", "SUMMARY")
    self:FullUpdate()
end

function CharacterAdvancementMixin:SelectBrowser()
    C_CVar.Set("caLastClass", "BROWSER")

    if not C_CVar.Get("caLastSpec") or (C_CVar.Get("caLastSpec") ~= "TALENTBROWSER") and (C_CVar.Get("caLastSpec") ~= "SPELLBROWSER") then
        self.Content:SelectTabID(SPELL_BROWSER_TAB)
        return
    end

    if C_CVar.Get("caLastSpec") == "TALENTBROWSER" then
        self.Content:SelectTabID(TALENT_BROWSER_TAB)
        return
    end

    self:FullUpdate(true)
end

-- DOC: CharacterAdvancementMixin:SelectClassInNavigation
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
--   - classFile: a piece of information passed in by the caller
-- Output: Nothing (nil).
-- What it changes: shows/hides UI pieces, uses Character Advancement API.
function CharacterAdvancementMixin:SelectClassInNavigation(classFile)
    C_CVar.Set("caLastClass", classFile)

    for class, button in pairs(self.ClassButtons) do
        if class == classFile then
            button:OnSelected()
        else
            button:OnDeSelected()
        end
    end
end

-- DOC: CharacterAdvancementMixin:SelectClass
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
--   - classFile: a piece of information passed in by the caller
--   - specFile: information about a specialization (spec) choice
-- Output: Nothing (nil).
-- What it changes: shows/hides UI pieces, uses Character Advancement API.
function CharacterAdvancementMixin:SelectClass(classFile, specFile)
    if not classFile then return end

    if not self.ClassButtons[classFile] then
        classFile = next(self.ClassButtons)
    end

    if not CHARACTER_ADVANCEMENT_CLASS_SPEC_ORDER[classFile] then
        return
    end

    self.classMasteries = {}
    self.classTraits = {}

    if not self.Content:IsVisible() then
        self.Content:Show()
    end

    for tabID = 1, NUM_SPEC_TABS do
        local class = CharacterAdvancementUtil.GetClassDBCByFile(classFile)
        local spec = CHARACTER_ADVANCEMENT_CLASS_SPEC_ORDER[classFile][tabID]
        local classInfo = C_ClassInfo.GetSpecInfo(classFile, spec)
        self.Content:UpdateTabText(tabID, classInfo.Name)

        spec = CharacterAdvancementUtil.GetSpecDBCByFile(spec)

        for _, entry in ipairs(C_CharacterAdvancement.GetMasteriesByClass(class, spec)) do
            table.insert(self.classMasteries , entry)
        end

        for _, entry in ipairs(C_CharacterAdvancement.GetImplicitByClass(class, spec)) do
            table.insert(self.classTraits , entry)
        end
    end

    --self.Navigation2.Summary:OnDeSelected()
    --self.Navigation2.Browser:OnDeSelected()
    
    self:SelectClassInNavigation(classFile)

    if C_CVar.Get("caLastSpec") and STICKY_TABS[C_CVar.Get("caLastSpec")] then -- keep mastery selected
        specFile = C_CVar.Get("caLastSpec")
    end

    if specFile then
        if specFile == "SUMMARY" then
            self.Content:SelectTabID(SUMMARY_SPEC_TAB)
            return
        elseif specFile == "MASTERY" and next(self.classMasteries) then
            self.Content:SelectTabID(MASTERY_TAB)
            return
        elseif specFile == "TALENTBROWSER" then
            self.Content:SelectTabID(TALENT_BROWSER_TAB)
            return
        elseif specFile == "SPELLBROWSER" then
            self.Content:SelectTabID(SPELL_BROWSER_TAB)
            return
        else
            if C_Player:IsHero() then
                self.Content:SelectTabID(SPELL_BROWSER_TAB)
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
    end

    if C_Player:IsHero() then
        self.Content:SelectTabID(SPELL_BROWSER_TAB)
    else
        self.Content:SelectTabID(1) -- no valid spec found, auto select tab 1
    end
end

-- DOC: CharacterAdvancementMixin:SelectSpec
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
--   - tabID: an identifier (a number/string that points to a specific thing)
-- Output: Nothing (nil).
-- What it changes: shows/hides UI pieces, changes text on screen.
function CharacterAdvancementMixin:SelectSpec(tabID)
    if tabID == SUMMARY_SPEC_TAB then
        C_CVar.Set("caLastSpec", "SUMMARY")
    elseif tabID == MASTERY_TAB then
        C_CVar.Set("caLastSpec", "MASTERY")
    elseif tabID == TALENT_BROWSER_TAB then
        C_CVar.Set("caLastSpec", "TALENTBROWSER")
    elseif tabID == SPELL_BROWSER_TAB then
        C_CVar.Set("caLastSpec", "SPELLBROWSER")
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
-- Output: Nothing (nil).
-- What it changes: shows/hides UI pieces, changes text on screen.
function CharacterAdvancementMixin:SetupClassButtons()
    if self.ClassButtons then return end
    self.ClassButtons = {}

    if IsDefaultClass() then
        local class = C_Player:GetClass()
        local button = CreateFrame("Button", "$parentClassButton1", self.Navigation2, "CAClassButtonTemplate")
        button:SetPoint("TOP", 0, 0)
        button:SetClass(class)
        button:Hide() -- default classes dont need these to be shown
        self.ClassButtons[class] = button
        return
    end

    -- hero layout
    local prevButton

    -- TODO: Remove from here
    self.Navigation2.Browser = CreateFrame("Button", "$parentBrowser", self.Navigation2, "CAClassButtonTemplate")
    self.Navigation2.Browser.Icon:SetSize(30, 30)
    self.Navigation2.Browser.Icon:SetIcon("Interface\\Icons\\inv_misc_spyglass_02")
    self.Navigation2.Browser:SetScript("OnClick", function()
        self:SelectBrowser()
    end)
    self.Navigation2.Browser.Text:SetPoint("LEFT", self.Navigation2.Browser.Icon, "RIGHT", 6, 0)
    self.Navigation2.Browser.Icon.ClassPoints:Hide()
    self.Navigation2.Browser:SetText(BROWSE)
    self.Navigation2.Browser:SetPoint("TOP", 0, 4)

    prevButton = self.Navigation2.Browser

    for i = 1, #CHARACTER_ADVANCEMENT_CLASS_ORDER do  
        local class = CHARACTER_ADVANCEMENT_CLASS_ORDER[i]
        local button = CreateFrame("Button", "$parentClassButton"..i, self.Navigation2, "CAClassButtonTemplate")

        --if i == 1 then
            --button:SetPoint("TOP", 0, 0)
        --else
            button:SetPoint("TOP", prevButton, "BOTTOM", 0, 0)
        --end

        button:SetClass(class)
        button:Show()
        self.ClassButtons[class] = button

        prevButton = button
    end

    self.Navigation2.Summary = CreateFrame("Button", "$parentSummary", self.Navigation2, "CAClassButtonTemplate")
    self.Navigation2.Summary.Icon:SetSize(30, 30)
    self.Navigation2.Summary.Icon:SetIcon("Interface\\Icons\\classicon_hero")
    self.Navigation2.Summary.Icon.ClassPoints:Hide()
    self.Navigation2.Summary:SetScript("OnClick", function()
        self:SelectSummary()
    end)
    self.Navigation2.Summary.Text:SetPoint("LEFT", self.Navigation2.Summary.Icon, "RIGHT", 6, 0)
    self.Navigation2.Summary:SetText(ACHIEVEMENT_SUMMARY_CATEGORY)
    self.Navigation2.Summary:SetPoint("TOP", prevButton, "BOTTOM", 0, 0)
    --self.Navigation2.Summary:Hide()

    --[[else
        local spacing = 60
        local y_shift = 8
        if C_CharacterAdvancement.CanUseBrowser() then
            local width = (#CHARACTER_ADVANCEMENT_CLASS_ORDER + 3) / 2

            local browserButton = self.Navigation2.Browser
            browserButton:SetPoint("CENTER", (1 - width) * spacing, y_shift)
            browserButton:Show()

            for i = 1, #CHARACTER_ADVANCEMENT_CLASS_ORDER do 
                local class = CHARACTER_ADVANCEMENT_CLASS_ORDER[i]
                local button = CreateFrame("Button", "$parentClassButton"..i, self.Navigation2, "CAClassButtonTemplate")
                button:SetPoint("CENTER", ((i+1) - width) * spacing, y_shift)
                button:SetClass(class)
                button:Show()
                self.ClassButtons[class] = button
            end
            
            local summaryButton = self.Navigation2.Summary
            summaryButton:SetPoint("CENTER", ((#CHARACTER_ADVANCEMENT_CLASS_ORDER + 2) - width) * spacing, y_shift)
        else
            local width = (#CHARACTER_ADVANCEMENT_CLASS_ORDER + 2) / 2

            for i = 1, #CHARACTER_ADVANCEMENT_CLASS_ORDER do 
                local class = CHARACTER_ADVANCEMENT_CLASS_ORDER[i]
                local button = CreateFrame("Button", "$parentClassButton"..i, self.Navigation2, "CAClassButtonTemplate")
                button:SetPoint("CENTER", (i - width) * spacing, y_shift)
                button:SetClass(class)
                button:Show()
                self.ClassButtons[class] = button
            end

            local summaryButton = self.Navigation2.Summary
            summaryButton:SetPoint("CENTER", ((#CHARACTER_ADVANCEMENT_CLASS_ORDER + 1) - width) * spacing, y_shift)
        end
    end]]--
    --self.PetTalents:SetFrameLevel(self.Content:GetFrameLevel()+99)
end

-- DOC: CharacterAdvancementMixin:ShowBrowserTabs
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces.
function CharacterAdvancementMixin:ShowBrowserTabs()
    self:ShowClassTabs()

    self.Content.SearchBox:Show()
    self.Content.Filter:Show()

    self.Content:HideTabID(MASTERY_TAB)
    self.Content:HideTabID(SUMMARY_SPEC_TAB)
    --self.Content:HideTabs()
    --self.Content:ShowTabID(BROWSER_TAB)
    --self.Content:ShowTabID(SUMMARY_SPEC_TAB)
end

-- DOC: CharacterAdvancementMixin:ShowClassTabs
-- What this does: Hide part of the UI (or close a popup).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces.
function CharacterAdvancementMixin:ShowClassTabs()
    self.Content.SearchBox:Hide()
    self.Content.Filter:Hide()
    self.Content:ShowTabs()

    if C_Player:IsHero() then
        for tabID = 1, NUM_SPEC_TABS do
            self.Content:HideTabID(tabID)
        end

        local talentsEnabled = (UnitLevel("player") < 10) and not(C_Player:IsPrestiged())
    
        self.Content:SetTabEnabled(TALENT_BROWSER_TAB, not talentsEnabled, FEATURE_BECOMES_AVAILABLE_AT_LEVEL:format(10))

    else
        self.Content:HideTabID(SPELL_BROWSER_TAB)
        self.Content:HideTabID(TALENT_BROWSER_TAB)
    end

    self.Content:HideTabID(BROWSER_TAB)
    self.Content:HideTabID(SUMMARY_SPEC_TAB)

    if not next(self.classMasteries) then
        self.Content:HideTabID(MASTERY_TAB)
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

    if C_Player:IsHero() then
        self.Content:SetTabPoint("BOTTOMLEFT", self.Content, "TOPLEFT", 12, -1)
    else
        self.Content:SetTabPoint("BOTTOMLEFT", self.Content, "TOPLEFT", 56, -1)
    end

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
        if tabID == BROWSER_TAB then
            tab:ClearAndSetPoint(unpack(self.Content.tabPoint))
        elseif not(lastTab) then
            tab:ClearAndSetPoint(unpack(self.Content.tabPoint))
        elseif tabID == SUMMARY_SPEC_TAB then
            tab:ClearAndSetPoint("BOTTOMRIGHT", self.Content, "TOPRIGHT", -12, -1)
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

    tab = self.Content:AddTab("Tab"..SPELL_BROWSER_TAB)
    tab:SetFrameLevel(self.Content.NineSlice:GetFrameLevel()+2)
    tab:SetTextPadding(30)
    tab:SetTabText(ABILITIES)
    tab:UpdateSpellCounts()

    tab = self.Content:AddTab("Tab"..TALENT_BROWSER_TAB)
    tab:SetFrameLevel(self.Content.NineSlice:GetFrameLevel()+2)
    tab:SetTextPadding(30)
    tab:SetTabText(TALENTS)
    tab:UpdateSpellCounts()

    tab = self.Content:AddTab("Tab"..MASTERY_TAB)
    tab:SetFrameLevel(self.Content.NineSlice:GetFrameLevel()+2)
    tab:SetTextPadding(30)
    tab:SetTabText(MASTERY)
    tab:UpdateSpellCounts()

    tab = self.Content:AddTab("Tab"..SUMMARY_SPEC_TAB)
    tab:SetFrameLevel(self.Content.NineSlice:GetFrameLevel()+2)
    tab:SetTextPadding(30)
    tab:SetTabText(ACHIEVEMENT_SUMMARY_CATEGORY)
    tab:UpdateSpellCounts()

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
-- Output: A value used by other code (C_Player:IsHero() and not(C_GameMode:IsG...).
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
    header.NineSlice.Background:SetTexture("Interface\\FrameGeneral\\UI-Background-Marble", true, true)

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

    local footer = self.SideBar.SpellList.Footer
    footer.Background:SetAtlas("professions-specializations-background-footer", Const.TextureKit.IgnoreAtlasSize)
    footer.RarityFlyout:SetFrameLevel(footer:GetFrameLevel()+20)
end

-- DOC: CharacterAdvancementMixin:CanShowPrimaryStat
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called when other code needs a yes/no or a piece of information.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: A value used by other code (C_Player:IsHero() and not(C_GameMode:IsG...).
-- What it changes: shows/hides UI pieces, changes text on screen, uses Character Advancement API.
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

    local stat = C_PrimaryStat:GetActivePrimaryStat()
    local selectedStat = stat and C_PrimaryStat:GetInternalID(stat) or nil

    if not selectedStat then
        header.NineSlice.PrimaryStat1:SetNoStat()
        header.NineSlice.HintText:Show()
        header.NineSlice.SelectedStatText:Hide()
    else
        local _, _, _, name = C_PrimaryStat:GetPrimaryStatInfo(stat)
        header.NineSlice.SelectedStatText:Show()
        header.NineSlice.HintText:Hide()
        header.NineSlice.SelectedStatText:SetText(PRIMARY_STAT.." "..name)
        --header.NineSlice.SelectedStatText2:SetText(name)
        --button:Show()
        header.NineSlice.PrimaryStat1:SetEntry(C_CharacterAdvancement.GetEntryByInternalID(selectedStat))
    end

end

-- DOC: CharacterAdvancementMixin:RefreshCurrencies
-- What this does: Update what is shown on screen so it matches the latest game data.
-- When it runs: Called whenever the screen needs to be redrawn with fresh information.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, changes text on screen, uses Character Advancement API.
function CharacterAdvancementMixin:RefreshCurrencies()
    local aeCount, teCount
    if BuildCreatorUtil.IsPickingSpells() then
        local _, remainingAE, _, remainingTE = C_BuildEditor.GetEssenceForLevel(BuildCreatorUtil.GetPickLevel())
        aeCount = remainingAE
        teCount = remainingTE
    else
        aeCount = C_CharacterAdvancement.IsPending() and C_CharacterAdvancement.GetPendingRemainingAE() or GetItemCount(ItemData.ABILITY_ESSENCE)
        teCount = C_CharacterAdvancement.IsPending() and C_CharacterAdvancement.GetPendingRemainingTE() or GetItemCount(ItemData.TALENT_ESSENCE)
    end

    --aeCount = (aeCount == 0) and DISABLED_FONT_COLOR:WrapText(aeCount) or aeCount
    --teCount = (teCount == 0) and DISABLED_FONT_COLOR:WrapText(teCount) or teCount

    if C_Player:IsDefaultClass() then
        self.Content.HeaderSpells.Total:SetText("")
    else
        self.Content.HeaderSpells.Total:SetText(string.format(ABILITY_ESSENCE_TOTAL, aeCount))
    end
    self.Content.HeaderTalents.Total:SetText(string.format(TALENT_ESSENCE_TOTAL, teCount))

    self:RefreshClassButtons()

    if C_CVar.Get("caLastSpec") == "TALENTBROWSER" then
        self.Navigation2.Currency2.CurrencyTotal:SetText(aeCount)
        self.Navigation2.Currency2.item = ItemData.ABILITY_ESSENCE
        self.Navigation2.Currency2:SetIcon("Interface\\Icons\\inv_custom_abilityessence")
        
        self.Navigation2.Currency.item = ItemData.TALENT_ESSENCE
        self.Navigation2.Currency:SetIcon("Interface\\Icons\\inv_custom_talentessence")
        self.Navigation2.Crystals:SetAtlas("ca-navigation-illustration-gems-purple", Const.TextureKit.IgnoreAtlasSize)
        self.Navigation2.Currency.CurrencyName:SetText(string.upper("Talent Essence"))
        self.Navigation2.Currency.CurrencyTotal:SetText(teCount)

        self.Navigation2.Currency:SetScript("OnClick", function() self.Content:SelectTabID(TALENT_BROWSER_TAB) end)
        self.Navigation2.Currency2:SetScript("OnClick", function() self.Content:SelectTabID(SPELL_BROWSER_TAB) end)
    else
        self.Navigation2.Currency2.CurrencyTotal:SetText(teCount)
        self.Navigation2.Currency2.item = ItemData.TALENT_ESSENCE
        self.Navigation2.Currency2:SetIcon("Interface\\Icons\\inv_custom_talentessence")

        self.Navigation2.Currency.item = ItemData.ABILITY_ESSENCE
        --SetPortraitToTexture(self.Navigation2.IconBG, "Interface\\Icons\\inv_custom_abilityessence")
        self.Navigation2.Crystals:SetAtlas("ca-navigation-illustration-gems-blue", Const.TextureKit.IgnoreAtlasSize)
        self.Navigation2.Currency.CurrencyName:SetText(string.upper("Ability Essence"))
        self.Navigation2.Currency:SetIcon("Interface\\Icons\\inv_custom_abilityessence")
        self.Navigation2.Currency.CurrencyTotal:SetText(aeCount)

        self.Navigation2.Currency:SetScript("OnClick", function() self.Content:SelectTabID(SPELL_BROWSER_TAB) end)
        self.Navigation2.Currency2:SetScript("OnClick", function() self.Content:SelectTabID(TALENT_BROWSER_TAB) end)
    end
end

-- DOC: CharacterAdvancementMixin:RefreshSaveChangesButton
-- What this does: Update what is shown on screen so it matches the latest game data.
-- When it runs: Called whenever the screen needs to be redrawn with fresh information.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, changes text on screen, uses Character Advancement API.
function CharacterAdvancementMixin:RefreshSaveChangesButton()
    local button = self.Content.Footer.SaveChangesButton
    local undoButton = self.Content.Footer.UndoButton

    --button:SetText(SAVE_CHANGES)
    button.ErrorText:Hide()
    button.Shadow:Hide()

    if C_CharacterAdvancement.IsPending() then
        local canApply, reason, traversalError, entryID, entryRank, marksCost, goldCost = C_CharacterAdvancement.CanApplyPendingBuild()
        button:SetEnabled(canApply)
        button.YellowGlowLeft:Show()
        button.YellowGlowRight:Show()
        button.YellowGlowMiddle:Show()
        undoButton:Enable()

        if reason and not(canApply) and traversalError then
            local reason = _G[reason] or reason .. ": %s"
            local entry = C_CharacterAdvancement.GetEntryByInternalID(entryID)

            if entry then
                reason = reason:format(entry.Name, entryRank or "", traversalError and _G[traversalError] or traversalError or "")
                button.ErrorText:SetText(reason)
                button.ErrorText:Show()
                button.Shadow:Show()
            end
        end
    elseif CharacterAdvancementUtil.IsSwapping() then
        undoButton:Enable()
        button:Disable()
        button.YellowGlowLeft:Hide()
        button.YellowGlowRight:Hide()
        button.YellowGlowMiddle:Hide()
    else
        undoButton:Disable()
        button:Disable()
        button.YellowGlowLeft:Hide()
        button.YellowGlowRight:Hide()
        button.YellowGlowMiddle:Hide()
    end
end

-- DOC: CharacterAdvancementMixin:OnClickUndoChanges
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Runs for a UI callback named OnClickUndoChanges.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, uses Character Advancement API.
function CharacterAdvancementMixin:OnClickUndoChanges()
    PlaySound("gsCharacterCreationCancel")
    CharacterAdvancementUtil.MarkForSwap(nil)
    C_CharacterAdvancement.CancelPendingBuild()
end

function CharacterAdvancementMixin:OnClickSaveChanges()
    CharacterAdvancementUtil.ConfirmApplyPendingBuild()
end

-- DOC: CharacterAdvancementMixin:RefreshClassButtons
-- What this does: Update what is shown on screen so it matches the latest game data.
-- When it runs: Called whenever the screen needs to be redrawn with fresh information.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces.
function CharacterAdvancementMixin:RefreshClassButtons()
    -- Update Spell & Talent Counts
    for _, button in pairs(self.ClassButtons) do
        button:UpdateSpellCounts()
    end
end

function CharacterAdvancementMixin:Refresh(dontRefreshHeader)
    self.GateCounterSpells:ReleaseAll()
    self.GateCounterTalents:ReleaseAll()

    self:RefreshPrimaryStats()
    -- check for draft
    self.Navigation.DraftButton:SetShown(DraftUtil.HasAnyPicks())
    --self.Content.GatesInfo:Hide()

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
        rarityBar:AddCurrency(ItemData.MARK_OF_ASCENSION)
        rarityBar:AddCurrency(ItemData.SCROLL_OF_UNLEARNING)
    end

    spellBar:Update()
    talentBar:Update()
    rarityBar:Update()
    
    -- Update Spell List Footer
    local footer = self.SideBar.SpellList.Footer
    if not C_Player:IsHero() or C_GameMode:IsGameModeActive(Enum.GameMode.Draft, Enum.GameMode.WildCard) or not(C_Config.GetBoolConfig("CONFIG_CHARACTER_ADVANCEMENT_QUALITIES_ENABLED")) then
        footer.FlyoutButton:Hide()
        self:HideRarityFlyout()
        
        footer.RarityCurrencyBar:Show()
        footer.RarityCurrencyBar:Update()
    else
        footer.FlyoutButton:Show()
        footer.RarityCurrencyBar:Hide()
    end

    if C_Player:IsDefaultClass() then
        spellBar:Hide()
        talentBar:Hide()
    end
    
    -- Update Unlearn Buttons
    if IsDefaultClass("player") then
        local canReset, reason = C_CharacterAdvancement.CanUnlearnAllTalents()
        self.Content.Footer.ResetBuildButton:SetEnabled(canReset)
        if canReset then
            self.Content.Footer.ResetBuildButton.tooltipExtra = nil
        else
            self.Content.Footer.ResetBuildButton.tooltipExtra = CA_CANNOT_PURGE_TALENTS_S:format(_G[reason] or reason)
        end
    else
        local canReset, reason, traversalError, entryID, entryRank = C_CharacterAdvancement.CanClearPendingBuild(Const.CharacterAdvancement.ClearEverything)
        self.Content.Footer.ResetBuildButton:SetEnabled(canReset)
        if canReset then
            self.Content.Footer.ResetBuildButton.tooltipExtra = nil
        else
            reason = _G[reason] or reason or ""
            local entry = C_CharacterAdvancement.GetEntryByInternalID(entryID)
            if entry then
                reason = reason:format(entry.Name or entryID, entryRank or "", _G[traversalError] or traversalError or "")
            else
                reason = reason:format(entryID, entryRank or "", _G[traversalError] or traversalError or "")
            end
            self.Content.Footer.ResetBuildButton.tooltipExtra = CA_CANNOT_RESET_BUILD_S:format(reason)
        end
    end
    
    self:RefreshClassButtons()

    local classFile = C_CVar.Get("caLastClass")
    local class = CharacterAdvancementUtil.GetClassDBCByFile(classFile)

    if not dontRefreshHeader then
        self:RefreshHeaderTotal()
    end

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

            if specFile and (specFile ~= "SUMMARY") then
                --self.Content.GatesInfo:Show()

                self:RefreshGateInfo(class, CharacterAdvancementUtil.GetSpecDBCByFile(specFile))

                if specFile == "TALENTBROWSER" then
                    self.Content.TalentBrowser:RefreshGates()
                elseif specFile ~= "MASTERY" then
                    self.Content.ScrollChild.Talents:RefreshGates(classFile, specFile)
                end
            end
        end
    end

    self.Content:GetTabByID(SUMMARY_SPEC_TAB):UpdateSpellCounts()
    
    -- check pet talents
    if HasPetUI() and PetCanBeAbandoned() and (GetNumTalents(1, false, true) > 0) then
        self.PetTalents:Show()
        local unspentPoints = GetUnspentTalentPoints(false, true)
        local hasUnspentPoints = unspentPoints and unspentPoints > 0
        if hasUnspentPoints then
            self.PetTalents.Glow:Show()
            self.PetTalents.Glow.Animation:Play()
            self.PetTalents.UnspentPoints:SetCount(unspentPoints)
            self.PetTalents.UnspentPoints:Show()
        else
            self.PetTalents.Glow:Hide()
            self.PetTalents.Glow.Animation:Stop()
            self.PetTalents.UnspentPoints:Hide()
        end
    else
        self.PetTalents:Hide()
    end

    self:RefreshCurrencies()
end

-- DOC: CharacterAdvancementMixin:ForceUpdateRarityFlyout
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (nil).
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
-- TODO: Work with build creator?
-- DOC: CharacterAdvancementMixin:RefreshGateInfo
-- What this does: Update what is shown on screen so it matches the latest game data.
-- When it runs: Called whenever the screen needs to be redrawn with fresh information.
-- Inputs:
--   - self: the UI object this function belongs to
--   - class: a piece of information passed in by the caller
--   - spec: information about a specialization (spec) choice
--   - hardReset: a piece of information passed in by the caller
-- Output: Nothing (nil).
-- What it changes: shows/hides UI pieces, uses Character Advancement API.
function CharacterAdvancementMixin:RefreshGateInfo(class, spec, hardReset)
    self.Content.ScrollChild.Talents:RefreshGateInfo(class, spec, hardReset)

    local oldAmount = 0
    local oldSpec, oldClass

    if self.Content.HeaderSpells.CounterSpells then
        oldSpec = self.Content.HeaderSpells.CounterSpells.spec
        oldClass = self.Content.HeaderSpells.CounterSpells.class
        oldAmount = self.Content.HeaderSpells.CounterSpells.total
    end

    self.GateCounterSpells:ReleaseAll()
    self.GateCounterTalents:ReleaseAll()

    local treeTESpent = C_CharacterAdvancement.GetTabTEInvestment(class, spec, 0) or 0
    local classTESpent = C_CharacterAdvancement.GetClassPointInvestment(class, 0) or 0

    if C_Player:IsDefaultClass() then
        return
    end

    local counterSpells = self.GateCounterSpells:Acquire()
    counterSpells:Init("CLASS", classTESpent, class)
    --counterSpells.GateText:SetWidth(512)\
    if not oldSpec then
        counterSpells.AnimatedText:ClearAndSetPoint("LEFT", counterSpells.GateText, "RIGHT", 0, 0)
    end
    --counterSpells:ClearAndSetPoint("TOPLEFT", self.Content.HeaderSpells, "TOP", 0, -10)
    counterSpells:Show()
    counterSpells:CompareAndPlayAnim(oldAmount, oldClass, oldSpec)
    self.Content.HeaderSpells.CounterSpells = counterSpells

    --[[local counterTalents = self.GateCounterTalents:Acquire()
    counterTalents:Init("TAB", treeTESpent, class, spec)
    --counterTalents:ClearAndSetPoint("TOPLEFT", self.Content.HeaderTalents, "TOP", 0, -10)
    counterTalents:Show()

    self.Content.HeaderTalents.CounterTalents = counterTalents]]--
    --self.Content.GatesInfo:Refresh(class, spec, treeTESpent, classTESpent, totalTESpent, totalAESpent)
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
    --dprint("CharacterAdvancementMixin:FullUpdate")
    self:Refresh(true)
    self:LockTalentsFrameCheck()

    local spellHeight, talentHeight 
    local classFile = C_CVar.Get("caLastClass")
    local specFile = C_CVar.Get("caLastSpec")
    self.Content.HeaderSpells:Show()
    self.Content.HeaderTalents:Show()
    self.Content.ScrollChild.Talents:Show()
    self.Content.ScrollChild.Spells:ClearAndSetPoint("TOPLEFT")
    self.Content.ScrollChild.Spells:SetPoint("BOTTOMRIGHT",  self.Content.ScrollChild, "BOTTOM", 32, 0)
    self.Content.SpellsOverlay:SetPoint("CENTER", self.Content, "LEFT", 218, 20)
    self.Content.ScrollChild.Talents.LinePool:ReleaseAll()
    self.SpellPool:ReleaseAll()
    self.TalentPool:ReleaseAll()
    self.CompactSpellPool:ReleaseAll()
    self.SpellClassIconsPool:ReleaseAll()
    self.TalentClassIconsPool:ReleaseAll()
    self.CategoryPool:ReleaseAll()
    self.Content.TalentBrowser:Hide()

    if specFile == "SUMMARY" then
        for class, button in pairs(self.ClassButtons) do
            button:OnDeSelected()
        end

        self.Navigation2.Browser:OnDeSelected()
        self.Navigation2.Summary:OnSelected()

        if C_Player:IsHero() then
            self.Content:HideTabs()
        else
            self:ShowClassTabs()
        end

        self.Content.ScrollChild:Show()
        self.Content.AbilityBrowser:Hide()
        self.Content.SpellTagFrame:Hide()
        self.Content.BrowserArtwork:Hide()
        self.Content.SearchBox:Hide()
        self.Content.Filter:Hide()
        spellHeight = self:SetSpellSummary()
        talentHeight = self:SetTalentSummary()
        self.Content.Background:SetAtlas("ca-background", Const.TextureKit.UseAtlasSize)
        self.Content.SpellsOverlay:SetTexture(nil)
    elseif specFile == "MASTERY" then
        self:ShowClassTabs()
        self.Content.ScrollChild:Show()
        self.Content.AbilityBrowser:Hide()
        self.Content.SpellTagFrame:Hide()
        self.Content.BrowserArtwork:Hide()
        self.Content.SearchBox:Hide()
        self.Content.Filter:Hide()
        spellHeight = self:SetMasteriesAndTraits(classFile)
        talentHeight = 0

        self.Content.ScrollChild.Spells:ClearAndSetPoint("TOP")
        self.Content.ScrollChild.Spells:Show()
        self.Content.ScrollChild.Talents:Hide()
        self.Content.Background:SetAtlas("ca-background-browser", Const.TextureKit.UseAtlasSize)
        self.Content.SpellsOverlay:SetTexture("Interface\\Pictures\\artifactbook-"..classFile.."-cover")
        self.Content.SpellsOverlay:SetPoint("CENTER", 0, 20)
    elseif specFile == "SPELLBROWSER" then
        talentHeight = 0

        if classFile == "BROWSER" then
            for class, button in pairs(self.ClassButtons) do
                button:OnDeSelected()
            end

            --self.Content:SelectTabID(BROWSER_TAB)
            self.Navigation2.Summary:OnDeSelected()
            self.Navigation2.Browser:OnSelected()

            self.Content.HeaderSpells:Hide()
            self.Content.HeaderTalents:Hide()
            self:ShowBrowserTabs()
            self.Content.ScrollChild:Hide()
            self.Content.AbilityBrowser:Show()
            self.Content.BrowserArtwork:Show()
            self.Content.Background:SetAtlas("ca-background-browser", Const.TextureKit.UseAtlasSize)
            self.Content.SpellsOverlay:SetTexture(nil)
            --self:BrowserSearch()

            spellHeight = 0
        else

            local class = CharacterAdvancementUtil.GetClassDBCByFile(classFile)
            self:ShowClassTabs()
            self.Navigation2.Summary:OnDeSelected()
            self.Navigation2.Browser:OnDeSelected()
            self.Content.ScrollChild:Show()
            self.Content.AbilityBrowser:Hide()
            self.Content.SpellTagFrame:Hide()
            self.Content.BrowserArtwork:Hide()
            self.Content.SearchBox:Hide()
            self.Content.Filter:Hide()
            spellHeight = self:SetSpells(class, "None")
            --self.Content.ScrollChild.Spells:ClearAndSetPoint("TOP")
            self.Content.ScrollChild.Spells:Show()
            self.Content.ScrollChild.Talents:Hide()
            self.Content.Background:SetAtlas("ca-background-browser", Const.TextureKit.UseAtlasSize)
            self.Content.SpellsOverlay:SetTexture("Interface\\Pictures\\artifactbook-"..classFile.."-cover")
            self.Content.SpellsOverlay:SetPoint("CENTER", 0, 20)
        end
    elseif specFile == "TALENTBROWSER" then
        self:ShowClassTabs()

        self.Content.HeaderSpells:Hide()
        --self.Content.HeaderTalents:Hide()
        --self:ShowBrowserTabs()
        self.Content.ScrollChild:Hide()
        self.Content.AbilityBrowser:Hide()
        self.Content.BrowserArtwork:Hide()
        self.Content.Background:SetAtlas("ca-background-talents", Const.TextureKit.IgnoreAtlasSize)
        self.Content.SpellsOverlay:SetTexture(nil)
        spellHeight = 0 
        talentHeight = 0

        if classFile == "BROWSER" then
            for class, button in pairs(self.ClassButtons) do
                button:OnDeSelected()
            end
            self.Navigation2.Summary:OnDeSelected()
            self.Navigation2.Browser:OnSelected()

            self.Content.TalentBrowser:LoadElements(classFile, true)
            HybridScrollFrame_ScrollToIndex(self.Content.TalentBrowser.ScrollFrame, 1)

            self.Content:HideTabID(MASTERY_TAB)
            self.Content:HideTabID(SUMMARY_SPEC_TAB)
        else

            self.Content.TalentBrowser:LoadElements(classFile, false)
            self.Content.TalentBrowser:SetClass(classFile)
            self.Navigation2.Summary:OnDeSelected()
            self.Navigation2.Browser:OnDeSelected()
        end

        self.Content.TalentBrowser:Show()
    else
        self:ShowClassTabs()
        self.Content.ScrollChild:Show()
        self.Content.BrowserArtwork:Hide()
        self.Content.AbilityBrowser:Hide()
        self.Content.SpellTagFrame:Hide()

        local class = CharacterAdvancementUtil.GetClassDBCByFile(classFile)
        local spec = CharacterAdvancementUtil.GetSpecDBCByFile(specFile)

        local atlas = "ca-background-"..classFile
        
        if AtlasUtil:AtlasExists(atlas) then
            self.Content.Background:SetAtlas(atlas, Const.TextureKit.UseAtlasSize)
        end

        self.Content.SpellsOverlay:SetTexture("Interface\\Pictures\\artifactbook-"..classFile.."-cover")

        spellHeight = self:SetSpells(class, spec)
        talentHeight = self:SetTalents(class, spec)
    end
    
    self.Content.ScrollChild:SetHeight(math.max(spellHeight, talentHeight))


    self:RefreshHeaderTotal()
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
    local yStarting = self.normalFooter and 42 or 64

    if C_Player:IsDefaultClass() then 
        yStarting = 56
    end

    local height = self.Content:GetHeight()
    local button, x, y

    local columns = (spec == "None") and 4 or 3

    for i, entry in ipairs(C_CharacterAdvancement.GetSpellsByClass(class, spec, false)) do

        button = self.SpellPool:Acquire()
        button:SetEntry(entry)

        if C_Player:IsDefaultClass() then 
            x = 22 + ((i - 1) % columns) * 132
        else
            x = 56 + ((i - 1) % columns) * 182
        end

        --[[if (x > 154) then -- cut text at 3rd column of abilities a little
            button.Text:SetWidth(80)
        else
            button.Text:SetWidth(90)
        end]]--

        y = yStarting + (math.floor((i - 1) / columns) * 46)
        button:ClearAndSetPoint("TOPLEFT", self.Content.ScrollChild.Spells, "TOPLEFT", x, -y)
        button:Show()

        height = math.max(height, y + button:GetHeight())

        if entry.ID == self.LocateID then
            button:ShowLocation()
            self.LocateID = nil
        end
    end
    
    return height
end

-- DOC: CharacterAdvancementMixin:SetMasteriesAndTraits
-- What this does: Set a value on this UI element and update related visuals.
-- When it runs: Called when code needs to store a value and/or update the visuals.
-- Inputs:
--   - self: the UI object this function belongs to
--   - classFile: a piece of information passed in by the caller
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, changes text on screen.
function CharacterAdvancementMixin:SetMasteriesAndTraits(classFile)
    local class = CharacterAdvancementUtil.GetClassDBCByFile(classFile)

    local yStarting = (C_Player:IsDefaultClass() or self.normalFooter) and 42 or 64

    local masteries = self.classMasteries
    local traits = self.classTraits
    
    local height = self.Content:GetHeight()

    local buttons = {}
    local buttonsPerRow = 5
    local lastButton

    local spacing = 12
    local y = 0

    -- 
    -- load masteries
    --
    local masteryHeader = self.CategoryPool:Acquire()
    masteryHeader:SetPoint("TOP", 0, -yStarting)
    masteryHeader:SetSize(self.Content:GetWidth()-spacing*2, 32)
    masteryHeader:Show()
    masteryHeader.Title:SetText(CA_ABILITY_MASTERIES)
    masteryHeader.tooltipTitle = CA_ABILITY_MASTERIES
    masteryHeader.tooltipText = CA_ABILITY_MASTERIES_DESC
    masteryHeader.Description:SetText(CA_ABILITY_MASTERIES_DESC)

    yStarting = yStarting + (masteryHeader:GetHeight()*2) + spacing

    for i = 1 , #masteries do
        local entry = masteries[i]
        local button = self.SpellPool:Acquire()

        button:SetEntry(entry)
        button:Show()

        if lastButton then
            button:ClearAndSetPoint("LEFT", lastButton, "RIGHT", spacing, 0)
        end

        lastButton = button
        buttons[i] = button

        if entry.ID == self.LocateID then
            button:ShowLocation()
            self.LocateID = nil
        end
    end

    for i = 1, #masteries, buttonsPerRow do
        local button = buttons[i]
        local buttonsInLine = math.min( (#masteries) - (i-1), buttonsPerRow)

        local x = -((button:GetWidth()+spacing)/2)*(buttonsInLine-1)
        y = yStarting + (math.floor((i - 1) / buttonsPerRow) * 46)

        buttons[i]:ClearAndSetPoint("TOP", x, -y)
    end

    if not next(traits) then
        return y
    end

    --
    -- load traits
    --

    y = y + 46 + spacing*2

    local traitsHeader = self.CategoryPool:Acquire()
    traitsHeader:SetPoint("TOP", 0, -y)
    traitsHeader:SetSize(self.Content:GetWidth()-spacing*2, 32)
    traitsHeader:Show()
    traitsHeader.Title:SetText(CA_TRAITS_TITLE)
    traitsHeader.tooltipTitle = CA_TRAITS_TITLE
    traitsHeader.tooltipText = CA_TRAITS_DESC
    traitsHeader.Description:SetText(CA_TRAITS_DESC)

    yStarting = y + (traitsHeader:GetHeight()*2) + spacing

    for i = 1 , #traits do
        local entry = traits[i]
        local button = self.SpellPool:Acquire()

        button:SetEntry(entry)
        button:Show()

        if lastButton then
            button:ClearAndSetPoint("LEFT", lastButton, "RIGHT", spacing, 0)
        end

        lastButton = button
        buttons[i] = button

        if entry.ID == self.LocateID then
            button:ShowLocation()
            self.LocateID = nil
        end
    end

    for i = 1, #traits, buttonsPerRow do
        local button = buttons[i]
        local buttonsInLine = math.min( (#traits) - (i-1), buttonsPerRow)

        local x = -((button:GetWidth()+spacing)/2)*(buttonsInLine-1)
        y = yStarting + (math.floor((i - 1) / buttonsPerRow) * 46)

        buttons[i]:ClearAndSetPoint("TOP", x, -y)
    end

    return y
end

-- DOC: CharacterAdvancementMixin:SetTalents
-- What this does: Set a value on this UI element and update related visuals.
-- When it runs: Called when code needs to store a value and/or update the visuals.
-- Inputs:
--   - self: the UI object this function belongs to
--   - class: a piece of information passed in by the caller
--   - spec: information about a specialization (spec) choice
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, uses Character Advancement API.
function CharacterAdvancementMixin:SetTalents(class, spec)
    local talentFrame = self.Content.ScrollChild.Talents
    wipe(talentFrame.NodeMap)
    wipe(talentFrame.ConnectedNodes)
    wipe(talentFrame.FilledNodes)

    talentFrame.shift = CA_USE_GATES_DEBUG and GATES_TALENT_SHIFT or 0

    local yStarting = self.normalFooter and 42 or 64

    if C_Player:IsDefaultClass() then 
        yStarting = 56
    end

    if CA_USE_GATES_DEBUG then
        self:RefreshGateInfo(class, spec, true) -- we need to scan it before to button properly update on SetEntry
    end

    local height = self.Content:GetHeight()
    local button, column, row, x, y
    for i, entry in ipairs(C_CharacterAdvancement.GetTalentsByClass(class, spec, false)) do
        button = self.TalentPool:Acquire()

        if CA_USE_GATES_DEBUG then
            -- work with gates
            local gate = talentFrame:DefineGatesForButton(entry.Row+1)

            talentFrame:DefineGateTopLeftNode(gate, entry, button)
            self:RefreshGateInfo(class, spec) -- TODO: needs better optimization we need to scan it before to button properly update on SetEntry

            button.gate = gate
        else
            button.gate = nil
        end
        
        button:SetEntry(entry)
        column = entry.Column - 1
        row = entry.Row
        talentFrame.FilledNodes[column] = talentFrame.FilledNodes[column] or {}
        talentFrame.FilledNodes[column][row] = true

        x = -58-26 + column * 52 + (talentFrame.shift or 0)-- -26 to center 4 rows under essence text 
        y = yStarting + row * 44

        button:ClearAndSetPoint("TOP", talentFrame, "TOP", x, -y)
        button:Show()

        if entry.ID == self.LocateID then
            button:ShowLocation()
            self.LocateID = nil
        end

        talentFrame.NodeMap[entry.ID] = { button = button, column = column, row = row }

        -- connections are backwards
        -- the child node references the parent node
        
        -- something else is a child of this node but couldnt find info about this parent node
        if talentFrame.ConnectedNodes[entry.ID] and not talentFrame.ConnectedNodes[entry.ID].button then
            talentFrame.ConnectedNodes[entry.ID].button = button
            talentFrame.ConnectedNodes[entry.ID].column = column
            talentFrame.ConnectedNodes[entry.ID].row = row
        end

        for _, parentNodeID in pairs(entry.ConnectedNodes) do
            -- parent node doesnt already exist 
            if not talentFrame.ConnectedNodes[parentNodeID] then
                if talentFrame.NodeMap[parentNodeID] then -- already discovered, connect parent.
                    talentFrame.ConnectedNodes[parentNodeID] = talentFrame.NodeMap[parentNodeID]
                else
                    talentFrame.ConnectedNodes[parentNodeID] = {}
                end
            end

            local parentNode = talentFrame.ConnectedNodes[parentNodeID]

            -- attach ourself as a child
            if not parentNode.targets then
                parentNode.targets = {}
            end
            
            tinsert(parentNode.targets, { column = column, row = row, button = button })
        end

        height = math.max(height, y + button:GetHeight())
    end

    if CA_USE_GATES_DEBUG then
        talentFrame:RefreshGates(class, spec)
    end
    
    talentFrame:DrawConnectedNodes()
    
    return height
end

-- DOC: CharacterAdvancementMixin:SetSpellSummary
-- What this does: Set a value on this UI element and update related visuals.
-- When it runs: Called when code needs to store a value and/or update the visuals.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: A value used by other code (height).
-- What it changes: shows/hides UI pieces, changes text on screen, uses Character Advancement API.
function CharacterAdvancementMixin:SetSpellSummary()
    local yStarting = (C_Player:IsDefaultClass() or self.normalFooter) and 42 or 64

    local height = self.Content:GetHeight()
    local button, x, y
    local index = 1

    for _, class in ipairs(CHARACTER_ADVANCEMENT_CLASS_ORDER) do
        local knownSpells = C_CharacterAdvancement.GetKnownSpellEntriesForClass(CharacterAdvancementUtil.GetClassDBCByFile(class), "None")
        if #knownSpells > 0 then
            -- make new row
            local remainder = (index - 1) % NUM_SPELLS_PER_ROW_SUMMARY
            if remainder ~= 0 then
                index = index + (NUM_SPELLS_PER_ROW_SUMMARY - remainder)
            end

            local classIcon = self.SpellClassIconsPool:Acquire()
            x = 22 + ((index - 1) % NUM_SPELLS_PER_ROW_SUMMARY) * 44
            y = yStarting + (math.floor((index - 1) / NUM_SPELLS_PER_ROW_SUMMARY) * 48)
            classIcon.class = class
            classIcon:SetIcon("Interface\\Icons\\classicon_" .. class:lower())
            classIcon.Count:SetText(LOCALIZED_CLASS_NAMES_MALE[class:upper()] or "")
            classIcon:ClearAndSetPoint("TOPLEFT", self.Content.ScrollChild.Spells, "TOPLEFT", 22, -y-4)
            classIcon:Show()
            index = index + 1

            for _, entry in ipairs(knownSpells) do
                button = self.CompactSpellPool:Acquire()
                x = 22 + ((index - 1) % NUM_SPELLS_PER_ROW_SUMMARY) * 44
                y = yStarting + (math.floor((index - 1) / NUM_SPELLS_PER_ROW_SUMMARY) * 48)
                button:SetEntry(entry)
                button:ClearAndSetPoint("TOPLEFT", self.Content.ScrollChild.Spells, "TOPLEFT", x, -y)
                button:Show()
                height = math.max(height, y + button:GetHeight())
                index = index + 1
            end
        end
    end

    return height
end

-- DOC: CharacterAdvancementMixin:SetTalentSummary
-- What this does: Set a value on this UI element and update related visuals.
-- When it runs: Called when code needs to store a value and/or update the visuals.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: A value used by other code (height).
-- What it changes: shows/hides UI pieces, changes text on screen, uses Character Advancement API.
function CharacterAdvancementMixin:SetTalentSummary()
    local height = self.Content:GetHeight()
    
    local button, x, y
    local yStarting = (C_Player:IsDefaultClass() or self.normalFooter) and 42 or 64
    
    local index = 1

    for _, class in ipairs(CHARACTER_ADVANCEMENT_CLASS_ORDER) do
        local knownTalents = C_CharacterAdvancement.GetKnownTalentEntriesForClass(CharacterAdvancementUtil.GetClassDBCByFile(class), "None")
        if #knownTalents > 0 then
            -- make new row
            local remainder = (index - 1) % NUM_TALENTS_PER_ROW_SUMMARY
            if remainder ~= 0 then
                index = index + (NUM_TALENTS_PER_ROW_SUMMARY - remainder)
            end

            local classIcon = self.TalentClassIconsPool:Acquire()
            x = 22 + ((index - 1) % NUM_TALENTS_PER_ROW_SUMMARY) * 48
            y = yStarting + (math.floor((index - 1) / NUM_TALENTS_PER_ROW_SUMMARY) * 48)
            classIcon.class = class
            classIcon:SetIcon("Interface\\Icons\\classicon_" .. class:lower())
            classIcon.Count:SetText(LOCALIZED_CLASS_NAMES_MALE[class:upper()] or "")
            classIcon:ClearAndSetPoint("TOPLEFT", self.Content.ScrollChild.Talents, "TOPLEFT", 22, -y-4)
            classIcon:Show()
            index = index + 1
            
            for _, entry in ipairs(knownTalents) do
                button = self.TalentPool:Acquire()
                button:SetEntry(entry)
                x = 22 + ((index - 1) % NUM_TALENTS_PER_ROW_SUMMARY) * 48
                y = yStarting + (math.floor((index - 1) / NUM_TALENTS_PER_ROW_SUMMARY) * 48)
                button:ClearAndSetPoint("TOPLEFT", self.Content.ScrollChild.Talents, "TOPLEFT", x, -y)
                button:Show()
                height = math.max(height, y + button:GetHeight())
                index = index + 1
            end
        end
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
        elseif C_CharacterAdvancement.IsTalentAbilitySpellID(dropdown.spellID) then
            nextSpellID = dropdown.spellID
        elseif not C_Player:IsDefaultClass() then -- default classes cannot pick spells
            nextSpellID = dropdown.spellID
        end

        -- if next talent or current spell isnt known then show add button
        if nextSpellID and not C_BuildEditor.DoesBuildHaveSpellID(nextSpellID) then
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
            -- What this does: Do a specific piece of work related to 'func'.
            -- When it runs: Called by other code when needed.
            -- Inputs: none
            -- Output: Nothing (it mainly updates state and/or the UI).
            -- What it changes: updates UI/state.
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
        -- swap
        if CharacterAdvancementUtil.IsSwapping() then
            info = UIDropDownMenu_CreateInfo()
            info.notCheckable = true
            info.disabled = not CharacterAdvancementUtil.IsSwapSuggestion(dropdown.targetEntry.ID)
            info.text = (CA_SWAP_BLUE):format(LinkUtil:GetSpellLinkInternalID(CharacterAdvancementUtil.IsSwapping()), LinkUtil:GetSpellLinkInternalID(dropdown.targetEntry.ID))
            -- DOC: info.func
            -- What this does: Call into the Character Advancement system (server/game API) and update the UI with the result.
            -- When it runs: Called by other code when needed.
            -- Inputs: none
            -- Output: Nothing (it mainly updates state and/or the UI).
            -- What it changes: uses Character Advancement API.
            info.func = function()
                CharacterAdvancementUtil.AttemptSwap(dropdown.targetEntry.ID)
            end
            UIDropDownMenu_AddButton(info, level)
        end

        -- learn
        info = UIDropDownMenu_CreateInfo()
        info.notCheckable = true
        info.text = LEARN
        if C_CVar.GetBool("previewCharacterAdvancementChanges") then
            local numRanks = 1
            info.disabled = not C_CharacterAdvancement.CanAddByEntryID(dropdown.targetEntry.ID, numRanks)
            -- DOC: info.func
            -- What this does: Call into the Character Advancement system (server/game API) and update the UI with the result.
            -- When it runs: Called by other code when needed.
            -- Inputs: none
            -- Output: Nothing (it mainly updates state and/or the UI).
            -- What it changes: uses Character Advancement API.
            info.func = function()
                CharacterAdvancementUtil.MarkForSwap(nil)
                C_CharacterAdvancement.AddByEntryID(dropdown.targetEntry.ID, numRanks)
            end
        else
            info.disabled = not C_CharacterAdvancement.CanLearnID(dropdown.targetEntry.ID)
            info.func = function()
                CharacterAdvancementUtil.ConfirmOrLearnID(dropdown.targetEntry.ID)
            end
        end
        UIDropDownMenu_AddButton(info, level)

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

    -- locate option
    if (dropdown.parent:GetParent() ~= self.Content.ScrollChild.Spells) and (dropdown.parent:GetParent():GetParent() ~= self.Content.TalentBrowser.ScrollFrame.scrollChild) then
        info = UIDropDownMenu_CreateInfo()
        info.notCheckable = true
        info.text = LOCATE
        -- DOC: info.func
        -- What this does: Call into the Character Advancement system (server/game API) and update the UI with the result.
        -- When it runs: Called by other code when needed.
        -- Inputs: none
        -- Output: Nothing (it mainly updates state and/or the UI).
        -- What it changes: uses Character Advancement API.
        info.func = function()
            self:Locate(dropdown.targetEntry)
            if C_CharacterAdvancement.IsMastery(dropdown.targetEntry.Spells[1]) then
                self:SetSearch(dropdown.targetEntry.Name)
            end
        end
        UIDropDownMenu_AddButton(info, level)
    end
    
    -- unlearn
    info = UIDropDownMenu_CreateInfo()
    info.notCheckable = true
    info.text = UNLEARN
    if C_CVar.GetBool("previewCharacterAdvancementChanges") then
        local canUnlearn, reason = C_CharacterAdvancement.CanRemoveByEntryID(dropdown.targetEntry.ID)
        info.disabled = not canUnlearn
        -- DOC: info.func
        -- What this does: Show part of the UI (or switch which panel is visible).
        -- When it runs: Called by other code when needed.
        -- Inputs: none
        -- Output: Nothing (nil).
        -- What it changes: uses Character Advancement API.
        info.func = function()
            CharacterAdvancementUtil.MarkForSwap(nil)
            C_CharacterAdvancement.RemoveByEntryID(dropdown.targetEntry.ID)
        end
        info.tooltip = _G[reason] or reason
    else
        info.disabled = not C_CharacterAdvancement.CanUnlearnID(dropdown.targetEntry.ID)
        info.func = function()
            CharacterAdvancementUtil.ConfirmOrUnlearnID(dropdown.targetEntry.ID)
        end
    end
    UIDropDownMenu_AddButton(info, level)

    -- swap suggestions 
    local hasSwapButton = false
    local swapSuggestions = nil
    local isInvertedSwap = false

    if C_CharacterAdvancement.IsKnownSpellID(dropdown.spellID) then
        -- swap
        if C_CVar.GetBool("previewCharacterAdvancementChanges") then
            hasSwapButton = true
            swapSuggestions = C_CharacterAdvancement.GetEntriesAvailableForSwap({Entry = dropdown.targetEntry.ID, NewCARank = 0})

            info = UIDropDownMenu_CreateInfo()
            info.notCheckable = true
            info.text = CA_MARK_FOR_SWAP
            
            if (swapSuggestions and next(swapSuggestions)) then
                info.disabled = false 
            else
                 info.disabled = true
            end
        end
    else
        if C_CVar.GetBool("previewCharacterAdvancementChanges") then
            hasSwapButton = true
            swapSuggestions = C_CharacterAdvancement.GetEntriesAvailableForTrade({Entry = dropdown.targetEntry.ID, NewCARank = #dropdown.targetEntry.Spells})
            isInvertedSwap = true

            info = UIDropDownMenu_CreateInfo()
            info.notCheckable = true
            info.text = SHOW_POSSIBLE_SWAPS
        end
    end

    if hasSwapButton then
        if (swapSuggestions and next(swapSuggestions)) then
            info.disabled = false 
        else
            info.disabled = true
        end

        -- DOC: info.func
        -- What this does: Show part of the UI (or switch which panel is visible).
        -- When it runs: Called by other code when needed.
        -- Inputs: none
        -- Output: Nothing (nil).
        -- What it changes: uses Character Advancement API.
        info.func = function()
            if C_CharacterAdvancement.IsPending() then
                StaticPopup_Show("CONFIRM_LEAVING_PENDING", nil, nil, {dropdown.targetEntry.ID, swapSuggestions})
                return
            end

            CharacterAdvancementUtil.MarkForSwap(dropdown.targetEntry.ID, swapSuggestions, isInvertedSwap) 
        end
        UIDropDownMenu_AddButton(info, level)
    end

    -- browser specials
    if self.Content.AbilityBrowser:IsVisible() then
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
            -- What this does: Call into the Character Advancement system (server/game API) and update the UI with the result.
            -- When it runs: Called by other code when needed.
            -- Inputs: none
            -- Output: Nothing (it mainly updates state and/or the UI).
            -- What it changes: uses Character Advancement API.
            info.func = function()
                C_CharacterAdvancement.ClearSuggestionContextOverrides()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end
    
    if not BuildCreatorUtil.IsPickingSpells() then
        if C_AccountInfo.GetGMLevel() > 0 then
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
            -- What this does: Hide part of the UI (or close a popup).
            -- When it runs: Called by other code when needed.
            -- Inputs: none
            -- Output: Nothing (it mainly updates state and/or the UI).
            -- What it changes: shows/hides UI pieces.
            info.func = function()
                SendChatMessage(format(".ca2 player removeentry %s %s", UnitName("player"), dropdown.targetEntry.ID))
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
    self.SpellDropDownMenu.parent = spellButton
    self.SpellDropDownMenu.targetEntry = spellButton.entry
    self.SpellDropDownMenu.spellID = spellButton.spellID
    if not spellButton.entry then return end
    relativeRegion = relativeRegion or spellButton

    if spellButton.entry.Row and (spellButton.entry.Row >= 8) then
        UIDropDownMenu_SetAnchor(self.SpellDropDownMenu, 0, 0, "BOTTOMRIGHT", relativeRegion, "TOPLEFT");
    else
        UIDropDownMenu_SetAnchor(self.SpellDropDownMenu, 0, 0, "TOPLEFT", relativeRegion, "BOTTOMLEFT")
    end
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

    if (maxOffset == 0 and (C_CVar.Get("caLastSpec") ~= "BROWSER")) or (C_CVar.Get("caLastSpec") == "TALENTBROWSER") then
        self.Content:SetWidth(678)
        self.Content:SetWidth(802)
        self.SideBar:SetPoint("TOPLEFT", self.Content, "TOPRIGHT", 1, 10)
        self.Content.scrollbar:Hide()
        self.Content.ScrollChild.Talents:SetWidth(369)
        self.Content.LockTalentsFrame:SetWidth(370)
        self.Content.ScrollBackground:Hide()
        self.Content.ScrollTop:Hide()
        self.Content.ScrollBottom:Hide()
        self.Content.ScrollMiddle:Hide()
        self.Content.Footer:SetPoint("TOPRIGHT", self.Content, "BOTTOMRIGHT", 0, 0)
    else
        self.Content:SetWidth(678-SCROLL_X_SHIFT)
        self.Content:SetWidth(802-SCROLL_X_SHIFT)
        self.SideBar:SetPoint("TOPLEFT", self.Content, "TOPRIGHT", 1+SCROLL_X_SHIFT, 10)
        self.Content.scrollbar:Show()
        self.Content.ScrollChild.Talents:SetWidth(369-SCROLL_X_SHIFT)
        self.Content.LockTalentsFrame:SetWidth(360)
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
    elseif self.Content.AbilityBrowser:IsVisible() then
        self:BrowserSearch()
    else
        self:Refresh()
    end

    self:RefreshCurrencies()
    self:RefreshSaveChangesButton()
    self:RefreshPrimaryStats()
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
    elseif self.Content.AbilityBrowser:IsVisible() then
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
-- What this does: Call into the Character Advancement system (server/game API) and update the UI with the result.
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (nil).
-- What it changes: uses Character Advancement API.
function CharacterAdvancementMixin:PLAYER_REGEN_DISABLED()
    self:FullUpdate()
end

function CharacterAdvancementMixin:PLAYER_REGEN_ENABLED()
    self:FullUpdate()
end

-- DOC: CharacterAdvancementMixin:PLAYER_LEVEL_UP
-- What this does: Call into the Character Advancement system (server/game API) and update the UI with the result.
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (nil).
-- What it changes: uses Character Advancement API.
function CharacterAdvancementMixin:PLAYER_LEVEL_UP()
    self:FullUpdate()
    self:RefreshCurrencies()
end 

function CharacterAdvancementMixin:TOKEN_UPDATED()
    self.SideBar.SpecList:RefreshScrollFrame()
    self.SideBar.SpellList.Footer.RarityCurrencyBar:Update()
end

-- DOC: CharacterAdvancementMixin:CHARACTER_ADVANCEMENT_BUILD_LEVEL_UPDATED
-- What this does: Call into the Character Advancement system (server/game API) and update the UI with the result.
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (nil).
-- What it changes: uses Character Advancement API.
function CharacterAdvancementMixin:CHARACTER_ADVANCEMENT_BUILD_LEVEL_UPDATED()
    dprint("CHARACTER_ADVANCEMENT_BUILD_LEVEL_UPDATED")
    -- currency bars update themselves
    self:RefreshCurrencies()
end 

function CharacterAdvancementMixin:CURRENCY_DISPLAY_UPDATE()
    -- currency bars update themselves
    self:RefreshCurrencies()
end 

-- DOC: CharacterAdvancementMixin:CHARACTER_ADVANCEMENT_SUGGESTIONS_UPDATED
-- What this does: Call into the Character Advancement system (server/game API) and update the UI with the result.
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (nil).
-- What it changes: uses Character Advancement API.
function CharacterAdvancementMixin:CHARACTER_ADVANCEMENT_SUGGESTIONS_UPDATED()
    if self.Content.AbilityBrowser:IsVisible() then
        self:BrowserSearch()
    end
end

function CharacterAdvancementMixin:SPELL_TAGS_CHANGED()
    self:CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED()
end

-- DOC: CharacterAdvancementMixin:SPELL_TAG_TYPES_CHANGED
-- What this does: Call into the Character Advancement system (server/game API) and update the UI with the result.
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (nil).
-- What it changes: uses Character Advancement API.
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

-- DOC: CharacterAdvancementMixin:CHARACTER_ADVANCEMENT_LEARN_RESULT
-- What this does: Call into the Character Advancement system (server/game API) and update the UI with the result.
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
--   - success: a piece of information passed in by the caller
--   - result: a piece of information passed in by the caller
--   - entryID: an identifier (a number/string that points to a specific thing)
--   - rank: a piece of information passed in by the caller
-- Output: Nothing (nil).
-- What it changes: uses Character Advancement API.
function CharacterAdvancementMixin:CHARACTER_ADVANCEMENT_LEARN_RESULT(success, result, entryID, rank)
    if success then
        return
    end
    
    local entry = C_CharacterAdvancement.GetEntryByInternalID(entryID)
    
    local reason = _G[result] or result .. ": %s"
    if not entry then
        local message = reason:format(UNKNOWN_OBJECT)
        message = RED_FONT_COLOR:WrapText(message)

        SendSystemMessage(message)
        return
    end
    
    local message = reason:format(entry.Name)
    UIErrorsFrame:AddMessage(message, 1.0, 0.1, 0.1, 1.0)
    message = RED_FONT_COLOR:WrapText(message)
    
    SendSystemMessage(message)
end

-- DOC: CharacterAdvancementMixin:CHARACTER_ADVANCEMENT_UNLEARN_RESULT
-- What this does: Call into the Character Advancement system (server/game API) and update the UI with the result.
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
--   - success: a piece of information passed in by the caller
--   - result: a piece of information passed in by the caller
--   - entryID: an identifier (a number/string that points to a specific thing)
-- Output: Nothing (nil).
-- What it changes: uses Character Advancement API.
function CharacterAdvancementMixin:CHARACTER_ADVANCEMENT_UNLEARN_RESULT(success, result, entryID)
    if success then
        return
    end

    local entry = C_CharacterAdvancement.GetEntryByInternalID(entryID)

    local reason = _G[result] or result .. ": %s"
    if not entry then
        local message = reason:format(UNKNOWN_OBJECT)
        message = RED_FONT_COLOR:WrapText(message)

        SendSystemMessage(message)
        return
    end

    local message = reason:format(entry.Name)
    UIErrorsFrame:AddMessage(message, 1.0, 0.1, 0.1, 1.0)
    message = RED_FONT_COLOR:WrapText(message)

    SendSystemMessage(message)
end


-- DOC: CharacterAdvancementMixin:CHARACTER_ADVANCEMENT_PURGE_ABILITIES_RESULT
-- What this does: Call into the Character Advancement system (server/game API) and update the UI with the result.
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
--   - success: a piece of information passed in by the caller
--   - result: a piece of information passed in by the caller
-- Output: Nothing (nil).
-- What it changes: uses Character Advancement API.
function CharacterAdvancementMixin:CHARACTER_ADVANCEMENT_PURGE_ABILITIES_RESULT(success, result)
    if success then
        return
    end

    local message = _G[result] or result
    UIErrorsFrame:AddMessage(message, 1.0, 0.1, 0.1, 1.0)
    message = RED_FONT_COLOR:WrapText(message)

    SendSystemMessage(message)
end 

-- DOC: CharacterAdvancementMixin:CHARACTER_ADVANCEMENT_PURGE_TALENTS_RESULT
-- What this does: Call into the Character Advancement system (server/game API) and update the UI with the result.
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
--   - success: a piece of information passed in by the caller
--   - result: a piece of information passed in by the caller
-- Output: Nothing (nil).
-- What it changes: uses Character Advancement API.
function CharacterAdvancementMixin:CHARACTER_ADVANCEMENT_PURGE_TALENTS_RESULT(success, result)
    if success then
        return
    end

    local message = _G[result] or result
    UIErrorsFrame:AddMessage(message, 1.0, 0.1, 0.1, 1.0)
    message = RED_FONT_COLOR:WrapText(message)

    SendSystemMessage(message)
end 

-- DOC: CharacterAdvancementMixin:CHARACTER_ADVANCEMENT_UPDATE_ENTRIES_RESULT
-- What this does: Call into the Character Advancement system (server/game API) and update the UI with the result.
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
--   - success: a piece of information passed in by the caller
--   - result: a piece of information passed in by the caller
--   - traversalResult: a piece of information passed in by the caller
--   - entryID: an identifier (a number/string that points to a specific thing)
--   - rank: a piece of information passed in by the caller
-- Output: Nothing (nil).
-- What it changes: uses Character Advancement API.
function CharacterAdvancementMixin:CHARACTER_ADVANCEMENT_UPDATE_ENTRIES_RESULT(success, result, traversalResult, entryID, rank)
    if success then
        return
    end

    local entry = C_CharacterAdvancement.GetEntryByInternalID(entryID)

    local reason = _G[result] or result .. ": %s"
    local message

    if not entry then
        message = reason:format(UNKNOWN_OBJECT)
    else
        message = reason:format(entry.Name, rank or "", traversalResult and _G[traversalResult] or traversalResult or "")
    end

    UIErrorsFrame:AddMessage(message, 1.0, 0.1, 0.1, 1.0)
    message = RED_FONT_COLOR:WrapText(message)
    SendSystemMessage(message)
end
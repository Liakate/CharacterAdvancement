-- GUIDE: What is this file?
-- Purpose: Logic for the CoA Talents UI (specialization/talent tree viewing and interactions).
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

CoATalentFrameMixin = {}
CoATalentFrameMixin.OnEvent = OnEventToMethod

-- DOC: CoATalentFrameMixin:OnLoad
-- What this does: Sets up this UI element: prepares data, connects events, and sets initial visuals.
-- When it runs: Runs once when this UI element is created/loaded.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, listens for game events, uses Character Advancement API.
function CoATalentFrameMixin:OnLoad()
    self.class = select(2, UnitClass("player"))
    PortraitFrame_SetTitle(self, COA_CA_TITLE)
    self.CloseButton:SetScript("OnClick", function()
        HideUIPanel(Collections)
    end)
end 

-- DOC: CoATalentFrameMixin:OnShow
-- What this does: Prepares the UI right before the player sees it (updates text, lists, or buttons).
-- When it runs: Runs each time this UI element becomes visible.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, listens for game events, uses Character Advancement API.
function CoATalentFrameMixin:OnShow()
    self:RegisterEvent("ASCENSION_CA_SPECIALIZATION_ACTIVE_ID_CHANGED")
    StaticPopup_Hide("CLOSE_CHARACTER_ADVANCEMENT_UNSAVED_PENDING_CHANGES")
    self:UpdateActiveSpec()
end 

function CoATalentFrameMixin:OnHide()
    self:UnregisterEvent("ASCENSION_CA_SPECIALIZATION_ACTIVE_ID_CHANGED")

    if C_CharacterAdvancement.IsPending() then
        StaticPopup_Show("CLOSE_CHARACTER_ADVANCEMENT_UNSAVED_PENDING_CHANGES")
    end
end

-- DOC: CoATalentFrameMixin:UpdateActiveSpec
-- What this does: Update what is shown on screen so it matches the latest game data.
-- When it runs: Called after this UI registers for events, or when something changes that needs a refresh.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, listens for game events, uses Character Advancement API.
function CoATalentFrameMixin:UpdateActiveSpec()
    local activeSpecID = C_CharacterAdvancement.GetActiveChrSpec()
    self.activeSpecID = activeSpecID
    self:UpdatePortrait(activeSpecID)
    if not activeSpecID then
        self:ShowSpecView()
    else
        self:ShowTreeView()
        self.TreeView:SetSpecID(activeSpecID)
    end
end

-- DOC: CoATalentFrameMixin:UpdatePortrait
-- What this does: Update what is shown on screen so it matches the latest game data.
-- When it runs: Called after this UI registers for events, or when something changes that needs a refresh.
-- Inputs:
--   - self: the UI object this function belongs to
--   - activeSpecID: an identifier (a number/string that points to a specific thing)
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, changes text on screen, listens for game events, uses Character Advancement API.
function CoATalentFrameMixin:UpdatePortrait(activeSpecID)
    activeSpecID = activeSpecID or C_CharacterAdvancement.GetActiveChrSpec()
    local icon
    if activeSpecID then
        local specInfo = C_ClassInfo.GetSpecInfoByID(activeSpecID)
        if specInfo and specInfo.SpecFilename then
            icon = "Interface\\Icons\\"..specInfo.SpecFilename
        end
    end

    if icon then
        PortraitFrame_SetIcon(self, icon)
    else
        PortraitFrame_SetClassIcon(self, self.class)
    end
end

-- DOC: CoATalentFrameMixin:ShowTreeView
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called after this UI registers for events, or when something changes that needs a refresh.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, changes text on screen, listens for game events, uses Character Advancement API.
function CoATalentFrameMixin:ShowTreeView()
    self.SpecView:Hide()
    if self.TreeView:IsShown() then
        self.TreeView:MarkTreesDirty()
    else
        self.TreeView:Show()
    end
end 

-- DOC: CoATalentFrameMixin:ShowSpecView
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called after this UI registers for events, or when something changes that needs a refresh.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, changes text on screen, listens for game events, uses Character Advancement API.
function CoATalentFrameMixin:ShowSpecView()
    self.TreeView:Hide()
    self.SpecView:Show()
end 

function CoATalentFrameMixin:ChangeSpecID(specID)
    self.expectingNewSpec = true
    self:RegisterEvent("CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED")
    C_CharacterAdvancement.SwitchActiveChrSpec(specID)
end 

-- DOC: CoATalentFrameMixin:CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Runs when the 'CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED' event happens (it is registered elsewhere in this file).
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (nil).
-- What it changes: shows/hides UI pieces, changes text on screen, listens for game events, uses Character Advancement API.
function CoATalentFrameMixin:CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED()
    if self.expectingNewSpec then
        self:UpdateActiveSpec()
    end
    
    self:UnregisterEvent("CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED")
end

-- DOC: CoATalentFrameMixin:ASCENSION_CA_SPECIALIZATION_ACTIVE_ID_CHANGED
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Runs when the 'ASCENSION_CA_SPECIALIZATION_ACTIVE_ID_CHANGED' event happens (it is registered elsewhere in this file).
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (nil).
-- What it changes: shows/hides UI pieces, changes text on screen, listens for game events, uses Character Advancement API.
function CoATalentFrameMixin:ASCENSION_CA_SPECIALIZATION_ACTIVE_ID_CHANGED()
    self:UpdateActiveSpec()
end 

--
-- Build Creator Menu
--
CoABuildCreatorMenuMixin = {}
CoABuildCreatorMenuMixin.OnEvent = OnEventToMethod

-- DOC: CoABuildCreatorMenuMixin:OnLoad
-- What this does: Sets up this UI element: prepares data, connects events, and sets initial visuals.
-- When it runs: Runs once when this UI element is created/loaded.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (nil).
-- What it changes: shows/hides UI pieces, changes text on screen, listens for game events, uses Character Advancement API.
function CoABuildCreatorMenuMixin:OnLoad()
    self.title:SetText(HERO_ARCHITECT)
    self.BuildList:SetGetNumResultsFunction(C_BuildCreator.GetNumBuilds)
    self.BuildList:SetSelectedHighlightTexture()
    self.BuildList:SetTemplate("CoATalentBuildTemplate")
    self:RegisterEvent("BUILD_CREATOR_CATEGORY_RESULT")
    self.Loading:SetFrameLevel(self:GetFrameLevel()+10)
end 

-- DOC: CoABuildCreatorMenuMixin:OnShow
-- What this does: Prepares the UI right before the player sees it (updates text, lists, or buttons).
-- When it runs: Runs each time this UI element becomes visible.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (nil).
-- What it changes: shows/hides UI pieces, listens for game events, uses Character Advancement API.
function CoABuildCreatorMenuMixin:OnShow()
    self:RefreshBuilds()
    self:GetParent().SpecializationMenu:Hide()
    self:RegisterEvent("GLOBAL_MOUSE_DOWN")
end

function CoABuildCreatorMenuMixin:OnHide()
    self:UnregisterEvent("GLOBAL_MOUSE_DOWN")
end

-- DOC: CoABuildCreatorMenuMixin:RefreshBuilds
-- What this does: Update what is shown on screen so it matches the latest game data.
-- When it runs: Called whenever the screen needs to be redrawn with fresh information.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (nil).
-- What it changes: shows/hides UI pieces, uses Character Advancement API.
function CoABuildCreatorMenuMixin:RefreshBuilds()
    self.Loading:Show()
    C_BuildCreator.QueryAllBuilds(Enum.BuildCategory.Leveling)
end 

function CoABuildCreatorMenuMixin:SelectBuild(buildID)
    BuildCreatorUtil.ImportPendingBuildID(buildID)
end

-- DOC: CoABuildCreatorMenuMixin:GLOBAL_MOUSE_DOWN
-- What this does: Hide part of the UI (or close a popup).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (nil).
-- What it changes: shows/hides UI pieces, uses Character Advancement API.
function CoABuildCreatorMenuMixin:GLOBAL_MOUSE_DOWN()
    FrameUtil.DialogStyleGlobalMouseDown(self, self:GetParent().BuildDropDown)
end

function CoABuildCreatorMenuMixin:BUILD_CREATOR_CATEGORY_RESULT(category)
    self.Loading:Hide()
    local specID = C_CharacterAdvancement.GetActiveChrSpec()
    if not specID then
        return
    end
    local specInfo = C_ClassInfo.GetSpecInfoByID(specID)
    local searchTag = CoACharacterAdvancementUtil.FormatArchitectTag(specInfo.Spec)
    if searchTag then
        C_BuildCreator.UpdateFilter(searchTag, table.empty, table.empty)
    end

    self.NoItemText:SeShown(C_BuildCreator.GetNumBuilds() == 0)
    self.BuildList:RefreshScrollFrame()
end 
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

CoATreeViewMixin = {}
CoATreeViewMixin.OnEvent = OnEventToMethod

-- DOC: CoATreeViewMixin:OnLoad
-- What this does: Sets up this UI element: prepares data, connects events, and sets initial visuals.
-- When it runs: Runs once when this UI element is created/loaded.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: changes text on screen, listens for game events.
function CoATreeViewMixin:OnLoad()
    local class = select(2, UnitClass("player"))
    local classDBC = CharacterAdvancementUtil.GetClassDBCByFile(class)
    self.ClassTree:SetClassTab(classDBC, "Class")
    self.ClassTree.Label:SetText(LOCALIZED_CLASS_NAMES_MALE[class]:upper())
    local popupFrameLevel = self.BottomBar:GetFrameLevel() + 20
    self.BottomBar.SpecializationMenu:SetFrameLevel(popupFrameLevel)
    self.BottomBar.BuildCreatorMenu:SetFrameLevel(popupFrameLevel)
    UIDropDownMenu_SetWidth(self.BottomBar.SpecDropDown, 180)
    UIDropDownMenu_SetWidth(self.BottomBar.BuildDropDown, 180)
    UIDropDownMenu_JustifyText(self.BottomBar.SpecDropDown, "LEFT")
    UIDropDownMenu_JustifyText(self.BottomBar.BuildDropDown, "LEFT")
    UIDropDownMenu_SetAnchor(self.BottomBar.ResetButton.DropDown, 0, 0, "BOTTOM", self.BottomBar.ResetButton, "TOP")
    UIDropDownMenu_Initialize(self.BottomBar.ResetButton.DropDown, GenerateClosure(self.InitializeResetDropDown, self), "MENU")
end

-- DOC: CoATreeViewMixin:OnShow
-- What this does: Prepares the UI right before the player sees it (updates text, lists, or buttons).
-- When it runs: Runs each time this UI element becomes visible.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: listens for game events, uses Character Advancement API.
function CoATreeViewMixin:OnShow()
    self:RegisterEvent("CHARACTER_ADVANCEMENT_UPDATE_ENTRIES_RESULT")
    self:RegisterEvent("CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED")
    self:RegisterEvent("ASCENSION_CA_SPECIALIZATION_ACTIVE_ID_CHANGED")
    self:RegisterEvent("BUILD_CREATOR_ACTIVATE_RESULT")
    self:RegisterEvent("BUILD_CREATOR_DEACTIVATE_RESULT")
    self:UpdateCommitButtons()
    self:UpdatePoints()
    self:UpdateDropDowns()
    self.Background3.Anim:Play()
end 

-- DOC: CoATreeViewMixin:OnHide
-- What this does: Cleans up when the UI closes (stops updates and hides extra popups).
-- When it runs: Runs when this UI element is hidden.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: listens for game events, uses Character Advancement API.
function CoATreeViewMixin:OnHide()
    self:UnregisterEvent("CHARACTER_ADVANCEMENT_UPDATE_ENTRIES_RESULT")
    self:UnregisterEvent("CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED")
    self:UnregisterEvent("ASCENSION_CA_SPECIALIZATION_ACTIVE_ID_CHANGED")
    self:UnregisterEvent("BUILD_CREATOR_ACTIVATE_RESULT")
    self:UnregisterEvent("BUILD_CREATOR_DEACTIVATE_RESULT")
    self.Background3.Anim:Stop()
end

-- DOC: CoATreeViewMixin:MarkTreesDirty
-- What this does: Play a UI sound and update state.
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: uses Character Advancement API.
function CoATreeViewMixin:MarkTreesDirty()
    self.ClassTree:MarkDirty(TalentTreeBaseMixin.DirtyReason.Nodes)
    self.SpecTree:MarkDirty(TalentTreeBaseMixin.DirtyReason.Nodes)
end

function CoATreeViewMixin:InitializeResetDropDown(dropdown, level, menuList)
    local info = UIDropDownMenu_CreateInfo()
    info.text = TALENT_FRAME_RESET_BUTTON_DROPDOWN_TITLE
    info.isTitle = true
    UIDropDownMenu_AddButton(info, level)
    
    UIDropDownMenu_CreateInfo()
    info.text = TALENT_FRAME_RESET_BUTTON_DROPDOWN_LEFT
    -- DOC: info.func
    -- What this does: Update text shown to the player.
    -- When it runs: Called by other code when needed.
    -- Inputs: none
    -- Output: Nothing (nil).
    -- What it changes: changes text on screen, uses Character Advancement API.
    info.func = function()
        self.ClassTree:ResetTree()
    end
    UIDropDownMenu_AddButton(info, level)

    UIDropDownMenu_CreateInfo()
    info.text = TALENT_FRAME_RESET_BUTTON_DROPDOWN_RIGHT
    info.func = function()
        self.SpecTree:ResetTree()
    end
    UIDropDownMenu_AddButton(info, level)

    UIDropDownMenu_CreateInfo()
    info.text = TALENT_FRAME_RESET_BUTTON_DROPDOWN_ALL
    -- DOC: info.func
    -- What this does: Update text shown to the player.
    -- When it runs: Called by other code when needed.
    -- Inputs: none
    -- Output: Nothing (nil).
    -- What it changes: changes text on screen, uses Character Advancement API.
    info.func = function()
        C_CharacterAdvancement.ClearPendingBuild(Const.CharacterAdvancement.OnlyClearAllowed)
    end
    UIDropDownMenu_AddButton(info, level)
end

function CoATreeViewMixin:ShowResetDropDown()
    ToggleDropDownMenu(1, nil, self.BottomBar.ResetButton.DropDown);
end

-- DOC: CoATreeViewMixin:CHARACTER_ADVANCEMENT_UPDATE_ENTRIES_RESULT
-- What this does: Update text shown to the player.
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
--   - success: a piece of information passed in by the caller
--   - reason: a piece of information passed in by the caller
-- Output: Nothing (nil).
-- What it changes: changes text on screen, uses Character Advancement API.
function CoATreeViewMixin:CHARACTER_ADVANCEMENT_UPDATE_ENTRIES_RESULT(success, reason)
    if success then
        PlaySound(SOUNDKIT.UI_CLASS_TALENT_APPLY_COMPLETE)
    end
end

function CoATreeViewMixin:CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED()
    self:UpdateCommitButtons()
    self:UpdatePoints()
end

-- DOC: CoATreeViewMixin:ASCENSION_CA_SPECIALIZATION_ACTIVE_ID_CHANGED
-- What this does: Update text shown to the player.
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (nil).
-- What it changes: changes text on screen, uses Character Advancement API.
function CoATreeViewMixin:ASCENSION_CA_SPECIALIZATION_ACTIVE_ID_CHANGED()
    self:UpdateDropDowns()
end

function CoATreeViewMixin:BUILD_CREATOR_ACTIVATE_RESULT()
    self:UpdateDropDowns()
end

-- DOC: CoATreeViewMixin:BUILD_CREATOR_DEACTIVATE_RESULT
-- What this does: Update text shown to the player.
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (nil).
-- What it changes: changes text on screen, uses Character Advancement API.
function CoATreeViewMixin:BUILD_CREATOR_DEACTIVATE_RESULT()
    self:UpdateDropDowns()
end

function CoATreeViewMixin:UpdateDropDowns()
    local spec = SpecializationUtil.GetActiveSpecialization()
    local name = SpecializationUtil.GetSpecializationInfo(spec)
    UIDropDownMenu_SetText(self.BottomBar.SpecDropDown, name)
    
    local activeBuildID = BuildCreatorUtil.GetActiveBuildID()
    if activeBuildID == self.activeBuildID then
        return
    end
    
    self.activeBuildID = activeBuildID

    if activeBuildID then
        BuildCreatorUtil.ContinueOnLoad(activeBuildID, function(build)
            if build then
                UIDropDownMenu_SetText(self.BottomBar.BuildDropDown, CoACharacterAdvancementUtil.StripArchitectTag(build.Name))
            else
                UIDropDownMenu_SetText(self.BottomBar.BuildDropDown, TALENTS_IMPORT_HERO_ARCHITECT)
            end
        end)
    end
    UIDropDownMenu_SetText(self.BottomBar.BuildDropDown, TALENTS_IMPORT_HERO_ARCHITECT)
end

-- DOC: CoATreeViewMixin:UpdatePoints
-- What this does: Update what is shown on screen so it matches the latest game data.
-- When it runs: Called whenever the screen needs to be redrawn with fresh information.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (nil).
-- What it changes: changes text on screen, uses Character Advancement API.
function CoATreeViewMixin:UpdatePoints()
    local remainingClass = C_CharacterAdvancement.GetPendingRemainingAE()
    local remainingSpec = C_CharacterAdvancement.GetPendingRemainingTE()
    
    self.ClassTree.Points:SetText(remainingClass)
    if remainingClass > 0 then
        self.ClassTree.Points:SetTextColor(GREEN_FONT_COLOR:GetRGB())
    else
        self.ClassTree.Points:SetTextColor(DISABLED_FONT_COLOR:GetRGB())
    end

    self.SpecTree.Points:SetText(remainingSpec)
    if remainingSpec > 0 then
        self.SpecTree.Points:SetTextColor(GREEN_FONT_COLOR:GetRGB())
    else
        self.SpecTree.Points:SetTextColor(DISABLED_FONT_COLOR:GetRGB())
    end
end

-- DOC: CoATreeViewMixin:UpdateCommitButtons
-- What this does: Update what is shown on screen so it matches the latest game data.
-- When it runs: Called whenever the screen needs to be redrawn with fresh information.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (nil).
-- What it changes: changes text on screen, uses Character Advancement API.
function CoATreeViewMixin:UpdateCommitButtons()
    local hasPendingChanges = C_CharacterAdvancement.IsPending()
    self.BottomBar.UndoButton:SetShown(hasPendingChanges)
    self.BottomBar.SaveChanges.YellowGlow:SetShown(hasPendingChanges)
    self.BottomBar.ResetButton:SetShown(not hasPendingChanges)

    local canApplyPendingChanges, reason, traversalError, entryID, entryRank, marksCost, goldCost, tokenType, tokenCost = C_CharacterAdvancement.CanApplyPendingBuild()
    self.BottomBar.SaveChanges:SetEnabled(canApplyPendingChanges)
    if hasPendingChanges then
        self.BottomBar.SaveChanges.tooltipTitle = CA_UNABLE_TO_SAVE_PENDING_BUILD
        local error = _G[reason] or reason or ""
        local entry = entryID and C_CharacterAdvancement.GetEntryByInternalID(entryID)
        error = error:format(entry and entry.Name or entryID, entryRank or "", traversalError and _G[traversalError] or traversalError or "")
        self.BottomBar.SaveChanges.tooltipText = RED_FONT_COLOR:WrapText(error)
    else
        self.BottomBar.SaveChanges.tooltipTitle = nil
        self.BottomBar.SaveChanges.tooltipText = nil
    end
end

-- DOC: CoATreeViewMixin:SetSpecID
-- What this does: Set a value on this UI element and update related visuals.
-- When it runs: Called when code needs to store a value and/or update the visuals.
-- Inputs:
--   - self: the UI object this function belongs to
--   - specID: an identifier (a number/string that points to a specific thing)
-- Output: Nothing (nil).
-- What it changes: changes text on screen, uses Character Advancement API.
function CoATreeViewMixin:SetSpecID(specID)
    if self.specID == specID then
        return
    end

    self.specID = specID
    local specInfo = C_ClassInfo.GetSpecInfoByID(specID)
    local specFile = specInfo.Spec
    local specDBC = CharacterAdvancementUtil.GetSpecDBCByFile(specFile)
    local classDBC = CharacterAdvancementUtil.GetClassDBCByFile(specInfo.Class)
    self.SpecTree.Label:SetText(specInfo.Name:upper())
    local specArt = CharacterAdvancementUtil.GetBackgroundAtlas(specInfo.Class, specInfo.Spec)
    self.Background1:SetAtlas(specArt)
    self.Background2:SetAtlas(specArt)
    self.Background3:SetAtlas(specArt)
    self.SpecTree:SetClassTab(classDBC, specDBC)
end 

-- DOC: CoATreeViewMixin:UpdateSearch
-- What this does: Update what is shown on screen so it matches the latest game data.
-- When it runs: Called whenever the screen needs to be redrawn with fresh information.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: uses Character Advancement API.
function CoATreeViewMixin:UpdateSearch()
    local search = self.BottomBar.Search:GetText()
    C_CharacterAdvancement.SetFilteredEntries(search, table.empty)
    self.ClassTree:MarkDirty(TalentTreeBaseMixin.DirtyReason.Search)
    self.SpecTree:MarkDirty(TalentTreeBaseMixin.DirtyReason.Search)
end 
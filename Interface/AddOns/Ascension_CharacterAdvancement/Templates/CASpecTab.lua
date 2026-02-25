-- GUIDE: What is this file?
-- Purpose: Behavior for a reusable UI widget (a 'template') used by the Character Advancement screens.
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

CASpecTabMixin = CreateFromMixins(TabSystemTabMixin)

-- DOC: CASpecTabMixin:UpdateSpellCounts
-- What this does: Update what is shown on screen so it matches the latest game data.
-- When it runs: Called whenever the screen needs to be redrawn with fresh information.
-- Inputs:
--   - self: the UI object this function belongs to
--   - class: a piece of information passed in by the caller
--   - spec: information about a specialization (spec) choice
-- Output: Nothing (nil).
-- What it changes: shows/hides UI pieces, changes text on screen, uses Character Advancement API.
function CASpecTabMixin:UpdateSpellCounts(class, spec)
    if spec == "BROWSER" or C_CVar.GetBool("previewCharacterAdvancementChanges") then
        self.TalentCount:Hide()
        self.SpellCount:Hide()
        return
    end

    local te = C_CharacterAdvancement.GetLearnedTE(class, spec)
    local ae = C_CharacterAdvancement.GetLearnedAE(class, spec)
    self.TalentCount:SetCount(te)
    self.SpellCount:SetCount(ae)

    local showAE = ae and ae > 0
    local showTE = te and te > 0

    self.SpellCount:SetShown(showAE)
    self.TalentCount:SetShown(showTE)

    self.Text:ClearAndSetPoint("CENTER", 0, 1)

    if showAE then
        self.SpellCount:ClearAndSetPoint("LEFT", self.Text, "RIGHT", 4, 0)
        self.Text:ClearAndSetPoint("CENTER", -(self.SpellCount:GetWidth()/2), 1)
    end

    if showAE and showTE then
        self.TalentCount:ClearAndSetPoint("LEFT", self.SpellCount, "RIGHT", 0, 0)
        self.Text:ClearAndSetPoint("CENTER", -(self.SpellCount:GetWidth()), 1)
    elseif showTE then
        self.TalentCount:ClearAndSetPoint("LEFT", self.Text, "RIGHT", 4, 0)
        self.Text:ClearAndSetPoint("CENTER", -(self.SpellCount:GetWidth()/2), 1)
    end
end

-- DOC: CASpecTabMixin:GetClassFile
-- What this does: Return a value that other parts of the UI need.
-- When it runs: Called when other code needs a yes/no or a piece of information.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: A value used by other code (self.classFile).
-- What it changes: shows/hides UI pieces, changes text on screen.
function CASpecTabMixin:GetClassFile()
    return self.classFile
end

function CASpecTabMixin:OnSpellCountEnter(spellCount)
    if not self.classFile or not self.spec then return end
    local className = LOCALIZED_CLASS_NAMES_MALE[self.classFile]
    if not className then return end
    local specInfo = C_ClassInfo.GetSpecInfo(self.classFile, self.spec)
    className = specInfo.Name .. " - " .. className
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(S_ABILITIES:format(className), RAID_CLASS_COLORS[self.classFile]:GetRGB())
    GameTooltip:AddLine(D_ABILITIES_KNOWN:format(tonumber(spellCount.Text:GetText())), 1, 1, 1, true)
    GameTooltip:Show()
    self:LockHighlight()
end

-- DOC: CASpecTabMixin:OnTalentCountEnter
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Runs for a UI callback named OnTalentCountEnter.
-- Inputs:
--   - self: the UI object this function belongs to
--   - talentCount: information about a talent (often an ID or data table)
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, changes text on screen.
function CASpecTabMixin:OnTalentCountEnter(talentCount)
    if not self.classFile or not self.spec then return end
    local className = LOCALIZED_CLASS_NAMES_MALE[self.classFile]
    if not className then return end
    local specInfo = C_ClassInfo.GetSpecInfo(self.classFile, self.spec)
    className = specInfo.Name .. " - " .. className
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(S_TALENTS:format(className), RAID_CLASS_COLORS[self.classFile]:GetRGB())
    GameTooltip:AddLine(D_TALENTS_KNOWN:format(tonumber(talentCount.Text:GetText())), 1, 1, 1, true)
    GameTooltip:Show()
    self:LockHighlight()
end

-- DOC: CASpecTabMixin:OnCountLeave
-- What this does: Hide part of the UI (or close a popup).
-- When it runs: Runs for a UI callback named OnCountLeave.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces.
function CASpecTabMixin:OnCountLeave()
    GameTooltip:Hide()
    self:UnlockHighlight()
end 

function CASpecTabMixin:OnLeave()
    GameTooltip:Hide()
    self:UnlockHighlight()
end 

-- DOC: CASpecTabMixin:UpdateButton
-- What this does: Update what is shown on screen so it matches the latest game data.
-- When it runs: Called whenever the screen needs to be redrawn with fresh information.
-- Inputs:
--   - self: the UI object this function belongs to
--   - buttonState: the button that triggered this (the thing you clicked)
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: updates UI/state.
function CASpecTabMixin:UpdateButton(buttonState)
    local buttonState = buttonState or self:GetButtonState()
    local atlasNamePostfix = ""
    --ThreeSliceButtonMixin.UpdateButton(self, buttonState)
    if self.GetChecked and self:GetChecked() then
        atlasNamePostfix = "-Checked"
    end

    self.Left:SetAtlas(self:GetLeftAtlasName()..atlasNamePostfix, Const.TextureKit.UseAtlasSize)
    self.Center:SetAtlas(self:GetCenterAtlasName()..atlasNamePostfix)
    self.Right:SetAtlas(self:GetRightAtlasName()..atlasNamePostfix, Const.TextureKit.UseAtlasSize)

    self.leftAtlasInfo = AtlasUtil:GetAtlasInfo(self:GetLeftAtlasName()..atlasNamePostfix)
    self.rightAtlasInfo = AtlasUtil:GetAtlasInfo(self:GetRightAtlasName()..atlasNamePostfix)

    local isDisabled = (self:IsEnabled() == 0 ) and not self:GetChecked()
    self.Left:SetDesaturated(isDisabled)
    self.Center:SetDesaturated(isDisabled)
    self.Right:SetDesaturated(isDisabled)

    self:UpdateScale()
end

-- DOC: CASpecTabMixin:OnMouseDown
-- What this does: Do a specific piece of work related to 'OnMouseDown'.
-- When it runs: Runs for a UI callback named OnMouseDown.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: updates UI/state.
function CASpecTabMixin:OnMouseDown()
    local buttonState = buttonState or self:GetButtonState()

    if buttonState ~= "DISABLED" then
        self:UpdateButton("PUSHED")
    end
end

-- DOC: CASpecTabMixin:OnMouseUp
-- What this does: Do a specific piece of work related to 'OnMouseUp'.
-- When it runs: Runs for a UI callback named OnMouseUp.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: updates UI/state.
function CASpecTabMixin:OnMouseUp()
    local buttonState = buttonState or self:GetButtonState()

    if buttonState ~= "DISABLED" then
        self:UpdatButton("NORMAL")
    end
end
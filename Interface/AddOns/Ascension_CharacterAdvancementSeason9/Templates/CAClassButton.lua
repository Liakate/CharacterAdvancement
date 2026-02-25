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

CAClassButtonMixin = CreateFromMixins(BorderIconTemplateMixin)

-- DOC: CAClassButtonMixin:OnLoad
-- What this does: Sets up this UI element: prepares data, connects events, and sets initial visuals.
-- When it runs: Runs once when this UI element is created/loaded.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, changes text on screen, uses Character Advancement API.
function CAClassButtonMixin:OnLoad()
    self:SetRounded(true)
    self:SetBorderSize(56, 56)
    self:SetBorderAtlas("draft-ring")

    self:SetOverlayBlendMode("ADD")
    self:SetOverlayTexture("Interface\\GLUES\\CHARACTERCREATE\\IconBorderRace_H")
    self:SetOverlaySize(95, 95)
    self:SetOverlayOffset(0, 0)
    self.Overlay:Hide()

    self.Highlight:SetAtlas("bags-roundhighlight")

    self:SetHighlightFontObject(GameFontHighlightOutline)
    self:SetNormalFontObject(GameFontNormalOutline)
    self:SetPushedTextOffset(1, -1)

    -- background is not used and we need text to be over the Overlay
    self.Icon:SetDrawLayer("BACKGROUND")
    self.IconBorder:SetDrawLayer("BORDER")
    self.Overlay:SetDrawLayer("ARTWORK")
    self.Text:SetDrawLayer("OVERLAY")
end

-- DOC: CAClassButtonMixin:SetClass
-- What this does: Set a value on this UI element and update related visuals.
-- When it runs: Called when code needs to store a value and/or update the visuals.
-- Inputs:
--   - self: the UI object this function belongs to
--   - classFile: a piece of information passed in by the caller
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, changes text on screen, uses Character Advancement API.
function CAClassButtonMixin:SetClass(classFile)
    self.classFile = classFile
    self.classDBC = CharacterAdvancementUtil.GetClassDBCByFile(classFile)
    self:SetIconAtlas("class-round-"..classFile)
    self:SetText(LOCALIZED_CLASS_NAMES_MALE[classFile])
    self:UpdateSpellCounts()
end

-- DOC: CAClassButtonMixin:UpdateSpellCounts
-- What this does: Update what is shown on screen so it matches the latest game data.
-- When it runs: Called whenever the screen needs to be redrawn with fresh information.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, changes text on screen, uses Character Advancement API.
function CAClassButtonMixin:UpdateSpellCounts()
    local te = C_CharacterAdvancement.GetLearnedTE(self.classDBC)
    local ae = C_CharacterAdvancement.GetLearnedAE(self.classDBC)
    self.TalentCount:SetCount(te)
    self.SpellCount:SetCount(ae)

    local showAE = ae and ae > 0
    local showTE = te and te > 0

    self.SpellCount:SetShown(showAE)
    self.TalentCount:SetShown(showTE)

    if showAE then
        self.SpellCount:ClearAndSetPoint("CENTER", self, "RIGHT", 8, -10)
    end

    if showAE and showTE then
        self.TalentCount:ClearAndSetPoint("CENTER", self, "RIGHT", 8, 10)
    elseif showTE then
        self.TalentCount:ClearAndSetPoint("CENTER", self, "RIGHT", 8, -10)
    end
end

-- DOC: CAClassButtonMixin:OnClick
-- What this does: Handle a button click (do the action and update the UI).
-- When it runs: Runs when the player clicks the related button.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, changes text on screen.
function CAClassButtonMixin:OnClick()
    PlaySound(SOUNDKIT.CHARACTER_SHEET_TAB)
    CharacterAdvancement:SelectClass(self.classFile)
end 

function CAClassButtonMixin:OnSelected()
    self.Overlay:Show()
end

-- DOC: CAClassButtonMixin:OnDeSelected
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Runs for a UI callback named OnDeSelected.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, changes text on screen.
function CAClassButtonMixin:OnDeSelected()
    self.Overlay:Hide()
end

function CAClassButtonMixin:OnSpellCountEnter(spellCount)
    if not self.classFile then return end
    local className = LOCALIZED_CLASS_NAMES_MALE[self.classFile]
    if not className then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(S_ABILITIES:format(className), RAID_CLASS_COLORS[self.classFile]:GetRGB())
    GameTooltip:AddLine(D_ABILITIES_KNOWN:format(tonumber(spellCount.Text:GetText())), 1, 1, 1, true)
    GameTooltip:Show()
    self:LockHighlight()
end

-- DOC: CAClassButtonMixin:OnTalentCountEnter
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Runs for a UI callback named OnTalentCountEnter.
-- Inputs:
--   - self: the UI object this function belongs to
--   - talentCount: information about a talent (often an ID or data table)
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, changes text on screen.
function CAClassButtonMixin:OnTalentCountEnter(talentCount)
    if not self.classFile then return end
    local className = LOCALIZED_CLASS_NAMES_MALE[self.classFile]
    if not className then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(S_TALENTS:format(className), RAID_CLASS_COLORS[self.classFile]:GetRGB())
    GameTooltip:AddLine(D_TALENTS_KNOWN:format(tonumber(talentCount.Text:GetText())), 1, 1, 1, true)
    GameTooltip:Show()
    self:LockHighlight()
end

-- DOC: CAClassButtonMixin:OnCountLeave
-- What this does: Hide part of the UI (or close a popup).
-- When it runs: Runs for a UI callback named OnCountLeave.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces.
function CAClassButtonMixin:OnCountLeave()
    GameTooltip:Hide()
    self:UnlockHighlight()
end 
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

CARarityBarMixin = {}

-- DOC: CARarityBarMixin:OnLoad
-- What this does: Sets up this UI element: prepares data, connects events, and sets initial visuals.
-- When it runs: Runs once when this UI element is created/loaded.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: changes text on screen, listens for game events, uses Character Advancement API.
function CARarityBarMixin:OnLoad()
    self.Highlight:SetAtlas("search-highlight", Const.TextureKit.IgnoreAtlasSize)
    self.Left:SetAtlas("collapse-button-left", Const.TextureKit.IgnoreAtlasSize)
    self.Right:SetAtlas("collapse-button-right", Const.TextureKit.IgnoreAtlasSize)
    self.Middle:SetAtlas("collapse-button-middle", Const.TextureKit.IgnoreAtlasSize)
    self.RarityGemContainer:SetPoint("LEFT", self.Text, "RIGHT", 4, 0)
    self.RarityGemContainer:SetGemSize(16)
    self.RarityGemContainer:SetOrientation({ "BOTTOMLEFT", "BOTTOMRIGHT", -2, 0 })
    self.RarityGemContainer:SetGemClickHandler(GenerateClosure(self.OnClick, self))
    self.RarityGemContainer:SetGemOnEnterHandler(function() self:LockHighlight() end)
    self.RarityGemContainer:SetGemOnLeaveHandler(function() self:UnlockHighlight() end)
    AttributesToKeyValues(self)
    if self.quality then
        self:SetQuality(self.quality)
    end
end 

-- DOC: CARarityBarMixin:OnShow
-- What this does: Prepares the UI right before the player sees it (updates text, lists, or buttons).
-- When it runs: Runs each time this UI element becomes visible.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: changes text on screen, listens for game events, uses Character Advancement API.
function CARarityBarMixin:OnShow()
    self:Update()
    self:RegisterEvent("CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED")
end

function CARarityBarMixin:OnHide()
    self:UnregisterEvent("CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED")
end

-- DOC: CARarityBarMixin:OnEvent
-- What this does: React to game events (for example: a build changed, points changed, or data loaded).
-- When it runs: Runs when the game sends an event to this UI element.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: changes text on screen, uses Character Advancement API.
function CARarityBarMixin:OnEvent()
    self:Update()
end

function CARarityBarMixin:SetQuality(quality)
    self.quality = quality
    self.RarityGemContainer:SetGemQuality(quality)
    self:SetText(ITEM_QUALITY_COLORS[quality]:WrapText(_G["ITEM_QUALITY" .. quality .. "_DESC"]))
end 

-- DOC: CARarityBarMixin:Update
-- What this does: Update what is shown on screen so it matches the latest game data.
-- When it runs: Called whenever the screen needs to be redrawn with fresh information.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: uses Character Advancement API.
function CARarityBarMixin:Update()
    if not self.quality then return end
    if not self:IsVisible() then return end

    local amount
    if BuildCreatorUtil.IsPickingSpells() then
        amount = select(self.quality, C_BuildEditor.GetQualityInfoForLevel()) or 0
    else
        amount = C_CharacterAdvancement.GetQualityCount(self.quality)
    end
    local limit = C_CharacterAdvancement.GetQualityLimit(self.quality)
    self.RarityGemContainer:SetNumGems(limit or amount, amount)
end

-- DOC: CARarityBarMixin:OnClick
-- What this does: Handle a button click (do the action and update the UI).
-- When it runs: Runs when the player clicks the related button.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: updates UI/state.
function CARarityBarMixin:OnClick()
    if self.quality then
        CharacterAdvancement:SetSearch(_G["ITEM_QUALITY" .. self.quality .. "_DESC"])
    end
end 
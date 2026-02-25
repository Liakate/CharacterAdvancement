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

CoASpecViewMixin = {}

-- DOC: CoASpecViewMixin:OnLoad
-- What this does: Sets up this UI element: prepares data, connects events, and sets initial visuals.
-- When it runs: Runs once when this UI element is created/loaded.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, uses Character Advancement API.
function CoASpecViewMixin:OnLoad()
    self.class = select(2, UnitClass("player"))
    self.Background:SetAtlas("spec-background", Const.TextureKit.IgnoreAtlasSize)
    self.SpecChoicePool = CreateFramePool("Frame", self, "CoASpecChoiceTemplate")

    local specs = C_ClassInfo.GetAllSpecs(self.class)
    local numSpecs = #specs
    local choiceWidth = self:GetWidth() / math.max(numSpecs, 1)
    local choiceHeight = self:GetHeight()
    
    local specInfo, choiceFrame
    for i, spec in ipairs(specs) do
        specInfo = C_ClassInfo.GetSpecInfo(self.class, spec)
        choiceFrame = self.SpecChoicePool:Acquire()
        choiceFrame:SetSpecInfo(specInfo, choiceWidth, choiceHeight, i == 1, i == numSpecs)
        choiceFrame:SetPoint("LEFT", choiceWidth*(i-1), 0)
        choiceFrame:SetDividerShown(i ~= numSpecs)
        choiceFrame:Show()
    end

end

-- DOC: CoASpecViewMixin:OnShow
-- What this does: Prepares the UI right before the player sees it (updates text, lists, or buttons).
-- When it runs: Runs each time this UI element becomes visible.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: uses Character Advancement API.
function CoASpecViewMixin:OnShow()
    local activeSpecID = C_CharacterAdvancement.GetActiveChrSpec()
    for choiceFrame in self.SpecChoicePool:EnumerateActive() do
        choiceFrame:UpdateVisualState(choiceFrame:GetSpecID() == activeSpecID)
    end
end
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

CAClassButtonMixin = {}

-- DOC: CAClassButtonMixin:OnLoad
-- What this does: Sets up this UI element: prepares data, connects events, and sets initial visuals.
-- When it runs: Runs once when this UI element is created/loaded.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, changes text on screen, uses Character Advancement API.
function CAClassButtonMixin:OnLoad()
    self.Overlay:Hide()

    self:SetHighlightFontObject(GameFontHighlightOutline)
    self:SetNormalFontObject(GameFontNormalOutline)
    self:SetPushedTextOffset(1, -1)

    self.Text:SetDrawLayer("OVERLAY")

    self.tabPointsPool = CreateFramePool("Button", self, "ClassPointsTemplate")

    -- to work with CATalentGateCounterMixin
    self.GateText = self.Icon.ClassPoints.Text
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
    self.topTab = nil
    self.Icon:SetIconAtlas("class-round-"..classFile)
    self:SetText(LOCALIZED_CLASS_NAMES_MALE[classFile])
    self:UpdateSpellCounts()

    if self.Text:GetStringHeight() > 12 then
        self:SetHighlightFontObject(GameFontHighlightOutlineSmall)
        self:SetNormalFontObject(GameFontNormalOutlineSmall)
    end

    local color = RAID_CLASS_COLORS[classFile]

    if color then
        self.Background:SetVertexColor(color.r, color.g, color.b)
    end
end

-- DOC: CAClassButtonMixin:UpdateSpellCounts
-- What this does: Update what is shown on screen so it matches the latest game data.
-- When it runs: Called whenever the screen needs to be redrawn with fresh information.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, changes text on screen, uses Character Advancement API.
function CAClassButtonMixin:UpdateSpellCounts()
    self.tabPointsPool:ReleaseAll()
    self.Text:Show()
    --self.Shadow:Hide()
    self.Icon.ClassPoints:Hide()

    if C_CVar.GetBool("previewCharacterAdvancementChanges") then
        local tabs = CHARACTER_ADVANCEMENT_CLASS_SPEC_ORDER[self.classFile]
        local class = CharacterAdvancementUtil.GetClassDBCByFile(self.classFile)

        local totalButtons = 0
        local firstButton, button

        local classPoints = C_CharacterAdvancement.GetClassPointInvestment(class, 0) or 0

        if classPoints and (classPoints > 0) then
            --self.Shadow:Show()
            self.Icon.ClassPoints:Show()
            self.Icon.ClassPoints:SetText(classPoints)

            self.tooltipTitle, self.tooltipText = CATalentGateCounterMixin.DefineTooltip(self, "CLASS", class)
        else
            self.tooltipTitle = nil
            self.tooltipText = nil
        end

        for i = 1, 3 do
            local tab = tabs[i]

            if tab then
                local spec = CharacterAdvancementUtil.GetSpecDBCByFile(tab)
                local spentOnTab = C_CharacterAdvancement.GetTabTEInvestment(class, spec, 0) or 0

                if spentOnTab > 0 then

                    if self.topTab then
                        if self.topTab.spentOnTab < spentOnTab then
                            self.topTab = {tab = tab, spentOnTab = spentOnTab}
                        end
                    else
                        self.topTab = {tab = tab, spentOnTab = spentOnTab}
                    end
                
                    local icon = CATalentGateCounterMixin:DefineIcon("TAB", class, spec)
                    local prevButton = button

                    button = self.tabPointsPool:Acquire()
                    button.GateText = button.Count
                    button:Show()
                    button:SetIcon(icon)
                    button.Count:SetText(spentOnTab)
                    button.tooltipTitle, button.tooltipText = CATalentGateCounterMixin.DefineTooltip(button, "TAB", class, spec)
                    button:SetScript("OnEnter", CATalentGateCounterMixin.OnEnter)
                    button:SetScript("OnClick", function()
                        CharacterAdvancement:SelectClass(self.classFile, tab)
                    end)

                    totalButtons = totalButtons + 1

                    if prevButton then
                        button:SetPoint("LEFT", prevButton, "RIGHT", 5, 0)
                    else
                        firstButton = button
                    end
                end
            end
        end

        if firstButton then
            self.Text:SetPoint("LEFT", self.Icon, "RIGHT", 8, 8)
            --firstButton:SetPoint("BOTTOM", -(19/2)*(totalButtons-1), 8)
            firstButton:SetPoint("LEFT", self.Icon, "RIGHT", 8, -8)
        else
            self.Text:SetPoint("LEFT", self.Icon, "RIGHT", 8, 0)
        end
    end
end

-- DOC: CAClassButtonMixin:OnEnter
-- What this does: Show a tooltip or highlight when the mouse is over this item.
-- When it runs: Runs when the mouse pointer moves over the related UI element.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces.
function CAClassButtonMixin:OnEnter()
    CATalentGateCounterMixin.OnEnter(self)
end

function CAClassButtonMixin:OnLeave()
    GameTooltip:Hide()
end

-- DOC: CAClassButtonMixin:OnClick
-- What this does: Handle a button click (do the action and update the UI).
-- When it runs: Runs when the player clicks the related button.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces.
function CAClassButtonMixin:OnClick()
    PlaySound(SOUNDKIT.CHARACTER_SHEET_TAB)
    CharacterAdvancement:SelectClass(self.classFile, self.topTab and self.topTab.tab or nil)
end 

function CAClassButtonMixin:OnSelected()
    self.Overlay:Show()
end

-- DOC: CAClassButtonMixin:OnDeSelected
-- What this does: Hide part of the UI (or close a popup).
-- When it runs: Runs for a UI callback named OnDeSelected.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces.
function CAClassButtonMixin:OnDeSelected()
    self.Overlay:Hide()
end

function CAClassButtonMixin:OnCountLeave()
    GameTooltip:Hide()
    self:UnlockHighlight()
end 
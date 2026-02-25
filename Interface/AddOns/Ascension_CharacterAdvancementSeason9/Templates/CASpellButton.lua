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

CASpellButtonBaseMixin = {}
CASpellButtonBaseMixin.OnEvent = OnEventToMethod

-- DOC: CASpellButtonBaseMixin:OnLoad
-- What this does: Sets up this UI element: prepares data, connects events, and sets initial visuals.
-- When it runs: Runs once when this UI element is created/loaded.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, listens for game events, uses Character Advancement API.
function CASpellButtonBaseMixin:OnLoad()
    self.Icon:EnableMouse(false)
    self.Icon:UseQuality(true)
    self.Icon:SetOverlayBlendMode("ADD")
    if self.Icon.LockIcon then
        self.Icon.LockIcon:SetAtlas("spell-list-locked")
    end
end

-- DOC: CASpellButtonBaseMixin:OnShow
-- What this does: Prepares the UI right before the player sees it (updates text, lists, or buttons).
-- When it runs: Runs each time this UI element becomes visible.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, listens for game events, uses Character Advancement API.
function CASpellButtonBaseMixin:OnShow()
    self:RegisterEvent("CHARACTER_ADVANCEMENT_LOCK_ENTRY_RESULT")
    self:RegisterEvent("CHARACTER_ADVANCEMENT_UNLOCK_ENTRY_RESULT")
    self:RegisterEvent("CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED")
end

function CASpellButtonBaseMixin:OnHide()
    self:UnregisterEvent("CHARACTER_ADVANCEMENT_LOCK_ENTRY_RESULT")
    self:UnregisterEvent("CHARACTER_ADVANCEMENT_UNLOCK_ENTRY_RESULT")
    self:UnregisterEvent("CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED")
end

-- DOC: CASpellButtonBaseMixin:SetEntry
-- What this does: Set a value on this UI element and update related visuals.
-- When it runs: Called when code needs to store a value and/or update the visuals.
-- Inputs:
--   - self: the UI object this function belongs to
--   - entry: a piece of information passed in by the caller
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, uses Character Advancement API.
function CASpellButtonBaseMixin:SetEntry(entry)
    self.Icon.LocationIcon:Hide()
    self.entry = entry
    self.spellID = entry.Spells[1]
    if entry.Type == "Talent" or entry.Type == "TalentAbility" then

        if BuildCreatorUtil.IsPickingSpells() then
            for _, spellID in ipairs(entry.Spells) do
                if C_BuildEditor.DoesBuildHaveSpellID(spellID) then
                    self.spellID = spellID
                else
                    break
                end
            end
        else
            local rank = C_CharacterAdvancement.GetTalentRankByID(entry.ID)
            if rank and rank > 0 then
                self.spellID = entry.Spells[rank]
            end
        end
    end

    local name = entry.Name
    local level = entry.RequiredLevel
    local isHighEnoughLevel = level <= C_Player:GetLevel()
    if isHighEnoughLevel then
        level = HIGHLIGHT_FONT_COLOR:WrapText(level)
    else
        level = RED_FONT_COLOR:WrapText(level)
    end
    self:SetFormattedText("%s\n%s %s", name, HIGHLIGHT_FONT_COLOR:WrapText(LEVEL), level)
    self.Icon:SetCharacterAdvancementEntry(entry)
    self:SetEnabledVisual()
    self.Icon:SetAlpha(1)
    self:EnableMouse(true)

    self.cannotLearn = nil
    self.cannotUnlearn = nil

    if BuildCreatorUtil.IsPickingSpells() then
        if self.Icon.LockIcon then
            self.Icon.LockIcon:Hide()
        end

        if self.Icon.RankUp then
            self.Icon.RankUp:Hide()
            self.Icon.RankUp.tooltipTitle = SPELL_RANK_AVAILABLE
            self.Icon.RankUp.tooltipText = SPELL_RANK_FIND_TRAINER
        end

        if C_BuildEditor.DoesBuildHaveSpellID(self.spellID) then
            if self.Icon.KnownGlow then
                self.Icon.KnownGlow:Show()
            end

            self.Icon:SetIconDesaturated(false)
            self.Icon:SetIconColor(1, 1, 1)
        else
            local canLearn, reason = C_BuildEditor.CanAddSpell(BuildCreatorUtil.CreateSpellInfo(self.spellID, BuildCreatorUtil.GetPickLevel()))
            if canLearn then
                if self.Icon.KnownGlow then
                    self.Icon.KnownGlow:Hide()
                end

                self.Icon:SetIconDesaturated(true)
                self.Icon:SetIconColor(1, 1, 1)
            else
                local color, desaturated = CharacterAdvancementUtil.GetSpellErrorColor(reason[1])
                
                if not(desaturated) then
                    self.Icon:SetIconDesaturated(true)
                    self:SetDisabledVisual()
                end
                if reason[1] ~= Enum.CALearnResult.DisplayEntry then
                    self.cannotLearn = reason[1] and _G[reason[1]] or reason[1]
                end
            end
        end
    else
        if self.Icon.LockIcon then
            self.Icon.LockIcon:SetShown(C_CharacterAdvancement.IsLockedID(entry.ID))
        end

        if C_CharacterAdvancement.IsKnownID(entry.ID) then
            if self.Icon.KnownGlow then
                self.Icon.KnownGlow:Show()
            end

            self.Icon:SetIconDesaturated(false)
            self.Icon:SetIconColor(1, 1, 1)

            local canUnlearn, reason = C_CharacterAdvancement.CanUnlearnID(entry.ID)

            if not canUnlearn and reason ~= Enum.CAUnlearnResult.NoWildCard  then
                self.cannotUnlearn = _G[reason] or reason
            end

            if self.Icon.RankUp and (self.entry.Type == "Ability" or self.entry.Type == "TalentAbility") then
                local maxSpellID = C_Spell.GetMaxLearnableRank(self.spellID, C_Player:GetLevel())
                local canLearn = maxSpellID and not IsSpellKnown(maxSpellID) and not CA_IsSpellKnown(maxSpellID)
                canLearn = canLearn and C_Spell.IsTrainerSpell(maxSpellID)
                
                self.Icon.RankUp:SetShown(maxSpellID and canLearn)
                self.Icon.RankUp.tooltipTitle = SPELL_RANK_AVAILABLE
                self.Icon.RankUp.tooltipText = SPELL_RANK_FIND_TRAINER
            else
                if self.Icon.RankUp then
                    self.Icon.RankUp:Hide()
                    self.Icon.RankUp.tooltipTitle = SPELL_RANK_AVAILABLE
                    self.Icon.RankUp.tooltipText = SPELL_RANK_FIND_TRAINER
                end
            end
        else
            local canLearn, reason = C_CharacterAdvancement.CanLearnID(entry.ID)
            if self.Icon.RankUp then
                if reason == Enum.CALearnResult.DisplayEntry and isHighEnoughLevel then
                    self.Icon.RankUp:Show()
                    self.Icon.RankUp.tooltipTitle = SPELL_AVAILABLE
                    self.Icon.RankUp.tooltipText = SPELL_AVAILABLE_FIND_TRAINER
                else
                    self.Icon.RankUp:Hide()
                    self.Icon.RankUp.tooltipTitle = SPELL_RANK_AVAILABLE
                    self.Icon.RankUp.tooltipText = SPELL_RANK_FIND_TRAINER
                end
            end

            if self.Icon.KnownGlow then
                self.Icon.KnownGlow:Hide()
            end


            if canLearn or reason == Enum.CALearnResult.NoWildCard then
                self.Icon:SetIconColor(1, 1, 1)
            else
                local color, desaturated = CharacterAdvancementUtil.GetSpellErrorColor(reason)

                if not(desaturated) then
                    self:SetDisabledVisual()
                end
            end

            self.Icon:SetIconDesaturated(true)
            if reason == Enum.CALearnResult.DisplayEntry then
                self.Icon:SetAlpha(0.75)
                self:EnableMouse(false)
            end

            if not(canLearn) then
                if reason ~= Enum.CALearnResult.DisplayEntry then
                    self.cannotLearn = _G[reason] or reason
                end
            end
        end
    end
end

-- DOC: CASpellButtonBaseMixin:Refresh
-- What this does: Update what is shown on screen so it matches the latest game data.
-- When it runs: Called whenever the screen needs to be redrawn with fresh information.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (nil).
-- What it changes: shows/hides UI pieces, uses Character Advancement API.
function CASpellButtonBaseMixin:Refresh()
    if self.entry then
        self:SetEntry(self.entry)
        if GameTooltip:IsOwned(self) then
            self:OnEnter()
        end
    end
end

-- DOC: CASpellButtonBaseMixin:ShowLocation
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (nil).
-- What it changes: shows/hides UI pieces, uses Character Advancement API.
function CASpellButtonBaseMixin:ShowLocation()
    self.Icon.LocationIcon:Show()
end

function CASpellButtonBaseMixin:OnEnter()
    if HelpTip:CanShow("SPELL_HINT_LEARN_HOTKEYS1") then
        HelpTip:Show("SPELL_HINT_LEARN_HOTKEYS1", self)
    end

    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetHyperlink(LinkUtil:GetSpellLink(self.spellID))
    if self.cannotLearn then
        GameTooltip:AddLine(CA_CANNOT_LEARN_S:format(self.cannotLearn), RED_FONT_COLOR.r , RED_FONT_COLOR.g, RED_FONT_COLOR.b, true)
    elseif self.cannotUnlearn then
        GameTooltip:AddLine(CA_CANNOT_UNLEARN_S:format(self.cannotUnlearn), RED_FONT_COLOR.r , RED_FONT_COLOR.g, RED_FONT_COLOR.b, true)
    end
    GameTooltip:Show()
    
    self.Icon:LockHighlight()
    self.Icon.LocationIcon:Hide()
end

-- DOC: CASpellButtonBaseMixin:OnLeave
-- What this does: Hide the tooltip/highlight when the mouse leaves this item.
-- When it runs: Runs when the mouse pointer leaves the related UI element.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (nil).
-- What it changes: shows/hides UI pieces, uses Character Advancement API.
function CASpellButtonBaseMixin:OnLeave()
    GameTooltip:Hide()
    self.Icon:GetPushedTexture():Hide()
    self.Icon:UnlockHighlight()
end

function CASpellButtonBaseMixin:OnDragStart()
    if not BuildCreatorUtil.IsPickingSpells() then
        C_CharacterAdvancement.PickupSpell(self.entry.ID)
    end
end

-- DOC: CASpellButtonBaseMixin:OnClick
-- What this does: Handle a button click (do the action and update the UI).
-- When it runs: Runs when the player clicks the related button.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (nil).
-- What it changes: uses Character Advancement API.
function CASpellButtonBaseMixin:OnClick()
    CloseDropDownMenus()
    if IsModifiedClick("CHATLINK") then
        local spellLink = LinkUtil:GetSpellLink(self.spellID)
        if ChatEdit_InsertLink(spellLink) then
            return
        end 
    end

    if not BuildCreatorUtil.IsPickingSpells() then
        if IsShiftKeyDown() then
            CloseDropDownMenus()
            if C_CharacterAdvancement.CanLearnID(self.entry.ID) then
                CharacterAdvancementUtil.ConfirmOrLearnID(self.entry.ID)
            end
            return
        end

        if IsAltKeyDown() then
            if C_CharacterAdvancement.CanUnlearnID(self.entry.ID) then
                CharacterAdvancementUtil.ConfirmOrUnlearnID(self.entry.ID)
            end
            return
        end
    else
        if IsAltKeyDown() then
            if C_BuildEditor.DoesBuildHaveSpellID(self.spellID) then
                C_BuildEditor.RemoveSpell(self.spellID)
                BuildCreatorUtil.RefreshFinishPickingPopup()
                BuildCreatorUtil.EditorSpellsChanged()
            end
            return
        end
    end

    CharacterAdvancement:ShowSpellDropDownMenu(self)
end

-- DOC: CASpellButtonBaseMixin:OnDoubleClick
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Runs for a UI callback named OnDoubleClick.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (nil).
-- What it changes: shows/hides UI pieces, uses Character Advancement API.
function CASpellButtonBaseMixin:OnDoubleClick()
    CloseDropDownMenus()
    if IsAltKeyDown() or IsShiftKeyDown() or IsControlKeyDown() then
        return
    end
    if BuildCreatorUtil.IsPickingSpells() then
        local nextSpellID
        if C_CharacterAdvancement.IsTalentSpellID(self.spellID) then
            nextSpellID = BuildCreatorUtil.GetNextTalentSpellID(self.spellID)
        else
            nextSpellID = self.spellID
        end

        local spellInfo = C_BuildEditor.GetSpellByID(self.spellID) or BuildCreatorUtil.CreateSpellInfo(nextSpellID, BuildCreatorUtil.GetPickLevel())
        spellInfo.Spell = nextSpellID
        spellInfo.Level = BuildCreatorUtil.GetPickLevel()
        C_BuildEditor.AddSpell(spellInfo)
        BuildCreatorUtil.RefreshFinishPickingPopup()
        BuildCreatorUtil.EditorSpellsChanged()
    elseif C_CharacterAdvancement.CanLearnID(self.entry.ID) then
        CharacterAdvancementUtil.ConfirmOrLearnID(self.entry.ID)
    end
end

-- DOC: CASpellButtonBaseMixin:OnMouseDown
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Runs for a UI callback named OnMouseDown.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces.
function CASpellButtonBaseMixin:OnMouseDown()
    self.Icon:GetPushedTexture():Show()
end

function CASpellButtonBaseMixin:OnMouseUp()
    self.Icon:GetPushedTexture():Hide()
end

-- DOC: CASpellButtonBaseMixin:SetDisabledVisual
-- What this does: Set a value on this UI element and update related visuals.
-- When it runs: Called when code needs to store a value and/or update the visuals.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces.
function CASpellButtonBaseMixin:SetDisabledVisual()
    if self.Icon.DisabledOverlay then
        self.Icon.DisabledOverlay:Show()
        self.Icon.DisabledOverlay:SetAlpha(0.35)
    end

    self.Icon.Icon:SetAlpha(0.35)
    self.Icon.IconBorder:SetAlpha(0.35)
    self.Icon.Overlay:SetAlpha(0.35)
end

-- DOC: CASpellButtonBaseMixin:SetEnabledVisual
-- What this does: Set a value on this UI element and update related visuals.
-- When it runs: Called when code needs to store a value and/or update the visuals.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces.
function CASpellButtonBaseMixin:SetEnabledVisual()
    if self.Icon.DisabledOverlay then
        self.Icon.DisabledOverlay:Hide()
        self.Icon.DisabledOverlay:SetAlpha(1)
    end

    self.Icon.Icon:SetAlpha(1)
    self.Icon.IconBorder:SetAlpha(1)
    self.Icon.Overlay:SetAlpha(1)
end

-- DOC: CASpellButtonBaseMixin:CHARACTER_ADVANCEMENT_LOCK_ENTRY_RESULT
-- What this does: Play a UI sound and update state.
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
--   - result: a piece of information passed in by the caller
--   - internalID: an identifier (a number/string that points to a specific thing)
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: updates UI/state.
function CASpellButtonBaseMixin:CHARACTER_ADVANCEMENT_LOCK_ENTRY_RESULT(result, internalID)
    if internalID == self.entry.ID then
        self:Refresh()
    end
end

function CASpellButtonBaseMixin:CHARACTER_ADVANCEMENT_UNLOCK_ENTRY_RESULT(result, internalID)
    if internalID == self.entry.ID then
        self:Refresh()
    end
end

-- DOC: CASpellButtonBaseMixin:CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED
-- What this does: Hide part of the UI (or close a popup).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, uses Character Advancement API.
function CASpellButtonBaseMixin:CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED()
    if self:IsVisible() then
        self:Refresh()
    end
end

CASpellButtonMixin = CreateFromMixins(CASpellButtonBaseMixin)

-- DOC: CASpellButtonMixin:OnLoad
-- What this does: Sets up this UI element: prepares data, connects events, and sets initial visuals.
-- When it runs: Runs once when this UI element is created/loaded.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, uses Character Advancement API.
function CASpellButtonMixin:OnLoad()
    CASpellButtonBaseMixin.OnLoad(self)
    self:RegisterForDrag("LeftButton")
    self.Icon:SetBorderSize(34, 34)
    self.Icon:SetOverlaySize(34, 34)
    --self.RarityGemContainer:SetGemSize(12)
    --self.RarityGemContainer:SetOrientation({ "BOTTOMLEFT", "BOTTOMRIGHT", -1, 0 })
    self.Shadow:SetAtlas("spellbook-text-background")

    self.Icon.KnownGlow:SetAtlas("ca_known_glow")
    self.Icon.KnownGlow:SetVertexColor(NORMAL_FONT_COLOR:GetRGB())

    self.Icon:SetBackgroundSize(58, 58)
    self.Icon:SetBackgroundTexture("Interface\\Spellbook\\UI-Spellbook-SpellBackground")
    self.Icon:SetBackgroundOffset(9.5, -9.5)
end

-- DOC: CASpellButtonMixin:SetEntry
-- What this does: Set a value on this UI element and update related visuals.
-- When it runs: Called when code needs to store a value and/or update the visuals.
-- Inputs:
--   - self: the UI object this function belongs to
--   - entry: a piece of information passed in by the caller
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, uses Character Advancement API.
function CASpellButtonMixin:SetEntry(entry)
    CASpellButtonBaseMixin.SetEntry(self, entry)

    if not(BuildCreatorUtil.IsPickingSpells()) then
        if entry.RequiredLevel > C_Player:GetLevel() then
            self:SetDisabledVisual()
        end
    end
end

-- DOC: CASpellButtonMixin:OnClick
-- What this does: Handle a button click (do the action and update the UI).
-- When it runs: Runs when the player clicks the related button.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, uses Character Advancement API.
function CASpellButtonMixin:OnClick()
    PlaySound(SOUNDKIT.UCHATSCROLLBUTTON)
    CASpellButtonBaseMixin.OnClick(self)
end

CATalentButtonMixin = CreateFromMixins(CASpellButtonBaseMixin)

function CATalentButtonMixin:OnLoad()
    CASpellButtonBaseMixin.OnLoad(self)
    self:RegisterForDrag("LeftButton")
    self.Icon:SetBorderSize(34, 34)
    self.Icon:SetOverlaySize(34, 34)

    self.Icon:SetBackgroundSize(59, 59)
    self.Icon:SetBackgroundTexture("Interface\\Buttons\\UI-EmptySlot")
    self.Icon:SetBackgroundOffset(0, -1)
end

-- DOC: CATalentButtonMixin:SetRankAndBg
-- What this does: Set a value on this UI element and update related visuals.
-- When it runs: Called when code needs to store a value and/or update the visuals.
-- Inputs:
--   - self: the UI object this function belongs to
--   - entry: a piece of information passed in by the caller
--   - rank: a piece of information passed in by the caller
--   - maxRank: a piece of information passed in by the caller
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, uses Character Advancement API.
function CATalentButtonMixin:SetRankAndBg(entry, rank, maxRank)
    rank = rank or (C_CharacterAdvancement.IsKnownID(entry.ID) and 1 or 0) 
    maxRank = maxRank or 1

    if maxRank <= 1 and IsHeroClass("player") then
        self.Icon.RankFrame:Hide()
    else
        self.Icon.RankFrame:Show()

        self.Icon.RankFrame:SetRank(rank)
        self.Icon.RankFrame:SetMaxRank(maxRank)
        self.Icon.RankFrame:UpdateVisual()
    end

    if rank == 0 then
        self.Icon.Background:SetDesaturated(true)
    else
        self.Icon.Background:SetDesaturated(false)
        local r, g, b = self.Icon.RankFrame.RankBorder:GetVertexColor()
        self.Icon.Background:SetVertexColor(r, g, b)
    end

end

-- DOC: CATalentButtonMixin:SetDisabledVisual
-- What this does: Set a value on this UI element and update related visuals.
-- When it runs: Called when code needs to store a value and/or update the visuals.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (nil).
-- What it changes: shows/hides UI pieces, uses Character Advancement API.
function CATalentButtonMixin:SetDisabledVisual()
    CASpellButtonBaseMixin.SetDisabledVisual(self)
    self.Icon.RankFrame:Hide()
end

function CATalentButtonMixin:SetEnabledVisual()
    CASpellButtonBaseMixin.SetEnabledVisual(self)
    self.Icon.RankFrame:Show()
end

-- DOC: CATalentButtonMixin:SetEntry
-- What this does: Set a value on this UI element and update related visuals.
-- When it runs: Called when code needs to store a value and/or update the visuals.
-- Inputs:
--   - self: the UI object this function belongs to
--   - entry: a piece of information passed in by the caller
-- Output: Nothing (nil).
-- What it changes: shows/hides UI pieces, uses Character Advancement API.
function CATalentButtonMixin:SetEntry(entry)
    CASpellButtonBaseMixin.SetEntry(self, entry)

    if BuildCreatorUtil.IsPickingSpells() then
        local rank = 0
        for index, spellID in ipairs(entry.Spells) do
            if C_BuildEditor.DoesBuildHaveSpellID(spellID) then
                rank = index
            else
                break
            end
        end

        local maxRank = #entry.Spells

        self:SetRankAndBg(entry, rank, maxRank)
    else
        local meetsGateCondition = not self.gate or (self.gate and self.gate.isMetTree and self.gate.isMetGlobal)

        local rank, maxRank = C_CharacterAdvancement.GetTalentRankByID(entry.ID)

        self:SetRankAndBg(entry, rank, maxRank)

        if entry.RequiredLevel > C_Player:GetLevel() or not(meetsGateCondition) then
            self:SetDisabledVisual()
            self.Icon.RankFrame:Hide()
        end
    end
end

-- DOC: CATalentButtonMixin:OnClick
-- What this does: Handle a button click (do the action and update the UI).
-- When it runs: Runs when the player clicks the related button.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (nil).
-- What it changes: shows/hides UI pieces, uses Character Advancement API.
function CATalentButtonMixin:OnClick()
    PlaySound(SOUNDKIT.UCHATSCROLLBUTTON)
    if not BuildCreatorUtil.IsPickingSpells() then
        if IsControlKeyDown() then
            local currentRank, maxRank = C_CharacterAdvancement.GetTalentRankByID(self.entry.ID)
            if currentRank and currentRank ~= maxRank then
                for i = math.max(currentRank, 1), maxRank do
                    if not C_CharacterAdvancement.CanLearnID(self.entry.ID) then
                        break
                    end
                    if CharacterAdvancementUtil.ConfirmOrLearnID(self.entry.ID) then
                        break
                    end
                end
                return
            end
        end
    end
    CASpellButtonBaseMixin.OnClick(self)
end

CAPrimaryStatButtonMixin = CreateFromMixins(CASpellButtonBaseMixin)
CAPrimaryStatButtonMixin.OnDoubleClick = nop

-- DOC: CAPrimaryStatButtonMixin:OnLoad
-- What this does: Sets up this UI element: prepares data, connects events, and sets initial visuals.
-- When it runs: Runs once when this UI element is created/loaded.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, uses Character Advancement API.
function CAPrimaryStatButtonMixin:OnLoad()
    CASpellButtonBaseMixin.OnLoad(self)
    self.Icon:SetBorderSize(34, 34)
    self.Icon:SetOverlaySize(34, 34)
    self.Icon.KnownGlow:SetAtlas("ca_known_glow")
    self.Icon.KnownGlow:SetVertexColor(NORMAL_FONT_COLOR:GetRGB())
end

-- DOC: CAPrimaryStatButtonMixin:OnClick
-- What this does: Handle a button click (do the action and update the UI).
-- When it runs: Runs when the player clicks the related button.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, uses Character Advancement API.
function CAPrimaryStatButtonMixin:OnClick()
    PlaySound(SOUNDKIT.UCHATSCROLLBUTTON)
    if C_CharacterAdvancement.CanLearnID(self.entry.ID) then
        CharacterAdvancementUtil.ConfirmOrLearnID(self.entry.ID)
    end
end

function CAPrimaryStatButtonMixin:OnEnter()
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:SetHyperlink(LinkUtil:GetSpellLink(self.spellID))
    if self.cannotLearn then
        GameTooltip:AddLine(CA_CANNOT_LEARN_S:format(self.cannotLearn), RED_FONT_COLOR.r , RED_FONT_COLOR.g, RED_FONT_COLOR.b, true)
    elseif self.cannotUnlearn then
        GameTooltip:AddLine(CA_CANNOT_UNLEARN_S:format(self.cannotUnlearn), RED_FONT_COLOR.r , RED_FONT_COLOR.g, RED_FONT_COLOR.b, true)
    end
    GameTooltip:Show()

    self.Icon:LockHighlight()
end 
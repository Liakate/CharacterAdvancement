-- GUIDE: What is this file?
-- Purpose: Shared utility helpers (small reusable functions) used by the Character Advancement UI.
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

CharacterAdvancementUtil = {}

local ClassConversions -- defined later

-- DOC: CharacterAdvancementUtil.GetTalentRankSpellByID
-- What this does: Return a value that other parts of the UI need.
-- When it runs: Called when other code needs a yes/no or a piece of information.
-- Inputs:
--   - internalID: an identifier (a number/string that points to a specific thing)
--   - rank: a piece of information passed in by the caller
-- Output: Nothing (nil).
-- What it changes: uses Character Advancement API.
function CharacterAdvancementUtil.GetTalentRankSpellByID(internalID, rank)
    local entry = C_CharacterAdvancement.GetEntryByInternalID(internalID)

    if not entry then
        return
    end

    local rankSpellID = entry.Spells[rank or 1]
    if not rankSpellID then
        return
    end

    return rankSpellID
end

-- DOC: CharacterAdvancementUtil.GetTalentRankSpellBySpellID
-- What this does: Return a value that other parts of the UI need.
-- When it runs: Called when other code needs a yes/no or a piece of information.
-- Inputs:
--   - spellID: an identifier (a number/string that points to a specific thing)
--   - rank: a piece of information passed in by the caller
-- Output: Nothing (nil).
-- What it changes: uses Character Advancement API.
function CharacterAdvancementUtil.GetTalentRankSpellBySpellID(spellID, rank)
    local entry = C_CharacterAdvancement.GetEntryBySpellID(spellID)

    if not entry then
        return
    end

    local rankSpellID = entry.Spells[rank or 1]
    if not rankSpellID then
        return
    end

    return rankSpellID
end

-- DOC: CharacterAdvancementUtil.GetSpellByID
-- What this does: Return a value that other parts of the UI need.
-- When it runs: Called when other code needs a yes/no or a piece of information.
-- Inputs:
--   - internalID: an identifier (a number/string that points to a specific thing)
-- Output: Nothing (nil).
-- What it changes: uses Character Advancement API.
function CharacterAdvancementUtil.GetSpellByID(internalID)
    local entry = C_CharacterAdvancement.GetEntryByInternalID(internalID)

    if not entry then
        return
    end

    return entry.Spells[1]
end

-- DOC: CharacterAdvancementUtil.GetIDBySpellID
-- What this does: Return a value that other parts of the UI need.
-- When it runs: Called when other code needs a yes/no or a piece of information.
-- Inputs:
--   - spellID: an identifier (a number/string that points to a specific thing)
-- Output: Nothing (nil).
-- What it changes: uses Character Advancement API.
function CharacterAdvancementUtil.GetIDBySpellID(spellID)
    local entry = C_CharacterAdvancement.GetEntryBySpellID(spellID)

    if not entry then
        return
    end

    return entry.ID
end 

-- DOC: CharacterAdvancementUtil.GetInvestmentByID
-- What this does: Return a value that other parts of the UI need.
-- When it runs: Called when other code needs a yes/no or a piece of information.
-- Inputs:
--   - internalID: an identifier (a number/string that points to a specific thing)
-- Output: Nothing (nil).
-- What it changes: uses Character Advancement API.
function CharacterAdvancementUtil.GetInvestmentByID(internalID)
    local entry = C_CharacterAdvancement.GetEntryByInternalID(internalID)

    if not entry then
        return
    end
    
    local currentRank = C_CharacterAdvancement.GetTalentRankByID(internalID)

    if currentRank then
        local spellID = entry.Spells[currentRank] or entry.Spells[1]
        local aeCost = C_CharacterAdvancement.GetAbilityEssenceCost(spellID)
        local teCost = C_CharacterAdvancement.GetTalentEssenceCost(spellID)
        if C_GameMode:IsGameModeActive(Enum.GameMode.WildCard) then
            return aeCost, teCost -- wc talents only cost 1x
        end
        return aeCost * currentRank, teCost * currentRank
    else
        local spellID = entry.Spells[1]
        local aeCost = C_CharacterAdvancement.GetAbilityEssenceCost(spellID)
        local teCost = C_CharacterAdvancement.GetTalentEssenceCost(spellID)
        return aeCost, teCost
    end
end 

-- DOC: CharacterAdvancementUtil.GetInvestmentBySpellID
-- What this does: Return a value that other parts of the UI need.
-- When it runs: Called when other code needs a yes/no or a piece of information.
-- Inputs:
--   - spellID: an identifier (a number/string that points to a specific thing)
-- Output: Nothing (nil).
-- What it changes: uses Character Advancement API.
function CharacterAdvancementUtil.GetInvestmentBySpellID(spellID)
    local entry = C_CharacterAdvancement.GetEntryBySpellID(spellID)

    if not entry then
        return
    end
    
    local currentRank = C_CharacterAdvancement.GetTalentRankBySpellID(spellID)

    if currentRank then
        local aeCost = C_CharacterAdvancement.GetAbilityEssenceCost(spellID)
        local teCost = C_CharacterAdvancement.GetTalentEssenceCost(spellID)
        if C_GameMode:IsGameModeActive(Enum.GameMode.WildCard) then
            return aeCost, teCost -- wc talents only cost 1x
        end
        return aeCost * currentRank, teCost * currentRank
    else
        local aeCost = C_CharacterAdvancement.GetAbilityEssenceCost(spellID)
        local teCost = C_CharacterAdvancement.GetTalentEssenceCost(spellID)
        return aeCost, teCost
    end
end

-- DOC: FormatConfirmReason
-- What this does: Call into the Character Advancement system (server/game API) and update the UI with the result.
-- When it runs: Called by other code when needed.
-- Inputs:
--   - reason: a piece of information passed in by the caller
--   - noCostString: a piece of information passed in by the caller
-- Output: A value used by other code (msg or "", noCostString).
-- What it changes: uses Character Advancement API.
local function FormatConfirmReason(reason, noCostString)
    local msg
    -- include / remove mastery spell
    if reason.Error == Enum.CAConfirmReason.IncludesMastery or reason.Error == Enum.CAConfirmReason.RemovesMastery then
        msg = _G[reason.Error] or reason
        local entry = C_CharacterAdvancement.GetEntryByInternalID(reason.Arg1)
        local name = entry and entry.Name or reason.Arg1
        msg = msg:format(name)
        
    -- reset all deactivates build
    elseif reason.Error == Enum.CAConfirmReason.AllTalentsDeactivateBuild or reason.Error == Enum.CAConfirmReason.AllAbilitiesDeactivateBuild then
        msg = "\n"..CA_CONFIRM_UNLEARN_DEACTIVATE_BUILD
        
    -- cost of unlearning
    else
        -- only includes cost string once
        local formatter = noCostString and "%s" or CA_CONFIRM_COST
        -- marks (arg1 = amount)
        if reason.Error == Enum.CAConfirmReason.Marks or reason.Error == Enum.CAConfirmReason.AllTalentsMarks or reason.Error == Enum.CAConfirmReason.AllAbilitiesMarks then
            local item = Item:CreateFromID(ItemData.MARK_OF_ASCENSION)
            msg = formatter:format(reason.Arg1 .. "  " .. item:GetIconLink(20))
        -- gold (arg1 = amount)
        elseif reason.Error == Enum.CAConfirmReason.Gold or reason.Error == Enum.CAConfirmReason.AllTalentsGold or reason.Error == Enum.CAConfirmReason.AllAbilitiesGold then
            msg = formatter:format(GetCoinTextureString(reason.Arg1))
        -- tokens (any itemID, arg1 = itemID, arg2 = amount)
        elseif reason.Error == Enum.CAConfirmReason.Token then
            local item = Item:CreateFromID(reason.Arg1)
            msg = formatter:format(reason.Arg2 .. "  " .. item:GetIconLink(20))
        elseif reason.Error == Enum.CAConfirmReason.AllTalentsToken or reason.Error == Enum.CAConfirmReason.AllAbilitiesToken then
            local item = Item:CreateFromID(reason.Arg1)
            msg = formatter:format(reason.Arg2 .. "  " .. item:GetIconLink(20))
        end
        noCostString = noCostString or true
    end
    
    return msg or "", noCostString
end

-- DOC: CharacterAdvancementUtil.ConfirmOrLearnID
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - internalID: an identifier (a number/string that points to a specific thing)
--   - preserveFilter: the filter/search text used to narrow results
-- Output: A yes/no value (boolean).
-- What it changes: uses Character Advancement API.
function CharacterAdvancementUtil.ConfirmOrLearnID(internalID, preserveFilter)
    local shouldConfirm, reasons = C_CharacterAdvancement.ShouldConfirmLearnID(internalID)
    if CharacterAdvancement then
        CharacterAdvancement.preserveFilter = preserveFilter
    end
    if not shouldConfirm then
        C_CharacterAdvancement.LearnID(internalID)
        return false
    end
    
    local confirmString = ""
    local formatted, noCostString
    for _, reason in pairs(reasons) do
        formatted, noCostString = FormatConfirmReason(reason, noCostString)
        confirmString = confirmString .. "\n" .. formatted
    end
    
    local spellList
    if type(internalID) == "number" then
        spellList = LinkUtil:GetSpellLinkInternalID(internalID)
    else
        for _, id in ipairs(internalID) do
            spellList = (spellList and spellList .. "|n" or "") .. LinkUtil:GetSpellLinkInternalID(id)
        end
    end
    StaticPopup_Show("CONFIRM_LEARN_S", spellList, confirmString, internalID)
    return true
end

-- DOC: CharacterAdvancementUtil.IsSwapSuggestion
-- What this does: Checks a condition and returns true/false.
-- When it runs: Called when other code needs a yes/no or a piece of information.
-- Inputs:
--   - internalID: an identifier (a number/string that points to a specific thing)
-- Output: A value used by other code (v.ExistingEntry, v).
-- What it changes: uses Character Advancement API.
function CharacterAdvancementUtil.IsSwapSuggestion(internalID)
    if CharacterAdvancement then
        local _, isInvertedSwap = CharacterAdvancementUtil.IsSwapping()

        for _, v in pairs(CharacterAdvancement.swapSuggestions) do
            if isInvertedSwap then
                if v.ExistingEntry.Entry == internalID then
                    return v.ExistingEntry, v
                end
            else
                if v.UpdatedEntries[1].Entry == internalID then
                    return v.UpdatedEntries[1], v
                end
            end
        end
    end
end

-- DOC: CharacterAdvancementUtil.IsSwapping
-- What this does: Checks a condition and returns true/false.
-- When it runs: Called when other code needs a yes/no or a piece of information.
-- Inputs: none
-- Output: A value used by other code (CharacterAdvancement.markedForSwap[1], C...).
-- What it changes: uses Character Advancement API.
function CharacterAdvancementUtil.IsSwapping()
    if CharacterAdvancement then
        if CharacterAdvancement.markedForSwap then
            return CharacterAdvancement.markedForSwap[1], CharacterAdvancement.markedForSwap[2]
        else
            return nil
        end
    end
end

-- DOC: CharacterAdvancementUtil.AttemptSwap
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - internalID: an identifier (a number/string that points to a specific thing)
-- Output: Nothing (nil).
-- What it changes: uses Character Advancement API.
function CharacterAdvancementUtil.AttemptSwap(internalID)
    if CharacterAdvancement then
        local sourceEntry = CharacterAdvancement.markedForSwap

        if not sourceEntry then
            return
        end

        local _, swapData = CharacterAdvancementUtil.IsSwapSuggestion(internalID)

        if not swapData then
            return
        end

        if C_CharacterAdvancement.CanSwapEntriesByID(swapData) then
            C_CharacterAdvancement.SwapEntriesByID(swapData)
            CharacterAdvancementUtil.ConfirmApplyPendingBuild()
        end
    end

end
-- DOC: CharacterAdvancementUtil.MarkForSwap
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - internalID: an identifier (a number/string that points to a specific thing)
--   - swapSuggestions: a piece of information passed in by the caller
--   - isInvertedSwap: a yes/no flag
-- Output: A yes/no value (boolean).
-- What it changes: uses Character Advancement API.
function CharacterAdvancementUtil.MarkForSwap(internalID, swapSuggestions, isInvertedSwap)
    local needsUpdate = false

    if not isInvertedSwap then
        isInvertedSwap = false
    end

    if CharacterAdvancement then

        if not internalID then 
            StaticPopup_Hide("CONFIRM_SWAP_S")

            if CharacterAdvancement.markedForSwap then
                needsUpdate = true
            end

            CharacterAdvancement.markedForSwap = nil
            CharacterAdvancement.swapSuggestions = nil
        else
            needsUpdate = true
            C_CharacterAdvancement.CancelPendingBuild()
            CharacterAdvancement.markedForSwap = {internalID, isInvertedSwap}
            CharacterAdvancement.swapSuggestions = swapSuggestions
            StaticPopup_Show("CONFIRM_SWAP_S", LinkUtil:GetSpellLinkInternalID(internalID))
        end

        if needsUpdate then
            CharacterAdvancement:RefreshSaveChangesButton()
            CharacterAdvancement:FullUpdate()
        end
    end
end

-- DOC: CharacterAdvancementUtil.ConfirmOrUnlearnID
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - internalID: an identifier (a number/string that points to a specific thing)
--   - preserveFilter: the filter/search text used to narrow results
-- Output: A yes/no value (boolean).
-- What it changes: uses Character Advancement API.
function CharacterAdvancementUtil.ConfirmOrUnlearnID(internalID, preserveFilter)
    local shouldConfirm, reasons = C_CharacterAdvancement.ShouldConfirmUnlearnID(internalID)
    if CharacterAdvancement then
        CharacterAdvancement.preserveFilter = preserveFilter
    end
    if not shouldConfirm then
        C_CharacterAdvancement.UnlearnID(internalID)
        return false
    end

    local confirmString = ""
    local formatted, noCostString
    for _, reason in pairs(reasons) do
        formatted, noCostString = FormatConfirmReason(reason, noCostString)
        confirmString = confirmString .. "\n" .. formatted
    end

    local spellList
    if type(internalID) == "number" then
        spellList = LinkUtil:GetSpellLinkInternalID(internalID)
    else
        for _, id in ipairs(internalID) do
            spellList = (spellList and spellList .. "|n" or "") .. LinkUtil:GetSpellLinkInternalID(id)
        end
    end

    StaticPopup_Show("CONFIRM_UNLEARN_S", spellList, confirmString, internalID)
    return true
end

-- DOC: CharacterAdvancementUtil.ConfirmClearBuild
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs: none
-- Output: A yes/no value (boolean).
-- What it changes: uses Character Advancement API.
function CharacterAdvancementUtil.ConfirmClearBuild()
    CharacterAdvancementUtil.MarkForSwap(nil)
    local clearType = Const.CharacterAdvancement.ClearEverything
    if C_Player:IsCustomClass() then
        clearType = Const.CharacterAdvancement.OnlyClearAllowed
    end
    C_CharacterAdvancement.ClearPendingBuild(clearType)
    local canApply, reason, traversalError, entryID, entryRank, marksCost, goldCost = C_CharacterAdvancement.CanApplyPendingBuild()
    local costString
    if marksCost > 0 then
        local markItem = Item:CreateFromID(ItemData.MARK_OF_ASCENSION)
        local markText = marksCost .. " " .. markItem:GetIconLink(22)

        costString = markText
    end

    if goldCost > 0 then
        costString = costString and (costString .. "\n") or "" .. GetMoneyString(goldCost)
    end

    if costString then
        StaticPopup_Show("CONFIRM_RESET_BUILD", costString)
    else
        StaticPopup_Show("CONFIRM_RESET_BUILD_NO_COST")
    end
    return true
end

-- DOC: CharacterAdvancementUtil.ConfirmOrUnlearnAllTalents
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs: none
-- Output: A yes/no value (boolean).
-- What it changes: uses Character Advancement API.
function CharacterAdvancementUtil.ConfirmOrUnlearnAllTalents()
    local shouldConfirm, reasons = C_CharacterAdvancement.ShouldConfirmUnlearnAllTalents()
    if not shouldConfirm then
        C_CharacterAdvancement.UnlearnAllTalents()
        return false
    end

    local confirmString = ""
    local formatted, noCostString
    for _, reason in ipairs(reasons) do
        formatted, noCostString = FormatConfirmReason(reason, noCostString)
        confirmString = confirmString .. "\n" .. formatted
    end

    StaticPopup_Show("CONFIRM_UNLEARN_ALL_S", TALENTS, confirmString, C_CharacterAdvancement.UnlearnAllTalents)
    return true
end

-- DOC: CharacterAdvancementUtil.ConfirmOrUnlearnAllSpells
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs: none
-- Output: A yes/no value (boolean).
-- What it changes: uses Character Advancement API.
function CharacterAdvancementUtil.ConfirmOrUnlearnAllSpells()
    local shouldConfirm, reasons = C_CharacterAdvancement.ShouldConfirmUnlearnAllSpells()
    if not shouldConfirm then
        C_CharacterAdvancement.UnlearnAllSpells()
        return false
    end

    local confirmString = ""
    local formatted, noCostString
    for _, reason in ipairs(reasons) do
        formatted, noCostString = FormatConfirmReason(reason, noCostString)
        confirmString = confirmString .. "\n" .. formatted
    end
    StaticPopup_Show("CONFIRM_UNLEARN_ALL_S", ABILITIES, confirmString, C_CharacterAdvancement.UnlearnAllSpells)
    return true
end

-- DOC: CharacterAdvancementUtil.ConfirmClearTabBuild
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - class: a piece of information passed in by the caller
--   - tab: a piece of information passed in by the caller
-- Output: A yes/no value (boolean).
-- What it changes: uses Character Advancement API.
function CharacterAdvancementUtil.ConfirmClearTabBuild(class, tab)
    CharacterAdvancementUtil.MarkForSwap(nil)
    local clearType = Const.CharacterAdvancement.ClearEverything
    if C_Player:IsCustomClass() then
        clearType = Const.CharacterAdvancement.OnlyClearAllowed
    end
    C_CharacterAdvancement.ClearPendingBuildByTab(class, tab, clearType)
    local canApply, reason, traversalError, entryID, entryRank, marksCost, goldCost = C_CharacterAdvancement.CanApplyPendingBuild()
    local costString
    if marksCost > 0 then
        local markItem = Item:CreateFromID(ItemData.MARK_OF_ASCENSION)
        local markText = marksCost .. " " .. markItem:GetIconLink(22)

        costString = markText
    end

    if goldCost > 0 then
        costString = costString and (costString .. "\n") or "" .. GetMoneyString(goldCost)
    end

    if costString then
        StaticPopup_Show("CONFIRM_RESET_BUILD", costString)
    else
        StaticPopup_Show("CONFIRM_RESET_BUILD_NO_COST")
    end
    return true
end


-- DOC: CharacterAdvancementUtil.ConfirmApplyPendingBuild
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs: none
-- Output: A yes/no value (boolean).
-- What it changes: uses Character Advancement API.
function CharacterAdvancementUtil.ConfirmApplyPendingBuild()
    CharacterAdvancementUtil.MarkForSwap(nil)
    local canApply, reason, traversalError, entryID, entryRank, marksCost, goldCost = C_CharacterAdvancement.CanApplyPendingBuild()
    local costString
    if marksCost > 0 then
        local markItem = Item:CreateFromID(ItemData.MARK_OF_ASCENSION)
        local markText = marksCost .. " " .. markItem:GetIconLink(22)

        costString = markText
    end

    if goldCost > 0 then
        costString = costString and (costString .. "\n") or "" .. GetMoneyString(goldCost)
    end

    if costString then
        StaticPopup_Show("CONFIRM_APPLY_PENDING_BUILD", costString)
    else
        --StaticPopup_Show("CONFIRM_APPLY_PENDING_BUILD_NO_COST")
        C_CharacterAdvancement.ApplyPendingBuild()
        if BuildCreatorUtil.GetPendingBuildID() then
            C_BuildCreator.ActivateBuild(BuildCreatorUtil.GetPendingBuildID(), true, true)
            BuildCreatorUtil.ClearPendingBuildID()
        end
    end
    return true
end

-- DOC: CharacterAdvancementUtil.IsUnlearnFreeForID
-- What this does: Checks a condition and returns true/false.
-- When it runs: Called when other code needs a yes/no or a piece of information.
-- Inputs:
--   - internalID: an identifier (a number/string that points to a specific thing)
-- Output: Nothing (nil).
-- What it changes: uses Character Advancement API.
function CharacterAdvancementUtil.IsUnlearnFreeForID(internalID)
    local entry = C_CharacterAdvancement.GetEntryByInternalID(internalID)
    if not entry then
        return
    end
    
    return bit.contains(entry.Flags, Enum.CharacterAdvancementFlag.FreeUnlearn)
end

-- DOC: CharacterAdvancementUtil.IsUnlearnFreeForSpellID
-- What this does: Checks a condition and returns true/false.
-- When it runs: Called when other code needs a yes/no or a piece of information.
-- Inputs:
--   - spellID: an identifier (a number/string that points to a specific thing)
-- Output: Nothing (nil).
-- What it changes: uses Character Advancement API.
function CharacterAdvancementUtil.IsUnlearnFreeForSpellID(spellID)
    local entry = C_CharacterAdvancement.GetEntryBySpellID(spellID)
    if not entry then
        return
    end
    
    return bit.contains(entry.Flags, Enum.CharacterAdvancementFlag.FreeUnlearn)
end

-- DOC: CharacterAdvancementUtil.GetGrantingMasteryBySpellID
-- What this does: Return a value that other parts of the UI need.
-- When it runs: Called when other code needs a yes/no or a piece of information.
-- Inputs:
--   - spellID: an identifier (a number/string that points to a specific thing)
-- Output: Nothing (nil).
-- What it changes: uses Character Advancement API.
function CharacterAdvancementUtil.GetGrantingMasteryBySpellID(spellID)
    local entry = C_CharacterAdvancement.GetEntryBySpellID(spellID)
    if not entry then
        return
    end

    for _, masteryID in ipairs(entry.Masteries) do
        if C_CharacterAdvancement.IsKnownID(masteryID) then
            return masteryID
        end
    end
end

-- DOC: CharacterAdvancementUtil.GetGrantingMasteryByID
-- What this does: Return a value that other parts of the UI need.
-- When it runs: Called when other code needs a yes/no or a piece of information.
-- Inputs:
--   - internalID: an identifier (a number/string that points to a specific thing)
-- Output: Nothing (nil).
-- What it changes: uses Character Advancement API.
function CharacterAdvancementUtil.GetGrantingMasteryByID(internalID)
    local entry = C_CharacterAdvancement.GetEntryByInternalID(internalID)
    if not entry then
        return
    end

    for _, masteryID in ipairs(entry.Masteries) do
        if C_CharacterAdvancement.IsKnownID(masteryID) then
            return masteryID
        end
    end
end

-- DOC: CharacterAdvancementUtil.GetBuildWebURL
-- What this does: Return a value that other parts of the UI need.
-- When it runs: Called when other code needs a yes/no or a piece of information.
-- Inputs: none
-- Output: A value used by other code (format("https://ascension.gg/v2/builder/...).
-- What it changes: uses Character Advancement API.
function CharacterAdvancementUtil.GetBuildWebURL()
    local buildLink = C_CharacterAdvancement.ExportBuild(true)
    if buildLink then
        if C_Realm.IsLive() then
            return format("https://ascension.gg/v2/builder/area-52/overview/%s", buildLink)
        else
            -- this might need to be changed
            return format("https://ascension.gg/v2/builder/elune/overview/%s", buildLink)
        end
    end
end

-- DOC: CharacterAdvancementUtil.GetBuildFromURL
-- What this does: Return a value that other parts of the UI need.
-- When it runs: Called when other code needs a yes/no or a piece of information.
-- Inputs:
--   - url: a piece of information passed in by the caller
-- Output: A value used by other code (buildLink or url).
-- What it changes: updates UI/state.
function CharacterAdvancementUtil.GetBuildFromURL(url)
    local buildLink = url:match("overview/(.*)")
    return buildLink or url
end

function CharacterAdvancementUtil.SendSystemLearnTalent(internalID, rank)
    local link = LinkUtil:GetTalentLinkByID(internalID, rank)
    if link then
        SendSystemMessage(ERR_LEARN_TALENT_S:format(link))
    end
end

-- DOC: CharacterAdvancementUtil.SendSystemUpgradeTalent
-- What this does: Do a specific piece of work related to 'SendSystemUpgradeTalent'.
-- When it runs: Called by other code when needed.
-- Inputs:
--   - internalID: an identifier (a number/string that points to a specific thing)
--   - rank: a piece of information passed in by the caller
-- Output: A value used by other code (BuildCreatorUtil.IsPickingSpells()).
-- What it changes: updates UI/state.
function CharacterAdvancementUtil.SendSystemUpgradeTalent(internalID, rank)
    local link = LinkUtil:GetTalentLinkByID(internalID, rank)
    if link then
        SendSystemMessage(ERR_UPGRADE_TALENT_S:format(link))
    end
end

function CharacterAdvancementUtil.SendSystemLearnSpell(internalID)
    local link = LinkUtil:GetSpellLinkInternalID(internalID)
    if link then
        SendSystemMessage(ERR_LEARN_SPELL_S:format(link))
    end
end

-- DOC: CharacterAdvancementUtil.InitializeFilter
-- What this does: Do a specific piece of work related to 'InitializeFilter'.
-- When it runs: Called by other code when needed.
-- Inputs:
--   - filter: the filter/search text used to narrow results
--   - OnFilterChangedClosure: the filter/search text used to narrow results
--   - noKnownFlag: a piece of information passed in by the caller
-- Output: A value used by other code (BuildCreatorUtil.IsPickingSpells()).
-- What it changes: updates UI/state.
function CharacterAdvancementUtil.InitializeFilter(filter, OnFilterChangedClosure, noKnownFlag)
    filter:RegisterCallback("OnFilterChanged", OnFilterChangedClosure)

    local function IsUsingBuildCreator()
        return BuildCreatorUtil.IsPickingSpells()
    end

    local function IsNotUsingBuildCreator()
        return not BuildCreatorUtil.IsPickingSpells()
    end

    if not noKnownFlag then -- in wildcard mass roll those filters are not needed
        -- known, build creator
        filter:AddFilterOption("FILTER_KNOWN", filter:CreateFilterInfo("CA_FILTER_KNOWN_IN_BUILD", nil, nil, IsUsingBuildCreator))
        filter:AddFilterOption("FILTER_UNKNOWN", filter:CreateFilterInfo("CA_FILTER_UNKNOWN_IN_BUILD", nil, nil, IsUsingBuildCreator))
        -- known, not build creator
        filter:AddFilterOption("FILTER_KNOWN", filter:CreateFilterInfo("CA_FILTER_KNOWN", nil, nil, IsNotUsingBuildCreator))
        filter:AddFilterOption("FILTER_UNKNOWN", filter:CreateFilterInfo("CA_FILTER_UNKNOWN", nil, nil, IsNotUsingBuildCreator))

        filter:AddOptionSpacer()

        -- can add, build creator
        filter:AddFilterOption("FILTER_CAN_ADD", filter:CreateFilterInfo("CA_FILTER_CAN_ADD", nil, nil, IsUsingBuildCreator))
        filter:AddFilterOption("FILTER_CAN_REMOVE", filter:CreateFilterInfo("CA_FILTER_CAN_REMOVE", nil, nil, IsUsingBuildCreator))
        -- can learn, not build creator
        filter:AddFilterOption("FILTER_CAN_LEARN", filter:CreateFilterInfo("CA_FILTER_CAN_LEARN", nil, nil, IsNotUsingBuildCreator))
        filter:AddFilterOption("FILTER_CAN_UNLEARN", filter:CreateFilterInfo("CA_FILTER_CAN_UNLEARN", nil, nil, IsNotUsingBuildCreator))

        -- quality filter
        filter:AddOptionSpacer()
    end

    filter:AddCategoryOption("QUALITY", QUALITY)
    filter:AddSubFilterOption("QUALITY", "FILTER_QUALITY_NORMAL", filter:CreateFilterInfo("ITEM_QUALITY1_DESC", ITEM_QUALITY_COLORS[1]))
    filter:AddSubFilterOption("QUALITY", "FILTER_QUALITY_UNCOMMON", filter:CreateFilterInfo("ITEM_QUALITY2_DESC", ITEM_QUALITY_COLORS[2]))
    filter:AddSubFilterOption("QUALITY", "FILTER_QUALITY_RARE", filter:CreateFilterInfo("ITEM_QUALITY3_DESC", ITEM_QUALITY_COLORS[3]))
    filter:AddSubFilterOption("QUALITY", "FILTER_QUALITY_EPIC", filter:CreateFilterInfo("ITEM_QUALITY4_DESC", ITEM_QUALITY_COLORS[4]))
    filter:AddSubFilterOption("QUALITY", "FILTER_QUALITY_LEGENDARY", filter:CreateFilterInfo("ITEM_QUALITY5_DESC", ITEM_QUALITY_COLORS[5]))

    -- class filter
    filter:AddCategoryOption("CLASS", CLASS)
    -- reborn filter [general | class > specs]
    if IsDefaultClass() then
        filter:AddSubFilterOption("CLASS", "FILTER_CLASS_REBORN_GENERAL", filter:CreateFilterInfo("CA_FILTER_CLASS_REBORN_GENERAL"))
        local class = C_Player:GetClass()
        local classFilterKey = "FILTER_CLASS_REBORN_"..class
        if class == "DEATHKNIGHT" then
            classFilterKey = "FILTER_CLASS_REBORN_DEATH_KNIGHT"
        end
        filter:AddSubFilterOption("CLASS", classFilterKey, filter:CreateFilterInfo(ClassInfoUtil.GetColoredClassName(class), nil, "groupfinder-icon-class-"..class))
    
    else
        -- normal filter [general | classes > specs]
        filter:AddSubFilterOption("CLASS", "FILTER_CLASS_GENERAL", filter:CreateFilterInfo("CA_FILTER_CLASS_GENERAL"))
        for _, class in ipairs(CHARACTER_ADVANCEMENT_CLASS_ORDER) do
            local classFilterKey = "FILTER_CLASS_"..class
            if class == "DEATHKNIGHT" then
                classFilterKey = "FILTER_CLASS_DEATH_KNIGHT"
            end
            filter:AddSubFilterOption("CLASS", classFilterKey, filter:CreateFilterInfo(ClassInfoUtil.GetColoredClassName(class), nil, "groupfinder-icon-class-"..class))
        end
    end

    filter:AddOptionSpacer()
    filter:AddFilterOption("FILTER_TYPE_ABILITY", filter:CreateFilterInfo("CA_FILTER_TYPE_ABILITY"))
    filter:AddFilterOption("FILTER_TYPE_TALENT", filter:CreateFilterInfo("CA_FILTER_TYPE_TALENT"))
    if IsDefaultClass() then
        filter:AddFilterOption("FILTER_TYPE_TRAIT", filter:CreateFilterInfo("CA_FILTER_TYPE_TRAIT"))
    end
end

-- DOC: CharacterAdvancementUtil.InitializeSpellTagFilter
-- What this does: Call into the Character Advancement system (server/game API) and update the UI with the result.
-- When it runs: Called by other code when needed.
-- Inputs:
--   - filter: the filter/search text used to narrow results
--   - OnFilterChangedClosure: the filter/search text used to narrow results
--   - noKnownFlag: a piece of information passed in by the caller
-- Output: A value used by other code (filers_no_spell_tags, filters_spell_tags).
-- What it changes: uses Character Advancement API.
function CharacterAdvancementUtil.InitializeSpellTagFilter(filter, OnFilterChangedClosure, noKnownFlag)
    CharacterAdvancementUtil.InitializeFilter(filter, OnFilterChangedClosure, noKnownFlag)
    function filter:GetFilter()
        local filters = self.filters

        local filers_no_spell_tags = {}
        local filters_spell_tags = {}

        for filter in pairs(filters) do
            local _,_, spellTagID = string.find(filter, "FILTER_SPELLTAG_(%d+)")
            if spellTagID then
                table.insert(filters_spell_tags, tonumber(spellTagID))
            else
                filers_no_spell_tags[filter] = true
            end
        end

        return filers_no_spell_tags, filters_spell_tags
    end

    filter:AddOptionSpacer()
    --filter:AddCategoryOption("TAGS", "Spell Tags")

    local rootTags = C_CharacterAdvancement.GetRootSpellTagTypes()

    local tags, subTags, tagName, icon

    for _, rootTag in pairs(rootTags) do
        tagName, icon = C_CharacterAdvancement.GetSpellTagTypeDisplayInfo(rootTag)
        if not tagName then
            tagName = "SPELLTAG_CATEGORY"..rootTag
        end
        filter:AddCategoryOption("SPELLTAG_CATEGORY"..rootTag, tagName, nil, icon)

        tags = C_CharacterAdvancement.GetSpellTagTypes(rootTag)

        if tags then
            for _, tagID in pairs(tags) do

                tagName, icon = C_CharacterAdvancement.GetSpellTagTypeDisplayInfo(tagID)

                if not tagName then
                    tagName = "FILTER_SPELLTAG_"..tagID
                end

                filter:AddSubFilterOption("SPELLTAG_CATEGORY"..rootTag, "FILTER_SPELLTAG_"..tagID, filter:CreateFilterInfo(tagName, nil, icon))

                subTags = C_CharacterAdvancement.GetSpellTagTypes(tagID)

                if subTags and next(subTags) then
                    for _, subTagID in pairs(subTags) do
                        tagName, icon = C_CharacterAdvancement.GetSpellTagTypeDisplayInfo(subTagID)

                        if not tagName then
                            tagName = "FILTER_SPELLTAG_"..subTagID
                        end

                        filter:AddSubFilterOption("FILTER_SPELLTAG_"..tagID, "FILTER_SPELLTAG_"..subTagID, filter:CreateFilterInfo(tagName, nil, icon))
                    end
                end
            end
        end
    end
end

-- DOC: CharacterAdvancementUtil.GetEntryPosition
-- What this does: Return a value that other parts of the UI need.
-- When it runs: Called when other code needs a yes/no or a piece of information.
-- Inputs:
--   - entry: a piece of information passed in by the caller
-- Output: A value used by other code (entry.PositionX, entry.PositionY).
-- What it changes: updates UI/state.
function CharacterAdvancementUtil.GetEntryPosition(entry)
    local classFile = CharacterAdvancementUtil.GetClassFileByDBC(entry.Class)
    if Enum.Class[classFile] and Enum.Class[classFile] >= Enum.Class.CustomStart then
        return entry.PositionX, entry.PositionY
    end
    
    return entry.Column, entry.Row
end

-- DOC: CharacterAdvancementUtil.GetBackgroundAtlas
-- What this does: Return a value that other parts of the UI need.
-- When it runs: Called when other code needs a yes/no or a piece of information.
-- Inputs:
--   - className: a piece of information passed in by the caller
--   - spec: information about a specialization (spec) choice
-- Output: A value used by other code (atlas).
-- What it changes: updates UI/state.
function CharacterAdvancementUtil.GetBackgroundAtlas(className, spec)
    if className and spec then
        local atlas = "talents-background-"..className:lower().."-"..spec:lower()
        if AtlasUtil:AtlasExists(atlas) then
            return atlas
        end
    end

    return "talents-background-druid-restoration"
end

-- DOC: CharacterAdvancementUtil.GetThumbnailAtlas
-- What this does: Return a value that other parts of the UI need.
-- When it runs: Called when other code needs a yes/no or a piece of information.
-- Inputs:
--   - className: a piece of information passed in by the caller
--   - spec: information about a specialization (spec) choice
-- Output: A value used by other code (atlas).
-- What it changes: updates UI/state.
function CharacterAdvancementUtil.GetThumbnailAtlas(className, spec)
    if className and spec then
        local atlas = "spec-thumbnail-"..className:lower().."-"..spec:lower()
        if AtlasUtil:AtlasExists(atlas) then
            return atlas
        end
    end

    return "spec-thumbnail-hero-hero"
end

local OkErrors = {
    [Enum.CALearnResult.BadGameMode] = true,
    [Enum.CALearnResult.NotInBattleground] = true,
    --[Enum.CALearnResult.MissingConnection] = true,
    [Enum.CALearnResult.NotInCombat] = true,
    [Enum.CALearnResult.Invulnerable] = true,
    [Enum.CALearnResult.NoWildCard] = true,
    [Enum.CALearnResult.NoDead] = true,
    [Enum.CALearnResult.NoTalentEssence] = true,
    [Enum.CALearnResult.NoAbilityEssence] = true,
    --[Enum.CALearnResult.LowLevel] = true,
    --[Enum.CALearnResult.MinAbilityEssenceInvestment] = true,
    --[Enum.CALearnResult.MinTalentEssenceInvestment] = true,
    [Enum.CALearnResult.MaxUncommon] = true,
    [Enum.CALearnResult.MaxRare] = true,
    [Enum.CALearnResult.MaxEpic] = true,
    [Enum.CALearnResult.MaxLegendary] = true,

    [Enum.CAUnlearnResult.MinAbilityEssenceInvestment] = true,
    [Enum.CAUnlearnResult.MinTalentEssenceInvestment] = true,
    [Enum.CAUnlearnResult.BadGameMode] = true,
    [Enum.CAUnlearnResult.NotInBattleground] = true,
    [Enum.CAUnlearnResult.NotInCombat] = true,
    --[Enum.CAUnlearnResult.MissingConnection] = true,
    [Enum.CAUnlearnResult.NoScrollOfFortune] = true,
    [Enum.CAUnlearnResult.NoWildCard] = true,
}
-- DOC: CharacterAdvancementUtil.GetSpellErrorColor
-- What this does: Return a value that other parts of the UI need.
-- When it runs: Called when other code needs a yes/no or a piece of information.
-- Inputs:
--   - error: a piece of information passed in by the caller
-- Output: A value used by other code (HIGHLIGHT_FONT_COLOR, true).
-- What it changes: updates UI/state.
function CharacterAdvancementUtil.GetSpellErrorColor(error)
    if OkErrors[error] then
        return HIGHLIGHT_FONT_COLOR, true
    end

    return SPELL_DISALLOWED_COLOR, false
end

-- DOC: CharacterAdvancementUtil.GetClassFileForEntry
-- What this does: Return a value that other parts of the UI need.
-- When it runs: Called when other code needs a yes/no or a piece of information.
-- Inputs:
--   - entry: a piece of information passed in by the caller
-- Output: Nothing (nil).
-- What it changes: updates UI/state.
function CharacterAdvancementUtil.GetClassFileForEntry(entry)
    if not entry or not entry.Class or not entry.Tab then
        return
    end
    
    return ClassConversions.ClassDBCToFile[entry.Class], ClassConversions.SpecDBCToFile[entry.Tab]
end

-- DOC: CharacterAdvancementUtil.MustUseLegacyAPI
-- What this does: Do a specific piece of work related to 'MustUseLegacyAPI'.
-- When it runs: Called by other code when needed.
-- Inputs: none
-- Output: A value used by other code (not canUsePending).
-- What it changes: updates UI/state.
function CharacterAdvancementUtil.MustUseLegacyAPI()
    local configEnabled = C_Config.GetBoolConfig("CONFIG_LEGACY_CHARACTER_ADVANCEMENT_ENABLED")
    local canUsePending = not C_Player:IsHero() or configEnabled == nil or configEnabled == true
    return not canUsePending
end

CharacterAdvancementUtil.NodeArtSet = {
    Square = {
        --iconMask = nil,
        --shadow = nil,
        --normal = nil,
        --disabled = nil,
        --selectable = nil,
        --maxed = nil,
        --locked = nil,
        --refundInvalid = nil,
        --glow = nil,
        --ghost = nil,
        --spendFont = nil,
    },

    Circle = {
    },

    Choice = {
    },

    LargeSquare = {
    },

    LargeCircle = {
    },
}

-- DOC: CharacterAdvancementUtil.GetClassDBCByFile
-- What this does: Return a value that other parts of the UI need.
-- When it runs: Called when other code needs a yes/no or a piece of information.
-- Inputs:
--   - classFile: a piece of information passed in by the caller
-- Output: A value used by other code (ClassConversions.ClassFileToDBC[classFil...).
-- What it changes: updates UI/state.
function CharacterAdvancementUtil.GetClassDBCByFile(classFile)
    return ClassConversions.ClassFileToDBC[classFile]
end

function CharacterAdvancementUtil.GetSpecDBCByFile(specFile)
    return ClassConversions.SpecFileToDBC[specFile]
end

-- DOC: CharacterAdvancementUtil.GetClassFileByDBC
-- What this does: Return a value that other parts of the UI need.
-- When it runs: Called when other code needs a yes/no or a piece of information.
-- Inputs:
--   - classDBC: a piece of information passed in by the caller
-- Output: A value used by other code (ClassConversions.ClassDBCToFile[classDBC...).
-- What it changes: updates UI/state.
function CharacterAdvancementUtil.GetClassFileByDBC(classDBC)
    return ClassConversions.ClassDBCToFile[classDBC]
end

function CharacterAdvancementUtil.GetSpecFileByDBC(specDBC)
    return ClassConversions.SpecDBCToFile[specDBC]
end

ClassConversions = {
    ClassDBCToFile = {
        ["Hunter"] = "HUNTER",
        ["Warlock"] = "WARLOCK",
        ["Priest"] = "PRIEST",
        ["Paladin"] = "PALADIN",
        ["Mage"] = "MAGE",
        ["Rogue"] = "ROGUE",
        ["Druid"] = "DRUID",
        ["Shaman"] = "SHAMAN",
        ["Warrior"] = "WARRIOR",
        ["DeathKnight"] = "DEATHKNIGHT",
        ["General"] = "GENERAL",
        ["Necromancer"] = "NECROMANCER",
        ["Pyromancer"] = "PYROMANCER",
        ["Cultist"] = "CULTIST",
        ["Starcaller"] = "STARCALLER",
        ["SunCleric"] = "SUNCLERIC",
        ["Tinker"] = "TINKER",
        ["Runemaster"] = "SPIRITMAGE",
        ["Primalist"] = "WILDWALKER",
        ["Reaper"] = "REAPER",
        ["Venomancer"] = "PROPHET",
        ["Chronomancer"] = "CHRONOMANCER",
        ["SonOfArugal"] = "SONOFARUGAL",
        ["Guardian"] = "GUARDIAN",
        ["Stormbringer"] = "STORMBRINGER",
        ["DemonHunter"] = "DEMONHUNTER",
        ["Barbarian"] = "BARBARIAN",
        ["WitchDoctor"] = "WITCHDOCTOR",
        ["WitchHunter"] = "WITCHHUNTER",
        ["KnightOfXoroth"] = "FLESHWARDEN",
        ["Monk"] = "MONK",
        ["Ranger"] = "RANGER",
        ["ConquestOfAzeroth"] = "CONQUESTOFAZEROTH",
        ["Hero"] = "HERO",
    },
    SpecDBCToFile = {
        ["Survival"] = "SURVIVAL",
        ["Marksmanship"] = "MARKSMANSHIP",
        ["BeastMastery"] = "BEASTMASTERY",
        ["Fury"] = "FURY",
        ["Arms"] = "ARMS",
        ["Protection"] = "PROTECTION",
        ["Combat"] = "COMBAT",
        ["Subtlety"] = "SUBTLETY",
        ["Assassination"] = "ASSASSINATION",
        ["Arcane"] = "ARCANE",
        ["Frost"] = "FROST",
        ["Fire"] = "FIRE",
        ["Holy"] = "HOLY",
        ["Shadow"] = "SHADOW",
        ["Discipline"] = "DISCIPLINE",
        ["Affliction"] = "AFFLICTION",
        ["Demonology"] = "DEMONOLOGY",
        ["Destruction"] = "DESTRUCTION",
        ["Restoration"] = "RESTORATION",
        ["Feral"] = "FERAL",
        ["Balance"] = "BALANCE",
        ["Elemental"] = "ELEMENTAL",
        ["Enhancement"] = "ENHANCEMENT",
        ["Retribution"] = "RETRIBUTION",
        ["Blood"] = "BLOOD",
        ["Unholy"] = "UNHOLY",
        ["General1"] = "GENERAL1",
        ["General2"] = "GENERAL2",
        ["General3"] = "GENERAL3",
        ["Brutality"] = "BRUTALITY",
        ["Tactics"] = "TACTICS",
        ["Ancestry"] = "ANCESTRY",
        ["Voodoo"] = "VOODOO",
        ["Brewing"] = "BREWING",
        ["Shadowhunting"] = "SHADOWHUNTING",
        ["Slaying"] = "SLAYING",
        ["Felblood"] = "FELBLOOD",
        ["Boltslinger"] = "BOLTSLINGER",
        ["Darkness"] = "DARKNESS",
        ["Inquisition"] = "INQUISITION",
        ["Lightning"] = "LIGHTNING",
        ["Wind"] = "WIND",
        ["Gifts"] = "GIFTS",
        ["War"] = "WAR",
        ["Hellfire"] = "HELLFIRE",
        ["Defiance"] = "DEFIANCE",
        ["Inspiration"] = "INSPIRATION",
        ["Gladiator"] = "GLADIATOR",
        ["Fighting"] = "FIGHTING",
        ["Runes"] = "RUNES",
        ["Ferocity"] = "FEROCITY",
        ["Packleader"] = "PACKLEADER",
        ["Archery"] = "ARCHERY",
        ["Dueling"] = "DUELING",
        ["Duality"] = "DUALITY",
        ["Time"] = "TIME",
        ["Displacement"] = "DISPLACEMENT",
        ["Death"] = "DEATH",
        ["Rime"] = "RIME",
        ["Animation"] = "ANIMATION",
        ["Incineration"] = "INCINERATION",
        ["Draconic"] = "DRACONIC",
        ["Godblade"] = "GODBLADE",
        ["Corruption"] = "CORRUPTION",
        ["Influence"] = "INFLUENCE",
        ["AstralWarfare"] = "ASTRALWARFARE",
        ["Tides"] = "TIDES",
        ["Moonbow"] = "MOONBOW",
        ["Piety"] = "PIETY",
        ["Blessings"] = "BLESSINGS",
        ["Seraphim"] = "SERAPHIM",
        ["Firearms"] = "FIREARMS",
        ["Invention"] = "INVENTION",
        ["Mechanics"] = "MECHANICS",
        ["Venom"] = "VENOM",
        ["Stalking"] = "STALKING",
        ["Fortitude"] = "FORTITUDE",
        ["Reaping"] = "REAPING",
        ["Soul"] = "SOUL",
        ["Domination"] = "DOMINATION",
        ["Primal"] = "PRIMAL",
        ["Geomancy"] = "GEOMANCY",
        ["Life"] = "LIFE",
        ["Runic"] = "RUNIC",
        ["Riftblade"] = "RIFTBLADE",
        ["Class"] = "CLASS",
        ["Bulwark"] = "BULWARK",
        ["Hydromancy"] = "HYDROMANCY",
        ["Valkyr"] = "VALKYR",
        ["MountainKing"] = "MOUNTAINKING",
        ["Vizier"] = "VIZIER",
        ["Fleshweaver"] = "FLESHWEAVER",
        ["WitchKnight"] = "WITCHKNIGHT",
        ["None"] = "NONE",
        ["Hero"] = "HERO",
    },
}

if IsDefaultClass() then
    ClassConversions.ClassDBCToFile["RebornHunter"] = "HUNTER"
    ClassConversions.ClassDBCToFile["RebornWarlock"] = "WARLOCK"
    ClassConversions.ClassDBCToFile["RebornPriest"] = "PRIEST"
    ClassConversions.ClassDBCToFile["RebornPaladin"] = "PALADIN"
    ClassConversions.ClassDBCToFile["RebornMage"] = "MAGE"
    ClassConversions.ClassDBCToFile["RebornRogue"] = "ROGUE"
    ClassConversions.ClassDBCToFile["RebornDruid"] = "DRUID"
    ClassConversions.ClassDBCToFile["RebornShaman"] = "SHAMAN"
    ClassConversions.ClassDBCToFile["RebornWarrior"] = "WARRIOR"
    ClassConversions.ClassDBCToFile["RebornDeathKnight"] = "DEATHKNIGHT"

    ClassConversions.ClassDBCToFile["Hunter"] = nil
    ClassConversions.ClassDBCToFile["Warlock"] = nil
    ClassConversions.ClassDBCToFile["Priest"] = nil
    ClassConversions.ClassDBCToFile["Paladin"] = nil
    ClassConversions.ClassDBCToFile["Mage"] = nil
    ClassConversions.ClassDBCToFile["Rogue"] = nil
    ClassConversions.ClassDBCToFile["Druid"] = nil
    ClassConversions.ClassDBCToFile["Shaman"] = nil
    ClassConversions.ClassDBCToFile["Warrior"] = nil
    ClassConversions.ClassDBCToFile["DeathKnight"] = nil
end

ClassConversions.ClassFileToDBC = table.invert(ClassConversions.ClassDBCToFile)
ClassConversions.SpecFileToDBC = table.invert(ClassConversions.SpecDBCToFile)

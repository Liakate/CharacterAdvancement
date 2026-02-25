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

--[[CA_GATE_TOOLTIP_FORMAT_LOCAL = CA_GATE_TOOLTIP_FORMAT_LOCAL or "Spend |cffFFFFFF%d|r more Talent Essence in |cffFFFFFFcurrent|r tree to unlock this row"
CA_GATE_TOOLTIP_FORMAT_GLOBAL = CA_GATE_TOOLTIP_FORMAT_GLOBAL or "Spend |cffFFFFFF%d|r more Talent Essence points in |cffFFFFFFany|r tree to unlock rows below"
CA_GATE_CLASS_POINTS_TEXT = CA_GATE_CLASS_POINTS_TEXT or "Requires Class Points: %s"
CA_GATE_INFO = CA_GATE_INFO or "You have |cffFFFFFF%s|r %s Talent Essence Invested"
CA_GATE_INFO_CLASS_POINTS = CA_GATE_INFO_CLASS_POINTS or "You have |cffFFFFFF%s|r %s |cffFFFFFFClass Points|r"
CA_GATE_INFO_CLASS_POINTS_HINT = CA_GATE_INFO_CLASS_POINTS_HINT or "Class Points are: TODO: FILL THIS TEXT"]]--

CA_POINTS_GLOBAL_STRING = CA_POINTS_GLOBAL_STRING or "Points: %s"

local CA_GATE_ICON_GLOBAL_TE = "Interface\\Icons\\inv_custom_talentessence"
local CA_GATE_ICON_GLOBAL_AE = "Interface\\Icons\\inv_custom_abilityessence"

-------------------------------------------------------------------------------
--                           Gate Mixin Structure --
-------------------------------------------------------------------------------
--
-- gate condition mixin
--
CAGateConditionMixin = {}

-- DOC: CAGateConditionMixin:OnLoad
-- What this does: Sets up this UI element: prepares data, connects events, and sets initial visuals.
-- When it runs: Runs once when this UI element is created/loaded.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: A value used by other code (self.isMet).
-- What it changes: updates UI/state.
function CAGateConditionMixin:OnLoad()
    self.required = -1 -- filled dynamically
    self.left = 0
    self.isMet = 0
end

function CAGateConditionMixin:IsMet()
    return self.isMet
end

-- DOC: CAGateConditionMixin:SetIsMet
-- What this does: Set a value on this UI element and update related visuals.
-- When it runs: Called when code needs to store a value and/or update the visuals.
-- Inputs:
--   - self: the UI object this function belongs to
--   - value: a value to store/apply
-- Output: A value used by other code (self.left).
-- What it changes: updates UI/state.
function CAGateConditionMixin:SetIsMet(value)
    self.isMet = value
end

function CAGateConditionMixin:SetLeft(value)
    self.left = value
end

-- DOC: CAGateConditionMixin:GetLeft
-- What this does: Return a value that other parts of the UI need.
-- When it runs: Called when other code needs a yes/no or a piece of information.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: A value used by other code (self.left).
-- What it changes: updates UI/state.
function CAGateConditionMixin:GetLeft()
    return self.left
end

function CAGateConditionMixin:SetRequired(value)
    self.required = value
end

-- DOC: CAGateConditionMixin:GetRequired
-- What this does: Return a value that other parts of the UI need.
-- When it runs: Called when other code needs a yes/no or a piece of information.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: A value used by other code (self.required).
-- What it changes: shows/hides UI pieces.
function CAGateConditionMixin:GetRequired()
    return self.required
end

--
-- gate info mixin
--
CAGateInfoMixin = {}

-- DOC: CAGateInfoMixin:OnLoad
-- What this does: Sets up this UI element: prepares data, connects events, and sets initial visuals.
-- When it runs: Runs once when this UI element is created/loaded.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: A value used by other code (self.conditions[name]).
-- What it changes: shows/hides UI pieces.
function CAGateInfoMixin:OnLoad()
    self.tier = -1
    self.topLeftNode = nil
    self.conditions = {}

    self.conditions["TAB"] = CreateFromMixinsAndLoad(CAGateConditionMixin)
    --self.conditions["CLASS"] = CreateFromMixinsAndLoad(CAGateConditionMixin)
    self.conditions["GLOBAL"] = CreateFromMixinsAndLoad(CAGateConditionMixin)
end

-- DOC: CAGateInfoMixin:GetCondition
-- What this does: Return a value that other parts of the UI need.
-- When it runs: Called when other code needs a yes/no or a piece of information.
-- Inputs:
--   - self: the UI object this function belongs to
--   - name: a piece of information passed in by the caller
-- Output: A value used by other code (self.conditions[name]).
-- What it changes: shows/hides UI pieces.
function CAGateInfoMixin:GetCondition(name)
    return self.conditions[name]
end

function CAGateInfoMixin:IsMetCondition(name)
    local condition = self:GetCondition(name)
    return condition and condition:IsMet() or false
end
-------------------------------------------------------------------------------
--                             Gate Frame Mixin --
-------------------------------------------------------------------------------
CATalentGatesInfoMixin = {}

-- DOC: CATalentGatesInfoMixin:OnLoad
-- What this does: Sets up this UI element: prepares data, connects events, and sets initial visuals.
-- When it runs: Runs once when this UI element is created/loaded.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, changes text on screen.
function CATalentGatesInfoMixin:OnLoad()
    self.GatePool = CreateFramePool("FRAME", self, "CATalentGateCounterTemplate")
end

function CATalentGatesInfoMixin:Refresh(class, spec, treeTESpent, classTESpent, totalTESpent, totalAESpent)
    self.GatePool:ReleaseAll()

    local btn 
    for i = 1, 4 do 
        local btnNew = self.GatePool:Acquire()

        if btn then
            btnNew:SetPoint("TOP", btn, "BOTTOM", 0, -2)
        else
            btnNew:SetPoint("TOP", 10, -20)
        end

        if i == 1 then
            btnNew:Init("TAB", treeTESpent, class, spec)
        elseif i == 2 then
            btnNew:Init("CLASS", classTESpent, class)
        elseif i == 3 then
            btnNew:Init("GLOBAL_TE", totalTESpent)
        elseif i == 4 then
            btnNew:Init("GLOBAL_AE", totalAESpent)
        end

        btnNew:Show()

        btn = btnNew
    end
end
-------------------------------------------------------------------------------
--                            Gate Counter Mixin --
-------------------------------------------------------------------------------
CATalentGateCounterMixin = {}

-- DOC: CATalentGateCounterMixin:OnLoad
-- What this does: Sets up this UI element: prepares data, connects events, and sets initial visuals.
-- When it runs: Runs once when this UI element is created/loaded.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: A value used by other code (classInfo.Name.." "..CA_POINTS_GLOBAL_ST...).
-- What it changes: shows/hides UI pieces, changes text on screen.
function CATalentGateCounterMixin:OnLoad()
    self.LockIcon:ClearAndSetPoint("CENTER", 0, 0)
    self.Line:Hide()
    self:SetWidth(40)
    self:SetHeight(24)

    --real icons 
    self.LockIconAdd:ClearAndSetPoint("CENTER", 0, 0)
    self.LockIconAdd:SetAtlas("category-icon-ring", Const.TextureKit.IgnoreAtlasSize)

    self.GateText:SetVertexColor(1, 1, 1)
    self.GateText:SetText("0")
    self.GateText:SetJustifyH("LEFT")
    self.GateText:ClearAndSetPoint("LEFT", self.LockIcon, "RIGHT", 6, -1)
end

-- DOC: CATalentGateCounterMixin:Init
-- What this does: Update text shown to the player.
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
--   - gateType: a piece of information passed in by the caller
--   - total: a piece of information passed in by the caller
--   - class: a piece of information passed in by the caller
--   - spec: information about a specialization (spec) choice
--   - minimized: a piece of information passed in by the caller
-- Output: A value used by other code (classInfo.Name.." "..CA_POINTS_GLOBAL_ST...).
-- What it changes: changes text on screen.
function CATalentGateCounterMixin:Init(gateType, total, class, spec, minimized)
    self.class = class
    self.spec = spec
    self.total = total
    
    self.LockIcon:SetPortraitTexture(self:DefineIcon(gateType, class, spec))

    if minimized then
        self.GateText:SetText(total)
    else
        self.GateText:SetText(self:DefineText(gateType, class, spec):format(total))
    end

    self.tooltipTitle, self.tooltipText = self:DefineTooltip(gateType, class, spec)
end

-- DOC: CATalentGateCounterMixin:CompareAndPlayAnim
-- What this does: Update text shown to the player.
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
--   - oldAmount: a piece of information passed in by the caller
--   - oldClass: a piece of information passed in by the caller
--   - oldSpec: information about a specialization (spec) choice
-- Output: A value used by other code (classInfo.Name.." "..CA_POINTS_GLOBAL_ST...).
-- What it changes: changes text on screen.
function CATalentGateCounterMixin:CompareAndPlayAnim(oldAmount, oldClass, oldSpec)
    --dprint("CATalentGateCounterMixin:CompareAndPlayAnim o - "..(oldAmount or "NO OLD AMOUNT").." n - "..(self.total or "NO NEW AMOUNT").." oClass - "..(oldClass or "NO OLD CLASS").." nClass - "..(self.class or "NO NEW CLASS"))
    if oldAmount and (oldAmount < self.total) and (oldClass and (oldClass == self.class)) then
        --dprint("|cff00FF00pass main check")
        if not oldSpec or (self.spec == oldSpec) then
            if self:IsVisible() then
                --dprint("|cff00FFFFplay anim")
                self.AnimatedText:SetText("+"..(self.total - oldAmount))
                self.AnimatedText.Animation:Stop()
                self.AnimatedText.Animation:Play()
            end
        end
    end
end

-- DOC: CATalentGateCounterMixin:DefineText
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
--   - gateType: a piece of information passed in by the caller
--   - class: a piece of information passed in by the caller
--   - spec: information about a specialization (spec) choice
-- Output: A value used by other code (classInfo.Name.." "..CA_POINTS_GLOBAL_ST...).
-- What it changes: shows/hides UI pieces.
function CATalentGateCounterMixin:DefineText(gateType, class, spec)
    class = string.gsub(class:lower(), "reborn", "")
    if gateType == "TAB" and class and spec then
        local classInfo = C_ClassInfo.GetSpecInfo(string.upper(class), string.upper(spec))
        return classInfo.Name.." "..CA_POINTS_GLOBAL_STRING
    elseif gateType == "CLASS" and class then
        return LOCALIZED_CLASS_NAMES_MALE[string.upper(class)].." "..CA_POINTS_GLOBAL_STRING
    end

    return "%d"
end

-- DOC: CATalentGateCounterMixin:DefineIcon
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
--   - gateType: a piece of information passed in by the caller
--   - class: a piece of information passed in by the caller
--   - spec: information about a specialization (spec) choice
-- Output: A value used by other code ("Interface\\Icons\\"..classInfo.SpecFile...).
-- What it changes: shows/hides UI pieces.
function CATalentGateCounterMixin:DefineIcon(gateType, class, spec)
    if gateType == "TAB" and class and spec then
        local classInfo = C_ClassInfo.GetSpecInfo(string.upper(class), string.upper(spec))
        if classInfo then
            return "Interface\\Icons\\"..classInfo.SpecFilename
        end
    elseif gateType == "CLASS" and class then
        return "interface\\icons\\classicon_"..class
    elseif gateType == "GLOBAL_AE" then
        return CA_GATE_ICON_GLOBAL_AE
    else
        return CA_GATE_ICON_GLOBAL_TE
    end
end

-- DOC: CATalentGateCounterMixin:DefineTooltip
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
--   - gateType: a piece of information passed in by the caller
--   - class: a piece of information passed in by the caller
--   - spec: information about a specialization (spec) choice
-- Output: A value used by other code (CA_GATE_INFO:format(self.GateText:GetTex...).
-- What it changes: shows/hides UI pieces, changes text on screen.
function CATalentGateCounterMixin:DefineTooltip(gateType, class, spec)
    if gateType == "TAB" and class and spec then
        local classInfo = C_ClassInfo.GetSpecInfo(string.upper(class), string.upper(spec))
        if classInfo then
            return CA_GATE_INFO:format(self.GateText:GetText(), classInfo.Name)
        end
    elseif gateType == "CLASS" and class then
        return CA_GATE_INFO_CLASS_POINTS:format(self.GateText:GetText(), AccessibilityUtil.GetClassPointsMarkup(class)), CA_GATE_INFO_CLASS_POINTS_HINT
    elseif gateType == "GLOBAL_AE" then
        return CA_GATE_INFO_GLOBAL_AE:format(self.GateText:GetText())
    else
        return CA_GATE_INFO:format(self.GateText:GetText(), "")
    end

    return ""
end

-- DOC: CATalentGateCounterMixin:OnEnter
-- What this does: Show a tooltip or highlight when the mouse is over this item.
-- When it runs: Runs when the mouse pointer moves over the related UI element.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, changes text on screen.
function CATalentGateCounterMixin:OnEnter()
    GameTooltip:SetOwner(self, "ANCHOR_LEFT", 4, -4)
    if self.tooltipText and self.tooltipTitle then
        GameTooltip:AddLine(self.tooltipTitle, 1, 0.82, 0, true)
        GameTooltip:AddLine(self.tooltipText, 1, 0.82, 0, true)
    else
        GameTooltip:AddLine(self.tooltipTitle, 1, 0.82, 0, true)
    end
    GameTooltip:Show()
end

-- DOC: CATalentGateCounterMixin:OnLeave
-- What this does: Hide the tooltip/highlight when the mouse leaves this item.
-- When it runs: Runs when the mouse pointer leaves the related UI element.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, changes text on screen.
function CATalentGateCounterMixin:OnLeave()
    GameTooltip:Hide()
end
-------------------------------------------------------------------------------
--                                Gate Mixin --
-------------------------------------------------------------------------------
CATalentGateMixin = {}

-- DOC: CATalentGateMixin:OnLoad
-- What this does: Sets up this UI element: prepares data, connects events, and sets initial visuals.
-- When it runs: Runs once when this UI element is created/loaded.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, changes text on screen.
function CATalentGateMixin:OnLoad()
    self.Line:SetVertexColor(1, 0.44, 0.26)
    self.Line:SetAtlas("levelup-line-white", Const.TextureKit.IgnoreAtlasSize)
    self.LockIconAdd:SetAtlas("category-icon-ring", Const.TextureKit.IgnoreAtlasSize)

    self.Shadow:SetAtlas("talents-node-choiceflyout-circle-shadow", Const.TextureKit.IgnoreAtlasSize)
end

-- DOC: CATalentGateMixin:Init
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
--   - gateInfo: a piece of information passed in by the caller
--   - class: a piece of information passed in by the caller
--   - spec: information about a specialization (spec) choice
--   - gateType: a piece of information passed in by the caller
-- Output: Nothing (nil).
-- What it changes: shows/hides UI pieces, changes text on screen.
function CATalentGateMixin:Init(gateInfo, class, spec, gateType)
    self.gateInfo = gateInfo

    class = string.gsub(class:lower(), "reborn", "")

    if gateType == "GLOBAL" then
        local left = gateInfo:GetCondition("GLOBAL"):GetLeft()
        self.LockIcon:SetPortraitTexture(CATalentGateCounterMixin:DefineIcon("GLOBAL_TE"))
        self.tooltip = CA_GATE_TOOLTIP_FORMAT_GLOBAL:format(left)
        self.GateText:SetText(left)
    elseif gateType == "TAB" then
        local left = gateInfo:GetCondition("TAB"):GetLeft()
        self.LockIcon:SetPortraitTexture(CATalentGateCounterMixin:DefineIcon("TAB", class, spec))
        self.tooltip = CA_GATE_TOOLTIP_FORMAT_LOCAL:format(left)
        self.GateText:SetText(left)
    end
end

-- DOC: CATalentGateMixin:OnEnter
-- What this does: Show a tooltip or highlight when the mouse is over this item.
-- When it runs: Runs when the mouse pointer moves over the related UI element.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (nil).
-- What it changes: shows/hides UI pieces.
function CATalentGateMixin:OnEnter()
    GameTooltip:SetOwner(self, "ANCHOR_LEFT", 4, -4)
    GameTooltip:AddLine(self.tooltip, 1, 0, 0, true)
    GameTooltip:Show()
end

function CATalentGateMixin:OnLeave()
    GameTooltip:Hide()
end

-------------------------------------------------------------------------------
--                     Gates attached to talents Mixin --
-------------------------------------------------------------------------------
CATalentFrameGatesMixin = {}

-- DOC: CATalentFrameGatesMixin:OnLoad
-- What this does: Sets up this UI element: prepares data, connects events, and sets initial visuals.
-- When it runs: Runs once when this UI element is created/loaded.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (nil).
-- What it changes: uses Character Advancement API.
function CATalentFrameGatesMixin:OnLoad()
    self.GatePool = CreateFramePool("Frame", self, "CATalentGateTemplate")

    self.tiers = {}

    for i = 1, 11 do
        self.tiers[i] = CreateFromMixinsAndLoad(CAGateInfoMixin)
        self.tiers[i].tier = i
    end
end

-- DOC: CATalentFrameGatesMixin:DefineGateConditionsRequired
-- What this does: Call into the Character Advancement system (server/game API) and update the UI with the result.
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
--   - gate: a piece of information passed in by the caller
--   - entry: a piece of information passed in by the caller
-- Output: Nothing (nil).
-- What it changes: uses Character Advancement API.
function CATalentFrameGatesMixin:DefineGateConditionsRequired(gate, entry)
    local conditionGlobal = gate:GetCondition("GLOBAL")
    local conditionTab = gate:GetCondition("TAB")
    --local conditionClass = gate:GetCondition("CLASS")

    conditionGlobal:SetRequired(entry.RequiredTEInvestment)
    conditionTab:SetRequired(entry.RequiredTabTEInvestment)
    --conditionClass:SetRequired(entry.RequiredClassPoints)
end

-- DOC: CATalentFrameGatesMixin:DefineGateTopLeftNode
-- What this does: Call into the Character Advancement system (server/game API) and update the UI with the result.
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
--   - gate: a piece of information passed in by the caller
--   - entry: a piece of information passed in by the caller
--   - button: the button that triggered this (the thing you clicked)
-- Output: Nothing (nil).
-- What it changes: uses Character Advancement API.
function CATalentFrameGatesMixin:DefineGateTopLeftNode(gate, entry, button)
    if not (gate) then 
        return
    end

    if not gate.topLeftNode then
        gate.topLeftNode = button
        self:DefineGateConditionsRequired(gate, entry)
    else
        if gate.topLeftNode.entry and (gate.topLeftNode.entry.Column > entry.Column) then
            gate.topLeftNode = button
            self:DefineGateConditionsRequired(gate, entry)
        end
    end
end

-- DOC: CATalentFrameGatesMixin:DefineGatesForButton
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
--   - row: a piece of information passed in by the caller
-- Output: A value used by other code (gate).
-- What it changes: shows/hides UI pieces, uses Character Advancement API.
function CATalentFrameGatesMixin:DefineGatesForButton(row)
    local gate = nil

    for _, gateInfo in ipairs(self.tiers) do
        if gateInfo.tier <= row then
            gate = gateInfo
        else
            break
        end
    end

    return gate
end

-- DOC: CATalentFrameGatesMixin:RefreshGateInfo
-- What this does: Update what is shown on screen so it matches the latest game data.
-- When it runs: Called whenever the screen needs to be redrawn with fresh information.
-- Inputs:
--   - self: the UI object this function belongs to
--   - class: a piece of information passed in by the caller
--   - spec: information about a specialization (spec) choice
--   - hardReset: a piece of information passed in by the caller
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, uses Character Advancement API.
function CATalentFrameGatesMixin:RefreshGateInfo(class, spec, hardReset)
    local totalTESpent = C_CharacterAdvancement.GetGlobalTEInvestment() or 0
    local treeTESpent = C_CharacterAdvancement.GetTabTEInvestment(class, spec, 0) or 0

    for _, gateInfo in pairs(self.tiers) do
        if hardReset then
            gateInfo.topLeftNode = nil -- to be later filled in:SetTalents
        end

        local conditionGlobal = gateInfo:GetCondition("GLOBAL")
        local conditionTab = gateInfo:GetCondition("TAB")

        local diffGlobal = conditionGlobal:GetRequired() - totalTESpent
        local diffTab = conditionTab:GetRequired() - treeTESpent

        conditionGlobal:SetLeft(diffGlobal > 0 and diffGlobal or 0)
        conditionTab:SetLeft(diffTab > 0 and diffTab or 0)

        conditionTab:SetIsMet(diffTab <= 0)
        conditionGlobal:SetIsMet(diffGlobal <= 0)
    end

    if self.RefreshGateInfoCallBack then
        self:RefreshGateInfoCallBack()
    end
end

-- DOC: CATalentFrameGatesMixin:RefreshGates
-- What this does: Update what is shown on screen so it matches the latest game data.
-- When it runs: Called whenever the screen needs to be redrawn with fresh information.
-- Inputs:
--   - self: the UI object this function belongs to
--   - classFile: a piece of information passed in by the caller
--   - specFile: information about a specialization (spec) choice
-- Output: Nothing (nil).
-- What it changes: shows/hides UI pieces.
function CATalentFrameGatesMixin:RefreshGates(classFile, specFile)
    local oldRequirement, oldPoint

    for gate in self.GatePool:EnumerateActive() do
        oldRequirement = gate.gateInfo:GetCondition("TAB").required
        oldPoint = {gate:GetPoint()}
    end

    self.GatePool:ReleaseAll()

    -- global lock 
    local hasGate, oldGateInfo

    --[[for i, gateInfo in ipairs(self.tiers) do
        if not(gateInfo:IsMetCondition("GLOBAL")) and gateInfo.topLeftNode then -- show lock at first global requirement
            local gate = self.GatePool:Acquire()
            gate:Init(gateInfo, classFile, specFile, "GLOBAL")
            gate:SetPoint("RIGHT", gateInfo.topLeftNode, "LEFT", 0, 0)
            gate.Line:Show()
            gate:SetWidth(82 + math.abs(gateInfo.topLeftNode.entry.Column - 1)*52)
            gate:Show()

            hasGate = gate
            oldGateInfo = gateInfo.topLeftNode

            break
        end
    end]]--

    -- local lock
    for i, gateInfo in ipairs(self.tiers) do
        if not(gateInfo:IsMetCondition("TAB")) and gateInfo.topLeftNode then

            if oldRequirement and (oldRequirement < gateInfo:GetCondition("TAB").required) then
                PlaySound(SOUNDKIT.COMMON_UI_MISSION_SELECT)
                self.GateDisappearanceFrame:ClearAndSetPoint(unpack(oldPoint))
                self.GateDisappearanceFrame.Shockwave.Explosion:Stop()
                self.GateDisappearanceFrame.Shockwave.Explosion:Play()
                self.GateDisappearanceFrame.Glow.Explosion:Stop()
                self.GateDisappearanceFrame.Glow.Explosion:Play()
            end

            if not gateInfo:IsMetCondition("GLOBAL") then
                return
            end

            local gate = self.GatePool:Acquire()
            gate:Init(gateInfo, classFile, specFile, "TAB")
            gate:SetPoint("RIGHT", gateInfo.topLeftNode, "LEFT", 0, 0)
            gate.Line:Show()
            gate:Show()

            if oldGateInfo and (oldGateInfo == gateInfo.topLeftNode) then
                gate:Hide()
               -- gate.Line:Hide()
                --gate:SetWidth(45 + 82 + math.abs(gateInfo.topLeftNode.entry.Column - 1)*52)
            else
                gate:SetWidth(82 + math.abs(gateInfo.topLeftNode.entry.Column - 1)*52)
            end

            break
        end
    end

end
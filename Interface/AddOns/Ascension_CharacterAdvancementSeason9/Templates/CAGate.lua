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

CA_GATE_TOOLTIP_FORMAT_LOCAL = "Spend |cffFFFFFF%d|r more Talent Essence in |cffFFFFFFcurrent|r tree to unlock this row"
CA_GATE_TOOLTIP_FORMAT_GLOBAL = "Spend |cffFFFFFF%d|r more Talent Essence points in |cffFFFFFFany|r tree to unlock rows below"
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
    self.tooltip = CA_GATE_TOOLTIP_FORMAT_LOCAL
end

function CATalentGateMixin:Init(gateInfo)
    self.gateInfo = gateInfo

    --self.GateText:SetText(gateInfo.requiresTree.."/"..gateInfo.requiresGlobal)
    self.GateText:SetText(gateInfo.requiresTree)
end

-- DOC: CATalentGateMixin:OnEnter
-- What this does: Show a tooltip or highlight when the mouse is over this item.
-- When it runs: Runs when the mouse pointer moves over the related UI element.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, changes text on screen.
function CATalentGateMixin:OnEnter()
    GameTooltip:SetOwner(self, "ANCHOR_LEFT", 4, -4)
    GameTooltip:AddLine(self.tooltip:format(self.gateInfo.requiresTree, self.gateInfo.requiresGlobal), 1, 0, 0, true)
    GameTooltip:Show()
end

function CATalentGateMixin:OnLeave()
    GameTooltip:Hide()
end

-------------------------------------------------------------------------------
--                            Global Gate Mixin --
-------------------------------------------------------------------------------
CATalentGateGlobalMixin = CreateFromMixins(CATalentGateMixin)

-- DOC: CATalentGateGlobalMixin:OnLoad
-- What this does: Sets up this UI element: prepares data, connects events, and sets initial visuals.
-- When it runs: Runs once when this UI element is created/loaded.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: changes text on screen.
function CATalentGateGlobalMixin:OnLoad()
    self.tooltip = CA_GATE_TOOLTIP_FORMAT_GLOBAL
end

function CATalentGateGlobalMixin:Init(gateInfo)
    self.gateInfo = gateInfo

    self.GateText:SetText(string.format(SPELL_REQUIRED_FORM, gateInfo.requiresGlobal))
end
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

CoACharacterAdvancementUtil = {}

local architectPrefix = "#SPEC:"

-- DOC: CoACharacterAdvancementUtil.GetDisplayTemplateForEntry
-- What this does: Return a value that other parts of the UI need.
-- When it runs: Called when other code needs a yes/no or a piece of information.
-- Inputs:
--   - entry: a piece of information passed in by the caller
-- Output: A text string.
-- What it changes: updates UI/state.
function CoACharacterAdvancementUtil.GetDisplayTemplateForEntry(entry)
    local nodeType = Enum.TraitNodeEntryType[entry.NodeType]

    if nodeType == Enum.TraitNodeEntryType.SpendHex then
    return "CoATalentButtonHexTemplate"
    elseif nodeType == Enum.TraitNodeEntryType.SpendCircle then
        return "CoATalentButtonCircleTemplate"
    elseif nodeType == Enum.TraitNodeEntryType.SpendSquare then
        return "CoATalentButtonSquareTemplate"
    elseif nodeType == Enum.TraitNodeEntryType.SpendDiamond then
        return "CoATalentButtonDiamondTemplate"
    else
        return "CoATalentButtonSquareTemplate"
    end
end

-- DOC: CoACharacterAdvancementUtil.GetDisplayTemplateForEntryChoice
-- What this does: Return a value that other parts of the UI need.
-- When it runs: Called when other code needs a yes/no or a piece of information.
-- Inputs:
--   - entry: a piece of information passed in by the caller
-- Output: A text string.
-- What it changes: updates UI/state.
function CoACharacterAdvancementUtil.GetDisplayTemplateForEntryChoice(entry)
    return "CoATalentChoiceButtonTemplate"
end

function CoACharacterAdvancementUtil.GetDisplayTemplateForConnection()
    return "CALineConnectionTemplate"
end

-- DOC: CoACharacterAdvancementUtil.GetDisplayTemplateForGate
-- What this does: Return a value that other parts of the UI need.
-- When it runs: Called when other code needs a yes/no or a piece of information.
-- Inputs: none
-- Output: A text string.
-- What it changes: updates UI/state.
function CoACharacterAdvancementUtil.GetDisplayTemplateForGate()
    return "CoAGateTemplate"
end

function CoACharacterAdvancementUtil.FormatArchitectTag(specName)
    if not specName then
        return
    end

    return architectPrefix .. tostring(specName)
end

-- DOC: CoACharacterAdvancementUtil.StripArchitectTag
-- What this does: Do a specific piece of work related to 'StripArchitectTag'.
-- When it runs: Called by other code when needed.
-- Inputs:
--   - name: a piece of information passed in by the caller
-- Output: A text string.
-- What it changes: updates UI/state.
function CoACharacterAdvancementUtil.StripArchitectTag(name)
    if not name then
        return ""
    end

    return name:gsub(architectPrefix ..".+$", "")
end

-- DOC: CoACharacterAdvancementUtil.GetGateRightAttachmentPoint
-- What this does: Return a value that other parts of the UI need.
-- When it runs: Called when other code needs a yes/no or a piece of information.
-- Inputs:
--   - nodes: a piece of information passed in by the caller
-- Output: A value used by other code ("LEFT", targetNode, "RIGHT", 0, 0).
-- What it changes: updates UI/state.
function CoACharacterAdvancementUtil.GetGateRightAttachmentPoint(nodes)
    local nodeX = 0
    local nodeY = math.huge
    local targetNode

    local x, y
    for _, node in ipairs(nodes) do
        if node:IsChoiceNode() then
            x = node.nodes[1].entry.PositionX
            y = node.nodes[1].entry.PositionY
        else
            x = node.entry.PositionX
            y = node.entry.PositionY
        end
        if y < nodeY or (x > nodeX and y <= nodeY) then
            nodeX = x
            nodeY = y
            targetNode = node
        end
    end

    if not targetNode then
        error("CoACharacterAdvancementUtil.GetGateRightAttachmentPoint could not create attachment point")
    end
    return "LEFT", targetNode, "RIGHT", 0, 0
end

-- DOC: CoACharacterAdvancementUtil.GetGateLeftAttachmentPoint
-- What this does: Return a value that other parts of the UI need.
-- When it runs: Called when other code needs a yes/no or a piece of information.
-- Inputs:
--   - nodes: a piece of information passed in by the caller
-- Output: A value used by other code ("RIGHT", targetNode, "LEFT", 0, 0).
-- What it changes: updates UI/state.
function CoACharacterAdvancementUtil.GetGateLeftAttachmentPoint(nodes)
    local nodeX = math.huge
    local nodeY = math.huge
    local targetNode
    
    local x, y
    for _, node in ipairs(nodes) do
        if node:IsChoiceNode() then
            x = node.nodes[1].entry.PositionX
            y = node.nodes[1].entry.PositionY
        else
            x = node.entry.PositionX
            y = node.entry.PositionY
        end
        if y < nodeY or (x < nodeX and y <= nodeY) then
            nodeX = x
            nodeY = y
            targetNode = node
        end
    end

    if not targetNode then
        error("CoACharacterAdvancementUtil.GetGateLeftAttachmentPoint could not create attachment point")
    end
    return "RIGHT", targetNode, "LEFT", 0, 0
end

-- DOC: CoACharacterAdvancementUtil.GetEntryAEGateRequirement
-- What this does: Return a value that other parts of the UI need.
-- When it runs: Called when other code needs a yes/no or a piece of information.
-- Inputs:
--   - entry: a piece of information passed in by the caller
-- Output: A value used by other code (entry.RequiredTabAEInvestment).
-- What it changes: updates UI/state.
function CoACharacterAdvancementUtil.GetEntryAEGateRequirement(entry)
    return entry.RequiredTabAEInvestment
end

function CoACharacterAdvancementUtil.GetEntryTEGateRequirement(entry)
    return entry.RequiredTabTEInvestment
end

CoACharacterAdvancementUtil.NodeArtSet = {
    Square = {
        iconMask = "Interface\\TalentFrame\\TalentsMaskNodeChoiceFlyout.blp",
        shadow = "talents-node-square-shadow",
        normal = "talents-node-square-yellow",
        disabled = "talents-node-square-gray",
        selectable = "talents-node-square-green",
        maxed = "talents-node-square-yellow",
        locked = "talents-node-square-locked",
        refundInvalid = "talents-node-square-red",
        glow = "talents-node-square-greenglow",
        ghost = "talents-node-square-ghost",
        spendFont = "SystemFont16_Shadow_ThickOutline",
        shape = TalentButtonUtil.VisualShape.Square,
    },

    Circle = {
        iconMask = "Interface\\TalentFrame\\TalentsMaskNodeCircle.blp",
        shadow = "talents-node-circle-shadow",
        normal = "talents-node-circle-yellow",
        disabled = "talents-node-circle-gray",
        selectable = "talents-node-circle-green",
        maxed = "talents-node-circle-yellow",
        refundInvalid = "talents-node-circle-red",
        locked = "talents-node-circle-locked",
        glow = "talents-node-circle-greenglow",
        ghost = "talents-node-circle-ghost",
        spendFont = "SystemFont16_Shadow_ThickOutline",
        shape = TalentButtonUtil.VisualShape.Circle,
    },

    Choice = {
        iconMask = "Interface\\TalentFrame\\TalentsMaskNodeChoice.blp",
        leftIconMask = "Interface\\TalentFrame\\TalentsMaskNodeChoiceLeft.blp",
        rightIconMask = "Interface\\TalentFrame\\TalentsMaskNodeChoiceRight.blp",
        shadow = "talents-node-choice-shadow",
        normal = "talents-node-choice-yellow",
        disabled = "talents-node-choice-gray",
        selectable = "talents-node-choice-green",
        maxed = "talents-node-choice-yellow",
        refundInvalid = "talents-node-choice-red",
        locked = "talents-node-choice-locked",
        glow = "talents-node-choice-greenglow",
        ghost = "talents-node-choice-ghost",
        spendFont = "SystemFont16_Shadow_ThickOutline",
        shape = TalentButtonUtil.VisualShape.Choice,
    },

    LargeSquare = {
        iconMask = "Interface\\TalentFrame\\TalentsMaskNodeChoiceFlyout.blp",
        shadow = "talents-node-choiceflyout-square-shadow",
        normal = "talents-node-choiceflyout-square-yellow",
        disabled = "talents-node-choiceflyout-square-gray",
        selectable = "talents-node-choiceflyout-square-green",
        maxed = "talents-node-choiceflyout-square-yellow",
        refundInvalid = "talents-node-choiceflyout-square-red",
        locked = "talents-node-choiceflyout-square-locked",
        glow = "talents-node-choiceflyout-square-greenglow",
        ghost = "talents-node-choiceflyout-square-ghost",
        spendFont = "SystemFont22_Shadow_ThickOutline",
        shape = TalentButtonUtil.VisualShape.Square,
    },

    LargeCircle = {
        iconMask = "Interface\\TalentFrame\\TalentsMaskNodeCircle.blp",
        shadow = "talents-node-choiceflyout-circle-shadow",
        normal = "talents-node-choiceflyout-circle-gray",
        disabled = "talents-node-choiceflyout-circle-gray",
        selectable = "talents-node-choiceflyout-circle-green",
        maxed = "talents-node-choiceflyout-circle-yellow",
        refundInvalid = "talents-node-choiceflyout-circle-red",
        locked = "talents-node-choiceflyout-circle-locked",
        glow = "talents-node-choiceflyout-circle-greenglow",
        ghost = "talents-node-choiceflyout-circle-ghost",
        spendFont = "SystemFont22_Shadow_ThickOutline",
        shape = TalentButtonUtil.VisualShape.Circle,
    },
}

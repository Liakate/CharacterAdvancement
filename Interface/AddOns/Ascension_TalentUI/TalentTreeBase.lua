-- GUIDE: What is this file?
-- Purpose: Shared talent-tree UI logic used by multiple Ascension addons.
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

TalentTreeBaseMixin = CreateFromMixins("CallbackRegistryMixin")
TalentTreeBaseMixin.OnEvent = OnEventToMethod

TalentTreeBaseMixin.DirtyReason = {
    Nodes = 1,
    RebuildTree = 2,
    RebuildGates = 3,
    RebuildConnections = 4,
    Search = 5,
}

-- DOC: ResetNode
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called after this UI registers for events, or when something changes that needs a refresh.
-- Inputs:
--   - pool: a piece of information passed in by the caller
--   - node: a piece of information passed in by the caller
-- Output: Nothing (nil).
-- What it changes: listens for game events, uses Character Advancement API.
local function ResetNode(pool, node)
    if node.Reset then
        node:Reset()
    end
    FramePool_HideAndClearAnchors(pool, node)
end

function TalentTreeBaseMixin:OnLoad()
    AttributesToKeyValues(self)
    self.nodePool    = CreateFramePoolCollection()
    self.displayPool = CreateFramePoolCollection()
    CallbackRegistryMixin.OnLoad(self)
    self:GenerateCallbackEvents({
        "UPDATE_CURRENCY_DISPLAY",
        "TREE_UPDATE",
    })
    
    self.needsCacheUpdate = {}
    self.nodeCache = {}
    self.groupCache = {}
    self.gateCache = {}
    self.dirty = {}
    
    self:RegisterEvent("CHARACTER_ADVANCEMENT_ENTRY_PATCHED")
end

-- DOC: TalentTreeBaseMixin:OnShow
-- What this does: Prepares the UI right before the player sees it (updates text, lists, or buttons).
-- When it runs: Runs each time this UI element becomes visible.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (nil).
-- What it changes: listens for game events, uses Character Advancement API.
function TalentTreeBaseMixin:OnShow()
    self:RegisterEvent("CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED")
end 

function TalentTreeBaseMixin:OnHide()
    self:UnregisterEvent("CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED")
end

-- DOC: TalentTreeBaseMixin:CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED
-- What this does: Call into the Character Advancement system (server/game API) and update the UI with the result.
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (nil).
-- What it changes: uses Character Advancement API.
function TalentTreeBaseMixin:CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED()
    self:MarkDirty(TalentTreeBaseMixin.DirtyReason.Nodes)
end

function TalentTreeBaseMixin:FullUpdate()
    self:RefreshTree()
end

-- DOC: TalentTreeBaseMixin:ResetTree
-- What this does: Hide part of the UI (or close a popup).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (nil).
-- What it changes: shows/hides UI pieces, uses Character Advancement API.
function TalentTreeBaseMixin:ResetTree()
    local clearType = Const.CharacterAdvancement.ClearEverything
    if C_Player:IsCustomClass() then
        clearType = Const.CharacterAdvancement.OnlyClearAllowed
    end
    C_CharacterAdvancement.ClearPendingBuildByTab(self.class, self.tab, clearType)
end

-- DOC: TalentTreeBaseMixin:MarkEntryNeedUpdateDefinition
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
--   - entryID: an identifier (a number/string that points to a specific thing)
-- Output: Nothing (nil).
-- What it changes: shows/hides UI pieces.
function TalentTreeBaseMixin:MarkEntryNeedUpdateDefinition(entryID)
    self.needsCacheUpdate[entryID] = true
    self:MarkDirty(TalentTreeBaseMixin.DirtyReason.Nodes)
end

function TalentTreeBaseMixin:CreateGateIfNeeded(node)
    if not self.useGates then
        return
    end
    assert(self.getEntryGateRequirement, "TalentTreeBaseMixin:CreateGateIfNeeded() getEntryGateRequirement function is nil")
    local entry
    if node:IsChoiceNode() then
        entry = node.nodes[1].entry
    else
        entry = node.entry
    end
    
    local requiredCurrency = self.getEntryGateRequirement(entry)
    if requiredCurrency and requiredCurrency > 0 then
        for _, gateInfo in ipairs(self.gateCache) do
            if gateInfo.requiredCurrency == requiredCurrency then
                tinsert(gateInfo.nodes, node)
                return
            end
        end
        
        -- we dont already have a gate made
        local gateInfo = {}
        gateInfo.requiredCurrency = requiredCurrency
        gateInfo.nodes = {node}
        tinsert(self.gateCache, gateInfo)
        table.sort(self.gateCache, function(a, b) return a.requiredCurrency < b.requiredCurrency end)
    end
end

-- DOC: TalentTreeBaseMixin:UpdateGates
-- What this does: Update what is shown on screen so it matches the latest game data.
-- When it runs: Called whenever the screen needs to be redrawn with fresh information.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (nil).
-- What it changes: shows/hides UI pieces.
function TalentTreeBaseMixin:UpdateGates()
    if not self.useGates then
        return
    end
    assert(self.getGateTemplate, "TalentTreeBaseMixin:UpdateGates() getGateTemplate function is nil")
    assert(self.gateCurrencyCount, "TalentTreeBaseMixin:UpdateGates() gateCurrencyCount function is nil")
    local gateTemplate = self.getGateTemplate()

    local currencyCount = self.gateCurrencyCount(self.class, self.tab, 0)
    local gate, gateShown
    for _, gateInfo in ipairs(self.gateCache) do
        gate = gateInfo.gate
        if self.onlyOneGate then
            if gateShown then
                gate:Hide()
            else
                gate:UpdateDisplay(currencyCount)
                if gate:IsLocked() then
                    gate:Show()
                    gateShown = true
                else
                    gate:Hide()
                end
            end
        else
            gate:UpdateDisplay(currencyCount)
            gate:Show()
        end
    end
end

-- DOC: TalentTreeBaseMixin:CreateGates
-- What this does: Do a specific piece of work related to 'CreateGates'.
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (nil).
-- What it changes: updates UI/state.
function TalentTreeBaseMixin:CreateGates()
    if not self.useGates then
        return
    end
    assert(self.getGateTemplate, "TalentTreeBaseMixin:CreateGates() getGateTemplate function is nil")
    assert(self.gateCurrencyCount, "TalentTreeBaseMixin:CreateGates() gateCurrencyCount function is nil")
    assert(self.getGateAttachmentPoint, "TalentTreeBaseMixin:CreateGates() getGateAttachmentPoint function is nil")
    
    local gateTemplate = self.getGateTemplate()
    local currencyCount = self.gateCurrencyCount(self.class, self.tab, 0)
    local gatePool = self.displayPool:GetOrCreatePool("Frame", self, gateTemplate)
    
    for _, gateInfo in pairs(self.gateCache) do
        local gate = gatePool:Acquire()
        gateInfo.gate = gate
        gate:SetGateInfo(gateInfo)
        gate:SetPosition(self.getGateAttachmentPoint(gateInfo.nodes))
        gate:UpdateDisplay(currencyCount)
    end
    
    self:UpdateGates() -- we could probably do better here but i dont wanna copy paste code
end

-- DOC: TalentTreeBaseMixin:Update
-- What this does: Update what is shown on screen so it matches the latest game data.
-- When it runs: Called whenever the screen needs to be redrawn with fresh information.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (nil).
-- What it changes: updates UI/state.
function TalentTreeBaseMixin:Update()
    local reason = next(self.dirty)
    if not reason then
        self:SetScript("OnUpdate", nil)
        return
    end

    self.dirty[reason] = nil
    if reason == TalentTreeBaseMixin.DirtyReason.RebuildTree then
        wipe(self.dirty)
        self:InvalidateCache()
        return
    end

    if reason == TalentTreeBaseMixin.DirtyReason.RebuildGates then
        self:CreateGates()
        return
    end

    if reason == TalentTreeBaseMixin.DirtyReason.RebuildConnections then
        self:BuildTreeConnections()
        return
    end 

    if reason == TalentTreeBaseMixin.DirtyReason.Nodes then
        self:RefreshTree()
        self:UpdateGates()
        return
    end

    if reason == TalentTreeBaseMixin.DirtyReason.Search then
        self:UpdateSearchMarkers()
        return
    end
end

-- DOC: TalentTreeBaseMixin:MarkDirty
-- What this does: Do a specific piece of work related to 'MarkDirty'.
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
--   - dirtyReason: a piece of information passed in by the caller
-- Output: A value used by other code (self.class, self.tab).
-- What it changes: updates UI/state.
function TalentTreeBaseMixin:MarkDirty(dirtyReason)
    if not dirtyReason then
        dirtyReason = TalentTreeBaseMixin.DirtyReason.RebuildTree
    end
    
    self.dirty[dirtyReason] = true
    self:SetScript("OnUpdate", self.Update)
end 

-- DOC: TalentTreeBaseMixin:InvalidateCache
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: A value used by other code (self.class, self.tab).
-- What it changes: shows/hides UI pieces.
function TalentTreeBaseMixin:InvalidateCache()
    wipe(self.dirty)
    wipe(self.needsCacheUpdate)
    self:BuildTree()
end

function TalentTreeBaseMixin:SetClassTab(class, tab)
    self.class = class
    self.tab = tab
    self:MarkDirty(TalentTreeBaseMixin.DirtyReason.RebuildTree)
end

-- DOC: TalentTreeBaseMixin:GetClassTab
-- What this does: Return a value that other parts of the UI need.
-- When it runs: Called when other code needs a yes/no or a piece of information.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: A value used by other code (self.class, self.tab).
-- What it changes: shows/hides UI pieces.
function TalentTreeBaseMixin:GetClassTab()
    return self.class, self.tab
end

function TalentTreeBaseMixin:IsGroupedEntry(entry)
    return entry and entry.Group and entry.Group ~= 0
end

-- DOC: TalentTreeBaseMixin:RefreshTree
-- What this does: Update what is shown on screen so it matches the latest game data.
-- When it runs: Called whenever the screen needs to be redrawn with fresh information.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: A value used by other code (self.nodePool:EnumerateActive()).
-- What it changes: shows/hides UI pieces.
function TalentTreeBaseMixin:RefreshTree()
    for node in self:EnumerateNodes() do
        if node.entry and self.needsCacheUpdate[node.entry.ID] then
            node:SetEntry(self.getEntry(node.entry.ID))
        end

        if node:IsChoiceNode() or not self:IsGroupedEntry(node.entry) then
            -- grouped entries will be handled by their parent update display.
            node:UpdateDisplay()
        end
    end
    wipe(self.needsCacheUpdate)
end

-- DOC: TalentTreeBaseMixin:UpdateSearchMarkers
-- What this does: Update what is shown on screen so it matches the latest game data.
-- When it runs: Called whenever the screen needs to be redrawn with fresh information.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: A value used by other code (self.nodePool:EnumerateActive()).
-- What it changes: shows/hides UI pieces.
function TalentTreeBaseMixin:UpdateSearchMarkers()
    for node in self:EnumerateNodes() do
        node:UpdateSearchMarker()
    end
end

function TalentTreeBaseMixin:EnumerateNodes()
    return self.nodePool:EnumerateActive()
end

-- DOC: TalentTreeBaseMixin:CreateNode
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
--   - entry: a piece of information passed in by the caller
-- Output: A value used by other code (node).
-- What it changes: shows/hides UI pieces.
function TalentTreeBaseMixin:CreateNode(entry)
    local nodeTemplate = self.getNodeTemplate(entry)

    local nodePool = self.nodePool:GetOrCreatePool("Button", self, nodeTemplate, ResetNode)
    local node = nodePool:Acquire()
    if node:GetParent() ~= self then
        -- could be reparented by a choice node.
        node:SetParent(self)
    end
    node:SetSize(self.buttonWidth, self.buttonHeight)
    node:SetEntry(entry)
    node:UpdateDisplay()
    node:Show()
    self.nodeCache[entry.ID] = node
    
    return node
end

-- DOC: TalentTreeBaseMixin:GetOrCreateChoiceNode
-- What this does: Return a value that other parts of the UI need.
-- When it runs: Called when other code needs a yes/no or a piece of information.
-- Inputs:
--   - self: the UI object this function belongs to
--   - entry: a piece of information passed in by the caller
-- Output: A value used by other code (choiceNode).
-- What it changes: shows/hides UI pieces.
function TalentTreeBaseMixin:GetOrCreateChoiceNode(entry)
    local choiceNode
    -- grouped nodes get a choice node instead
    if not self.groupCache[entry.Group] then
        local choiceNodeTemplate = self.getChoiceNodeTemplate(entry)
        local choiceNodePool = self.nodePool:GetOrCreatePool("Button", self, choiceNodeTemplate, ResetNode)
        choiceNode = choiceNodePool:Acquire()
        choiceNode:SetSize(self.buttonWidth, self.buttonHeight)
        choiceNode:Show()
        self.groupCache[entry.Group] = choiceNode
    else
        choiceNode = self.groupCache[entry.Group]
    end
    
    return choiceNode
end

-- DOC: TalentTreeBaseMixin:CreateNodeConnections
-- What this does: Do a specific piece of work related to 'CreateNodeConnections'.
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
--   - node: a piece of information passed in by the caller
--   - connectionPool: a piece of information passed in by the caller
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: updates UI/state.
function TalentTreeBaseMixin:CreateNodeConnections(node, connectionPool)
    if node:IsChoiceNode() then
        -- group node
        for _, subNode in ipairs(node.nodes) do
            for _, connectionID in ipairs(subNode.entry.ConnectedNodes) do
                local targetNode = self.nodeCache[connectionID]
                if targetNode then
                    if self:IsGroupedEntry(targetNode.entry) then
                        targetNode = self.groupCache[targetNode.entry.Group]
                    end
                    -- note this adds to the parent choice node
                    node:AddConnection(targetNode, connectionPool)
                else
                    C_Logger.Error("Entry %s[ID: %s] Connects to [ID: %s], which doesn't exist.", subNode.entry.Name, subNode.entry.ID, connectionID)
                end
            end
        end
    elseif not self:IsGroupedEntry(node.entry) then
        -- single node
        for _, connectionID in ipairs(node.entry.ConnectedNodes) do
            local targetNode = self.nodeCache[connectionID]
            if targetNode then
                if self:IsGroupedEntry(targetNode.entry) then
                    targetNode = self.groupCache[targetNode.entry.Group]
                end
                node:AddConnection(targetNode, connectionPool)
            else
                C_Logger.Error("Entry %s[ID: %s] Connects to [ID: %s], which doesn't exist.", node.entry.Name, node.entry.ID, connectionID)
            end
        end
    end
end

-- DOC: TalentTreeBaseMixin:BuildTreeConnections
-- What this does: Do a specific piece of work related to 'BuildTreeConnections'.
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: updates UI/state.
function TalentTreeBaseMixin:BuildTreeConnections()
    local connectionTemplate = self.getConnectionTemplate()
    local connectionPool = self.displayPool:GetOrCreatePool("Frame", self, connectionTemplate)
    for node in self:EnumerateNodes() do
        self:CreateNodeConnections(node, connectionPool)
    end
end

-- DOC: TalentTreeBaseMixin:BuildTree
-- What this does: Do a specific piece of work related to 'BuildTree'.
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: updates UI/state.
function TalentTreeBaseMixin:BuildTree()
    assert(self.class, "TalentTreeBaseMixin:BuildTree() No Class Set. Use SetClassTab")
    assert(self.tab, "TalentTreeBaseMixin:BuildTree() No Tab Set. Use SetClassTab")
    assert(self.getEntries, "TalentTreeBaseMixin:BuildTree() getEntries function is nil")
    assert(self.getPosition, "TalentTreeBaseMixin:BuildTree() getPosition function is nil")
    assert(self.getNodeTemplate, "TalentTreeBaseMixin:BuildTree() getNodeTemplate function is nil")
    
    wipe(self.groupCache)
    wipe(self.nodeCache)
    wipe(self.gateCache)
    self.nodePool:ReleaseAll()
    self.displayPool:ReleaseAll()

    local positionX, positionY, x, y
    local node, choiceNode
    for index, entry in ipairs(self.getEntries(self.class, self.tab, false)) do
        positionX, positionY = self.getPosition(entry)
        x, y = GridLayoutUtil.SimpleGridXY(positionX, positionY, self.buttonWidth, self.buttonHeight, 0, 0, self.buttonSpacingX, self.buttonSpacingY)
        
        -- single nodes
        node = self:CreateNode(entry)
        node.positionX = x
        node.positionY = y

        if self:IsGroupedEntry(entry) then
            -- group node
            choiceNode = self:GetOrCreateChoiceNode(entry)
            choiceNode:SetPoint("TOPLEFT", self, "TOPLEFT", x, y)
            choiceNode:AddNode(node)
            choiceNode.positionX = x
            choiceNode.positionY = y
            self:CreateGateIfNeeded(choiceNode)
        else
            -- no group single node 
            node:SetPoint("TOPLEFT", self, "TOPLEFT", x, y)
            self:CreateGateIfNeeded(node)
        end
    end

    self:MarkDirty(TalentTreeBaseMixin.DirtyReason.RebuildGates)
    self:MarkDirty(TalentTreeBaseMixin.DirtyReason.RebuildConnections)
end

-- DOC: TalentTreeBaseMixin:CHARACTER_ADVANCEMENT_ENTRY_PATCHED
-- What this does: Do a specific piece of work related to 'CHARACTER_ADVANCEMENT_ENTRY_PATCHED'.
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
--   - isNew: a yes/no flag
--   - class: a piece of information passed in by the caller
--   - tab: a piece of information passed in by the caller
--   - entryID: an identifier (a number/string that points to a specific thing)
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: updates UI/state.
function TalentTreeBaseMixin:CHARACTER_ADVANCEMENT_ENTRY_PATCHED(isNew, class, tab, entryID)
    if class ~= "None" and class == self.class and tab == self.tab then
        if isNew then
            self:MarkDirty(TalentTreeBaseMixin.DirtyReason.RebuildTree)
        else
            self:MarkEntryNeedUpdateDefinition(entryID)
        end
    end
end 
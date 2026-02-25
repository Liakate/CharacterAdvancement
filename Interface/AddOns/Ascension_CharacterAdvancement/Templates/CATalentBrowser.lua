-- GUIDE: What is this file?
-- Purpose: Logic for the in-game browser/search UI (filtering, tags, search results, and click behavior).
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

--
-- talents mixin
--
CATalentsClassMixin = CreateFromMixins(ScrollListItemBaseMixin)

-- DOC: CATalentsClassMixin:OnLoad
-- What this does: Sets up this UI element: prepares data, connects events, and sets initial visuals.
-- When it runs: Runs once when this UI element is created/loaded.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: A value used by other code (self:GetParent():GetParent():GetParent()).
-- What it changes: shows/hides UI pieces, uses Character Advancement API.
function CATalentsClassMixin:OnLoad()
    self.shift = 30
    self.GateCounterTalents = CreateFramePool("Frame", self, "CATalentGateCounterTemplate")
    self.TalentPool = CreateFramePool("Button", self, "CATalentButtonTemplate")
    self:EnableMouse(false)

    MixinAndLoadScripts(self, "CAConnectedNodesMixin")
    MixinAndLoadScripts(self, "CATalentFrameGatesMixin")
    --self:SetBackdrop(GameTooltip:GetBackdrop())
end

-- DOC: CATalentsClassMixin:Init
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: A value used by other code (self:GetParent():GetParent():GetParent()).
-- What it changes: shows/hides UI pieces, uses Character Advancement API.
function CATalentsClassMixin:Init()
end

function CATalentsClassMixin:SetSelected()
end

function CATalentsClassMixin:OnSelected()
end

-- DOC: CATalentsClassMixin:GetScrollParent
-- What this does: Return a value that other parts of the UI need.
-- When it runs: Called when other code needs a yes/no or a piece of information.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: A value used by other code (self:GetParent():GetParent():GetParent()).
-- What it changes: shows/hides UI pieces, changes text on screen, uses Character Advancement API.
function CATalentsClassMixin:GetScrollParent()
    return self:GetParent():GetParent():GetParent()
end

function CATalentsClassMixin:RefreshGateInfoCallBack()
    local oldAmountTalents, oldClassTalents, oldSpecTalents, oldAmountAbilities, oldClassAbilities

    if self.counterTalents then
        oldSpecTalents = self.counterTalents.spec
        oldClassTalents = self.counterTalents.class
        oldAmountTalents = self.counterTalents.total
    end

    if self.counterSpells then
        oldClassAbilities = self.counterSpells.class
        oldAmountAbilities = self.counterSpells.total
    end

    self.GateCounterTalents:ReleaseAll()

    local classFile, specFile = self:GetScrollParent():GetDataForIndex(self.index)
    local class = CharacterAdvancementUtil.GetClassDBCByFile(classFile)
    local spec = CharacterAdvancementUtil.GetSpecDBCByFile(specFile)
    local treeTESpent = C_CharacterAdvancement.GetTabTEInvestment(class, spec, 0) or 0
    local classTESpent = C_CharacterAdvancement.GetClassPointInvestment(class, 0) or 0

    local counterTalents = self.GateCounterTalents:Acquire()
    counterTalents:Init("TAB", treeTESpent, class, spec, true)
    counterTalents:Show()
    counterTalents:CompareAndPlayAnim(oldAmountTalents, oldClassTalents, oldSpecTalents)
    self.counterTalents = counterTalents
    
    --if self.isMidClassTree or self:GetScrollParent().isInBrowserMode then
    local counterSpells = self.GateCounterTalents:Acquire()
    counterSpells:Init("CLASS", classTESpent, class, nil, true)
    counterSpells.GateText:SetWidth(512)
    counterSpells:ClearAndSetPoint("LEFT", counterTalents, "RIGHT", 6, 0)
    counterSpells:Show()
    counterSpells:CompareAndPlayAnim(oldAmountAbilities, oldClassAbilities)
    self.counterSpells = counterSpells
    

    local length = counterTalents.GateText:GetStringWidth() + 6 + counterTalents.LockIcon:GetWidth() + 6 + counterSpells.GateText:GetStringWidth() + 6 + counterSpells.LockIcon:GetWidth()

    counterTalents:ClearAndSetPoint("TOP", self, -length/2, -16)

    self:GetScrollParent().TalentGlobalLockFrame:Hide()
    for i, gateInfo in ipairs(self.tiers) do
        if not(gateInfo:IsMetCondition("GLOBAL")) and gateInfo.topLeftNode then -- show lock at first global requirement
            local _, _, _, _, yOfs = gateInfo.topLeftNode:GetPoint()
            if yOfs then
                if not self:GetScrollParent().TalentGlobalLockFrame.yOfsOld then
                    self:GetScrollParent().TalentGlobalLockFrame.yOfsOld = self:GetScrollParent().TalentGlobalLockFrame.yOfs
                end

                self:GetScrollParent().TalentGlobalLockFrame.Text:SetText(CA_GATE_TOOLTIP_FORMAT_GLOBAL:format(gateInfo:GetCondition("GLOBAL"):GetLeft(), ""))
                self:GetScrollParent().TalentGlobalLockFrame:Show()
                self:GetScrollParent().TalentGlobalLockFrame.yOfs = yOfs-70

                if not self:GetScrollParent().TalentGlobalLockFrame:GetScript("OnUpdate") then
                    self:GetScrollParent().TalentGlobalLockFrame:SetScript("OnUpdate", function(self)
                        if MApprox(self.yOfsOld, self.yOfs, 0.5) then
                            self:SetScript("OnUpdate", nil)
                        end

                        self.yOfsOld = self.yOfsOld + (self.yOfs-self.yOfsOld)*0.1

                        self:SetPoint("TOPLEFT", 0, self.yOfsOld)
                    end)
                end
                --self:GetScrollParent().TalentGlobalLockFrame:SetPoint("TOPLEFT", 0, yOfs-70)
            end
            break
        end
    end
end

-- DOC: CATalentsClassMixin:Update
-- What this does: Update what is shown on screen so it matches the latest game data.
-- When it runs: Called whenever the screen needs to be redrawn with fresh information.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, changes text on screen, uses Character Advancement API.
function CATalentsClassMixin:Update()
    self.TalentPool:ReleaseAll()
    wipe(self.NodeMap)
    wipe(self.ConnectedNodes)
    wipe(self.FilledNodes)
    self.LinePool:ReleaseAll()

    local nextClass = self:GetScrollParent():GetDataForIndex(self.index+1)
    local prevClass = self:GetScrollParent():GetDataForIndex(self.index-1)

    self.isMidClassTree = nextClass and prevClass and (nextClass == prevClass) 

    local classFile, specFile = self:GetScrollParent():GetDataForIndex(self.index)
    local class = CharacterAdvancementUtil.GetClassDBCByFile(classFile)
    local spec = CharacterAdvancementUtil.GetSpecDBCByFile(specFile)

    local color = RAID_CLASS_COLORS[classFile]

    if color then
        self.Background:SetVertexColor(color.r, color.g, color.b)
    end

    local classInfo = C_ClassInfo.GetSpecInfo(classFile,specFile)

    if classInfo then
        self.Title:SetText(classInfo.Name)
    end

    local yStarting = 64
    local button, column, row, x, y

    if CA_USE_GATES_DEBUG then
        self:RefreshGateInfo(class, spec, true) -- we need to scan it before to button properly update on SetEntry
    end

    for i, entry in ipairs(C_CharacterAdvancement.GetTalentsByClass(class, spec, false)) do
        button = self.TalentPool:Acquire()

        if CA_USE_GATES_DEBUG then
            -- work with gates
            local gate = self:DefineGatesForButton(entry.Row+1)

            self:DefineGateTopLeftNode(gate, entry, button)
            self:RefreshGateInfo(class, spec) -- TODO: needs better optimization we need to scan it before to button properly update on SetEntry

            button.gate = gate
        else
            button.gate = nil
        end
        
        button:SetEntry(entry)
        column = entry.Column - 1
        row = entry.Row
        self.FilledNodes[column] = self.FilledNodes[column] or {}
        self.FilledNodes[column][row] = true
        x = -58-26 + column * 52 + (self.shift or 0)
        --y = 42 + row * (self.normalFooter and 44 or 46)
        y = yStarting + row * 44
        button:ClearAndSetPoint("TOP", self, "TOP", x, -y)
        button:Show()

        if CharacterAdvancement and (entry.ID == CharacterAdvancement.LocateID) then
            button:ShowLocation()
            self.LocateID = nil
        end

        self.NodeMap[entry.ID] = { button = button, column = column, row = row }

        -- connections are backwards
        -- the child node references the parent node
        
        -- something else is a child of this node but couldnt find info about this parent node
        if self.ConnectedNodes[entry.ID] and not self.ConnectedNodes[entry.ID].button then
            self.ConnectedNodes[entry.ID].button = button
            self.ConnectedNodes[entry.ID].column = column
            self.ConnectedNodes[entry.ID].row = row
        end

        for _, parentNodeID in pairs(entry.ConnectedNodes) do
            -- parent node doesnt already exist 
            if not self.ConnectedNodes[parentNodeID] then
                if self.NodeMap[parentNodeID] then -- already discovered, connect parent.
                    self.ConnectedNodes[parentNodeID] = self.NodeMap[parentNodeID]
                else
                    self.ConnectedNodes[parentNodeID] = {}
                end
            end

            local parentNode = self.ConnectedNodes[parentNodeID]

            -- attach ourself as a child
            if not parentNode.targets then
                parentNode.targets = {}
            end
            
            tinsert(parentNode.targets, { column = column, row = row, button = button })
        end
    end

    if CA_USE_GATES_DEBUG then
        self:RefreshGates(class, spec)
    end
    
    self:DrawConnectedNodes()

    if self.isMidClassTree then
        if self:GetScrollParent().UpdateClassCallback then
            self:GetScrollParent():UpdateClassCallback(classFile)
        end
    end
end

--
-- browser mixin
--
CATalentBrowserMixin = CreateFromMixins(ScrollListMixin)

-- DOC: CATalentBrowserMixin:UpdateClassCallback
-- What this does: Update what is shown on screen so it matches the latest game data.
-- When it runs: Called whenever the screen needs to be redrawn with fresh information.
-- Inputs:
--   - self: the UI object this function belongs to
--   - classFile: a piece of information passed in by the caller
-- Output: Nothing (nil).
-- What it changes: changes text on screen, uses Character Advancement API.
function CATalentBrowserMixin:UpdateClassCallback(classFile)
    if self.isInBrowserMode then
        return
    end

    CharacterAdvancement:SelectClassInNavigation(classFile)
end

-- DOC: CATalentBrowserMixin:LoadElements
-- What this does: Update text shown to the player.
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
--   - caClass: a piece of information passed in by the caller
--   - duplicateKnown: a piece of information passed in by the caller
-- Output: A value used by other code (a[3] > b[3]).
-- What it changes: changes text on screen, uses Character Advancement API.
function CATalentBrowserMixin:LoadElements(caClass, duplicateKnown)
    self.isInBrowserMode = duplicateKnown

    self.specializations = {}

    for i = 1, #CHARACTER_ADVANCEMENT_CLASS_ORDER do  
        local class = CHARACTER_ADVANCEMENT_CLASS_ORDER[i]
        local specs = CHARACTER_ADVANCEMENT_CLASS_SPEC_ORDER[class]

        for j = 1, #specs do
            local classFile = CharacterAdvancementUtil.GetClassDBCByFile(class)
            local specFile = CharacterAdvancementUtil.GetSpecDBCByFile(specs[j])
            local investment = C_CharacterAdvancement.GetTabTEInvestment(classFile, specFile, 0) or 0

            if (duplicateKnown and (investment > 0)) or (caClass == class) then -- show proper class or show only invested
                table.insert(self.specializations, {class, specs[j], investment})
            end
        end
    end
    
    if duplicateKnown then
        table.sort(self.specializations, function(a, b)
            return a[3] > b[3]
        end)
    end
end

-- DOC: CATalentBrowserMixin:OnLoad
-- What this does: Sets up this UI element: prepares data, connects events, and sets initial visuals.
-- When it runs: Runs once when this UI element is created/loaded.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (nil).
-- What it changes: changes text on screen.
function CATalentBrowserMixin:OnLoad()
    self:LoadElements()
    self:SetGetNumResultsFunction(function () return #self.specializations end)
    self:SetTemplate("CATalentsClassTemplate")
    self:GetSelectedHighlight():SetTexture("") 
end

function CATalentBrowserMixin:RefreshGates()
    if not next(self.ScrollFrame.buttons) then
        return
    end

    for _, button in pairs(self.ScrollFrame.buttons) do
        --button:Update()
        if button.index and button:IsVisible() then
            local classFile, specFile = self:GetDataForIndex(button.index)
            local class = CharacterAdvancementUtil.GetClassDBCByFile(classFile)
            local spec = CharacterAdvancementUtil.GetSpecDBCByFile(specFile)

            button:RefreshGateInfo(class, spec)
            button:RefreshGates(class, spec)
        end
        --button:RefreshGates(self:GetDataForIndex(button.index))
    end
end

-- DOC: CATalentBrowserMixin:SetClass
-- What this does: Set a value on this UI element and update related visuals.
-- When it runs: Called when code needs to store a value and/or update the visuals.
-- Inputs:
--   - self: the UI object this function belongs to
--   - class: a piece of information passed in by the caller
-- Output: Nothing (nil).
-- What it changes: shows/hides UI pieces.
function CATalentBrowserMixin:SetClass(class)
    if self.isInBrowserMode then
        return
    end

    --[[for i, v in pairs(self.specializations) do
        if v[1] == class then
            HybridScrollFrame_ScrollToIndex(self.ScrollFrame, i+1)
            return
        end
    end]]--
end

-- DOC: CATalentBrowserMixin:GetDataForIndex
-- What this does: Return a value that other parts of the UI need.
-- When it runs: Called when other code needs a yes/no or a piece of information.
-- Inputs:
--   - self: the UI object this function belongs to
--   - index: a position number in a list
-- Output: Nothing (nil).
-- What it changes: shows/hides UI pieces.
function CATalentBrowserMixin:GetDataForIndex(index)
    if not self.specializations[index] then
        return
    end

    return self.specializations[index][1], self.specializations[index][2]
end

--[[function CATalentBrowserMixin:OnMouseDown()
    self.rotationStart = GetCursorPosition()
    self:SetScript("OnUpdate", self._OnUpdate)
end

function CATalentBrowserMixin:OnMouseUp()
    self:SetScript("OnUpdate", nil)
end]]--

-- DOC: CATalentBrowserMixin:_OnUpdate
-- What this does: Hide part of the UI (or close a popup).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (nil).
-- What it changes: shows/hides UI pieces.
function CATalentBrowserMixin:_OnUpdate()
    local x = GetCursorPosition()
    local diff = (x - self.rotationStart) * self.rotationConst
    self.rotationStart = x
    self.scrollBar:SetValue(self.scrollBar:GetValue()-diff)
end

function CATalentBrowserMixin:Init()
    if self.isInitialized or self.template == nil then
        return
    end

    -- DOC: self.ScrollFrame.update
    -- What this does: Hide part of the UI (or close a popup).
    -- When it runs: Called by other code when needed.
    -- Inputs: none
    -- Output: Nothing (it mainly updates state and/or the UI).
    -- What it changes: shows/hides UI pieces.
    self.ScrollFrame.update = function()
        self:RefreshScrollFrame()
    end

    self.ScrollFrame.scrollBar:Hide()

    self.ScrollFrame.rotationConst = 1

    --[[self.ScrollFrame:SetScript("OnMouseDown", GenerateClosure(self.OnMouseDown, self.ScrollFrame))
    self.ScrollFrame:SetScript("OnMouseUp", GenerateClosure(self.OnMouseUp, self.ScrollFrame))
    self.ScrollFrame._OnUpdate = GenerateClosure(self._OnUpdate, self.ScrollFrame)]]--
    self.ScrollFrame:EnableMouseWheel(false)

    self.ScrollFrame.isHorizontal = true
    HybridScrollFrame_CreateButtons(self.ScrollFrame, self.template, -8, -58, nil, nil, nil, nil, "LEFT", "RIGHT")
    --HybridScrollFrame_CreateButtons(self.ScrollFrame, self.template, 0, 0)
    for i, button in ipairs(self.ScrollFrame.buttons) do
        button:Init(self.templateArgs)
    end

    HybridScrollFrame_SetDoNotHideScrollBar(self.ScrollFrame, false)
    self.isInitialized = true

    self:UpdatedSelectedHighlight()
end

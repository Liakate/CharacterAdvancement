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

local SPELLS_PER_ROW = 16
local MAX_TAGS_PER_ROW = 4
local MAX_ICON_LOADS_PER_FRAME = 4
local DEFAULT_TAG_SPACING_LEFT = 8

CA_BROWSER_UNLOCKS_AT_LEVEL = CA_BROWSER_UNLOCKS_AT_LEVEL or "Unlocks at level: %s"
CA_CLICK_TO_REMOVE_FILTER = CA_CLICK_TO_REMOVE_FILTER or "Click to remove filter"

local FILTER_TO_STRING_TABLE = {
	["FILTER_KNOWN"] = CA_FILTER_KNOWN_IN_BUILD,
	["FILTER_UNKNOWN"] = CA_FILTER_UNKNOWN_IN_BUILD,
	["FILTER_KNOWN"] = CA_FILTER_KNOWN,
	["FILTER_UNKNOWN"] = CA_FILTER_UNKNOWN,
	["FILTER_CAN_ADD"] = CA_FILTER_CAN_ADD,
	["FILTER_CAN_REMOVE"] = CA_FILTER_CAN_REMOVE,
	["FILTER_CAN_LEARN"] = CA_FILTER_CAN_LEARN,
	["FILTER_CAN_UNLEARN"] = CA_FILTER_CAN_UNLEARN,
	["FILTER_QUALITY_NORMAL"] = ITEM_QUALITY_COLORS[1]:WrapText(ITEM_QUALITY1_DESC),
	["FILTER_QUALITY_UNCOMMON"] = ITEM_QUALITY_COLORS[2]:WrapText(ITEM_QUALITY2_DESC),
	["FILTER_QUALITY_RARE"] = ITEM_QUALITY_COLORS[3]:WrapText(ITEM_QUALITY3_DESC),
	["FILTER_QUALITY_EPIC"] = ITEM_QUALITY_COLORS[4]:WrapText(ITEM_QUALITY4_DESC),
	["FILTER_QUALITY_LEGENDARY"] = ITEM_QUALITY_COLORS[5]:WrapText(ITEM_QUALITY5_DESC),
	["FILTER_CLASS_DRUID"] = ClassInfoUtil.GetColoredClassName("DRUID"),
	["FILTER_CLASS_HUNTER"] = ClassInfoUtil.GetColoredClassName("HUNTER"),
	["FILTER_CLASS_MAGE"] = ClassInfoUtil.GetColoredClassName("MAGE"),
	["FILTER_CLASS_PALADIN"] = ClassInfoUtil.GetColoredClassName("PALADIN"),
	["FILTER_CLASS_PRIEST"] = ClassInfoUtil.GetColoredClassName("PRIEST"),
	["FILTER_CLASS_ROGUE"] = ClassInfoUtil.GetColoredClassName("ROGUE"),
	["FILTER_CLASS_SHAMAN"] = ClassInfoUtil.GetColoredClassName("SHAMAN"),
	["FILTER_CLASS_WARLOCK"] = ClassInfoUtil.GetColoredClassName("WARLOCK"),
	["FILTER_CLASS_WARRIOR"] = ClassInfoUtil.GetColoredClassName("WARRIOR"),
	["FILTER_CLASS_DEATH_KNIGHT"] = ClassInfoUtil.GetColoredClassName("DEATHKNIGHT"),
	["FILTER_TYPE_ABILITY"] = CA_FILTER_TYPE_ABILITY,
	["FILTER_TYPE_TALENT"] = CA_FILTER_TYPE_TALENT,
	["FILTER_TYPE_TRAIT"] = CA_FILTER_TYPE_TRAIT,
}

--
-- SpellTag Mixin 
--
CASpellTagMixin = CreateFromMixins("CallbackRegistryMixin")

-- DOC: CASpellTagMixin:OnLoad
-- What this does: Sets up this UI element: prepares data, connects events, and sets initial visuals.
-- When it runs: Runs once when this UI element is created/loaded.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, changes text on screen, uses Character Advancement API.
function CASpellTagMixin:OnLoad()
	CallbackRegistryMixin.OnLoad(self)
	self:SetHeight(16)
	self.Left:SetSize(32, 16)
	self.Right:SetSize(32, 16)
	self.Middle:SetHeight(16)
	self.Text:SetFontObject(GameFontHighlightSmall)

	self:GetHighlightTexture():SetAtlas("wow-tab-highlight", false)
end

-- DOC: CASpellTagMixin:UpdateLayout
-- What this does: Update what is shown on screen so it matches the latest game data.
-- When it runs: Called whenever the screen needs to be redrawn with fresh information.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, changes text on screen, uses Character Advancement API.
function CASpellTagMixin:UpdateLayout()
	self:SetWidth(math.max(64, self.Text:GetWidth()+16))
end

function CASpellTagMixin:SetTag(value)
	self.filter = nil
	self.tag = value

	local name = C_CharacterAdvancement.GetSpellTagTypeDisplayInfo(value) or value
	self.Text:SetText(name)
	self:UpdateLayout()
end

-- DOC: CASpellTagMixin:SetFilter
-- What this does: Set a value on this UI element and update related visuals.
-- When it runs: Called when code needs to store a value and/or update the visuals.
-- Inputs:
--   - self: the UI object this function belongs to
--   - filter: the filter/search text used to narrow results
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, changes text on screen.
function CASpellTagMixin:SetFilter(filter)
	self.tag = nil
	self.filter = filter

	self.Text:SetText(FILTER_TO_STRING_TABLE[filter] or filter)

	self:UpdateLayout()
end

-- DOC: CASpellTagMixin:OnClick
-- What this does: Handle a button click (do the action and update the UI).
-- When it runs: Runs when the player clicks the related button.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces.
function CASpellTagMixin:OnClick()
	self:GetParent():OnButtonClick(self)
end

function CASpellTagMixin:OnEnter()
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:AddLine(self.Text:GetText(), 1, 1, 1)
	GameTooltip:AddLine(CA_CLICK_TO_REMOVE_FILTER)
	GameTooltip:Show()
end

-- DOC: CASpellTagMixin:OnLeave
-- What this does: Hide the tooltip/highlight when the mouse leaves this item.
-- When it runs: Runs when the mouse pointer leaves the related UI element.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces.
function CASpellTagMixin:OnLeave()
	GameTooltip:Hide()
end
--
-- SpellTag frame
--
CASpellTagFrameMixin = CreateFromMixins("CallbackRegistryMixin")

-- DOC: CASpellTagFrameMixin:OnLoad
-- What this does: Sets up this UI element: prepares data, connects events, and sets initial visuals.
-- When it runs: Runs once when this UI element is created/loaded.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: updates UI/state.
function CASpellTagFrameMixin:OnLoad()
	CallbackRegistryMixin.OnLoad(self)

	self:SetBackdrop(GameTooltip:GetBackdrop())
	self:SetBackdropColor(0, 0, 0, 0.8)
	self:SetBackdropBorderColor(0.6, 0.6, 0.6)

	self.framePool = CreateFramePool("Button", self, "CASpellTagTemplate")
	self.framesToID = {}

	self:GenerateCallbackEvents({ "OnSpellTagClicked"})
end

-- DOC: CASpellTagFrameMixin:AllocateButton
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
--   - button: the button that triggered this (the thing you clicked)
--   - layoutIndex: a position number in a list
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces.
function CASpellTagFrameMixin:AllocateButton(button, layoutIndex)
	if ((layoutIndex-1)%MAX_TAGS_PER_ROW) == 0 then
		local prevRowTopLeft = self.framesToID[layoutIndex-MAX_TAGS_PER_ROW]

		if prevRowTopLeft then
			button:ClearAndSetPoint("TOPLEFT", prevRowTopLeft, "BOTTOMLEFT", 0, -DEFAULT_TAG_SPACING_LEFT/2)
		else
			button:ClearAndSetPoint("TOPLEFT", self.Text, "BOTTOMLEFT", 0, -DEFAULT_TAG_SPACING_LEFT/2)
		end
	else
		button:ClearAndSetPoint("LEFT", self.framesToID[layoutIndex-1], "RIGHT", DEFAULT_TAG_SPACING_LEFT/2, 0)
	end

	self:UpdateWidth()
end

-- DOC: CASpellTagFrameMixin:UpdateWidth
-- What this does: Update what is shown on screen so it matches the latest game data.
-- When it runs: Called whenever the screen needs to be redrawn with fresh information.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces.
function CASpellTagFrameMixin:UpdateWidth()
	local rowWidth = 12

	for i = 1, #self.framesToID do
		if ((i-1)%MAX_TAGS_PER_ROW) == 0 then
			rowWidth = 12
		end

		local button = self.framesToID[i]

		rowWidth = rowWidth + (button and (button:GetWidth() + (DEFAULT_TAG_SPACING_LEFT/2)) or 0)

		if self:GetWidth() < rowWidth then
			self:SetWidth(rowWidth)
		end
	end
end

-- DOC: CASpellTagFrameMixin:OnButtonClick
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Runs for a UI callback named OnButtonClick.
-- Inputs:
--   - self: the UI object this function belongs to
--   - button: the button that triggered this (the thing you clicked)
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces.
function CASpellTagFrameMixin:OnButtonClick(button)
	self:TriggerEvent("OnSpellTagClicked", button.filter, button.tag)
end

function CASpellTagFrameMixin:SetUpSpellTags(filtersTable, spellTagsTable)
	self.framePool:ReleaseAll()
	wipe(self.framesToID)
	self.framesToID = {}

	self:SetWidth(16)

	-- 4 entries per row max

	local layoutIndex = 1

	for filter in pairs(filtersTable) do
		local button = self.framePool:Acquire()
		button:Show()
		button:SetFilter(filter)

		self.framesToID[layoutIndex] = button
		self:AllocateButton(button, layoutIndex)

		layoutIndex = layoutIndex + 1
	end

	for _, tag in pairs(spellTagsTable) do
		local button, isNew = self.framePool:Acquire()
		button:Show()
		button:SetTag(tag)

		self.framesToID[layoutIndex] = button
		self:AllocateButton(button, layoutIndex)

		layoutIndex = layoutIndex + 1
	end

	local totalRows = math.ceil((layoutIndex-1)/MAX_TAGS_PER_ROW)
	self:SetHeight((totalRows*16) + ((totalRows-1)*4) + 16 + 12)
end

--
-- Ability Mixin
--
CABrowserAbilityMixin = CreateFromMixins("CASpellButtonBaseMixin")

-- DOC: CABrowserAbilityMixin:OnShow
-- What this does: Prepares the UI right before the player sees it (updates text, lists, or buttons).
-- When it runs: Runs each time this UI element becomes visible.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces.
function CABrowserAbilityMixin:OnShow()
end

function CABrowserAbilityMixin:OnHide()
end

function CABrowserAbilityMixin:OnLoad()
    CASpellButtonBaseMixin.OnLoad(self)
    self:RegisterForDrag("LeftButton")
    self.Icon:SetBorderSize(34, 34)
    self.Icon:SetOverlaySize(34, 34)

    self.Icon.KnownGlow:SetAtlas("ca_known_glow")
    self.Icon.KnownGlow:SetVertexColor(NORMAL_FONT_COLOR:GetRGB())
    self.Icon:SetBackgroundSize(58, 58)
    self.Icon:SetBackgroundTexture("Interface\\Spellbook\\UI-Spellbook-SpellBackground")
    self.Icon:SetBackgroundOffset(9.5, -9.5)

    -- DOC: self.Icon:SetIconDesaturated
    -- What this does: Set a value on this UI element and update related visuals.
    -- When it runs: Called when code needs to store a value and/or update the visuals.
    -- Inputs:
    --   - self: the UI object this function belongs to
    --   - desaturated: a piece of information passed in by the caller
    -- Output: Nothing (nil).
    -- What it changes: shows/hides UI pieces.
    function self.Icon:SetIconDesaturated(desaturated)
    	BorderIconTemplateMixin.SetIconDesaturated(self, desaturated)
    	self:GetParent().Class.Icon:SetDesaturated(desaturated)
    end

    self.Class:SetScript("OnEnter", function(self)
    	local class = self:GetParent().entry.Class

    	if class then
    		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    		GameTooltip:AddLine(ClassInfoUtil.GetColoredClassName(string.upper(class)))
    	end

    	GameTooltip:Show()
	end)

	self.Class:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

    self.Suggested:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(SUGGESTED_ABILITY, 1, 1, 1)
		GameTooltip:AddLine(SUGGESTED_ABILITY_TOOLTIP)

    	GameTooltip:Show()
	end)

	self.Suggested:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
end

-- DOC: CABrowserAbilityMixin:SetDisabledVisual
-- What this does: Set a value on this UI element and update related visuals.
-- When it runs: Called when code needs to store a value and/or update the visuals.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (nil).
-- What it changes: shows/hides UI pieces, uses Character Advancement API.
function CABrowserAbilityMixin:SetDisabledVisual()
	CASpellButtonBaseMixin.SetDisabledVisual(self)
	self.Class:EnableMouse(false)
	self.Class.Icon:SetVertexColor(0.5, 0.5, 0.5, 0.5)
	self:EnableMouse(false)
end

function CABrowserAbilityMixin:SetEntry(entry, isSuggested)
	self.Class.Icon:SetVertexColor(1, 1, 1, 1)
	self.Class:EnableMouse(true)
	self:EnableMouse(true)
	CASpellButtonBaseMixin.SetEntry(self, entry)

	local class = entry.Class
	local classAtlas = string.lower("groupfinder-icon-class-"..class)

	if AtlasUtil:AtlasExists(classAtlas) then
		self.Class:Show()
		self.Class.Icon:SetAtlas(classAtlas, false)
	else
		self.Class:Hide()
	end

	if BuildCreatorUtil.IsPickingSpells() then
		return
	end

	if not self:GetParent():GetAvailableStatus() then
        self.Icon:SetIconDesaturated(true)
        self:SetDisabledVisual()
	end

	if isSuggested then
		self.Suggested.Icon:SetAtlas("talents-search-notonactionbar", false)
		self.Suggested:Show()
	else
		self.Suggested:Hide()
	end

	if C_CharacterAdvancement.IsSuggestionContextOverride(entry.ID) then
		self.Suggested:Show()
		self.Suggested.Icon:SetAtlas("talents-search-notonactionbarhidden", false)
	end
end

--
-- browser row mixin
--
CABrowserRowMixin = CreateFromMixins(ScrollListItemBaseMixin)

-- DOC: CABrowserRowMixin:OnLoad
-- What this does: Sets up this UI element: prepares data, connects events, and sets initial visuals.
-- When it runs: Runs once when this UI element is created/loaded.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: A value used by other code (self:GetParent():GetParent():GetParent()).
-- What it changes: shows/hides UI pieces, changes text on screen, uses Character Advancement API.
function CABrowserRowMixin:OnLoad()
	self:EnableMouse(false)
	self.AbilityPool = CreateFramePool("Button", self, "CABrowserSpellButtonTemplate")

	self.Icon:SetScript("OnEnter", GenerateClosure(self.OnEnterCategoryButton, self))
	self.Icon:SetScript("OnLeave", function() GameTooltip:Hide() end)

	self.delayedEntries = {}
	self.categoryID = nil
end

-- DOC: CABrowserRowMixin:Init
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: A value used by other code (self:GetParent():GetParent():GetParent()).
-- What it changes: shows/hides UI pieces, changes text on screen, uses Character Advancement API.
function CABrowserRowMixin:Init()
end

function CABrowserRowMixin:SetSelected()
end

function CABrowserRowMixin:OnSelected()
end

-- DOC: CABrowserRowMixin:GetScrollParent
-- What this does: Return a value that other parts of the UI need.
-- When it runs: Called when other code needs a yes/no or a piece of information.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: A value used by other code (self:GetParent():GetParent():GetParent()).
-- What it changes: shows/hides UI pieces, changes text on screen, uses Character Advancement API.
function CABrowserRowMixin:GetScrollParent()
	return self:GetParent():GetParent():GetParent()
end

function CABrowserRowMixin:GetAvailableStatus()
	return self.isAvailable
end

-- DOC: CABrowserRowMixin:SetAvailableStatus
-- What this does: Set a value on this UI element and update related visuals.
-- When it runs: Called when code needs to store a value and/or update the visuals.
-- Inputs:
--   - self: the UI object this function belongs to
--   - isAvailable: a yes/no flag
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, changes text on screen, uses Character Advancement API.
function CABrowserRowMixin:SetAvailableStatus(isAvailable)
	self.isAvailable = isAvailable
end

function CABrowserRowMixin:SetAvailableVisual(isAvailable, text, errorText)
	if not(isAvailable) then
		self.Icon.Icon:SetVertexColor(0, 0, 0)
     	self.Icon.Lock:Show()
     	self.Icon.Ring:SetVertexColor(0.5, 0.5, 0.5)
     	self.Icon.Text:SetText(errorText)
     	self.Icon.Text:SetTextColor(0.5, 0.5, 0.5)
     else
	    self.Icon.Icon:SetVertexColor(1, 1, 1)
	    self.Icon.Ring:SetVertexColor(1, 1, 1)
	    self.Icon.Lock:Hide()
	    self.Icon.Text:SetText(text)
	    self.Icon.Text:SetTextColor(1, 1, 1)
	end
end

-- DOC: CABrowserRowMixin:OnEnterCategoryButton
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Runs for a UI callback named OnEnterCategoryButton.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: A value used by other code (self.categoryID).
-- What it changes: shows/hides UI pieces, uses Character Advancement API.
function CABrowserRowMixin:OnEnterCategoryButton()
	GameTooltip:SetOwner(self.Icon, "ANCHOR_RIGHT")
	GameTooltip:AddLine(self.tooltipTitle, 1, 1, 1)
	GameTooltip:AddLine(self.tooltipText, 1, 0.82, 0, true)
	GameTooltip:Show()
end

function CABrowserRowMixin:UpdateCategoryVisual()
	local reqLevel, name, icon, description = C_CharacterAdvancement.GetCategoryDisplayInfo(self:GetCategoryID())

	if not name then return end

	SetPortraitToTexture(self.Icon.Icon, "Interface\\Icons\\"..icon)

	self.tooltipTitle = name
	self.tooltipText = description or "No description for this category is filled yet. Please update data."

    self:SetAvailableVisual(reqLevel <= UnitLevel("player"), name, name.." ("..string.format(CA_BROWSER_UNLOCKS_AT_LEVEL, "|cffFF0000"..reqLevel.."|r")..")|r")
end

-- DOC: CABrowserRowMixin:LoadEntry
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
--   - button: the button that triggered this (the thing you clicked)
--   - index: a position number in a list
-- Output: A value used by other code (self.categoryID).
-- What it changes: shows/hides UI pieces, uses Character Advancement API.
function CABrowserRowMixin:LoadEntry(button, index)
	local entry, isSuggested = C_CharacterAdvancement.GetFilteredEntryAtIndexByCategory(self:GetCategoryID(), index)

	if entry then
		button.Icon.Icon:Show()
		button:SetEntry(entry, isSuggested)
	end
end

-- DOC: CABrowserRowMixin:LoadIconsOnUpdate
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: A value used by other code (self.categoryID).
-- What it changes: shows/hides UI pieces, uses Character Advancement API.
function CABrowserRowMixin:LoadIconsOnUpdate()
	for i = 1, MAX_ICON_LOADS_PER_FRAME do
		local button, index = next(self.delayedEntries) 

		if button then
			self:LoadEntry(button, index)
			self.delayedEntries[button] = nil
		else
			self:SetScript("OnUpdate", nil)
		end
	end
end

-- DOC: CABrowserRowMixin:SetCategoryID
-- What this does: Set a value on this UI element and update related visuals.
-- When it runs: Called when code needs to store a value and/or update the visuals.
-- Inputs:
--   - self: the UI object this function belongs to
--   - value: a value to store/apply
-- Output: A value used by other code (self.categoryID).
-- What it changes: shows/hides UI pieces, uses Character Advancement API.
function CABrowserRowMixin:SetCategoryID(value)
	self.categoryID = value
end

function CABrowserRowMixin:GetCategoryID()
	return self.categoryID
end

-- DOC: CABrowserRowMixin:Update
-- What this does: Update what is shown on screen so it matches the latest game data.
-- When it runs: Called whenever the screen needs to be redrawn with fresh information.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (nil).
-- What it changes: shows/hides UI pieces, uses Character Advancement API.
function CABrowserRowMixin:Update()
	local categoryID, startIndex, maxIndex = self:GetScrollParent():GetDataForIndex(self.index)

	self.AbilityPool:ReleaseAll()
	wipe(self.delayedEntries)
	self:SetScript("OnUpdate", nil)

	if not categoryID then
		dprint("error. no category id")
		return
	end

	self:SetCategoryID(categoryID)

	if startIndex < 0 then -- we should display category icon
		self:UpdateCategoryVisual()
		self.Icon:Show()
		self.Shadow:Show()
		return
	end

	local reqLevel, _, _, _, shouldStaggerDisplayingEntries = C_CharacterAdvancement.GetCategoryDisplayInfo(categoryID)

	self:SetAvailableStatus(UnitLevel("player") >= reqLevel)

	self.Icon:Hide()
	self.Shadow:Hide()

	for i = 1, math.min(SPELLS_PER_ROW, (maxIndex-startIndex)) do
		local index = startIndex+i

        button = self.AbilityPool:Acquire()
        button:SetPoint("LEFT", ( 24 + ((i - 1) % SPELLS_PER_ROW) * 44), 0)
        button:Show()

        if shouldStaggerDisplayingEntries then -- categories thousands of entries, optimize it for better performance
        	button.Icon.Icon:Hide()
        	button.Class:Hide()
        	button.Suggested:Hide()
        	self.delayedEntries[button] = index
        else
        	self:LoadEntry(button, index)
        end
    end

    if next(self.delayedEntries) then
    	self:SetScript("OnUpdate", self.LoadIconsOnUpdate)
    end
end

--
-- browser mixin
--

CABorwserMixin = CreateFromMixins(ScrollListMixin)

-- DOC: CABorwserMixin:GetNumResults
-- What this does: Return a value that other parts of the UI need.
-- When it runs: Called when other code needs a yes/no or a piece of information.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: A value used by other code (totalRows).
-- What it changes: shows/hides UI pieces, uses Character Advancement API.
function CABorwserMixin:GetNumResults()
	wipe(self.categoryMap)
	self.categoryMap = {}
	local totalRows = 0
	local categories = C_CharacterAdvancement.GetCategories()
	local hasDisabledCategory = false

	for i = 1, #categories do
		local categoryID = categories[i]
		local categoryTotalResults = C_CharacterAdvancement.GetNumFilteredEntriesByCategory(categoryID) 
		local categoryTakesRows = math.ceil(categoryTotalResults/SPELLS_PER_ROW)
		local reqLevel = C_CharacterAdvancement.GetCategoryDisplayInfo(categoryID)

		if categoryTakesRows > 0 then
			if hasDisabledCategory then
				categoryTakesRows = 1 -- display just category name
			else
				categoryTakesRows = categoryTakesRows + 1 -- add 1 extra row for category name
			end
		end

		if reqLevel > UnitLevel("player") then
			hasDisabledCategory = true
		end

		self.categoryMap[i] = {categoryID, categoryTakesRows, categoryTotalResults}
		totalRows = totalRows + categoryTakesRows
	end

	if totalRows == 0 then
		self.NoSearchResults:Show()
	else
		self.NoSearchResults:Hide()
	end

	return totalRows
end

-- DOC: CABorwserMixin:GetDataForIndex
-- What this does: Return a value that other parts of the UI need.
-- When it runs: Called when other code needs a yes/no or a piece of information.
-- Inputs:
--   - self: the UI object this function belongs to
--   - index: a position number in a list
-- Output: A value used by other code (categoryID, (rowInCategory-2)*SPELLS_PER...).
-- What it changes: changes text on screen, uses Character Advancement API.
function CABorwserMixin:GetDataForIndex(index) -- returns categoryID, startIndex, maxIndex
	local totalRows = 0
	
	for i = 1, #self.categoryMap do
		local categoryID = self.categoryMap[i][1]
		local categoryTakesRows = self.categoryMap[i][2]
		local categoryTotalResults = self.categoryMap[i][3]

		if (totalRows+categoryTakesRows) >= index then -- we're in right category
			local rowInCategory = index - totalRows
			return categoryID, (rowInCategory-2)*SPELLS_PER_ROW, categoryTotalResults -- -2 for to start listing spells from 2nd line
		end

		totalRows = totalRows + categoryTakesRows
	end
end

-- DOC: CABorwserMixin:OnLoad
-- What this does: Sets up this UI element: prepares data, connects events, and sets initial visuals.
-- When it runs: Runs once when this UI element is created/loaded.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: A value used by other code (totalHeight).
-- What it changes: changes text on screen, uses Character Advancement API.
function CABorwserMixin:OnLoad()
	self.categoryMap = {}

	self:SetGetNumResultsFunction(GenerateClosure(self.GetNumResults, self))
	self:SetTemplate("CABrowserRowTemplate")
	self:GetSelectedHighlight():SetTexture("") 
end

-- DOC: CABorwserMixin:DisplaySearchResults
-- What this does: Call into the Character Advancement system (server/game API) and update the UI with the result.
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
--   - searchQuery: the filter/search text used to narrow results
--   - filterOutput: the filter/search text used to narrow results
-- Output: A value used by other code (totalHeight).
-- What it changes: uses Character Advancement API.
function CABorwserMixin:DisplaySearchResults(searchQuery, filterOutput)
	local categories = C_CharacterAdvancement.GetCategories()

	for i = 1, #categories do
		C_CharacterAdvancement.SetFilteredEntriesByCategory(categories[i], filterOutput[2], searchQuery or "", filterOutput[1])
	end

	self:RefreshScrollFrame()

	return totalHeight
end
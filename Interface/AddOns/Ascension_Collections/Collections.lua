-- GUIDE: What is this file?
-- Purpose: Logic for the Collections UI (tabs, panels, and the framework that other UIs attach to).
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

CollectionsMixin = CreateFromMixins(TabSystemMixin)

-- DOC: CollectionsMixin:OnLoad
-- What this does: Sets up this UI element: prepares data, connects events, and sets initial visuals.
-- When it runs: Runs once when this UI element is created/loaded.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: listens for game events.
function CollectionsMixin:OnLoad()
	self:SetupTabSystem()

	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	-- auto show CoA talents
	if IsCustomClass() and C_Player:GetLevel() < COA_AUTO_SHOW_TALENTS_LEVEL then
		self:RegisterEvent("PLAYER_LEVEL_UP")
	end

	self:RegisterForDrag("LeftButton")
	self:SetScript("OnDragStart", self.StartMoving)
	self:SetScript("OnDragStop", self.StopMovingOrSizing)
	local uiScale = GetUIScale()
	if uiScale > 0.9 then
		uiScale = uiScale - 0.9
		self:SetScale(1 - uiScale)
	end
end

-- DOC: CollectionsMixin:SetupTabSystem
-- What this does: Set a value on this UI element and update related visuals.
-- When it runs: Called when code needs to store a value and/or update the visuals.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: updates UI/state.
function CollectionsMixin:SetupTabSystem()
	TabSystemMixin.OnLoad(self)
	self:SetTabTemplate("CollectionTabTemplate")
	self:SetTabSelectedSound(SOUNDKIT.CHARACTER_SHEET_TAB_70)
	self:SetTabPoint("TOPLEFT", self, "BOTTOMLEFT", 12, 10)
	self:RegisterCallback("OnTabSelected", self.OnTabSelected, self)
	self.Tabs = {}
	
	-- Character Advancement Tab
	local tab
	do
		if IsCustomClass() then
			tab = self:AddTab(CHARACTER_ADVANCEMENT, "CoATalentFrame")
		else
			tab = self:AddTab(CHARACTER_ADVANCEMENT, "CharacterAdvancement")
		end
		tab:SetPreClick(CharacterAdvancement_LoadUI)
		tab:SetIcon("Interface\\Icons\\spell_Paladin_divinecircle")
		tab:SetTooltip(CHARACTER_ADVANCEMENT, CHARACTER_ADVANCEMENT_TOOLTIP)
		self.Tabs.CharacterAdvancement = tab:GetTabID()
	end
	
	-- Hero Architect Tab
	local isHero = C_Player:IsHero()

	if isHero then
		tab = self:AddTab(HERO_ARCHITECT, "BuildCreatorFrame")
		tab:SetPreClick(BuildCreator_LoadUI)
		tab:SetIcon("Interface\\Icons\\ability_priest_angelicfeather")
		tab:SetTooltip(HERO_ARCHITECT, HERO_ARCHITECT_TOOLTIP)
		self.Tabs.HeroArchitect = tab:GetTabID()
	end

	-- Skill Card Tab
	if isHero then
		tab = self:AddTab(RECOVERY_CATEGORY7, "SkillCardsFrame")
		tab:SetPreClick(SkillCards_LoadUI)
		tab:SetIcon("Interface\\Icons\\inv_inscription_darkmooncard_putrescence")
		tab:SetTooltip(UNLOCK_SKILL_CARDS_TITLE, BOOSTER_TAB_SUBTEXT)
		self.Tabs.SkillCards = tab:GetTabID()
	end
	
	-- Vanity Tab
	do
		tab = self:AddTab(VANITY, "StoreCollectionFrame")
		tab:SetIcon("Interface\\icons\\INV_Chest_Awakening")
		tab:SetTooltip(VANITY, VANITY_TOOLTIP)
		self.Tabs.Vanity = tab:GetTabID()
	end

	-- Mystic Enchanting Tab
	if not IsCustomClass() then -- coa does not have mystic enchants
		tab = self:AddTab(MYSTIC_ENCHANT, "EnchantCollection")
		tab:SetPreClick(MysticEnchant_LoadUI)
		tab:SetIcon("Interface\\icons\\inv_custom_ReforgeToken")
		tab:SetTooltip(MYSTIC_ENCHANT, MYSTIC_ENCHANT_TOOLTIP)
		self.Tabs.MysticEnchants = tab:GetTabID()
	end
	
	-- Season Collection Tab
	if isHero then
		tab = self:AddTab(SEASONAL_COLLECTION, "SeasonCollectionFrame")
		tab:SetPreClick(SeasonCollection_LoadUI)
		tab:SetIcon("Interface\\icons\\season1_complete")
		tab:SetTooltip(SEASONAL_COLLECTION, SEASONAL_COLLECTION_TOOLTIP)
		self.Tabs.SeasonalCollection = tab:GetTabID()
	end

	-- Wardrobe Tab
	do
		tab = self:AddTab(WARDROBE, "AppearanceWardrobeFrame")
		tab:SetPreClick(AppearanceUI_LoadUI)
		tab:SetIcon("Interface\\Icons\\inv_arcane_orb")
		tab:SetTooltip(WARDROBE, WARDROBE_TOOLTIP)
		self.Tabs.Wardrobe = tab:GetTabID()
	end
end

-- DOC: CollectionsMixin:OnTabSelected
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Runs for a UI callback named OnTabSelected.
-- Inputs:
--   - self: the UI object this function belongs to
--   - tabID: an identifier (a number/string that points to a specific thing)
--   - tab: a piece of information passed in by the caller
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: updates UI/state.
function CollectionsMixin:OnTabSelected(tabID, tab)
	local panel = self:GetPanelForTabID(tabID)
	if panel then
		local sizeX, sizeY = panel:GetSize()
		
		local tabX = 12
		-- @andrew
		-- hack fix: some panels seem to have sizes bigger than the art randomly
		--so tab Y needs to be changed to match per tab
		local tabY = 10
		if tabID == self.Tabs.SeasonalCollection then
			tabY = 2
		elseif tabID == self.Tabs.Wardrobe then
			tabY = 2
		elseif tabID == self.Tabs.Vanity then
			sizeY = sizeY + 50
			sizeX = sizeX + 80
		end
		
		self:SetSize(sizeX, sizeY)
		self:SetTabPoint("TOPLEFT", self, "BOTTOMLEFT", tabX, tabY)
		self:UpdateTabLayout()
	end
end

-- DOC: CollectionsMixin:OnShow
-- What this does: Prepares the UI right before the player sees it (updates text, lists, or buttons).
-- When it runs: Runs each time this UI element becomes visible.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: A value used by other code (self:GetTabByID(self.Tabs.CharacterAdvan...).
-- What it changes: updates UI/state.
function CollectionsMixin:OnShow()
	-- nov 26th 2023 @andrew
	-- huge issue where `toplevel="true"` would cause this frame to climb level every time staticpopup was shown while this was open
	-- it was then saved in layout-cache.txt and persists on that character indefinitely. 
	-- extremely high levels (like 200k+) cause fps issues
	self:SetFrameLevel(MainMenuBarOverlayFrame:GetFrameLevel()+1)
	PlaySound(SOUNDKIT.CHARACTER_SHEET_OPEN_70)
	if Draft then
		Draft:HideCards()
	end
	UpdateMicroButtons()
	
	-- disable character advancement tab if player is a coa class and not level 10+
	local caTab = self:GetCharacterAdvancementTab()
	caTab:SetTabEnabled(not IsCustomClass() or C_Player:GetLevel() >= COA_AUTO_SHOW_TALENTS_LEVEL, format(FEATURE_BECOMES_AVAILABLE_AT_LEVEL, COA_AUTO_SHOW_TALENTS_LEVEL))
	
	-- disable enchanting tab if player is not 60+, is not prestiged, and has not opened the ui before
	local enchantTab = self:GetMysticEnchantTab()
	if enchantTab then
		enchantTab:SetTabEnabled(MysticEnchantUtil.HasUnlockedEnchantTab(), format(MYSTIC_ENCHANTING_ALTAR_UNLOCK, 60))
	end

	-- skill card tab only shown in draft/wildcard
	if C_GameMode:IsGameModeActive(Enum.GameMode.WildCard) or C_GameMode:IsGameModeActive(Enum.GameMode.Draft) then
		self:ShowTabID(self.Tabs.SkillCards)
	else
		self:HideTabID(self.Tabs.SkillCards)
	end
	
	HelpTip:Acknowledge("WARDROBE_CHANGE_TRANSMOG_HINT")
end

-- DOC: CollectionsMixin:OnHide
-- What this does: Cleans up when the UI closes (stops updates and hides extra popups).
-- When it runs: Runs when this UI element is hidden.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: A value used by other code (self:GetTabByID(self.Tabs.CharacterAdvan...).
-- What it changes: listens for game events.
function CollectionsMixin:OnHide()
	PlaySound(SOUNDKIT.CHARACTER_SHEET_CLOSE_70)
	self:HideCurrentPanel()
	UpdateMicroButtons()
end

function CollectionsMixin:PLAYER_REGEN_DISABLED()
	HideUIPanel(self)
end

-- DOC: CollectionsMixin:GetCharacterAdvancementTab
-- What this does: Return a value that other parts of the UI need.
-- When it runs: Called when other code needs a yes/no or a piece of information.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: A value used by other code (self:GetTabByID(self.Tabs.CharacterAdvan...).
-- What it changes: listens for game events.
function CollectionsMixin:GetCharacterAdvancementTab()
	return self:GetTabByID(self.Tabs.CharacterAdvancement)
end

function CollectionsMixin:GetMysticEnchantTab()
	return self:GetTabByID(self.Tabs.MysticEnchants)
end

-- DOC: CollectionsMixin:GetTransmogTab
-- What this does: Return a value that other parts of the UI need.
-- When it runs: Called when other code needs a yes/no or a piece of information.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: A value used by other code (self:GetTabByID(self.Tabs.Wardrobe)).
-- What it changes: listens for game events.
function CollectionsMixin:GetTransmogTab()
	return self:GetTabByID(self.Tabs.Wardrobe)
end

function CollectionsMixin:GoToTab(id)
	if not id then return end
	ShowUIPanel(self)
	self:SelectTabID(id)
	UpdateMicroButtons()
end

-- DOC: CollectionsMixin:IsOnTab
-- What this does: Checks a condition and returns true/false.
-- When it runs: Called when other code needs a yes/no or a piece of information.
-- Inputs:
--   - self: the UI object this function belongs to
--   - id: an identifier (a number/string that points to a specific thing)
-- Output: A value used by other code (self:IsShown() and self:GetCurrentTabID(...).
-- What it changes: listens for game events.
function CollectionsMixin:IsOnTab(id)
	return self:IsShown() and self:GetCurrentTabID() == id
end

function CollectionsMixin:PLAYER_LEVEL_UP(level)
	if level < COA_AUTO_SHOW_TALENTS_LEVEL then
		return
	end
	
	Timer.AfterCombat(function()
		Timer.After(2, function()
			C_PopupQueue:Add(self, function() self:GoToTab(Collections.Tabs.CharacterAdvancement) end, function() return not self:IsVisible() end)
		end)
	end)
	
	self:UnregisterEvent("PLAYER_LEVEL_UP")
end 
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

CoASpecChoiceMixin = {}

CoASpecChoiceMixin.State = {
    Active = 1,
    Inactive = 2,
    Disabled = 3,
}

-- DOC: CoASpecChoiceMixin:OnLoad
-- What this does: Sets up this UI element: prepares data, connects events, and sets initial visuals.
-- When it runs: Runs once when this UI element is created/loaded.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: updates UI/state.
function CoASpecChoiceMixin:OnLoad()
    self.ColumnDivider:SetAtlas("spec-columndivider", Const.TextureKit.IgnoreAtlasSize)
    self.HoverBackground:SetAtlas("spec-hover-background", Const.TextureKit.IgnoreAtlasSize)
    
    self.pools = CreateFramePoolCollection()

    self.selectedBackground = {
        back  = { self.SelectedBackgroundBack1, self.SelectedBackgroundBack2 },
        left  = { self.SelectedBackgroundLeft1, self.SelectedBackgroundLeft2, self.SelectedBackgroundLeft3, self.SelectedBackgroundLeft4 },
        right = { self.SelectedBackgroundRight1, self.SelectedBackgroundRight2, self.SelectedBackgroundRight3, self.SelectedBackgroundRight4 },
    }
    
    self.activatedBackground = {
        back = { self.ActivatedBackgroundBack1, self.ActivatedBackgroundBack2 },
        left = { self.ActivatedBackgroundLeft1, self.ActivatedBackgroundLeft2, self.ActivatedBackgroundLeft3, self.ActivatedBackgroundLeft4 },
        right = { self.ActivatedBackgroundRight1, self.ActivatedBackgroundRight2, self.ActivatedBackgroundRight3, self.ActivatedBackgroundRight4 },
    }

    self.SelectedBackgroundBack1:SetAtlas("spec-selected-background1", Const.TextureKit.UseAtlasSize)
    self.SelectedBackgroundBack2:SetAtlas("spec-selected-background1", Const.TextureKit.UseAtlasSize)

    self.SelectedBackgroundLeft1:SetAtlas("spec-selected-background2", Const.TextureKit.UseAtlasSize)
    self.SelectedBackgroundLeft2:SetAtlas("spec-selected-background3", Const.TextureKit.UseAtlasSize)
    self.SelectedBackgroundLeft3:SetAtlas("spec-selected-background4", Const.TextureKit.UseAtlasSize)
    self.SelectedBackgroundLeft4:SetAtlas("spec-selected-background5", Const.TextureKit.UseAtlasSize)

    self.SelectedBackgroundRight1:SetAtlas("spec-selected-background2", Const.TextureKit.UseAtlasSize)
    self.SelectedBackgroundRight2:SetAtlas("spec-selected-background3", Const.TextureKit.UseAtlasSize)
    self.SelectedBackgroundRight3:SetAtlas("spec-selected-background4", Const.TextureKit.UseAtlasSize)
    self.SelectedBackgroundRight4:SetAtlas("spec-selected-background5", Const.TextureKit.UseAtlasSize)
    self.SelectedBackgroundRight1:FlipX()
    self.SelectedBackgroundRight2:FlipX()
    self.SelectedBackgroundRight3:FlipX()
    self.SelectedBackgroundRight4:FlipX()

    self.ActivatedBackgroundBack1:SetAtlas("spec-selected-background1", Const.TextureKit.UseAtlasSize)
    self.ActivatedBackgroundBack2:SetAtlas("spec-selected-background1", Const.TextureKit.UseAtlasSize)

    self.ActivatedBackgroundLeft1:SetAtlas("spec-selected-background2", Const.TextureKit.UseAtlasSize)
    self.ActivatedBackgroundLeft2:SetAtlas("spec-selected-background3", Const.TextureKit.UseAtlasSize)
    self.ActivatedBackgroundLeft3:SetAtlas("spec-selected-background4", Const.TextureKit.UseAtlasSize)
    self.ActivatedBackgroundLeft4:SetAtlas("spec-selected-background5", Const.TextureKit.UseAtlasSize)

    self.ActivatedBackgroundRight1:SetAtlas("spec-selected-background2", Const.TextureKit.UseAtlasSize)
    self.ActivatedBackgroundRight2:SetAtlas("spec-selected-background3", Const.TextureKit.UseAtlasSize)
    self.ActivatedBackgroundRight3:SetAtlas("spec-selected-background4", Const.TextureKit.UseAtlasSize)
    self.ActivatedBackgroundRight4:SetAtlas("spec-selected-background5", Const.TextureKit.UseAtlasSize)
    self.ActivatedBackgroundRight1:FlipX()
    self.ActivatedBackgroundRight2:FlipX()
    self.ActivatedBackgroundRight3:FlipX()
    self.ActivatedBackgroundRight4:FlipX()

    self.SpecInfo.Separator.topPadding = 12
    self.SpecInfo.Separator.bottomPadding = 12
    self.SpecInfo.Complexity.topPadding = 12
end 

-- DOC: CoASpecChoiceMixin:OnHide
-- What this does: Cleans up when the UI closes (stops updates and hides extra popups).
-- When it runs: Runs when this UI element is hidden.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: changes text on screen.
function CoASpecChoiceMixin:OnHide()
    self:StopActiveFX()
end

function CoASpecChoiceMixin:SetSpecInfo(specInfo, width, height, isLeftMost, isRightMost)
    self.nextLayoutIndex = CreateCounter()
    self.SpecInfo.Name.layoutIndex = self.nextLayoutIndex()
    self.specInfo = specInfo

    self:SetSize(width, height)
    FrameUtil.SetRegionsSize(self.selectedBackground.back, width, height+24)
    FrameUtil.SetRegionsHeight(self.selectedBackground.left, height+24)
    FrameUtil.SetRegionsHeight(self.selectedBackground.right, height+24)
    FrameUtil.SetRegionsSize(self.activatedBackground.back, width, height+24)
    FrameUtil.SetRegionsHeight(self.activatedBackground.left, height+24)
    FrameUtil.SetRegionsHeight(self.activatedBackground.right, height+24)

    local atlasName = CharacterAdvancementUtil.GetThumbnailAtlas(specInfo.Class, specInfo.Spec)
    self.Banner.Image:SetAtlas(atlasName)
    self.Banner.ImageHover:SetAtlas(atlasName)
    
    self.isLeftMostSpec = isLeftMost
    self.isRightMostSpec = isRightMost
    
    self.SpecInfo.Name:SetText(specInfo.Name)
    self:CreateRoles()
    self.SpecInfo.Complexity.layoutIndex = self.nextLayoutIndex()
    self.SpecInfo.Separator.layoutIndex = self.nextLayoutIndex()
    self.SpecInfo.Description.layoutIndex = self.nextLayoutIndex()
    self:CreateAdditionalInfo()

    self.SpecInfo.Separator:SetAtlas("spec-dividerline", Const.TextureKit.IgnoreAtlasSize)
    self.SpecInfo.Description:SetWidth(width*0.6)
    self.SpecInfo.Description:SetText(specInfo.Description)
    self.SpecInfo.Description.bottomPadding = math.max(0, 58-self.SpecInfo.Description:GetHeight())
    
    self.SpecInfo.fixedHeight = height -188
    
    local complexity = _G["SPEC_COMPLEXITY_"..specInfo.DifficultyRating:upper()]
    if not complexity then
        C_Logger.Error("Spec: %s has no DifficultyRating!", specInfo.Spec)
        self.SpecInfo.Complexity:SetText("")
    else
        self.SpecInfo.Complexity:SetText(COMPLEXITY_COLORS[specInfo.DifficultyRating]:WrapText(complexity))
    end

    self:CreateSampleAbilities()
    self.SpecInfo:MarkDirty()
end

-- DOC: CoASpecChoiceMixin:CreateRoles
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces.
function CoASpecChoiceMixin:CreateRoles()
    local pool = self.pools:GetOrCreatePool("Frame", self.SpecInfo, "CoASpecRoleTemplate")
    
    local roles = {}
    if self.specInfo.MeleeDPS then
        tinsert(roles, "MeleeDPS")
    end
    if self.specInfo.RangedDPS then
        tinsert(roles, "RangedDPS")
    end
    if self.specInfo.CasterDPS then
        tinsert(roles, "CasterDPS")
    end
    if self.specInfo.Healer then
        tinsert(roles, "Healer")
    end
    if self.specInfo.Tank then
        tinsert(roles, "Tank")
    end
    if self.specInfo.Support then
        tinsert(roles, "Support")
    end

    local roleFrame
    for _, role in ipairs(roles) do
        roleFrame = pool:Acquire()
        roleFrame.layoutIndex = self.nextLayoutIndex()
        roleFrame:SetRole(role)
        roleFrame:Show()
    end
end

-- DOC: CoASpecChoiceMixin:CreateAdditionalInfo
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces.
function CoASpecChoiceMixin:CreateAdditionalInfo()
    self:CreatePrimaryStats()
    self:CreateArmorProficiencies()
end

function CoASpecChoiceMixin:CreatePrimaryStats()
    local pool = self.pools:GetOrCreatePool("Frame", self.SpecInfo, "CoASpecStatTemplate")
    local statButton
    for i, primaryStat in ipairs(self.specInfo.PrimaryStats) do
        statButton = pool:Acquire()
        statButton.layoutIndex = self.nextLayoutIndex()
        statButton:SetStat(primaryStat)
        statButton:Show()
    end
end

-- DOC: CoASpecChoiceMixin:CreateArmorProficiencies
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
--   - relativeTo: a piece of information passed in by the caller
-- Output: A value used by other code (self:SetVisualState(CoASpecChoiceMixin.S...).
-- What it changes: shows/hides UI pieces, uses Character Advancement API.
function CoASpecChoiceMixin:CreateArmorProficiencies(relativeTo)
    local armorTypes = {}
    if self.specInfo.Plate then
        tinsert(armorTypes, "Plate")
    end
    if self.specInfo.Mail then
        tinsert(armorTypes, "Mail")
    end
    if self.specInfo.Leather then
        tinsert(armorTypes, "Leather")
    end
    if self.specInfo.Cloth then
        tinsert(armorTypes, "Cloth")
    end

    local pool = self.pools:GetOrCreatePool("Frame", self.SpecInfo, "CoASpecArmorTemplate")
    local armorButton
    for i, armorType in ipairs(armorTypes) do
        armorButton = pool:Acquire()
        armorButton.layoutIndex = self.nextLayoutIndex()
        armorButton:SetArmorType(armorType)
        armorButton:Show()
    end
end

-- DOC: CoASpecChoiceMixin:CreateSampleAbilities
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: A value used by other code (self:SetVisualState(CoASpecChoiceMixin.S...).
-- What it changes: shows/hides UI pieces, uses Character Advancement API.
function CoASpecChoiceMixin:CreateSampleAbilities()
    local index = 1
    local pool = self.pools:GetOrCreatePool("Button", self.SampleAbilities, "CoASampleAbilityTemplate")
    local icon = pool:Acquire()
    icon:SetSpell(self.specInfo.PassiveSpell)
    icon.layoutIndex = index
    index = index + 1
    icon:Show()

    for _, spellID in ipairs(self.specInfo.ExampleSpells) do
        icon = pool:Acquire()
        icon:SetSpell(spellID)
        icon.layoutIndex = index
        index = index + 1
        icon:Show()
    end
    
    self.SampleAbilities:MarkDirty()
end

-- DOC: CoASpecChoiceMixin:UpdateVisualState
-- What this does: Update what is shown on screen so it matches the latest game data.
-- When it runs: Called whenever the screen needs to be redrawn with fresh information.
-- Inputs:
--   - self: the UI object this function belongs to
--   - isActiveSpecID: an identifier (a number/string that points to a specific thing)
-- Output: A value used by other code (self:SetVisualState(CoASpecChoiceMixin.S...).
-- What it changes: shows/hides UI pieces, changes text on screen, uses Character Advancement API.
function CoASpecChoiceMixin:UpdateVisualState(isActiveSpecID)
    if not self.specInfo then
        return self:SetVisualState(CoASpecChoiceMixin.State.Inactive)
    end

    if isActiveSpecID then
        return self:SetVisualState(CoASpecChoiceMixin.State.Active)
    end

    if not C_CharacterAdvancement.CanSwitchActiveChrSpec(self.specInfo.ID) then
        return self:SetVisualState(CoASpecChoiceMixin.State.Disabled)
    end
    
    return self:SetVisualState(CoASpecChoiceMixin.State.Inactive)
end 

-- DOC: CoASpecChoiceMixin:SetVisualState
-- What this does: Set a value on this UI element and update related visuals.
-- When it runs: Called when code needs to store a value and/or update the visuals.
-- Inputs:
--   - self: the UI object this function belongs to
--   - visualState: a piece of information passed in by the caller
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, changes text on screen.
function CoASpecChoiceMixin:SetVisualState(visualState)
    self.visualState = visualState
    self.SelectButton:SetEnabled(visualState ~= CoASpecChoiceMixin.State.Disabled)

    if visualState == CoASpecChoiceMixin.State.Inactive then
        self:SetInactiveVisual()
    elseif visualState == CoASpecChoiceMixin.State.Active then
        self:SetActiveVisual()
    elseif visualState == CoASpecChoiceMixin.State.Disabled then
        self:SetDisabledVisual()
    end
end 

-- DOC: CoASpecChoiceMixin:PlayActiveFX
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, changes text on screen.
function CoASpecChoiceMixin:PlayActiveFX()
    self.FXFrame:PlayActivateFX()

    for _, texture in ipairs(self.activatedBackground.left) do
        texture.Flash:Play()
    end

    for _, texture in ipairs(self.activatedBackground.right) do
        texture.Flash:Play()
    end
end

-- DOC: CoASpecChoiceMixin:StopActiveFX
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, changes text on screen.
function CoASpecChoiceMixin:StopActiveFX()
    self.FXFrame:StopActivateFX()

    for _, texture in ipairs(self.activatedBackground.left) do
        texture.Flash:Stop()
    end

    for _, texture in ipairs(self.activatedBackground.right) do
        texture.Flash:Stop()
    end
end

-- DOC: CoASpecChoiceMixin:SetActiveVisual
-- What this does: Set a value on this UI element and update related visuals.
-- When it runs: Called when code needs to store a value and/or update the visuals.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, changes text on screen.
function CoASpecChoiceMixin:SetActiveVisual()
    self.SelectButton:SetText(VIEW_TALENTS)
    self.SelectButton.ActiveText:Show()
    self:SetBannerStateActive(true)
    self:SetDesaturated(false)
    self:SetSelectedBackgroundState(true)
    
    self.FXFrame:PlayActivateFX()
    
    for _, texture in ipairs(self.activatedBackground.left) do
        texture.Flash:Play()
    end

    for _, texture in ipairs(self.activatedBackground.right) do
        texture.Flash:Play()
    end
end

-- DOC: CoASpecChoiceMixin:SetInactiveVisual
-- What this does: Set a value on this UI element and update related visuals.
-- When it runs: Called when code needs to store a value and/or update the visuals.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: A value used by other code (self.specInfo and self.specInfo.ID).
-- What it changes: shows/hides UI pieces, changes text on screen.
function CoASpecChoiceMixin:SetInactiveVisual()
    self.SelectButton:SetText(ACTIVATE_TALENTS)
    self.SelectButton.ActiveText:Hide()
    self:SetBannerStateActive(false)
    self:SetDesaturated(false)
    self:SetSelectedBackgroundState(false)
end

-- DOC: CoASpecChoiceMixin:SetDisabledVisual
-- What this does: Set a value on this UI element and update related visuals.
-- When it runs: Called when code needs to store a value and/or update the visuals.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: A value used by other code (self.specInfo and self.specInfo.ID).
-- What it changes: shows/hides UI pieces, changes text on screen.
function CoASpecChoiceMixin:SetDisabledVisual()
    self.SelectButton:SetText(DISABLED)
    self.SelectButton.ActiveText:Hide()
    self:SetBannerStateActive(false)
    self:SetDesaturated(true)
    self:SetSelectedBackgroundState(false)
end

-- DOC: CoASpecChoiceMixin:SetSelectedBackgroundState
-- What this does: Set a value on this UI element and update related visuals.
-- When it runs: Called when code needs to store a value and/or update the visuals.
-- Inputs:
--   - self: the UI object this function belongs to
--   - active: a piece of information passed in by the caller
-- Output: A value used by other code (self.specInfo and self.specInfo.ID).
-- What it changes: updates UI/state.
function CoASpecChoiceMixin:SetSelectedBackgroundState(active)
    FrameUtil.SetRegionsShown(self.selectedBackground.back, active)
    if self.isLeftMostSpec then
        FrameUtil.SetRegionsShown(self.selectedBackground.right, active)
    elseif self.isRightMostSpec then
        FrameUtil.SetRegionsShown(self.selectedBackground.left, active)
    else
        FrameUtil.SetRegionsShown(self.selectedBackground.left, active)
        FrameUtil.SetRegionsShown(self.selectedBackground.right, active)
    end
end

-- DOC: CoASpecChoiceMixin:SetBannerStateActive
-- What this does: Set a value on this UI element and update related visuals.
-- When it runs: Called when code needs to store a value and/or update the visuals.
-- Inputs:
--   - self: the UI object this function belongs to
--   - active: a piece of information passed in by the caller
-- Output: A value used by other code (self.specInfo and self.specInfo.ID).
-- What it changes: updates UI/state.
function CoASpecChoiceMixin:SetBannerStateActive(active)
    local borderAtlas = "spec-thumbnailborder-"..(active and "on" or "off")
    self.Banner.BorderNormal:SetAtlas(borderAtlas)
    self.Banner.BorderHover:SetAtlas(borderAtlas)
end

function CoASpecChoiceMixin:SetDesaturated(desaturate)
    self.Banner.Image:SetDesaturated(desaturate)
    self.Banner.ImageHover:SetDesaturated(desaturate)
end

-- DOC: CoASpecChoiceMixin:SetHoverStateActive
-- What this does: Set a value on this UI element and update related visuals.
-- When it runs: Called when code needs to store a value and/or update the visuals.
-- Inputs:
--   - self: the UI object this function belongs to
--   - active: a piece of information passed in by the caller
-- Output: A value used by other code (self.specInfo and self.specInfo.ID).
-- What it changes: updates UI/state.
function CoASpecChoiceMixin:SetHoverStateActive(active)
    self.HoverBackground:SetShown(active)
    self.Banner.ImageHover:SetShown(active)
    self.Banner.BorderHover:SetShown(active)
end

function CoASpecChoiceMixin:OnSelected()
    if self.visualState == CoASpecChoiceMixin.State.Inactive then
        self:GetParent():GetParent():ChangeSpecID(self.specInfo.ID)
    else
        self:GetParent():GetParent():ShowTreeView()
    end
end 

-- DOC: CoASpecChoiceMixin:GetSpecID
-- What this does: Return a value that other parts of the UI need.
-- When it runs: Called when other code needs a yes/no or a piece of information.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: A value used by other code (self.specInfo and self.specInfo.ID).
-- What it changes: updates UI/state.
function CoASpecChoiceMixin:GetSpecID()
    return self.specInfo and self.specInfo.ID
end 

function CoASpecChoiceMixin:SetDividerShown(show)
    self.ColumnDivider:SetShown(show)
end 

-- DOC: CoASpecChoiceMixin:OnEnter
-- What this does: Show a tooltip or highlight when the mouse is over this item.
-- When it runs: Runs when the mouse pointer moves over the related UI element.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: updates UI/state.
function CoASpecChoiceMixin:OnEnter()
    self:SetHoverStateActive(true)
end 

function CoASpecChoiceMixin:OnLeave()
    if not DoesAncestryInclude(self, GetMouseFocus()) then
        self:SetHoverStateActive(false)
    end
end 
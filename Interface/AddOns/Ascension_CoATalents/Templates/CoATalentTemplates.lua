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

CoATalentButtonMixin = CreateFromMixins("CATalentBaseMixin")

-- DOC: CoATalentButtonMixin:OnLoad
-- What this does: Sets up this UI element: prepares data, connects events, and sets initial visuals.
-- When it runs: Runs once when this UI element is created/loaded.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: updates UI/state.
function CoATalentButtonMixin:OnLoad()
    CATalentBaseMixin.OnLoad(self)
    self.Icon:SetBackgroundInset(-20, -20, -20, -20)
    self.Icon:SetBorderInset(-2, -2, -2, -2)
    self.Icon:SetOverlayInset(-2, -2, -2, -2)
    self.Icon:SetHighlightInset(-2, -2, -2, -2)
    self.RankFrame:ShowMaxRank(false)
end

-- DOC: CoATalentButtonMixin:SetEntry
-- What this does: Set a value on this UI element and update related visuals.
-- When it runs: Called when code needs to store a value and/or update the visuals.
-- Inputs:
--   - self: the UI object this function belongs to
--   - entry: a piece of information passed in by the caller
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: updates UI/state.
function CoATalentButtonMixin:SetEntry(entry)
    CATalentBaseMixin.SetEntry(self, entry)
end

CoATalentButtonSquareMixin = CreateFromMixins("CoATalentButtonMixin")

function CoATalentButtonSquareMixin:OnLoad()
    CoATalentButtonMixin.OnLoad(self)
    self:SetArtSet(CoACharacterAdvancementUtil.NodeArtSet.Square)
end

-- DOC: CoATalentButtonSquareMixin:SetIsSubNode
-- What this does: Set a value on this UI element and update related visuals.
-- When it runs: Called when code needs to store a value and/or update the visuals.
-- Inputs:
--   - self: the UI object this function belongs to
--   - isSubNode: a yes/no flag
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: updates UI/state.
function CoATalentButtonSquareMixin:SetIsSubNode(isSubNode)
    CoATalentButtonMixin.SetIsSubNode(self, isSubNode)
    if isSubNode then
        self.Icon:SetBackgroundInset(-20, -20, -20, -20)
        self.Icon:SetBorderInset(0, 0, 0, 0)
        self.Icon:SetOverlayInset(0, 0, 0, 0)
        self.Icon:SetHighlightInset(0, 0, 0, 0)
        self:SetArtSet(CoACharacterAdvancementUtil.NodeArtSet.LargeSquare)
    else
        self.Icon:SetBackgroundInset(-20, -20, -20, -20)
        self.Icon:SetBorderInset(-2, -2, -2, -2)
        self.Icon:SetOverlayInset(-2, -2, -2, -2)
        self.Icon:SetHighlightInset(-2, -2, -2, -2)
        self:SetArtSet(CoACharacterAdvancementUtil.NodeArtSet.Square)
    end
end

CoATalentButtonCircleMixin = CreateFromMixins("CoATalentButtonMixin")

-- DOC: CoATalentButtonCircleMixin:OnLoad
-- What this does: Sets up this UI element: prepares data, connects events, and sets initial visuals.
-- When it runs: Runs once when this UI element is created/loaded.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: updates UI/state.
function CoATalentButtonCircleMixin:OnLoad()
    CoATalentButtonMixin.OnLoad(self)
    self:SetArtSet(CoACharacterAdvancementUtil.NodeArtSet.Circle)
end

function CoATalentButtonCircleMixin:SetIsSubNode(isSubNode)
    CoATalentButtonMixin.SetIsSubNode(self, isSubNode)
    if isSubNode then
        self.Icon:SetBackgroundInset(-20, -20, -20, -20)
        self.Icon:SetBorderInset(-1, -1, -1, -1)
        self.Icon:SetOverlayInset(-1, -1, -1, -1)
        self.Icon:SetHighlightInset(-1, -1, -1, -1)
        self:SetArtSet(CoACharacterAdvancementUtil.NodeArtSet.LargeCircle)
    else
        self.Icon:SetBackgroundInset(-20, -20, -20, -20)
        self.Icon:SetBorderInset(-2, -2, -2, -2)
        self.Icon:SetOverlayInset(-2, -2, -2, -2)
        self.Icon:SetHighlightInset(-2, -2, -2, -2)
        self:SetArtSet(CoACharacterAdvancementUtil.NodeArtSet.Circle)
    end
end

CoATalentButtonHexMixin = CreateFromMixins("CoATalentButtonMixin")

-- DOC: CoATalentButtonHexMixin:OnLoad
-- What this does: Sets up this UI element: prepares data, connects events, and sets initial visuals.
-- When it runs: Runs once when this UI element is created/loaded.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: updates UI/state.
function CoATalentButtonHexMixin:OnLoad()
    CoATalentButtonMixin.OnLoad(self)
    self:SetArtSet(CoACharacterAdvancementUtil.NodeArtSet.Choice)
end

function CoATalentButtonHexMixin:SetIsSubNode(isSubNode)
    CoATalentButtonMixin.SetIsSubNode(self, isSubNode)
    if isSubNode then
        self.Icon:SetBackgroundInset(-20, -20, -20, -20)
        self.Icon:SetBorderInset(-1, -1, -1, -1)
        self.Icon:SetOverlayInset(-1, -1, -1, -1)
        self.Icon:SetHighlightInset(-1, -1, -1, -1)
        self:SetArtSet(CoACharacterAdvancementUtil.NodeArtSet.LargeCircle)
    else
        self.Icon:SetBackgroundInset(-20, -20, -20, -20)
        self.Icon:SetBorderInset(-2, -2, -2, -2)
        self.Icon:SetOverlayInset(-2, -2, -2, -2)
        self.Icon:SetHighlightInset(-2, -2, -2, -2)
        self:SetArtSet(CoACharacterAdvancementUtil.NodeArtSet.Circle)
    end
end

CoATalentButtonDiamondMixin = CreateFromMixins("CoATalentButtonMixin")

-- DOC: CoATalentButtonDiamondMixin:OnLoad
-- What this does: Sets up this UI element: prepares data, connects events, and sets initial visuals.
-- When it runs: Runs once when this UI element is created/loaded.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces, changes text on screen.
function CoATalentButtonDiamondMixin:OnLoad()
    CoATalentButtonMixin.OnLoad(self)
    self:SetArtSet(CoACharacterAdvancementUtil.NodeArtSet.Square)
end

function CoATalentButtonDiamondMixin:SetIsSubNode(isSubNode)
    CoATalentButtonMixin.SetIsSubNode(self, isSubNode)
    if isSubNode then
        self.Icon:SetBackgroundInset(-20, -20, -20, -20)
        self.Icon:SetBorderInset(-1, -1, -1, -1)
        self.Icon:SetOverlayInset(-1, -1, -1, -1)
        self.Icon:SetHighlightInset(-1, -1, -1, -1)
        self:SetArtSet(CoACharacterAdvancementUtil.NodeArtSet.LargeSquare)
    else
        self.Icon:SetBackgroundInset(-20, -20, -20, -20)
        self.Icon:SetBorderInset(-2, -2, -2, -2)
        self.Icon:SetOverlayInset(-2, -2, -2, -2)
        self.Icon:SetHighlightInset(-2, -2, -2, -2)
        self:SetArtSet(CoACharacterAdvancementUtil.NodeArtSet.LargeSquare)
    end
end

CoATalentChoiceButtonMixin = CreateFromMixins("CATalentChoiceBaseMixin")

-- DOC: CoATalentChoiceButtonMixin:OnLoad
-- What this does: Sets up this UI element: prepares data, connects events, and sets initial visuals.
-- When it runs: Runs once when this UI element is created/loaded.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (nil).
-- What it changes: shows/hides UI pieces, changes text on screen.
function CoATalentChoiceButtonMixin:OnLoad()
    CATalentChoiceBaseMixin.OnLoad(self)
    self.Icon:SetBackgroundInset(-20, -20, -20, -20)
    self.Icon:SetBorderInset(-10, -10, -7, -7)
    self.Icon:SetOverlayInset(-10, -10, -7, -7)
    self.Icon:SetHighlightInset(-10, -10, -7, -7)
    self.RankFrame:ShowMaxRank(false)
    self:SetArtSet(CoACharacterAdvancementUtil.NodeArtSet.Choice)
end

-- DOC: CoATalentChoiceButtonMixin:AddNode
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
--   - node: a piece of information passed in by the caller
-- Output: Nothing (nil).
-- What it changes: shows/hides UI pieces, changes text on screen.
function CoATalentChoiceButtonMixin:AddNode(node)
    CATalentChoiceBaseMixin.AddNode(self, node)
    node:SetSize(42, 42)
end 

--
-- Gate Template
--
CoAGateMixin = CreateFromMixins("CAGateBaseMixin")

-- DOC: CoAGateMixin:UpdateDisplay
-- What this does: Update what is shown on screen so it matches the latest game data.
-- When it runs: Called whenever the screen needs to be redrawn with fresh information.
-- Inputs:
--   - self: the UI object this function belongs to
--   - investedCurrency: a piece of information passed in by the caller
-- Output: Nothing (nil).
-- What it changes: shows/hides UI pieces, changes text on screen.
function CoAGateMixin:UpdateDisplay(investedCurrency)
    CAGateBaseMixin.UpdateDisplay(self, investedCurrency)
    local remainder = self.requiredCurrency - investedCurrency
    self.GateText:SetText(remainder)
end

function CoAGateMixin:SetLocked()
    CAGateBaseMixin.SetLocked(self)
    self.GateText:Show()
    self.LockIcon:SetAtlas("talents-gate", Const.TextureKit.IgnoreAtlasSize)
end 

-- DOC: CoAGateMixin:SetUnlocked
-- What this does: Set a value on this UI element and update related visuals.
-- When it runs: Called when code needs to store a value and/or update the visuals.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (nil).
-- What it changes: shows/hides UI pieces, changes text on screen.
function CoAGateMixin:SetUnlocked()
    CAGateBaseMixin.SetUnlocked(self)
    self.GateText:Hide()
    self.LockIcon:SetAtlas("talents-gate-open", Const.TextureKit.IgnoreAtlasSize)
end 

--
-- Spec Role Template
--
CoASpecRoleMixin = {}

-- DOC: CoASpecRoleMixin:SetRole
-- What this does: Set a value on this UI element and update related visuals.
-- When it runs: Called when code needs to store a value and/or update the visuals.
-- Inputs:
--   - self: the UI object this function belongs to
--   - role: a piece of information passed in by the caller
-- Output: Nothing (nil).
-- What it changes: changes text on screen.
function CoASpecRoleMixin:SetRole(role)
    local roleID = Enum.ClassRole[role] or role
    local name = ROLE_TEXT[roleID]
    local atlas = ROLE_ATLAS[roleID]

    if not name or not atlas then
        C_Logger.Error("Bad role provided for CoASpecRoleMixin:SetRole(%s)", tostring(role))
        return
    end

    self.Icon:SetAtlas(atlas.."-micro", Const.TextureKit.IgnoreAtlasSize)
    self.Text:SetText(name)
    self:SetWidth(self.Text:GetStringWidth())
end

--
-- Spec Stat Template
--
CoASpecStatMixin = {}

-- DOC: CoASpecStatMixin:SetStat
-- What this does: Set a value on this UI element and update related visuals.
-- When it runs: Called when code needs to store a value and/or update the visuals.
-- Inputs:
--   - self: the UI object this function belongs to
--   - stat: a piece of information passed in by the caller
-- Output: Nothing (nil).
-- What it changes: changes text on screen.
function CoASpecStatMixin:SetStat(stat)
    if not stat then
        C_Logger.Error("Bad stat provided for CoASpecStatMixin:SetStat(%s)", tostring(stat))
        return
    end

    local statID = Enum.PrimaryStat[stat] or stat
    local name = _G[PRIMARY_STAT_NAME_FORMAT:format(statID)]
    local atlas = PRIMARY_STAT_ATLAS[statID]

    if not name or not atlas then
        C_Logger.Error("Bad stat provided for CoASpecStatMixin:SetStat(%s)", tostring(stat))
        return
    end

    self.Icon:SetAtlas(atlas)
    self.Text:SetText(name)
    self:SetWidth(self.Text:GetStringWidth())
end

--
-- Spec Armor Proficiency 
--
CoASpecArmorMixin = {}

-- DOC: CoASpecArmorMixin:SetArmorType
-- What this does: Set a value on this UI element and update related visuals.
-- When it runs: Called when code needs to store a value and/or update the visuals.
-- Inputs:
--   - self: the UI object this function belongs to
--   - armorType: a piece of information passed in by the caller
-- Output: Nothing (nil).
-- What it changes: changes text on screen.
function CoASpecArmorMixin:SetArmorType(armorType)
    if not armorType then
        C_Logger.Error("Bad armor type provided for CoASpecArmorMixin:SetArmor(%s)", tostring(armorType))
        return
    end

    local armorTypeID = Enum.ClassArmorType[armorType] or armorType
    local name = ARMOR_TYPE_NAME[armorTypeID]
    local atlas = ARMOR_TYPE_ATLAS[armorTypeID]

    if not name or not atlas then
        C_Logger.Error("Bad armor type provided for CoASpecArmorMixin:SetArmor(%s)", tostring(armorType))
        return
    end

    self.Icon:SetAtlas(atlas)
    self.Text:SetText(name)
    self:SetWidth(self.Text:GetWidth())
end 

--
-- Sample Ability
--
CoASampleAbilityMixin = CreateFromMixins("SpellIconTemplateMixin")

-- DOC: CoASampleAbilityMixin:OnLoad
-- What this does: Sets up this UI element: prepares data, connects events, and sets initial visuals.
-- When it runs: Runs once when this UI element is created/loaded.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: updates UI/state.
function CoASampleAbilityMixin:OnLoad()
    SpellIconTemplateMixin.OnLoad(self)
    self:SetBorderAtlas("spec-sampleabilityring")
    self:SetBorderSize(50, 48)
    self:SetRounded(true)
end

function CoASampleAbilityMixin:OnEnter()
    SpellIconTemplateMixin.OnEnter(self)
    FrameUtil.PassOnEnterToParent(self)
end

-- DOC: CoASampleAbilityMixin:OnLeave
-- What this does: Hide the tooltip/highlight when the mouse leaves this item.
-- When it runs: Runs when the mouse pointer leaves the related UI element.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: updates UI/state.
function CoASampleAbilityMixin:OnLeave()
    SpellIconTemplateMixin.OnLeave(self)
    FrameUtil.PassOnLeaveToParent(self)
end 

--
-- Spec Choice FX
--

CoASpecChoiceFXMixin = {}

-- DOC: CoASpecChoiceFXMixin:OnLoad
-- What this does: Sets up this UI element: prepares data, connects events, and sets initial visuals.
-- When it runs: Runs once when this UI element is created/loaded.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: updates UI/state.
function CoASpecChoiceFXMixin:OnLoad()
    UseParentLevel(self)
    self.Child:SetSize(self:GetSize())
    
    self.Child.ActivationFX:SetAtlas("talents-animations-gridburst", Const.TextureKit.IgnoreAtlasSize)
end

function CoASpecChoiceFXMixin:OnSizeChanged(width, height)
    self.Child:SetSize(width, height)
end 

-- DOC: CoASpecChoiceFXMixin:PlayActivateFX
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Called after this UI registers for events, or when something changes that needs a refresh.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: listens for game events.
function CoASpecChoiceFXMixin:PlayActivateFX()
    self.Child.ActivationFX.Flash:Play()
end

function CoASpecChoiceFXMixin:StopActivateFX()
    self.Child.ActivationFX.Flash:Stop()
end 

--
-- Tree FX
--
CoATreeFXMixin = {}

-- DOC: CoATreeFXMixin:OnLoad
-- What this does: Sets up this UI element: prepares data, connects events, and sets initial visuals.
-- When it runs: Runs once when this UI element is created/loaded.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: A value used by other code (self:GetScrollList():GetParent()).
-- What it changes: listens for game events.
function CoATreeFXMixin:OnLoad()
    UseParentLevel(self)
    self.Child:SetSize(self:GetSize())
    
    self.Child.Clouds1:SetAtlas("talents-animations-clouds", Const.TextureKit.IgnoreAtlasSize)
    self.Child.Clouds2:SetAtlas("talents-animations-clouds", Const.TextureKit.IgnoreAtlasSize)
    self.Child.AirParticlesClose:SetAtlas("talents-animations-particles", Const.TextureKit.UseAtlasSize)
    self.Child.AirParticlesFar:SetAtlas("talents-animations-particles", Const.TextureKit.UseAtlasSize)
    self.Child.AirParticlesFar:FlipX()
end

-- DOC: CoATreeFXMixin:OnSizeChanged
-- What this does: Show part of the UI (or switch which panel is visible).
-- When it runs: Runs for a UI callback named OnSizeChanged.
-- Inputs:
--   - self: the UI object this function belongs to
--   - width: a piece of information passed in by the caller
--   - height: a piece of information passed in by the caller
-- Output: A value used by other code (self:GetScrollList():GetParent()).
-- What it changes: changes text on screen, listens for game events.
function CoATreeFXMixin:OnSizeChanged(width, height)
    self.Child:SetSize(width, height)
end 

function CoATreeFXMixin:OnShow()
    self.Child.Clouds1.Anim:Play()
    self.Child.Clouds2.Anim:Play()
    self.Child.AirParticlesClose.Anim:Play()
    self.Child.AirParticlesFar.Anim:Play()
end 

-- DOC: CoATreeFXMixin:OnHide
-- What this does: Cleans up when the UI closes (stops updates and hides extra popups).
-- When it runs: Runs when this UI element is hidden.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: A value used by other code (self:GetScrollList():GetParent()).
-- What it changes: changes text on screen, listens for game events.
function CoATreeFXMixin:OnHide()
    self.Child.Clouds1.Anim:Stop()
    self.Child.Clouds2.Anim:Stop()
    self.Child.AirParticlesClose.Anim:Stop()
    self.Child.AirParticlesFar.Anim:Stop()
end 

--
-- CoA Build Item 
--
CoATalentBuildScrollItemMixin = CreateFromMixins("ScrollListItemBaseMixin")

-- DOC: CoATalentBuildScrollItemMixin:OnLoad
-- What this does: Sets up this UI element: prepares data, connects events, and sets initial visuals.
-- When it runs: Runs once when this UI element is created/loaded.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: A value used by other code (self:GetScrollList():GetParent()).
-- What it changes: changes text on screen, listens for game events.
function CoATalentBuildScrollItemMixin:OnLoad()
    self.Background:SetVertexColor(0.5, 0.5, 0.5)
    self.Background:SetAtlas("buildcreator-class-header", Const.TextureKit.IgnoreAtlasSize)
    self.Role:SetBackgroundTexture("Interface\\LFGFrame\\UI-LFG-ICONS-ROLEBACKGROUNDS")
    self.Role:SetBackgroundSize(48, 48)
    self.Role:SetBackgroundAlpha(0.6)

    self.Icon:SetRounded(true)
    self.Icon:SetBorderSize(48, 48)
    self.Icon:SetBorderOffset(0, -1)
    self.Icon:SetBorderAtlas("build-draft-border")
    self:RegisterEvent("BUILD_CREATOR_RATE_RESULT")
end

-- DOC: CoATalentBuildScrollItemMixin:GetBuildListParent
-- What this does: Return a value that other parts of the UI need.
-- When it runs: Called when other code needs a yes/no or a piece of information.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: A value used by other code (self:GetScrollList():GetParent()).
-- What it changes: changes text on screen.
function CoATalentBuildScrollItemMixin:GetBuildListParent()
    return self:GetScrollList():GetParent()
end

function CoATalentBuildScrollItemMixin:Update()
    self.data = C_BuildCreator.GetBuildAtIndex(self.index)

    if not self.data then
        return
    end

    local name = CoACharacterAdvancementUtil.StripArchitectTag(self.data.Name)

    self.tooltipTitle = name
    self.tooltipText = self.data.Subtext.."\n"..self.data.Description

    local text = name
    self.Text:SetText(name)
    self.Icon:SetIcon("Interface\\Icons\\"..self.data.Icon)

    if BuildCreatorUtil.IsActiveBuildID(self.data.ID) then
        text = text .. "|cff00FF00("..ACTIVE..")"
        self.Text:SetText(text)
    end

    -- role update
    local role = BuildCreatorUtil.ConvertBuildRoleToLFGRole(self.data.Roles)
    self.Role:SetIconAtlas(ROLE_ATLAS[role])
    self.Role.Background:SetTexCoord(GetBackgroundTexCoordsForRole(role))
    self.Role.tooltipTitle = BUILD_CREATOR_ROLE_S:format(_G[role])
    self.Role.tooltipText = _G["BUILD_CREATOR_ROLE_"..role]
    if GameTooltip:IsOwned(self.Role) then
        self.Role:CallScript("OnEnter")
    end

    self:UpdateRating()
end

-- DOC: CoATalentBuildScrollItemMixin:UpdateRating
-- What this does: Update what is shown on screen so it matches the latest game data.
-- When it runs: Called whenever the screen needs to be redrawn with fresh information.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces.
function CoATalentBuildScrollItemMixin:UpdateRating()
    -- rating update
    local rating = self.data.Upvotes or 0
    rating = ITEM_QUALITY_COLORS[Enum.ItemQuality.Uncommon]:WrapText(rating)
    self.RatingText:SetFormattedText(BUILD_RATING_S, rating)
    self.LikeButton:SetChecked(C_BuildCreator.IsUpvotedBuild(self.data.ID))
    if self.LikeButton:GetBoolValue() then
        self.LikeButton:LockHighlight()
    else
        self.LikeButton:UnlockHighlight()
    end
end

-- DOC: CoATalentBuildScrollItemMixin:OnSelected
-- What this does: Hide part of the UI (or close a popup).
-- When it runs: Runs for a UI callback named OnSelected.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces.
function CoATalentBuildScrollItemMixin:OnSelected()
    self:GetBuildListParent():SelectBuild(self.data and self.data.ID)
end

function CoATalentBuildScrollItemMixin:LikeBuild()
    if C_BuildCreator.IsUpvotedBuild(self.data.ID) then
        PlaySound(SOUNDKIT.UCHATSCROLLBUTTON_70)
        C_BuildCreator.RateBuild(self.data.ID, false)
    else
        C_BuildCreator.RateBuild(self.data.ID, true)
        PlaySound(SOUNDKIT.UCHATSCROLLBUTTON)
    end
end

-- DOC: CoATalentBuildScrollItemMixin:OnEnter
-- What this does: Show a tooltip or highlight when the mouse is over this item.
-- When it runs: Runs when the mouse pointer moves over the related UI element.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: shows/hides UI pieces.
function CoATalentBuildScrollItemMixin:OnEnter()
    GameTooltip_GenericTooltip(self)
end

function CoATalentBuildScrollItemMixin:OnLeave()
    GameTooltip:Hide()
end

-- DOC: CoATalentBuildScrollItemMixin:BUILD_CREATOR_RATE_RESULT
-- What this does: Do a specific piece of work related to 'BUILD_CREATOR_RATE_RESULT'.
-- When it runs: Called by other code when needed.
-- Inputs:
--   - self: the UI object this function belongs to
--   - result: a piece of information passed in by the caller
--   - buildID: an identifier (a number/string that points to a specific thing)
--   - rating: a piece of information passed in by the caller
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: updates UI/state.
function CoATalentBuildScrollItemMixin:BUILD_CREATOR_RATE_RESULT(result, buildID, rating)
    self.LikeButton:Enable()
    if self.data and self.data.ID == buildID then
        self.data.Upvotes = rating
        self:UpdateRating()
    end
end 
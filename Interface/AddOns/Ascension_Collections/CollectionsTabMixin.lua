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

CollectionsTabMixin = CreateFromMixins(TabSystemTabMixin)

-- DOC: CollectionsTabMixin:OnLoad
-- What this does: Sets up this UI element: prepares data, connects events, and sets initial visuals.
-- When it runs: Runs once when this UI element is created/loaded.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: changes text on screen.
function CollectionsTabMixin:OnLoad()
	self:SetTextPadding(26)
	self.Icon:SetBorderTexture("Interface\\common\\WhiteIconFrame")
	self.Icon:SetBorderColor(GRAY_FONT_COLOR:GetRGB())
end

function CollectionsTabMixin:SetIcon(icon)
	self.Icon:SetIcon(icon)
end

-- DOC: CollectionsTabMixin:OnMouseDown
-- What this does: Hide part of the UI (or close a popup).
-- When it runs: Runs for a UI callback named OnMouseDown.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: updates UI/state.
function CollectionsTabMixin:OnMouseDown()
	self.Icon:SetPointOffset(0, -1)
end 

function CollectionsTabMixin:OnMouseUp()
	self.Icon:SetPointOffset(0, 0)
end

-- DOC: CollectionsTabMixin:OnHide
-- What this does: Cleans up when the UI closes (stops updates and hides extra popups).
-- When it runs: Runs when this UI element is hidden.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: updates UI/state.
function CollectionsTabMixin:OnHide()
	self.Icon:SetPointOffset(0, 0)
end

function CollectionsTabMixin:OnSelected()
	self.Icon:SetBorderColor(YELLOW_FONT_COLOR:GetRGB())
end

-- DOC: CollectionsTabMixin:OnDeselected
-- What this does: Do a specific piece of work related to 'OnDeselected'.
-- When it runs: Runs for a UI callback named OnDeselected.
-- Inputs:
--   - self: the UI object this function belongs to
-- Output: Nothing (it mainly updates state and/or the UI).
-- What it changes: updates UI/state.
function CollectionsTabMixin:OnDeselected()
	self.Icon:SetBorderColor(GRAY_FONT_COLOR:GetRGB())
end 
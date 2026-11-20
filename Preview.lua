local _, ns = ...
local L = ns.L;

--[[
	Preview nameplate for the settings panel.

	Uses a private instance of Blizzard's nameplate unit frame that is NOT registered with Blizzard's
	nameplate driver and has NO unit. Blizzard's layout code (ApplyFrameOptions/UpdateAnchors, plus
	our hooks) arranges it exactly like a real nameplate, but all content (name, health, level,
	cast) is fake data set here.

	Why no unit: health values of real units are "secret values" for addon code. Running Blizzard's
	unit update code from the addon makes it compare secret numbers, which errors. Without a unit,
	no secret values are ever involved.
]]

local CAST_TIME = 3;
local CAST_INTERVAL = CAST_TIME + 1;
local CAST_ICON = "Interface\\Icons\\Spell_Shadow_ShadowBolt";
local MAX_HEALTH = 24500;
local ELITE_ATLAS = "nameplates-icon-elite-gold";

local HOSTILE_COLOR = CreateColor(1.0, 0.0, 0.0);
local NEUTRAL_COLOR = CreateColor(1.0, 1.0, 0.0);
local FRIENDLY_PLAYER_COLOR = CreateColor(0.667, 0.667, 1.0);
local WHITE = CreateColor(1.0, 1.0, 1.0);

-- Index = value of the "previewType" setting. Level colors are looked up lazily (global names).
ns.PREVIEWS = {
	{ label = L.PREVIEW_ENEMY_NPC, name = L.PREVIEW_NAME_ENEMY_NPC, isPlayer = false, isFriend = false, isTarget = true,
	  classification = "elite", color = HOSTILE_COLOR, health = 0.72, level = 62, levelColor = "DIFFICULT_DIFFICULTY_COLOR", cast = true },
	{ label = L.PREVIEW_ENEMY_PLAYER, name = L.PREVIEW_NAME_ENEMY_PLAYER, isPlayer = true, isFriend = false, isTarget = true,
	  class = "MAGE", health = 0.45, level = 60, levelColor = "FAIR_DIFFICULTY_COLOR", cast = true },
	{ label = L.PREVIEW_NEUTRAL_NPC, name = L.PREVIEW_NAME_NEUTRAL_NPC, isPlayer = false, isFriend = false,
	  color = NEUTRAL_COLOR, health = 1.0, level = 54, levelColor = "EASY_DIFFICULTY_COLOR" },
	{ label = L.PREVIEW_FRIENDLY_PLAYER, name = L.PREVIEW_NAME_FRIENDLY_PLAYER, isPlayer = true, isFriend = true,
	  class = "PALADIN", health = 1.0, level = 60, levelColor = "UNIT_LEVEL_NON_ATTACKABLE" },
};

local function GetDefinition()
	return ns.PREVIEWS[ns.Round(ns.GetOption("previewType"))] or ns.PREVIEWS[1];
end

local function GetClassColor(definition)
	return definition.class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[definition.class];
end

-- Respects the class color options of Blizzard's nameplate settings.
local function GetHealthColor(definition)
	if definition.class then
		local cvar = definition.isFriend and "nameplateShowFriendlyClassColor" or "nameplateShowClassColor";
		local classColor = GetClassColor(definition);
		if classColor and GetCVarBool(cvar) then
			return classColor;
		end
		return definition.isFriend and FRIENDLY_PLAYER_COLOR or HOSTILE_COLOR;
	end
	return definition.color or HOSTILE_COLOR;
end

local function GetFrameOptions(definition)
	return definition.isFriend and NamePlateFriendlyFrameOptions or NamePlateEnemyFrameOptions;
end

-- Safety net: if any Blizzard code path asks the frame to update its name, keep the fake name
-- instead of looking up a unit.
local function PreviewUpdateNameOverride(unitFrame)
	local name = unitFrame.name;
	name:SetText(GetDefinition().name);
	return true;
end

EasyDefaultPlatesPreviewMixin = {};

function EasyDefaultPlatesPreviewMixin:EnsureSetUp()
	local base = self.NamePlate;
	if base.isPreviewSetUp then
		return true;
	end

	if not NamePlateSetupOptions or not NamePlateEnemyFrameOptions then
		return false;
	end

	local unitFrame = CreateFrame("Button", nil, base, "NamePlateUnitFrameTemplate");
	unitFrame:SetAllPoints(base);
	unitFrame:SetNamePlateFrame(base);
	unitFrame.UpdateNameOverride = PreviewUpdateNameOverride;

	-- This frame never gets a unit; everything is driven from here.
	unitFrame:UnregisterAllEvents();
	unitFrame.CastBarsContainer.castBar:UnregisterAllEvents();
	unitFrame.ClassificationFrame:UnregisterAllEvents();
	unitFrame.AurasFrame:UnregisterAllEvents();
	unitFrame.AurasFrame:SetActive(false);

	ns.SetupUnitFrame(unitFrame);

	base.UnitFrame = unitFrame;
	base.isPreviewSetUp = true;
	return true;
end

function EasyDefaultPlatesPreviewMixin:GetUnitFrame()
	local base = self.NamePlate;
	if base and base.isPreviewSetUp and self:IsVisible() then
		return base.UnitFrame;
	end
end

function EasyDefaultPlatesPreviewMixin:OnShow()
	if not self:EnsureSetUp() then
		self.Label:SetText(L.PREVIEW_UNAVAILABLE);
		return;
	end

	ns.activePreview = self;
	self:Refresh();

	if self.castTicker then
		self.castTicker:Cancel();
	end
	self.castTicker = C_Timer.NewTicker(CAST_INTERVAL, function()
		self:UpdateCast();
	end);
end

function EasyDefaultPlatesPreviewMixin:OnHide()
	if self.castTicker then
		self.castTicker:Cancel();
		self.castTicker = nil;
	end

	if ns.activePreview == self then
		ns.activePreview = nil;
	end

	local base = self.NamePlate;
	if base.isPreviewSetUp then
		base.UnitFrame.CastBarsContainer.castBar:UpdateShownState(false);
	end
end

-- Sizes the preview like a real nameplate, scaled down only if it doesn't fit into the panel.
function EasyDefaultPlatesPreviewMixin:UpdateSize()
	local base = self.NamePlate;
	local width, height = C_NamePlate.GetNamePlateSize();
	if not base or not width or width <= 0 or not height or height <= 0 then
		return;
	end

	base:SetSize(width, height);

	local scale = 1;
	local availableWidth = self:GetWidth() - 80;
	local availableHeight = self:GetHeight() - 40;
	if availableWidth > 0 and width > availableWidth then
		scale = availableWidth / width;
	end
	if availableHeight > 0 and height * scale > availableHeight then
		scale = availableHeight / height;
	end
	base:SetScale(scale);
end

function EasyDefaultPlatesPreviewMixin:Refresh()
	local base = self.NamePlate;
	if not base.isPreviewSetUp then
		return;
	end

	local definition = GetDefinition();
	local unitFrame = base.UnitFrame;
	local options = GetFrameOptions(definition);

	self:UpdateSize();

	-- Unit type state, normally derived from the unit (UpdateIsPlayer/UpdateIsFriend).
	unitFrame.isPlayer = definition.isPlayer;
	unitFrame.isFriend = definition.isFriend;
	unitFrame:UpdateShowOnlyName();
	self:UpdateCastBarDisplay();

	-- Blizzard's layout for the current style and size. Our UpdateAnchors hook applies the tweaks.
	unitFrame:ApplyFrameOptions(NamePlateSetupOptions, options);

	self:UpdateHealth(definition);
	self:UpdateName(definition, options);
	self:UpdateLevel(definition, options);
	self:UpdateClassification(definition, options);
	self:UpdateCast();
	self:HideUnitOnlyElements();

	self.Label:SetText(L.PREVIEW_LABEL:format(definition.label));
end

-- Template elements that start out visible and are normally hidden by unit-driven Blizzard code
-- (threat, behind-camera arrow, heal prediction/absorbs, soft target, raid icon, auras).
local UNIT_ONLY_ELEMENT_KEYS = {
	"aggroHighlight", "aggroHighlightBase", "aggroHighlightAdditive", "aggroHighlightMask", "aggroFlash",
	"behindCameraIcon",
	"myHealPrediction", "otherHealPrediction", "totalAbsorb", "totalAbsorbOverlay", "overAbsorbGlow",
	"myHealAbsorb", "myHealAbsorbLeftShadow", "myHealAbsorbRightShadow", "overHealAbsorbGlow",
	"SoftTargetFrame", "RaidTargetFrame", "AurasFrame",
};

function EasyDefaultPlatesPreviewMixin:HideUnitOnlyElements()
	local unitFrame = self.NamePlate.UnitFrame;
	for _, key in ipairs(UNIT_ONLY_ELEMENT_KEYS) do
		local element = unitFrame[key];
		if element then
			element:Hide();
		end
	end

	if unitFrame.AggroHighlightScrollAnim then
		unitFrame.AggroHighlightScrollAnim:Stop();
	end
end

function EasyDefaultPlatesPreviewMixin:UpdateHealth(definition)
	local unitFrame = self.NamePlate.UnitFrame;
	local healthBar = unitFrame.HealthBarsContainer.healthBar;
	local color = GetHealthColor(definition);

	healthBar:SetMinMaxValues(0, MAX_HEALTH);
	healthBar:SetValue(MAX_HEALTH * definition.health);
	healthBar:SetStatusBarColor(color.r, color.g, color.b);
	healthBar:UpdateShownState();

	-- Shows the target border, so the border options are visible in the preview.
	healthBar:SetIsTarget(definition.isTarget == true);
	unitFrame.PlayerLevelDiffFrame:SetIsTarget(definition.isTarget == true);
end

function EasyDefaultPlatesPreviewMixin:UpdateName(definition, options)
	local unitFrame = self.NamePlate.UnitFrame;
	local name = unitFrame.name;
	name:SetText(definition.name);

	local color = WHITE;
	local classColor = GetClassColor(definition);
	if definition.isPlayer and definition.isFriend and classColor
		and CVarCallbackRegistry:GetCVarValueBool(NamePlateConstants.USE_CLASS_COLOR_FOR_FRIENDLY_PLAYER_UNIT_NAMES_CVAR) then
		color = classColor;
	elseif options.colorNameBySelection then
		color = GetHealthColor(definition);
	end
	name:SetVertexColor(color.r, color.g, color.b);
	name:Show();

	unitFrame.HealthBarsContainer.healthBar:UpdateTextDisplay();
end

function EasyDefaultPlatesPreviewMixin:UpdateLevel(definition, options)
	local unitFrame = self.NamePlate.UnitFrame;
	local showLevel = definition.level ~= nil and not unitFrame:IsShowOnlyName();
	local color = _G[definition.levelColor] or WHITE;
	local levelText = color:WrapTextInColorCode(tostring(definition.level));

	-- Forever's level box next to the health bar.
	local levelDiffFrame = unitFrame.PlayerLevelDiffFrame;
	if levelDiffFrame and levelDiffFrame.playerLevelDiffText then
		if showLevel then
			levelDiffFrame.playerLevelDiffText:SetText(levelText);
			levelDiffFrame.playerLevelDiffText:Show();
			if levelDiffFrame.highLevelTexture then
				levelDiffFrame.highLevelTexture:Hide();
			end
		end
		levelDiffFrame:SetShown(showLevel);
	end

	-- Level inside the border of the Classic style.
	local levelFrame = unitFrame.LevelFrame;
	if levelFrame and levelFrame.LevelText then
		local showClassicLevel = showLevel and options.showLevel;
		if showClassicLevel then
			levelFrame.LevelText:SetText(levelText);
		end
		levelFrame:SetShown(showClassicLevel);
	end
end

function EasyDefaultPlatesPreviewMixin:UpdateClassification(definition, options)
	local unitFrame = self.NamePlate.UnitFrame;
	local classificationFrame = unitFrame.ClassificationFrame;
	classificationFrame:SetOptions(options);

	local showElite = definition.classification == "elite"
		and not unitFrame:IsShowOnlyName()
		and classificationFrame:ShouldShowPvEClassificationIndicator();
	if showElite then
		classificationFrame.classificationIndicator:SetAtlas(ELITE_ATLAS);
	end
	classificationFrame:SetShown(showElite);
end

-- Same as NamePlateUnitFrameMixin:UpdateCastBarDisplay, minus SetHighlightWhenCastTarget: that one
-- calls PlayerIsSpellTarget(unit), which fails without a unit.
function EasyDefaultPlatesPreviewMixin:UpdateCastBarDisplay()
	local castBar = self.NamePlate.UnitFrame.CastBarsContainer.castBar;
	local function IsShown(enumValue)
		return CVarCallbackRegistry:GetCVarBitfieldIndex(NamePlateConstants.CAST_BAR_DISPLAY_CVAR, enumValue);
	end

	castBar:SetNameTextShown(IsShown(Enum.NamePlateCastBarDisplay.SpellName));
	castBar:SetIconShown(IsShown(Enum.NamePlateCastBarDisplay.SpellIcon));
	castBar:SetTargetNameTextShown(IsShown(Enum.NamePlateCastBarDisplay.SpellTarget));
	castBar:SetHighlightImportantCasts(IsShown(Enum.NamePlateCastBarDisplay.HighlightImportantCasts));
end

-- Loops a simulated cast while the preview is visible.
function EasyDefaultPlatesPreviewMixin:UpdateCast()
	local unitFrame = self:GetUnitFrame();
	local castBar = unitFrame and unitFrame.CastBarsContainer and unitFrame.CastBarsContainer.castBar;
	if not castBar or not castBar.SimulateCast then
		return;
	end

	local showCast = GetDefinition().cast
		and GameRulesUtil.ShouldShowNamePlateCastBar()
		and not unitFrame:IsShowOnlyName();

	if showCast then
		castBar:SimulateCast({
			barType = "standard",
			iconTexture = CAST_ICON,
			spellName = L.PREVIEW_SPELL,
			targetName = UnitName("player"),
			isImportantSpell = false,
			isSpellTarget = false,
			castTime = CAST_TIME,
		});
	else
		castBar:UpdateShownState(false);
	end
end

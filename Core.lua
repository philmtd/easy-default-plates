local addonName, ns = ...

--[[
	Easy Default Plates

	Design rules:
	- Never write to Blizzard tables/fields and never call Blizzard nameplate update functions.
	  Everything happens in post-hooks (hooksecurefunc) that only touch widgets,
	  so Blizzard's own nameplate code stays untainted.
	- Never measure nameplate regions (GetPoint/GetWidth/...): the client forbids it for addons.
	- Nothing is persisted outside our own SavedVariables (no CVars are changed), so disabling
	  the addon restores the stock nameplates on the next login/reload.
	- Every tweak has a default value that means "leave Blizzard's value alone". A feature only
	  starts touching widgets once it was set to a non-default value during this session.
]]

local DB_VERSION = 1;

ns.defaults = {
	plateWidth = 100,           -- Percent of Blizzard's nameplate width.
	nameFontSize = 0,           -- 0 = Blizzard default.
	healthFontSize = 0,         -- 0 = Blizzard default.
	castFontSize = 0,           -- 0 = Blizzard default.
	levelFontSize = 0,          -- 0 = Blizzard default.
	nameWidth = 0,              -- Percent of health bar width, 0 = Blizzard default (automatic).
	castIconSize = 0,           -- 0 = Blizzard default.
	whiteTargetBorder = false,  -- Use the white target border of Classic Anniversary instead of the yellow one.
	previewType = 1,            -- Which preview the settings panel shows (see Preview.lua).
};

-- Which feature a setting belongs to. Features are "touched" once they deviate from the default.
local FEATURE_OF_KEY = {
	nameFontSize = "fonts",
	healthFontSize = "fonts",
	castFontSize = "fonts",
	levelFontSize = "fonts",
	nameWidth = "nameWidth",
	castIconSize = "castIcon",
	whiteTargetBorder = "targetBorder",
};

-- Values of the Classic Anniversary client (Blizzard_NamePlateConstants.lua, build 2.5.6) where
-- Forever's "Camelot" overrides differ.
ns.ANNIVERSARY = {
	NAME_PLATE_WIDTH = 230,
	HEALTH_BAR_FONT_HEIGHT = 12,
	CAST_BAR_ICON_HEIGHT = 12,
	CLASSIC_CAST_BAR_ICON_HEIGHT = 14,
	SELECTED_BORDER_ATLAS = "UI-HUD-Nameplates-Selected",
	SELECTED_BORDER_OFFSETS = { topLeftX = -1, topLeftY = 1, bottomRightX = -3, bottomRightY = 3 },
};

local hookedUnitFrames = setmetatable({}, { __mode = "k" });
local touched = {};

local blizzardWidth, blizzardHeight;
local widthOverridden = false;
local widthPendingAfterCombat = false;

local function Round(value)
	return math.floor(value + 0.5);
end
ns.Round = Round;

local function GetOption(key)
	local default = ns.defaults[key];
	local value = ns.db and ns.db[key];
	if value == nil or type(value) ~= type(default) then
		return default;
	end
	return value;
end
ns.GetOption = GetOption;

local function IsDefault(key)
	local value, default = GetOption(key), ns.defaults[key];
	if type(value) == "number" then
		return Round(value) == default;
	end
	return value == default;
end

local function Print(message)
	print("|cff33ff99" .. ns.L.TITLE .. "|r: " .. message);
end
ns.Print = Print;

-- Blizzard's current values (read only). Used for "Default" and for the settings tooltips.
function ns.GetBlizzardFontSize(key)
	local options = NamePlateSetupOptions;
	if not options then
		return nil;
	end

	if key == "nameFontSize" or key == "healthFontSize" then
		return options.healthBarFontHeight;
	elseif key == "castFontSize" then
		return options.castBarFontHeight;
	elseif key == "levelFontSize" then
		return options.levelFontHeight;
	elseif key == "castIconSize" then
		return options.castIconHeight;
	end
end

function ns.GetBlizzardPlateWidth()
	return blizzardWidth;
end

local function ResolveSize(key)
	local custom = Round(GetOption(key));
	if custom > 0 then
		return custom;
	end
	return ns.GetBlizzardFontSize(key);
end

local function SetFontStringSize(fontString, size)
	if fontString and size and size > 0 then
		fontString:SetTextHeight(size);
	end
end

---------------------------------------------------------------------------------------------------
-- Fonts
---------------------------------------------------------------------------------------------------

local function ApplyFonts(unitFrame)
	if not touched.fonts then
		return;
	end

	SetFontStringSize(unitFrame.name, ResolveSize("nameFontSize"));

	local healthBar = unitFrame.HealthBarsContainer and unitFrame.HealthBarsContainer.healthBar;
	if healthBar then
		local size = ResolveSize("healthFontSize");
		SetFontStringSize(healthBar.Text, size);
		SetFontStringSize(healthBar.LeftText, size);
		SetFontStringSize(healthBar.RightText, size);
	end

	local castBar = unitFrame.CastBarsContainer and unitFrame.CastBarsContainer.castBar;
	if castBar then
		local size = ResolveSize("castFontSize");
		SetFontStringSize(castBar.Text, size);
		SetFontStringSize(castBar.CastTargetNameText, size);
	end

	local levelSize = ResolveSize("levelFontSize");
	if unitFrame.PlayerLevelDiffFrame then
		SetFontStringSize(unitFrame.PlayerLevelDiffFrame.playerLevelDiffText, levelSize);
	end
	if unitFrame.LevelFrame then
		SetFontStringSize(unitFrame.LevelFrame.LevelText, levelSize);
	end
end

---------------------------------------------------------------------------------------------------
-- Name width
---------------------------------------------------------------------------------------------------

--[[
	The client forbids addons from measuring nameplate regions (GetPoint, GetWidth, ... fail with
	"Can't measure restricted regions"). So nothing here reads anchors or sizes from the frames:
	- The health bar width is derived from the nameplate size, the same way Blizzard lays it out.
	- "Auto" restores the RIGHT anchor exactly as Blizzard's NamePlateUnitFrameMixin:UpdateAnchors sets it.
]]

local function GetNameAnchorStyle()
	local options = NamePlateSetupOptions;
	local styles = NamePlateConstants and NamePlateConstants.NAME_ANCHOR_STYLES;
	if not options or not styles then
		return nil;
	end

	if options.unitNameAnchorStyle == styles.InsideHealthBar then
		return "inside";
	elseif options.unitNameAnchorStyle == styles.AboveHealthBar then
		return "above";
	end
	return nil; -- CenteredAboveHealthBar (Classic style): name has no right edge to limit.
end

local function IsShowOnlyName(unitFrame)
	return unitFrame.IsShowOnlyName and unitFrame:IsShowOnlyName();
end

-- Width of HealthBarsContainer: it spans the nameplate minus Blizzard's horizontal inset on both sides.
-- (In Forever the level indicator sits outside the bar, so it doesn't shrink the bar.)
local function GetHealthBarWidth()
	local plateWidth = C_NamePlate.GetNamePlateSize();
	local inset = NamePlateSetupOptions and NamePlateSetupOptions.insetWidth or 0;
	if not plateWidth then
		return 0;
	end
	return plateWidth - 2 * inset;
end

local function ApplyNameWidth(unitFrame)
	if not touched.nameWidth then
		return;
	end

	local style = GetNameAnchorStyle();
	if not style or IsShowOnlyName(unitFrame) then
		return; -- Blizzard anchors the name differently here; nothing to limit.
	end

	local name = unitFrame.name;
	local container = unitFrame.HealthBarsContainer;
	local percent = Round(GetOption("nameWidth"));

	if percent > 0 then
		local width = GetHealthBarWidth();
		if width > 0 then
			name:SetPoint("RIGHT", container, "LEFT", width * percent / 100, 0);
		end
		return;
	end

	-- Back to Blizzard's anchor.
	local healthBarText = container.healthBar.Text;
	if style == "inside" then
		name:SetPoint("RIGHT", healthBarText, "LEFT", -2, 0);
	elseif NamePlateSetupOptions.healthTextInsideBarWhenNameAboveHealthBar then
		name:SetPoint("RIGHT", container, "RIGHT", 0, 0);
	else
		name:SetPoint("RIGHT", healthBarText, "LEFT", -2, 0);
	end
end

---------------------------------------------------------------------------------------------------
-- Cast bar icon
---------------------------------------------------------------------------------------------------

local function ApplyCastIcon(unitFrame)
	if not touched.castIcon then
		return;
	end

	local options = NamePlateSetupOptions;
	local container = unitFrame.CastBarsContainer;
	local castBar = container and container.castBar;
	if not options or not castBar or not castBar.Icon then
		return;
	end

	local size = Round(GetOption("castIconSize"));
	local width, height = options.castIconWidth, options.castIconHeight;
	if size > 0 then
		width, height = size, size;
	end

	castBar.Icon:SetSize(width, height);

	-- Mirrors NamePlateUnitFrameMixin:ApplyFrameOptions: when the spell name sits below the bar,
	-- the icon height is part of the cast bar area.
	if options.spellNameInsideCastBar then
		container:SetHeight(options.castBarHeight);
	else
		container:SetHeight(options.castBarHeight + height);
	end
end

---------------------------------------------------------------------------------------------------
-- Target border
---------------------------------------------------------------------------------------------------

local function ApplyTargetBorder(unitFrame)
	if not touched.targetBorder or not NamePlateConstants then
		return;
	end

	local white = GetOption("whiteTargetBorder");

	-- Health bar: swap Forever's yellow border for Classic Anniversary's white one.
	local healthBar = unitFrame.HealthBarsContainer and unitFrame.HealthBarsContainer.healthBar;
	local border = healthBar and healthBar.selectedBorder;
	local background = healthBar and healthBar.bgTexture;
	if border and background then
		local atlas, offsets;
		if white then
			atlas, offsets = ns.ANNIVERSARY.SELECTED_BORDER_ATLAS, ns.ANNIVERSARY.SELECTED_BORDER_OFFSETS;
		else
			atlas, offsets = NamePlateConstants.SELECTED_BORDER_ATLAS, NamePlateConstants.SELECTED_BORDER_OFFSETS;
		end

		border:SetAtlas(atlas, TextureKitConstants.IgnoreAtlasSize);
		border:SetPoint("TOPLEFT", background, "TOPLEFT", offsets.topLeftX, offsets.topLeftY);
		border:SetPoint("BOTTOMRIGHT", background, "BOTTOMRIGHT", offsets.bottomRightX, offsets.bottomRightY);
	end

	-- Level indicator: its border image is painted yellow and has no white counterpart, so it is
	-- desaturated instead. Blizzard's tint (white for target, orange for focus) still applies on top.
	local levelFrame = unitFrame.PlayerLevelDiffFrame;
	if levelFrame and levelFrame.selectedBorder then
		levelFrame.selectedBorder:SetDesaturated(white);
	end
end

---------------------------------------------------------------------------------------------------
-- Unit frame hooks
---------------------------------------------------------------------------------------------------

local function ApplyAll(unitFrame)
	ApplyNameWidth(unitFrame);
	ApplyFonts(unitFrame);
	ApplyCastIcon(unitFrame);
	ApplyTargetBorder(unitFrame);
end

-- Hooked after Blizzard's NamePlateUnitFrameMixin:UpdateAnchors. Blizzard calls it at the end of
-- ApplyFrameOptions, so at this point all of Blizzard's fonts, sizes and anchors are freshly set.
local function SetupUnitFrame(unitFrame)
	if hookedUnitFrames[unitFrame] then
		return;
	end
	hookedUnitFrames[unitFrame] = true;

	hooksecurefunc(unitFrame, "UpdateAnchors", ApplyAll);
end
ns.SetupUnitFrame = SetupUnitFrame;

local function IsUsableUnitFrame(unitFrame)
	return unitFrame and not unitFrame:IsForbidden() and unitFrame.UpdateAnchors ~= nil;
end

-- Blizzard's own preview in its nameplate settings.
local function GetBlizzardPreviewNamePlate()
	local token = NamePlateConstants and NamePlateConstants.PREVIEW_UNIT_TOKEN;
	if token and NamePlateDriverFrame:IsScriptNamePlateRegistered(token) then
		return NamePlateDriverFrame:GetNamePlateForUnit(token);
	end
end

local function ForEachUnitFrame(func)
	for _, namePlate in ipairs(C_NamePlate.GetNamePlates()) do
		if not namePlate:IsForbidden() and IsUsableUnitFrame(namePlate.UnitFrame) then
			func(namePlate.UnitFrame);
		end
	end

	local blizzardPreview = GetBlizzardPreviewNamePlate();
	if blizzardPreview and IsUsableUnitFrame(blizzardPreview.UnitFrame) then
		func(blizzardPreview.UnitFrame);
	end

	local ownPreview = ns.activePreview and ns.activePreview:GetUnitFrame();
	if ownPreview then
		func(ownPreview);
	end
end

local function OnNamePlateAdded(_driver, namePlateUnitToken)
	-- Called from an insecure context, so forbidden nameplates are never returned here.
	local namePlate = NamePlateDriverFrame:GetNamePlateForUnit(namePlateUnitToken);
	if not namePlate or namePlate:IsForbidden() then
		return;
	end

	local unitFrame = namePlate.UnitFrame;
	if IsUsableUnitFrame(unitFrame) then
		SetupUnitFrame(unitFrame);
		ApplyAll(unitFrame);
	end
end

---------------------------------------------------------------------------------------------------
-- Nameplate width
---------------------------------------------------------------------------------------------------

local function UpdatePreviewSize()
	if ns.activePreview then
		ns.activePreview:UpdateSize();
	end
end

local function ApplyPlateWidth()
	if not blizzardWidth or not blizzardHeight then
		return;
	end

	local percent = Round(GetOption("plateWidth"));
	if percent == 100 and not widthOverridden then
		return; -- Nothing to do, Blizzard's size is in effect.
	end

	if InCombatLockdown() then
		if not widthPendingAfterCombat then
			widthPendingAfterCombat = true;
			Print(ns.L.COMBAT_DEFERRED);
		end
		return;
	end
	widthPendingAfterCombat = false;

	local width = blizzardWidth * percent / 100;
	C_NamePlate.SetNamePlateSize(width, blizzardHeight);
	widthOverridden = percent ~= 100;

	-- Blizzard's settings preview nameplate is sized by Lua instead of C++.
	local blizzardPreview = GetBlizzardPreviewNamePlate();
	if blizzardPreview then
		blizzardPreview:SetSize(width, blizzardHeight);
	end

	UpdatePreviewSize();

	-- The name width is computed from the nameplate width, so it has to follow.
	ForEachUnitFrame(ApplyNameWidth);
end

-- Runs after Blizzard's NamePlateDriverMixin:UpdateNamePlateSize, which has just set its own size.
local function OnBlizzardPlateSizeUpdated()
	blizzardWidth, blizzardHeight = C_NamePlate.GetNamePlateSize();
	widthOverridden = false;
	ApplyPlateWidth();
	UpdatePreviewSize();
end

---------------------------------------------------------------------------------------------------
-- Setting changes
---------------------------------------------------------------------------------------------------

function ns.OnSettingChanged(key)
	if key == "plateWidth" then
		ApplyPlateWidth();
	elseif key == "previewType" then
		if ns.activePreview then
			ns.activePreview:Refresh();
		end
	elseif FEATURE_OF_KEY[key] then
		touched[FEATURE_OF_KEY[key]] = true;
		ForEachUnitFrame(ApplyAll);
	end
end

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

local function InitDatabase()
	if type(EasyDefaultPlatesDB) ~= "table" then
		EasyDefaultPlatesDB = {};
	end

	if EasyDefaultPlatesDB.dbVersion ~= DB_VERSION then
		wipe(EasyDefaultPlatesDB);
		EasyDefaultPlatesDB.dbVersion = DB_VERSION;
	end

	ns.db = EasyDefaultPlatesDB;

	for key, feature in pairs(FEATURE_OF_KEY) do
		if not IsDefault(key) then
			touched[feature] = true;
		end
	end
end

local function InstallNamePlateHooks()
	if ns.hooksInstalled or not NamePlateDriverFrame then
		return;
	end
	ns.hooksInstalled = true;

	hooksecurefunc(NamePlateDriverFrame, "UpdateNamePlateSize", OnBlizzardPlateSizeUpdated);
	hooksecurefunc(NamePlateDriverFrame, "OnNamePlateAdded", OnNamePlateAdded);

	-- Nameplates that already exist (normally none at this point).
	ForEachUnitFrame(function(unitFrame)
		SetupUnitFrame(unitFrame);
		ApplyAll(unitFrame);
	end);
end

local eventFrame = CreateFrame("Frame");
eventFrame:RegisterEvent("ADDON_LOADED");
eventFrame:RegisterEvent("PLAYER_LOGIN");
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
eventFrame:SetScript("OnEvent", function(_self, event, arg1)
	if event == "ADDON_LOADED" then
		if arg1 == addonName then
			InitDatabase();
			ns.RegisterSettings();
			InstallNamePlateHooks();
		elseif arg1 == "Blizzard_NamePlates" and ns.db then
			InstallNamePlateHooks();
		end
	elseif event == "PLAYER_LOGIN" then
		InstallNamePlateHooks();
		-- Normally Blizzard's size update (VARIABLES_LOADED) already fed us its size. If not, the
		-- current size is still Blizzard's own because we haven't changed anything yet.
		if not blizzardWidth then
			blizzardWidth, blizzardHeight = C_NamePlate.GetNamePlateSize();
			ApplyPlateWidth();
		end
	elseif event == "PLAYER_REGEN_ENABLED" then
		if widthPendingAfterCombat then
			ApplyPlateWidth();
		end
	end
end);

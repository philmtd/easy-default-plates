local addonName, ns = ...
local L = ns.L;

local FONT_SIZE_MAX = 30;
local CAST_ICON_SIZE_MAX = 32;

local Round = ns.Round;

local function GetVariable(key)
	return addonName .. "_" .. key;
end

local function FormatNumber(value)
	if not value then
		return L.UNKNOWN;
	end
	return tostring(Round(value));
end

local function FormatPercent(value)
	return ("%d%%"):format(Round(value));
end

local function FormatSize(value)
	value = Round(value);
	if value <= 0 then
		return L.DEFAULT;
	end
	return tostring(value);
end

local function FormatNameWidth(value)
	value = Round(value);
	if value <= 0 then
		return L.AUTO;
	end
	return FormatPercent(value);
end

-- Values that reproduce the Classic Anniversary nameplates, scaled like Blizzard scales its own
-- values for the current nameplate size (NamePlateDriverMixin:UpdateNamePlateOptions).
local function GetAnniversaryPresetValues()
	local options = NamePlateSetupOptions or {};
	local verticalScale = options.verticalScale or 1;
	local anniversary = ns.ANNIVERSARY;

	if options.useClassicHealthBar then
		-- Classic style: same width and fonts in both clients, only the cast icon differs.
		return {
			plateWidth = 100,
			nameFontSize = 0,
			healthFontSize = 0,
			nameWidth = 0,
			castIconSize = Round(anniversary.CLASSIC_CAST_BAR_ICON_HEIGHT * verticalScale),
			whiteTargetBorder = true,
		};
	end

	local foreverWidth = NamePlateConstants and NamePlateConstants.NAME_PLATE_WIDTH or 190;
	local fontSize = Round(anniversary.HEALTH_BAR_FONT_HEIGHT * verticalScale);
	return {
		plateWidth = Round(anniversary.NAME_PLATE_WIDTH / foreverWidth * 100),
		nameFontSize = fontSize,
		healthFontSize = fontSize,
		nameWidth = 0,
		castIconSize = Round(anniversary.CAST_BAR_ICON_HEIGHT * verticalScale),
		whiteTargetBorder = true,
	};
end

local function ApplyAnniversaryPreset()
	for key, value in pairs(GetAnniversaryPresetValues()) do
		Settings.SetValue(GetVariable(key), value);
	end
end

function ns.RegisterSettings()
	local category, layout = Settings.RegisterVerticalLayoutCategory(L.TITLE);
	ns.settingsCategory = category;

	local function RegisterSetting(key, label, varType)
		local setting = Settings.RegisterAddOnSetting(category, GetVariable(key), key, ns.db, varType, label, ns.defaults[key]);
		setting:SetValueChangedCallback(function()
			ns.OnSettingChanged(key);
		end);
		return setting;
	end

	local function AddSlider(key, label, tooltip, minValue, maxValue, step, formatter)
		local setting = RegisterSetting(key, label, Settings.VarType.Number);
		local options = Settings.CreateSliderOptions(minValue, maxValue, step);
		options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, formatter);
		return Settings.CreateSlider(category, setting, options, tooltip);
	end

	local function AddCheckbox(key, label, tooltip)
		local setting = RegisterSetting(key, label, Settings.VarType.Boolean);
		return Settings.CreateCheckbox(category, setting, tooltip);
	end

	local function BlizzardSizeTooltip(key, text)
		return function()
			return text:format(FormatNumber(ns.GetBlizzardFontSize(key)));
		end;
	end

	-- Preview
	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L.SECTION_PREVIEW));
	layout:AddInitializer(Settings.CreatePanelInitializer("EasyDefaultPlatesPreviewTemplate", {}));
	do
		local setting = RegisterSetting("previewType", L.PREVIEW_TYPE, Settings.VarType.Number);
		local function GetOptions()
			local container = Settings.CreateControlTextContainer();
			for index, preview in ipairs(ns.PREVIEWS) do
				container:Add(index, preview.label);
			end
			return container:GetData();
		end
		Settings.CreateDropdown(category, setting, GetOptions, L.PREVIEW_TYPE_TOOLTIP);
	end

	-- Preset
	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L.SECTION_PRESETS));
	do
		local addSearchTags = true;
		layout:AddInitializer(CreateSettingsButtonInitializer(L.PRESET_ANNIVERSARY, L.PRESET_APPLY, ApplyAnniversaryPreset, L.PRESET_ANNIVERSARY_TOOLTIP, addSearchTags));
	end

	-- Nameplate
	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L.SECTION_PLATE));
	AddSlider("plateWidth", L.PLATE_WIDTH,
		function() return L.PLATE_WIDTH_TOOLTIP:format(FormatNumber(ns.GetBlizzardPlateWidth())); end,
		50, 300, 1, FormatPercent);

	-- Text sizes
	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L.SECTION_FONTS));
	AddSlider("nameFontSize", L.NAME_FONT, BlizzardSizeTooltip("nameFontSize", L.NAME_FONT_TOOLTIP), 0, FONT_SIZE_MAX, 1, FormatSize);
	AddSlider("healthFontSize", L.HEALTH_FONT, BlizzardSizeTooltip("healthFontSize", L.HEALTH_FONT_TOOLTIP), 0, FONT_SIZE_MAX, 1, FormatSize);
	AddSlider("castFontSize", L.CAST_FONT, BlizzardSizeTooltip("castFontSize", L.CAST_FONT_TOOLTIP), 0, FONT_SIZE_MAX, 1, FormatSize);
	AddSlider("levelFontSize", L.LEVEL_FONT, BlizzardSizeTooltip("levelFontSize", L.LEVEL_FONT_TOOLTIP), 0, FONT_SIZE_MAX, 1, FormatSize);

	-- Text width
	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L.SECTION_LAYOUT));
	AddSlider("nameWidth", L.NAME_WIDTH, L.NAME_WIDTH_TOOLTIP, 0, 100, 5, FormatNameWidth);

	-- Appearance
	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L.SECTION_APPEARANCE));
	AddCheckbox("whiteTargetBorder", L.WHITE_TARGET_BORDER, L.WHITE_TARGET_BORDER_TOOLTIP);
	AddSlider("castIconSize", L.CAST_ICON, BlizzardSizeTooltip("castIconSize", L.CAST_ICON_TOOLTIP), 0, CAST_ICON_SIZE_MAX, 1, FormatSize);

	Settings.RegisterAddOnCategory(category);
end

SLASH_EASYDEFAULTPLATES1 = "/easydefaultplates";
SLASH_EASYDEFAULTPLATES2 = "/edp";
-- Blizzard doesn't allow addons to open the settings panel during combat, so the request waits
-- until combat ends.
local openAfterCombatFrame = CreateFrame("Frame");
openAfterCombatFrame:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_REGEN_ENABLED");
	Settings.OpenToCategory(ns.settingsCategory:GetID());
end);

SlashCmdList.EASYDEFAULTPLATES = function()
	if not ns.settingsCategory then
		return;
	end

	if InCombatLockdown() then
		openAfterCombatFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
		ns.Print(L.SETTINGS_AFTER_COMBAT);
		return;
	end

	Settings.OpenToCategory(ns.settingsCategory:GetID());
end;

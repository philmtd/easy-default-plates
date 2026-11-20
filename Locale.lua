local _, ns = ...

local L = {
	TITLE = "Easy Default Plates",

	SECTION_PLATE = "Nameplate",
	SECTION_FONTS = "Text Sizes",
	SECTION_LAYOUT = "Text Width",

	PLATE_WIDTH = "Nameplate Width",
	PLATE_WIDTH_TOOLTIP = "Width of all nameplates relative to Blizzard's width (100%% = unchanged). A wider nameplate leaves more room for long names.\n\nBlizzard's current width: %s\n\nCan't be changed during combat; the change is applied when combat ends.",

	NAME_FONT = "Name",
	NAME_FONT_TOOLTIP = "Font size of the unit name.\n\n\"Default\" keeps Blizzard's size (currently %s).",
	HEALTH_FONT = "Health Text",
	HEALTH_FONT_TOOLTIP = "Font size of the health value and percentage.\n\n\"Default\" keeps Blizzard's size (currently %s).",
	CAST_FONT = "Cast Bar Text",
	CAST_FONT_TOOLTIP = "Font size of the spell name and spell target on the cast bar.\n\n\"Default\" keeps Blizzard's size (currently %s).",
	LEVEL_FONT = "Level",
	LEVEL_FONT_TOOLTIP = "Font size of the level indicator.\n\n\"Default\" keeps Blizzard's size (currently %s).",

	NAME_WIDTH = "Name Width",
	NAME_WIDTH_TOOLTIP = "How far the name may extend, as a share of the health bar width. Longer names are truncated there.\n\n\"Auto\" keeps Blizzard's behavior: the name ends where the health text begins.\n\nHas no effect on styles that center the name above the health bar (e.g. Classic).",

	SECTION_APPEARANCE = "Appearance",
	WHITE_TARGET_BORDER = "White Target Border",
	WHITE_TARGET_BORDER_TOOLTIP = "Uses the white target border of Classic Anniversary instead of Forever's yellow one, on the health bar and the level indicator.\n\nWith the Classic style only the level indicator has a target border.",
	CAST_ICON = "Cast Bar Icon",
	CAST_ICON_TOOLTIP = "Size of the spell icon on the cast bar.\n\n\"Default\" keeps Blizzard's size (currently %s). Classic Anniversary uses 12 (14 with the Classic style).",

	SECTION_PRESETS = "Preset",
	PRESET_ANNIVERSARY = "Classic Anniversary Look",
	PRESET_APPLY = "Apply",
	PRESET_ANNIVERSARY_TOOLTIP = "Sets nameplate width, name and health text size, cast bar icon and target border to the values of the Classic Anniversary client (TBC Anniversary), adjusted to your current nameplate size and style. Other settings are not changed.\n\nUse \"Defaults\" at the bottom to return to Blizzard's Forever look.",

	SECTION_PREVIEW = "Preview",
	PREVIEW_TYPE = "Preview Unit",
	PREVIEW_TYPE_TOOLTIP = "Which kind of nameplate the preview shows. The preview is a real Blizzard nameplate and follows Blizzard's nameplate settings too.\n\nNameplates in the game world use their own scale, so their size on screen can differ slightly from the preview.",
	PREVIEW_LABEL = "Preview: %s",
	PREVIEW_UNAVAILABLE = "Preview not available.",
	PREVIEW_ENEMY_NPC = "Enemy NPC (elite, casting)",
	PREVIEW_ENEMY_PLAYER = "Enemy Player (Mage, casting)",
	PREVIEW_NEUTRAL_NPC = "Neutral NPC",
	PREVIEW_FRIENDLY_PLAYER = "Friendly Player (Paladin)",
	PREVIEW_NAME_ENEMY_NPC = "Thornmaw the Withering Plaguebringer",
	PREVIEW_NAME_ENEMY_PLAYER = "Nightwhisper-Silverwatch",
	PREVIEW_NAME_NEUTRAL_NPC = "Greedy Tunnel Rat of the Deep Mines",
	PREVIEW_NAME_FRIENDLY_PLAYER = "Lightheart",
	PREVIEW_SPELL = "Greater Shadow Bolt of Corruption",

	DEFAULT = "Default",
	AUTO = "Auto",
	UNKNOWN = "unknown",

	COMBAT_DEFERRED = "Nameplate width will be applied after combat.",
	SETTINGS_AFTER_COMBAT = "Settings can't be opened during combat. They will open when combat ends.",
};

if GetLocale() == "deDE" then
	L.SECTION_PLATE = "Nameplate";
	L.SECTION_FONTS = "Textgrößen";
	L.SECTION_LAYOUT = "Textbreite";

	L.PLATE_WIDTH = "Nameplate-Breite";
	L.PLATE_WIDTH_TOOLTIP = "Breite aller Nameplates relativ zur Blizzard-Breite (100%% = unverändert). Breitere Nameplates lassen mehr Platz für lange Namen.\n\nAktuelle Blizzard-Breite: %s\n\nKann im Kampf nicht geändert werden; die Änderung wird nach dem Kampf übernommen.";

	L.NAME_FONT = "Name";
	L.NAME_FONT_TOOLTIP = "Schriftgröße des Einheitennamens.\n\n\"Standard\" behält die Blizzard-Größe bei (aktuell %s).";
	L.HEALTH_FONT = "Gesundheitstext";
	L.HEALTH_FONT_TOOLTIP = "Schriftgröße von Gesundheitswert und -prozent.\n\n\"Standard\" behält die Blizzard-Größe bei (aktuell %s).";
	L.CAST_FONT = "Zauberleisten-Text";
	L.CAST_FONT_TOOLTIP = "Schriftgröße von Zaubername und Zauberziel auf der Zauberleiste.\n\n\"Standard\" behält die Blizzard-Größe bei (aktuell %s).";
	L.LEVEL_FONT = "Stufe";
	L.LEVEL_FONT_TOOLTIP = "Schriftgröße der Stufenanzeige.\n\n\"Standard\" behält die Blizzard-Größe bei (aktuell %s).";

	L.NAME_WIDTH = "Namensbreite";
	L.NAME_WIDTH_TOOLTIP = "Wie weit der Name reichen darf, als Anteil an der Breite der Gesundheitsleiste. Längere Namen werden dort gekürzt.\n\n\"Auto\" behält das Blizzard-Verhalten bei: Der Name endet dort, wo der Gesundheitstext beginnt.\n\nHat keine Wirkung bei Stilen, die den Namen zentriert über der Leiste anzeigen (z. B. Klassisch).";

	L.SECTION_APPEARANCE = "Darstellung";
	L.WHITE_TARGET_BORDER = "Weißer Zielrahmen";
	L.WHITE_TARGET_BORDER_TOOLTIP = "Verwendet den weißen Zielrahmen aus Classic Anniversary statt des gelben aus Forever, an der Gesundheitsleiste und an der Stufenanzeige.\n\nBeim Stil \"Klassisch\" hat nur die Stufenanzeige einen Zielrahmen.";
	L.CAST_ICON = "Zaubersymbol";
	L.CAST_ICON_TOOLTIP = "Größe des Zaubersymbols auf der Zauberleiste.\n\n\"Standard\" behält die Blizzard-Größe bei (aktuell %s). Classic Anniversary verwendet 12 (14 beim Stil \"Klassisch\").";

	L.SECTION_PRESETS = "Voreinstellung";
	L.PRESET_ANNIVERSARY = "Classic-Anniversary-Look";
	L.PRESET_APPLY = "Übernehmen";
	L.PRESET_ANNIVERSARY_TOOLTIP = "Setzt Nameplate-Breite, Größe von Name und Gesundheitstext, Zaubersymbol und Zielrahmen auf die Werte des Classic-Anniversary-Clients (TBC Anniversary), angepasst an deine aktuelle Nameplate-Größe und deinen Stil. Andere Einstellungen bleiben unverändert.\n\nMit \"Standardeinstellungen\" unten kommst du zurück zum Forever-Look von Blizzard.";

	L.SECTION_PREVIEW = "Vorschau";
	L.PREVIEW_TYPE = "Vorschau-Einheit";
	L.PREVIEW_TYPE_TOOLTIP = "Welche Art von Nameplate die Vorschau zeigt. Die Vorschau ist eine echte Blizzard-Nameplate und folgt auch den Nameplate-Einstellungen von Blizzard.\n\nNameplates in der Spielwelt haben eine eigene Skalierung, daher kann ihre Größe auf dem Bildschirm leicht von der Vorschau abweichen.";
	L.PREVIEW_LABEL = "Vorschau: %s";
	L.PREVIEW_UNAVAILABLE = "Vorschau nicht verfügbar.";
	L.PREVIEW_ENEMY_NPC = "Feindlicher NPC (Elite, wirkt Zauber)";
	L.PREVIEW_ENEMY_PLAYER = "Feindlicher Spieler (Magier, wirkt Zauber)";
	L.PREVIEW_NEUTRAL_NPC = "Neutraler NPC";
	L.PREVIEW_FRIENDLY_PLAYER = "Freundlicher Spieler (Paladin)";
	L.PREVIEW_NAME_ENEMY_NPC = "Dornschlund der verdorrende Seuchenbringer";
	L.PREVIEW_NAME_ENEMY_PLAYER = "Nachtschwinge-Silberwacht";
	L.PREVIEW_NAME_NEUTRAL_NPC = "Gierige Tunnelratte der Tiefenminen";
	L.PREVIEW_NAME_FRIENDLY_PLAYER = "Lichtherz";
	L.PREVIEW_SPELL = "Großer Schattenblitz der Verderbnis";

	L.DEFAULT = "Standard";
	L.AUTO = "Auto";
	L.UNKNOWN = "unbekannt";

	L.COMBAT_DEFERRED = "Die Nameplate-Breite wird nach dem Kampf übernommen.";
	L.SETTINGS_AFTER_COMBAT = "Die Einstellungen können im Kampf nicht geöffnet werden. Sie öffnen sich nach dem Kampf.";
end

ns.L = L;

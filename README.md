<p align="center"><img src="Media/Logo.png" alt="Easy Default Plates logo" width="160"></p>

# Easy Default Plates

Simple tweaks for Blizzard's default nameplates in World of Warcraft: Forever.
The addon adjusts the stock nameplates and never draws nameplates of its own.

The default nameplates in Forever are narrower and use larger text than in Classic Anniversary,
so names and health text get truncated quickly. Easy Default Plates makes them fit again.

## Features

- Nameplate width
- Separate text sizes for name, health text, cast bar text and level
- Name width before truncation
- Cast bar icon size
- White target border instead of the yellow one
- One-click "Classic Anniversary Look" preset
- Live preview in the settings
- English and German

All options are in the game's AddOns settings (`/edp`).

## Design

- Only adjusts Blizzard's own nameplate frames after Blizzard has laid them out.
- Changes no game settings. Disabling the addon restores the stock nameplates.
- Every option defaults to Blizzard's own value.

## Limitations

- Nameplate width changes made during combat are applied when combat ends.
- Friendly nameplates in dungeons and raids are protected by Blizzard and can't be changed.

## License

[MIT](LICENSE)

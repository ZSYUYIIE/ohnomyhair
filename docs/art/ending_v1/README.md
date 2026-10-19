# Ending CG integration

Source: the user-supplied `ohnomyhair_ending_assets_v1.zip`. The seven original
1280×720 PNGs are in `assets/art/ending/`; their SHA-256 hashes match the supplied
`asset_manifest.json`. This folder retains the supplied timeline, storyboard and
English subtitle cues for review.

After both friends leave the final room of The Assistant, the CLEAR banner records
progress as usual. On the first clear, the game pauses and plays all seven panels
for 25 seconds before the results. The seen flag persists when playback begins,
so later clears go straight to results. Story on the map offers manual replays once
all chapters are cleared, without changing chapter records or the chosen map stop.
Any key, left click or pad button advances a panel; Esc / B / Start or Skip ends it.
An initial 0.35-second guard prevents accidental input, followed by a 0.25-second
page-turn cooldown.

The opening and ending share `storyboard_cutscene.gd`: full-screen framing,
subtitle styling, shot counter and skip controls. Shot 02 hides
the subtitle strip entirely. Panels retain stable framing without zoom resampling; the
last image fades over its final half-second, inside its four-second duration.
No sound files were included; the existing game music continues.

# Ending CG integration

Source: the user-supplied `ohnomyhair_ending_assets_v1.zip`. The seven original
1280×720 PNGs are in `assets/art/ending/`; their SHA-256 hashes match the supplied
`asset_manifest.json`. This folder retains the supplied timeline, storyboard and
English subtitle cues for review.

After both friends leave the final room of The Assistant, the CLEAR banner records
progress as usual. The game then pauses and plays all seven panels for 25 seconds
before showing the existing final results. Keyboard, mouse and controller skip
to the same results after a 0.35-second guard against accidental input.

The opening and ending share `storyboard_cutscene.gd`: full-screen framing,
subtitle styling, shot counter, restrained zoom and skip controls. Shot 02 hides
the subtitle strip entirely. Only wide ending shots push in (1.00 → 1.03); the
last image fades over its final half-second, inside its four-second duration.
No sound files were included; the existing game music continues.

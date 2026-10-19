# Oh No My Hair — prototype pitch

Final delivery: 1920 × 1080, 30 fps, H.264 MP4 with AAC English narration,
music and burned-in English subtitles. Timeline: 8,290 frames / 4:36.33.
An English SRT is included as a separate editable subtitle file.

## Credits

NPC Union — ChenHongshan333 and ZSYUYIIE.
Public prototype and final-slide QR destination:
https://chenhongshan333.itch.io/ohnomyhair

No private email address or unverified professional biography was added.
The final slide uses the public game page as its contact/materials destination.

## Guide coverage

The pitch follows the pitch section supplied in this conversation from:
https://docs.google.com/document/d/1qH4gfUiiFVJAD6eJYvH6diEbaKcGEAbIRtbpO9PTjrQ/view

- Three-to-five-minute video: 4:36.33.
- English speech and English subtitles.
- Actual gameplay: 1:55.8 across role demonstrations, cooperative combinations,
  water/dryer puzzles, the boss and the prototype overview.
- Premise, game description, atmosphere and distinctive cooperative mechanics.
- Target audience and comparison with two existing co-op puzzle games.
- Indicative minimum, ideal and expanded USD budget scenarios.
- Proposed twelve-week MVP roadmap with three milestones.
- Honest validation plan instead of invented wishlist, follower or player counts.
- Team credits, final thank-you, public prototype URL and QR code.

## Gameplay provenance

Gameplay is captured from this local Godot project using its actual renderer,
scenes, abilities, collisions and enemies. Input is scripted for clean capture.
Chapter 1, chapter 2 room 1 and chapter 3 recordings follow successful automated
playthrough routes. These are gameplay recordings, not AI-generated gameplay.
The boss segment stages the phase transition and a dazed-counterattack setup
to demonstrate existing attacks and the stomp. Selected action clips are slowed
for readability. No playable game code or real-user save data was modified.

Opening/ending artwork, fonts and music come from the project assets.
English voiceover is synthesized with Microsoft Edge TTS, Aria.
The pitch was composed using the official Remotion skill installed from
https://github.com/remotion-dev/skills/tree/main/skills/remotion-best-practices

## Budget assumptions — estimates, not committed costs or funding raised

| Scenario | Duration | Development | Art/audio | QA/tools/localization | Launch | Contingency | Total |
|---|---:|---:|---:|---:|---:|---:|---:|
| Minimum viable | 12 weeks | $12,000 | $3,000 | $1,000 | Included in development | $4,000 | $20,000 |
| Ideal | 24 weeks | $36,000 | $10,000 | $4,000 | $4,000 | $6,000 | $60,000 |
| Expanded ceiling | 36 weeks | $72,000 | $20,000 | $8,000 | $8,000 | $12,000 | $120,000 |

The minimum development allowance assumes two contributors for three months at
an indicative $2,000 each per month. The ideal assumes $3,000 each per month
for six months; the expanded scenario assumes $4,000 each per month for nine
months. These are production allowances, not local salary-market quotations.
Re-scope after playtests; no online multiplayer commitment in the MVP.

## Market and metrics

Comparable descriptions were checked against their official store pages:

- PICO PARK 2: https://store.steampowered.com/app/2644470/?l=english
  — cooperative action puzzles for 2–8 players.
- ibb & obb: https://store.steampowered.com/app/95400/ibb__obb/?cc=us&l=english
  — two-player cooperative puzzles using gravity in both directions.

The positioning is an argument about the game design, not a sales forecast.
No Steam wishlists, Discord members, paid customers or external playtest counts
were supplied or independently established. The cohort of twenty pairs is a
proposed next validation target. Four chapters, twelve rooms and three boss
phases describe prototype content, not audience traction.

## Editing

Project: build/pitch/editor. Start preview with `npm run dev`.
Eighteen independently authored scene nodes live in src/Root.tsx.
Visual layouts are in src/PitchScene.tsx. Original narration is in script.json;
word timings, media and the complete timeline are in editor/public.
Raw gameplay movies and their clip indexes are retained in build/pitch.

The entire build/pitch directory is ignored by Git; the game branch is unchanged.

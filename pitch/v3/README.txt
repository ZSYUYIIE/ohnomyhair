OH NO MY HAIR / PITCH v3

中文交付与统一换配音说明：交付与配音替换.txt

Deliverables
  ../videos/Oh_No_My_Hair_Pitch_v3.mp4       Main film: temporary AI narration, game SFX, music, English captions
  ../videos/Oh_No_My_Hair_Pitch_v3_NoBGM.mp4 Same film and SFX, without background music
  ../videos/Oh_No_My_Hair_Pitch_v3_Clean.mp4  Clean silent picture without burned-in captions or AI voice
  ../videos/Oh_No_My_Hair_Pitch_v3.en.srt    Editable English subtitles
  Oh_No_My_Hair_v3_Voiceover.wav            Full temporary narration stem
  Oh_No_My_Hair_v3_Music_Effects.wav        Full music and effects stem, no narration
  Oh_No_My_Hair_v3_Music.wav                Full ducked music stem, no voices or effects

Preview / edit
  From pitch/editor: npm run dev:v3
  Composition: OhNoMyHairPitchV3 (separate from v1/v2's entry point)
  v3 visual scenes: editor/src/v3/Scenes.tsx
  Narration: v3/script.py and v3/read_aloud.txt
  Timeline and captions: v3/timeline.json (generated)
  Per-section and per-line audio: editor/public/v3/voice/

Rebuild (commands below are run from the project root)
  python pitch/v3/script.py
  pitch/.venv-v3/Scripts/python.exe pitch/v3/voice.py
  python pitch/v3/build.py
  npm --prefix pitch/editor run lint:v3
  python pitch/v3/render.py bundle
  python pitch/v3/render.py stills
  python pitch/v3/render.py final
  python pitch/v3/qa.py --decode
  pitch/.venv-v3/Scripts/python.exe pitch/v3/check_audio.py

Setup: npm ci in pitch/editor; create a Python venv in pitch/.venv-v3 and
install pitch/requirements.txt. The capture script defaults to the local
Godot executable in F:/godot; edit record.ps1 if the engine is elsewhere.
The renderer defaults to the local Chrome executable; change CHROME in
render.py if necessary. FFmpeg / FFprobe must be on PATH.

Replacing the AI voices
  The easiest unified replacement is in your video editor: use the Clean
  picture, Music_Effects.wav and your new narration. Import the SRT and
  retime captions to your recording. Every stem starts at film time zero.
  read_aloud.txt is the recording script; storyboard.txt shows section starts.

  For a Remotion rebuild, replace each editor/public/v3/voice/<section>.mp3.
  Update <section>-timing.json with the actual recording duration and word
  timestamps (seconds relative to the section audio). Run build.py and
  render.py; section boundaries expand if the replacement needs more room.
  Do not run voice.py after importing human recordings: it generates TTS.
  Root.tsx, PitchV3.tsx and data.ts are generated. For durable changes, edit
  script.py, timing JSON or Scenes.tsx, then rebuild.

Capture provenance
  sling, failure, parry, dryer and swap were newly recorded from the actual
  Godot 4.7.2 project, renderer, physics, enemies, abilities and sound effects.
  PlayBot supplies deterministic input. Capture uses the inherited isolated
  test save. The menu screenshots use a separate pitch_v3_ui.cfg save.
  The failure clip is a deliberate carry without the required sling.

  The new boss clip is a mechanic demonstration: starting player positions,
  an incoming scissor and capture immunity are staged. The player then uses
  real parry, launch and movement inputs. The boss's own collision, stun,
  stomp damage, phase-two transition and backup rules resolve normally.
  This is not evidence of an unaided human playthrough or an audience test.

  Some existing v2 clips remain for basic abilities, showers and a wider
  boss view. Their original provenance is in ../docs/Oh_No_My_Hair_Pitch_Notes.md.
  Editorial crops, normal-speed cuts and a labelled 0.8x replay aid reading.
  Ready? / Throw me! are staged, synthesized presentation dialogue.

Pitch claims
  Four chapters and twelve rooms match current levels 01,02,03,06 (3+2+3+4).
  Twenty player pairs is a proposed next test cohort, not completed testing.
  Twelve weeks / USD 17,200 is a proposed production plan based on the
  existing pitch budget research; it is not money secured or a release date.
  The primary request is playtest participation and mentoring. No individual
  team responsibilities, player metrics or funding commitments were invented.

Skills and references
  video-shotcraft: https://github.com/Vincentwei1021/video-shotcraft
  Remotion: https://github.com/remotion-dev/skills
  Humanizer: https://github.com/blader/humanizer
  Project: game-feel, audio-design, game-ui-ux, godot-gdscript
  Reference talk: https://www.youtube.com/watch?v=t5MZhwGgXbk
  Author's companion article:
  https://www.tinybuild.com/single-post/how-to-pitch-games-in-2024

  Shotcraft mode: autonomous original creation, following the user's
  instruction to execute the previous proposal. Palette, type and art come
  from the game. See production_brief.json for adaptations to product-ad
  defaults. Real game SFX and characterful game music deliberately replace
  the product template's tech-house / no-game-audio preference.

  One recipe card is adapted: marker-underline-title / marker-underline-title.
  Source: demos/typography/marker-underline-title/MarkerUnderlineTitle.tsx.
  The modified Marker.tsx preserves the seeded stroke geometry and f32–42
  drawing interval. Game action shots, crops and process labels are custom
  editorial treatments rather than claims of exact Gallery recreation.

  Rendering uses frame-exact OffthreadVideo and bounded decode caches.
  Audio-only props reuse the same Footage trims and clip boundaries with
  ClipAudio, so stems do not decode pictures that will not be exported.
  The NoBGM audio is rendered from this same composition with bgm=false;
  its picture stream is copied from the main master, guaranteeing identical
  pictures. It does not attempt to remove music from a finished mixed track.

Verification
  review/technical_checks.json: final media, decode, captions, QR and stems.
  review/audio_checks.json and audio_checks_nobgm.json: encoded cue timing
  and measured loudness. Voice-source alignment is reported separately
  from frame-locked game SFX; no subjective listening is claimed.
  review/independent_review.txt: independent findings and any limitations.
  review/final-contact.jpg: three encoded frames per section.
  Detailed renderer logs remain locally in review/logs/ (ignored by Git).

  Third-party code attribution: LICENSE-shotcraft.txt and NOTICE-shotcraft.txt.
  Visuals, fonts and game audio are reused from this project.

Optional Shotcraft sharing notes
  Voluntary author credit when publishing:
  X https://x.com/VincentWei93
  Douyin https://www.douyin.com/user/MS4wLjABAAAAK1pkjBxilk2Oi_9h_vFyD-lTAu9CTlvhmOtkosDvvxg
  Xiaohongshu https://xhslink.cn/m/At9iP2d5C1V
  Optional showcase: https://vincentwei1021.github.io/video-shotcraft/showcase.html
  The skill also supports a future Jianying export; that export is not part
  of this delivery. The Remotion source and clean replacement assets are.

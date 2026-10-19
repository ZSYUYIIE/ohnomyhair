# Oh No My Hair pitch v2: script, voice and budget notes

In the repo, the files sit in `pitch/`:

- `videos/Oh_No_My_Hair_Pitch_v2.mp4` and `.en.srt`: the v2 video, told by two voices (a guy and a girl), and its subtitles.
- `docs/Oh_No_My_Hair_Pitch_Script_v2.txt`: the two-voice script, same 18 scenes as v1, if you'd rather record it yourselves.
- `docs/Oh No My Hair global USD budget.md`: the sourced budget research (indie team, USD, international funding only), with notes in `docs/research_notes/`.
- This file. See `pitch/README.md` for how to change and re-render the video.

## Why v1 sounded like AI

The writing was checked with the humanizer skill (github.com/blader/humanizer, based on Wikipedia's "Signs of AI writing"). It's now installed in `~/.claude/skills/humanizer`, so you can run `/humanizer` on future text. The v1 script had these tells:

- Contrasts that only add weight: "a shared resource, rather than just a personal advantage", "planning estimates, not funding raised", "future validation targets, not achieved audience metrics".
- One-line closers that restate the scene: "The solution belongs to both players.", "An enemy attack becomes the key to the next door.", "A bad haircut becomes a warm story about trust."
- Fake-deep titles and lines: "Better Together. Literally.", "Escaping means learning to trust each other.", "Measure the partnership."
- Everything in threes ("glide, pull levers, and carry", "dash, parry, and launch", "friends, siblings, and couples", "Carry me. Wait for the water. Parry now.").
- Report language read aloud: "Our audience is", "indicative budgets", "the minimum allocates", "His tools complement hers".
- An unnamed narrator describing the game from outside, every sentence about the same length, which a TTS voice then reads with the same flat rhythm.

## What changed in the storytelling

- The two of you tell it in turns, in first person. It opens with who you are and the 48-hour jam ("Better Together") the game came from.
- Gameplay scenes describe what happens on screen, the way you'd explain it to a friend, instead of naming the design idea behind it.
- The repeated "this proves cooperation" lines are gone. The design rule is said once (scene 09), with the kind of thing players actually shout.
- Facts are unchanged: the same mechanics, comparisons, prototype content, roadmap and validation plan. Two true details were added from the project: the game logs where players die, and the team runs bot playthroughs with human-like mistakes to find rooms that need perfect timing.
- The budget is rewritten from the research (below). The US$60k and US$120k tiers and the word "incubation" are gone.

## Making the voice sound human

The best fix is to record yourselves. Two real student voices telling their own story is more convincing than any synthetic voice, and it matches the new script, which is written for two speakers. Accents and small stumbles are fine; they're what makes it sound human.

1. Record on a phone voice memo in a small room with soft things around (a bedroom with a bed and curtains, or a wardrobe full of clothes). Keep the phone about a hand-span from your mouth, slightly to the side.
2. Read each scene two or three times. Talk to one imagined friend, not to "an audience", and don't try to sound like a presenter.
3. Keep the take that sounds most like talking. Cut in Audacity (free) or straight in the Remotion editor; leave the natural pauses in.
4. Make new subtitles from your recording with faster-whisper, which is already installed on this PC:

```
python -c "from faster_whisper import WhisperModel; import sys; m=WhisperModel('small'); segs,_=m.transcribe(sys.argv[1]); import datetime as d; f=lambda t: str(d.timedelta(seconds=t))[:-3].rjust(12,'0').replace('.',','); print('\n'.join(f'{i}\n{f(s.start)} --> {f(s.end)}\n{s.text.strip()}\n' for i,s in enumerate(segs,1)))" voiceover.wav > Oh_No_My_Hair_Pitch_v2.en.srt
```

The v2 video uses two different Microsoft neural voices, one per speaker: Brian (A, guy) and Emma (B, girl), both from the newer "multilingual" set, which sound more conversational than v1's "Aria", a voice many people recognise. Each line is a separate take with a short pause when the other person picks up, so it sounds like two people talking. To swap who says what, change the A/B letters in the script.

If you want better synthetic voices than that, ElevenLabs' free tier (10,000 characters a month) covers this script (about 3,700 characters). Use two different voices for A and B, and paste the v2 script as written: it has contractions, short sentences and numbers spelled out, which are what make TTS sound less read-out. Even so, recording yourselves will sound more real than any of these.

## Budget (scenes 13 and 14)

From the global USD report, recommended tier, 12 weeks (2.76 months):

| Line | USD |
|---|---:|
| Pay for both of you, US$1,600 a month each (low end of Rami Ismail's US$1,600–2,200 benchmark for small indie teams) | 8,830 |
| Freelance art (3 character sets, 8 backgrounds, UI) | 2,270 |
| Music, 8 minutes | 1,200 |
| Custom sound effects, 25 | 750 |
| Steam fee, playtests, tools, store art, trailer, Steam page in Simplified Chinese | 1,265 |
| 20% buffer | 2,863 |
| Total | about 17,200 |

The lean fallback is about US$900 with no pay, which you can cover yourselves, so the game ships either way. A stretch version (US$2,200 a month each, more commissioned art and music) is about US$26,500, but only keep it if you have a realistic source for it.

Why the v1 numbers looked fake: the US$2,000 a month rate was actually fine, and itemised it comes to about US$19,800, so the US$20k total was close. What gave it away was that it showed no line items, counted 12 weeks as 3 months, left out the Steam fee, store art and trailer, and had a buffer bigger than the whole art and audio line. The US$60k and US$120k tiers had nothing behind them and no one who would fund them.

Where the money could come from: your own savings for the roughly US$6,600 of production costs, and a Kickstarter of about US$10,000 for your pay (fees are about 9%; video games succeed about 32% of the time, so it's upside, not a promise). Festival prizes like IGF are a bonus. Epic MegaGrants (Unreal only), Outersloth (US$50k minimum) and publisher advances (US$20k minimum, rare for first games) don't fit. If one of you is a woman or gender-marginalised developer, WINGS finishing funds fit this size and timing well.

## Check before you record

- Kickstarter: one of you has to be 18+ and live in one of its 25 supported countries, with a local bank account. If not, say "pre-orders and itch.io sales" in scene 14 instead.
- Steam: the script says the Steam page goes up by week eight, because Steam needs the page "coming soon" for two weeks and about seven working days for review. Keep that line only if you really plan a Steam release.
- Names: the script uses your handles, like v1. Swap in real first names if you'd rather.
